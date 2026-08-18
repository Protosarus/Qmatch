/**
 * Pure entitlement snapshot helpers (`resonance_entitlement_firestore_schema_v1`).
 * No I/O — safe for unit tests and Cloud Functions.
 */

'use strict';

const {
  SCHEMA_VERSION,
  ACCESS_GRANTING_STATES,
  SUBSCRIPTION_STATES,
  TIERS,
  BALANCE_FIELDS,
  SUPER_RESONANCE_DAILY,
} = require('./entitlement_schema');

/**
 * Derived access invariant — never client-authored.
 * @param {string} tier
 * @param {string} subscriptionState
 * @returns {boolean}
 */
function deriveResonanceAccess(tier, subscriptionState) {
  return (
    tier === 'resonance' &&
    ACCESS_GRANTING_STATES.includes(subscriptionState)
  );
}

/**
 * Normalized free default snapshot for uid.
 * @param {string} uid
 * @returns {Record<string, unknown>}
 */
function defaultFreeSnapshot(uid) {
  return {
    uid,
    tier: 'free',
    subscription_state: 'none',
    resonance_access: false,
    platform: 'unknown',
    canonical_product_key: null,
    product_id: null,
    base_plan_id: null,
    period_ends_at: null,
    grace_ends_at: null,
    billing_retry_ends_at: null,
    last_verified_at: null,
    verification_source: null,
    original_transaction_id: null,
    latest_transaction_ref: null,
    [BALANCE_FIELDS.SUPER_RESONANCE]: 0,
    [BALANCE_FIELDS.BOOST]: 0,
    [SUPER_RESONANCE_DAILY.UTC_DATE]: null,
    [SUPER_RESONANCE_DAILY.USED]: 0,
    schema_version: SCHEMA_VERSION,
  };
}

/**
 * Normalize a partial/raw snapshot into schema-safe shape.
 * Always re-derives resonance_access. Never invents Resonance.
 * @param {string} uid
 * @param {Record<string, unknown>|null|undefined} raw
 * @returns {Record<string, unknown>}
 */
function normalizeSnapshot(uid, raw) {
  const base = defaultFreeSnapshot(uid);
  if (!raw || typeof raw !== 'object') {
    return base;
  }

  const tier = TIERS.includes(raw.tier) ? raw.tier : 'free';
  const subscription_state = SUBSCRIPTION_STATES.includes(raw.subscription_state)
    ? raw.subscription_state
    : 'none';

  const superBal = nonNegInt(raw[BALANCE_FIELDS.SUPER_RESONANCE]);
  const boostBal = nonNegInt(raw[BALANCE_FIELDS.BOOST]);
  const dailyDate = isUtcDate(raw[SUPER_RESONANCE_DAILY.UTC_DATE])
    ? raw[SUPER_RESONANCE_DAILY.UTC_DATE]
    : null;
  const dailyUsed = nonNegInt(raw[SUPER_RESONANCE_DAILY.USED]);

  return {
    ...base,
    ...pickKnown(raw),
    uid,
    tier,
    subscription_state,
    resonance_access: deriveResonanceAccess(tier, subscription_state),
    [BALANCE_FIELDS.SUPER_RESONANCE]: superBal,
    [BALANCE_FIELDS.BOOST]: boostBal,
    [SUPER_RESONANCE_DAILY.UTC_DATE]: dailyDate,
    [SUPER_RESONANCE_DAILY.USED]: dailyUsed,
    schema_version: SCHEMA_VERSION,
  };
}

function isUtcDate(value) {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function nonNegInt(v) {
  const n = typeof v === 'number' ? Math.floor(v) : 0;
  return Number.isFinite(n) && n > 0 ? n : 0;
}

function pickKnown(raw) {
  const keys = [
    'platform',
    'canonical_product_key',
    'product_id',
    'base_plan_id',
    'period_ends_at',
    'grace_ends_at',
    'billing_retry_ends_at',
    'last_verified_at',
    'verification_source',
    'original_transaction_id',
    'latest_transaction_ref',
  ];
  const out = {};
  for (const k of keys) {
    if (k in raw) out[k] = raw[k];
  }
  return out;
}

/**
 * Apply subscription fields safely. Re-derives resonance_access.
 * Does not mutate consumable balances.
 *
 * @param {Record<string, unknown>} snapshot normalized current
 * @param {object} patch
 * @param {string} [patch.tier]
 * @param {string} [patch.subscription_state]
 * @param {string|null} [patch.platform]
 * @param {string|null} [patch.canonical_product_key]
 * @param {string|null} [patch.product_id]
 * @param {string|null} [patch.base_plan_id]
 * @param {unknown} [patch.period_ends_at]
 * @param {unknown} [patch.grace_ends_at]
 * @param {unknown} [patch.billing_retry_ends_at]
 * @param {unknown} [patch.last_verified_at]
 * @param {string|null} [patch.verification_source]
 * @param {string|null} [patch.original_transaction_id]
 * @param {string|null} [patch.latest_transaction_ref]
 * @returns {Record<string, unknown>}
 */
function applySubscriptionState(snapshot, patch) {
  const next = { ...snapshot };
  if (patch.tier !== undefined) {
    if (!TIERS.includes(patch.tier)) {
      throw new Error(`invalid_tier:${patch.tier}`);
    }
    next.tier = patch.tier;
  }
  if (patch.subscription_state !== undefined) {
    if (!SUBSCRIPTION_STATES.includes(patch.subscription_state)) {
      throw new Error(`invalid_subscription_state:${patch.subscription_state}`);
    }
    next.subscription_state = patch.subscription_state;
  }

  const passthrough = [
    'platform',
    'canonical_product_key',
    'product_id',
    'base_plan_id',
    'period_ends_at',
    'grace_ends_at',
    'billing_retry_ends_at',
    'last_verified_at',
    'verification_source',
    'original_transaction_id',
    'latest_transaction_ref',
  ];
  for (const k of passthrough) {
    if (patch[k] !== undefined) next[k] = patch[k];
  }

  // Revoke / expire: force access false via derivation (tier may stay or go free).
  if (
    next.subscription_state === 'revoked' ||
    next.subscription_state === 'expired' ||
    next.subscription_state === 'none'
  ) {
    if (patch.tier === undefined) {
      next.tier = 'free';
    }
  }

  next.resonance_access = deriveResonanceAccess(
    next.tier,
    next.subscription_state,
  );
  next.schema_version = SCHEMA_VERSION;
  return next;
}

/**
 * Credit a consumable balance without touching subscription access.
 * @param {Record<string, unknown>} snapshot
 * @param {'super_resonance_balance'|'boost_balance'} field
 * @param {number} delta positive credit
 * @returns {Record<string, unknown>}
 */
function creditBalance(snapshot, field, delta) {
  if (
    field !== BALANCE_FIELDS.SUPER_RESONANCE &&
    field !== BALANCE_FIELDS.BOOST
  ) {
    throw new Error(`invalid_balance_field:${field}`);
  }
  const d = Math.floor(delta);
  if (!Number.isFinite(d) || d <= 0) {
    throw new Error(`invalid_credit_delta:${delta}`);
  }
  const current = nonNegInt(snapshot[field]);
  return {
    ...snapshot,
    [field]: current + d,
    // Explicitly preserve access — credits never grant Resonance.
    resonance_access: deriveResonanceAccess(
      snapshot.tier,
      snapshot.subscription_state,
    ),
    schema_version: SCHEMA_VERSION,
  };
}

/**
 * Debit a consumable balance without touching subscription access.
 * Never goes below 0 — rejects when current < delta.
 *
 * @param {Record<string, unknown>} snapshot
 * @param {'super_resonance_balance'|'boost_balance'} field
 * @param {number} delta positive debit
 * @returns {Record<string, unknown>}
 */
function debitBalance(snapshot, field, delta) {
  if (
    field !== BALANCE_FIELDS.SUPER_RESONANCE &&
    field !== BALANCE_FIELDS.BOOST
  ) {
    throw new Error(`invalid_balance_field:${field}`);
  }
  const d = Math.floor(delta);
  if (!Number.isFinite(d) || d <= 0) {
    throw new Error(`invalid_debit_delta:${delta}`);
  }
  const current = nonNegInt(snapshot[field]);
  if (current < d) {
    throw new Error('insufficient_balance');
  }
  return {
    ...snapshot,
    [field]: current - d,
    // Explicitly preserve access — debits never grant or revoke Resonance.
    resonance_access: deriveResonanceAccess(
      snapshot.tier,
      snapshot.subscription_state,
    ),
    schema_version: SCHEMA_VERSION,
  };
}

module.exports = {
  deriveResonanceAccess,
  defaultFreeSnapshot,
  normalizeSnapshot,
  applySubscriptionState,
  creditBalance,
  debitBalance,
};
