'use strict';

const assert = require('assert');
const { NotificationTypeV2, Status } = require('@apple/app-store-server-library');
const {
  handleAppleAssnNotification,
  mapAssnTypeToLifecycleHint,
} = require('../src/store_notification_apple');
const {
  handlePlayRtdnNotification,
  parseRtdnPubSubInput,
  SUB_NOTIFICATION,
} = require('../src/store_notification_play');
const {
  upsertPurchaseIndex,
  appleOriginalIndexId,
  androidTokenIndexId,
} = require('../src/store_purchase_index');
const {
  STORE_PRODUCT_IDS,
  CANONICAL_PRODUCT_KEYS,
  VERIFICATION_NOT_CONFIGURED,
} = require('../src/entitlement_schema');
const {
  getOrCreateEntitlementSnapshot,
} = require('../src/entitlement_repository');
const { MemoryFirestore } = require('./memory_firestore');

function appleAssnOpts(db, overrides = {}) {
  return {
    db,
    verifyAndDecodeNotification: async () => ({
      notificationType: NotificationTypeV2.DID_RENEW,
      notificationUUID: 'uuid-renew-1',
      data: {
        signedTransactionInfo: 'signed.txn',
      },
    }),
    verifySignedTransaction: async () => ({
      productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
      transactionId: 'txn-100',
      originalTransactionId: 'orig-100',
      appAccountToken: 'uid-assn',
    }),
    fetchTransactionInfo: async () => ({
      productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
      transactionId: 'txn-100',
      originalTransactionId: 'orig-100',
      appAccountToken: 'uid-assn',
      expiresDate: Date.now() + 86400000,
    }),
    fetchSubscriptionStatuses: async () => ({
      data: [{ lastTransactions: [{ status: Status.ACTIVE }] }],
    }),
    apple: { credentials: { configured: true } },
    ...overrides,
  };
}

describe('store_notification_foundation_v1', () => {
  describe('Apple ASSN v2', () => {
    it('maps lifecycle hints', () => {
      assert.strictEqual(
        mapAssnTypeToLifecycleHint(NotificationTypeV2.DID_RENEW),
        'renew',
      );
      assert.strictEqual(
        mapAssnTypeToLifecycleHint(NotificationTypeV2.EXPIRED),
        'expire',
      );
      assert.strictEqual(
        mapAssnTypeToLifecycleHint(NotificationTypeV2.REFUND),
        'revoke',
      );
      assert.strictEqual(
        mapAssnTypeToLifecycleHint(NotificationTypeV2.DID_FAIL_TO_RENEW),
        'billing_or_grace',
      );
    });

    it('renew re-fetches and grants Resonance', async () => {
      const db = new MemoryFirestore();
      await upsertPurchaseIndex(
        {
          indexId: appleOriginalIndexId('orig-100'),
          uid: 'uid-assn',
          platform: 'ios',
        },
        { db },
      );

      const r = await handleAppleAssnNotification(
        { signedPayload: 'signed.payload' },
        appleAssnOpts(db),
      );
      assert.strictEqual(r.code, 'assn_processed');
      assert.strictEqual(r.repository_applied, true);
      assert.strictEqual(r.resonance_access, true);

      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-assn', {
        db,
      });
      assert.strictEqual(snapshot.resonance_access, true);
      assert.strictEqual(
        snapshot.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
      );
    });

    it('duplicate notificationUUID is idempotent', async () => {
      const db = new MemoryFirestore();
      await upsertPurchaseIndex(
        {
          indexId: appleOriginalIndexId('orig-100'),
          uid: 'uid-assn',
          platform: 'ios',
        },
        { db },
      );
      const opts = appleAssnOpts(db);
      const first = await handleAppleAssnNotification(
        { signedPayload: 'x' },
        opts,
      );
      const second = await handleAppleAssnNotification(
        { signedPayload: 'x' },
        opts,
      );
      assert.strictEqual(first.apply_status, 'applied');
      assert.strictEqual(second.apply_status, 'noop');
    });

    it('expire denies Resonance after authoritative re-fetch', async () => {
      const db = new MemoryFirestore();
      await upsertPurchaseIndex(
        {
          indexId: appleOriginalIndexId('orig-exp'),
          uid: 'uid-assn',
          platform: 'ios',
        },
        { db },
      );
      const r = await handleAppleAssnNotification(
        { signedPayload: 'x' },
        appleAssnOpts(db, {
          verifyAndDecodeNotification: async () => ({
            notificationType: NotificationTypeV2.EXPIRED,
            notificationUUID: 'uuid-exp',
            data: { signedTransactionInfo: 's' },
          }),
          verifySignedTransaction: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
            transactionId: 'txn-exp',
            originalTransactionId: 'orig-exp',
            appAccountToken: 'uid-assn',
          }),
          fetchTransactionInfo: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
            transactionId: 'txn-exp',
            originalTransactionId: 'orig-exp',
            appAccountToken: 'uid-assn',
            expiresDate: Date.now() - 1000,
          }),
          fetchSubscriptionStatuses: async () => ({
            data: [{ lastTransactions: [{ status: Status.EXPIRED }] }],
          }),
        }),
      );
      assert.strictEqual(r.resonance_access, false);
      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-assn', {
        db,
      });
      assert.strictEqual(snapshot.subscription_state, 'expired');
    });

    it('revoke/refund denies access', async () => {
      const db = new MemoryFirestore();
      const r = await handleAppleAssnNotification(
        { signedPayload: 'x' },
        appleAssnOpts(db, {
          verifyAndDecodeNotification: async () => ({
            notificationType: NotificationTypeV2.REVOKE,
            notificationUUID: 'uuid-rev',
            data: { signedTransactionInfo: 's' },
          }),
          verifySignedTransaction: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_ANNUAL,
            transactionId: 'txn-rev',
            originalTransactionId: 'orig-rev',
            appAccountToken: 'uid-assn',
          }),
          fetchTransactionInfo: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_ANNUAL,
            transactionId: 'txn-rev',
            originalTransactionId: 'orig-rev',
            appAccountToken: 'uid-assn',
            revocationDate: Date.now(),
          }),
          fetchSubscriptionStatuses: async () => ({
            data: [{ lastTransactions: [{ status: Status.REVOKED }] }],
          }),
        }),
      );
      assert.strictEqual(r.resonance_access, false);
    });

    it('billing/grace maps from re-fetched status', async () => {
      const db = new MemoryFirestore();
      const r = await handleAppleAssnNotification(
        { signedPayload: 'x' },
        appleAssnOpts(db, {
          verifyAndDecodeNotification: async () => ({
            notificationType: NotificationTypeV2.DID_FAIL_TO_RENEW,
            notificationUUID: 'uuid-grace',
            data: { signedTransactionInfo: 's' },
          }),
          verifySignedTransaction: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
            transactionId: 'txn-g',
            originalTransactionId: 'orig-g',
            appAccountToken: 'uid-assn',
          }),
          fetchTransactionInfo: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
            transactionId: 'txn-g',
            originalTransactionId: 'orig-g',
            appAccountToken: 'uid-assn',
          }),
          fetchSubscriptionStatuses: async () => ({
            data: [
              {
                lastTransactions: [{ status: Status.BILLING_GRACE_PERIOD }],
              },
            ],
          }),
        }),
      );
      assert.strictEqual(r.resonance_access, true);
      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-assn', {
        db,
      });
      assert.strictEqual(snapshot.subscription_state, 'grace');
    });

    it('invalid signature fails closed', async () => {
      const r = await handleAppleAssnNotification(
        { signedPayload: 'bad' },
        {
          verifyAndDecodeNotification: async () => {
            throw new Error('bad sig');
          },
        },
      );
      assert.strictEqual(r.code, 'invalid_jws');
      assert.strictEqual(r.ok, false);
    });

    it('unknown product fails closed', async () => {
      const r = await handleAppleAssnNotification(
        { signedPayload: 'x' },
        appleAssnOpts(new MemoryFirestore(), {
          verifySignedTransaction: async () => ({
            productId: 'qmatch.orbit.monthly',
            transactionId: 't',
            originalTransactionId: 'o',
            appAccountToken: 'uid-assn',
          }),
        }),
      );
      assert.strictEqual(r.code, 'product_not_allowed');
    });

    it('API failure fails closed', async () => {
      const db = new MemoryFirestore();
      const r = await handleAppleAssnNotification(
        { signedPayload: 'x' },
        appleAssnOpts(db, {
          fetchTransactionInfo: async () => {
            throw new Error('503');
          },
        }),
      );
      assert.strictEqual(r.code, 'store_verification_failed');
    });

    it('missing config fails closed', async () => {
      const r = await handleAppleAssnNotification(
        { signedPayload: 'x' },
        { env: {} },
      );
      assert.strictEqual(r.code, VERIFICATION_NOT_CONFIGURED);
    });

    it('unknown uid fails closed', async () => {
      const r = await handleAppleAssnNotification(
        { signedPayload: 'x' },
        appleAssnOpts(new MemoryFirestore(), {
          verifySignedTransaction: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
            transactionId: 't',
            originalTransactionId: 'unknown-orig',
            // no appAccountToken
          }),
        }),
      );
      assert.strictEqual(r.code, 'unknown_uid');
    });
  });

  describe('Google RTDN', () => {
    it('parses pubsub envelope', () => {
      const note = {
        packageName: 'com.qmatch.app',
        subscriptionNotification: {
          notificationType: SUB_NOTIFICATION.RENEWED,
          purchaseToken: 'tok-1',
        },
      };
      const parsed = parseRtdnPubSubInput({
        message: {
          messageId: 'msg-1',
          data: Buffer.from(JSON.stringify(note), 'utf8').toString('base64'),
        },
      });
      assert.strictEqual(parsed.ok, true);
      assert.strictEqual(parsed.messageId, 'msg-1');
    });

    it('renew re-fetches Play state and applies', async () => {
      const db = new MemoryFirestore();
      await upsertPurchaseIndex(
        {
          indexId: androidTokenIndexId('tok-renew'),
          uid: 'uid-rtdn',
          platform: 'android',
        },
        { db },
      );

      const r = await handlePlayRtdnNotification(
        {
          messageId: 'msg-renew',
          developerNotification: {
            subscriptionNotification: {
              notificationType: SUB_NOTIFICATION.RENEWED,
              purchaseToken: 'tok-renew',
            },
          },
        },
        {
          db,
          play: {
            credentials: { configured: true },
            fetchSubscription: async () => ({
              subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
              lineItems: [
                {
                  productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
                  offerDetails: { basePlanId: 'monthly' },
                },
              ],
              acknowledgementState: 1,
              obfuscatedExternalAccountId: 'uid-rtdn',
            }),
            acknowledgeSubscription: async () => {},
          },
        },
      );
      assert.strictEqual(r.code, 'rtdn_processed');
      assert.strictEqual(r.resonance_access, true);
    });

    it('duplicate messageId is idempotent', async () => {
      const db = new MemoryFirestore();
      await upsertPurchaseIndex(
        {
          indexId: androidTokenIndexId('tok-dup'),
          uid: 'uid-rtdn',
          platform: 'android',
        },
        { db },
      );
      const deps = {
        db,
        play: {
          credentials: { configured: true },
          fetchSubscription: async () => ({
            subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
            lineItems: [
              {
                productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
                offerDetails: { basePlanId: 'annual' },
              },
            ],
            acknowledgementState: 1,
          }),
          acknowledgeSubscription: async () => {},
        },
      };
      const body = {
        messageId: 'msg-dup',
        developerNotification: {
          subscriptionNotification: {
            notificationType: SUB_NOTIFICATION.RENEWED,
            purchaseToken: 'tok-dup',
          },
        },
      };
      const first = await handlePlayRtdnNotification(body, deps);
      const second = await handlePlayRtdnNotification(body, deps);
      assert.strictEqual(first.apply_status, 'applied');
      assert.strictEqual(second.apply_status, 'noop');
    });

    it('expire/revoke deny Resonance after re-fetch', async () => {
      const db = new MemoryFirestore();
      await upsertPurchaseIndex(
        {
          indexId: androidTokenIndexId('tok-exp'),
          uid: 'uid-rtdn',
          platform: 'android',
        },
        { db },
      );
      const expired = await handlePlayRtdnNotification(
        {
          messageId: 'msg-exp',
          developerNotification: {
            subscriptionNotification: {
              notificationType: SUB_NOTIFICATION.EXPIRED,
              purchaseToken: 'tok-exp',
            },
          },
        },
        {
          db,
          play: {
            credentials: { configured: true },
            fetchSubscription: async () => ({
              subscriptionState: 'SUBSCRIPTION_STATE_EXPIRED',
              lineItems: [
                {
                  productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
                  offerDetails: { basePlanId: 'monthly' },
                },
              ],
            }),
          },
        },
      );
      assert.strictEqual(expired.resonance_access, false);
    });

    it('billing/grace from re-fetched Play state', async () => {
      const db = new MemoryFirestore();
      await upsertPurchaseIndex(
        {
          indexId: androidTokenIndexId('tok-grace'),
          uid: 'uid-rtdn',
          platform: 'android',
        },
        { db },
      );
      const r = await handlePlayRtdnNotification(
        {
          messageId: 'msg-grace',
          developerNotification: {
            subscriptionNotification: {
              notificationType: SUB_NOTIFICATION.IN_GRACE_PERIOD,
              purchaseToken: 'tok-grace',
            },
          },
        },
        {
          db,
          play: {
            credentials: { configured: true },
            fetchSubscription: async () => ({
              subscriptionState: 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
              lineItems: [
                {
                  productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
                  offerDetails: { basePlanId: 'monthly' },
                },
              ],
            }),
          },
        },
      );
      assert.strictEqual(r.resonance_access, true);
      const { snapshot } = await getOrCreateEntitlementSnapshot('uid-rtdn', {
        db,
      });
      assert.strictEqual(snapshot.subscription_state, 'grace');
    });

    it('invalid message fails closed', async () => {
      const r = await handlePlayRtdnNotification(
        { message: { messageId: 'm', data: '!!!' } },
        {
          play: {
            credentials: { configured: true },
            fetchSubscription: async () => ({}),
          },
        },
      );
      assert.strictEqual(r.code, 'invalid_message');
    });

    it('unknown product fails closed', async () => {
      const db = new MemoryFirestore();
      await upsertPurchaseIndex(
        {
          indexId: androidTokenIndexId('tok-bad'),
          uid: 'uid-rtdn',
          platform: 'android',
        },
        { db },
      );
      const r = await handlePlayRtdnNotification(
        {
          messageId: 'msg-bad',
          developerNotification: {
            oneTimeProductNotification: {
              notificationType: 1,
              purchaseToken: 'tok-bad',
              sku: 'qmatch.orbit.x1',
            },
          },
        },
        {
          db,
          play: {
            credentials: { configured: true },
            fetchProductPurchase: async () => ({ purchaseState: 0 }),
          },
        },
      );
      assert.strictEqual(r.code, 'product_not_allowed');
    });

    it('API failure fails closed', async () => {
      const db = new MemoryFirestore();
      await upsertPurchaseIndex(
        {
          indexId: androidTokenIndexId('tok-api'),
          uid: 'uid-rtdn',
          platform: 'android',
        },
        { db },
      );
      const r = await handlePlayRtdnNotification(
        {
          messageId: 'msg-api',
          developerNotification: {
            subscriptionNotification: {
              notificationType: SUB_NOTIFICATION.RENEWED,
              purchaseToken: 'tok-api',
            },
          },
        },
        {
          db,
          play: {
            credentials: { configured: true },
            fetchSubscription: async () => {
              throw new Error('503');
            },
          },
        },
      );
      assert.strictEqual(r.code, 'store_verification_failed');
    });

    it('unknown uid fails closed', async () => {
      const r = await handlePlayRtdnNotification(
        {
          messageId: 'msg-uid',
          developerNotification: {
            subscriptionNotification: {
              notificationType: SUB_NOTIFICATION.RENEWED,
              purchaseToken: 'tok-missing',
            },
          },
        },
        {
          db: new MemoryFirestore(),
          play: {
            credentials: { configured: true },
            fetchSubscription: async () => ({
              subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
              lineItems: [
                {
                  productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
                  offerDetails: { basePlanId: 'monthly' },
                },
              ],
            }),
          },
        },
      );
      assert.strictEqual(r.code, 'unknown_uid');
    });
  });
});
