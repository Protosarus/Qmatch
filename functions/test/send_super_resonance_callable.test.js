'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  handleSendSuperResonance,
  CALLABLE_NAME,
  PUBLIC_RESULT_KEYS,
  signalId,
} = require('../src/send_super_resonance_callable');
const {
  SCHEMA_VERSION,
  SPEND_PLATFORM,
} = require('../src/super_resonance_signal');
const { spendLedgerId } = require('../src/entitlement_ledger');
const { handleLikeAndMaybeCreateMatch, OUTCOME } = require('../src/like_and_maybe_create_match_callable');
const {
  EVENT_TYPES,
  EFFECTS,
} = require('../src/entitlement_schema');

function eligibleUser(overrides = {}) {
  return {
    discover_eligible: true,
    active: true,
    profile_completed: true,
    test_completed: true,
    profile_photo_url: 'https://example.com/p.jpg',
    name: 'Ada',
    ...overrides,
  };
}

function entitlement(uid, extras = {}) {
  return {
    uid,
    tier: 'resonance',
    subscription_state: 'active',
    resonance_access: true,
    super_resonance_balance: 2,
    boost_balance: 5,
    schema_version: 'resonance_entitlement_firestore_schema_v1',
    ...extras,
  };
}

function request(uid, targetUid, requestId) {
  return {
    auth: uid ? { uid } : null,
    data: { target_uid: targetUid, request_id: requestId },
  };
}

function deps(db) {
  return {
    db,
    serverTimestamp: () => 'TS',
    now: () => new Date('2026-08-17T00:00:00.000Z'),
  };
}

async function seedReady(db, extras = {}) {
  const from = extras.from || 'userA';
  const to = extras.to || 'userB';
  await db.doc(`users/${from}`).set(eligibleUser({ name: from }));
  await db.doc(`users/${to}`).set(
    eligibleUser({ name: to, ...(extras.targetUser || {}) }),
  );
  await db.doc(`entitlements/${from}`).set(
    entitlement(from, extras.entitlement || {}),
  );
  return { from, to };
}

describe('sendSuperResonance callable', () => {
  it('callable name is sendSuperResonance', () => {
    assert.strictEqual(CALLABLE_NAME, 'sendSuperResonance');
  });

  it('success spends 1 and creates exactly one signal', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db);
    const reqId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const res = await handleSendSuperResonance(
      request(from, to, reqId),
      deps(db),
    );

    assert.strictEqual(res.ok, true);
    assert.strictEqual(res.already_sent, false);
    assert.strictEqual(res.super_resonance_balance, 1);
    assert.strictEqual(res.signal_id, signalId(from, to));
    assert.deepStrictEqual(Object.keys(res).sort(), [...PUBLIC_RESULT_KEYS].sort());

    const signal = await db.doc(`super_resonance_signals/${from}_${to}`).get();
    assert.strictEqual(signal.exists, true);
    const row = signal.data();
    assert.strictEqual(row.from_uid, from);
    assert.strictEqual(row.to_uid, to);
    assert.strictEqual(row.status, 'active');
    assert.strictEqual(row.spend_request_id, reqId);
    assert.strictEqual(
      row.spend_ledger_id,
      spendLedgerId(SPEND_PLATFORM, from, reqId),
    );
    assert.strictEqual(row.schema_version, SCHEMA_VERSION);
    assert.strictEqual(row.created_at, 'TS');

    const ledger = await db
      .doc(
        `entitlements/${from}/purchase_ledger/${spendLedgerId(SPEND_PLATFORM, from, reqId)}`,
      )
      .get();
    assert.strictEqual(ledger.exists, true);
    assert.strictEqual(ledger.data().event_type, EVENT_TYPES.CONSUMABLE_SPEND);
    assert.strictEqual(ledger.data().effect, EFFECTS.DEBIT_SUPER_RESONANCE);
    assert.strictEqual(ledger.data().verification_source, 'spend');
    assert.strictEqual(ledger.data().target_uid, to);

    const ent = await db.doc(`entitlements/${from}`).get();
    assert.strictEqual(ent.data().super_resonance_balance, 1);
    assert.strictEqual(ent.data().boost_balance, 5);
    assert.strictEqual(ent.data().tier, 'resonance');
    assert.strictEqual(ent.data().resonance_access, true);

    const swipe = await db.doc(`users/${from}/swipes/${to}`).get();
    assert.strictEqual(swipe.exists, false);
    const match = await db.doc('matches/userA_userB').get();
    assert.strictEqual(match.exists, false);

    let signalCount = 0;
    for (const p of db._store.keys()) {
      if (p.startsWith('super_resonance_signals/')) signalCount += 1;
    }
    assert.strictEqual(signalCount, 1);
  });

  it('duplicate pair does not debit a second time', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db);
    const first = await handleSendSuperResonance(
      request(from, to, 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
      deps(db),
    );
    const second = await handleSendSuperResonance(
      request(from, to, 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
      deps(db),
    );
    assert.strictEqual(first.already_sent, false);
    assert.strictEqual(first.super_resonance_balance, 1);
    assert.strictEqual(second.ok, true);
    assert.strictEqual(second.already_sent, true);
    assert.strictEqual(second.super_resonance_balance, 1);
    assert.strictEqual(second.signal_id, first.signal_id);

    const ent = await db.doc(`entitlements/${from}`).get();
    assert.strictEqual(ent.data().super_resonance_balance, 1);
  });

  it('duplicate request_id is idempotent', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db);
    const reqId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
    const first = await handleSendSuperResonance(
      request(from, to, reqId),
      deps(db),
    );
    const second = await handleSendSuperResonance(
      request(from, to, reqId),
      deps(db),
    );
    assert.strictEqual(first.ok, true);
    assert.strictEqual(first.already_sent, false);
    assert.strictEqual(second.ok, true);
    assert.strictEqual(second.already_sent, true);
    assert.strictEqual(second.super_resonance_balance, 1);
    assert.strictEqual(second.signal_id, first.signal_id);
  });

  it('either-direction block refuses without debit or signal', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db);
    await db.doc(`users/${from}/blocks/${to}`).set({ blocked: true });
    await assert.rejects(
      () =>
        handleSendSuperResonance(
          request(from, to, 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'failed-precondition' &&
        !String(err.message).toLowerCase().includes('block'),
    );
    assert.strictEqual(
      (await db.doc(`super_resonance_signals/${from}_${to}`).get()).exists,
      false,
    );
    assert.strictEqual(
      (await db.doc(`entitlements/${from}`).get()).data().super_resonance_balance,
      2,
    );

    const db2 = new MemoryFirestore();
    await seedReady(db2);
    await db2.doc('users/userB/blocks/userA').set({ blocked: true });
    await assert.rejects(
      () =>
        handleSendSuperResonance(
          request(
            'userA',
            'userB',
            'ffffffff-ffff-4fff-8fff-ffffffffffff',
          ),
          deps(db2),
        ),
      (err) => err instanceof HttpsError && err.code === 'failed-precondition',
    );
    assert.strictEqual(
      (await db2.doc('super_resonance_signals/userA_userB').get()).exists,
      false,
    );
  });

  it('already-passed refuses', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db);
    await db.doc(`users/${from}/swipes/${to}`).set({
      from_uid: from,
      target_uid: to,
      direction: 'pass',
    });
    await assert.rejects(
      () =>
        handleSendSuperResonance(
          request(from, to, '12121212-1212-4121-8121-121212121212'),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'failed-precondition',
    );
    assert.strictEqual(
      (await db.doc(`entitlements/${from}`).get()).data().super_resonance_balance,
      2,
    );
    assert.strictEqual(
      (await db.doc(`super_resonance_signals/${from}_${to}`).get()).exists,
      false,
    );
  });

  it('existing match in any state refuses', async () => {
    for (const state of ['active', 'unmatched', 'blocked']) {
      const db = new MemoryFirestore();
      const { from, to } = await seedReady(db);
      await db.doc('matches/userA_userB').set({ state, match_id: 'userA_userB' });
      await assert.rejects(
        () =>
          handleSendSuperResonance(
            request(from, to, `match-${state}-aaaa-4aaa-8aaa-aaaaaaaaaaaa`),
            deps(db),
          ),
        (err) => err instanceof HttpsError && err.code === 'failed-precondition',
      );
      assert.strictEqual(
        (await db.doc(`entitlements/${from}`).get()).data()
          .super_resonance_balance,
        2,
      );
    }
  });

  it('inactive / deleted / ineligible target refuses', async () => {
    const cases = [
      { active: false, discover_eligible: false },
      { account_deletion_requested: true },
      { discover_eligible: false },
      { profile_completed: false, discover_eligible: true },
    ];
    for (const targetUser of cases) {
      const db = new MemoryFirestore();
      const { from, to } = await seedReady(db, { targetUser });
      await assert.rejects(
        () =>
          handleSendSuperResonance(
            request(from, to, `inelig-${Object.keys(targetUser)[0]}-aaaa-8aaa-aaaaaaaaaaaa`),
            deps(db),
          ),
        (err) => err instanceof HttpsError && err.code === 'failed-precondition',
      );
      assert.strictEqual(
        (await db.doc(`super_resonance_signals/${from}_${to}`).get()).exists,
        false,
      );
      assert.strictEqual(
        (await db.doc(`entitlements/${from}`).get()).data()
          .super_resonance_balance,
        2,
      );
    }

    const missing = new MemoryFirestore();
    await missing.doc('users/userA').set(eligibleUser());
    await missing.doc('entitlements/userA').set(entitlement('userA'));
    await assert.rejects(
      () =>
        handleSendSuperResonance(
          request('userA', 'missing', 'missing1-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
          deps(missing),
        ),
      (err) => err instanceof HttpsError && err.code === 'failed-precondition',
    );
  });

  it('already-liked target is allowed', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db);
    await db.doc(`users/${from}/swipes/${to}`).set({
      from_uid: from,
      target_uid: to,
      direction: 'like',
      source: 'discover',
    });
    const res = await handleSendSuperResonance(
      request(from, to, 'liked000-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
      deps(db),
    );
    assert.strictEqual(res.ok, true);
    assert.strictEqual(res.already_sent, false);
    assert.strictEqual(res.super_resonance_balance, 1);
    const swipe = await db.doc(`users/${from}/swipes/${to}`).get();
    assert.strictEqual(swipe.data().direction, 'like');
    const match = await db.doc('matches/userA_userB').get();
    assert.strictEqual(match.exists, false);
  });

  it('insufficient balance refuses', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db, {
      entitlement: { super_resonance_balance: 0 },
    });
    await assert.rejects(
      () =>
        handleSendSuperResonance(
          request(from, to, 'zero0000-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'failed-precondition' &&
        err.details &&
        err.details.code === 'insufficient_balance',
    );
    assert.strictEqual(
      (await db.doc(`super_resonance_signals/${from}_${to}`).get()).exists,
      false,
    );
    assert.strictEqual(
      (await db.doc(`entitlements/${from}`).get()).data().super_resonance_balance,
      0,
    );
  });

  it('Like/Pass/matching semantics stay unchanged after send', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db);
    await handleSendSuperResonance(
      request(from, to, 'likekeep-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
      deps(db),
    );

    const likeRes = await handleLikeAndMaybeCreateMatch(
      {
        auth: { uid: from },
        data: { target_uid: to },
      },
      {
        db,
        serverTimestamp: () => 'TS',
        nowMs: () => 1,
      },
    );
    assert.strictEqual(likeRes.outcome, OUTCOME.noMatch);
    const swipe = await db.doc(`users/${from}/swipes/${to}`).get();
    assert.strictEqual(swipe.exists, true);
    assert.strictEqual(swipe.data().direction, 'like');
    const match = await db.doc('matches/userA_userB').get();
    assert.strictEqual(match.exists, false);

    const sendSrc = fs.readFileSync(
      path.join(__dirname, '../src/send_super_resonance_callable.js'),
      'utf8',
    );
    assert.strictEqual(sendSrc.includes('likeAndMaybeCreateMatch'), false);
    assert.strictEqual(sendSrc.includes('writeMatchArtifacts'), false);
    assert.strictEqual(sendSrc.includes('tx.set(ownSwipeRef'), false);
    assert.strictEqual(sendSrc.includes('tx.set(matchRef'), false);
    assert.strictEqual(sendSrc.includes('compareStageB2Structural'), false);

    const likeSrc = fs.readFileSync(
      path.join(__dirname, '../src/like_and_maybe_create_match_callable.js'),
      'utf8',
    );
    assert.strictEqual(likeSrc.includes('super_resonance'), false);
  });

  it('unauthenticated and self are rejected', async () => {
    await assert.rejects(
      () =>
        handleSendSuperResonance(
          request(null, 'userB', 'auth0000-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
          deps(new MemoryFirestore()),
        ),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
    await assert.rejects(
      () =>
        handleSendSuperResonance(
          request('userA', 'userA', 'self0000-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
          deps(new MemoryFirestore()),
        ),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
  });
});
