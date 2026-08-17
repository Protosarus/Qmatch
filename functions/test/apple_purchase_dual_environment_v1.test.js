'use strict';

const { appleAppAccountTokenFromUid } = require('../src/apple_app_account_token');

const assert = require('assert');
const {
  Environment,
  Status,
  VerificationException,
  VerificationStatus,
} = require('@apple/app-store-server-library');
const {
  verifyApplePurchase,
  isAppleEnvironmentMismatchError,
  APPLE_TRANSACTION_ID_NOT_FOUND,
} = require('../src/store_verify_apple');
const { isTrustedVerified } = require('../src/store_verification_result');
const {
  handleVerifyAndApplyPurchase,
  handleRestorePurchases,
} = require('../src/entitlement_callables');
const { STORE_PRODUCT_IDS } = require('../src/entitlement_schema');
const {
  getOrCreateEntitlementSnapshot,
} = require('../src/entitlement_repository');
const { APPLE_STOREKIT_API_HOST } = require('../src/apple_iap_clients');
const { MemoryFirestore } = require('./memory_firestore');

function trustedTransaction(uid, overrides = {}) {
  return {
    productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
    transactionId: 'txn-dual-1',
    originalTransactionId: 'orig-dual-1',
    appAccountToken: appleAppAccountTokenFromUid(uid),
    expiresDate: Date.now() + 86400000,
    ...overrides,
  };
}

function envMismatchError() {
  return new VerificationException(VerificationStatus.INVALID_ENVIRONMENT);
}

function txnNotFoundError() {
  const err = new Error('TransactionIdNotFoundError');
  err.apiError = APPLE_TRANSACTION_ID_NOT_FOUND;
  err.httpStatusCode = 404;
  return err;
}

function dualPurchaseClientsMock({
  sandboxAccepts,
  productionAccepts,
  transaction,
}) {
  const counts = {
    sandbox: { jws: 0, api: 0, status: 0 },
    production: { jws: 0, api: 0, status: 0 },
  };

  function envHelpers(label, accepts, environment) {
    return {
      environment,
      apiHost: APPLE_STOREKIT_API_HOST[environment],
      verifySignedTransaction: async () => {
        counts[label].jws += 1;
        if (!accepts) throw envMismatchError();
        return transaction;
      },
      fetchTransactionInfo: async () => {
        counts[label].api += 1;
        if (!accepts) throw txnNotFoundError();
        return transaction;
      },
      fetchSubscriptionStatuses: async () => {
        counts[label].status += 1;
        return {
          data: [{ lastTransactions: [{ status: Status.ACTIVE }] }],
        };
      },
    };
  }

  return {
    ok: true,
    sandbox: envHelpers('sandbox', sandboxAccepts, Environment.SANDBOX),
    production: envHelpers(
      'production',
      productionAccepts,
      Environment.PRODUCTION,
    ),
    counts,
  };
}

function appleDualOpts(dual, extra = {}) {
  return {
    credentials: { configured: true },
    requireBinding: true,
    dualAppleClients: dual,
    ...extra,
  };
}

describe('apple_purchase_dual_environment_v1', () => {
  it('detects Apple environment mismatch errors', () => {
    assert.strictEqual(isAppleEnvironmentMismatchError(envMismatchError()), true);
    assert.strictEqual(isAppleEnvironmentMismatchError(txnNotFoundError()), true);
    assert.strictEqual(
      isAppleEnvironmentMismatchError(new Error('invalid signature')),
      false,
    );
    assert.strictEqual(
      isAppleEnvironmentMismatchError(new Error('503')),
      false,
    );
  });

  it('Sandbox succeeds without calling Production', async () => {
    const uid = 'uid-sandbox';
    const txn = trustedTransaction(uid);
    const dual = dualPurchaseClientsMock({
      sandboxAccepts: true,
      productionAccepts: false,
      transaction: txn,
    });

    const r = await verifyApplePurchase(
      {
        callerUid: uid,
        signedTransaction: 'signed.sandbox.jws',
        transactionId: txn.transactionId,
      },
      appleDualOpts(dual),
    );

    assert.strictEqual(isTrustedVerified(r), true);
    assert.strictEqual(r.resonance_access, true);
    assert.strictEqual(r.apple_environment, Environment.SANDBOX);
    assert.strictEqual(
      r.api_host,
      APPLE_STOREKIT_API_HOST[Environment.SANDBOX],
    );
    assert.strictEqual(dual.counts.sandbox.jws, 1);
    assert.strictEqual(dual.counts.sandbox.api, 1);
    assert.strictEqual(dual.counts.production.jws, 0);
    assert.strictEqual(dual.counts.production.api, 0);
  });

  it('Production succeeds without calling Sandbox when preferred', async () => {
    const uid = 'uid-production';
    const txn = trustedTransaction(uid, { transactionId: 'txn-prod-1' });
    const dual = dualPurchaseClientsMock({
      sandboxAccepts: false,
      productionAccepts: true,
      transaction: txn,
    });

    const r = await verifyApplePurchase(
      {
        callerUid: uid,
        signedTransaction: 'signed.production.jws',
        transactionId: txn.transactionId,
      },
      appleDualOpts(dual, {
        preferredEnvironment: Environment.PRODUCTION,
      }),
    );

    assert.strictEqual(isTrustedVerified(r), true);
    assert.strictEqual(r.resonance_access, true);
    assert.strictEqual(r.apple_environment, Environment.PRODUCTION);
    assert.strictEqual(
      r.api_host,
      APPLE_STOREKIT_API_HOST[Environment.PRODUCTION],
    );
    assert.strictEqual(dual.counts.production.jws, 1);
    assert.strictEqual(dual.counts.production.api, 1);
    assert.strictEqual(dual.counts.sandbox.jws, 0);
    assert.strictEqual(dual.counts.sandbox.api, 0);
  });

  it('first environment mismatch then second succeeds', async () => {
    const uid = 'uid-fallback';
    const txn = trustedTransaction(uid, { transactionId: 'txn-fallback-1' });
    const dual = dualPurchaseClientsMock({
      sandboxAccepts: false,
      productionAccepts: true,
      transaction: txn,
    });

    const r = await verifyApplePurchase(
      {
        callerUid: uid,
        signedTransaction: 'signed.production.jws',
        transactionId: txn.transactionId,
      },
      appleDualOpts(dual),
    );

    assert.strictEqual(isTrustedVerified(r), true);
    assert.strictEqual(r.apple_environment, Environment.PRODUCTION);
    assert.strictEqual(dual.counts.sandbox.jws, 1);
    assert.strictEqual(dual.counts.sandbox.api, 0);
    assert.strictEqual(dual.counts.production.jws, 1);
    assert.strictEqual(dual.counts.production.api, 1);
  });

  it('both environments fail closed — no grant', async () => {
    const uid = 'uid-both-fail';
    const txn = trustedTransaction(uid, { transactionId: 'txn-missing' });
    const dual = dualPurchaseClientsMock({
      sandboxAccepts: false,
      productionAccepts: false,
      transaction: txn,
    });
    const db = new MemoryFirestore();

    const verified = await verifyApplePurchase(
      {
        callerUid: uid,
        signedTransaction: 'signed.bad.jws',
        transactionId: txn.transactionId,
      },
      appleDualOpts(dual),
    );
    assert.strictEqual(isTrustedVerified(verified), false);
    assert.strictEqual(verified.ok, false);
    assert.strictEqual(verified.resonance_access, false);
    assert.strictEqual(verified.reason, 'environment_mismatch');

    const applied = await handleVerifyAndApplyPurchase(
      {
        auth: { uid },
        data: {
          platform: 'ios',
          signedTransaction: 'signed.bad.jws',
          transactionId: txn.transactionId,
        },
      },
      { apple: appleDualOpts(dual), db },
    );
    assert.strictEqual(applied.granted, false);
    assert.strictEqual(applied.repository_applied, false);
    assert.strictEqual(applied.resonance_access, false);

    const { snapshot } = await getOrCreateEntitlementSnapshot(uid, { db });
    assert.strictEqual(snapshot.tier, 'free');
    assert.strictEqual(snapshot.resonance_access, false);

    const ledger = await db
      .doc(`entitlements/${uid}/purchase_ledger/ios:${txn.transactionId}`)
      .get();
    assert.strictEqual(ledger.exists, false);
  });

  it('restorePurchases uses the same dual-environment verify path', async () => {
    const uid = 'uid-restore-dual';
    const txn = trustedTransaction(uid, { transactionId: 'txn-restore-dual' });
    const dual = dualPurchaseClientsMock({
      sandboxAccepts: false,
      productionAccepts: true,
      transaction: txn,
    });
    const db = new MemoryFirestore();

    const r = await handleRestorePurchases(
      {
        auth: { uid },
        data: {
          platform: 'ios',
          transactions: [
            {
              signedTransaction: 'signed.restore.jws',
              transactionId: txn.transactionId,
            },
          ],
        },
      },
      { apple: appleDualOpts(dual), db },
    );

    assert.strictEqual(r.code, 'restore_processed');
    assert.strictEqual(r.granted, true);
    assert.strictEqual(r.resonance_access, true);
    assert.strictEqual(r.results[0].verification_source, 'restore');
    assert.strictEqual(r.results[0].apple_environment, Environment.PRODUCTION);
    assert.strictEqual(dual.counts.sandbox.jws, 1);
    assert.strictEqual(dual.counts.production.jws, 1);
    assert.strictEqual(dual.counts.production.api, 1);

    const { snapshot } = await getOrCreateEntitlementSnapshot(uid, { db });
    assert.strictEqual(snapshot.resonance_access, true);
  });

  it('retries do not duplicate ledger or grant', async () => {
    const uid = 'uid-idempotent-dual';
    const txn = trustedTransaction(uid, { transactionId: 'txn-idem-dual' });
    const dual = dualPurchaseClientsMock({
      sandboxAccepts: false,
      productionAccepts: true,
      transaction: txn,
    });
    const db = new MemoryFirestore();
    const req = {
      auth: { uid },
      data: {
        platform: 'ios',
        signedTransaction: 'signed.prod.jws',
        transactionId: txn.transactionId,
      },
    };
    const deps = { apple: appleDualOpts(dual), db };

    const first = await handleVerifyAndApplyPurchase(req, deps);
    assert.strictEqual(first.repository_applied, true);
    assert.strictEqual(first.apply_status, 'applied');
    assert.strictEqual(first.granted, true);
    assert.strictEqual(first.resonance_access, true);
    assert.strictEqual(first.apple_environment, Environment.PRODUCTION);

    const second = await handleVerifyAndApplyPurchase(req, deps);
    assert.strictEqual(second.repository_applied, true);
    assert.strictEqual(second.apply_status, 'noop');
    assert.strictEqual(second.granted, true);
    assert.strictEqual(second.resonance_access, true);

    const { snapshot } = await getOrCreateEntitlementSnapshot(uid, { db });
    assert.strictEqual(snapshot.tier, 'resonance');
    assert.strictEqual(snapshot.resonance_access, true);

    const ledger = await db
      .doc(`entitlements/${uid}/purchase_ledger/ios:${txn.transactionId}`)
      .get();
    assert.strictEqual(ledger.exists, true);
    assert.strictEqual(ledger.data().store_transaction_id, txn.transactionId);

    assert.strictEqual(dual.counts.sandbox.jws, 2);
    assert.strictEqual(dual.counts.production.api, 2);
    assert.strictEqual(dual.counts.sandbox.api, 0);
  });
});
