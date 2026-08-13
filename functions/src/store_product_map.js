/**
 * Frozen store product allowlist + pure mappers
 * (`store_purchase_verification_contract_v1`).
 */

'use strict';

const {
  CANONICAL_PRODUCT_KEYS,
  STORE_PRODUCT_IDS,
  PLAY_BASE_PLANS,
  ACCESS_GRANTING_STATES,
} = require('./entitlement_schema');
const { deriveResonanceAccess } = require('./entitlement_access');

const PRODUCT_KIND = Object.freeze({
  SUBSCRIPTION: 'subscription',
  CONSUMABLE: 'consumable',
});

/** Apple productId → canonical mapping. */
const APPLE_PRODUCT_ALLOWLIST = Object.freeze({
  [STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY]: {
    canonical_product_key: CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
    kind: PRODUCT_KIND.SUBSCRIPTION,
    product_id: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
    base_plan_id: null,
  },
  [STORE_PRODUCT_IDS.IOS_RESONANCE_ANNUAL]: {
    canonical_product_key: CANONICAL_PRODUCT_KEYS.RESONANCE_ANNUAL,
    kind: PRODUCT_KIND.SUBSCRIPTION,
    product_id: STORE_PRODUCT_IDS.IOS_RESONANCE_ANNUAL,
    base_plan_id: null,
  },
  [STORE_PRODUCT_IDS.SUPER_RESONANCE_X1]: {
    canonical_product_key: CANONICAL_PRODUCT_KEYS.SUPER_RESONANCE_X1,
    kind: PRODUCT_KIND.CONSUMABLE,
    product_id: STORE_PRODUCT_IDS.SUPER_RESONANCE_X1,
    base_plan_id: null,
  },
  [STORE_PRODUCT_IDS.BOOST_X1]: {
    canonical_product_key: CANONICAL_PRODUCT_KEYS.BOOST_X1,
    kind: PRODUCT_KIND.CONSUMABLE,
    product_id: STORE_PRODUCT_IDS.BOOST_X1,
    base_plan_id: null,
  },
});

/** Play consumable productId → canonical. */
const PLAY_CONSUMABLE_ALLOWLIST = Object.freeze({
  [STORE_PRODUCT_IDS.SUPER_RESONANCE_X1]: {
    canonical_product_key: CANONICAL_PRODUCT_KEYS.SUPER_RESONANCE_X1,
    kind: PRODUCT_KIND.CONSUMABLE,
    product_id: STORE_PRODUCT_IDS.SUPER_RESONANCE_X1,
    base_plan_id: null,
  },
  [STORE_PRODUCT_IDS.BOOST_X1]: {
    canonical_product_key: CANONICAL_PRODUCT_KEYS.BOOST_X1,
    kind: PRODUCT_KIND.CONSUMABLE,
    product_id: STORE_PRODUCT_IDS.BOOST_X1,
    base_plan_id: null,
  },
});

/** Play subscription: product + base plan. */
const PLAY_SUBSCRIPTION_PRODUCT_ID = STORE_PRODUCT_IDS.PLAY_RESONANCE;

const PLAY_BASE_PLAN_ALLOWLIST = Object.freeze({
  [PLAY_BASE_PLANS.MONTHLY]: {
    canonical_product_key: CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
    kind: PRODUCT_KIND.SUBSCRIPTION,
    product_id: PLAY_SUBSCRIPTION_PRODUCT_ID,
    base_plan_id: PLAY_BASE_PLANS.MONTHLY,
  },
  [PLAY_BASE_PLANS.ANNUAL]: {
    canonical_product_key: CANONICAL_PRODUCT_KEYS.RESONANCE_ANNUAL,
    kind: PRODUCT_KIND.SUBSCRIPTION,
    product_id: PLAY_SUBSCRIPTION_PRODUCT_ID,
    base_plan_id: PLAY_BASE_PLANS.ANNUAL,
  },
});

/**
 * @param {string} productId
 * @returns {{ ok: true, mapping: object }|{ ok: false, code: string }}
 */
function mapAppleProduct(productId) {
  const mapping = APPLE_PRODUCT_ALLOWLIST[productId];
  if (!mapping) {
    return { ok: false, code: 'product_not_allowed' };
  }
  return { ok: true, mapping: { ...mapping } };
}

/**
 * @param {string} productId
 * @param {string|null|undefined} basePlanId
 * @returns {{ ok: true, mapping: object }|{ ok: false, code: string }}
 */
function mapPlayProduct(productId, basePlanId) {
  if (productId === PLAY_SUBSCRIPTION_PRODUCT_ID) {
    const mapping = PLAY_BASE_PLAN_ALLOWLIST[basePlanId];
    if (!mapping) {
      return { ok: false, code: 'product_not_allowed' };
    }
    return { ok: true, mapping: { ...mapping } };
  }
  const consumable = PLAY_CONSUMABLE_ALLOWLIST[productId];
  if (consumable) {
    return { ok: true, mapping: { ...consumable } };
  }
  return { ok: false, code: 'product_not_allowed' };
}

/**
 * Map Apple-like subscription lifecycle signals to canonical subscription_state.
 * @param {string} status
 * @returns {string} canonical subscription_state
 */
function mapAppleSubscriptionStatus(status) {
  const s = String(status || '').toLowerCase();
  switch (s) {
    case 'active':
    case 'subscribed':
      return 'active';
    case 'grace':
    case 'grace_period':
    case 'graceperiod':
    case 'in_billing_grace_period':
      return 'grace';
    case 'billing_retry':
    case 'billingretry':
    case 'in_billing_retry_period':
    case 'account_hold':
    case 'accounthold':
      return 'billing_retry';
    case 'expired':
    case 'lapse':
    case 'lapsed':
      return 'expired';
    case 'revoked':
    case 'refund':
    case 'refunded':
      return 'revoked';
    case 'none':
      return 'none';
    default:
      return 'none';
  }
}

/**
 * Map Play subscription state enums / strings to canonical subscription_state.
 * @param {string} status
 * @returns {string}
 */
function mapPlaySubscriptionStatus(status) {
  const s = String(status || '')
    .toUpperCase()
    .replace(/^SUBSCRIPTION_STATE_/, '');
  switch (s) {
    case 'ACTIVE':
    case 'SUBSCRIBED':
      return 'active';
    case 'IN_GRACE_PERIOD':
    case 'GRACE':
      return 'grace';
    case 'ON_HOLD':
    case 'IN_BILLING_RETRY':
    case 'BILLING_RETRY':
    case 'ACCOUNT_HOLD':
      return 'billing_retry';
    case 'EXPIRED':
    case 'CANCELED': // past expiry / not entitled — treat as expired if not entitled
      return 'expired';
    case 'REVOKED':
    case 'PENDING_PURCHASE_CANCELED':
      return 'revoked';
    default: {
      // Also accept lowercase Apple-style for shared fixtures
      return mapAppleSubscriptionStatus(status);
    }
  }
}

/**
 * Build entitlement-facing fields from a mapped subscription verification.
 * Does not write Firestore. Consumables must not call this for grants.
 *
 * @param {object} args
 * @param {object} args.mapping product mapping
 * @param {string} args.subscriptionState canonical
 * @param {string} args.platform
 * @returns {object}
 */
function buildSubscriptionEntitlementFields({
  mapping,
  subscriptionState,
  platform,
}) {
  const accessGranting = ACCESS_GRANTING_STATES.includes(subscriptionState);
  const tier = accessGranting ? 'resonance' : 'free';
  return {
    tier,
    subscription_state: subscriptionState,
    resonance_access: deriveResonanceAccess(tier, subscriptionState),
    platform,
    canonical_product_key: accessGranting
      ? mapping.canonical_product_key
      : mapping.canonical_product_key,
    product_id: mapping.product_id,
    base_plan_id: mapping.base_plan_id,
  };
}

/**
 * Consumable credit intent from mapping — never sets resonance.
 * @param {object} mapping
 * @returns {{ balance_field: string, delta: number }|null}
 */
function consumableCreditIntent(mapping) {
  if (!mapping || mapping.kind !== PRODUCT_KIND.CONSUMABLE) return null;
  if (
    mapping.canonical_product_key === CANONICAL_PRODUCT_KEYS.SUPER_RESONANCE_X1
  ) {
    return { balance_field: 'super_resonance_balance', delta: 1 };
  }
  if (mapping.canonical_product_key === CANONICAL_PRODUCT_KEYS.BOOST_X1) {
    return { balance_field: 'boost_balance', delta: 1 };
  }
  return null;
}

module.exports = {
  PRODUCT_KIND,
  APPLE_PRODUCT_ALLOWLIST,
  PLAY_CONSUMABLE_ALLOWLIST,
  PLAY_SUBSCRIPTION_PRODUCT_ID,
  PLAY_BASE_PLAN_ALLOWLIST,
  mapAppleProduct,
  mapPlayProduct,
  mapAppleSubscriptionStatus,
  mapPlaySubscriptionStatus,
  buildSubscriptionEntitlementFields,
  consumableCreditIntent,
};
