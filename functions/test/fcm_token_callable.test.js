'use strict';

const assert = require('assert');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  tokenHash,
  tokenPath,
  handleRegisterFcmToken,
  handleUnregisterFcmToken,
} = require('../src/fcm_token_callable');

function request(uid, data = {}) {
  return {
    auth: uid ? { uid } : null,
    data,
  };
}

function deps(db) {
  return { db, serverTimestamp: () => 'TS' };
}

const TOKEN = 'tok-1';
const TOKEN_HASH =
  '65dcf16ea3dfa49069628089eb4a75483070f5584b2a21ee64912b5f621f12da';

describe('fcm token callables', () => {
  it('hashes the raw token with stable SHA-256', () => {
    assert.strictEqual(tokenHash(TOKEN), TOKEN_HASH);
  });

  it('unauthenticated register and unregister throw', async () => {
    const db = new MemoryFirestore();
    await assert.rejects(
      () =>
        handleRegisterFcmToken(
          request(null, {
            token: TOKEN,
            platform: 'ios',
            app_id: 'app',
            apns_env: 'sandbox',
          }),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
    await assert.rejects(
      () => handleUnregisterFcmToken(request(null, { token: TOKEN }), deps(db)),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
  });

  it('rejects empty token and unknown platform', async () => {
    const db = new MemoryFirestore();
    await assert.rejects(
      () =>
        handleRegisterFcmToken(
          request('userA', {
            token: '   ',
            platform: 'ios',
            app_id: 'app',
            apns_env: 'sandbox',
          }),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
    await assert.rejects(
      () =>
        handleRegisterFcmToken(
          request('userA', {
            token: TOKEN,
            platform: 'web',
            app_id: 'app',
          }),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
  });

  it('iOS requires apns_env; android ignores it', async () => {
    const db = new MemoryFirestore();
    await assert.rejects(
      () =>
        handleRegisterFcmToken(
          request('userA', {
            token: TOKEN,
            platform: 'ios',
            app_id: 'app',
          }),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
    const android = await handleRegisterFcmToken(
      request('userA', {
        token: TOKEN,
        platform: 'android',
        app_id: 'app',
        apns_env: 'sandbox',
      }),
      deps(db),
    );
    assert.deepStrictEqual(android, { ok: true });
    const snap = await db.doc(tokenPath('userA', TOKEN_HASH)).get();
    assert.strictEqual(snap.data().apns_env, undefined);
    assert.strictEqual(snap.data().platform, 'android');
  });

  it('writes token under the authenticated uid hash path', async () => {
    const db = new MemoryFirestore();
    const result = await handleRegisterFcmToken(
      request('userA', {
        token: TOKEN,
        platform: 'ios',
        app_id: '1:55490039374:ios:523d1a173f0ba32ac7fd1f',
        apns_env: 'sandbox',
        uid: 'userB',
      }),
      deps(db),
    );
    assert.deepStrictEqual(result, { ok: true });
    assert.strictEqual(result.token, undefined);
    const snap = await db.doc(tokenPath('userA', TOKEN_HASH)).get();
    assert.strictEqual(snap.exists, true);
    assert.deepStrictEqual(snap.data(), {
      token: TOKEN,
      platform: 'ios',
      app_id: '1:55490039374:ios:523d1a173f0ba32ac7fd1f',
      notification_locale: 'en',
      apns_env: 'sandbox',
      created_at: 'TS',
      updated_at: 'TS',
      last_seen_at: 'TS',
    });
    const other = await db.doc(tokenPath('userB', TOKEN_HASH)).get();
    assert.strictEqual(other.exists, false);
  });

  it('re-register keeps created_at and refreshes last_seen_at', async () => {
    const db = new MemoryFirestore();
    let tick = 1;
    const timed = {
      db,
      serverTimestamp: () => `TS${tick}`,
    };
    await handleRegisterFcmToken(
      request('userA', {
        token: TOKEN,
        platform: 'ios',
        app_id: 'app',
        apns_env: 'sandbox',
      }),
      timed,
    );
    tick = 2;
    await handleRegisterFcmToken(
      request('userA', {
        token: TOKEN,
        platform: 'ios',
        app_id: 'app',
        apns_env: 'production',
      }),
      timed,
    );
    const snap = await db.doc(tokenPath('userA', TOKEN_HASH)).get();
    assert.strictEqual(snap.data().created_at, 'TS1');
    assert.strictEqual(snap.data().updated_at, 'TS2');
    assert.strictEqual(snap.data().last_seen_at, 'TS2');
    assert.strictEqual(snap.data().apns_env, 'production');
  });

  it('one user cannot unregister another user token', async () => {
    const db = new MemoryFirestore();
    await handleRegisterFcmToken(
      request('userA', {
        token: TOKEN,
        platform: 'ios',
        app_id: 'app',
        apns_env: 'sandbox',
      }),
      deps(db),
    );
    await handleUnregisterFcmToken(
      request('userB', { token: TOKEN }),
      deps(db),
    );
    const a = await db.doc(tokenPath('userA', TOKEN_HASH)).get();
    assert.strictEqual(a.exists, true);
    const b = await db.doc(tokenPath('userB', TOKEN_HASH)).get();
    assert.strictEqual(b.exists, false);
  });

  it('unregister deletes only the current user token doc', async () => {
    const db = new MemoryFirestore();
    await handleRegisterFcmToken(
      request('userA', {
        token: TOKEN,
        platform: 'ios',
        app_id: 'app',
        apns_env: 'sandbox',
      }),
      deps(db),
    );
    await handleRegisterFcmToken(
      request('userA', {
        token: 'other-device',
        platform: 'ios',
        app_id: 'app',
        apns_env: 'sandbox',
      }),
      deps(db),
    );
    const result = await handleUnregisterFcmToken(
      request('userA', { token: TOKEN }),
      deps(db),
    );
    assert.deepStrictEqual(result, { ok: true });
    const gone = await db.doc(tokenPath('userA', TOKEN_HASH)).get();
    assert.strictEqual(gone.exists, false);
    const other = await db
      .doc(tokenPath('userA', tokenHash('other-device')))
      .get();
    assert.strictEqual(other.exists, true);
  });

  it('unregister of a missing token is idempotent', async () => {
    const db = new MemoryFirestore();
    const result = await handleUnregisterFcmToken(
      request('userA', { token: TOKEN }),
      deps(db),
    );
    assert.deepStrictEqual(result, { ok: true });
  });
});
