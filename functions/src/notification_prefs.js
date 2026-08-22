/**
 * Notification preferences (`notification_prefs_v1`).
 *
 * Admin-owned preference doc at users/{uid}/preferences/notification_prefs_v1.
 * Missing or malformed fields default to enabled (current push behavior).
 */

'use strict';

const SCHEMA_VERSION = 'notification_prefs_v1';
const PREF_DOC_ID = 'notification_prefs_v1';

const BOOL_KEYS = Object.freeze([
  'push_master',
  'messages',
  'matches',
  'super_resonance',
]);

const CATEGORY = Object.freeze({
  MESSAGES: 'messages',
  MATCHES: 'matches',
  SUPER_RESONANCE: 'super_resonance',
});

const PUBLIC_KEYS = Object.freeze([...BOOL_KEYS]);

function prefsPath(uid) {
  return `users/${uid}/preferences/${PREF_DOC_ID}`;
}

/**
 * Missing / non-boolean → true (fail-open, same as pre-prefs push default).
 * Only explicit `false` disables.
 * @param {unknown} value
 * @returns {boolean}
 */
function coerceEnabled(value) {
  return value !== false;
}

/**
 * @param {Record<string, unknown>|null|undefined} data
 * @returns {{
 *   push_master: boolean,
 *   messages: boolean,
 *   matches: boolean,
 *   super_resonance: boolean,
 * }}
 */
function normalizePrefs(data) {
  const src = data && typeof data === 'object' ? data : null;
  return {
    push_master: coerceEnabled(src && src.push_master),
    messages: coerceEnabled(src && src.messages),
    matches: coerceEnabled(src && src.matches),
    super_resonance: coerceEnabled(src && src.super_resonance),
  };
}

function defaultPrefs() {
  return normalizePrefs(null);
}

/**
 * @param {Record<string, unknown>} prefs
 * @param {string} category one of messages|matches|super_resonance
 * @returns {boolean}
 */
function isCategoryEnabled(prefs, category) {
  const normalized = normalizePrefs(prefs);
  if (normalized.push_master !== true) return false;
  if (category === CATEGORY.MESSAGES) return normalized.messages === true;
  if (category === CATEGORY.MATCHES) return normalized.matches === true;
  if (category === CATEGORY.SUPER_RESONANCE) {
    return normalized.super_resonance === true;
  }
  return false;
}

/**
 * Admin-read recipient prefs once. Missing doc → all enabled.
 * @param {{ doc: Function }} db
 * @param {string} recipientUid
 * @param {string} category
 * @returns {Promise<boolean>}
 */
async function isPushCategoryEnabled(db, recipientUid, category) {
  if (!recipientUid || typeof recipientUid !== 'string') return true;
  try {
    const snap = await db.doc(prefsPath(recipientUid)).get();
    const data = snap && snap.exists && typeof snap.data === 'function'
      ? snap.data()
      : null;
    return isCategoryEnabled(data, category);
  } catch (_) {
    // Fail-open: preserve pre-prefs send behavior on read errors.
    return true;
  }
}

/**
 * @param {unknown} raw
 * @returns {{
 *   push_master: boolean,
 *   messages: boolean,
 *   matches: boolean,
 *   super_resonance: boolean,
 * }|null}
 */
function parseStrictBoolPayload(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const out = {};
  for (const key of BOOL_KEYS) {
    if (typeof raw[key] !== 'boolean') return null;
    out[key] = raw[key];
  }
  return out;
}

function publicPrefs(prefs) {
  const normalized = normalizePrefs(prefs);
  const out = {};
  for (const key of PUBLIC_KEYS) {
    out[key] = normalized[key];
  }
  return out;
}

module.exports = {
  SCHEMA_VERSION,
  PREF_DOC_ID,
  BOOL_KEYS,
  CATEGORY,
  PUBLIC_KEYS,
  prefsPath,
  coerceEnabled,
  normalizePrefs,
  defaultPrefs,
  isCategoryEnabled,
  isPushCategoryEnabled,
  parseStrictBoolPayload,
  publicPrefs,
};
