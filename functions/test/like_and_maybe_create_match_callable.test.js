'use strict';

const assert = require('assert');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  handleLikeAndMaybeCreateMatch,
  CALLABLE_NAME,
  OUTCOME,
} = require('../src/like_and_maybe_create_match_callable');

function eligibleUser(overrides = {}) {
  return {
    discover_eligible: true,
    active: true,
    profile_completed: true,
    test_completed: true,
    profile_photo_url: 'https://example.com/p.jpg',
    ...overrides,
  };
}

function request(uid, targetUid) {
  return {
    auth: uid ? { uid } : null,
    data: { target_uid: targetUid },
  };
}

function deps(db) {
  return {
    db,
    serverTimestamp: () => 'TS',
    nowMs: () => 1_700_000_000_000,
  };
}

async function seedEligiblePair(db, a = 'userA', b = 'userB') {
  await db.doc(`users/${a}`).set(eligibleUser({ name: a }));
  await db.doc(`users/${b}`).set(eligibleUser({ name: b }));
}

describe('likeAndMaybeCreateMatch callable', () => {
  it('unauthenticated throws', async () => {
    await assert.rejects(
      () =>
        handleLikeAndMaybeCreateMatch(request(null, 'userB'), {
          db: new MemoryFirestore(),
        }),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
  });

  it('rejects self Like', async () => {
    await assert.rejects(
      () =>
        handleLikeAndMaybeCreateMatch(request('userA', 'userA'), {
          db: new MemoryFirestore(),
        }),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
  });

  it('first Like succeeds — swipe written, no match', async () => {
    const db = new MemoryFirestore();
    await seedEligiblePair(db);
    const res = await handleLikeAndMaybeCreateMatch(
      request('userA', 'userB'),
      deps(db),
    );
    assert.strictEqual(res.outcome, OUTCOME.noMatch);
    const swipe = await db.doc('users/userA/swipes/userB').get();
    assert.strictEqual(swipe.exists, true);
    assert.strictEqual(swipe.data().direction, 'like');
    assert.strictEqual(swipe.data().from_uid, 'userA');
    assert.strictEqual(swipe.data().target_uid, 'userB');
    const match = await db.doc('matches/userA_userB').get();
    assert.strictEqual(match.exists, false);
    assert.deepStrictEqual(Object.keys(res).sort(), ['outcome']);
  });

  it('reciprocal Like creates exactly one match + thread + system message', async () => {
    const db = new MemoryFirestore();
    await seedEligiblePair(db);
    await handleLikeAndMaybeCreateMatch(request('userA', 'userB'), deps(db));
    const res = await handleLikeAndMaybeCreateMatch(
      request('userB', 'userA'),
      deps(db),
    );
    assert.strictEqual(res.outcome, OUTCOME.createdNewMatch);

    const match = await db.doc('matches/userA_userB').get();
    assert.strictEqual(match.exists, true);
    assert.strictEqual(match.data().state, 'active');
    assert.strictEqual(match.data().match_id, 'userA_userB');
    assert.strictEqual(match.data().thread_id, 'userA_userB');
    assert.strictEqual(match.data().created_by, 'system');
    assert.strictEqual(match.data().match_created_by_uid, 'userB');
    assert.deepStrictEqual(match.data().users, ['userA', 'userB']);
    assert.strictEqual(match.data().user_a, 'userA');
    assert.strictEqual(match.data().user_b, 'userB');
    assert.strictEqual(match.data().reveal.blur_level, 3);

    const thread = await db.doc('threads/userA_userB').get();
    assert.strictEqual(thread.exists, true);
    assert.strictEqual(thread.data().status, 'active');
    assert.deepStrictEqual(thread.data().participants, ['userA', 'userB']);
    assert.strictEqual(thread.data().last_message_preview, 'You matched!');

    const msg = await db.doc('threads/userA_userB/messages/system_match_v1').get();
    assert.strictEqual(msg.exists, true);
    assert.strictEqual(msg.data().sender_id, 'system');
    assert.strictEqual(msg.data().type, 'system');
    assert.strictEqual(msg.data().text, 'You matched!');

    let matchCount = 0;
    let threadCount = 0;
    for (const path of db._store.keys()) {
      if (path.startsWith('matches/')) matchCount += 1;
      if (path === 'threads/userA_userB') threadCount += 1;
    }
    assert.strictEqual(matchCount, 1);
    assert.strictEqual(threadCount, 1);
  });

  it('repeated Like is idempotent — one swipe, no duplicate match', async () => {
    const db = new MemoryFirestore();
    await seedEligiblePair(db);
    const first = await handleLikeAndMaybeCreateMatch(
      request('userA', 'userB'),
      deps(db),
    );
    const second = await handleLikeAndMaybeCreateMatch(
      request('userA', 'userB'),
      deps(db),
    );
    assert.strictEqual(first.outcome, OUTCOME.noMatch);
    assert.strictEqual(second.outcome, OUTCOME.noMatch);
    const swipe = await db.doc('users/userA/swipes/userB').get();
    assert.strictEqual(swipe.data().direction, 'like');
    assert.strictEqual(swipe.data().updated_at, 'TS');
    const match = await db.doc('matches/userA_userB').get();
    assert.strictEqual(match.exists, false);
  });

  it('existing active match returns existingActiveMatch without new artifacts', async () => {
    const db = new MemoryFirestore();
    await seedEligiblePair(db);
    await db.doc('users/userA/swipes/userB').set({ direction: 'like' });
    await db.doc('users/userB/swipes/userA').set({ direction: 'like' });
    await db.doc('matches/userA_userB').set({
      match_id: 'userA_userB',
      users: ['userA', 'userB'],
      state: 'active',
      thread_id: 'userA_userB',
      created_by: 'system',
      match_created_by_uid: 'userB',
    });
    await db.doc('threads/userA_userB').set({
      thread_id: 'userA_userB',
      status: 'active',
      last_message_preview: 'keep',
    });

    const res = await handleLikeAndMaybeCreateMatch(
      request('userA', 'userB'),
      deps(db),
    );
    assert.strictEqual(res.outcome, OUTCOME.existingActiveMatch);
    const match = await db.doc('matches/userA_userB').get();
    assert.strictEqual(match.data().match_created_by_uid, 'userB');
    const thread = await db.doc('threads/userA_userB').get();
    assert.strictEqual(thread.data().last_message_preview, 'keep');
    const msg = await db.doc('threads/userA_userB/messages/system_match_v1').get();
    assert.strictEqual(msg.exists, false);
  });

  it('viewer block of target prevents Like and match', async () => {
    const db = new MemoryFirestore();
    await seedEligiblePair(db);
    await db.doc('users/userB/swipes/userA').set({ direction: 'like' });
    await db.doc('users/userA/blocks/userB').set({
      blocked_uid: 'userB',
      reason: 'secret-viewer',
    });
    const res = await handleLikeAndMaybeCreateMatch(
      request('userA', 'userB'),
      deps(db),
    );
    assert.strictEqual(res.outcome, OUTCOME.noMatch);
    const swipe = await db.doc('users/userA/swipes/userB').get();
    assert.strictEqual(swipe.exists, false);
    const match = await db.doc('matches/userA_userB').get();
    assert.strictEqual(match.exists, false);
    const blob = JSON.stringify(res);
    assert.strictEqual(blob.includes('secret-viewer'), false);
    assert.strictEqual(blob.includes('blocked_uid'), false);
  });

  it('reverse-block prevents Like and match without leaking block data', async () => {
    const db = new MemoryFirestore();
    await seedEligiblePair(db);
    await db.doc('users/userB/swipes/userA').set({ direction: 'like' });
    await db.doc('users/userB/blocks/userA').set({
      blocked_uid: 'userA',
      reason: 'secret-reverse',
    });
    const res = await handleLikeAndMaybeCreateMatch(
      request('userA', 'userB'),
      deps(db),
    );
    assert.strictEqual(res.outcome, OUTCOME.noMatch);
    const swipe = await db.doc('users/userA/swipes/userB').get();
    assert.strictEqual(swipe.exists, false);
    const match = await db.doc('matches/userA_userB').get();
    assert.strictEqual(match.exists, false);
    const blob = JSON.stringify(res);
    assert.strictEqual(blob.includes('secret-reverse'), false);
    assert.strictEqual(blob.includes('reason'), false);
    assert.deepStrictEqual(Object.keys(res), ['outcome']);
  });

  it('inactive / ineligible target cannot Like or match', async () => {
    const db = new MemoryFirestore();
    await db.doc('users/userA').set(eligibleUser());
    await db.doc('users/userB').set(
      eligibleUser({ active: false, discover_eligible: false }),
    );
    await db.doc('users/userB/swipes/userA').set({ direction: 'like' });
    const res = await handleLikeAndMaybeCreateMatch(
      request('userA', 'userB'),
      deps(db),
    );
    assert.strictEqual(res.outcome, OUTCOME.noMatch);
    const swipe = await db.doc('users/userA/swipes/userB').get();
    assert.strictEqual(swipe.exists, false);
    const match = await db.doc('matches/userA_userB').get();
    assert.strictEqual(match.exists, false);
  });

  it('callable name is likeAndMaybeCreateMatch', () => {
    assert.strictEqual(CALLABLE_NAME, 'likeAndMaybeCreateMatch');
  });
});
