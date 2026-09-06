'use strict';

const assert = require('assert');
const {
  POLICY,
  CALLABLE_NAME,
  STEPS,
  DELETION_MATRIX,
  resolveDeletionUid,
  requiresAppleRevocationSignal,
  appleRevocationAccepted,
  isUidOwnedStoragePath,
  ownedStoragePrefixes,
  visibilityRevokeFields,
  authDeleteIsLast,
} = require('../src/delete_qmatch_account');
const { handleDeleteQMatchAccount } = require('../src/delete_qmatch_account_callable');
const { runDeleteQMatchAccount } = require('../src/delete_qmatch_account_runner');
const { MemoryFirestore } = require('./memory_firestore');

function request({
  uid = 'self',
  emailVerified = false,
  signInProvider = 'password',
  data = {},
} = {}) {
  if (!uid) {
    return { auth: null, data };
  }
  return {
    auth: {
      uid,
      token: {
        email_verified: emailVerified,
        firebase: { sign_in_provider: signInProvider },
      },
    },
    data,
  };
}

function seedUser(db, uid, extra = {}) {
  db._store.set(`users/${uid}`, {
    uid,
    name: 'Ada',
    discover_eligible: true,
    active: true,
    account_deletion_requested: false,
    ...extra,
  });
  db._store.set(`users/${uid}/assessments/iq`, { status: 'completed' });
  db._store.set(`users/${uid}/swipes/other`, { direction: 'like' });
  db._store.set(`users/${uid}/blocks/blocked`, { blocked_uid: 'blocked' });
  db._store.set(`users/${uid}/fcm_tokens/tok`, { token_hash: 'tok' });
  db._store.set(`users/${uid}/preferences/notification_prefs_v1`, { likes: true });
  db._store.set(`users/${uid}/profiles/canonical_v1`, { ready: true });
  db._store.set(`public_profiles/${uid}`, {
    name: 'Ada',
    discover_eligible: true,
  });
  db._store.set(`entitlements/${uid}`, { uid, tier: 'free' });
  db._store.set(`entitlements/${uid}/purchase_ledger/p1`, { product_id: 'sku' });
  db._store.set('reports/r1', { reporter_uid: uid, reported_uid: 'other' });
  db._store.set('users/other/swipes/self', { direction: 'like' });
  db._store.set('users/other', { uid: 'other', name: 'Other', discover_eligible: true });
}

describe('delete_qmatch_account_v1 policy', () => {
  it('A unauthenticated deletion is rejected', async () => {
    assert.throws(
      () => resolveDeletionUid(request({ uid: null })),
      (err) => err.code === 'unauthenticated',
    );
    const handler = handleDeleteQMatchAccount({
      db: new MemoryFirestore(),
    });
    await assert.rejects(
      () => handler(request({ uid: null })),
      (err) => err.code === 'unauthenticated',
    );
  });

  it('B/C/Q only auth.uid is deleted; targetUid is ignored', async () => {
    assert.strictEqual(
      resolveDeletionUid(request({
        uid: 'self',
        data: { targetUid: 'victim', target_uid: 'victim' },
      })),
      'self',
    );
    const db = new MemoryFirestore();
    seedUser(db, 'self');
    seedUser(db, 'victim', { name: 'Victim' });
    const deletedUsers = [];
    await runDeleteQMatchAccount('self', {
      db,
      getUser: async () => ({ uid: 'self', providerData: [] }),
      deleteUser: async (uid) => {
        deletedUsers.push(uid);
        return true;
      },
      listOwnedStorage: async () => [],
      closeMatches: async () => ({ closed: 0 }),
      serverTimestamp: () => ({ seconds: 1 }),
    });
    assert.deepStrictEqual(deletedUsers, ['self']);
    assert.strictEqual(db._store.has('users/victim'), true);
    assert.strictEqual(db._store.has('public_profiles/victim'), true);
  });

  it('D/E/F unverified password, phone, and Google may delete themselves', async () => {
    for (const provider of ['password', 'phone', 'google.com']) {
      const uid = resolveDeletionUid(request({
        uid: 'self',
        emailVerified: false,
        signInProvider: provider,
      }));
      assert.strictEqual(uid, 'self');
    }
  });

  it('G Apple-linked account requires revocation completion signal', async () => {
    assert.strictEqual(
      requiresAppleRevocationSignal({
        providerData: [{ providerId: 'apple.com' }, { providerId: 'google.com' }],
      }),
      true,
    );
    assert.strictEqual(appleRevocationAccepted({}), false);
    assert.strictEqual(appleRevocationAccepted({ apple_revocation_completed: true }), true);

    const db = new MemoryFirestore();
    seedUser(db, 'self');
    await assert.rejects(
      () => runDeleteQMatchAccount('self', {
        db,
        getUser: async () => ({
          uid: 'self',
          providerData: [{ providerId: 'apple.com' }],
        }),
        requestData: {},
        listOwnedStorage: async () => [],
        closeMatches: async () => ({ closed: 0 }),
      }),
      (err) => err.code === 'failed-precondition',
    );
    assert.strictEqual(db._store.has('users/self'), true);
  });

  it('H/I/J public profile gone, matches close, unrelated docs stay', async () => {
    const db = new MemoryFirestore();
    seedUser(db, 'self');
    db._store.set('matches/self_other', {
      users: ['self', 'other'],
      state: 'active',
      thread_id: 'self_other',
    });
    db._store.set('threads/self_other', {
      participants: ['self', 'other'],
      status: 'active',
      last_message_sender: 'self',
      last_message_preview: 'Hi from Ada',
      unread_counts: { self: 0, other: 2 },
    });
    db._store.set('threads/self_other/messages/m1', {
      sender_id: 'self',
      text: 'Hi from Ada',
    });

    let closedUid = null;
    await runDeleteQMatchAccount('self', {
      db,
      getUser: async () => ({ uid: 'self', providerData: [] }),
      deleteUser: async () => true,
      listOwnedStorage: async () => ['profile_photos/self/a.jpg'],
      deleteStoragePath: async () => {},
      closeMatches: async (uid) => {
        closedUid = uid;
        db._store.set('matches/self_other', {
          users: ['self', 'other'],
          state: 'unmatched',
          thread_id: 'self_other',
          close_reason: 'account_deletion_requested',
        });
        return { closed: 1 };
      },
      serverTimestamp: () => ({ seconds: 1 }),
    });

    assert.strictEqual(closedUid, 'self');
    assert.strictEqual(db._store.has('public_profiles/self'), false);
    assert.strictEqual(db._store.has('users/other'), true);
    assert.strictEqual(db._store.has('users/other/swipes/self'), true);
    assert.strictEqual(db._store.has('threads/self_other/messages/m1'), true);
    assert.strictEqual(db._store.has('reports/r1'), true);
    const thread = db._store.get('threads/self_other');
    assert.strictEqual(thread.status, 'closed');
    assert.strictEqual(thread.last_message_preview, '');
    assert.strictEqual(thread.unread_counts.self, 0);
  });

  it('L user private subcollections are deleted', async () => {
    const db = new MemoryFirestore();
    seedUser(db, 'self');
    await runDeleteQMatchAccount('self', {
      db,
      getUser: async () => ({ uid: 'self', providerData: [] }),
      deleteUser: async () => true,
      listOwnedStorage: async () => [],
      closeMatches: async () => ({ closed: 0 }),
      serverTimestamp: () => ({ seconds: 1 }),
    });
    assert.strictEqual(db._store.has('users/self'), false);
    assert.strictEqual(db._store.has('users/self/assessments/iq'), false);
    assert.strictEqual(db._store.has('users/self/swipes/other'), false);
    assert.strictEqual(db._store.has('users/self/blocks/blocked'), false);
    assert.strictEqual(db._store.has('users/self/fcm_tokens/tok'), false);
    assert.strictEqual(db._store.has('users/self/preferences/notification_prefs_v1'), false);
    assert.strictEqual(db._store.has('users/self/profiles/canonical_v1'), false);
  });

  it('M storage delete plan is uid-scoped', () => {
    assert.deepStrictEqual(ownedStoragePrefixes('self'), ['profile_photos/self/']);
    assert.strictEqual(isUidOwnedStoragePath('self', 'profile_photos/self/a.jpg'), true);
    assert.strictEqual(isUidOwnedStoragePath('self', 'profile_photos/other/a.jpg'), false);
    assert.strictEqual(isUidOwnedStoragePath('self', 'chat_media/self_other/self/a.jpg'), false);
  });

  it('N/O retry is idempotent and missing docs are harmless', async () => {
    const db = new MemoryFirestore();
    seedUser(db, 'self');
    const deps = {
      db,
      getUser: async () => ({ uid: 'self', providerData: [] }),
      deleteUser: async () => true,
      listOwnedStorage: async () => [],
      closeMatches: async () => ({ closed: 0 }),
      serverTimestamp: () => ({ seconds: 1 }),
    };
    const first = await runDeleteQMatchAccount('self', deps);
    const second = await runDeleteQMatchAccount('self', deps);
    assert.strictEqual(first.ok, true);
    assert.strictEqual(second.ok, true);
    assert.strictEqual(db._store.get('account_deletion_requests/self').status, 'completed');
    assert.strictEqual(db._store.has('users/self'), false);
  });

  it('P Firebase Auth delete is last', () => {
    assert.strictEqual(authDeleteIsLast(STEPS), true);
  });

  it('callable does not use verified_product_auth', () => {
    const src = require('fs').readFileSync(
      require('path').join(__dirname, '../src/delete_qmatch_account_callable.js'),
      'utf8',
    );
    assert.ok(!src.includes('verified_product_auth'));
    assert.ok(!src.includes('requireVerifiedProductUid'));
    assert.strictEqual(CALLABLE_NAME, 'deleteQMatchAccount');
    assert.strictEqual(POLICY, 'delete_qmatch_account_v1');
    assert.ok(DELETION_MATRIX.some((row) => row.path.includes('messages')));
    assert.ok(visibilityRevokeFields().discover_eligible === false);
  });

  it('Apple-linked succeeds only after client revocation signal', async () => {
    const db = new MemoryFirestore();
    seedUser(db, 'self');
    const result = await runDeleteQMatchAccount('self', {
      db,
      getUser: async () => ({
        uid: 'self',
        providerData: [{ providerId: 'apple.com' }, { providerId: 'google.com' }],
      }),
      deleteUser: async () => true,
      listOwnedStorage: async () => [],
      closeMatches: async () => ({ closed: 0 }),
      requestData: { apple_revocation_completed: true, targetUid: 'victim' },
      serverTimestamp: () => ({ seconds: 1 }),
    });
    assert.strictEqual(result.ok, true);
    assert.strictEqual(result.uid, 'self');
    assert.strictEqual(result.messages_deleted, false);
    assert.strictEqual(result.entitlements_deleted, false);
    assert.strictEqual(db._store.get('entitlements/self').account_deleted, true);
    assert.strictEqual(db._store.has('entitlements/self/purchase_ledger/p1'), true);
  });

  it('emits structured per-step timings without PII', async () => {
    const db = new MemoryFirestore();
    seedUser(db, 'self');
    const lines = [];
    const result = await runDeleteQMatchAccount('self', {
      db,
      getUser: async () => ({ uid: 'self', providerData: [] }),
      deleteUser: async () => true,
      listOwnedStorage: async () => [],
      closeMatches: async () => ({ closed: 0 }),
      serverTimestamp: () => ({ seconds: 1 }),
      log: (line) => lines.push(line),
    });
    assert.strictEqual(result.ok, true);
    assert.deepStrictEqual(result.completed_steps, STEPS);

    const records = lines.map((line) => JSON.parse(line));
    const steps = records.map((row) => row.step);
    assert.deepStrictEqual(steps, [
      'load_auth_user',
      'claim_request',
      'revoke_visibility',
      'delete_public_profile',
      'close_matches_threads',
      'deidentify_shared_threads',
      'delete_user_owned_data',
      'delete_owned_storage',
      'retain_entitlements',
      'delete_user_doc',
      'delete_auth_user',
      'finalize_request',
      'total',
    ]);

    const forbidden = [
      'email',
      'phone',
      'name',
      'token',
      'authorization',
      'identityToken',
      'authorizationCode',
      'message',
      'preview',
    ];
    for (const row of records) {
      assert.strictEqual(row.event, 'delete_qmatch_account_timing');
      assert.strictEqual(typeof row.step, 'string');
      assert.strictEqual(typeof row.duration_ms, 'number');
      assert.strictEqual(typeof row.total_duration_ms, 'number');
      assert.ok(row.duration_ms >= 0);
      assert.ok(row.total_duration_ms >= row.duration_ms);
      assert.deepStrictEqual(
        Object.keys(row).sort(),
        ['duration_ms', 'event', 'step', 'total_duration_ms'],
      );
      const raw = JSON.stringify(row);
      for (const key of forbidden) {
        assert.ok(!raw.toLowerCase().includes(key.toLowerCase()), key);
      }
      assert.ok(!raw.includes('self@'));
      assert.ok(!raw.includes('+90'));
    }
    assert.ok(authDeleteIsLast(result.completed_steps));
  });

  it('still times load_auth_user when Apple revoke precondition fails', async () => {
    const db = new MemoryFirestore();
    seedUser(db, 'self');
    const lines = [];
    await assert.rejects(
      () => runDeleteQMatchAccount('self', {
        db,
        getUser: async () => ({
          uid: 'self',
          providerData: [{ providerId: 'apple.com' }],
        }),
        requestData: {},
        listOwnedStorage: async () => [],
        closeMatches: async () => ({ closed: 0 }),
        log: (line) => lines.push(line),
      }),
      (err) => err.code === 'failed-precondition',
    );
    const records = lines.map((line) => JSON.parse(line));
    assert.deepStrictEqual(records.map((row) => row.step), [
      'load_auth_user',
      'total',
    ]);
    assert.strictEqual(db._store.has('users/self'), true);
  });
});
