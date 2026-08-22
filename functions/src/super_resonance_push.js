/**
 * Super Resonance push (`super_resonance_push_v1`).
 *
 * onDocumentCreated super_resonance_signals/{signalId} in europe-west1.
 * Notifies only to_uid. Does not change sendSuperResonance or credits.
 */

'use strict';

const { isValidLiveUser } = require('./like_match_atomicity');
const { STATUS_ACTIVE } = require('./super_resonance_signal');
const {
  isPushCategoryEnabled,
  CATEGORY,
} = require('./notification_prefs');

const TRIGGER_NAME = 'sendSuperResonancePush';
const REGION = 'europe-west1';
const DOCUMENT_PATH = 'super_resonance_signals/{signalId}';
const PUSH_TYPE = 'super_resonance';
const DEFAULT_LOCALE = 'en';
const NOTIFICATION_COPY = Object.freeze({
  en: Object.freeze({
    title: 'QMatch',
    body: 'You received a Super Resonance.',
  }),
  tr: Object.freeze({
    title: 'QMatch',
    body: 'Bir Süper Rezonans aldın.',
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

function recipientIsLive(exists, data) {
  if (!isValidLiveUser(exists, data)) return false;
  if (data && data.account_deletion_requested === true) return false;
  return true;
}

function buildDataPayload({ signalId, otherUid }) {
  return {
    type: PUSH_TYPE,
    signal_id: String(signalId),
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

function receiptPath(signalId) {
  return `push_receipts/super_resonance_${signalId}`;
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

async function claimReceipt(db, signalId, recipientUid, deps) {
  const ref = db.doc(receiptPath(signalId));
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) return false;
    tx.set(ref, {
      type: PUSH_TYPE,
      signal_id: signalId,
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
async function handleSuperResonanceSignalCreated(event, deps = {}) {
  const params = (event && event.params) || {};
  const signalId = nonEmptyString(params.signalId);
  if (!signalId) return skip('malformed_ids');

  const signal = snapshotData(event.data);
  if (!signal) return skip('missing_signal');

  if (nonEmptyString(signal.status) !== STATUS_ACTIVE) {
    return skip('signal_not_active');
  }

  const fromUid = nonEmptyString(signal.from_uid);
  const toUid = nonEmptyString(signal.to_uid);
  if (!fromUid || !toUid || fromUid === toUid) {
    return skip('malformed_participants');
  }
  if (signalId !== `${fromUid}_${toUid}`) {
    return skip('signal_id_mismatch');
  }

  const db = resolveDb(deps);
  const recipientUid = toUid;
  const senderUid = fromUid;

  const [recipientUserSnap, recipientBlockedSender, senderBlockedRecipient] =
    await Promise.all([
      db.doc(`users/${recipientUid}`).get(),
      db.doc(blockPath(recipientUid, senderUid)).get(),
      db.doc(blockPath(senderUid, recipientUid)).get(),
    ]);

  if (
    !recipientIsLive(
      !!(recipientUserSnap && recipientUserSnap.exists),
      snapshotData(recipientUserSnap),
    )
  ) {
    return skip('recipient_not_live');
  }

  if (recipientBlockedSender && recipientBlockedSender.exists) {
    return skip('blocked');
  }
  if (senderBlockedRecipient && senderBlockedRecipient.exists) {
    return skip('blocked');
  }

  if (
    !(await isPushCategoryEnabled(
      db,
      recipientUid,
      CATEGORY.SUPER_RESONANCE,
    ))
  ) {
    return skip('super_resonance_pref_disabled');
  }

  const tokens = await listRecipientTokens(db, recipientUid);
  if (!tokens.length) return skip('no_tokens');

  const claimed = await claimReceipt(db, signalId, recipientUid, deps);
  if (!claimed) return skip('duplicate');

  const copy = resolveNotificationCopy();
  const data = buildDataPayload({
    signalId,
    otherUid: senderUid,
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
  isInvalidTokenError,
  recipientIsLive,
  handleSuperResonanceSignalCreated,
};
