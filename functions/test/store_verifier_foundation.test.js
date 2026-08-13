'use strict';

const assert = require('assert');
const {
  mapAppleProduct,
  mapPlayProduct,
  mapAppleSubscriptionStatus,
  mapPlaySubscriptionStatus,
  buildSubscriptionEntitlementFields,
  consumableCreditIntent,
  PRODUCT_KIND,
} = require('../src/store_product_map');
const { validateUidBinding } = require('../src/store_uid_binding');
const {
  isTrustedVerified,
  clientClaimsCanGrant,
  failClosedNotConfigured,
} = require('../src/store_verification_result');
const {
  hasAppleVerifier,
  mapTrustedAppleTransaction,
  verifyApplePurchase,
} = require('../src/store_verify_apple');
const {
  hasPlayVerifier,
  mapTrustedPlayPurchase,
  verifyPlayPurchase,
} = require('../src/store_verify_play');
const {
  handleVerifyAndApplyPurchase,
  maybeApplyVerifiedEntitlement,
} = require('../src/entitlement_callables');
const {
  STORE_PRODUCT_IDS,
  CANONICAL_PRODUCT_KEYS,
  VERIFICATION_NOT_CONFIGURED,
} = require('../src/entitlement_schema');
const {
  creditConsumableIdempotent,
} = require('../src/entitlement_repository');
const { MemoryFirestore } = require('./memory_firestore');

describe('store_verifier_foundation_v1', () => {
  describe('product mapping', () => {
    it('maps known Apple subscriptions', () => {
      const m = mapAppleProduct(STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY);
      assert.strictEqual(m.ok, true);
      assert.strictEqual(
        m.mapping.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
      );
      assert.strictEqual(m.mapping.kind, PRODUCT_KIND.SUBSCRIPTION);

      const a = mapAppleProduct(STORE_PRODUCT_IDS.IOS_RESONANCE_ANNUAL);
      assert.strictEqual(
        a.mapping.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_ANNUAL,
      );
    });

    it('maps known Apple/Play consumables', () => {
      const s = mapAppleProduct(STORE_PRODUCT_IDS.SUPER_RESONANCE_X1);
      assert.strictEqual(s.ok, true);
      assert.strictEqual(s.mapping.kind, PRODUCT_KIND.CONSUMABLE);
      assert.deepStrictEqual(consumableCreditIntent(s.mapping), {
        balance_field: 'super_resonance_balance',
        delta: 1,
      });

      const b = mapPlayProduct(STORE_PRODUCT_IDS.BOOST_X1, null);
      assert.strictEqual(
        b.mapping.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.BOOST_X1,
      );
    });

    it('maps Play subscription + base plans', () => {
      const monthly = mapPlayProduct(STORE_PRODUCT_IDS.PLAY_RESONANCE, 'monthly');
      assert.strictEqual(monthly.ok, true);
      assert.strictEqual(
        monthly.mapping.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
      );
      assert.strictEqual(monthly.mapping.base_plan_id, 'monthly');

      const annual = mapPlayProduct(STORE_PRODUCT_IDS.PLAY_RESONANCE, 'annual');
      assert.strictEqual(
        annual.mapping.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_ANNUAL,
      );
    });

    it('rejects unknown products', () => {
      assert.strictEqual(mapAppleProduct('com.other.premium').ok, false);
      assert.strictEqual(
        mapPlayProduct(STORE_PRODUCT_IDS.PLAY_RESONANCE, 'quarterly').ok,
        false,
      );
      assert.strictEqual(mapPlayProduct('qmatch.orbit.monthly', 'monthly').ok, false);
    });
  });

  describe('subscription status mapping', () => {
    it('maps active/grace/billing_retry', () => {
      assert.strictEqual(mapAppleSubscriptionStatus('active'), 'active');
      assert.strictEqual(mapAppleSubscriptionStatus('gracePeriod'), 'grace');
      assert.strictEqual(
        mapAppleSubscriptionStatus('billingRetry'),
        'billing_retry',
      );
      assert.strictEqual(
        mapPlaySubscriptionStatus('SUBSCRIPTION_STATE_ACTIVE'),
        'active',
      );
      assert.strictEqual(
        mapPlaySubscriptionStatus('SUBSCRIPTION_STATE_IN_GRACE_PERIOD'),
        'grace',
      );
      assert.strictEqual(
        mapPlaySubscriptionStatus('SUBSCRIPTION_STATE_ON_HOLD'),
        'billing_retry',
      );
    });

    it('maps revoked/expired', () => {
      assert.strictEqual(mapAppleSubscriptionStatus('expired'), 'expired');
      assert.strictEqual(mapAppleSubscriptionStatus('revoked'), 'revoked');
      assert.strictEqual(
        mapPlaySubscriptionStatus('SUBSCRIPTION_STATE_EXPIRED'),
        'expired',
      );
      assert.strictEqual(
        mapPlaySubscriptionStatus('SUBSCRIPTION_STATE_REVOKED'),
        'revoked',
      );
    });

    it('buildSubscriptionEntitlementFields derives resonance_access', () => {
      const mapping = mapAppleProduct(
        STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
      ).mapping;
      const active = buildSubscriptionEntitlementFields({
        mapping,
        subscriptionState: 'active',
        platform: 'ios',
      });
      assert.strictEqual(active.resonance_access, true);
      assert.strictEqual(active.tier, 'resonance');

      const expired = buildSubscriptionEntitlementFields({
        mapping,
        subscriptionState: 'expired',
        platform: 'ios',
      });
      assert.strictEqual(expired.resonance_access, false);
      assert.strictEqual(expired.tier, 'free');

      const grace = buildSubscriptionEntitlementFields({
        mapping,
        subscriptionState: 'grace',
        platform: 'ios',
      });
      assert.strictEqual(grace.resonance_access, true);

      const retry = buildSubscriptionEntitlementFields({
        mapping,
        subscriptionState: 'billing_retry',
        platform: 'ios',
      });
      assert.strictEqual(retry.resonance_access, true);

      const revoked = buildSubscriptionEntitlementFields({
        mapping,
        subscriptionState: 'revoked',
        platform: 'ios',
      });
      assert.strictEqual(revoked.resonance_access, false);
    });
  });

  describe('uid binding', () => {
    it('accepts matching uid', () => {
      assert.strictEqual(
        validateUidBinding({
          callerUid: 'user-1',
          storeAccountToken: 'user-1',
        }).ok,
        true,
      );
    });

    it('rejects mismatch', () => {
      assert.strictEqual(
        validateUidBinding({
          callerUid: 'user-1',
          storeAccountToken: 'user-2',
        }).ok,
        false,
      );
      assert.strictEqual(
        validateUidBinding({
          callerUid: 'user-1',
          storeAccountToken: 'user-2',
        }).code,
        'uid_binding_mismatch',
      );
    });

    it('rejects missing binding when required', () => {
      assert.strictEqual(
        validateUidBinding({
          callerUid: 'user-1',
          storeAccountToken: null,
          requireBinding: true,
        }).ok,
        false,
      );
    });
  });

  describe('Apple verifier foundation', () => {
    it('fail closed when credentials/API missing', async () => {
      assert.strictEqual(hasAppleVerifier({}), false);
      const r = await verifyApplePurchase({
        callerUid: 'u1',
        transactionId: 't1',
      });
      assert.strictEqual(r.code, VERIFICATION_NOT_CONFIGURED);
      assert.strictEqual(r.can_grant, false);
      assert.strictEqual(isTrustedVerified(r), false);
    });

    it('maps trusted active subscription with uid match', () => {
      const r = mapTrustedAppleTransaction({
        callerUid: 'u1',
        transaction: {
          productId: STORE_PRODUCT_IDS.IOS_RESONANCE_ANNUAL,
          status: 'active',
          transactionId: 'txn-a',
          originalTransactionId: 'orig-a',
          appAccountToken: 'u1',
        },
      });
      assert.strictEqual(isTrustedVerified(r), true);
      assert.strictEqual(r.resonance_access, true);
      assert.strictEqual(
        r.mapping.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_ANNUAL,
      );
    });

    it('rejects unknown product and uid mismatch on trusted map', () => {
      const unknown = mapTrustedAppleTransaction({
        callerUid: 'u1',
        transaction: {
          productId: 'qmatch.plus.monthly',
          status: 'active',
          appAccountToken: 'u1',
        },
      });
      assert.strictEqual(unknown.code, 'product_not_allowed');
      assert.strictEqual(isTrustedVerified(unknown), false);

      const mismatch = mapTrustedAppleTransaction({
        callerUid: 'u1',
        transaction: {
          productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
          status: 'active',
          appAccountToken: 'other',
        },
      });
      assert.strictEqual(mismatch.code, 'uid_binding_mismatch');
    });

    it('maps expired/revoked subscription without access', () => {
      const expired = mapTrustedAppleTransaction({
        callerUid: 'u1',
        transaction: {
          productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
          status: 'expired',
          appAccountToken: 'u1',
        },
      });
      assert.strictEqual(isTrustedVerified(expired), true);
      assert.strictEqual(expired.resonance_access, false);
      assert.strictEqual(expired.subscription_state, 'expired');

      const revoked = mapTrustedAppleTransaction({
        callerUid: 'u1',
        transaction: {
          productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
          status: 'revoked',
          appAccountToken: 'u1',
        },
      });
      assert.strictEqual(revoked.resonance_access, false);
      assert.strictEqual(revoked.subscription_state, 'revoked');
    });

    it('maps consumable without granting resonance', () => {
      const r = mapTrustedAppleTransaction({
        callerUid: 'u1',
        transaction: {
          productId: STORE_PRODUCT_IDS.BOOST_X1,
          transactionId: 'c1',
          appAccountToken: 'u1',
        },
      });
      assert.strictEqual(isTrustedVerified(r), true);
      assert.strictEqual(r.kind, PRODUCT_KIND.CONSUMABLE);
      assert.strictEqual(r.resonance_access, false);
      assert.strictEqual(r.credit.balance_field, 'boost_balance');
    });

    it('verifyApplePurchase with injected verifier returns trusted result', async () => {
      const r = await verifyApplePurchase(
        { callerUid: 'u1', transactionId: 't9' },
        {
          credentials: { configured: true },
          fetchTransactionInfo: async () => ({
            productId: STORE_PRODUCT_IDS.SUPER_RESONANCE_X1,
            transactionId: 't9',
            appAccountToken: 'u1',
          }),
        },
      );
      assert.strictEqual(isTrustedVerified(r), true);
      assert.strictEqual(r.kind, PRODUCT_KIND.CONSUMABLE);
    });
  });

  describe('Google Play verifier foundation', () => {
    it('fail closed when credentials/API missing', async () => {
      assert.strictEqual(hasPlayVerifier({}), false);
      const r = await verifyPlayPurchase({
        callerUid: 'u1',
        purchaseToken: 'tok',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
      });
      assert.strictEqual(r.code, VERIFICATION_NOT_CONFIGURED);
      assert.strictEqual(isTrustedVerified(r), false);
    });

    it('maps trusted Play subscription monthly/annual', () => {
      const monthly = mapTrustedPlayPurchase({
        callerUid: 'u1',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        kindHint: PRODUCT_KIND.SUBSCRIPTION,
        purchase: {
          productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
          basePlanId: 'monthly',
          subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
          orderId: 'GPA.1',
          obfuscatedExternalAccountId: 'u1',
        },
      });
      assert.strictEqual(isTrustedVerified(monthly), true);
      assert.strictEqual(monthly.resonance_access, true);
      assert.strictEqual(
        monthly.mapping.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
      );

      const annual = mapTrustedPlayPurchase({
        callerUid: 'u1',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        kindHint: PRODUCT_KIND.SUBSCRIPTION,
        purchase: {
          basePlanId: 'annual',
          subscriptionState: 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
          orderId: 'GPA.2',
          obfuscatedExternalAccountId: 'u1',
        },
      });
      assert.strictEqual(annual.subscription_state, 'grace');
      assert.strictEqual(annual.resonance_access, true);
    });

    it('rejects unknown base plan and uid mismatch', () => {
      const unknown = mapTrustedPlayPurchase({
        callerUid: 'u1',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        kindHint: PRODUCT_KIND.SUBSCRIPTION,
        purchase: {
          basePlanId: 'weekly',
          subscriptionState: 'ACTIVE',
          obfuscatedExternalAccountId: 'u1',
        },
      });
      assert.strictEqual(unknown.code, 'product_not_allowed');

      const mismatch = mapTrustedPlayPurchase({
        callerUid: 'u1',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        kindHint: PRODUCT_KIND.SUBSCRIPTION,
        purchase: {
          basePlanId: 'monthly',
          subscriptionState: 'ACTIVE',
          obfuscatedExternalAccountId: 'other',
        },
      });
      assert.strictEqual(mismatch.code, 'uid_binding_mismatch');
    });

    it('maps revoked/expired Play subscription', () => {
      const revoked = mapTrustedPlayPurchase({
        callerUid: 'u1',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        kindHint: PRODUCT_KIND.SUBSCRIPTION,
        purchase: {
          basePlanId: 'monthly',
          subscriptionState: 'SUBSCRIPTION_STATE_REVOKED',
          obfuscatedExternalAccountId: 'u1',
        },
      });
      assert.strictEqual(revoked.subscription_state, 'revoked');
      assert.strictEqual(revoked.resonance_access, false);

      const expired = mapTrustedPlayPurchase({
        callerUid: 'u1',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        kindHint: PRODUCT_KIND.SUBSCRIPTION,
        purchase: {
          basePlanId: 'annual',
          subscriptionState: 'SUBSCRIPTION_STATE_EXPIRED',
          obfuscatedExternalAccountId: 'u1',
        },
      });
      assert.strictEqual(expired.subscription_state, 'expired');
      assert.strictEqual(expired.resonance_access, false);
    });
  });

  describe('grant gates', () => {
    it('unverified payload / client claims cannot grant', () => {
      assert.strictEqual(
        clientClaimsCanGrant({
          resonance_access: true,
          tier: 'resonance',
          productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
        }),
        false,
      );
      assert.strictEqual(
        isTrustedVerified(failClosedNotConfigured('ios')),
        false,
      );
      assert.strictEqual(
        isTrustedVerified({
          ok: true,
          trusted: false,
          verified: false,
          can_grant: true,
        }),
        false,
      );
    });

    it('callable fail closed without credentials and never applies repository', async () => {
      let applied = false;
      const result = await handleVerifyAndApplyPurchase(
        {
          auth: { uid: 'u1' },
          data: {
            platform: 'ios',
            transactionId: 't1',
            resonance_access: true,
            grant: true,
          },
        },
        {
          applyTrusted: async () => {
            applied = true;
          },
        },
      );
      assert.strictEqual(result.code, VERIFICATION_NOT_CONFIGURED);
      assert.strictEqual(result.granted, false);
      assert.strictEqual(result.repository_applied, false);
      assert.strictEqual(applied, false);
    });

    it('maybeApplyVerifiedEntitlement skips repository when not trusted', async () => {
      let called = false;
      const ok = await maybeApplyVerifiedEntitlement(
        { ok: false, trusted: false, verified: false, can_grant: false },
        {
          applyTrusted: async () => {
            called = true;
          },
        },
      );
      assert.strictEqual(ok, false);
      assert.strictEqual(called, false);
    });

    it('trusted consumable result may call applyTrusted but foundation callable still reports granted false without wire', async () => {
      const trusted = mapTrustedAppleTransaction({
        callerUid: 'u1',
        transaction: {
          productId: STORE_PRODUCT_IDS.SUPER_RESONANCE_X1,
          transactionId: 'sr1',
          appAccountToken: 'u1',
        },
      });
      assert.strictEqual(isTrustedVerified(trusted), true);

      const db = new MemoryFirestore();
      let applyCount = 0;
      const applied = await maybeApplyVerifiedEntitlement(trusted, {
        applyTrusted: async (r) => {
          applyCount += 1;
          await creditConsumableIdempotent(
            {
              uid: 'u1',
              platform: 'ios',
              storeTransactionId: r.store_transaction_id,
              canonicalProductKey: r.mapping.canonical_product_key,
              productId: r.mapping.product_id,
            },
            { db },
          );
        },
      });
      assert.strictEqual(applied, true);
      assert.strictEqual(applyCount, 1);
    });
  });
});
