'use strict';

const assert = require('assert');
const { MemoryFirestore } = require('./memory_firestore');
const {
  TRIGGER_NAME,
  REGION,
  DOCUMENT_PATH,
  NOTIFICATION_COPY,
  resolveNotificationCopy,
  buildDataPayload,
  buildFcmMessage,
  resolveMatchActor,
  handleMatchCreated,
} = require('../src/new_match_push');

const MATCH_ID = 'userA_userB';
const THREAD_ID = 'userA_userB';

function createdEvent({ matchId = MATCH_ID, data } = {}) {
  return {
    params: { matchId },
    data: {
      id: matchId,
      exists: true,
      ref: { path: `matches/${matchId}` },
      data: () => data,
    },
  };
}

function activeMatch(overrides = {}) {
  return {
    match_id: MATCH_ID,
    user_a: 'userA',
    user_b: 'userB',
    users: ['userA', 'userB'],
    created_at: 'TS',
    created_by: 'system',
    match_created_by_uid: 'userB',
    thread_id: THREAD_ID,
    state: 'active',
    last_activity_at: 'TS',
    compat: {},
    ...overrides,
  };
}

async function seedActiveThread(db, overrides = {}) {
  await db.doc(`threads/${THREAD_ID}`).set({
    thread_id: THREAD_ID,
    match_id: MATCH_ID,
    participants: ['userA', 'userB'],
    status: 'active',
    unread_counts: { userA: 0, userB: 0 },
    ...overrides,
  });
}

async function seedToken(db, uid, token, id) {
  await db.doc(`users/${uid}/fcm_tokens/${id || token}`).set({
    token,
    platform: 'ios',
    app_id: 'app',
    apns_env: 'sandbox',
  });
}

function fakeMessaging(failMap = {}) {
  const sent = [];
  return {
    sent,
    async send(message) {
      const code = failMap[message.token];
      if (code) {
        const err = new Error(code);
        err.code = code;
        throw err;
      }
      sent.push(message);
      return `mid-${sent.length}`;
    },
  };
}

function deps(db, messaging) {
  return { db, messaging, serverTimestamp: () => 'TS' };
}

describe('new match push', () => {
  it('uses europe-west1 document path constants', () => {
    assert.strictEqual(TRIGGER_NAME, 'sendNewMatchPush');
    assert.strictEqual(REGION, 'europe-west1');
    assert.strictEqual(DOCUMENT_PATH, 'matches/{matchId}');
  });

  it('defaults to English because no persisted user locale exists', () => {
    const copy = resolveNotificationCopy();
    assert.strictEqual(copy.locale, 'en');
    assert.strictEqual(copy.locale_source, 'default_en_no_persisted_user_locale');
    assert.strictEqual(copy.title, 'QMatch');
    assert.strictEqual(copy.body, 'You have a new match.');
    assert.strictEqual(NOTIFICATION_COPY.tr.body, 'Yeni bir eşleşmen var.');
  });

  it('resolveMatchActor uses match_created_by_uid only', () => {
    const users = ['userA', 'userB'];
    assert.strictEqual(
      resolveMatchActor({ match_created_by_uid: 'userB' }, users),
      'userB',
    );
    assert.strictEqual(resolveMatchActor({}, users), '');
    assert.strictEqual(
      resolveMatchActor({ match_created_by_uid: 'userC' }, users),
      '',
    );
  });

  it('sends a privacy-safe push to the first liker only', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();
    const result = await handleMatchCreated(
      createdEvent({ data: activeMatch({ match_created_by_uid: 'userB' }) }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, null);
    assert.strictEqual(result.sent, 1);
    assert.strictEqual(messaging.sent.length, 1);
    const msg = messaging.sent[0];
    assert.strictEqual(msg.token, 'tok-a1');
    assert.deepStrictEqual(msg.notification, {
      title: 'QMatch',
      body: 'You have a new match.',
    });
    assert.deepStrictEqual(msg.data, {
      type: 'match',
      match_id: MATCH_ID,
      thread_id: THREAD_ID,
      other_uid: 'userB',
    });
    assert.strictEqual(msg.apns.payload.match_id, MATCH_ID);
    assert.strictEqual(msg.apns.payload.other_uid, 'userB');
    assert.strictEqual(msg.data.name, undefined);
    assert.strictEqual(msg.data.photo, undefined);
    assert.strictEqual(msg.data.iq, undefined);
  });

  it('does not notify the creating / second liker', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();
    const result = await handleMatchCreated(
      createdEvent({ data: activeMatch({ match_created_by_uid: 'userA' }) }),
      deps(db, messaging),
    );
    assert.strictEqual(result.sent, 1);
    assert.strictEqual(messaging.sent[0].token, 'tok-b1');
    assert.strictEqual(messaging.sent[0].data.other_uid, 'userA');
  });

  it('dedupes on matchId so a retry does not send twice', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    const messaging = fakeMessaging();
    const first = await handleMatchCreated(
      createdEvent({ data: activeMatch() }),
      deps(db, messaging),
    );
    const second = await handleMatchCreated(
      createdEvent({ data: activeMatch() }),
      deps(db, messaging),
    );
    assert.strictEqual(first.sent, 1);
    assert.strictEqual(second.skipped, 'duplicate');
    assert.strictEqual(messaging.sent.length, 1);
    const receipt = await db.doc(`push_receipts/match_${MATCH_ID}`).get();
    assert.strictEqual(receipt.exists, true);
    assert.strictEqual(receipt.data().match_id, MATCH_ID);
  });

  it('fail-closes when match_created_by_uid is missing', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    // Swipe stamps would previously invert actor — must not matter.
    await db.doc('users/userA/swipes/userB').set({
      direction: 'like',
      created_at: 9999,
      updated_at: 9999,
    });
    await db.doc('users/userB/swipes/userA').set({
      direction: 'like',
      created_at: 1,
    });
    const messaging = fakeMessaging();
    const match = activeMatch();
    delete match.match_created_by_uid;
    const result = await handleMatchCreated(
      createdEvent({ data: match }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, 'actor_unknown');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('fail-closes when match_created_by_uid is not a participant', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    const messaging = fakeMessaging();
    const result = await handleMatchCreated(
      createdEvent({
        data: activeMatch({ match_created_by_uid: 'userC' }),
      }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, 'actor_unknown');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('later swipe timestamp changes cannot flip the recipient', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    // First liker swipe made "newer" after match create (race / retry).
    await db.doc('users/userA/swipes/userB').set({
      from_uid: 'userA',
      target_uid: 'userB',
      direction: 'like',
      created_at: 1000,
      updated_at: 9_000_000,
    });
    await db.doc('users/userB/swipes/userA').set({
      from_uid: 'userB',
      target_uid: 'userA',
      direction: 'like',
      created_at: 2000,
    });
    const messaging = fakeMessaging();
    const result = await handleMatchCreated(
      createdEvent({ data: activeMatch({ match_created_by_uid: 'userB' }) }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, null);
    assert.strictEqual(result.sent, 1);
    assert.strictEqual(messaging.sent[0].token, 'tok-a1');
    assert.strictEqual(messaging.sent[0].data.other_uid, 'userB');
  });

  it('does not send for inactive or closed match/thread', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    const messaging = fakeMessaging();
    const inactive = await handleMatchCreated(
      createdEvent({ data: activeMatch({ state: 'unmatched' }) }),
      deps(db, messaging),
    );
    assert.strictEqual(inactive.skipped, 'match_not_active');

    await db.doc(`threads/${THREAD_ID}`).set({ status: 'closed' }, { merge: true });
    const closed = await handleMatchCreated(
      createdEvent({ data: activeMatch() }),
      deps(db, messaging),
    );
    assert.strictEqual(closed.skipped, 'thread_not_active');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('does not send when either side has blocked the other', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    await db.doc('users/userA/blocks/userB').set({ blocked_uid: 'userB' });
    const messaging = fakeMessaging();
    const result = await handleMatchCreated(
      createdEvent({ data: activeMatch() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, 'blocked');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('does not send when created_by is not system', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    const messaging = fakeMessaging();
    const result = await handleMatchCreated(
      createdEvent({ data: activeMatch({ created_by: 'userB' }) }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, 'created_by_not_system');
  });

  it('deletes only the invalid token and still sends the valid one', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-bad', 'hash-bad');
    await seedToken(db, 'userA', 'tok-good', 'hash-good');
    const messaging = fakeMessaging({
      'tok-bad': 'messaging/registration-token-not-registered',
    });
    const result = await handleMatchCreated(
      createdEvent({ data: activeMatch() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.sent, 1);
    assert.strictEqual(result.cleaned, 1);
    assert.strictEqual(messaging.sent.length, 1);
    assert.strictEqual(messaging.sent[0].token, 'tok-good');
    const bad = await db.doc('users/userA/fcm_tokens/hash-bad').get();
    const good = await db.doc('users/userA/fcm_tokens/hash-good').get();
    assert.strictEqual(bad.exists, false);
    assert.strictEqual(good.exists, true);
  });

  it('data payload has only type, match_id, thread_id, other_uid', () => {
    const payload = buildDataPayload({
      matchId: MATCH_ID,
      threadId: THREAD_ID,
      otherUid: 'userB',
    });
    assert.deepStrictEqual(Object.keys(payload).sort(), [
      'match_id',
      'other_uid',
      'thread_id',
      'type',
    ]);
    const msg = buildFcmMessage({
      token: 'tok',
      title: 'QMatch',
      body: 'You have a new match.',
      data: payload,
    });
    assert.strictEqual(msg.apns.payload.type, 'match');
    assert.strictEqual(msg.apns.payload.match_id, MATCH_ID);
  });

  it('skips when recipient matches pref or push_master is false', async () => {
    async function runWithPrefs(prefs) {
      const db = new MemoryFirestore();
      await seedActiveThread(db);
      await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
      await db.doc('users/userA/preferences/notification_prefs_v1').set(prefs);
      const messaging = fakeMessaging();
      const result = await handleMatchCreated(
        createdEvent({ data: activeMatch() }),
        deps(db, messaging),
      );
      return { result, messaging };
    }

    const categoryOff = await runWithPrefs({
      push_master: true,
      messages: true,
      matches: false,
      super_resonance: true,
    });
    assert.strictEqual(categoryOff.result.skipped, 'match_pref_disabled');
    assert.strictEqual(categoryOff.messaging.sent.length, 0);

    const masterOff = await runWithPrefs({
      push_master: false,
      messages: true,
      matches: true,
      super_resonance: true,
    });
    assert.strictEqual(masterOff.result.skipped, 'match_pref_disabled');
    assert.strictEqual(masterOff.messaging.sent.length, 0);
  });
});
