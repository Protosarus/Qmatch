'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  handleListSuperResonanceInbox,
  CALLABLE_NAME,
  DEPLOYED_REGION,
  MAX_ITEMS,
  ENRICHMENT_DOCS_PER_CANDIDATE,
  PUBLIC_CARD_KEYS,
  PUBLIC_RESULT_KEYS,
  toPublicInboxCard,
  buildSenderEnrichmentRefs,
} = require('../src/list_super_resonance_inbox_callable');
const {
  handleListWhoLikedYou,
} = require('../src/list_who_liked_you_callable');
const { SCHEMA_VERSION } = require('../src/super_resonance_signal');
const { GET_ALL_CHUNK_SIZE } = require('../src/alignment_signals_batch');
const { deterministicMatchId } = require('../src/like_match_atomicity');

function eligibleUser(overrides = {}) {
  return {
    discover_eligible: true,
    active: true,
    profile_completed: true,
    test_completed: true,
    profile_photo_url: 'https://example.com/p.jpg',
    photos: ['https://example.com/p.jpg'],
    name: 'Sender',
    age: 28,
    bio: 'Hello',
    interests: ['music'],
    ...overrides,
  };
}

function request(uid, data = {}) {
  return {
    auth: uid ? { uid } : null,
    data,
  };
}

async function seedViewer(db, uid = 'viewer', entitlement = null) {
  await db.doc(`users/${uid}`).set(eligibleUser({ name: 'Viewer' }));
  if (entitlement) {
    await db.doc(`entitlements/${uid}`).set(entitlement);
  }
}

async function seedSignal(db, fromUid, toUid, createdAt, userOverrides = {}) {
  await db.doc(`users/${fromUid}`).set(
    eligibleUser({ name: fromUid, ...userOverrides }),
  );
  await db.doc(`super_resonance_signals/${fromUid}_${toUid}`).set({
    from_uid: fromUid,
    to_uid: toUid,
    created_at: createdAt,
    status: 'active',
    spend_request_id: `req-${fromUid}`,
    spend_ledger_id: `led-${fromUid}`,
    schema_version: SCHEMA_VERSION,
  });
}

async function seedOrdinaryLike(db, fromUid, toUid, createdAt) {
  await db.doc(`users/${fromUid}`).set(eligibleUser({ name: fromUid }));
  await db.doc(`users/${fromUid}/swipes/${toUid}`).set({
    from_uid: fromUid,
    target_uid: toUid,
    direction: 'like',
    source: 'discover',
    created_at: createdAt,
  });
}

describe('listSuperResonanceInbox callable', () => {
  it('callable name is listSuperResonanceInbox', () => {
    assert.strictEqual(CALLABLE_NAME, 'listSuperResonanceInbox');
    assert.strictEqual(DEPLOYED_REGION, 'us-central1');
    assert.strictEqual(MAX_ITEMS, 50);
  });

  it('unauthenticated throws', async () => {
    await assert.rejects(
      () =>
        handleListSuperResonanceInbox(request(null), {
          db: new MemoryFirestore(),
        }),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
  });

  it('Free receiver can see inbound Super Resonance identity', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db, 'viewer', {
      uid: 'viewer',
      tier: 'free',
      subscription_state: 'none',
      resonance_access: false,
    });
    await seedSignal(db, 'sender1', 'viewer', 200, {
      name: 'Ada',
      age: 31,
      bio: 'Stars',
      interests: ['art', 'tea'],
      photos: ['https://example.com/a.jpg'],
      profile_photo_url: 'https://example.com/a.jpg',
    });
    const res = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.deepStrictEqual(Object.keys(res).sort(), [...PUBLIC_RESULT_KEYS].sort());
    assert.strictEqual(res.items.length, 1);
    assert.deepStrictEqual(res.items[0], {
      uid: 'sender1',
      name: 'Ada',
      age: 31,
      photos: ['https://example.com/a.jpg'],
      profile_photo_url: 'https://example.com/a.jpg',
      bio: 'Stars',
      interests: ['art', 'tea'],
      super_resonance: true,
      created_at: 200,
    });
    assert.strictEqual('resonance_access' in res, false);
  });

  it('Resonance receiver can see inbound Super Resonance identity', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db, 'viewer', {
      uid: 'viewer',
      tier: 'resonance',
      subscription_state: 'active',
      resonance_access: true,
    });
    await seedSignal(db, 'sender1', 'viewer', 100, { name: 'Ada', age: 30 });
    const res = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.strictEqual(res.items.length, 1);
    assert.strictEqual(res.items[0].uid, 'sender1');
    assert.strictEqual(res.items[0].super_resonance, true);
  });

  it('ordinary Like is not included', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db);
    await seedOrdinaryLike(db, 'liker1', 'viewer', 300);
    const inbox = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.deepStrictEqual(inbox.items, []);

    await db.doc('entitlements/viewer').set({
      uid: 'viewer',
      tier: 'free',
      subscription_state: 'none',
      resonance_access: false,
    });
    await seedSignal(db, 'sender1', 'viewer', 200, { name: 'Ada', age: 30 });
    const whoLiked = await handleListWhoLikedYou(request('viewer'), { db });
    assert.strictEqual(whoLiked.resonance_access, false);
    assert.deepStrictEqual(whoLiked.items, []);
    const after = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.strictEqual(after.items.length, 1);
    assert.strictEqual(after.items[0].uid, 'sender1');
  });

  it('either-direction block is omitted without leaking reasons', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db);
    await seedSignal(db, 'blockedMe', 'viewer', 100);
    await seedSignal(db, 'iBlocked', 'viewer', 90);
    await db.doc('users/blockedMe/blocks/viewer').set({ reason: 'secret' });
    await db.doc('users/viewer/blocks/iBlocked').set({ reason: 'mine' });
    const res = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.deepStrictEqual(res.items, []);
    assert.strictEqual(JSON.stringify(res).includes('secret'), false);
    assert.strictEqual(JSON.stringify(res).includes('mine'), false);
    assert.strictEqual(JSON.stringify(res).includes('block'), false);
    assert.strictEqual('reason' in res, false);
  });

  it('any existing match state is omitted', async () => {
    for (const state of ['active', 'unmatched', 'blocked']) {
      const db = new MemoryFirestore();
      await seedViewer(db);
      await seedSignal(db, 'sender1', 'viewer', 100);
      await db.doc('matches/sender1_viewer').set({ state });
      const res = await handleListSuperResonanceInbox(request('viewer'), { db });
      assert.deepStrictEqual(res.items, []);
    }
  });

  it('receiver already swiped sender is omitted', async () => {
    for (const direction of ['like', 'pass']) {
      const db = new MemoryFirestore();
      await seedViewer(db);
      await seedSignal(db, 'sender1', 'viewer', 100);
      await db.doc('users/viewer/swipes/sender1').set({
        from_uid: 'viewer',
        target_uid: 'sender1',
        direction,
      });
      const res = await handleListSuperResonanceInbox(request('viewer'), { db });
      assert.deepStrictEqual(res.items, []);
    }
  });

  it('sender later Pass is omitted', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db);
    await seedSignal(db, 'sender1', 'viewer', 100);
    await db.doc('users/sender1/swipes/viewer').set({
      from_uid: 'sender1',
      target_uid: 'viewer',
      direction: 'pass',
    });
    const res = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.deepStrictEqual(res.items, []);
  });

  it('sender later Like still appears', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db);
    await seedSignal(db, 'sender1', 'viewer', 100, { name: 'Ada', age: 30 });
    await db.doc('users/sender1/swipes/viewer').set({
      from_uid: 'sender1',
      target_uid: 'viewer',
      direction: 'like',
    });
    const res = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.strictEqual(res.items.length, 1);
    assert.strictEqual(res.items[0].uid, 'sender1');
  });

  it('inactive / deleted / ineligible sender is omitted', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db);
    await seedSignal(db, 'noPhoto', 'viewer', 100, {
      profile_photo_url: '',
      photos: [],
    });
    await seedSignal(db, 'inactive', 'viewer', 90, { active: false });
    await seedSignal(db, 'deleted', 'viewer', 80, {
      account_deletion_requested: true,
      discover_eligible: true,
    });
    await seedSignal(db, 'noAssess', 'viewer', 70, {
      test_completed: false,
      assessment_flow_completed: false,
    });
    await seedSignal(db, 'incomplete', 'viewer', 60, {
      profile_completed: false,
    });
    await seedSignal(db, 'ineligible', 'viewer', 50, {
      discover_eligible: false,
    });
    await db.doc('super_resonance_signals/ghost_viewer').set({
      from_uid: 'ghost',
      to_uid: 'viewer',
      created_at: 40,
      status: 'active',
      spend_request_id: 'req-ghost',
      spend_ledger_id: 'led-ghost',
      schema_version: SCHEMA_VERSION,
    });
    const res = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.deepStrictEqual(res.items, []);
  });

  it('orders newest first and caps at 50', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db);
    for (let i = 0; i < 51; i += 1) {
      const uid = `sender${String(i).padStart(2, '0')}`;
      await seedSignal(db, uid, 'viewer', i, { name: uid, age: 24 });
    }
    const res = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.strictEqual(res.items.length, 50);
    assert.strictEqual(res.items[0].uid, 'sender50');
    assert.strictEqual(res.items[49].uid, 'sender01');
    assert.strictEqual(
      res.items.some((item) => item.uid === 'sender00'),
      false,
    );
    assert.ok(
      res.items.every(
        (item, idx) => idx === 0 || item.created_at <= res.items[idx - 1].created_at,
      ),
    );
  });

  it('failed sender lookup is omitted and does not expose the person', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db);
    await seedSignal(db, 'sender_ok', 'viewer', 200, { name: 'Ok' });
    await seedSignal(db, 'sender_boom', 'viewer', 100, { name: 'Boom' });
    const realDoc = db.doc.bind(db);
    db.doc = (path) => {
      if (path === 'users/sender_boom') {
        return {
          get: async () => {
            throw new Error('unavailable');
          },
        };
      }
      return realDoc(path);
    };
    const res = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.strictEqual(res.items.length, 1);
    assert.strictEqual(res.items[0].uid, 'sender_ok');
    assert.strictEqual(
      res.items.some((item) => item.uid === 'sender_boom'),
      false,
    );
  });

  it('never leaks private fields', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db);
    await seedSignal(db, 'sender1', 'viewer', 100, {
      name: 'Ada',
      age: 30,
      bio: 'Hi',
      interests: ['x'],
      photos: ['https://example.com/a.jpg'],
      profile_photo_url: 'https://example.com/a.jpg',
      iq_normalized: 99,
      eq_normalized: 88,
      frequency_type: 'secret',
      archetype: 'hidden',
      category: 'A',
      email: 'ada@example.com',
      phone: '+1555',
      canonical_v1: { secret: true },
      compatibility_score: 0.9,
      ranking_score: 12,
    });
    await db.doc('entitlements/sender1').set({
      super_resonance_balance: 7,
      resonance_access: true,
    });
    const res = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.strictEqual(res.items.length, 1);
    assert.deepStrictEqual(Object.keys(res.items[0]).sort(), [
      ...PUBLIC_CARD_KEYS,
    ].sort());
    const raw = JSON.stringify(res);
    assert.strictEqual(raw.includes('iq_normalized'), false);
    assert.strictEqual(raw.includes('eq_normalized'), false);
    assert.strictEqual(raw.includes('frequency_type'), false);
    assert.strictEqual(raw.includes('canonical_v1'), false);
    assert.strictEqual(raw.includes('ada@example.com'), false);
    assert.strictEqual(raw.includes('+1555'), false);
    assert.strictEqual(raw.includes('compatibility_score'), false);
    assert.strictEqual(raw.includes('ranking_score'), false);
    assert.strictEqual(raw.includes('super_resonance_balance'), false);
    assert.strictEqual('email' in res.items[0], false);
    assert.strictEqual('phone' in res.items[0], false);
  });

  it('toPublicInboxCard never copies sensitive fields', () => {
    const card = toPublicInboxCard(
      'u1',
      {
        name: 'Ada',
        age: 30,
        bio: 'Hi',
        interests: ['x'],
        photos: ['https://example.com/a.jpg'],
        profile_photo_url: 'https://example.com/a.jpg',
        iq_normalized: 1,
        eq_normalized: 2,
        email: 'x@y.z',
        phone: '1',
        canonical_v1: { secret: true },
      },
      12,
    );
    assert.deepStrictEqual(Object.keys(card).sort(), [...PUBLIC_CARD_KEYS].sort());
    assert.strictEqual(card.super_resonance, true);
    assert.strictEqual(card.email, undefined);
  });

  it('does not query likes or change Alignment Signals / matching sources', () => {
    const inboxSrc = fs.readFileSync(
      path.join(__dirname, '../src/list_super_resonance_inbox_callable.js'),
      'utf8',
    );
    assert.strictEqual(inboxSrc.includes('resonance_access'), false);
    assert.strictEqual(inboxSrc.includes('collectionGroup'), false);
    assert.strictEqual(inboxSrc.includes('handleListWhoLikedYou'), false);
    assert.strictEqual(inboxSrc.includes('likeAndMaybeCreateMatch'), false);
    assert.strictEqual(inboxSrc.includes('compareStageB2Structural'), false);

    const whoLikedSrc = fs.readFileSync(
      path.join(__dirname, '../src/list_who_liked_you_callable.js'),
      'utf8',
    );
    assert.strictEqual(whoLikedSrc.includes('super_resonance'), false);
  });

  it('batches enrichment refs in one getAll round with stable path order', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db);
    await seedSignal(db, 'sender_a', 'viewer', 300, { name: 'Ada' });
    await seedSignal(db, 'sender_b', 'viewer', 200, { name: 'Bea' });
    await seedSignal(db, 'sender_c', 'viewer', 100, { name: 'Cia' });

    const getAllCalls = [];
    const orig = db.getAll.bind(db);
    db.getAll = async (...refs) => {
      getAllCalls.push(refs.map((r) => r.path));
      return orig(...refs);
    };

    const res = await handleListSuperResonanceInbox(request('viewer'), { db });

    assert.strictEqual(getAllCalls.length, 1);
    assert.strictEqual(getAllCalls[0].length, 3 * ENRICHMENT_DOCS_PER_CANDIDATE);
    const expected = [];
    for (const uid of ['sender_a', 'sender_b', 'sender_c']) {
      const matchId = deterministicMatchId('viewer', uid);
      expected.push(
        `users/${uid}`,
        `users/viewer/swipes/${uid}`,
        `users/${uid}/swipes/viewer`,
        `matches/${matchId}`,
        `users/viewer/blocks/${uid}`,
        `users/${uid}/blocks/viewer`,
      );
    }
    assert.deepStrictEqual(getAllCalls[0], expected);
    assert.deepStrictEqual(
      res.items.map((c) => c.uid),
      ['sender_a', 'sender_b', 'sender_c'],
    );
    assert.ok(GET_ALL_CHUNK_SIZE >= 100);
  });

  it('batched enrichment preserves eligibility, blocks, passes, matches, and order', async () => {
    const db = new MemoryFirestore();
    await seedViewer(db);
    await seedSignal(db, 'keep_new', 'viewer', 500, { name: 'New' });
    await seedSignal(db, 'blocked_me', 'viewer', 400, { name: 'BlockedMe' });
    await seedSignal(db, 'i_blocked', 'viewer', 300, { name: 'IBlocked' });
    await seedSignal(db, 'viewer_swiped', 'viewer', 250, { name: 'Swiped' });
    await seedSignal(db, 'sender_passed', 'viewer', 200, { name: 'Passed' });
    await seedSignal(db, 'matched', 'viewer', 150, { name: 'Matched' });
    await seedSignal(db, 'keep_old', 'viewer', 100, { name: 'Old' });
    await seedSignal(db, 'inactive', 'viewer', 50, {
      name: 'Inactive',
      active: false,
    });

    await db.doc('users/blocked_me/blocks/viewer').set({ reason: 'secret' });
    await db.doc('users/viewer/blocks/i_blocked').set({ reason: 'mine' });
    await db.doc('users/viewer/swipes/viewer_swiped').set({
      from_uid: 'viewer',
      target_uid: 'viewer_swiped',
      direction: 'like',
    });
    await db.doc('users/sender_passed/swipes/viewer').set({
      from_uid: 'sender_passed',
      target_uid: 'viewer',
      direction: 'pass',
    });
    await db
      .doc(`matches/${deterministicMatchId('viewer', 'matched')}`)
      .set({ state: 'active' });

    const res = await handleListSuperResonanceInbox(request('viewer'), { db });
    assert.deepStrictEqual(
      res.items.map((c) => c.uid),
      ['keep_new', 'keep_old'],
    );
    assert.strictEqual(res.items.every((c) => c.super_resonance === true), true);
    assert.strictEqual(JSON.stringify(res).includes('secret'), false);
  });

  it('buildSenderEnrichmentRefs and source use getAll without per-candidate fan-out', () => {
    const db = new MemoryFirestore();
    const refs = buildSenderEnrichmentRefs(db, 'viewer', [
      { senderUid: 'a' },
      { senderUid: 'b' },
    ]);
    assert.strictEqual(refs.length, 12);
    assert.strictEqual(refs[0].path, 'users/a');
    assert.strictEqual(refs[6].path, 'users/b');

    const src = fs.readFileSync(
      path.join(__dirname, '../src/list_super_resonance_inbox_callable.js'),
      'utf8',
    );
    assert.ok(src.includes('getAllSnapsIsolating'));
    assert.ok(src.includes('buildSenderEnrichmentRefs'));
    assert.ok(src.includes("require('./alignment_signals_batch')"));
    assert.strictEqual(src.includes('mapWithConcurrency'), false);
    assert.strictEqual(src.includes('qmatch.alignment'), false);
    assert.strictEqual(src.includes('emitAlignmentTimings'), false);
  });
});
