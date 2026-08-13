/**
 * Apple App Store verification v1
 * (`store_purchase_verification_contract_v1`).
 *
 * Uses official `@apple/app-store-server-library`:
 * - AppStoreServerAPIClient.getTransactionInfo / getAllSubscriptionStatuses
 * - SignedDataVerifier.verifyAndDecodeTransaction
 *
 * No fake verification. Fail closed without config/API/JWS.
 * ASSN v2 not implemented here.
 */

'use strict';

const { Status } = require('@apple/app-store-server-library');
const { loadAppleIapConfig } = require('./apple_iap_config');
const { createAppleIapClients } = require('./apple_iap_clients');
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
 * @param {object} [opts]
 * @returns {boolean}
 */
function hasAppleVerifier(opts = {}) {
  if (
    typeof opts.verifySignedTransaction === 'function' ||
    typeof opts.fetchTransactionInfo === 'function' ||
    (opts.apiClient && opts.signedDataVerifier)
  ) {
    if (opts.credentials && opts.credentials.configured === false) {
      return false;
    }
    // Injected clients/verifiers for tests, or explicit credentials flag.
    if (opts.apiClient && opts.signedDataVerifier) return true;
    if (
      typeof opts.verifySignedTransaction === 'function' ||
      typeof opts.fetchTransactionInfo === 'function'
    ) {
      const creds = opts.credentials;
      return !!(
        creds &&
        (creds.configured ||
          creds.keyId ||
          creds.issuerId ||
          creds.privateKey)
      );
    }
  }

  const loaded = loadAppleIapConfig(opts.env || process.env);
  return loaded.ok === true;
}

/**
 * Infer subscription_state from transaction fields when Status API unavailable.
 * @param {object} transaction
 * @param {number} [nowMs]
 * @returns {string}
 */
function inferSubscriptionStateFromTransaction(transaction, nowMs = Date.now()) {
  if (transaction.revocationDate || transaction.revocation_date) {
    return 'revoked';
  }
  const expires =
    transaction.expiresDate ||
    transaction.expires_date ||
    transaction.expiresDateMs;
  if (expires != null) {
    const expMs = typeof expires === 'number' ? expires : Number(expires);
    if (Number.isFinite(expMs) && expMs < nowMs) {
      return 'expired';
    }
  }
  if (transaction.status != null || transaction.subscriptionStatus != null) {
    const mapped = mapAppleSubscriptionStatus(
      transaction.status != null
        ? transaction.status
        : transaction.subscriptionStatus,
    );
    if (mapped !== 'none') return mapped;
  }
  return 'active';
}

/**
 * Pick best Status from getAllSubscriptionStatuses response.
 * @param {object|null} statusResponse
 * @param {string|null} productId
 * @returns {number|string|null}
 */
function pickSubscriptionStatus(statusResponse, productId) {
  if (!statusResponse || !Array.isArray(statusResponse.data)) return null;
  for (const group of statusResponse.data) {
    const last = Array.isArray(group.lastTransactions)
      ? group.lastTransactions
      : [];
    for (const item of last) {
      if (productId && item.productId && item.productId !== productId) {
        continue;
      }
      if (item.status != null) return item.status;
    }
    // If no product filter match, still take first status in group.
    if (last[0] && last[0].status != null) return last[0].status;
  }
  return null;
}

/**
 * Normalize a decoded Apple transaction into verification result.
 * Only call after trusted decode/fetch.
 *
 * @param {object} args
 * @returns {Record<string, unknown>}
 */
function mapTrustedAppleTransaction({
  callerUid,
  transaction,
  requireBinding = true,
  subscriptionStatus = null,
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

  let subscriptionState;
  if (subscriptionStatus != null) {
    subscriptionState = mapAppleSubscriptionStatus(subscriptionStatus);
  } else {
    subscriptionState = inferSubscriptionStateFromTransaction(transaction);
  }
  // Explicit: revoked/expired must not report access grant.
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
    apple_status: subscriptionStatus,
  });
}

/**
 * Build real Apple API + JWS helpers from config (or use injected opts).
 * @param {object} opts
 * @returns {{ ok: true, helpers: object }|{ ok: false, result: object }}
 */
function resolveAppleHelpers(opts = {}) {
  if (opts.apiClient && opts.signedDataVerifier) {
    return {
      ok: true,
      helpers: {
        apiClient: opts.apiClient,
        signedDataVerifier: opts.signedDataVerifier,
      },
    };
  }

  if (
    typeof opts.verifySignedTransaction === 'function' ||
    typeof opts.fetchTransactionInfo === 'function'
  ) {
    if (!hasAppleVerifier(opts)) {
      return { ok: false, result: failClosedNotConfigured('ios') };
    }
    return {
      ok: true,
      helpers: {
        verifySignedTransaction: opts.verifySignedTransaction,
        fetchTransactionInfo: opts.fetchTransactionInfo,
        fetchSubscriptionStatuses: opts.fetchSubscriptionStatuses,
      },
    };
  }

  const loaded = loadAppleIapConfig(opts.env || process.env);
  if (!loaded.ok) {
    return { ok: false, result: failClosedNotConfigured('ios') };
  }

  try {
    const clients = createAppleIapClients(loaded.config, opts);
    return { ok: true, helpers: clients };
  } catch (_err) {
    return { ok: false, result: failClosedNotConfigured('ios') };
  }
}

/**
 * Verify + decode a JWS transaction string.
 * @param {string} signedTransaction
 * @param {object} helpers
 */
async function verifyJwsTransaction(signedTransaction, helpers) {
  if (helpers.verifySignedTransaction) {
    return helpers.verifySignedTransaction(signedTransaction);
  }
  if (helpers.signedDataVerifier) {
    return helpers.signedDataVerifier.verifyAndDecodeTransaction(
      signedTransaction,
    );
  }
  throw new Error('jws_verifier_unavailable');
}

/**
 * Fetch authoritative transaction JWS from Apple and verify it.
 * @param {string} transactionId
 * @param {object} helpers
 */
async function fetchAndVerifyTransactionInfo(transactionId, helpers) {
  if (helpers.fetchTransactionInfo) {
    return helpers.fetchTransactionInfo(transactionId);
  }
  if (!helpers.apiClient || !helpers.signedDataVerifier) {
    throw new Error('apple_api_unavailable');
  }
  const response = await helpers.apiClient.getTransactionInfo(transactionId);
  if (!response || !response.signedTransactionInfo) {
    throw new Error('apple_transaction_info_empty');
  }
  return helpers.signedDataVerifier.verifyAndDecodeTransaction(
    response.signedTransactionInfo,
  );
}

/**
 * @param {string} originalTransactionId
 * @param {object} helpers
 */
async function fetchSubscriptionStatuses(originalTransactionId, helpers) {
  if (helpers.fetchSubscriptionStatuses) {
    return helpers.fetchSubscriptionStatuses(originalTransactionId);
  }
  if (!helpers.apiClient) return null;
  try {
    return await helpers.apiClient.getAllSubscriptionStatuses(
      originalTransactionId,
    );
  } catch (_err) {
    // Status enrichment is best-effort; transaction revoke/expiry still applied.
    return null;
  }
}

/**
 * Verify an Apple purchase with official library (or injected test doubles).
 *
 * @param {object} input
 * @param {string} input.callerUid
 * @param {string} [input.signedTransaction]
 * @param {string} [input.transactionId]
 * @param {object} [opts]
 * @returns {Promise<Record<string, unknown>>}
 */
async function verifyApplePurchase(input, opts = {}) {
  const callerUid = input && input.callerUid;
  if (!callerUid) {
    return failClosed('unauthenticated', { platform: 'ios' });
  }

  const resolved = resolveAppleHelpers(opts);
  if (!resolved.ok) {
    return resolved.result;
  }
  const helpers = resolved.helpers;

  if (!input.signedTransaction && !input.transactionId) {
    return failClosed('invalid_argument', { platform: 'ios' });
  }

  let clientDecoded = null;
  let transaction = null;

  try {
    // Always verify client-supplied JWS if present (reject invalid JWS).
    if (input.signedTransaction) {
      try {
        clientDecoded = await verifyJwsTransaction(
          input.signedTransaction,
          helpers,
        );
      } catch (_err) {
        return failClosed('invalid_jws', { platform: 'ios' });
      }
    }

    const transactionId =
      input.transactionId ||
      (clientDecoded &&
        (clientDecoded.transactionId || clientDecoded.transaction_id));

    if (!transactionId) {
      return failClosed('invalid_argument', { platform: 'ios' });
    }

    // Authoritative fetch from Apple API + JWS verify of response.
    try {
      transaction = await fetchAndVerifyTransactionInfo(transactionId, helpers);
    } catch (_err) {
      return failClosed('store_verification_failed', { platform: 'ios' });
    }

    if (
      clientDecoded &&
      clientDecoded.transactionId &&
      transaction.transactionId &&
      String(clientDecoded.transactionId) !== String(transaction.transactionId)
    ) {
      return failClosed('store_verification_failed', {
        platform: 'ios',
        reason: 'transaction_id_mismatch',
      });
    }
  } catch (_err) {
    return failClosed('store_verification_failed', { platform: 'ios' });
  }

  if (!transaction) {
    return failClosed('store_verification_failed', { platform: 'ios' });
  }

  let subscriptionStatus = null;
  const mappedProduct = mapAppleProduct(
    transaction.productId || transaction.product_id,
  );
  if (mappedProduct.ok && mappedProduct.mapping.kind === PRODUCT_KIND.SUBSCRIPTION) {
    const originalId =
      transaction.originalTransactionId ||
      transaction.original_transaction_id ||
      transaction.transactionId;
    const statusResponse = await fetchSubscriptionStatuses(originalId, helpers);
    subscriptionStatus = pickSubscriptionStatus(
      statusResponse,
      transaction.productId,
    );
    // Map library Status constants if present on lastTransactions items.
    if (
      subscriptionStatus == null &&
      statusResponse &&
      Array.isArray(statusResponse.data)
    ) {
      // Fallback: if only Status.ACTIVE style available via enum compare later.
      void Status;
    }
  }

  return mapTrustedAppleTransaction({
    callerUid,
    transaction,
    requireBinding: opts.requireBinding !== false,
    subscriptionStatus,
  });
}

module.exports = {
  hasAppleVerifier,
  mapTrustedAppleTransaction,
  verifyApplePurchase,
  inferSubscriptionStateFromTransaction,
  pickSubscriptionStatus,
  resolveAppleHelpers,
};
