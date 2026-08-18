/**
 * Ledger id builders + event shaping for entitlement purchase ledger.
 */

'use strict';

const { SCHEMA_VERSION, EFFECTS } = require('./entitlement_schema');

/**
 * Android purchaseToken → stable ledger identity.
 * Primary replay key is the purchaseToken (hashed for Firestore doc id safety).
 * Never use orderId as the primary key.
 *
 * @param {string} purchaseToken
 * @returns {string} e.g. token:<sha256hex>
 */
function androidStoreTransactionIdFromToken(purchaseToken) {
  if (!purchaseToken || typeof purchaseToken !== 'string') {
    throw new Error('purchase_token_required');
  }
  const crypto = require('crypto');
  const hash = crypto.createHash('sha256').update(purchaseToken).digest('hex');
  return `token:${hash}`;
}

/**
 * Purchase / restore / consumable credit idempotency key.
 * @param {string} platform ios|android
 * @param {string} storeTransactionId
 * @returns {string}
 */
function purchaseLedgerId(platform, storeTransactionId) {
  if (!platform || !storeTransactionId) {
    throw new Error('ledger_id_requires_platform_and_transaction');
  }
  return `${platform}:${storeTransactionId}`;
}

/**
 * Subscription lifecycle / webhook event idempotency key.
 * @param {string} platform
 * @param {string} originalTransactionId
 * @param {string} eventType
 * @param {string} eventId store notification / message id
 * @returns {string}
 */
function subscriptionEventLedgerId(
  platform,
  originalTransactionId,
  eventType,
  eventId,
) {
  if (!platform || !originalTransactionId || !eventType || !eventId) {
    throw new Error('subscription_event_ledger_id_incomplete');
  }
  return `${platform}:sub:${originalTransactionId}:${eventType}:${eventId}`;
}

/**
 * Notification dedupe key (ASSN notificationUUID / Pub/Sub message id).
 * @param {string} platform
 * @param {string} notificationId
 * @returns {string}
 */
function notificationLedgerId(platform, notificationId) {
  if (!platform || !notificationId) {
    throw new Error('notification_ledger_id_incomplete');
  }
  return `${platform}:notif:${notificationId}`;
}

/**
 * Spend idempotency key — requires unique request_id.
 * @param {string} platform
 * @param {string} uid
 * @param {string} requestId
 * @returns {string}
 */
function spendLedgerId(platform, uid, requestId) {
  if (!platform || !uid || !requestId) {
    throw new Error('spend_ledger_id_requires_request_id');
  }
  return `${platform}:spend:${uid}:${requestId}`;
}

/**
 * Build immutable ledger document body.
 * @param {object} input
 * @returns {Record<string, unknown>}
 */
function buildLedgerDocument(input) {
  const {
    uid,
    ledgerId,
    storeTransactionId,
    platform,
    canonicalProductKey,
    productId = null,
    basePlanId = null,
    eventType,
    effect,
    subscriptionStateAfter = null,
    balanceDeltaSuperResonance = 0,
    balanceDeltaBoost = 0,
    verificationSource,
    processedAt,
    targetUid = null,
  } = input;

  const doc = {
    uid,
    ledger_id: ledgerId,
    store_transaction_id: storeTransactionId,
    platform,
    canonical_product_key: canonicalProductKey,
    product_id: productId,
    base_plan_id: basePlanId,
    event_type: eventType,
    effect,
    subscription_state_after: subscriptionStateAfter,
    balance_delta_super_resonance: balanceDeltaSuperResonance,
    balance_delta_boost: balanceDeltaBoost,
    verification_source: verificationSource,
    processed_at: processedAt,
    schema_version: SCHEMA_VERSION,
  };
  if (targetUid) {
    doc.target_uid = targetUid;
  }
  return doc;
}

/**
 * Plan applying a ledger event to a snapshot (pure).
 * If existingLedger is set → noop (idempotent).
 *
 * @param {object} args
 * @param {Record<string, unknown>|null} args.existingLedger
 * @param {Record<string, unknown>} args.snapshot
 * @param {Record<string, unknown>} args.ledgerDoc
 * @param {Record<string, unknown>} args.nextSnapshot
 * @returns {{ status: 'noop'|'applied', effect: string, snapshot: Record<string, unknown>, ledger: Record<string, unknown> }}
 */
function planLedgerApply({
  existingLedger,
  snapshot,
  ledgerDoc,
  nextSnapshot,
}) {
  if (existingLedger) {
    return {
      status: 'noop',
      effect: EFFECTS.NOOP,
      snapshot,
      ledger: existingLedger,
    };
  }
  return {
    status: 'applied',
    effect: ledgerDoc.effect,
    snapshot: nextSnapshot,
    ledger: ledgerDoc,
  };
}

module.exports = {
  purchaseLedgerId,
  androidStoreTransactionIdFromToken,
  subscriptionEventLedgerId,
  notificationLedgerId,
  spendLedgerId,
  buildLedgerDocument,
  planLedgerApply,
};
