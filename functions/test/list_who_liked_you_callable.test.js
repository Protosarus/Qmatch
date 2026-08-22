'use strict';

const assert = require('assert');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  handleListWhoLikedYou,
  CALLABLE_NAME,
  DEPLOYED_REGION,
  MAX_ITEMS,
  ENRICHMENT_DOCS_PER_CANDIDATE,
  PUBLIC_CARD_KEYS,
  toPublicCard,
  buildLikerEnrichmentRefs,
} = require('../src/list_who_liked_you_callable');
const { GET_ALL_CHUNK_SIZE } = require('../src/alignment_signals_batch');
const { deterministicMatchId } = require('../src/like_match_atomicity');
const fs = require('fs');
const path = require('path');

function eligibleUser(overrides = {}) {
  return {
    discover_eligible: true,
    active: true,
    profile_completed: true,
    test_completed: true,
    profile_photo_url: 'https://example.com/p.jpg',
    photos: ['https://example.com/p.jpg'],
    name: 'Liker',
    age: 28,
    bio: 'Hello',
    interests: ['music'],
    ...overrides,
  };
}

function entitledSnapshot(overrides = {}) {
  return {
    uid: 'viewer',
    tier: 'resonance',
    subscription_state: 'active',
    resonance_access: true,
    ...overrides,
  };
}

function request(uid, data = {}) {
  return {
    auth: uid ? { uid } : null,
    data,
  };
}

async function seedEntitledViewer(db, uid = 'viewer') {
  await db.doc(`users/${uid}`).set(eligibleUser({ name: 'Viewer' }));
  await db.doc(`entitlements/${uid}`).set(entitledSnapshot({ uid }));
}

async function seedInboundLike(db, likerUid, viewerUid, createdAt, userOverrides = {}) {
  await db.doc(`users/${likerUid}`).set(
    eligibleUser({ name: likerUid, ...userOverrides }),
  );
  await db.doc(`users/${likerUid}/swipes/${viewerUid}`).set({
    from_uid: likerUid,
    target_uid: viewerUid,
    direction: 'like',
    source: 'discover',
    created_at: createdAt,
  });
}

describe('listWhoLikedYou callable', () => {
  it('callable name is listWhoLikedYou', () => {
    assert.strictEqual(CALLABLE_NAME, 'listWhoLikedYou');
    assert.strictEqual(DEPLOYED_REGION, 'us-central1');
    assert.strictEqual(MAX_ITEMS, 50);
  });

  it('unauthenticated throws', async () => {
    await assert.rejects(
      () =>
        handleListWhoLikedYou(request(null), { db: new MemoryFirestore() }),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
  });

  it('missing entitlement returns no identities', async () => {
    const db = new MemoryFirestore();
    await seedInboundLike(db, 'liker1', 'viewer', 100);
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.deepStrictEqual(res, { resonance_access: false, items: [] });
  });

  it('expired Resonance returns no identities', async () => {
    const db = new MemoryFirestore();
    await db.doc('entitlements/viewer').set({
      tier: 'resonance',
      subscription_state: 'expired',
      resonance_access: true,
    });
    await seedInboundLike(db, 'liker1', 'viewer', 100);
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.strictEqual(res.resonance_access, false);
    assert.deepStrictEqual(res.items, []);
  });

  it('forged resonance_access true without granting state is denied', async () => {
    const db = new MemoryFirestore();
    await db.doc('entitlements/viewer').set({
      tier: 'free',
      subscription_state: 'none',
      resonance_access: true,
    });
    await seedInboundLike(db, 'liker1', 'viewer', 100);
    const res = await handleListWhoLikedYou(
      request('viewer', { resonance_access: true }),
      { db },
    );
    assert.strictEqual(res.resonance_access, false);
    assert.deepStrictEqual(res.items, []);
  });

  it('returns public card for entitled inbound like', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    await seedInboundLike(db, 'liker1', 'viewer', 200, {
      name: 'Ada',
      age: 31,
      bio: 'Stars',
      interests: ['art', 'tea'],
      photos: ['https://example.com/a.jpg'],
      profile_photo_url: 'https://example.com/a.jpg',
      iq_normalized: 99,
      eq_normalized: 88,
      frequency_type: 'secret',
      archetype: 'hidden',
      category: 'A',
      email: 'ada@example.com',
      phone: '+1555',
    });
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.strictEqual(res.resonance_access, true);
    assert.strictEqual(res.items.length, 1);
    assert.deepStrictEqual(Object.keys(res.items[0]).sort(), [
      ...PUBLIC_CARD_KEYS,
    ].sort());
    assert.deepStrictEqual(res.items[0], {
      uid: 'liker1',
      name: 'Ada',
      age: 31,
      photos: ['https://example.com/a.jpg'],
      profile_photo_url: 'https://example.com/a.jpg',
      bio: 'Stars',
      interests: ['art', 'tea'],
    });
    assert.strictEqual('iq_normalized' in res.items[0], false);
    assert.strictEqual('email' in res.items[0], false);
    assert.strictEqual('phone' in res.items[0], false);
    assert.strictEqual('compatibility_score' in res.items[0], false);
  });

  it('omits pass inbound swipes', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    await db.doc('users/passer').set(eligibleUser({ name: 'Passer' }));
    await db.doc('users/passer/swipes/viewer').set({
      from_uid: 'passer',
      target_uid: 'viewer',
      direction: 'pass',
      created_at: 300,
    });
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.deepStrictEqual(res.items, []);
  });

  it('excludes liker the viewer already swiped', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    await seedInboundLike(db, 'liker1', 'viewer', 100);
    await db.doc('users/viewer/swipes/liker1').set({
      from_uid: 'viewer',
      target_uid: 'liker1',
      direction: 'pass',
    });
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.deepStrictEqual(res.items, []);
  });

  it('excludes any existing match state', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    await seedInboundLike(db, 'liker1', 'viewer', 100);
    await db.doc('matches/liker1_viewer').set({ state: 'unmatched' });
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.deepStrictEqual(res.items, []);
  });

  it('excludes either-direction block without leaking block fields', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    await seedInboundLike(db, 'blockedMe', 'viewer', 100);
    await seedInboundLike(db, 'iBlocked', 'viewer', 90);
    await db.doc('users/blockedMe/blocks/viewer').set({ reason: 'secret' });
    await db.doc('users/viewer/blocks/iBlocked').set({ reason: 'mine' });
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.deepStrictEqual(res.items, []);
    assert.strictEqual(JSON.stringify(res).includes('secret'), false);
    assert.strictEqual(JSON.stringify(res).includes('blocks'), false);
  });

  it('excludes ineligible, inactive, and deletion-requested likers', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    await seedInboundLike(db, 'noPhoto', 'viewer', 100, {
      profile_photo_url: '',
      photos: [],
    });
    await seedInboundLike(db, 'inactive', 'viewer', 90, { active: false });
    await seedInboundLike(db, 'deleted', 'viewer', 80, {
      account_deletion_requested: true,
      discover_eligible: true,
    });
    await seedInboundLike(db, 'noAssess', 'viewer', 70, {
      test_completed: false,
      assessment_flow_completed: false,
    });
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.deepStrictEqual(res.items, []);
  });

  it('excludes self inbound like', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    await db.doc('users/viewer/swipes/viewer').set({
      from_uid: 'viewer',
      target_uid: 'viewer',
      direction: 'like',
      created_at: 1,
    });
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.deepStrictEqual(res.items, []);
  });

  it('orders newest first and caps at 50', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    for (let i = 0; i < 51; i += 1) {
      const uid = `liker${String(i).padStart(2, '0')}`;
      await seedInboundLike(db, uid, 'viewer', i, { name: uid });
    }
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.strictEqual(res.items.length, 50);
    assert.strictEqual(res.items[0].uid, 'liker50');
    assert.strictEqual(res.items[49].uid, 'liker01');
    assert.strictEqual(
      res.items.some((item) => item.uid === 'liker00'),
      false,
    );
  });

  it('failed liker lookup is omitted and does not expose the person', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    await seedInboundLike(db, 'liker_ok', 'viewer', 200, { name: 'Ok' });
    await seedInboundLike(db, 'liker_boom', 'viewer', 100, { name: 'Boom' });
    const realDoc = db.doc.bind(db);
    db.doc = (path) => {
      if (path === 'users/liker_boom') {
        return {
          get: async () => {
            throw new Error('unavailable');
          },
        };
      }
      return realDoc(path);
    };
    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.strictEqual(res.resonance_access, true);
    assert.strictEqual(res.items.length, 1);
    assert.strictEqual(res.items[0].uid, 'liker_ok');
    assert.strictEqual(
      res.items.some((item) => item.uid === 'liker_boom'),
      false,
    );
  });

  it('toPublicCard never copies sensitive fields', () => {
    const card = toPublicCard('u1', {
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
    });
    assert.deepStrictEqual(Object.keys(card).sort(), [...PUBLIC_CARD_KEYS].sort());
    assert.strictEqual(card.email, undefined);
  });

  it('batches enrichment refs in one getAll round with stable path order', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    await seedInboundLike(db, 'liker_a', 'viewer', 300, { name: 'Ada' });
    await seedInboundLike(db, 'liker_b', 'viewer', 200, { name: 'Bea' });
    await seedInboundLike(db, 'liker_c', 'viewer', 100, { name: 'Cia' });

    const getAllCalls = [];
    const orig = db.getAll.bind(db);
    db.getAll = async (...refs) => {
      getAllCalls.push(refs.map((r) => r.path));
      return orig(...refs);
    };

    const res = await handleListWhoLikedYou(request('viewer'), { db });

    assert.strictEqual(getAllCalls.length, 1);
    assert.strictEqual(getAllCalls[0].length, 3 * ENRICHMENT_DOCS_PER_CANDIDATE);
    const expected = [];
    for (const uid of ['liker_a', 'liker_b', 'liker_c']) {
      const matchId = deterministicMatchId('viewer', uid);
      expected.push(
        `users/${uid}`,
        `users/viewer/swipes/${uid}`,
        `matches/${matchId}`,
        `users/viewer/blocks/${uid}`,
        `users/${uid}/blocks/viewer`,
      );
    }
    assert.deepStrictEqual(getAllCalls[0], expected);
    assert.deepStrictEqual(
      res.items.map((c) => c.uid),
      ['liker_a', 'liker_b', 'liker_c'],
    );
    assert.ok(GET_ALL_CHUNK_SIZE >= 100);
  });

  it('batched enrichment preserves eligibility, blocks, matches, and order', async () => {
    const db = new MemoryFirestore();
    await seedEntitledViewer(db);
    // Newest first from query order by created_at desc.
    await seedInboundLike(db, 'keep_new', 'viewer', 500, { name: 'New' });
    await seedInboundLike(db, 'blocked_me', 'viewer', 400, { name: 'BlockedMe' });
    await seedInboundLike(db, 'i_blocked', 'viewer', 300, { name: 'IBlocked' });
    await seedInboundLike(db, 'already_swiped', 'viewer', 200, { name: 'Swiped' });
    await seedInboundLike(db, 'matched', 'viewer', 150, { name: 'Matched' });
    await seedInboundLike(db, 'keep_old', 'viewer', 100, { name: 'Old' });
    await seedInboundLike(db, 'inactive', 'viewer', 50, {
      name: 'Inactive',
      active: false,
    });

    await db.doc('users/blocked_me/blocks/viewer').set({ reason: 'secret' });
    await db.doc('users/viewer/blocks/i_blocked').set({ reason: 'mine' });
    await db.doc('users/viewer/swipes/already_swiped').set({
      from_uid: 'viewer',
      target_uid: 'already_swiped',
      direction: 'pass',
    });
    await db
      .doc(`matches/${deterministicMatchId('viewer', 'matched')}`)
      .set({ state: 'unmatched' });

    const res = await handleListWhoLikedYou(request('viewer'), { db });
    assert.strictEqual(res.resonance_access, true);
    assert.deepStrictEqual(
      res.items.map((c) => c.uid),
      ['keep_new', 'keep_old'],
    );
    assert.strictEqual(JSON.stringify(res).includes('secret'), false);
    assert.strictEqual(JSON.stringify(res).includes('blocks'), false);
  });

  it('buildLikerEnrichmentRefs and source use getAll without per-candidate fan-out', () => {
    const db = new MemoryFirestore();
    const refs = buildLikerEnrichmentRefs(db, 'viewer', ['a', 'b']);
    assert.strictEqual(refs.length, 10);
    assert.strictEqual(refs[0].path, 'users/a');
    assert.strictEqual(refs[5].path, 'users/b');

    const src = fs.readFileSync(
      path.join(__dirname, '../src/list_who_liked_you_callable.js'),
      'utf8',
    );
    assert.ok(src.includes('getAllSnapsIsolating'));
    assert.ok(src.includes('buildLikerEnrichmentRefs'));
    assert.ok(src.includes("require('./alignment_signals_batch')"));
    assert.strictEqual(src.includes('mapWithConcurrency'), false);
    assert.strictEqual(src.includes('qmatch.alignment'), false);
    assert.strictEqual(src.includes('emitAlignmentTimings'), false);
  });
});
