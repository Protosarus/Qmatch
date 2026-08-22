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
  handleThreadMessageCreated,
} = require('../src/new_message_push');

const THREAD_ID = 'userA_userB';
const MESSAGE_ID = 'msg-1';
const SECRET_TEXT = 'secret-hello-do-not-push';

function createdEvent({
  threadId = THREAD_ID,
  messageId = MESSAGE_ID,
  data,
} = {}) {
  return {
    params: { threadId, messageId },
    data: {
      id: messageId,
      exists: true,
      ref: { path: `threads/${threadId}/messages/${messageId}` },
      data: () => data,
    },
  };
}

function textMessage(overrides = {}) {
  return {
    thread_id: THREAD_ID,
    sender_id: 'userA',
    type: 'text',
    text: SECRET_TEXT,
    created_at: 'TS',
    client_created_at: 1,
    read_by: {},
    moderation: null,
    ...overrides,
  };
}

async function seedActiveThread(db, overrides = {}) {
  await db.doc(`threads/${THREAD_ID}`).set({
    thread_id: THREAD_ID,
    match_id: THREAD_ID,
    participants: ['userA', 'userB'],
    status: 'active',
    unread_counts: { userA: 0, userB: 1 },
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

describe('new message push', () => {
  it('uses europe-west1 document path constants', () => {
    assert.strictEqual(TRIGGER_NAME, 'sendNewMessagePush');
    assert.strictEqual(REGION, 'europe-west1');
    assert.strictEqual(
      DOCUMENT_PATH,
      'threads/{threadId}/messages/{messageId}',
    );
  });

  it('defaults to English because no persisted user locale exists', () => {
    const copy = resolveNotificationCopy();
    assert.strictEqual(copy.locale, 'en');
    assert.strictEqual(copy.locale_source, 'default_en_no_persisted_user_locale');
    assert.strictEqual(copy.title, 'QMatch');
    assert.strictEqual(copy.body, 'You have a new message.');
    assert.strictEqual(NOTIFICATION_COPY.tr.body, 'Yeni bir mesajın var.');
  });

  it('sends a privacy-safe push to the recipient', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    const messaging = fakeMessaging();
    const result = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, null);
    assert.strictEqual(result.sent, 1);
    assert.strictEqual(messaging.sent.length, 1);
    const msg = messaging.sent[0];
    assert.strictEqual(msg.token, 'tok-b1');
    assert.deepStrictEqual(msg.notification, {
      title: 'QMatch',
      body: 'You have a new message.',
    });
    assert.deepStrictEqual(msg.data, {
      type: 'message',
      thread_id: THREAD_ID,
      other_uid: 'userA',
      message_id: MESSAGE_ID,
      chat_message_id: MESSAGE_ID,
    });
    assert.strictEqual(msg.apns.payload.aps.sound, 'default');
    assert.strictEqual(msg.apns.payload.type, 'message');
    assert.strictEqual(msg.apns.payload.thread_id, THREAD_ID);
    assert.strictEqual(msg.apns.payload.other_uid, 'userA');
    assert.strictEqual(msg.apns.payload.message_id, MESSAGE_ID);
    assert.strictEqual(msg.apns.payload.chat_message_id, MESSAGE_ID);
    assert.strictEqual(msg.apns.payload.aps.type, undefined);
    assert.strictEqual(JSON.stringify(msg).includes(SECRET_TEXT), false);
    assert.strictEqual(msg.data.text, undefined);
    const unread = (await db.doc(`threads/${THREAD_ID}`).get()).data()
      .unread_counts;
    assert.deepStrictEqual(unread, { userA: 0, userB: 1 });
  });

  it('does not send for system_match_v1 or system type', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();
    const systemId = await handleThreadMessageCreated(
      createdEvent({
        messageId: 'system_match_v1',
        data: textMessage({
          sender_id: 'system',
          type: 'system',
          text: 'You matched!',
        }),
      }),
      deps(db, messaging),
    );
    const systemType = await handleThreadMessageCreated(
      createdEvent({
        messageId: 'sys-2',
        data: textMessage({ type: 'system', sender_id: 'system' }),
      }),
      deps(db, messaging),
    );
    assert.strictEqual(systemId.skipped, 'system_match');
    assert.strictEqual(systemType.skipped, 'not_text');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('does not send for closed threads', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db, {
      status: 'closed',
      closed_reason: 'unmatched',
    });
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();
    const result = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, 'thread_not_active');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('does not send when either side has blocked the other', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    await db.doc('users/userB/blocks/userA').set({ blocked_uid: 'userA' });
    const messaging = fakeMessaging();
    const blockedRecipient = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db, messaging),
    );
    assert.strictEqual(blockedRecipient.skipped, 'blocked');

    const db2 = new MemoryFirestore();
    await seedActiveThread(db2);
    await seedToken(db2, 'userB', 'tok-b1', 'hash-b1');
    await db2.doc('users/userA/blocks/userB').set({ blocked_uid: 'userB' });
    const blockedSender = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db2, messaging),
    );
    assert.strictEqual(blockedSender.skipped, 'blocked');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('does not send for malformed sender or participants', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();
    const noSender = await handleThreadMessageCreated(
      createdEvent({ data: textMessage({ sender_id: '' }) }),
      deps(db, messaging),
    );
    assert.strictEqual(noSender.skipped, 'malformed_sender');

    await seedActiveThread(db, { participants: ['userA'] });
    const oneParty = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db, messaging),
    );
    assert.strictEqual(oneParty.skipped, 'malformed_participants');

    await seedActiveThread(db, { participants: ['userA', 'userB'] });
    const outsider = await handleThreadMessageCreated(
      createdEvent({ data: textMessage({ sender_id: 'userC' }) }),
      deps(db, messaging),
    );
    assert.strictEqual(outsider.skipped, 'sender_not_participant');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('never sends to the sender token collection', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userA', 'tok-a1', 'hash-a1');
    const messaging = fakeMessaging();
    const result = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, 'no_tokens');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('fans out to every recipient device token', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    await seedToken(db, 'userB', 'tok-b2', 'hash-b2');
    const messaging = fakeMessaging();
    const result = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.sent, 2);
    assert.deepStrictEqual(
      messaging.sent.map((m) => m.token).sort(),
      ['tok-b1', 'tok-b2'],
    );
  });

  it('deletes only the invalid token and still sends the valid one', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userB', 'tok-bad', 'hash-bad');
    await seedToken(db, 'userB', 'tok-good', 'hash-good');
    const messaging = fakeMessaging({
      'tok-bad': 'messaging/registration-token-not-registered',
    });
    const result = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
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

  it('data payload has type, thread_id, other_uid, message_id, chat_message_id', async () => {
    const payload = buildDataPayload({
      threadId: THREAD_ID,
      senderId: 'userA',
      messageId: MESSAGE_ID,
    });
    assert.deepStrictEqual(Object.keys(payload).sort(), [
      'chat_message_id',
      'message_id',
      'other_uid',
      'thread_id',
      'type',
    ]);
    assert.strictEqual(payload.type, 'message');
    assert.strictEqual(payload.message_id, payload.chat_message_id);
  });

  it('buildFcmMessage mirrors routing keys onto apns.payload outside aps', () => {
    const { buildFcmMessage } = require('../src/new_message_push');
    const data = buildDataPayload({
      threadId: THREAD_ID,
      senderId: 'userA',
      messageId: MESSAGE_ID,
    });
    const msg = buildFcmMessage({
      token: 'tok',
      title: 'QMatch',
      body: 'You have a new message.',
      data,
    });
    assert.deepStrictEqual(msg.data, data);
    assert.strictEqual(msg.notification.body, 'You have a new message.');
    assert.strictEqual(msg.apns.payload.aps.sound, 'default');
    assert.strictEqual(msg.apns.payload.thread_id, THREAD_ID);
    assert.strictEqual(msg.apns.payload.other_uid, 'userA');
    assert.strictEqual(msg.apns.payload.message_id, MESSAGE_ID);
    assert.strictEqual(msg.apns.payload.chat_message_id, MESSAGE_ID);
  });

  it('dedupes on messageId so a retry does not send twice', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();
    const first = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db, messaging),
    );
    const second = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db, messaging),
    );
    assert.strictEqual(first.sent, 1);
    assert.strictEqual(second.skipped, 'duplicate');
    assert.strictEqual(messaging.sent.length, 1);
    const receipt = await db.doc(`push_receipts/${THREAD_ID}_${MESSAGE_ID}`).get();
    assert.strictEqual(receipt.exists, true);
    assert.strictEqual(receipt.data().message_id, MESSAGE_ID);
    assert.strictEqual(receipt.data().text, undefined);
  });

  it('skips when recipient messages pref or push_master is false', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();

    await db.doc('users/userB/preferences/notification_prefs_v1').set({
      push_master: true,
      messages: false,
      matches: true,
      super_resonance: true,
    });
    const disabled = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db, messaging),
    );
    assert.strictEqual(disabled.skipped, 'messages_pref_disabled');
    assert.strictEqual(messaging.sent.length, 0);

    await db.doc('users/userB/preferences/notification_prefs_v1').set({
      push_master: false,
      messages: true,
      matches: true,
      super_resonance: true,
    });
    const masterOff = await handleThreadMessageCreated(
      createdEvent({ messageId: 'msg-2', data: textMessage() }),
      deps(db, messaging),
    );
    assert.strictEqual(masterOff.skipped, 'messages_pref_disabled');
    assert.strictEqual(messaging.sent.length, 0);
  });

  it('still sends when prefs doc is missing (default on)', async () => {
    const db = new MemoryFirestore();
    await seedActiveThread(db);
    await seedToken(db, 'userB', 'tok-b1', 'hash-b1');
    const messaging = fakeMessaging();
    const result = await handleThreadMessageCreated(
      createdEvent({ data: textMessage() }),
      deps(db, messaging),
    );
    assert.strictEqual(result.skipped, null);
    assert.strictEqual(result.sent, 1);
  });
});
