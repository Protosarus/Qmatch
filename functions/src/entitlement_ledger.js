/**
 * Ledger id builders + event shaping for entitlement purchase ledger.
 */

'use strict';

const { SCHEMA_VERSION, EFFECTS } = require('./entitlement_schema');

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
  } = input;

  return {
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
  subscriptionEventLedgerId,
  spendLedgerId,
  buildLedgerDocument,
  planLedgerApply,
};
