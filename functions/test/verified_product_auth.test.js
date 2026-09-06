'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { HttpsError } = require('firebase-functions/v2/https');
const {
  PASSWORD_PROVIDER,
  PHONE_PROVIDER,
  GOOGLE_PROVIDER,
  APPLE_PROVIDER,
  EMAIL_VERIFICATION_REQUIRED,
  requiresEmailVerification,
  requireVerifiedProductUid,
} = require('../src/verified_product_auth');
const { handleFinalizeIq } = require('../src/finalize_iq_v1');
const { handleFinalizeEq } = require('../src/finalize_eq_v1');
const { handleFinalizeFrequencyV2 } = require('../src/finalize_frequency_v2_v1');
const {
  handleCompareStageB2Structural,
} = require('../src/stage_b2_l2_callable');
const {
  handleLikeAndMaybeCreateMatch,
} = require('../src/like_and_maybe_create_match_callable');
const { handleUnregisterFcmToken } = require('../src/fcm_token_callable');
const { MemoryFirestore } = require('./memory_firestore');

function passwordAuth(uid, emailVerified) {
  return {
    uid,
    token: {
      email_verified: emailVerified,
      firebase: { sign_in_provider: PASSWORD_PROVIDER },
    },
  };
}

function phoneAuth(uid) {
  return {
    uid,
    token: {
      firebase: { sign_in_provider: PHONE_PROVIDER },
    },
  };
}

function providerAuth(uid, provider, extras = {}) {
  return {
    uid,
    token: {
      email_verified: extras.emailVerified,
      email: extras.email,
      firebase: { sign_in_provider: provider },
    },
  };
}

function denied(fn) {
  return assert.rejects(
    fn,
    (err) =>
      err instanceof HttpsError &&
      err.code === 'permission-denied' &&
      err.details &&
      err.details.code === EMAIL_VERIFICATION_REQUIRED,
  );
}

describe('verified product auth guard', () => {
  it('A password + unverified is rejected', () => {
    assert.strictEqual(
      requiresEmailVerification(passwordAuth('u1', false)),
      true,
    );
    assert.throws(
      () =>
        requireVerifiedProductUid({
          auth: passwordAuth('u1', false),
        }),
      (err) => err instanceof HttpsError && err.code === 'permission-denied',
    );
  });

  it('B password + verified succeeds through the auth guard', () => {
    assert.strictEqual(
      requireVerifiedProductUid({ auth: passwordAuth('u1', true) }),
      'u1',
    );
  });

  it('C phone auth succeeds without email verification', () => {
    assert.strictEqual(
      requiresEmailVerification(phoneAuth('phone1')),
      false,
    );
    assert.strictEqual(
      requireVerifiedProductUid({ auth: phoneAuth('phone1') }),
      'phone1',
    );
  });

  it('D email-bearing Google/Apple accounts are not treated as password', () => {
    assert.strictEqual(
      requiresEmailVerification(
        providerAuth('g1', GOOGLE_PROVIDER, {
          emailVerified: false,
          email: 'ada@gmail.com',
        }),
      ),
      false,
    );
    assert.strictEqual(
      requireVerifiedProductUid({
        auth: providerAuth('g1', GOOGLE_PROVIDER, {
          emailVerified: false,
          email: 'ada@gmail.com',
        }),
      }),
      'g1',
    );
    assert.strictEqual(
      requireVerifiedProductUid({
        auth: providerAuth('a1', APPLE_PROVIDER, {
          emailVerified: false,
          email: 'ada@privaterelay.appleid.com',
        }),
      }),
      'a1',
    );
    assert.strictEqual(
      requireVerifiedProductUid({ auth: { uid: 'legacy' } }),
      'legacy',
    );
  });

  it('unauthenticated keeps the existing error code', () => {
    assert.throws(
      () =>
        requireVerifiedProductUid(
          { auth: null },
          'Authentication required to finalize IQ.',
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'unauthenticated' &&
        err.message === 'Authentication required to finalize IQ.',
    );
  });

  it('E finalize IQ rejects unverified password', async () => {
    await denied(() =>
      handleFinalizeIq({
        auth: passwordAuth('userA', false),
        data: {},
      }),
    );
  });

  it('F finalize EQ rejects unverified password', async () => {
    await denied(() =>
      handleFinalizeEq({
        auth: passwordAuth('userA', false),
        data: {},
      }),
    );
  });

  it('G finalize Frequency V2 rejects unverified password', async () => {
    await denied(() =>
      handleFinalizeFrequencyV2({
        auth: passwordAuth('userA', false),
        data: {},
      }),
    );
  });

  it('H live Discover callable rejects unverified password', async () => {
    await denied(() =>
      handleCompareStageB2Structural({
        auth: passwordAuth('viewer', false),
        data: { candidate_uids: ['c1'] },
      }),
    );
  });

  it('I protected like/match endpoint rejects unverified password', async () => {
    await denied(() =>
      handleLikeAndMaybeCreateMatch({
        auth: passwordAuth('viewer', false),
        data: { target_uid: 'other' },
      }),
    );
  });

  it('J FCM unregister used at sign-out is not gated', async () => {
    const db = new MemoryFirestore();
    const tokenId = 'a'.repeat(64);
    await handleUnregisterFcmToken(
      {
        auth: passwordAuth('viewer', false),
        data: { token_id: tokenId },
      },
      { db },
    );
  });

  it('J Admin/background triggers do not import the product guard', () => {
    const trigger = fs.readFileSync(
      path.join(__dirname, '../src/recompute_discover_eligible_authority.js'),
      'utf8',
    );
    const deletion = fs.readFileSync(
      path.join(__dirname, '../src/deletion_close_all_runner.js'),
      'utf8',
    );
    const fcm = fs.readFileSync(
      path.join(__dirname, '../src/fcm_token_callable.js'),
      'utf8',
    );
    assert.ok(!trigger.includes('verified_product_auth'));
    assert.ok(!deletion.includes('verified_product_auth'));
    assert.ok(!fcm.includes('verified_product_auth'));
  });

  it('does not consult a client email_verified Firestore field', () => {
    const src = fs.readFileSync(
      path.join(__dirname, '../src/verified_product_auth.js'),
      'utf8',
    );
    assert.ok(!src.includes("['email_verified']"));
    assert.ok(!src.includes('data.email_verified'));
    assert.ok(src.includes('token.email_verified') || src.includes('email_verified === true'));
  });
});
