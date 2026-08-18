'use strict';

const assert = require('assert');
const {
  APPLE_IAP_SECRET_NAMES,
  PLAY_IAP_SECRET_NAMES,
  STORE_IAP_SECRET_NAMES,
  secretKeysFromFunction,
} = require('../src/store_iap_secrets');
const { loadAppleIapConfig } = require('../src/apple_iap_config');
const { loadPlayIapConfig } = require('../src/play_iap_config');

describe('store_iap_secrets_binding_v1', () => {
  const idx = require('../index.js');

  it('defines the frozen Apple + Play secret names', () => {
    assert.deepStrictEqual([...APPLE_IAP_SECRET_NAMES], [
      'APPLE_IAP_ISSUER_ID',
      'APPLE_IAP_KEY_ID',
      'APPLE_IAP_PRIVATE_KEY',
      'APPLE_IAP_BUNDLE_ID',
      'APPLE_IAP_ENVIRONMENT',
      'APPLE_IAP_APP_APPLE_ID',
    ]);
    assert.deepStrictEqual([...PLAY_IAP_SECRET_NAMES], [
      'PLAY_IAP_PACKAGE_NAME',
      'PLAY_IAP_CLIENT_EMAIL',
      'PLAY_IAP_PRIVATE_KEY',
    ]);
    assert.deepStrictEqual(
      [...STORE_IAP_SECRET_NAMES],
      [...APPLE_IAP_SECRET_NAMES, ...PLAY_IAP_SECRET_NAMES],
    );
  });

  it('wires Apple+Play secrets on verify and restore callables', () => {
    const verifyKeys = secretKeysFromFunction(idx.verifyAndApplyPurchase).sort();
    const restoreKeys = secretKeysFromFunction(idx.restorePurchases).sort();
    const expected = [...STORE_IAP_SECRET_NAMES].sort();
    assert.deepStrictEqual(verifyKeys, expected);
    assert.deepStrictEqual(restoreKeys, expected);
  });

  it('wires Apple-only secrets on ASSN and Play-only on RTDN', () => {
    assert.deepStrictEqual(
      secretKeysFromFunction(idx.appStoreServerNotification).sort(),
      [...APPLE_IAP_SECRET_NAMES].sort(),
    );
    assert.deepStrictEqual(
      secretKeysFromFunction(idx.playRealtimeDeveloperNotification).sort(),
      [...PLAY_IAP_SECRET_NAMES].sort(),
    );
  });

  it('does not attach store secrets to unrelated Functions', () => {
    const discoverKeys = secretKeysFromFunction(
      idx.recomputeDiscoverEligibleOnUserWrite,
    );
    const deletionKeys = secretKeysFromFunction(
      idx.closeMatchesOnAccountDeletionRequested,
    );
    const whoLikedKeys = secretKeysFromFunction(idx.listWhoLikedYou);
    const sendSuperKeys = secretKeysFromFunction(idx.sendSuperResonance);
    const availabilitySuperKeys = secretKeysFromFunction(
      idx.getSuperResonanceAvailability,
    );
    const inboxSuperKeys = secretKeysFromFunction(idx.listSuperResonanceInbox);
    assert.deepStrictEqual(discoverKeys, []);
    assert.deepStrictEqual(deletionKeys, []);
    assert.deepStrictEqual(whoLikedKeys, []);
    assert.deepStrictEqual(sendSuperKeys, []);
    assert.deepStrictEqual(availabilitySuperKeys, []);
    assert.deepStrictEqual(inboxSuperKeys, []);
    for (const name of STORE_IAP_SECRET_NAMES) {
      assert.strictEqual(discoverKeys.includes(name), false);
      assert.strictEqual(deletionKeys.includes(name), false);
      assert.strictEqual(whoLikedKeys.includes(name), false);
      assert.strictEqual(sendSuperKeys.includes(name), false);
      assert.strictEqual(availabilitySuperKeys.includes(name), false);
      assert.strictEqual(inboxSuperKeys.includes(name), false);
    }
  });

  it('verifier config reads bound secret env names when present', () => {
    const appleEnv = {
      APPLE_IAP_ISSUER_ID: 'issuer-from-secret',
      APPLE_IAP_KEY_ID: 'KEYID12345',
      APPLE_IAP_PRIVATE_KEY: 'TEST_PRIVATE_KEY_PLACEHOLDER_NOT_A_SECRET',
      APPLE_IAP_BUNDLE_ID: 'com.qmatch.app',
      APPLE_IAP_ENVIRONMENT: 'Sandbox',
      APPLE_IAP_APP_APPLE_ID: '1234567890',
    };
    const apple = loadAppleIapConfig(appleEnv);
    assert.strictEqual(apple.ok, true);
    assert.strictEqual(apple.config.issuerId, 'issuer-from-secret');
    assert.strictEqual(apple.config.bundleId, 'com.qmatch.app');

    const playEnv = {
      PLAY_IAP_PACKAGE_NAME: 'com.qmatch.app',
      PLAY_IAP_CLIENT_EMAIL: 'play-sa@example.iam.gserviceaccount.com',
      PLAY_IAP_PRIVATE_KEY: 'TEST_PLAY_KEY_PLACEHOLDER_NOT_A_SECRET',
    };
    const play = loadPlayIapConfig(playEnv);
    assert.strictEqual(play.ok, true);
    assert.strictEqual(play.config.packageName, 'com.qmatch.app');
    assert.strictEqual(
      play.config.clientEmail,
      'play-sa@example.iam.gserviceaccount.com',
    );
  });

  it('missing secrets still fail closed', () => {
    const apple = loadAppleIapConfig({});
    assert.strictEqual(apple.ok, false);
    assert.strictEqual(apple.code, 'verification_not_configured');
    assert.ok(apple.missing.includes('APPLE_IAP_ISSUER_ID'));
    assert.ok(apple.missing.includes('APPLE_IAP_PRIVATE_KEY'));

    const play = loadPlayIapConfig({});
    assert.strictEqual(play.ok, false);
    assert.strictEqual(play.code, 'verification_not_configured');
    assert.ok(play.missing.includes('PLAY_IAP_PACKAGE_NAME'));
  });

  it('does not hardcode credential values in secret or index modules', () => {
    const fs = require('fs');
    const path = require('path');
    const secretsSrc = fs.readFileSync(
      path.join(__dirname, '../src/store_iap_secrets.js'),
      'utf8',
    );
    const indexSrc = fs.readFileSync(
      path.join(__dirname, '../index.js'),
      'utf8',
    );
    assert.strictEqual(secretsSrc.includes('BEGIN PRIVATE KEY'), false);
    assert.strictEqual(indexSrc.includes('BEGIN PRIVATE KEY'), false);
    assert.strictEqual(secretsSrc.includes('-----BEGIN'), false);
    assert.ok(secretsSrc.includes('defineSecret'));
    assert.ok(indexSrc.includes('STORE_IAP_SECRETS'));
    assert.ok(indexSrc.includes('APPLE_IAP_SECRETS'));
    assert.ok(indexSrc.includes('PLAY_IAP_SECRETS'));
  });
});
