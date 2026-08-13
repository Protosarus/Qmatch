/**
 * Apple App Store Server Notifications v2 handler foundation.
 *
 * Verify signedPayload → dedupe notificationUUID → resolve uid →
 * re-fetch authoritative Apple state → apply entitlement (idempotent).
 *
 * Dual-environment: Sandbox and Production SignedDataVerifier instances are
 * both tried. Only a cryptographically verified match selects the API client.
 */

'use strict';

const {
  NotificationTypeV2,
  Environment,
} = require('@apple/app-store-server-library');
const { loadAppleIapConfig } = require('./apple_iap_config');
const {
  createDualAppleAssnClients,
} = require('./apple_iap_clients');
const { verifyApplePurchase } = require('./store_verify_apple');
const {
  applyTrustedVerificationResult,
} = require('./apply_trusted_verification');
const {
  subscriptionEventLedgerId,
} = require('./entitlement_ledger');
const {
  appleOriginalIndexId,
  lookupPurchaseIndex,
} = require('./store_purchase_index');
const {
  failClosedNotConfigured,
  failClosed,
  isTrustedVerified,
} = require('./store_verification_result');
const { mapAppleProduct } = require('./store_product_map');

/** Notification types that should drive entitlement lifecycle updates. */
const HANDLED_TYPES = new Set([
  NotificationTypeV2.DID_RENEW,
  NotificationTypeV2.EXPIRED,
  NotificationTypeV2.DID_FAIL_TO_RENEW,
  NotificationTypeV2.GRACE_PERIOD_EXPIRED,
  NotificationTypeV2.REFUND,
  NotificationTypeV2.REVOKE,
  NotificationTypeV2.SUBSCRIBED,
  NotificationTypeV2.OFFER_REDEEMED,
  NotificationTypeV2.RENEWAL_EXTENDED,
]);

/**
 * Map ASSN type → expected lifecycle hint (authoritative state still re-fetched).
 * @param {string} notificationType
 * @returns {string|null}
 */
function mapAssnTypeToLifecycleHint(notificationType) {
  switch (notificationType) {
    case NotificationTypeV2.DID_RENEW:
    case NotificationTypeV2.SUBSCRIBED:
    case NotificationTypeV2.OFFER_REDEEMED:
    case NotificationTypeV2.RENEWAL_EXTENDED:
      return 'renew';
    case NotificationTypeV2.EXPIRED:
    case NotificationTypeV2.GRACE_PERIOD_EXPIRED:
      return 'expire';
    case NotificationTypeV2.DID_FAIL_TO_RENEW:
      return 'billing_or_grace';
    case NotificationTypeV2.REFUND:
    case NotificationTypeV2.REVOKE:
      return 'revoke';
    default:
      return null;
  }
}

/**
 * Try one SignedDataVerifier; never treat decode-without-verify as success.
 * @param {object} signedDataVerifier
 * @param {string} signedPayload
 * @returns {Promise<{ ok: true, decoded: object }|{ ok: false }>}
 */
async function tryVerifyNotification(signedDataVerifier, signedPayload) {
  if (
    !signedDataVerifier ||
    typeof signedDataVerifier.verifyAndDecodeNotification !== 'function'
  ) {
    return { ok: false };
  }
  try {
    const decoded = await signedDataVerifier.verifyAndDecodeNotification(
      signedPayload,
    );
    if (!decoded) return { ok: false };
    return { ok: true, decoded };
  } catch (_err) {
    return { ok: false };
  }
}

/**
 * Verify ASSN signedPayload against Sandbox and Production verifiers.
 * Environment is selected only from which verifier cryptographically accepts.
 *
 * @param {string} signedPayload
 * @param {object} [opts]
 * @returns {Promise<object>}
 */
async function verifyAssnSignedPayload(signedPayload, opts = {}) {
  if (typeof opts.verifyAssnDual === 'function') {
    return opts.verifyAssnDual(signedPayload);
  }

  // Legacy single injector (existing foundation tests).
  if (typeof opts.verifyAndDecodeNotification === 'function') {
    try {
      const decoded = await opts.verifyAndDecodeNotification(signedPayload);
      return {
        ok: true,
        decoded,
        environment: opts.assnEnvironment || Environment.SANDBOX,
        apiClient: opts.apiClient || null,
        signedDataVerifier: opts.signedDataVerifier || null,
        apiHost: opts.apiHost || null,
      };
    } catch (_err) {
      return { ok: false, code: 'invalid_jws' };
    }
  }

  let dual = opts.dualAppleClients || null;
  if (!dual) {
    const loaded = loadAppleIapConfig(opts.env || process.env);
    if (!loaded.ok) {
      return { ok: false, code: 'verification_not_configured' };
    }
    const built = createDualAppleAssnClients(loaded.config, opts);
    if (!built.ok) {
      return { ok: false, code: 'verification_not_configured' };
    }
    dual = built;
  }

  if (!dual.sandbox || !dual.production) {
    return { ok: false, code: 'verification_not_configured' };
  }

  const sandboxTry = await tryVerifyNotification(
    dual.sandbox.signedDataVerifier,
    signedPayload,
  );
  const productionTry = await tryVerifyNotification(
    dual.production.signedDataVerifier,
    signedPayload,
  );

  if (sandboxTry.ok && !productionTry.ok) {
    return {
      ok: true,
      decoded: sandboxTry.decoded,
      environment: Environment.SANDBOX,
      apiClient: dual.sandbox.apiClient,
      signedDataVerifier: dual.sandbox.signedDataVerifier,
      apiHost: dual.sandbox.apiHost || null,
    };
  }
  if (productionTry.ok && !sandboxTry.ok) {
    return {
      ok: true,
      decoded: productionTry.decoded,
      environment: Environment.PRODUCTION,
      apiClient: dual.production.apiClient,
      signedDataVerifier: dual.production.signedDataVerifier,
      apiHost: dual.production.apiHost || null,
    };
  }

  // Both failed, or ambiguous both-succeeded (should not happen for real Apple JWS).
  return { ok: false, code: 'invalid_jws' };
}

/**
 * Decode signedTransactionInfo from notification data when present.
 * @param {object} decodedNotification
 * @param {object} opts
 * @param {object} [matched]
 */
async function decodeNotificationTransaction(
  decodedNotification,
  opts,
  matched = null,
) {
  const signed =
    decodedNotification &&
    decodedNotification.data &&
    decodedNotification.data.signedTransactionInfo;
  if (!signed) return null;
  if (typeof opts.verifySignedTransaction === 'function') {
    return opts.verifySignedTransaction(signed);
  }
  const verifier =
    (matched && matched.signedDataVerifier) || opts.signedDataVerifier;
  if (verifier && typeof verifier.verifyAndDecodeTransaction === 'function') {
    return verifier.verifyAndDecodeTransaction(signed);
  }
  return null;
}

/**
 * Handle one ASSN v2 signedPayload.
 *
 * @param {object} input
 * @param {string} input.signedPayload
 * @param {object} [opts] injectors for tests + db
 * @returns {Promise<Record<string, unknown>>}
 */
async function handleAppleAssnNotification(input, opts = {}) {
  if (!input || !input.signedPayload) {
    return failClosed('invalid_argument', { platform: 'ios' });
  }

  const verified = await verifyAssnSignedPayload(input.signedPayload, opts);
  if (!verified.ok) {
    if (verified.code === 'verification_not_configured') {
      return failClosedNotConfigured('ios');
    }
    return failClosed('invalid_jws', { platform: 'ios', source: 'assn' });
  }

  const decoded = verified.decoded;
  if (!decoded || !decoded.notificationUUID) {
    return failClosed('invalid_argument', {
      platform: 'ios',
      reason: 'missing_notification_uuid',
    });
  }

  const notificationType = decoded.notificationType;
  const notificationUUID = String(decoded.notificationUUID);
  const lifecycleHint = mapAssnTypeToLifecycleHint(notificationType);
  const appleEnvironment = verified.environment;

  if (notificationType === NotificationTypeV2.TEST) {
    return {
      ok: true,
      trusted: true,
      verified: true,
      can_grant: false,
      code: 'assn_test_ack',
      processed: false,
      notification_uuid: notificationUUID,
      platform: 'ios',
      apple_environment: appleEnvironment,
      api_host: verified.apiHost || null,
    };
  }

  if (!HANDLED_TYPES.has(notificationType)) {
    return {
      ok: true,
      trusted: true,
      verified: true,
      can_grant: false,
      code: 'assn_ignored_type',
      processed: false,
      notification_type: notificationType,
      notification_uuid: notificationUUID,
      platform: 'ios',
      apple_environment: appleEnvironment,
      api_host: verified.apiHost || null,
    };
  }

  let txHint = await decodeNotificationTransaction(decoded, opts, verified);
  const transactionId =
    (txHint && (txHint.transactionId || txHint.transaction_id)) ||
    (decoded.data && decoded.data.transactionId) ||
    null;
  const originalTransactionId =
    (txHint &&
      (txHint.originalTransactionId || txHint.original_transaction_id)) ||
    (decoded.data && decoded.data.originalTransactionId) ||
    null;

  if (!transactionId && !originalTransactionId) {
    return failClosed('invalid_argument', {
      platform: 'ios',
      reason: 'missing_transaction_identity',
    });
  }

  if (txHint && (txHint.productId || txHint.product_id)) {
    const mapped = mapAppleProduct(txHint.productId || txHint.product_id);
    if (!mapped.ok) {
      return failClosed('product_not_allowed', {
        platform: 'ios',
        product_id: txHint.productId || txHint.product_id,
      });
    }
  }

  let uid =
    (txHint && (txHint.appAccountToken || txHint.app_account_token)) || null;
  if (!uid && originalTransactionId) {
    const indexed = await lookupPurchaseIndex(
      appleOriginalIndexId(String(originalTransactionId)),
      { db: opts.db },
    );
    uid = indexed && indexed.uid;
  }
  if (!uid) {
    return failClosed('unknown_uid', {
      platform: 'ios',
      original_transaction_id: originalTransactionId,
    });
  }

  // Authoritative re-fetch with the environment-matched API client only.
  // Test injectors (fetchTransactionInfo / verifySignedTransaction) take
  // precedence so matched clients do not shadow them in resolveAppleHelpers.
  const useInjectedFetch =
    typeof opts.fetchTransactionInfo === 'function' ||
    typeof opts.verifySignedTransaction === 'function';
  const verifyResult = await verifyApplePurchase(
    {
      callerUid: String(uid),
      transactionId: String(transactionId || originalTransactionId),
      signedTransaction:
        decoded.data && decoded.data.signedTransactionInfo
          ? decoded.data.signedTransactionInfo
          : undefined,
    },
    {
      ...(opts.apple || {}),
      credentials: (opts.apple && opts.apple.credentials) || {
        configured: true,
      },
      ...(useInjectedFetch
        ? {
            verifySignedTransaction: opts.verifySignedTransaction,
            fetchTransactionInfo: opts.fetchTransactionInfo,
            fetchSubscriptionStatuses: opts.fetchSubscriptionStatuses,
          }
        : {
            apiClient: verified.apiClient || opts.apiClient,
            signedDataVerifier:
              verified.signedDataVerifier || opts.signedDataVerifier,
          }),
      env: opts.env,
      requireBinding: false,
    },
  );

  if (!isTrustedVerified(verifyResult)) {
    return {
      ...verifyResult,
      notification_uuid: notificationUUID,
      notification_type: notificationType,
      lifecycle_hint: lifecycleHint,
      apple_environment: appleEnvironment,
      api_host: verified.apiHost || null,
      source: 'assn',
    };
  }

  if (
    lifecycleHint === 'revoke' &&
    verifyResult.resonance_access === true &&
    opts.forceRevokeOnAssnSignal
  ) {
    verifyResult.subscription_state = 'revoked';
    verifyResult.tier = 'free';
    verifyResult.resonance_access = false;
  }

  verifyResult.verification_source = 'webhook';

  const ledgerId = subscriptionEventLedgerId(
    'ios',
    String(originalTransactionId || transactionId),
    String(notificationType),
    notificationUUID,
  );

  const applyOut = await applyTrustedVerificationResult(
    String(uid),
    verifyResult,
    {
      db: opts.db,
      ledgerIdOverride: ledgerId,
      skipPlayFinalize: true,
    },
  );

  return {
    ok: true,
    trusted: true,
    verified: true,
    can_grant: true,
    code: 'assn_processed',
    platform: 'ios',
    uid: String(uid),
    notification_uuid: notificationUUID,
    notification_type: notificationType,
    lifecycle_hint: lifecycleHint,
    apple_environment: appleEnvironment,
    api_host: verified.apiHost || null,
    repository_applied: !!applyOut.applied,
    apply_status: applyOut.status || null,
    resonance_access: !!(
      applyOut.snapshot && applyOut.snapshot.resonance_access
    ),
    ledger_id: ledgerId,
    source: 'assn',
  };
}

module.exports = {
  HANDLED_TYPES,
  mapAssnTypeToLifecycleHint,
  tryVerifyNotification,
  verifyAssnSignedPayload,
  handleAppleAssnNotification,
};
