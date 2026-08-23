'use strict';

const assert = require('assert');
const { MemoryFirestore } = require('./memory_firestore');
const {
  ACTIVITY_TYPES,
  handleProfileActivityWritten,
  handleMatchActivityCreated,
  handleSuperResonanceActivityCreated,
} = require('../src/activity_feed');

function profile(overrides = {}) {
  return {
    name: 'Ada',
    profile_photo_url: 'https://example.com/ada-main.jpg',
    photos: ['https://example.com/ada-main.jpg'],
    bio: 'Hello',
    education: 'University',
    occupation: 'Engineer',
    profile_completed: true,
    ...overrides,
  };
}

function writtenEvent({
  uid = 'userA',
  before,
  after,
  id = 'profile-event-1',
} = {}) {
  return {
    id,
    time: '2026-08-23T08:00:00.000Z',
    params: { uid },
    data: {
      before: { data: () => before },
      after: { data: () => after },
    },
  };
}

function createdEvent({
  params = {},
  data,
  id = 'created-event-1',
} = {}) {
  return {
    id,
    time: '2026-08-23T08:00:00.000Z',
    params,
    data: {
      data: () => data,
    },
  };
}

async function seedActiveMatch(
  db,
  {
    matchId = 'match-1',
    userA = 'userA',
    userB = 'userB',
  } = {},
) {
  await db.doc(`matches/${matchId}`).set({
    match_id: matchId,
    users: [userA, userB],
    user_a: userA,
    user_b: userB,
    state: 'active',
    thread_id: `${userA}_${userB}`,
  });
}

async function feedRows(db, uid) {
  const snap = await db
    .collection(`users/${uid}/activity_feed`)
    .get();

  return snap.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

describe('activity feed', () => {
  it('does not create feed events for initial profile creation', async () => {
    const db = new MemoryFirestore();

    const result = await handleProfileActivityWritten(
      writtenEvent({
        before: undefined,
        after: profile(),
      }),
      { db },
    );

    assert.strictEqual(result.skipped, 'create_or_delete');
    assert.deepStrictEqual(await feedRows(db, 'userB'), []);
  });

  it('creates photo_added only for genuinely added photos', async () => {
    const db = new MemoryFirestore();
    await seedActiveMatch(db);

    const addedUrl = 'https://example.com/new-photo.jpg';

    const result = await handleProfileActivityWritten(
      writtenEvent({
        before: profile(),
        after: profile({
          photos: [
            'https://example.com/ada-main.jpg',
            addedUrl,
          ],
        }),
      }),
      { db },
    );

    assert.strictEqual(result.skipped, null);
    assert.deepStrictEqual(result.event_types, [
      ACTIVITY_TYPES.PHOTO_ADDED,
    ]);

    const rows = await feedRows(db, 'userB');
    assert.strictEqual(rows.length, 1);
    assert.strictEqual(
      rows[0].type,
      ACTIVITY_TYPES.PHOTO_ADDED,
    );
    assert.strictEqual(rows[0].actor_uid, 'userA');
    assert.strictEqual(rows[0].actor_name, 'Ada');
    assert.strictEqual(rows[0].photo_url, addedUrl);
    assert.strictEqual(rows[0].photo_added_count, 1);
  });

  it('does not create photo events for reorder or deletion only', async () => {
    const db = new MemoryFirestore();
    await seedActiveMatch(db);

    const before = profile({
      photos: [
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
      ],
    });

    const reordered = await handleProfileActivityWritten(
      writtenEvent({
        id: 'reorder-event',
        before,
        after: profile({
          photos: [
            'https://example.com/b.jpg',
            'https://example.com/a.jpg',
          ],
        }),
      }),
      { db },
    );

    assert.strictEqual(
      reordered.skipped,
      'no_feed_relevant_change',
    );

    const deleted = await handleProfileActivityWritten(
      writtenEvent({
        id: 'delete-event',
        before,
        after: profile({
          photos: ['https://example.com/a.jpg'],
        }),
      }),
      { db },
    );

    assert.strictEqual(
      deleted.skipped,
      'no_feed_relevant_change',
    );
    assert.deepStrictEqual(await feedRows(db, 'userB'), []);
  });

  it('creates bio_updated without copying bio text', async () => {
    const db = new MemoryFirestore();
    await seedActiveMatch(db);

    await handleProfileActivityWritten(
      writtenEvent({
        before: profile({ bio: 'Old bio' }),
        after: profile({ bio: 'New private bio text' }),
      }),
      { db },
    );

    const rows = await feedRows(db, 'userB');
    assert.strictEqual(rows.length, 1);
    assert.strictEqual(
      rows[0].type,
      ACTIVITY_TYPES.BIO_UPDATED,
    );
    assert.strictEqual(rows[0].bio, undefined);
  });

  it('combines education and occupation changes into one event', async () => {
    const db = new MemoryFirestore();
    await seedActiveMatch(db);

    await handleProfileActivityWritten(
      writtenEvent({
        before: profile({
          education: 'University',
          occupation: 'Engineer',
        }),
        after: profile({
          education: 'Graduate School',
          occupation: 'Researcher',
        }),
      }),
      { db },
    );

    const rows = await feedRows(db, 'userB');
    assert.strictEqual(rows.length, 1);
    assert.strictEqual(
      rows[0].type,
      ACTIVITY_TYPES.WORK_EDUCATION_UPDATED,
    );
    assert.deepStrictEqual(
      rows[0].changed_fields,
      ['education', 'occupation'],
    );
    assert.strictEqual(rows[0].education, undefined);
    assert.strictEqual(rows[0].occupation, undefined);
  });

  it('creates a match event for both participants', async () => {
    const db = new MemoryFirestore();

    await db.doc('users/userA').set(
      profile({
        name: 'Ada',
        profile_photo_url: 'https://example.com/ada.jpg',
      }),
    );

    await db.doc('users/userB').set(
      profile({
        name: 'Bora',
        profile_photo_url: 'https://example.com/bora.jpg',
      }),
    );

    const result = await handleMatchActivityCreated(
      createdEvent({
        id: 'match-create-event',
        params: { matchId: 'match-1' },
        data: {
          match_id: 'match-1',
          users: ['userA', 'userB'],
          state: 'active',
          thread_id: 'userA_userB',
        },
      }),
      { db },
    );

    assert.strictEqual(result.skipped, null);
    assert.strictEqual(result.writes, 2);

    const aRows = await feedRows(db, 'userA');
    const bRows = await feedRows(db, 'userB');

    assert.strictEqual(aRows.length, 1);
    assert.strictEqual(bRows.length, 1);

    assert.strictEqual(
      aRows[0].type,
      ACTIVITY_TYPES.MATCH_CREATED,
    );
    assert.strictEqual(aRows[0].actor_uid, 'userB');
    assert.strictEqual(aRows[0].actor_name, 'Bora');

    assert.strictEqual(bRows[0].actor_uid, 'userA');
    assert.strictEqual(bRows[0].actor_name, 'Ada');
  });

  it('creates Super Resonance activity only for the receiver', async () => {
    const db = new MemoryFirestore();

    await db.doc('users/userA').set(
      profile({
        name: 'Ada',
        profile_photo_url: 'https://example.com/ada.jpg',
      }),
    );

    const result = await handleSuperResonanceActivityCreated(
      createdEvent({
        id: 'sr-create-event',
        params: { signalId: 'signal-1' },
        data: {
          signal_id: 'signal-1',
          from_uid: 'userA',
          to_uid: 'userB',
        },
      }),
      { db },
    );

    assert.strictEqual(result.skipped, null);
    assert.strictEqual(result.writes, 1);

    const senderRows = await feedRows(db, 'userA');
    const receiverRows = await feedRows(db, 'userB');

    assert.deepStrictEqual(senderRows, []);
    assert.strictEqual(receiverRows.length, 1);
    assert.strictEqual(
      receiverRows[0].type,
      ACTIVITY_TYPES.SUPER_RESONANCE_RECEIVED,
    );
    assert.strictEqual(receiverRows[0].actor_uid, 'userA');
    assert.strictEqual(receiverRows[0].signal_id, 'signal-1');
  });

  it('does not fan profile updates out without an active match', async () => {
    const db = new MemoryFirestore();

    const result = await handleProfileActivityWritten(
      writtenEvent({
        before: profile({ bio: 'Old' }),
        after: profile({ bio: 'New' }),
      }),
      { db },
    );

    assert.strictEqual(result.skipped, 'no_active_matches');
    assert.deepStrictEqual(await feedRows(db, 'userB'), []);
  });
});
