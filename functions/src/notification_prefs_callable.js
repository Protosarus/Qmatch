/**
 * Trusted notification preference callables (`notification_prefs_v1`).
 *
 * Auth required. Admin writes users/{uid}/preferences/notification_prefs_v1.
 * Clients cannot write the preference doc. Missing doc reads as all-enabled.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const { requireVerifiedProductUid } = require('./verified_product_auth');
const {
  SCHEMA_VERSION,
  BOOL_KEYS,
  PUBLIC_KEYS,
  prefsPath,
  normalizePrefs,
  publicPrefs,
  parseStrictBoolPayload,
} = require('./notification_prefs');

const GET_CALLABLE_NAME = 'getNotificationPrefs';
const SET_CALLABLE_NAME = 'setNotificationPrefs';

function requireAuthUid(request) {
  return requireVerifiedProductUid(
    request,
    'Authentication required for notification preferences.',
  );
}

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return require('firebase-admin/firestore').getFirestore();
}

function timestamp(deps) {
  if (deps && typeof deps.serverTimestamp === 'function') {
    return deps.serverTimestamp();
  }
  return require('firebase-admin/firestore').FieldValue.serverTimestamp();
}

function requestData(request) {
  return request.data && typeof request.data === 'object' ? request.data : {};
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object }} [deps]
 */
async function handleGetNotificationPrefs(request, deps = {}) {
  const uid = requireAuthUid(request);
  const db = resolveDb(deps);
  const snap = await db.doc(prefsPath(uid)).get();
  const data =
    snap && snap.exists && typeof snap.data === 'function' ? snap.data() : null;
  return publicPrefs(normalizePrefs(data));
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object, serverTimestamp?: Function }} [deps]
 */
async function handleSetNotificationPrefs(request, deps = {}) {
  const uid = requireAuthUid(request);
  const parsed = parseStrictBoolPayload(requestData(request));
  if (!parsed) {
    throw new HttpsError(
      'invalid-argument',
      'push_master, messages, matches, and super_resonance must be booleans.',
    );
  }

  const db = resolveDb(deps);
  const payload = {
    schema_version: SCHEMA_VERSION,
    push_master: parsed.push_master,
    messages: parsed.messages,
    matches: parsed.matches,
    super_resonance: parsed.super_resonance,
    updated_at: timestamp(deps),
  };
  await db.doc(prefsPath(uid)).set(payload, { merge: true });
  return publicPrefs(parsed);
}

module.exports = {
  GET_CALLABLE_NAME,
  SET_CALLABLE_NAME,
  SCHEMA_VERSION,
  BOOL_KEYS,
  PUBLIC_KEYS,
  requireAuthUid,
  handleGetNotificationPrefs,
  handleSetNotificationPrefs,
};
