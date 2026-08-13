'use strict';

const assert = require('assert');
const { Status } = require('@apple/app-store-server-library');
const { loadAppleIapConfig } = require('../src/apple_iap_config');
const {
  verifyApplePurchase,
  mapTrustedAppleTransaction,
  hasAppleVerifier,
} = require('../src/store_verify_apple');
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
const { MemoryFirestore } = require('./memory_firestore');

function appleOpts(overrides = {}) {
  return {
    credentials: { configured: true },
    requireBinding: true,
    ...overrides,
  };
}

describe('apple_app_store_verification_v1', () => {
  describe('config', () => {
    it('missing config fails closed', () => {
      const loaded = loadAppleIapConfig({});
      assert.strictEqual(loaded.ok, false);
      assert.strictEqual(hasAppleVerifier({ env: {} }), false);
    });

    it('complete env config is detected', () => {
      const env = {
        APPLE_IAP_ISSUER_ID: 'issuer',
        APPLE_IAP_KEY_ID: 'KEYID12345',
        APPLE_IAP_PRIVATE_KEY: 'TEST_PRIVATE_KEY_PLACEHOLDER_NOT_A_SECRET',
        APPLE_IAP_BUNDLE_ID: 'com.qmatch.app',
        APPLE_IAP_ENVIRONMENT: 'Sandbox',
        APPLE_IAP_APP_APPLE_ID: '1234567890',
      };
      const loaded = loadAppleIapConfig(env);
      assert.strictEqual(loaded.ok, true);
      assert.strictEqual(hasAppleVerifier({ env }), true);
    });
  });

  describe('verifyApplePurchase', () => {
    it('valid trusted subscription maps and can grant', async () => {
      const r = await verifyApplePurchase(
        { callerUid: 'uid-1', transactionId: 'txn-sub-1' },
        appleOpts({
          fetchTransactionInfo: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
            transactionId: 'txn-sub-1',
            originalTransactionId: 'orig-1',
            appAccountToken: 'uid-1',
            expiresDate: Date.now() + 86400000,
          }),
          fetchSubscriptionStatuses: async () => ({
            data: [
              {
                lastTransactions: [
                  {
                    productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
                    status: Status.ACTIVE,
                  },
                ],
              },
            ],
          }),
        }),
      );
      assert.strictEqual(isTrustedVerified(r), true);
      assert.strictEqual(r.kind, PRODUCT_KIND.SUBSCRIPTION);
      assert.strictEqual(r.subscription_state, 'active');
      assert.strictEqual(r.resonance_access, true);
      assert.strictEqual(
        r.mapping.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
      );
    });

    it('valid consumable produces credit intent only', async () => {
      const r = await verifyApplePurchase(
        {
          callerUid: 'uid-1',
          signedTransaction: 'signed.jws.token',
          transactionId: 'txn-c-1',
        },
        appleOpts({
          verifySignedTransaction: async () => ({
            productId: STORE_PRODUCT_IDS.SUPER_RESONANCE_X1,
            transactionId: 'txn-c-1',
            appAccountToken: 'uid-1',
          }),
          fetchTransactionInfo: async () => ({
            productId: STORE_PRODUCT_IDS.SUPER_RESONANCE_X1,
            transactionId: 'txn-c-1',
            appAccountToken: 'uid-1',
          }),
        }),
      );
      assert.strictEqual(isTrustedVerified(r), true);
      assert.strictEqual(r.kind, PRODUCT_KIND.CONSUMABLE);
      assert.strictEqual(r.resonance_access, false);
      assert.strictEqual(r.credit.balance_field, 'super_resonance_balance');
    });

    it('uid mismatch rejects', async () => {
      const r = await verifyApplePurchase(
        { callerUid: 'uid-1', transactionId: 'txn-1' },
        appleOpts({
          fetchTransactionInfo: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_ANNUAL,
            transactionId: 'txn-1',
            appAccountToken: 'other-uid',
            status: 'active',
          }),
        }),
      );
      assert.strictEqual(r.code, 'uid_binding_mismatch');
      assert.strictEqual(isTrustedVerified(r), false);
    });

    it('unknown product rejects', async () => {
      const r = await verifyApplePurchase(
        { callerUid: 'uid-1', transactionId: 'txn-1' },
        appleOpts({
          fetchTransactionInfo: async () => ({
            productId: 'qmatch.orbit.monthly',
            transactionId: 'txn-1',
            appAccountToken: 'uid-1',
          }),
        }),
      );
      assert.strictEqual(r.code, 'product_not_allowed');
      assert.strictEqual(isTrustedVerified(r), false);
    });

    it('revoked and expired do not grant access', async () => {
      const revoked = mapTrustedAppleTransaction({
        callerUid: 'uid-1',
        transaction: {
          productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
          transactionId: 't-r',
          appAccountToken: 'uid-1',
          revocationDate: Date.now(),
        },
        subscriptionStatus: Status.REVOKED,
      });
      assert.strictEqual(isTrustedVerified(revoked), true);
      assert.strictEqual(revoked.resonance_access, false);
      assert.strictEqual(revoked.subscription_state, 'revoked');

      const expired = await verifyApplePurchase(
        { callerUid: 'uid-1', transactionId: 't-e' },
        appleOpts({
          fetchTransactionInfo: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
            transactionId: 't-e',
            appAccountToken: 'uid-1',
            expiresDate: Date.now() - 1000,
          }),
          fetchSubscriptionStatuses: async () => ({
            data: [
              {
                lastTransactions: [{ status: Status.EXPIRED }],
              },
            ],
          }),
        }),
      );
      assert.strictEqual(expired.resonance_access, false);
      assert.strictEqual(expired.subscription_state, 'expired');
    });

    it('invalid JWS fails closed', async () => {
      const r = await verifyApplePurchase(
        {
          callerUid: 'uid-1',
          signedTransaction: 'not.a.valid.jws',
        },
        appleOpts({
          verifySignedTransaction: async () => {
            throw new Error('invalid signature');
          },
          fetchTransactionInfo: async () => {
            throw new Error('should not be called');
          },
        }),
      );
      assert.strictEqual(r.code, 'invalid_jws');
      assert.strictEqual(isTrustedVerified(r), false);
    });

    it('Apple API failure fails closed', async () => {
      const r = await verifyApplePurchase(
        { callerUid: 'uid-1', transactionId: 'txn-x' },
        appleOpts({
          fetchTransactionInfo: async () => {
            throw new Error('503');
          },
        }),
      );
      assert.strictEqual(r.code, 'store_verification_failed');
      assert.strictEqual(isTrustedVerified(r), false);
    });

    it('missing config fails closed', async () => {
      const r = await verifyApplePurchase(
        { callerUid: 'uid-1', transactionId: 'txn-x' },
        { env: {} },
      );
      assert.strictEqual(r.code, VERIFICATION_NOT_CONFIGURED);
      assert.strictEqual(isTrustedVerified(r), false);
    });
  });

  describe('repository wiring', () => {
    it('wires trusted Apple subscription into entitlements (idempotent duplicate)', async () => {
      const db = new MemoryFirestore();
      const apple = appleOpts({
        fetchTransactionInfo: async () => ({
          productId: STORE_PRODUCT_IDS.IOS_RESONANCE_ANNUAL,
          transactionId: 'dup-1',
          originalTransactionId: 'orig-dup',
          appAccountToken: 'uid-1',
          expiresDate: Date.now() + 86400000,
        }),
        fetchSubscriptionStatuses: async () => ({
          data: [{ lastTransactions: [{ status: Status.ACTIVE }] }],
        }),
      });

      const first = await handleVerifyAndApplyPurchase(
        {
          auth: { uid: 'uid-1' },
          data: { platform: 'ios', transactionId: 'dup-1' },
        },
        { apple, db },
      );
      assert.strictEqual(first.repository_applied, true);
      assert.strictEqual(first.apply_status, 'applied');
      assert.strictEqual(first.granted, true);
      assert.strictEqual(first.resonance_access, true);

      const second = await handleVerifyAndApplyPurchase(
        {
          auth: { uid: 'uid-1' },
          data: { platform: 'ios', transactionId: 'dup-1' },
        },
        { apple, db },
      );
      assert.strictEqual(second.repository_applied, true);
      assert.strictEqual(second.apply_status, 'noop');

      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-1', { db });
      assert.strictEqual(snapshot.tier, 'resonance');
      assert.strictEqual(snapshot.resonance_access, true);
      assert.strictEqual(
        snapshot.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_ANNUAL,
      );
    });

    it('wires trusted consumable credit idempotently', async () => {
      const db = new MemoryFirestore();
      const apple = appleOpts({
        fetchTransactionInfo: async () => ({
          productId: STORE_PRODUCT_IDS.BOOST_X1,
          transactionId: 'boost-1',
          appAccountToken: 'uid-2',
        }),
      });

      const first = await handleVerifyAndApplyPurchase(
        {
          auth: { uid: 'uid-2' },
          data: { platform: 'ios', transactionId: 'boost-1' },
        },
        { apple, db },
      );
      assert.strictEqual(first.repository_applied, true);
      assert.strictEqual(first.balances_changed, true);
      assert.strictEqual(first.granted, false);

      const second = await handleVerifyAndApplyPurchase(
        {
          auth: { uid: 'uid-2' },
          data: { platform: 'ios', transactionId: 'boost-1' },
        },
        { apple, db },
      );
      assert.strictEqual(second.apply_status, 'noop');

      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-2', { db });
      assert.strictEqual(snapshot.boost_balance, 1);
      assert.strictEqual(snapshot.resonance_access, false);
    });

    it('unverified result cannot mutate entitlement', async () => {
      const db = new MemoryFirestore();
      await getOrCreateEntitlementSnapshot('uid-3', { db });

      const unverified = failClosedNotConfigured('ios');
      const apply = await applyTrustedVerificationResult(
        'uid-3',
        unverified,
        { db },
      );
      assert.strictEqual(apply.applied, false);

      const gate = await maybeApplyVerifiedEntitlement('uid-3', unverified, {
        db,
      });
      assert.strictEqual(gate.applied, false);

      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-3', { db });
      assert.strictEqual(snapshot.tier, 'free');
      assert.strictEqual(snapshot.resonance_access, false);
      assert.strictEqual(snapshot.super_resonance_balance, 0);
    });

    it('expired trusted subscription applies deny without access', async () => {
      const db = new MemoryFirestore();
      const apple = appleOpts({
        fetchTransactionInfo: async () => ({
          productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
          transactionId: 'exp-1',
          appAccountToken: 'uid-4',
          expiresDate: Date.now() - 1000,
        }),
        fetchSubscriptionStatuses: async () => ({
          data: [{ lastTransactions: [{ status: Status.EXPIRED }] }],
        }),
      });

      const r = await handleVerifyAndApplyPurchase(
        {
          auth: { uid: 'uid-4' },
          data: { platform: 'ios', transactionId: 'exp-1' },
        },
        { apple, db },
      );
      assert.strictEqual(r.repository_applied, true);
      assert.strictEqual(r.granted, false);
      assert.strictEqual(r.resonance_access, false);

      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-4', { db });
      assert.strictEqual(snapshot.subscription_state, 'expired');
      assert.strictEqual(snapshot.resonance_access, false);
    });
  });
});
