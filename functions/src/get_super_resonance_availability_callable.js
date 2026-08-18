/**
 * Trusted Super Resonance availability (`getSuperResonanceAvailability`).
 *
 * Read-only. Uses trusted server time for UTC-day remaining.
 * Never grants Resonance. Never spends. Never trusts a client clock.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const {
  normalizeSnapshot,
  defaultFreeSnapshot,
} = require('./entitlement_access');
const { resolveDailyAllowance } = require('./super_resonance_daily_allowance');

const CALLABLE_NAME = 'getSuperResonanceAvailability';
const PUBLIC_RESULT_KEYS = Object.freeze([
  'daily_remaining',
  'daily_limit',
  'purchased_balance',
  'total_available',
  'super_resonance_balance',
]);

function requireAuthUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Authentication required for Super Resonance availability.',
    );
  }
  return uid;
}

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return require('firebase-admin/firestore').getFirestore();
}

function processedAt(deps) {
  if (deps && typeof deps.now === 'function') return deps.now();
  return new Date();
}

function publicAvailabilityResult(daily) {
  const purchased =
    daily && typeof daily.purchased === 'number' && Number.isFinite(daily.purchased)
      ? Math.max(0, daily.purchased)
      : 0;
  const remaining =
    daily && typeof daily.remaining === 'number' && Number.isFinite(daily.remaining)
      ? Math.max(0, daily.remaining)
      : 0;
  const limit =
    daily && typeof daily.limit === 'number' && Number.isFinite(daily.limit)
      ? Math.max(0, daily.limit)
      : 0;
  return {
    daily_remaining: remaining,
    daily_limit: limit,
    purchased_balance: purchased,
    total_available: remaining + purchased,
    super_resonance_balance: purchased,
  };
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object, now?: Function }} [deps]
 */
async function handleGetSuperResonanceAvailability(request, deps = {}) {
  const uid = requireAuthUid(request);
  const db = resolveDb(deps);
  const at = processedAt(deps);
  const snap = await db.doc(`entitlements/${uid}`).get();
  const snapshot = snap && snap.exists
    ? normalizeSnapshot(uid, snap.data())
    : defaultFreeSnapshot(uid);
  return publicAvailabilityResult(resolveDailyAllowance(snapshot, at));
}

module.exports = {
  CALLABLE_NAME,
  PUBLIC_RESULT_KEYS,
  handleGetSuperResonanceAvailability,
  publicAvailabilityResult,
};
