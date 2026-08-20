/**
 * New-message push (`new_message_push_v1`).
 *
 * onDocumentCreated threads/{threadId}/messages/{messageId} in europe-west1.
 * Sends a privacy-safe FCM alert to the other participant only.
 * Does not change message storage, unread_counts, matching, or blocks.
 */

'use strict';

const TRIGGER_NAME = 'sendNewMessagePush';
const REGION = 'europe-west1';
const DOCUMENT_PATH = 'threads/{threadId}/messages/{messageId}';
const PUSH_TYPE = 'message';
const SYSTEM_MATCH_MESSAGE_ID = 'system_match_v1';
const DEFAULT_LOCALE = 'en';
const NOTIFICATION_COPY = Object.freeze({
  en: Object.freeze({
    title: 'QMatch',
    body: 'You have a new message.',
  }),
  tr: Object.freeze({
    title: 'QMatch',
    body: 'Yeni bir mesajın var.',
  }),
});
const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return require('firebase-admin/firestore').getFirestore();
}

function resolveMessaging(deps) {
  if (deps && deps.messaging) return deps.messaging;
  return require('firebase-admin/messaging').getMessaging();
}

function timestamp(deps) {
  if (deps && typeof deps.serverTimestamp === 'function') {
    return deps.serverTimestamp();
  }
  return require('firebase-admin/firestore').FieldValue.serverTimestamp();
}

function snapshotData(snap) {
  if (!snap || typeof snap.data !== 'function') return null;
  if (snap.exists === false) return null;
  const data = snap.data();
  return data && typeof data === 'object' ? data : null;
}

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim() ? value.trim() : '';
}

/**
 * No trusted persisted notification locale exists on users/{uid}.
 * Assessment bank locale and deletion-request locale are not used.
 * Default lock-screen copy is English until a real preference is stored.
 */
function resolveNotificationCopy() {
  const copy = NOTIFICATION_COPY[DEFAULT_LOCALE];
  return {
    locale: DEFAULT_LOCALE,
    title: copy.title,
    body: copy.body,
    locale_source: 'default_en_no_persisted_user_locale',
  };
}

function isMessagePushEnabled() {
  // Persisted notification settings are not implemented. v1 default: on.
  return true;
}

function buildDataPayload({ threadId, senderId, messageId }) {
  return {
    type: PUSH_TYPE,
    thread_id: String(threadId),
    other_uid: String(senderId),
    message_id: String(messageId),
  };
}

function buildFcmMessage({ token, title, body, data }) {
  return {
    token,
    notification: {
      title,
      body,
    },
    data,
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };
}

function receiptPath(threadId, messageId) {
  return `push_receipts/${threadId}_${messageId}`;
}

function tokenCollectionPath(uid) {
  return `users/${uid}/fcm_tokens`;
}

function blockPath(fromUid, toUid) {
  return `users/${fromUid}/blocks/${toUid}`;
}

function errorCode(err) {
  if (!err) return '';
  if (typeof err.code === 'string') return err.code;
  if (err.errorInfo && typeof err.errorInfo.code === 'string') {
    return err.errorInfo.code;
  }
  return '';
}

function isInvalidTokenError(err) {
  return INVALID_TOKEN_CODES.has(errorCode(err));
}

function parseParticipants(raw) {
  if (!Array.isArray(raw) || raw.length !== 2) return null;
  const a = nonEmptyString(raw[0]);
  const b = nonEmptyString(raw[1]);
  if (!a || !b || a === b) return null;
  return [a, b];
}

function otherParticipant(participants, senderId) {
  if (!participants) return '';
  const others = participants.filter((uid) => uid !== senderId);
  if (others.length !== 1) return '';
  return others[0];
}

async function claimReceipt(db, threadId, messageId, recipientUid, deps) {
  const ref = db.doc(receiptPath(threadId, messageId));
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) return false;
    tx.set(ref, {
      type: PUSH_TYPE,
      thread_id: threadId,
      message_id: messageId,
      recipient_uid: recipientUid,
      created_at: timestamp(deps),
    });
    return true;
  });
}

async function listRecipientTokens(db, uid) {
  const snap = await db.collection(tokenCollectionPath(uid)).get();
  const docs = (snap && snap.docs) || [];
  const out = [];
  for (const doc of docs) {
    const data = snapshotData(doc) || {};
    const token = nonEmptyString(data.token);
    if (!token) continue;
    const path =
      (doc.ref && doc.ref.path) || `${tokenCollectionPath(uid)}/${doc.id}`;
    out.push({ path, token });
  }
  return out;
}

async function sendToTokens({ messaging, db, tokens, title, body, data }) {
  let sent = 0;
  let cleaned = 0;
  for (const row of tokens) {
    try {
      await messaging.send(
        buildFcmMessage({
          token: row.token,
          title,
          body,
          data,
        }),
      );
      sent += 1;
    } catch (err) {
      if (isInvalidTokenError(err)) {
        try {
          await db.doc(row.path).delete();
          cleaned += 1;
        } catch (_) {
          // Cleanup failure must not block remaining tokens.
        }
      }
    }
  }
  return { sent, cleaned };
}

function skip(reason) {
  return { ok: true, sent: 0, skipped: reason };
}

/**
 * @param {object} event Firestore onDocumentCreated event
 * @param {{ db?: object, messaging?: object, serverTimestamp?: Function }} [deps]
 */
async function handleThreadMessageCreated(event, deps = {}) {
  const params = (event && event.params) || {};
  const threadId = nonEmptyString(params.threadId);
  const messageId = nonEmptyString(params.messageId);
  if (!threadId || !messageId) return skip('malformed_ids');
  if (messageId === SYSTEM_MATCH_MESSAGE_ID) return skip('system_match');

  const message = snapshotData(event.data);
  if (!message) return skip('missing_message');

  const type = nonEmptyString(message.type);
  if (type !== 'text') return skip('not_text');

  const senderId = nonEmptyString(message.sender_id);
  if (!senderId || senderId === 'system') return skip('malformed_sender');

  const db = resolveDb(deps);
  const threadSnap = await db.doc(`threads/${threadId}`).get();
  const thread = snapshotData(threadSnap);
  if (!thread) return skip('missing_thread');
  if (thread.status !== 'active') return skip('thread_not_active');

  const participants = parseParticipants(thread.participants);
  if (!participants) return skip('malformed_participants');
  if (!participants.includes(senderId)) return skip('sender_not_participant');

  const recipientUid = otherParticipant(participants, senderId);
  if (!recipientUid || recipientUid === senderId) {
    return skip('malformed_participants');
  }

  const [recipientBlockedSender, senderBlockedRecipient] = await Promise.all([
    db.doc(blockPath(recipientUid, senderId)).get(),
    db.doc(blockPath(senderId, recipientUid)).get(),
  ]);
  if (recipientBlockedSender && recipientBlockedSender.exists) {
    return skip('blocked');
  }
  if (senderBlockedRecipient && senderBlockedRecipient.exists) {
    return skip('blocked');
  }

  if (!isMessagePushEnabled()) return skip('messages_pref_disabled');

  const tokens = await listRecipientTokens(db, recipientUid);
  if (!tokens.length) return skip('no_tokens');

  const claimed = await claimReceipt(
    db,
    threadId,
    messageId,
    recipientUid,
    deps,
  );
  if (!claimed) return skip('duplicate');

  const copy = resolveNotificationCopy();
  const data = buildDataPayload({ threadId, senderId, messageId });
  const messaging = resolveMessaging(deps);
  const result = await sendToTokens({
    messaging,
    db,
    tokens,
    title: copy.title,
    body: copy.body,
    data,
  });
  return {
    ok: true,
    sent: result.sent,
    cleaned: result.cleaned,
    skipped: null,
    locale: copy.locale,
    locale_source: copy.locale_source,
  };
}

module.exports = {
  TRIGGER_NAME,
  REGION,
  DOCUMENT_PATH,
  PUSH_TYPE,
  SYSTEM_MATCH_MESSAGE_ID,
  DEFAULT_LOCALE,
  NOTIFICATION_COPY,
  resolveNotificationCopy,
  buildDataPayload,
  buildFcmMessage,
  isInvalidTokenError,
  isMessagePushEnabled,
  handleThreadMessageCreated,
};
