/**
 * Apply a trusted store verification result to the entitlement repository.
 * Must only be called when isTrustedVerified(result) === true.
 *
 * Play: after successful ledger write, consume/acknowledge via Play API helpers.
 */

'use strict';

const {
  EFFECTS,
  EVENT_TYPES,
  CANONICAL_PRODUCT_KEYS,
} = require('./entitlement_schema');
const {
  creditConsumableIdempotent,
  applySubscriptionLedgerEvent,
} = require('./entitlement_repository');
const { purchaseLedgerId } = require('./entitlement_ledger');
const { PRODUCT_KIND } = require('./store_product_map');
const { isTrustedVerified } = require('./store_verification_result');
const {
  finalizePlayPurchaseSideEffects,
} = require('./store_verify_play');

function subscriptionEffectForState(state) {
  switch (state) {
    case 'active':
    case 'grace':
    case 'billing_retry':
      return EFFECTS.GRANT_RESONANCE;
    case 'expired':
      return EFFECTS.DENY_RESONANCE_EXPIRED;
    case 'revoked':
      return EFFECTS.DENY_RESONANCE_REVOKED;
    default:
      return EFFECTS.DENY_RESONANCE_EXPIRED;
  }
}

function subscriptionEventTypeForState(state) {
  switch (state) {
    case 'active':
      return EVENT_TYPES.SUBSCRIPTION_PURCHASE;
    case 'grace':
      return EVENT_TYPES.SUBSCRIPTION_GRACE;
    case 'billing_retry':
      return EVENT_TYPES.SUBSCRIPTION_BILLING_RETRY;
    case 'expired':
      return EVENT_TYPES.SUBSCRIPTION_EXPIRE;
    case 'revoked':
      return EVENT_TYPES.SUBSCRIPTION_REVOKE;
    default:
      return EVENT_TYPES.SUBSCRIPTION_EXPIRE;
  }
}

/**
 * @param {string} uid
 * @param {Record<string, unknown>} result trusted verification result
 * @param {{ db?: FirebaseFirestore.Firestore, playFinalizeHelpers?: object }} [opts]
 * @returns {Promise<object>}
 */
async function applyTrustedVerificationResult(uid, result, opts = {}) {
  if (!isTrustedVerified(result)) {
    return { applied: false, reason: 'not_trusted_verified' };
  }
  if (!uid) {
    return { applied: false, reason: 'uid_required' };
  }

  let applyOut;

  if (result.kind === PRODUCT_KIND.CONSUMABLE) {
    if (!result.credit || !result.mapping) {
      return { applied: false, reason: 'no_credit_intent' };
    }
    const out = await creditConsumableIdempotent(
      {
        uid,
        platform: result.platform || 'ios',
        storeTransactionId: String(result.store_transaction_id),
        canonicalProductKey: result.mapping.canonical_product_key,
        productId: result.mapping.product_id,
        eventType: EVENT_TYPES.CONSUMABLE_PURCHASE,
        verificationSource: result.verification_source || 'app_store',
      },
      opts,
    );
    applyOut = {
      applied: true,
      status: out.status,
      snapshot: out.snapshot,
      ledgerId: out.ledgerId,
    };
  } else if (result.kind === PRODUCT_KIND.SUBSCRIPTION) {
    const storeTransactionId = String(result.store_transaction_id || '');
    if (!storeTransactionId) {
      return { applied: false, reason: 'missing_transaction_id' };
    }
    const platform = result.platform || 'ios';
    const state = result.subscription_state || 'none';
    const ledgerId = purchaseLedgerId(platform, storeTransactionId);
    const out = await applySubscriptionLedgerEvent(
      {
        uid,
        ledgerId,
        storeTransactionId,
        platform,
        canonicalProductKey:
          (result.mapping && result.mapping.canonical_product_key) ||
          CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
        productId: result.mapping && result.mapping.product_id,
        basePlanId: (result.mapping && result.mapping.base_plan_id) || null,
        eventType: subscriptionEventTypeForState(state),
        effect: subscriptionEffectForState(state),
        subscriptionPatch: {
          tier: result.tier,
          subscription_state: state,
          platform,
          canonical_product_key:
            result.mapping && result.mapping.canonical_product_key,
          product_id: result.mapping && result.mapping.product_id,
          base_plan_id: (result.mapping && result.mapping.base_plan_id) || null,
          period_ends_at: result.period_ends_at || null,
          original_transaction_id: result.original_transaction_id || null,
          latest_transaction_ref: storeTransactionId,
        },
        verificationSource: result.verification_source || 'app_store',
      },
      opts,
    );
    applyOut = {
      applied: true,
      status: out.status,
      snapshot: out.snapshot,
      ledgerId: out.ledgerId,
    };
  } else {
    return { applied: false, reason: 'unknown_kind' };
  }

  // Play server-side consume / acknowledge after ledger success (incl. noop retry).
  if (result.platform === 'android' && applyOut.applied) {
    const finalize = await finalizePlayPurchaseSideEffects(
      result,
      opts.playFinalizeHelpers || null,
    );
    applyOut.play_finalize = finalize;
    applyOut.acknowledged = !!finalize.acknowledged;
    applyOut.consumed = !!finalize.consumed;
  }

  return applyOut;
}

module.exports = {
  applyTrustedVerificationResult,
  subscriptionEffectForState,
  subscriptionEventTypeForState,
};
