'use strict';

const { appleAppAccountTokenFromUid } = require('../src/apple_app_account_token');

const assert = require('assert');
const { Status } = require('@apple/app-store-server-library');
const {
  handleRestorePurchases,
  normalizeAppleRestoreItems,
} = require('../src/entitlement_callables');
const {
  STORE_PRODUCT_IDS,
  CANONICAL_PRODUCT_KEYS,
  VERIFICATION_NOT_CONFIGURED,
  EVENT_TYPES,
} = require('../src/entitlement_schema');
const {
  getOrCreateEntitlementSnapshot,
} = require('../src/entitlement_repository');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');

function appleRestoreDeps(db, overrides = {}) {
  return {
    db,
    apple: {
      credentials: { configured: true },
      verifySignedTransaction: async () => ({
        productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
        transactionId: 'txn-restore-1',
        originalTransactionId: 'orig-restore-1',
        appAccountToken: appleAppAccountTokenFromUid('uid-restore'),
        expiresDate: Date.now() + 86400000,
      }),
      fetchTransactionInfo: async () => ({
        productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
        transactionId: 'txn-restore-1',
        originalTransactionId: 'orig-restore-1',
        appAccountToken: appleAppAccountTokenFromUid('uid-restore'),
        expiresDate: Date.now() + 86400000,
      }),
      fetchSubscriptionStatuses: async () => ({
        data: [{ lastTransactions: [{ status: Status.ACTIVE }] }],
      }),
      ...(overrides.apple || {}),
    },
    ...overrides,
  };
}

describe('apple_restore_purchases_v1', () => {
  it('normalizes restore transaction inputs', () => {
    const items = normalizeAppleRestoreItems({
      transactions: [
        { signedTransaction: 's1', transactionId: 't1' },
        { id: 'ignored' },
      ],
      signedTransactions: ['s2'],
      signedTransaction: 's3',
      transactionId: 't3',
    });
    assert.strictEqual(items.length, 3);
    assert.strictEqual(items[0].signedTransaction, 's1');
    assert.strictEqual(items[1].signedTransaction, 's2');
    assert.strictEqual(items[2].signedTransaction, 's3');
    assert.strictEqual(items[2].transactionId, 't3');
  });

  it('requires authentication', async () => {
    await assert.rejects(
      () =>
        handleRestorePurchases({
          auth: null,
          data: { platform: 'ios', transactionId: 't' },
        }),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
  });

  it('android restore remains fail-closed', async () => {
    const r = await handleRestorePurchases({
      auth: { uid: 'uid-restore' },
      data: {
        platform: 'android',
        purchaseToken: 'tok',
        productId: STORE_PRODUCT_IDS.PLAY_RESONANCE,
        grant: true,
      },
    });
    assert.strictEqual(r.code, VERIFICATION_NOT_CONFIGURED);
    assert.strictEqual(r.granted, false);
    assert.strictEqual(r.repository_applied, false);
  });

  it('rejects client entitlement claims', async () => {
    const r = await handleRestorePurchases({
      auth: { uid: 'uid-restore' },
      data: {
        platform: 'ios',
        transactionId: 'txn-restore-1',
        resonance_access: true,
        grant: true,
      },
    });
    assert.strictEqual(r.code, VERIFICATION_NOT_CONFIGURED);
    assert.strictEqual(r.granted, false);
  });

  it('restores Apple subscription after authoritative re-fetch + uid bind', async () => {
    const db = new MemoryFirestore();
    const r = await handleRestorePurchases(
      {
        auth: { uid: 'uid-restore' },
        data: {
          platform: 'ios',
          transactions: [
            {
              signedTransaction: 'signed.txn',
              transactionId: 'txn-restore-1',
            },
          ],
        },
      },
      appleRestoreDeps(db),
    );

    assert.strictEqual(r.code, 'restore_processed');
    assert.strictEqual(r.granted, true);
    assert.strictEqual(r.resonance_access, true);
    assert.strictEqual(r.repository_applied, true);
    assert.strictEqual(r.results[0].verification_source, 'restore');

    const { snapshot } = await getOrCreateEntitlementSnapshot('uid-restore', {
      db,
    });
    assert.strictEqual(snapshot.resonance_access, true);
    assert.strictEqual(
      snapshot.canonical_product_key,
      CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
    );

    const ledger = await db
      .doc('entitlements/uid-restore/purchase_ledger/ios:txn-restore-1')
      .get();
    assert.strictEqual(ledger.exists, true);
    assert.strictEqual(ledger.data().event_type, EVENT_TYPES.SUBSCRIPTION_RESTORE);
    assert.strictEqual(ledger.data().verification_source, 'restore');
  });

  it('restore is idempotent on duplicate transaction', async () => {
    const db = new MemoryFirestore();
    const deps = appleRestoreDeps(db);
    const req = {
      auth: { uid: 'uid-restore' },
      data: {
        platform: 'ios',
        transactionId: 'txn-restore-1',
        signedTransaction: 'signed.txn',
      },
    };
    const first = await handleRestorePurchases(req, deps);
    const second = await handleRestorePurchases(req, deps);
    assert.strictEqual(first.apply_status || first.results[0].apply_status, 'applied');
    assert.strictEqual(second.results[0].apply_status, 'noop');
    assert.strictEqual(second.resonance_access, true);
  });

  it('rejects appAccountToken mismatch', async () => {
    const db = new MemoryFirestore();
    const r = await handleRestorePurchases(
      {
        auth: { uid: 'uid-restore' },
        data: {
          platform: 'ios',
          transactionId: 'txn-restore-1',
          signedTransaction: 'signed.txn',
        },
      },
      appleRestoreDeps(db, {
        apple: {
          credentials: { configured: true },
          verifySignedTransaction: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
            transactionId: 'txn-restore-1',
            originalTransactionId: 'orig-restore-1',
            appAccountToken: appleAppAccountTokenFromUid('other-uid'),
          }),
          fetchTransactionInfo: async () => ({
            productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
            transactionId: 'txn-restore-1',
            originalTransactionId: 'orig-restore-1',
            appAccountToken: appleAppAccountTokenFromUid('other-uid'),
            expiresDate: Date.now() + 86400000,
          }),
          fetchSubscriptionStatuses: async () => ({
            data: [{ lastTransactions: [{ status: Status.ACTIVE }] }],
          }),
        },
      }),
    );
    assert.strictEqual(r.granted, false);
    assert.strictEqual(r.results[0].code, 'uid_binding_mismatch');
  });

  it('rejects unknown Apple product', async () => {
    const db = new MemoryFirestore();
    const r = await handleRestorePurchases(
      {
        auth: { uid: 'uid-restore' },
        data: {
          platform: 'ios',
          transactionId: 'txn-bad',
          signedTransaction: 'signed.txn',
        },
      },
      appleRestoreDeps(db, {
        apple: {
          credentials: { configured: true },
          verifySignedTransaction: async () => ({
            productId: 'qmatch.orbit.monthly',
            transactionId: 'txn-bad',
            originalTransactionId: 'orig-bad',
            appAccountToken: appleAppAccountTokenFromUid('uid-restore'),
          }),
          fetchTransactionInfo: async () => ({
            productId: 'qmatch.orbit.monthly',
            transactionId: 'txn-bad',
            originalTransactionId: 'orig-bad',
            appAccountToken: appleAppAccountTokenFromUid('uid-restore'),
          }),
          fetchSubscriptionStatuses: async () => ({ data: [] }),
        },
      }),
    );
    assert.strictEqual(r.granted, false);
    assert.strictEqual(r.results[0].code, 'product_not_allowed');
  });

  it('credits consumable restore through ledger only', async () => {
    const db = new MemoryFirestore();
    const r = await handleRestorePurchases(
      {
        auth: { uid: 'uid-restore' },
        data: {
          platform: 'ios',
          transactionId: 'txn-boost-1',
          signedTransaction: 'signed.boost',
        },
      },
      appleRestoreDeps(db, {
        apple: {
          credentials: { configured: true },
          verifySignedTransaction: async () => ({
            productId: STORE_PRODUCT_IDS.BOOST_X1,
            transactionId: 'txn-boost-1',
            originalTransactionId: 'txn-boost-1',
            appAccountToken: appleAppAccountTokenFromUid('uid-restore'),
          }),
          fetchTransactionInfo: async () => ({
            productId: STORE_PRODUCT_IDS.BOOST_X1,
            transactionId: 'txn-boost-1',
            originalTransactionId: 'txn-boost-1',
            appAccountToken: appleAppAccountTokenFromUid('uid-restore'),
          }),
        },
      }),
    );
    assert.strictEqual(r.results[0].kind, 'consumable');
    assert.strictEqual(r.balances_changed, true);
    assert.strictEqual(r.granted, false);
    const { snapshot } = await getOrCreateEntitlementSnapshot('uid-restore', {
      db,
    });
    assert.strictEqual(snapshot.boost_balance, 1);
    assert.strictEqual(snapshot.resonance_access, false);

    const ledger = await db
      .doc('entitlements/uid-restore/purchase_ledger/ios:txn-boost-1')
      .get();
    assert.strictEqual(
      ledger.data().event_type,
      EVENT_TYPES.CONSUMABLE_RESTORE_CREDIT,
    );
  });
});
