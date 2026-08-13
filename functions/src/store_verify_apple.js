/**
 * Apple App Store verifier foundation
 * (`store_purchase_verification_contract_v1`).
 *
 * No fake verification. Without credentials + API/JWS verifier → fail closed.
 * Does not write entitlements. ASSN v2 not implemented here.
 */

'use strict';

const {
  mapAppleProduct,
  mapAppleSubscriptionStatus,
  buildSubscriptionEntitlementFields,
  consumableCreditIntent,
  PRODUCT_KIND,
} = require('./store_product_map');
const { validateUidBinding } = require('./store_uid_binding');
const {
  failClosedNotConfigured,
  failClosed,
  trustedVerifiedResult,
} = require('./store_verification_result');

/**
 * Detect whether Apple verification credentials / API client are available.
 * @param {object} [opts]
 * @param {object|null} [opts.credentials]
 * @param {Function|null} [opts.verifySignedTransaction] async (jws) => decoded
 * @param {Function|null} [opts.fetchTransactionInfo] async (transactionId) => decoded
 * @returns {boolean}
 */
function hasAppleVerifier(opts = {}) {
  const creds = opts.credentials;
  const hasCreds =
    creds &&
    typeof creds === 'object' &&
    !!(creds.keyId || creds.issuerId || creds.privateKey || creds.configured);
  const hasClient =
    typeof opts.verifySignedTransaction === 'function' ||
    typeof opts.fetchTransactionInfo === 'function';
  return !!(hasCreds && hasClient);
}

/**
 * Normalize a decoded Apple transaction fixture into verification result.
 * Only call after trusted decode/fetch.
 *
 * @param {object} args
 * @param {string} args.callerUid
 * @param {object} args.transaction decoded store transaction (trusted)
 * @param {boolean} [args.requireBinding=true]
 * @returns {Record<string, unknown>}
 */
function mapTrustedAppleTransaction({
  callerUid,
  transaction,
  requireBinding = true,
}) {
  if (!transaction || typeof transaction !== 'object') {
    return failClosed('store_verification_failed', { platform: 'ios' });
  }

  const productId = transaction.productId || transaction.product_id;
  const mapped = mapAppleProduct(productId);
  if (!mapped.ok) {
    return failClosed(mapped.code, {
      platform: 'ios',
      product_id: productId || null,
    });
  }

  const binding = validateUidBinding({
    callerUid,
    storeAccountToken:
      transaction.appAccountToken || transaction.app_account_token,
    requireBinding,
  });
  if (!binding.ok) {
    return failClosed(binding.code, { platform: 'ios' });
  }

  const mapping = mapped.mapping;
  const transactionId =
    transaction.transactionId || transaction.transaction_id || null;
  const originalTransactionId =
    transaction.originalTransactionId ||
    transaction.original_transaction_id ||
    transactionId;

  if (mapping.kind === PRODUCT_KIND.CONSUMABLE) {
    const revoked =
      String(transaction.revocationDate || transaction.revocation_date || '')
        .length > 0 ||
      mapAppleSubscriptionStatus(transaction.status || '') === 'revoked';
    if (revoked) {
      return failClosed('revoked', {
        platform: 'ios',
        mapping,
        store_transaction_id: transactionId,
      });
    }
    return trustedVerifiedResult({
      platform: 'ios',
      kind: PRODUCT_KIND.CONSUMABLE,
      mapping,
      credit: consumableCreditIntent(mapping),
      subscription_state: null,
      resonance_access: false,
      store_transaction_id: transactionId,
      original_transaction_id: originalTransactionId,
      period_ends_at: null,
      verification_source: 'app_store',
    });
  }

  const subscriptionState = mapAppleSubscriptionStatus(
    transaction.status || transaction.subscriptionStatus || 'active',
  );
  const fields = buildSubscriptionEntitlementFields({
    mapping,
    subscriptionState,
    platform: 'ios',
  });

  return trustedVerifiedResult({
    platform: 'ios',
    kind: PRODUCT_KIND.SUBSCRIPTION,
    mapping,
    credit: null,
    ...fields,
    store_transaction_id: transactionId,
    original_transaction_id: originalTransactionId,
    period_ends_at:
      transaction.expiresDate || transaction.expires_date || null,
    verification_source: 'app_store',
  });
}

/**
 * Verify an Apple purchase. Fail closed without credentials/API.
 *
 * @param {object} input
 * @param {string} input.callerUid
 * @param {string} [input.signedTransaction]
 * @param {string} [input.transactionId]
 * @param {object} [opts] credentials + injectors for tests
 * @returns {Promise<Record<string, unknown>>}
 */
async function verifyApplePurchase(input, opts = {}) {
  const callerUid = input && input.callerUid;
  if (!callerUid) {
    return failClosed('unauthenticated', { platform: 'ios' });
  }

  if (!hasAppleVerifier(opts)) {
    return failClosedNotConfigured('ios');
  }

  let transaction = null;
  try {
    if (input.signedTransaction && opts.verifySignedTransaction) {
      transaction = await opts.verifySignedTransaction(input.signedTransaction);
    } else if (input.transactionId && opts.fetchTransactionInfo) {
      transaction = await opts.fetchTransactionInfo(input.transactionId);
    } else {
      return failClosed('invalid_argument', { platform: 'ios' });
    }
  } catch (_err) {
    return failClosed('store_verification_failed', { platform: 'ios' });
  }

  if (!transaction) {
    return failClosed('store_verification_failed', { platform: 'ios' });
  }

  return mapTrustedAppleTransaction({
    callerUid,
    transaction,
    requireBinding: opts.requireBinding !== false,
  });
}

module.exports = {
  hasAppleVerifier,
  mapTrustedAppleTransaction,
  verifyApplePurchase,
};
