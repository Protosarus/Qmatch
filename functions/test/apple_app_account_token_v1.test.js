'use strict';

const assert = require('assert');
const {
  APPLE_APP_ACCOUNT_TOKEN_NAMESPACE_V1,
  appleAppAccountTokenFromUid,
} = require('../src/apple_app_account_token');

describe('apple_app_account_token_v1', () => {
  it('namespace is frozen', () => {
    assert.strictEqual(
      APPLE_APP_ACCOUNT_TOKEN_NAMESPACE_V1,
      'b3e1f9a0-7c4d-4e2b-9f1a-8d6c5b4a3e2f',
    );
  });

  it('is deterministic and UUID-shaped', () => {
    const a = appleAppAccountTokenFromUid('uid-parity-1');
    const b = appleAppAccountTokenFromUid('uid-parity-1');
    assert.strictEqual(a, b);
    assert.match(
      a,
      /^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );
  });

  it('golden vectors match Flutter AppleAppAccountToken.fromUid', () => {
    // Keep in sync with test/ios_iap_client_v1_test.dart / apple_app_account_token tests.
    assert.strictEqual(
      appleAppAccountTokenFromUid('uid-1'),
      'c2089afd-fde1-5d45-b054-7d3f81339887',
    );
    assert.strictEqual(
      appleAppAccountTokenFromUid('firebaseUidExample01'),
      appleAppAccountTokenFromUid('firebaseUidExample01'),
    );
  });

  it('different uids produce different tokens', () => {
    assert.notStrictEqual(
      appleAppAccountTokenFromUid('uid-a'),
      appleAppAccountTokenFromUid('uid-b'),
    );
  });
});
