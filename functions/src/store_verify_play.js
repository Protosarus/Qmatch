/**
 * Google Play purchase verification v1
 * (`store_purchase_verification_contract_v1`).
 *
 * Uses Play Developer API:
 * - purchases.subscriptionsv2.get
 * - purchases.products.get
 *
 * Idempotency primary key: purchaseToken (hashed as android:token:<sha256>).
 * RTDN / Billing client SDK not implemented here.
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
const { loadPlayIapConfig } = require('./play_iap_config');
const { resolvePlayApiHelpers } = require('./play_iap_clients');
const {
  androidStoreTransactionIdFromToken,
} = require('./entitlement_ledger');

/** Product purchaseState: 0 purchased, 1 canceled, 2 pending. */
const PRODUCT_PURCHASE_STATE = Object.freeze({
  PURCHASED: 0,
  CANCELED: 1,
  PENDING: 2,
});

/**
 * @param {object} [opts]
 * @returns {boolean}
 */
function hasPlayVerifier(opts = {}) {
  if (
    typeof opts.fetchSubscription === 'function' ||
    typeof opts.fetchProductPurchase === 'function'
  ) {
    const creds = opts.credentials;
    return !!(
      creds &&
      (creds.configured || creds.clientEmail || creds.privateKey)
    );
  }
  return loadPlayIapConfig(opts.env || process.env).ok === true;
}

/**
 * Extract base plan from subscriptionsv2 payload.
 * @param {object} purchase
 * @returns {string|null}
 */
function extractBasePlanId(purchase) {
  if (purchase.basePlanId || purchase.base_plan_id) {
    return purchase.basePlanId || purchase.base_plan_id;
  }
  const item =
    Array.isArray(purchase.lineItems) && purchase.lineItems[0]
      ? purchase.lineItems[0]
      : null;
  if (!item) return null;
  if (item.offerDetails && item.offerDetails.basePlanId) {
    return item.offerDetails.basePlanId;
  }
  return item.basePlanId || null;
}

/**
 * Extract obfuscated account id from Play payloads.
 * @param {object} purchase
 * @returns {string|null}
 */
function extractPlayAccountBinding(purchase) {
  const ext =
    purchase.externalAccountIdentifiers ||
    purchase.external_account_identifiers ||
    {};
  return (
    purchase.obfuscatedExternalAccountId ||
    purchase.obfuscated_external_account_id ||
    purchase.obfuscatedAccountId ||
    ext.obfuscatedExternalAccountId ||
    ext.obfuscatedExternalProfileId ||
    null
  );
}

/**
 * True when subscription is pending / not a completed purchase.
 * @param {object} purchase
 * @returns {boolean}
 */
function isSubscriptionPending(purchase) {
  const state = String(
    purchase.subscriptionState || purchase.subscription_state || '',
  ).toUpperCase();
  return (
    state.includes('PENDING') && !state.includes('PENDING_PURCHASE_CANCELED')
  );
}

function isConsumableProductId(productId) {
  return (
    productId === 'qmatch.super_resonance.x1' ||
    productId === 'qmatch.boost.x1'
  );
}

function mapTrustedConsumable({
  callerUid,
  productId,
  purchase,
  purchaseToken,
  storeTransactionId,
  orderId,
  requireBinding,
}) {
  const effectiveProductId =
    purchase.productId || purchase.product_id || productId;
  const mapped = mapPlayProduct(effectiveProductId, null);
  if (!mapped.ok) {
    return failClosed(mapped.code, {
      platform: 'android',
      product_id: effectiveProductId,
    });
  }

  const binding = validateUidBinding({
    callerUid,
    storeAccountToken: extractPlayAccountBinding(purchase),
    requireBinding,
  });
  if (!binding.ok) {
    return failClosed(binding.code, { platform: 'android' });
  }

  const purchaseState = purchase.purchaseState;
  const stateNum =
    typeof purchaseState === 'number'
      ? purchaseState
      : Number.parseInt(String(purchaseState), 10);

  if (
    stateNum === PRODUCT_PURCHASE_STATE.PENDING ||
    String(purchaseState).toUpperCase() === 'PENDING'
  ) {
    return failClosed('purchase_pending', {
      platform: 'android',
      store_transaction_id: storeTransactionId,
    });
  }

  if (
    stateNum === PRODUCT_PURCHASE_STATE.CANCELED ||
    String(purchaseState).toUpperCase() === 'CANCELLED' ||
    String(purchaseState).toUpperCase() === 'CANCELED'
  ) {
    return failClosed('revoked', {
      platform: 'android',
      mapping: mapped.mapping,
      store_transaction_id: storeTransactionId,
    });
  }

  if (
    stateNum !== PRODUCT_PURCHASE_STATE.PURCHASED &&
    String(purchaseState).toUpperCase() !== 'PURCHASED' &&
    purchaseState !== undefined &&
    purchaseState !== null &&
    purchaseState !== ''
  ) {
    return failClosed('store_verification_failed', {
      platform: 'android',
      reason: 'not_purchased',
    });
  }

  const acknowledgementState = purchase.acknowledgementState;
  const needsAck =
    acknowledgementState === 0 ||
    acknowledgementState === '0' ||
    String(acknowledgementState).toUpperCase() === 'PENDING';

  return trustedVerifiedResult({
    platform: 'android',
    kind: PRODUCT_KIND.CONSUMABLE,
    mapping: mapped.mapping,
    credit: consumableCreditIntent(mapped.mapping),
    subscription_state: null,
    resonance_access: false,
    store_transaction_id: storeTransactionId,
    purchase_token: purchaseToken,
    order_id: orderId,
    original_transaction_id: storeTransactionId,
    period_ends_at: null,
    verification_source: 'play',
    acknowledgement_required: needsAck || acknowledgementState == null,
    consumption_required: true,
  });
}

function mapTrustedSubscription({
  callerUid,
  productId,
  purchase,
  purchaseToken,
  storeTransactionId,
  orderId,
  requireBinding,
}) {
  if (isSubscriptionPending(purchase)) {
    return failClosed('purchase_pending', {
      platform: 'android',
      store_transaction_id: storeTransactionId,
    });
  }

  const basePlanId = extractBasePlanId(purchase);
  const lineProduct =
    purchase.lineItems &&
    purchase.lineItems[0] &&
    purchase.lineItems[0].productId;
  const effectiveProductId =
    lineProduct ||
    purchase.productId ||
    purchase.product_id ||
    productId ||
    PLAY_SUBSCRIPTION_PRODUCT_ID;

  if (
    effectiveProductId !== PLAY_SUBSCRIPTION_PRODUCT_ID &&
    productId !== PLAY_SUBSCRIPTION_PRODUCT_ID
  ) {
    return failClosed('product_not_allowed', {
      platform: 'android',
      product_id: effectiveProductId,
      base_plan_id: basePlanId,
    });
  }

  const mapped = mapPlayProduct(PLAY_SUBSCRIPTION_PRODUCT_ID, basePlanId);
  if (!mapped.ok) {
    return failClosed(mapped.code, {
      platform: 'android',
      product_id: PLAY_SUBSCRIPTION_PRODUCT_ID,
      base_plan_id: basePlanId,
    });
  }

  const binding = validateUidBinding({
    callerUid,
    storeAccountToken: extractPlayAccountBinding(purchase),
    requireBinding,
  });
  if (!binding.ok) {
    return failClosed(binding.code, { platform: 'android' });
  }

  const subscriptionState = mapPlaySubscriptionStatus(
    purchase.subscriptionState ||
      purchase.subscription_state ||
      purchase.status ||
      'ACTIVE',
  );

  const fields = buildSubscriptionEntitlementFields({
    mapping: mapped.mapping,
    subscriptionState,
    platform: 'android',
  });

  const acknowledgementState = purchase.acknowledgementState;
  const needsAck =
    acknowledgementState === 0 ||
    acknowledgementState === '0' ||
    acknowledgementState === 'ACKNOWLEDGEMENT_STATE_PENDING' ||
    String(acknowledgementState || '').toUpperCase().includes('PENDING');

  return trustedVerifiedResult({
    platform: 'android',
    kind: PRODUCT_KIND.SUBSCRIPTION,
    mapping: mapped.mapping,
    credit: null,
    ...fields,
    store_transaction_id: storeTransactionId,
    purchase_token: purchaseToken,
    order_id: orderId,
    original_transaction_id: storeTransactionId,
    period_ends_at:
      purchase.lineItems &&
      purchase.lineItems[0] &&
      purchase.lineItems[0].expiryTime
        ? purchase.lineItems[0].expiryTime
        : purchase.expiryTimeMillis || purchase.expiryTime || null,
    verification_source: 'play',
    acknowledgement_required:
      needsAck ||
      acknowledgementState == null ||
      fields.resonance_access === true,
    consumption_required: false,
  });
}

/**
 * Map trusted Play API body → verification result.
 * purchaseToken from the client request is required for idempotency identity.
 *
 * @param {object} args
 * @returns {Record<string, unknown>}
 */
function mapTrustedPlayPurchase({
  callerUid,
  productId,
  purchaseToken,
  purchase,
  kindHint,
  requireBinding = true,
}) {
  if (!purchase || typeof purchase !== 'object') {
    return failClosed('store_verification_failed', { platform: 'android' });
  }
  if (!purchaseToken) {
    return failClosed('invalid_argument', { platform: 'android' });
  }

  const storeTransactionId = androidStoreTransactionIdFromToken(purchaseToken);
  const orderId = purchase.orderId || purchase.order_id || null;

  if (kindHint === PRODUCT_KIND.CONSUMABLE || isConsumableProductId(productId)) {
    return mapTrustedConsumable({
      callerUid,
      productId,
      purchase,
      purchaseToken,
      storeTransactionId,
      orderId,
      requireBinding,
    });
  }

  return mapTrustedSubscription({
    callerUid,
    productId,
    purchase,
    purchaseToken,
    storeTransactionId,
    orderId,
    requireBinding,
  });
}

/**
 * Verify a Google Play purchase. Fail closed without credentials/API.
 *
 * @param {object} input
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

  const resolved = await resolvePlayApiHelpers(opts);
  if (!resolved.ok) {
    return failClosedNotConfigured('android');
  }

  const kindHint =
    input.kind === PRODUCT_KIND.CONSUMABLE ||
    isConsumableProductId(input.productId)
      ? PRODUCT_KIND.CONSUMABLE
      : PRODUCT_KIND.SUBSCRIPTION;

  const packageName =
    input.packageName || resolved.config.packageName || undefined;

  let purchase = null;
  try {
    if (kindHint === PRODUCT_KIND.SUBSCRIPTION) {
      if (!resolved.helpers.fetchSubscription) {
        return failClosedNotConfigured('android');
      }
      purchase = await resolved.helpers.fetchSubscription({
        purchaseToken: input.purchaseToken,
        productId: input.productId,
        packageName,
      });
    } else {
      if (!resolved.helpers.fetchProductPurchase) {
        return failClosedNotConfigured('android');
      }
      purchase = await resolved.helpers.fetchProductPurchase({
        purchaseToken: input.purchaseToken,
        productId: input.productId,
        packageName,
      });
    }
  } catch (_err) {
    return failClosed('store_verification_failed', { platform: 'android' });
  }

  if (!purchase) {
    return failClosed('store_verification_failed', { platform: 'android' });
  }

  const purchaseWithToken = {
    ...purchase,
    purchaseToken: input.purchaseToken,
  };

  const requireBinding =
    opts.requireBinding !== undefined
      ? opts.requireBinding !== false
      : resolved.config.requireAccountBinding !== false;

  const result = mapTrustedPlayPurchase({
    callerUid,
    productId: input.productId,
    purchaseToken: input.purchaseToken,
    purchase: purchaseWithToken,
    kindHint,
    requireBinding,
  });

  if (
    result &&
    result.ok === true &&
    result.trusted === true &&
    result.verified === true &&
    result.can_grant === true
  ) {
    result._play_helpers = {
      acknowledgeSubscription: resolved.helpers.acknowledgeSubscription,
      acknowledgeProduct: resolved.helpers.acknowledgeProduct,
      consumeProduct: resolved.helpers.consumeProduct,
      packageName,
      productId: input.productId,
      purchaseToken: input.purchaseToken,
    };
  }

  return result;
}

/**
 * After successful ledger apply: consume consumables / acknowledge subscriptions.
 * Failures do not roll back ledger (retry-safe).
 *
 * @param {Record<string, unknown>} result
 * @param {object|null} [helpers]
 * @returns {Promise<{ acknowledged: boolean, consumed: boolean, error?: string }>}
 */
async function finalizePlayPurchaseSideEffects(result, helpers = null) {
  const h = helpers || result._play_helpers || {};
  const purchaseToken = result.purchase_token || h.purchaseToken;
  const productId =
    (result.mapping && result.mapping.product_id) || h.productId;
  const out = { acknowledged: false, consumed: false };

  if (!purchaseToken || !productId) {
    return { ...out, error: 'missing_token_or_product' };
  }

  try {
    if (result.kind === PRODUCT_KIND.CONSUMABLE && result.consumption_required) {
      if (typeof h.consumeProduct === 'function') {
        await h.consumeProduct({ purchaseToken, productId });
        out.consumed = true;
      }
      out.acknowledged = true;
    } else if (
      result.kind === PRODUCT_KIND.SUBSCRIPTION &&
      result.acknowledgement_required
    ) {
      if (typeof h.acknowledgeSubscription === 'function') {
        await h.acknowledgeSubscription({
          purchaseToken,
          productId: PLAY_SUBSCRIPTION_PRODUCT_ID,
        });
        out.acknowledged = true;
      }
    }
  } catch (err) {
    const msg = String((err && err.message) || err || '');
    if (/already|acked|consumed|duplicate/i.test(msg)) {
      out.acknowledged = true;
      if (result.kind === PRODUCT_KIND.CONSUMABLE) out.consumed = true;
      return out;
    }
    return { ...out, error: 'play_finalize_failed' };
  }

  return out;
}

module.exports = {
  PRODUCT_PURCHASE_STATE,
  hasPlayVerifier,
  mapTrustedPlayPurchase,
  verifyPlayPurchase,
  finalizePlayPurchaseSideEffects,
  extractBasePlanId,
  extractPlayAccountBinding,
  androidStoreTransactionIdFromToken,
};
