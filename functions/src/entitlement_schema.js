/**
 * Frozen Resonance entitlement schema constants
 * (`resonance_entitlement_firestore_schema_v1`).
 *
 * No Plus / Orbit / premiumTier. discover_eligible stays on users/{uid}.
 */

'use strict';

const SCHEMA_VERSION = 'resonance_entitlement_firestore_schema_v1';

const TIERS = Object.freeze(['free', 'resonance']);

const SUBSCRIPTION_STATES = Object.freeze([
  'none',
  'active',
  'billing_retry',
  'grace',
  'expired',
  'revoked',
]);

/** States that grant resonance_access when tier === resonance. */
const ACCESS_GRANTING_STATES = Object.freeze([
  'active',
  'grace',
  'billing_retry',
]);

const PLATFORMS = Object.freeze(['ios', 'android', 'unknown']);

const CANONICAL_PRODUCT_KEYS = Object.freeze({
  RESONANCE_MONTHLY: 'resonance_monthly',
  RESONANCE_ANNUAL: 'resonance_annual',
  SUPER_RESONANCE_X1: 'super_resonance_x1',
  BOOST_X1: 'boost_x1',
});

/** Frozen store product IDs only. */
const STORE_PRODUCT_IDS = Object.freeze({
  IOS_RESONANCE_MONTHLY: 'qmatch.resonance.monthly',
  IOS_RESONANCE_ANNUAL: 'qmatch.resonance.annual',
  PLAY_RESONANCE: 'qmatch.resonance',
  SUPER_RESONANCE_X1: 'qmatch.super_resonance.x1',
  BOOST_X1: 'qmatch.boost.x1',
});

const PLAY_BASE_PLANS = Object.freeze({
  MONTHLY: 'monthly',
  ANNUAL: 'annual',
});

const BALANCE_FIELDS = Object.freeze({
  SUPER_RESONANCE: 'super_resonance_balance',
  BOOST: 'boost_balance',
});

const EVENT_TYPES = Object.freeze({
  SUBSCRIPTION_PURCHASE: 'subscription_purchase',
  SUBSCRIPTION_RESTORE: 'subscription_restore',
  SUBSCRIPTION_RENEW: 'subscription_renew',
  SUBSCRIPTION_EXPIRE: 'subscription_expire',
  SUBSCRIPTION_GRACE: 'subscription_grace',
  SUBSCRIPTION_BILLING_RETRY: 'subscription_billing_retry',
  SUBSCRIPTION_REVOKE: 'subscription_revoke',
  CONSUMABLE_PURCHASE: 'consumable_purchase',
  CONSUMABLE_RESTORE_CREDIT: 'consumable_restore_credit',
  CONSUMABLE_SPEND: 'consumable_spend',
});

const EFFECTS = Object.freeze({
  GRANT_RESONANCE: 'grant_resonance',
  REFRESH_RESONANCE: 'refresh_resonance',
  DENY_RESONANCE_EXPIRED: 'deny_resonance_expired',
  DENY_RESONANCE_REVOKED: 'deny_resonance_revoked',
  CREDIT_SUPER_RESONANCE: 'credit_super_resonance',
  CREDIT_BOOST: 'credit_boost',
  DEBIT_SUPER_RESONANCE: 'debit_super_resonance',
  DEBIT_BOOST: 'debit_boost',
  NOOP: 'noop',
});

const VERIFICATION_NOT_CONFIGURED = 'verification_not_configured';

module.exports = {
  SCHEMA_VERSION,
  TIERS,
  SUBSCRIPTION_STATES,
  ACCESS_GRANTING_STATES,
  PLATFORMS,
  CANONICAL_PRODUCT_KEYS,
  STORE_PRODUCT_IDS,
  PLAY_BASE_PLANS,
  BALANCE_FIELDS,
  EVENT_TYPES,
  EFFECTS,
  VERIFICATION_NOT_CONFIGURED,
};
