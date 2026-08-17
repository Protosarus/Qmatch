/**
 * Apple App Store verification v1
 * (`store_purchase_verification_contract_v1`).
 *
 * Uses official `@apple/app-store-server-library`:
 * - AppStoreServerAPIClient.getTransactionInfo / getAllSubscriptionStatuses
 * - SignedDataVerifier.verifyAndDecodeTransaction
 *
 * Dual-environment: Sandbox and Production clients/verifiers are built with
 * the same `createDualAppleAssnClients` pattern as ASSN. Try one environment,
 * then the other only on environment / verification mismatch.
 *
 * No fake verification. Fail closed without config/API/JWS.
 * Never grant unless JWS + App Store API verification succeeds.
 */

'use strict';

const {
  Status,
  Environment,
  VerificationException,
  VerificationStatus,
} = require('@apple/app-store-server-library');
const { loadAppleIapConfig } = require('./apple_iap_config');
const {
  createAppleIapClients,
  createDualAppleAssnClients,
} = require('./apple_iap_clients');
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

/** Apple Get Transaction Info: txn exists in the other environment. */
const APPLE_TRANSACTION_ID_NOT_FOUND = 4040010;
/** Apple Get Transaction Info: original txn exists in the other environment. */
const APPLE_ORIGINAL_TRANSACTION_ID_NOT_FOUND = 4040011;

/**
 * @param {object} [opts]
 * @returns {boolean}
 */
function hasAppleVerifier(opts = {}) {
  if (hasDualAppleClients(opts)) {
    return true;
  }
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
 * True when Apple rejected this environment (try the other one).
 * Not used for invalid JWS, 5xx, or uid/product failures.
 *
 * @param {unknown} err
 * @returns {boolean}
 */
function isAppleEnvironmentMismatchError(err) {
  if (!err || typeof err !== 'object') return false;
  if (
    err instanceof VerificationException &&
    err.status === VerificationStatus.INVALID_ENVIRONMENT
  ) {
    return true;
  }
  if (err.status === VerificationStatus.INVALID_ENVIRONMENT) {
    return true;
  }
  const apiError = err.apiError != null ? err.apiError : err.errorCode;
  if (
    apiError === APPLE_TRANSACTION_ID_NOT_FOUND ||
    apiError === APPLE_ORIGINAL_TRANSACTION_ID_NOT_FOUND
  ) {
    return true;
  }
  const msg = `${err.message || ''} ${apiError || ''} ${err.status || ''}`;
  if (/INVALID_ENVIRONMENT/i.test(msg)) return true;
  if (/4040010|4040011/.test(msg)) return true;
  if (/TransactionIdNotFound/i.test(msg)) return true;
  return false;
}

/**
 * @param {object} [opts]
 * @returns {boolean}
 */
function hasDualAppleClients(opts = {}) {
  const dual = opts.dualAppleClients;
  return !!(dual && dual.sandbox && dual.production);
}

/**
 * @param {object} [opts]
 * @returns {boolean}
 */
function hasSingleAppleInjectors(opts = {}) {
  return !!(
    (opts.apiClient && opts.signedDataVerifier) ||
    typeof opts.verifySignedTransaction === 'function' ||
    typeof opts.fetchTransactionInfo === 'function'
  );
}

/**
 * Dual Sandbox + Production clients, reusing the ASSN builder.
 * Single injectors (tests / already-matched ASSN client) skip dual.
 *
 * @param {object} [opts]
 * @returns {{ mode: 'dual', dual: object, preferredEnvironment?: object }|{ mode: 'single' }}
 */
function resolveDualApplePurchasePlan(opts = {}) {
  // ASSN already-matched client / unit-test injectors stay single-env.
  if (hasSingleAppleInjectors(opts)) {
    return { mode: 'single' };
  }
  if (hasDualAppleClients(opts)) {
    return {
      mode: 'dual',
      dual: opts.dualAppleClients,
      preferredEnvironment: opts.preferredEnvironment || null,
    };
  }
  const loaded = loadAppleIapConfig(opts.env || process.env);
  if (!loaded.ok) {
    return { mode: 'single' };
  }
  const built = createDualAppleAssnClients(loaded.config, opts);
  if (!built.ok) {
    return { mode: 'single' };
  }
  return {
    mode: 'dual',
    dual: built,
    preferredEnvironment:
      opts.preferredEnvironment || loaded.config.environment,
  };
}

/**
 * @param {object} dual
 * @param {string|null} [preferredEnvironment]
 * @returns {object[]}
 */
function dualEnvironmentOrder(dual, preferredEnvironment) {
  const sandbox = dual.sandbox;
  const production = dual.production;
  if (preferredEnvironment === Environment.PRODUCTION) {
    return [production, sandbox];
  }
  return [sandbox, production];
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
    bindingMode: 'apple',
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
 * JWS + App Store API fetch on one environment. Does not map/grant.
 *
 * @param {object} input
 * @param {object} helpers
 * @returns {Promise<
 *   | { status: 'ok', transaction: object }
 *   | { status: 'mismatch', stage: string }
 *   | { status: 'fail', result: Record<string, unknown> }
 * >}
 */
async function tryVerifyAppleOnEnvironment(input, helpers) {
  let clientDecoded = null;
  try {
    if (input.signedTransaction) {
      try {
        clientDecoded = await verifyJwsTransaction(
          input.signedTransaction,
          helpers,
        );
      } catch (err) {
        if (isAppleEnvironmentMismatchError(err)) {
          return { status: 'mismatch', stage: 'jws' };
        }
        return {
          status: 'fail',
          result: failClosed('invalid_jws', { platform: 'ios' }),
        };
      }
    }

    const transactionId =
      input.transactionId ||
      (clientDecoded &&
        (clientDecoded.transactionId || clientDecoded.transaction_id));

    if (!transactionId) {
      return {
        status: 'fail',
        result: failClosed('invalid_argument', { platform: 'ios' }),
      };
    }

    let transaction;
    try {
      transaction = await fetchAndVerifyTransactionInfo(transactionId, helpers);
    } catch (err) {
      if (isAppleEnvironmentMismatchError(err)) {
        return { status: 'mismatch', stage: 'api' };
      }
      return {
        status: 'fail',
        result: failClosed('store_verification_failed', { platform: 'ios' }),
      };
    }

    if (!transaction) {
      return {
        status: 'fail',
        result: failClosed('store_verification_failed', { platform: 'ios' }),
      };
    }

    if (
      clientDecoded &&
      clientDecoded.transactionId &&
      transaction.transactionId &&
      String(clientDecoded.transactionId) !== String(transaction.transactionId)
    ) {
      return {
        status: 'fail',
        result: failClosed('store_verification_failed', {
          platform: 'ios',
          reason: 'transaction_id_mismatch',
        }),
      };
    }

    return { status: 'ok', transaction };
  } catch (err) {
    if (isAppleEnvironmentMismatchError(err)) {
      return { status: 'mismatch', stage: 'unknown' };
    }
    return {
      status: 'fail',
      result: failClosed('store_verification_failed', { platform: 'ios' }),
    };
  }
}

/**
 * Map a successfully fetched Apple transaction (bundle/product/token/status).
 * @param {object} args
 * @returns {Promise<Record<string, unknown>>}
 */
async function finalizeAppleTransaction({
  callerUid,
  transaction,
  helpers,
  opts,
}) {
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
    if (
      subscriptionStatus == null &&
      statusResponse &&
      Array.isArray(statusResponse.data)
    ) {
      void Status;
    }
  }

  const result = mapTrustedAppleTransaction({
    callerUid,
    transaction,
    requireBinding: opts.requireBinding !== false,
    subscriptionStatus,
  });
  if (helpers && helpers.environment) {
    result.apple_environment = helpers.environment;
  }
  if (helpers && helpers.apiHost) {
    result.api_host = helpers.apiHost;
  }
  return result;
}

/**
 * Try Sandbox then Production (or preferred first) only on env mismatch.
 *
 * @param {object} input
 * @param {object} dual
 * @param {object} opts
 * @returns {Promise<Record<string, unknown>>}
 */
async function verifyApplePurchaseDual(input, dual, opts = {}) {
  const order = dualEnvironmentOrder(
    dual,
    opts.preferredEnvironment || null,
  );
  for (const helpers of order) {
    const attempt = await tryVerifyAppleOnEnvironment(input, helpers);
    if (attempt.status === 'ok') {
      return finalizeAppleTransaction({
        callerUid: input.callerUid,
        transaction: attempt.transaction,
        helpers,
        opts,
      });
    }
    if (attempt.status === 'fail') {
      return attempt.result;
    }
  }
  return failClosed('store_verification_failed', {
    platform: 'ios',
    reason: 'environment_mismatch',
  });
}

/**
 * Verify an Apple purchase with official library (or injected test doubles).
 *
 * Dual-environment by default when dual clients can be built. Restore uses
 * this same function. Entitlement is never granted here — only after
 * isTrustedVerified + repository apply.
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

  if (!input.signedTransaction && !input.transactionId) {
    return failClosed('invalid_argument', { platform: 'ios' });
  }

  const plan = resolveDualApplePurchasePlan(opts);
  if (plan.mode === 'dual') {
    return verifyApplePurchaseDual(input, plan.dual, {
      ...opts,
      preferredEnvironment:
        opts.preferredEnvironment || plan.preferredEnvironment || null,
    });
  }

  const resolved = resolveAppleHelpers(opts);
  if (!resolved.ok) {
    return resolved.result;
  }

  const attempt = await tryVerifyAppleOnEnvironment(input, resolved.helpers);
  if (attempt.status === 'ok') {
    return finalizeAppleTransaction({
      callerUid,
      transaction: attempt.transaction,
      helpers: resolved.helpers,
      opts,
    });
  }
  if (attempt.status === 'fail') {
    return attempt.result;
  }
  return failClosed('store_verification_failed', { platform: 'ios' });
}

module.exports = {
  APPLE_TRANSACTION_ID_NOT_FOUND,
  APPLE_ORIGINAL_TRANSACTION_ID_NOT_FOUND,
  hasAppleVerifier,
  hasDualAppleClients,
  isAppleEnvironmentMismatchError,
  mapTrustedAppleTransaction,
  verifyApplePurchase,
  inferSubscriptionStateFromTransaction,
  pickSubscriptionStatus,
  resolveAppleHelpers,
  resolveDualApplePurchasePlan,
  tryVerifyAppleOnEnvironment,
};
