'use strict';

const assert = require('assert');
const {
  Environment,
  NotificationTypeV2,
  Status,
  VerificationException,
  VerificationStatus,
} = require('@apple/app-store-server-library');
const {
  verifyAssnSignedPayload,
  handleAppleAssnNotification,
} = require('../src/store_notification_apple');
const {
  APPLE_STOREKIT_API_HOST,
  createDualAppleAssnClients,
} = require('../src/apple_iap_clients');
const { STORE_PRODUCT_IDS } = require('../src/entitlement_schema');
const { MemoryFirestore } = require('./memory_firestore');

function fakeDecoded(envLabel) {
  return {
    notificationType: NotificationTypeV2.TEST,
    notificationUUID: `uuid-${envLabel}`,
    data: { environment: envLabel },
  };
}

function dualClientsMock({ sandboxAccepts, productionAccepts }) {
  const sandboxClient = {
    id: 'sandbox-api',
    getTransactionInfo: async () => ({ signedTransactionInfo: 's' }),
  };
  const productionClient = {
    id: 'production-api',
    getTransactionInfo: async () => ({ signedTransactionInfo: 's' }),
  };

  return {
    ok: true,
    sandbox: {
      apiClient: sandboxClient,
      signedDataVerifier: {
        verifyAndDecodeNotification: async () => {
          if (!sandboxAccepts) {
            throw new VerificationException(
              VerificationStatus.INVALID_ENVIRONMENT,
            );
          }
          return fakeDecoded(Environment.SANDBOX);
        },
      },
      environment: Environment.SANDBOX,
      apiHost: APPLE_STOREKIT_API_HOST[Environment.SANDBOX],
    },
    production: {
      apiClient: productionClient,
      signedDataVerifier: {
        verifyAndDecodeNotification: async () => {
          if (!productionAccepts) {
            throw new VerificationException(
              VerificationStatus.INVALID_ENVIRONMENT,
            );
          }
          return fakeDecoded(Environment.PRODUCTION);
        },
      },
      environment: Environment.PRODUCTION,
      apiHost: APPLE_STOREKIT_API_HOST[Environment.PRODUCTION],
    },
  };
}

describe('apple_assn_dual_environment_v1', () => {
  it('accepts Sandbox notification via Sandbox verifier only', async () => {
    const dual = dualClientsMock({
      sandboxAccepts: true,
      productionAccepts: false,
    });
    const r = await verifyAssnSignedPayload('signed.sandbox', {
      dualAppleClients: dual,
    });
    assert.strictEqual(r.ok, true);
    assert.strictEqual(r.environment, Environment.SANDBOX);
    assert.strictEqual(r.apiClient.id, 'sandbox-api');
    assert.strictEqual(
      r.apiHost,
      APPLE_STOREKIT_API_HOST[Environment.SANDBOX],
    );

    const handled = await handleAppleAssnNotification(
      { signedPayload: 'signed.sandbox' },
      { dualAppleClients: dual },
    );
    assert.strictEqual(handled.code, 'assn_test_ack');
    assert.strictEqual(handled.apple_environment, Environment.SANDBOX);
  });

  it('accepts Production notification via Production verifier only', async () => {
    const dual = dualClientsMock({
      sandboxAccepts: false,
      productionAccepts: true,
    });
    const r = await verifyAssnSignedPayload('signed.production', {
      dualAppleClients: dual,
    });
    assert.strictEqual(r.ok, true);
    assert.strictEqual(r.environment, Environment.PRODUCTION);
    assert.strictEqual(r.apiClient.id, 'production-api');
    assert.strictEqual(
      r.apiHost,
      APPLE_STOREKIT_API_HOST[Environment.PRODUCTION],
    );

    const handled = await handleAppleAssnNotification(
      { signedPayload: 'signed.production' },
      { dualAppleClients: dual },
    );
    assert.strictEqual(handled.code, 'assn_test_ack');
    assert.strictEqual(handled.apple_environment, Environment.PRODUCTION);
  });

  it('rejects wrong-environment payload on the mismatched verifier', async () => {
    const dual = dualClientsMock({
      sandboxAccepts: false,
      productionAccepts: false,
    });

    // Direct mismatched verifier rejection.
    let threw = false;
    try {
      await dual.sandbox.signedDataVerifier.verifyAndDecodeNotification(
        'signed.production',
      );
    } catch (err) {
      threw = true;
      assert.ok(err instanceof VerificationException);
      assert.strictEqual(err.status, VerificationStatus.INVALID_ENVIRONMENT);
    }
    assert.strictEqual(threw, true);

    const r = await verifyAssnSignedPayload('signed.production', {
      dualAppleClients: dual,
    });
    assert.strictEqual(r.ok, false);
    assert.strictEqual(r.code, 'invalid_jws');

    const handled = await handleAppleAssnNotification(
      { signedPayload: 'signed.production' },
      { dualAppleClients: dual },
    );
    assert.strictEqual(handled.ok, false);
    assert.strictEqual(handled.code, 'invalid_jws');
  });

  it('selects matching API host/client after verification for re-fetch', async () => {
    const dual = dualClientsMock({
      sandboxAccepts: false,
      productionAccepts: true,
    });
    let usedClientId = null;

    const verified = await verifyAssnSignedPayload('signed.production', {
      dualAppleClients: dual,
    });
    assert.strictEqual(verified.ok, true);
    assert.strictEqual(verified.apiClient.id, 'production-api');
    assert.strictEqual(
      verified.apiHost,
      APPLE_STOREKIT_API_HOST[Environment.PRODUCTION],
    );

    const r = await handleAppleAssnNotification(
      { signedPayload: 'signed.production' },
      {
        db: new MemoryFirestore(),
        // No fetch injectors — re-fetch must use matched Production apiClient.
        verifyAssnDual: async () => ({
          ok: true,
          decoded: {
            notificationType: NotificationTypeV2.DID_RENEW,
            notificationUUID: 'uuid-prod-renew',
            data: { signedTransactionInfo: 'signed.txn' },
          },
          environment: Environment.PRODUCTION,
          apiClient: {
            id: 'production-api',
            getTransactionInfo: async () => {
              usedClientId = 'production-api';
              return { signedTransactionInfo: 'signed.txn.from.api' };
            },
            getAllSubscriptionStatuses: async () => ({
              data: [{ lastTransactions: [{ status: Status.ACTIVE }] }],
            }),
          },
          signedDataVerifier: {
            verifyAndDecodeTransaction: async () => ({
              productId: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
              transactionId: 'txn-prod',
              originalTransactionId: 'orig-prod',
              appAccountToken: 'uid-prod',
              expiresDate: Date.now() + 86400000,
            }),
          },
          apiHost: APPLE_STOREKIT_API_HOST[Environment.PRODUCTION],
        }),
        apple: { credentials: { configured: true } },
      },
    );

    assert.strictEqual(r.code, 'assn_processed');
    assert.strictEqual(r.apple_environment, Environment.PRODUCTION);
    assert.strictEqual(
      r.api_host,
      APPLE_STOREKIT_API_HOST[Environment.PRODUCTION],
    );
    assert.strictEqual(usedClientId, 'production-api');
  });

  it('createDualAppleAssnClients requires APPLE_IAP_APP_APPLE_ID for Production', () => {
    const missing = createDualAppleAssnClients({
      privateKey: 'k',
      keyId: 'KEY',
      issuerId: 'iss',
      bundleId: 'com.qmatch.app',
      environment: Environment.SANDBOX,
      enableOnlineChecks: false,
    });
    assert.strictEqual(missing.ok, false);
    assert.ok(missing.missing.includes('APPLE_IAP_APP_APPLE_ID'));
  });
});
