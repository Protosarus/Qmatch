/**
 * New-match push (`new_match_push_v1`).
 *
 * onDocumentCreated matches/{matchId} in europe-west1.
 * Sends a privacy-safe FCM alert to the non-creator participant only.
 * Actor identity comes from match.match_created_by_uid (written at create).
 * Does not change matching semantics, chat storage, or blocks.
 */

'use strict';

const TRIGGER_NAME = 'sendNewMatchPush';
const REGION = 'europe-west1';
const DOCUMENT_PATH = 'matches/{matchId}';
const PUSH_TYPE = 'match';
const DEFAULT_LOCALE = 'en';
const NOTIFICATION_COPY = Object.freeze({
  en: Object.freeze({
    title: 'QMatch',
    body: 'You have a new match.',
  }),
  tr: Object.freeze({
    title: 'QMatch',
    body: 'Yeni bir eşleşmen var.',
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

function isMatchPushEnabled() {
  // Persisted notification settings are not implemented. v1 default: on.
  return true;
}

function buildDataPayload({ matchId, threadId, otherUid }) {
  return {
    type: PUSH_TYPE,
    match_id: String(matchId),
    thread_id: String(threadId),
    other_uid: String(otherUid),
  };
}

function buildFcmMessage({ token, title, body, data }) {
  const routing = {};
  Object.keys(data || {}).forEach((key) => {
    routing[key] = String(data[key]);
  });
  return {
    token,
    notification: {
      title,
      body,
    },
    data: routing,
    apns: {
      headers: {
        'apns-priority': '10',
      },
      payload: {
        aps: {
          sound: 'default',
        },
        ...routing,
      },
    },
  };
}

function receiptPath(matchId) {
  return `push_receipts/match_${matchId}`;
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

function parseUsers(raw) {
  if (!Array.isArray(raw) || raw.length !== 2) return null;
  const a = nonEmptyString(raw[0]);
  const b = nonEmptyString(raw[1]);
  if (!a || !b || a === b) return null;
  return [a, b];
}

/**
 * Actor = match_created_by_uid when it is exactly one of the two participants.
 * Missing/invalid → empty (caller fail-closes). No swipe-timestamp inference.
 */
function resolveMatchActor(match, users) {
  const actorUid = nonEmptyString(match && match.match_created_by_uid);
  if (!actorUid || !users || !users.includes(actorUid)) return '';
  return actorUid;
}

async function claimReceipt(db, matchId, recipientUid, deps) {
  const ref = db.doc(receiptPath(matchId));
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) return false;
    tx.set(ref, {
      type: PUSH_TYPE,
      match_id: matchId,
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
async function handleMatchCreated(event, deps = {}) {
  const params = (event && event.params) || {};
  const matchId = nonEmptyString(params.matchId);
  if (!matchId) return skip('malformed_ids');

  const match = snapshotData(event.data);
  if (!match) return skip('missing_match');

  if (nonEmptyString(match.state) !== 'active') return skip('match_not_active');
  if (nonEmptyString(match.created_by) !== 'system') {
    return skip('created_by_not_system');
  }

  const users = parseUsers(match.users);
  if (!users) return skip('malformed_participants');

  const threadId =
    nonEmptyString(match.thread_id) || nonEmptyString(match.match_id) || matchId;
  if (!threadId) return skip('malformed_thread_id');

  const db = resolveDb(deps);
  const threadSnap = await db.doc(`threads/${threadId}`).get();
  const thread = snapshotData(threadSnap);
  if (!thread) return skip('missing_thread');
  if (thread.status !== 'active') return skip('thread_not_active');

  const participants = parseUsers(thread.participants);
  if (!participants) return skip('malformed_participants');
  if (
    !(
      participants.includes(users[0]) &&
      participants.includes(users[1]) &&
      participants.length === 2
    )
  ) {
    return skip('thread_users_mismatch');
  }

  const actorUid = resolveMatchActor(match, users);
  if (!actorUid) return skip('actor_unknown');

  const recipientUid = users[0] === actorUid ? users[1] : users[0];
  if (!recipientUid || recipientUid === actorUid) {
    return skip('malformed_participants');
  }

  const [recipientBlockedActor, actorBlockedRecipient] = await Promise.all([
    db.doc(blockPath(recipientUid, actorUid)).get(),
    db.doc(blockPath(actorUid, recipientUid)).get(),
  ]);
  if (recipientBlockedActor && recipientBlockedActor.exists) {
    return skip('blocked');
  }
  if (actorBlockedRecipient && actorBlockedRecipient.exists) {
    return skip('blocked');
  }

  if (!isMatchPushEnabled()) return skip('match_pref_disabled');

  const tokens = await listRecipientTokens(db, recipientUid);
  if (!tokens.length) return skip('no_tokens');

  const claimed = await claimReceipt(db, matchId, recipientUid, deps);
  if (!claimed) return skip('duplicate');

  const copy = resolveNotificationCopy();
  const data = buildDataPayload({
    matchId,
    threadId,
    otherUid: actorUid,
  });
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
  DEFAULT_LOCALE,
  NOTIFICATION_COPY,
  resolveNotificationCopy,
  buildDataPayload,
  buildFcmMessage,
  resolveMatchActor,
  isInvalidTokenError,
  isMatchPushEnabled,
  handleMatchCreated,
};
