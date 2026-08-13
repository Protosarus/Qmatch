'use strict';

const assert = require('assert');
const { loadPlayIapConfig } = require('../src/play_iap_config');
const {
  verifyPlayPurchase,
  mapTrustedPlayPurchase,
  hasPlayVerifier,
  finalizePlayPurchaseSideEffects,
  androidStoreTransactionIdFromToken,
  PRODUCT_PURCHASE_STATE,
} = require('../src/store_verify_play');
const {
  isTrustedVerified,
  failClosedNotConfigured,
} = require('../src/store_verification_result');
const {
  handleVerifyAndApplyPurchase,
  maybeApplyVerifiedEntitlement,
} = require('../src/entitlement_callables');
const {
  applyTrustedVerificationResult,
} = require('../src/apply_trusted_verification');
const {
  getOrCreateEntitlementSnapshot,
} = require('../src/entitlement_repository');
const {
  STORE_PRODUCT_IDS,
  CANONICAL_PRODUCT_KEYS,
  VERIFICATION_NOT_CONFIGURED,
} = require('../src/entitlement_schema');
const { PRODUCT_KIND } = require('../src/store_product_map');
const { purchaseLedgerId } = require('../src/entitlement_ledger');
const { MemoryFirestore } = require('./memory_firestore');

function playOpts(overrides = {}) {
  return {
    credentials: { configured: true },
    requireBinding: true,
    ...overrides,
  };
}

function activeSub(basePlanId, token = 'tok') {
  return {
    fetchSubscription: async ({ purchaseToken }) => ({
      lineItems: [
        {
          productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
          offerDetails: { basePlanId },
          expiryTime: new Date(Date.now() + 86400000).toISOString(),
        },
      ],
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      acknowledgementState: 0,
      orderId: 'GPA.ORDER.1',
      obfuscatedExternalAccountId: 'uid-1',
      purchaseToken,
    }),
  };
}

describe('google_play_purchase_verification_v1', () => {
  describe('config + idempotency id', () => {
    it('missing config fails closed', () => {
      assert.strictEqual(loadPlayIapConfig({}).ok, false);
      assert.strictEqual(hasPlayVerifier({ env: {} }), false);
    });

    it('purchaseToken is primary android ledger identity (not orderId)', () => {
      const a = androidStoreTransactionIdFromToken('same-token');
      const b = androidStoreTransactionIdFromToken('same-token');
      const c = androidStoreTransactionIdFromToken('other-token');
      assert.strictEqual(a, b);
      assert.notStrictEqual(a, c);
      assert.ok(a.startsWith('token:'));
      assert.strictEqual(
        purchaseLedgerId('android', a),
        `android:${a}`,
      );
    });
  });

  describe('verifyPlayPurchase', () => {
    it('valid monthly subscription', async () => {
      const r = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok-m',
          productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        },
        playOpts(activeSub('monthly')),
      );
      assert.strictEqual(isTrustedVerified(r), true);
      assert.strictEqual(
        r.mapping.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
      );
      assert.strictEqual(r.resonance_access, true);
      assert.strictEqual(r.acknowledgement_required, true);
    });

    it('valid annual subscription', async () => {
      const r = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok-a',
          productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        },
        playOpts(activeSub('annual')),
      );
      assert.strictEqual(
        r.mapping.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_ANNUAL,
      );
      assert.strictEqual(r.resonance_access, true);
    });

    it('valid Super Resonance consumable', async () => {
      const r = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok-sr',
          productId: STORE_PRODUCT_IDS.SUPER_RESONANCE_X1,
        },
        playOpts({
          fetchProductPurchase: async () => ({
            purchaseState: PRODUCT_PURCHASE_STATE.PURCHASED,
            acknowledgementState: 0,
            obfuscatedExternalAccountId: 'uid-1',
            productId: STORE_PRODUCT_IDS.SUPER_RESONANCE_X1,
          }),
        }),
      );
      assert.strictEqual(isTrustedVerified(r), true);
      assert.strictEqual(r.kind, PRODUCT_KIND.CONSUMABLE);
      assert.strictEqual(r.resonance_access, false);
      assert.strictEqual(r.consumption_required, true);
      assert.strictEqual(r.credit.balance_field, 'super_resonance_balance');
    });

    it('valid Boost consumable', async () => {
      const r = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok-boost',
          productId: STORE_PRODUCT_IDS.BOOST_X1,
        },
        playOpts({
          fetchProductPurchase: async () => ({
            purchaseState: PRODUCT_PURCHASE_STATE.PURCHASED,
            obfuscatedExternalAccountId: 'uid-1',
          }),
        }),
      );
      assert.strictEqual(r.credit.balance_field, 'boost_balance');
    });

    it('pending purchase grants nothing', async () => {
      const pendingProduct = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok-p',
          productId: STORE_PRODUCT_IDS.BOOST_X1,
        },
        playOpts({
          fetchProductPurchase: async () => ({
            purchaseState: PRODUCT_PURCHASE_STATE.PENDING,
            obfuscatedExternalAccountId: 'uid-1',
          }),
        }),
      );
      assert.strictEqual(pendingProduct.code, 'purchase_pending');
      assert.strictEqual(isTrustedVerified(pendingProduct), false);

      const pendingSub = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok-ps',
          productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        },
        playOpts({
          fetchSubscription: async () => ({
            subscriptionState: 'SUBSCRIPTION_STATE_PENDING',
            lineItems: [
              {
                productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
                offerDetails: { basePlanId: 'monthly' },
              },
            ],
            obfuscatedExternalAccountId: 'uid-1',
          }),
        }),
      );
      assert.strictEqual(pendingSub.code, 'purchase_pending');
    });

    it('expired/revoked subscription does not grant Resonance', async () => {
      const expired = mapTrustedPlayPurchase({
        callerUid: 'uid-1',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        purchaseToken: 'tok-exp',
        kindHint: PRODUCT_KIND.SUBSCRIPTION,
        purchase: {
          basePlanId: 'monthly',
          subscriptionState: 'SUBSCRIPTION_STATE_EXPIRED',
          obfuscatedExternalAccountId: 'uid-1',
        },
      });
      assert.strictEqual(expired.resonance_access, false);

      const revoked = mapTrustedPlayPurchase({
        callerUid: 'uid-1',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        purchaseToken: 'tok-rev',
        kindHint: PRODUCT_KIND.SUBSCRIPTION,
        purchase: {
          basePlanId: 'annual',
          subscriptionState: 'SUBSCRIPTION_STATE_REVOKED',
          obfuscatedExternalAccountId: 'uid-1',
        },
      });
      assert.strictEqual(revoked.resonance_access, false);
    });

    it('unknown product/base plan rejects', async () => {
      const unknownPlan = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok-w',
          productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        },
        playOpts({
          fetchSubscription: async () => ({
            subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
            lineItems: [
              {
                productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
                offerDetails: { basePlanId: 'weekly' },
              },
            ],
            obfuscatedExternalAccountId: 'uid-1',
          }),
        }),
      );
      assert.strictEqual(unknownPlan.code, 'product_not_allowed');

      const unknownProduct = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok-x',
          productId: 'qmatch.orbit.x1',
          kind: 'consumable',
        },
        playOpts({
          fetchProductPurchase: async () => ({
            purchaseState: 0,
            productId: 'qmatch.orbit.x1',
            obfuscatedExternalAccountId: 'uid-1',
          }),
        }),
      );
      assert.strictEqual(unknownProduct.code, 'product_not_allowed');
    });

    it('uid/account mismatch rejects', async () => {
      const r = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok-mm',
          productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        },
        playOpts({
          fetchSubscription: async () => ({
            subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
            lineItems: [
              {
                productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
                offerDetails: { basePlanId: 'monthly' },
              },
            ],
            obfuscatedExternalAccountId: 'other-user',
          }),
        }),
      );
      assert.strictEqual(r.code, 'uid_binding_mismatch');
    });

    it('API/config failure fails closed', async () => {
      const missing = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok',
          productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        },
        { env: {} },
      );
      assert.strictEqual(missing.code, VERIFICATION_NOT_CONFIGURED);

      const apiFail = await verifyPlayPurchase(
        {
          callerUid: 'uid-1',
          purchaseToken: 'tok',
          productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        },
        playOpts({
          fetchSubscription: async () => {
            throw new Error('503');
          },
        }),
      );
      assert.strictEqual(apiFail.code, 'store_verification_failed');
    });
  });

  describe('repository wiring + ack/consume', () => {
    it('duplicate purchaseToken is idempotent', async () => {
      const db = new MemoryFirestore();
      let ackCount = 0;
      const play = playOpts({
        ...activeSub('monthly', 'dup-token'),
        acknowledgeSubscription: async () => {
          ackCount += 1;
        },
      });

      const first = await handleVerifyAndApplyPurchase(
        {
          auth: { uid: 'uid-1' },
          data: {
            platform: 'android',
            purchaseToken: 'dup-token',
            productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
          },
        },
        { play, db },
      );
      assert.strictEqual(first.repository_applied, true);
      assert.strictEqual(first.apply_status, 'applied');
      assert.strictEqual(first.granted, true);
      assert.strictEqual(first.acknowledged, true);

      const second = await handleVerifyAndApplyPurchase(
        {
          auth: { uid: 'uid-1' },
          data: {
            platform: 'android',
            purchaseToken: 'dup-token',
            productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
          },
        },
        { play, db },
      );
      assert.strictEqual(second.apply_status, 'noop');
      assert.ok(ackCount >= 1);

      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-1', {
        db,
      });
      assert.strictEqual(snapshot.resonance_access, true);
    });

    it('consume required after successful consumable credit', async () => {
      const db = new MemoryFirestore();
      let consumed = 0;
      const play = playOpts({
        fetchProductPurchase: async () => ({
          purchaseState: PRODUCT_PURCHASE_STATE.PURCHASED,
          acknowledgementState: 0,
          obfuscatedExternalAccountId: 'uid-2',
        }),
        consumeProduct: async () => {
          consumed += 1;
        },
      });

      const r = await handleVerifyAndApplyPurchase(
        {
          auth: { uid: 'uid-2' },
          data: {
            platform: 'android',
            purchaseToken: 'boost-token',
            productId: STORE_PRODUCT_IDS.BOOST_X1,
          },
        },
        { play, db },
      );
      assert.strictEqual(r.repository_applied, true);
      assert.strictEqual(r.consumed, true);
      assert.strictEqual(consumed, 1);
      assert.strictEqual(r.granted, false);

      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-2', {
        db,
      });
      assert.strictEqual(snapshot.boost_balance, 1);
    });

    it('finalizePlayPurchaseSideEffects acknowledges subscriptions', async () => {
      let ack = false;
      const result = mapTrustedPlayPurchase({
        callerUid: 'uid-1',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        purchaseToken: 'tok-ack',
        kindHint: PRODUCT_KIND.SUBSCRIPTION,
        purchase: {
          basePlanId: 'monthly',
          subscriptionState: 'ACTIVE',
          acknowledgementState: 0,
          obfuscatedExternalAccountId: 'uid-1',
        },
      });
      const fin = await finalizePlayPurchaseSideEffects(result, {
        acknowledgeSubscription: async () => {
          ack = true;
        },
        purchaseToken: 'tok-ack',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
      });
      assert.strictEqual(fin.acknowledged, true);
      assert.strictEqual(ack, true);
    });

    it('unverified payload cannot mutate entitlement', async () => {
      const db = new MemoryFirestore();
      await getOrCreateEntitlementSnapshot('uid-3', { db });
      const unverified = failClosedNotConfigured('android');
      const apply = await applyTrustedVerificationResult('uid-3', unverified, {
        db,
      });
      assert.strictEqual(apply.applied, false);
      const gate = await maybeApplyVerifiedEntitlement('uid-3', unverified, {
        db,
      });
      assert.strictEqual(gate.applied, false);
      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-3', {
        db,
      });
      assert.strictEqual(snapshot.resonance_access, false);
      assert.strictEqual(snapshot.boost_balance, 0);
    });
  });
});
