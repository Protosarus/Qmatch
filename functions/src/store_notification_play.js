/**
 * Google Play Real-time Developer Notifications (RTDN) handler foundation.
 *
 * Pub/Sub message is a signal only — always re-fetch via Play verifier.
 */

'use strict';

const { verifyPlayPurchase, hasPlayVerifier } = require('./store_verify_play');
const {
  applyTrustedVerificationResult,
} = require('./apply_trusted_verification');
const {
  subscriptionEventLedgerId,
  androidStoreTransactionIdFromToken,
} = require('./entitlement_ledger');
const {
  androidTokenIndexId,
  lookupPurchaseIndex,
} = require('./store_purchase_index');
const {
  failClosedNotConfigured,
  failClosed,
  isTrustedVerified,
} = require('./store_verification_result');
const { STORE_PRODUCT_IDS } = require('./entitlement_schema');
const { PRODUCT_KIND } = require('./store_product_map');

/** subscriptionNotification.notificationType codes (Play docs). */
const SUB_NOTIFICATION = Object.freeze({
  RECOVERED: 1,
  RENEWED: 2,
  CANCELED: 3,
  PURCHASED: 4,
  ON_HOLD: 5,
  IN_GRACE_PERIOD: 6,
  RESTARTED: 7,
  PRICE_CHANGE_CONFIRMED: 8,
  DEFERRED: 9,
  PAUSED: 10,
  PAUSE_SCHEDULE_CHANGED: 11,
  REVOKED: 12,
  EXPIRED: 13,
});

const ONE_TIME_NOTIFICATION = Object.freeze({
  PURCHASED: 1,
  CANCELED: 2,
});

/**
 * @param {number} notificationType
 * @returns {string|null}
 */
function mapRtdnSubscriptionLifecycleHint(notificationType) {
  switch (Number(notificationType)) {
    case SUB_NOTIFICATION.RECOVERED:
    case SUB_NOTIFICATION.RENEWED:
    case SUB_NOTIFICATION.PURCHASED:
    case SUB_NOTIFICATION.RESTARTED:
      return 'renew';
    case SUB_NOTIFICATION.IN_GRACE_PERIOD:
    case SUB_NOTIFICATION.ON_HOLD:
      return 'billing_or_grace';
    case SUB_NOTIFICATION.EXPIRED:
    case SUB_NOTIFICATION.CANCELED:
      return 'expire';
    case SUB_NOTIFICATION.REVOKED:
      return 'revoke';
    default:
      return null;
  }
}

/**
 * Parse Pub/Sub push / Eventarc-style body into developer notification JSON.
 * @param {object|string} input
 * @returns {{ ok: true, messageId: string, notification: object }|{ ok: false, code: string }}
 */
function parseRtdnPubSubInput(input) {
  if (!input) {
    return { ok: false, code: 'invalid_argument' };
  }

  if (input.developerNotification && input.messageId) {
    return {
      ok: true,
      messageId: String(input.messageId),
      notification: input.developerNotification,
    };
  }

  const message = input.message || input;
  const messageId = message.messageId || message.message_id || input.messageId;
  if (!messageId) {
    return { ok: false, code: 'invalid_argument' };
  }

  let notification = input.developerNotification || null;
  if (!notification && message.data) {
    try {
      const raw =
        typeof message.data === 'string'
          ? Buffer.from(message.data, 'base64').toString('utf8')
          : null;
      notification = raw ? JSON.parse(raw) : null;
    } catch (_err) {
      return { ok: false, code: 'invalid_message' };
    }
  }

  if (!notification || typeof notification !== 'object') {
    return { ok: false, code: 'invalid_message' };
  }

  return {
    ok: true,
    messageId: String(messageId),
    notification,
  };
}

function playVerifierAvailable(opts) {
  if (opts.play && opts.play.credentials && opts.play.credentials.configured) {
    return !!(
      opts.play.fetchSubscription || opts.play.fetchProductPurchase
    );
  }
  return hasPlayVerifier(opts.play || opts);
}

/**
 * Handle one RTDN Pub/Sub notification.
 *
 * @param {object} input Pub/Sub body or { messageId, developerNotification }
 * @param {object} [opts]
 * @returns {Promise<Record<string, unknown>>}
 */
async function handlePlayRtdnNotification(input, opts = {}) {
  if (!playVerifierAvailable(opts)) {
    return failClosedNotConfigured('android');
  }

  const parsed = parseRtdnPubSubInput(input);
  if (!parsed.ok) {
    return failClosed(parsed.code, { platform: 'android', source: 'rtdn' });
  }

  const { messageId, notification } = parsed;
  const packageName =
    notification.packageName ||
    (opts.play && opts.play.packageName) ||
    undefined;

  const sub = notification.subscriptionNotification;
  const oneTime = notification.oneTimeProductNotification;
  const voided = notification.voidedPurchaseNotification;

  let purchaseToken = null;
  let productId = null;
  let kind = PRODUCT_KIND.SUBSCRIPTION;
  let lifecycleHint = null;
  let eventType = 'rtdn';

  if (sub) {
    purchaseToken = sub.purchaseToken;
    productId = STORE_PRODUCT_IDS.PLAY_RESONANCE;
    kind = PRODUCT_KIND.SUBSCRIPTION;
    lifecycleHint = mapRtdnSubscriptionLifecycleHint(sub.notificationType);
    eventType = `sub_${sub.notificationType}`;
    if (lifecycleHint == null) {
      return {
        ok: true,
        trusted: true,
        verified: true,
        can_grant: false,
        code: 'rtdn_ignored_type',
        processed: false,
        message_id: messageId,
        platform: 'android',
      };
    }
  } else if (oneTime) {
    purchaseToken = oneTime.purchaseToken;
    productId = oneTime.sku;
    kind = PRODUCT_KIND.CONSUMABLE;
    eventType = `otp_${oneTime.notificationType}`;
    if (Number(oneTime.notificationType) === ONE_TIME_NOTIFICATION.CANCELED) {
      return {
        ok: true,
        trusted: true,
        verified: true,
        can_grant: false,
        code: 'rtdn_otp_canceled',
        processed: false,
        message_id: messageId,
        platform: 'android',
      };
    }
    if (
      productId !== STORE_PRODUCT_IDS.SUPER_RESONANCE_X1 &&
      productId !== STORE_PRODUCT_IDS.BOOST_X1
    ) {
      return failClosed('product_not_allowed', {
        platform: 'android',
        product_id: productId,
        source: 'rtdn',
      });
    }
  } else if (voided) {
    purchaseToken = voided.purchaseToken;
    productId =
      voided.productType === 1
        ? STORE_PRODUCT_IDS.PLAY_RESONANCE
        : voided.sku || null;
    kind =
      voided.productType === 1
        ? PRODUCT_KIND.SUBSCRIPTION
        : PRODUCT_KIND.CONSUMABLE;
    lifecycleHint = 'revoke';
    eventType = 'voided';
  } else {
    return {
      ok: true,
      trusted: true,
      verified: true,
      can_grant: false,
      code: 'rtdn_ignored_payload',
      processed: false,
      message_id: messageId,
      platform: 'android',
    };
  }

  if (!purchaseToken) {
    return failClosed('invalid_argument', {
      platform: 'android',
      reason: 'missing_purchase_token',
    });
  }

  const indexed = await lookupPurchaseIndex(androidTokenIndexId(purchaseToken), {
    db: opts.db,
  });
  if (!indexed || !indexed.uid) {
    return failClosed('unknown_uid', {
      platform: 'android',
      purchase_token_fingerprint: androidStoreTransactionIdFromToken(
        purchaseToken,
      ),
      source: 'rtdn',
    });
  }
  const uid = String(indexed.uid);

  // Authoritative re-fetch — never mutate from RTDN fields alone.
  const trusted = await verifyPlayPurchase(
    {
      callerUid: uid,
      purchaseToken,
      productId:
        productId ||
        (kind === PRODUCT_KIND.SUBSCRIPTION
          ? STORE_PRODUCT_IDS.PLAY_RESONANCE
          : null),
      packageName,
      kind,
    },
    {
      ...(opts.play || {}),
      credentials: (opts.play && opts.play.credentials) || { configured: true },
      requireBinding: false,
    },
  );

  if (!isTrustedVerified(trusted)) {
    return {
      ...trusted,
      message_id: messageId,
      lifecycle_hint: lifecycleHint,
      source: 'rtdn',
    };
  }

  trusted.verification_source = 'webhook';

  const tokenKey = androidStoreTransactionIdFromToken(purchaseToken);
  const ledgerId = subscriptionEventLedgerId(
    'android',
    tokenKey,
    eventType,
    messageId,
  );

  const playHelpers = trusted._play_helpers;
  if (trusted._play_helpers) delete trusted._play_helpers;

  const applyOut = await applyTrustedVerificationResult(uid, trusted, {
    db: opts.db,
    ledgerIdOverride: ledgerId,
    playFinalizeHelpers: opts.playFinalizeHelpers || playHelpers || null,
  });

  return {
    ok: true,
    trusted: true,
    verified: true,
    can_grant: true,
    code: 'rtdn_processed',
    platform: 'android',
    uid,
    message_id: messageId,
    lifecycle_hint: lifecycleHint,
    repository_applied: !!applyOut.applied,
    apply_status: applyOut.status || null,
    resonance_access: !!(
      applyOut.snapshot && applyOut.snapshot.resonance_access
    ),
    ledger_id: ledgerId,
    acknowledged: !!applyOut.acknowledged,
    consumed: !!applyOut.consumed,
    source: 'rtdn',
  };
}

module.exports = {
  SUB_NOTIFICATION,
  ONE_TIME_NOTIFICATION,
  mapRtdnSubscriptionLifecycleHint,
  parseRtdnPubSubInput,
  handlePlayRtdnNotification,
};
