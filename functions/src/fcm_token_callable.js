/**
 * Trusted FCM device-token registration (`fcm_token_registration_v1`).
 *
 * Auth required. Writes only users/{auth.uid}/fcm_tokens/{sha256(token)}.
 * Clients cannot register a token for another uid. Does not send pushes.
 */

'use strict';

const crypto = require('crypto');
const { HttpsError } = require('firebase-functions/v2/https');

const REGISTER_CALLABLE_NAME = 'registerFcmToken';
const UNREGISTER_CALLABLE_NAME = 'unregisterFcmToken';
const PLATFORMS = new Set(['ios', 'android']);
const APNS_ENVS = new Set(['sandbox', 'production']);
const NOTIFICATION_LOCALES = new Set(['en', 'tr']);
const MAX_TOKEN_LENGTH = 4096;
const MAX_APP_ID_LENGTH = 256;

function requireAuthUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Authentication required to register a device token.',
    );
  }
  return uid;
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

function tokenHash(token) {
  return crypto.createHash('sha256').update(token, 'utf8').digest('hex');
}

function tokenPath(uid, hash) {
  return `users/${uid}/fcm_tokens/${hash}`;
}

function normalizeToken(raw) {
  if (typeof raw !== 'string') {
    throw new HttpsError('invalid-argument', 'A non-empty token is required.');
  }
  const token = raw.trim();
  if (!token || token.length > MAX_TOKEN_LENGTH) {
    throw new HttpsError('invalid-argument', 'A non-empty token is required.');
  }
  return token;
}

function normalizePlatform(raw) {
  const platform = typeof raw === 'string' ? raw.trim().toLowerCase() : '';
  if (!PLATFORMS.has(platform)) {
    throw new HttpsError(
      'invalid-argument',
      'platform must be ios or android.',
    );
  }
  return platform;
}

function normalizeNotificationLocale(raw) {
  if (raw == null || raw === '') return 'en';
  if (typeof raw !== 'string') {
    throw new HttpsError(
      'invalid-argument',
      'notification_locale must be en or tr.',
    );
  }
  const locale = raw.trim().toLowerCase();
  if (!NOTIFICATION_LOCALES.has(locale)) {
    throw new HttpsError(
      'invalid-argument',
      'notification_locale must be en or tr.',
    );
  }
  return locale;
}

function normalizeAppId(raw) {
  if (typeof raw !== 'string') {
    throw new HttpsError('invalid-argument', 'app_id is required.');
  }
  const appId = raw.trim();
  if (!appId || appId.length > MAX_APP_ID_LENGTH) {
    throw new HttpsError('invalid-argument', 'app_id is required.');
  }
  return appId;
}

function normalizeApnsEnv(platform, raw) {
  if (platform !== 'ios') return null;
  const env = typeof raw === 'string' ? raw.trim().toLowerCase() : '';
  if (!APNS_ENVS.has(env)) {
    throw new HttpsError(
      'invalid-argument',
      'apns_env must be sandbox or production on iOS.',
    );
  }
  return env;
}

function resolveTokenId(data) {
  if (typeof data.token_id === 'string' && data.token_id.trim()) {
    const id = data.token_id.trim().toLowerCase();
    if (!/^[a-f0-9]{64}$/.test(id)) {
      throw new HttpsError('invalid-argument', 'token_id is invalid.');
    }
    return id;
  }
  return tokenHash(normalizeToken(data.token));
}

async function handleRegisterFcmToken(request, deps = {}) {
  const uid = requireAuthUid(request);
  const data = requestData(request);
  const token = normalizeToken(data.token);
  const platform = normalizePlatform(data.platform);
  const appId = normalizeAppId(data.app_id);
  const notificationLocale = normalizeNotificationLocale(
    data.notification_locale,
  );
  const apnsEnv = normalizeApnsEnv(platform, data.apns_env);
  const id = tokenHash(token);
  const db = resolveDb(deps);
  const ts = timestamp(deps);
  const ref = db.doc(tokenPath(uid, id));
  const snap = await ref.get();
  const payload = {
    token,
    platform,
    app_id: appId,
    notification_locale: notificationLocale,
    updated_at: ts,
    last_seen_at: ts,
  };
  if (apnsEnv) payload.apns_env = apnsEnv;
  if (!snap.exists) {
    payload.created_at = ts;
    await ref.set(payload);
  } else {
    await ref.set(payload, { merge: true });
  }
  return { ok: true };
}

async function handleUnregisterFcmToken(request, deps = {}) {
  const uid = requireAuthUid(request);
  const data = requestData(request);
  const id = resolveTokenId(data);
  const db = resolveDb(deps);
  await db.doc(tokenPath(uid, id)).delete();
  return { ok: true };
}

module.exports = {
  REGISTER_CALLABLE_NAME,
  UNREGISTER_CALLABLE_NAME,
  tokenHash,
  tokenPath,
  normalizeNotificationLocale,
  handleRegisterFcmToken,
  handleUnregisterFcmToken,
};
