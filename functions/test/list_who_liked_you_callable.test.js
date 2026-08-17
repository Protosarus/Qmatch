'use strict';

const assert = require('assert');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  handleListWhoLikedYou,
  CALLABLE_NAME,
  MAX_ITEMS,
  PUBLIC_CARD_KEYS,
  toPublicCard,
} = require('../src/list_who_liked_you_callable');

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
});
