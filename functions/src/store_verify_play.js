/**
 * Google Play verifier foundation
 * (`store_purchase_verification_contract_v1`).
 *
 * No fake verification. Without credentials + API client → fail closed.
 * Does not write entitlements. Server owns ack/consume (not performed here).
 * RTDN not implemented here.
 */

'use strict';

const {
  mapPlayProduct,
  mapPlaySubscriptionStatus,
  buildSubscriptionEntitlementFields,
  consumableCreditIntent,
  PRODUCT_KIND,
  PLAY_SUBSCRIPTION_PRODUCT_ID,
} = require('./store_product_map');
const { validateUidBinding } = require('./store_uid_binding');
const {
  failClosedNotConfigured,
  failClosed,
  trustedVerifiedResult,
} = require('./store_verification_result');

/**
 * @param {object} [opts]
 * @param {object|null} [opts.credentials]
 * @param {Function|null} [opts.fetchSubscription] async ({purchaseToken,productId,packageName}) => data
 * @param {Function|null} [opts.fetchProductPurchase] async ({purchaseToken,productId,packageName}) => data
 * @returns {boolean}
 */
function hasPlayVerifier(opts = {}) {
  const creds = opts.credentials;
  const hasCreds =
    creds &&
    typeof creds === 'object' &&
    !!(creds.clientEmail || creds.privateKey || creds.configured);
  const hasClient =
    typeof opts.fetchSubscription === 'function' ||
    typeof opts.fetchProductPurchase === 'function';
  return !!(hasCreds && hasClient);
}

/**
 * Map a trusted Play API payload (subscription or product) to verification result.
 *
 * @param {object} args
 * @param {string} args.callerUid
 * @param {string} args.productId client/store product id
 * @param {object} args.purchase trusted API body
 * @param {'subscription'|'consumable'} args.kindHint
 * @param {boolean} [args.requireBinding=true]
 * @returns {Record<string, unknown>}
 */
function mapTrustedPlayPurchase({
  callerUid,
  productId,
  purchase,
  kindHint,
  requireBinding = true,
}) {
  if (!purchase || typeof purchase !== 'object') {
    return failClosed('store_verification_failed', { platform: 'android' });
  }

  const basePlanId =
    purchase.basePlanId ||
    purchase.base_plan_id ||
    (purchase.lineItems &&
      purchase.lineItems[0] &&
      (purchase.lineItems[0].offerDetails || {}).basePlanId) ||
    null;

  const effectiveProductId =
    purchase.productId ||
    purchase.product_id ||
    productId ||
    (kindHint === PRODUCT_KIND.SUBSCRIPTION
      ? PLAY_SUBSCRIPTION_PRODUCT_ID
      : null);

  const mapped = mapPlayProduct(effectiveProductId, basePlanId);
  if (!mapped.ok) {
    return failClosed(mapped.code, {
      platform: 'android',
      product_id: effectiveProductId,
      base_plan_id: basePlanId,
    });
  }

  const binding = validateUidBinding({
    callerUid,
    storeAccountToken:
      purchase.obfuscatedExternalAccountId ||
      purchase.obfuscated_external_account_id ||
      purchase.obfuscatedAccountId,
    requireBinding,
  });
  if (!binding.ok) {
    return failClosed(binding.code, { platform: 'android' });
  }

  const mapping = mapped.mapping;
  const orderId = purchase.orderId || purchase.order_id || null;
  const purchaseToken =
    purchase.purchaseToken || purchase.purchase_token || null;
  const storeTransactionId = orderId || purchaseToken;

  if (mapping.kind === PRODUCT_KIND.CONSUMABLE) {
    const state = String(purchase.purchaseState ?? '').toUpperCase();
    if (
      purchase.purchaseState === 1 ||
      state === '1' ||
      state === 'CANCELLED' ||
      state === 'CANCELED'
    ) {
      return failClosed('revoked', {
        platform: 'android',
        mapping,
        store_transaction_id: storeTransactionId,
      });
    }
    return trustedVerifiedResult({
      platform: 'android',
      kind: PRODUCT_KIND.CONSUMABLE,
      mapping,
      credit: consumableCreditIntent(mapping),
      subscription_state: null,
      resonance_access: false,
      store_transaction_id: storeTransactionId,
      original_transaction_id: orderId || storeTransactionId,
      period_ends_at: null,
      verification_source: 'play',
      acknowledgement_required: true,
      consumption_required: true,
    });
  }

  const subscriptionState = mapPlaySubscriptionStatus(
    purchase.subscriptionState ||
      purchase.subscription_state ||
      purchase.status ||
      'ACTIVE',
  );
  const fields = buildSubscriptionEntitlementFields({
    mapping,
    subscriptionState,
    platform: 'android',
  });

  return trustedVerifiedResult({
    platform: 'android',
    kind: PRODUCT_KIND.SUBSCRIPTION,
    mapping,
    credit: null,
    ...fields,
    store_transaction_id: storeTransactionId,
    original_transaction_id: orderId || storeTransactionId,
    period_ends_at:
      purchase.lineItems &&
      purchase.lineItems[0] &&
      purchase.lineItems[0].expiryTime
        ? purchase.lineItems[0].expiryTime
        : purchase.expiryTimeMillis || purchase.expiryTime || null,
    verification_source: 'play',
    acknowledgement_required: true,
    consumption_required: false,
  });
}

/**
 * Verify a Google Play purchase. Fail closed without credentials/API.
 *
 * @param {object} input
 * @param {string} input.callerUid
 * @param {string} input.purchaseToken
 * @param {string} input.productId
 * @param {string} [input.packageName]
 * @param {string} [input.kind] subscription|consumable
 * @param {object} [opts]
 * @returns {Promise<Record<string, unknown>>}
 */
async function verifyPlayPurchase(input, opts = {}) {
  const callerUid = input && input.callerUid;
  if (!callerUid) {
    return failClosed('unauthenticated', { platform: 'android' });
  }
  if (!input.purchaseToken || !input.productId) {
    return failClosed('invalid_argument', { platform: 'android' });
  }

  if (!hasPlayVerifier(opts)) {
    return failClosedNotConfigured('android');
  }

  const kindHint =
    input.kind === PRODUCT_KIND.CONSUMABLE ||
    input.productId === 'qmatch.super_resonance.x1' ||
    input.productId === 'qmatch.boost.x1'
      ? PRODUCT_KIND.CONSUMABLE
      : PRODUCT_KIND.SUBSCRIPTION;

  let purchase = null;
  try {
    if (kindHint === PRODUCT_KIND.SUBSCRIPTION && opts.fetchSubscription) {
      purchase = await opts.fetchSubscription({
        purchaseToken: input.purchaseToken,
        productId: input.productId,
        packageName: input.packageName,
      });
    } else if (
      kindHint === PRODUCT_KIND.CONSUMABLE &&
      opts.fetchProductPurchase
    ) {
      purchase = await opts.fetchProductPurchase({
        purchaseToken: input.purchaseToken,
        productId: input.productId,
        packageName: input.packageName,
      });
    } else {
      return failClosedNotConfigured('android');
    }
  } catch (_err) {
    return failClosed('store_verification_failed', { platform: 'android' });
  }

  if (!purchase) {
    return failClosed('store_verification_failed', { platform: 'android' });
  }

  return mapTrustedPlayPurchase({
    callerUid,
    productId: input.productId,
    purchase,
    kindHint,
    requireBinding: opts.requireBinding !== false,
  });
}

module.exports = {
  hasPlayVerifier,
  mapTrustedPlayPurchase,
  verifyPlayPurchase,
};
