/**
 * Apple App Store Server Notifications v2 handler foundation.
 *
 * Verify signedPayload → dedupe notificationUUID → resolve uid →
 * re-fetch authoritative Apple state → apply entitlement (idempotent).
 */

'use strict';

const { NotificationTypeV2 } = require('@apple/app-store-server-library');
const { loadAppleIapConfig } = require('./apple_iap_config');
const { createAppleIapClients } = require('./apple_iap_clients');
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
 * @param {object} [opts]
 */
function resolveAppleNotificationVerifier(opts = {}) {
  if (typeof opts.verifyAndDecodeNotification === 'function') {
    return {
      ok: true,
      verifyAndDecodeNotification: opts.verifyAndDecodeNotification,
    };
  }
  if (opts.signedDataVerifier) {
    return {
      ok: true,
      verifyAndDecodeNotification: (payload) =>
        opts.signedDataVerifier.verifyAndDecodeNotification(payload),
    };
  }
  const loaded = loadAppleIapConfig(opts.env || process.env);
  if (!loaded.ok) {
    return { ok: false };
  }
  try {
    const { signedDataVerifier } = createAppleIapClients(loaded.config, opts);
    return {
      ok: true,
      verifyAndDecodeNotification: (payload) =>
        signedDataVerifier.verifyAndDecodeNotification(payload),
    };
  } catch (_err) {
    return { ok: false };
  }
}

/**
 * Decode signedTransactionInfo from notification data when present.
 * @param {object} decodedNotification
 * @param {object} opts
 */
async function decodeNotificationTransaction(decodedNotification, opts) {
  const signed =
    decodedNotification &&
    decodedNotification.data &&
    decodedNotification.data.signedTransactionInfo;
  if (!signed) return null;
  if (typeof opts.verifySignedTransaction === 'function') {
    return opts.verifySignedTransaction(signed);
  }
  if (opts.signedDataVerifier) {
    return opts.signedDataVerifier.verifyAndDecodeTransaction(signed);
  }
  // Fall through: verifyApplePurchase will fetch by transactionId if provided.
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

  const verifier = resolveAppleNotificationVerifier(opts);
  if (!verifier.ok) {
    return failClosedNotConfigured('ios');
  }

  let decoded;
  try {
    decoded = await verifier.verifyAndDecodeNotification(input.signedPayload);
  } catch (_err) {
    return failClosed('invalid_jws', { platform: 'ios', source: 'assn' });
  }

  if (!decoded || !decoded.notificationUUID) {
    return failClosed('invalid_argument', {
      platform: 'ios',
      reason: 'missing_notification_uuid',
    });
  }

  const notificationType = decoded.notificationType;
  const notificationUUID = String(decoded.notificationUUID);
  const lifecycleHint = mapAssnTypeToLifecycleHint(notificationType);

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
    };
  }

  let txHint = await decodeNotificationTransaction(decoded, opts);
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

  // Product allowlist check on notification-decoded product when available.
  if (txHint && (txHint.productId || txHint.product_id)) {
    const mapped = mapAppleProduct(txHint.productId || txHint.product_id);
    if (!mapped.ok) {
      return failClosed('product_not_allowed', {
        platform: 'ios',
        product_id: txHint.productId || txHint.product_id,
      });
    }
  }

  // Resolve uid: prefer appAccountToken, else purchase index.
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

  // Authoritative re-fetch — never mutate from notification fields alone.
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
      verifySignedTransaction: opts.verifySignedTransaction,
      fetchTransactionInfo: opts.fetchTransactionInfo,
      fetchSubscriptionStatuses: opts.fetchSubscriptionStatuses,
      apiClient: opts.apiClient,
      signedDataVerifier: opts.signedDataVerifier,
      env: opts.env,
      requireBinding: false, // uid already resolved via token/index
    },
  );

  if (!isTrustedVerified(verifyResult)) {
    // API failure / invalid product after re-fetch → fail closed
    return {
      ...verifyResult,
      notification_uuid: notificationUUID,
      notification_type: notificationType,
      lifecycle_hint: lifecycleHint,
      source: 'assn',
    };
  }

  // Force revoke semantics when ASSN says REFUND/REVOKE and re-fetch still
  // returned access (edge race): prefer store revoke signal only if re-fetch
  // already denies OR status is revoked. Otherwise trust re-fetch.
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
  handleAppleAssnNotification,
};
