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
  handleSuperResonanceSignalCreated,
} = require('../src/super_resonance_push');

const SIGNAL_ID = 'userA_userB';

function createdEvent({ signalId = SIGNAL_ID, data } = {}) {
  return {
    params: { signalId },
    data: {
      id: signalId,
      exists: true,
      ref: { path: `super_resonance_signals/${signalId}` },
      data: () => data,
    },
  };
}

function activeSignal(overrides = {}) {
  return {
    from_uid: 'userA',
    to_uid: 'userB',
    created_at: 'TS',
    status: 'active',
    spend_request_id: 'req-1',
    spend_ledger_id: 'led-1',
    schema_version: 'super_resonance_signal_v1',
    ...overrides,
  };
}

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

async function seedRecipient(db, uid = 'userB') {
  await db.doc(`users/${uid}`).set(eligibleUser({ name: uid }));
}

async function seedToken(
  db,
  uid,
  token,
  id,
  notificationLocale,
) {
  await db.doc(`users/${uid}/fcm_tokens/${id || token}`).set({
    token,
    platform: 'ios',
    app_id: 'app',
    apns_env: 'sandbox',
    ...(notificationLocale
      ? { notification_locale: notificationLocale }
      : {}),
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

describe('super resonance push', () => {
  it('uses europe-west1 document path constants', () => {
    assert.strictEqual(TRIGGER_NAME, 'sendSuperResonancePush');
    assert.strictEqual(REGION, 'europe-west1');
    assert.strictEqual(DOCUMENT_PATH, 'super_resonance_signals/{signalId}');
  });

  it('uses token locale and safely defaults missing locale to English', () => {
    const copy = resolveNotificationCopy();
    assert.strictEqual(copy.locale, 'en');
    assert.strictEqual(copy.locale_source, 'default_en_missing_token_locale');
    assert.strictEqual(copy.title, 'QMatch');
    assert.strictEqual(copy.body, 'You received a Super Resonance.');

    const en = resolveNotificationCopy('en');
    assert.strictEqual(en.locale, 'en');
    assert.strictEqual(en.locale_source, 'fcm_token_notification_locale');
    assert.strictEqual(en.body, 'You received a Super Resonance.');

    const tr = resolveNotificationCopy('tr');
    assert.strictEqual(tr.locale, 'tr');
    assert.strictEqual(tr.locale_source, 'fcm_token_notification_locale');
    assert.strictEqual(tr.body, 'Bir Süper Rezonans aldın.');

    const unsupported = resolveNotificationCopy('de');
    assert.strictEqual(unsupported.locale, 'en');
    assert.strictEqual(
      unsupported.locale_source,
      'default_en_missing_token_locale',
    );
  });

  it('sends a privacy-safe push to to_uid only', async () => {
    const db = new MemoryFirestore();
    await seedRecipient(db, 'userB');
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    const messaging = fakeMessaging();
    const result = await handleSuperResonanceSignalCreated(
      createdEvent({ data: activeSignal() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, null);
    assert.strictEqual(result.sent, 1);
    assert.strictEqual(messaging.sent.length, 1);
    const msg = messaging.sent[0];
    assert.strictEqual(msg.token, 'tok-b1');
    assert.deepStrictEqual(msg.notification, {
      title: 'QMatch',
      body: 'You received a Super Resonance.',
    });
    assert.deepStrictEqual(msg.data, {
      type: 'super_resonance',
      signal_id: SIGNAL_ID,
      other_uid: 'userA',
    });
    assert.strictEqual(msg.apns.payload.signal_id, SIGNAL_ID);
    assert.strictEqual(msg.apns.payload.other_uid, 'userA');
    assert.strictEqual(msg.data.name, undefined);
    assert.strictEqual(msg.data.photo, undefined);
    assert.strictEqual(msg.data.iq, undefined);
  });

  it('sends Turkish copy to a token registered with tr locale', async () => {
    const db = new MemoryFirestore();
    await seedRecipient(db, 'userB');
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1', 'tr');
    const messaging = fakeMessaging();

    const result = await handleSuperResonanceSignalCreated(
      createdEvent({ data: activeSignal() }),
      deps(db, messaging),
    );

    assert.strictEqual(result.sent, 1);
    assert.deepStrictEqual(messaging.sent[0].notification, {
      title: 'QMatch',
      body: 'Bir Süper Rezonans aldın.',
    });
  });

  it('does not notify the sender from_uid', async () => {
    const db = new MemoryFirestore();
    await seedRecipient(db, 'userB');
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();
    await handleSuperResonanceSignalCreated(
      createdEvent({ data: activeSignal() }),
      deps(db, messaging),
    );
    assert.strictEqual(messaging.sent.length, 1);
    assert.strictEqual(messaging.sent[0].token, 'tok-b1');
  });

  it('dedupes on signalId so a retry does not send twice', async () => {
    const db = new MemoryFirestore();
    await seedRecipient(db, 'userB');
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();
    const first = await handleSuperResonanceSignalCreated(
      createdEvent({ data: activeSignal() }),
      deps(db, messaging),
    );
    const second = await handleSuperResonanceSignalCreated(
      createdEvent({ data: activeSignal() }),
      deps(db, messaging),
    );
    assert.strictEqual(first.sent, 1);
    assert.strictEqual(second.skipped, 'duplicate');
    assert.strictEqual(messaging.sent.length, 1);
    const receipt = await db
      .doc(`push_receipts/super_resonance_${SIGNAL_ID}`)
      .get();
    assert.strictEqual(receipt.exists, true);
    assert.strictEqual(receipt.data().signal_id, SIGNAL_ID);
  });

  it('does not send when either side has blocked the other', async () => {
    const db = new MemoryFirestore();
    await seedRecipient(db, 'userB');
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    await db.doc('users/userB/blocks/userA').set({ blocked_uid: 'userA' });
    const messaging = fakeMessaging();
    const result = await handleSuperResonanceSignalCreated(
      createdEvent({ data: activeSignal() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, 'blocked');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('does not send when recipient is not live-eligible', async () => {
    const db = new MemoryFirestore();
    await db.doc('users/userB').set(
      eligibleUser({ discover_eligible: false, active: false }),
    );
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();
    const result = await handleSuperResonanceSignalCreated(
      createdEvent({ data: activeSignal() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, 'recipient_not_live');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('deletes only the invalid token and still sends the valid one', async () => {
    const db = new MemoryFirestore();
    await seedRecipient(db, 'userB');
    await seedToken(db, 'userB', 'tok-bad', 'hash-bad');
    await seedToken(db, 'userB', 'tok-good', 'hash-good');
    const messaging = fakeMessaging({
      'tok-bad': 'messaging/registration-token-not-registered',
    });
    const result = await handleSuperResonanceSignalCreated(
      createdEvent({ data: activeSignal() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.sent, 1);
    assert.strictEqual(result.cleaned, 1);
    assert.strictEqual(messaging.sent.length, 1);
    assert.strictEqual(messaging.sent[0].token, 'tok-good');
    const bad = await db.doc('users/userB/fcm_tokens/hash-bad').get();
    const good = await db.doc('users/userB/fcm_tokens/hash-good').get();
    assert.strictEqual(bad.exists, false);
    assert.strictEqual(good.exists, true);
  });

  it('data payload has only type, signal_id, other_uid', () => {
    const payload = buildDataPayload({
      signalId: SIGNAL_ID,
      otherUid: 'userA',
    });
    assert.deepStrictEqual(Object.keys(payload).sort(), [
      'other_uid',
      'signal_id',
      'type',
    ]);
    const msg = buildFcmMessage({
      token: 'tok',
      title: 'QMatch',
      body: 'You received a Super Resonance.',
      data: payload,
    });
    assert.strictEqual(msg.apns.payload.type, 'super_resonance');
    assert.strictEqual(msg.apns.payload.signal_id, SIGNAL_ID);
  });

  it('skips when recipient super_resonance pref or push_master is false', async () => {
    async function runWithPrefs(prefs) {
      const db = new MemoryFirestore();
      await seedRecipient(db, 'userB');
      await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
      await db.doc('users/userB/preferences/notification_prefs_v1').set(prefs);
      const messaging = fakeMessaging();
      const result = await handleSuperResonanceSignalCreated(
        createdEvent({ data: activeSignal() }),
        deps(db, messaging),
      );
      return { result, messaging };
    }

    const categoryOff = await runWithPrefs({
      push_master: true,
      messages: true,
      matches: true,
      super_resonance: false,
    });
    assert.strictEqual(
      categoryOff.result.skipped,
      'super_resonance_pref_disabled',
    );
    assert.strictEqual(categoryOff.messaging.sent.length, 0);

    const masterOff = await runWithPrefs({
      push_master: false,
      messages: true,
      matches: true,
      super_resonance: true,
    });
    assert.strictEqual(
      masterOff.result.skipped,
      'super_resonance_pref_disabled',
    );
    assert.strictEqual(masterOff.messaging.sent.length, 0);
  });
});
