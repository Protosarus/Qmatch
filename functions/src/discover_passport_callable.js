/**
 * Trusted Discover Passport preference (`discover_passport_v1`).
 *
 * Owner-only preference doc. Resonance gating is Admin-derived from
 * entitlements/{uid}. Clients cannot write the preference. Super Resonance
 * credits are unrelated. Does not change L2 ranking math.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const { requireVerifiedProductUid } = require('./verified_product_auth');
const {
  normalizeSnapshot,
  defaultFreeSnapshot,
} = require('./entitlement_access');
const {
  normalizeCountryCode,
  normalizeCitySlug,
} = require('./home_geography');

const SCHEMA_VERSION = 'discover_passport_v1';
const GET_CALLABLE_NAME = 'getDiscoverPassport';
const SET_CALLABLE_NAME = 'setDiscoverPassport';
const DISABLE_CALLABLE_NAME = 'disableDiscoverPassport';
const PUBLIC_GET_KEYS = Object.freeze([
  'resonance_access',
  'passport_enabled',
  'passport_country',
  'passport_city',
]);

function requireAuthUid(request) {
  return requireVerifiedProductUid(
    request,
    'Authentication required for Discover Passport.',
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

function passportPath(uid) {
  return `users/${uid}/preferences/discover_passport_v1`;
}

function requestData(request) {
  return request.data && typeof request.data === 'object' ? request.data : {};
}

async function readEntitlement(db, uid) {
  const snap = await db.doc(`entitlements/${uid}`).get();
  return snap && snap.exists
    ? normalizeSnapshot(uid, snap.data())
    : defaultFreeSnapshot(uid);
}

function storedCountryCity(data) {
  const country = normalizeCountryCode(data && data.passport_country);
  const city = normalizeCitySlug(data && data.passport_city);
  if (!country || !city) {
    return { passport_country: null, passport_city: null };
  }
  return { passport_country: country, passport_city: city };
}

function publicGetResult(resonanceAccess, stored) {
  const saved = storedCountryCity(stored);
  const storedEnabled = !!(stored && stored.passport_enabled === true);
  return {
    resonance_access: resonanceAccess === true,
    passport_enabled: storedEnabled && resonanceAccess === true,
    passport_country: saved.passport_country,
    passport_city: saved.passport_city,
  };
}

function refuseResonanceRequired() {
  throw new HttpsError(
    'failed-precondition',
    'Resonance is required to set a Passport destination.',
    { code: 'resonance_required' },
  );
}

function parseDestination(data) {
  const country = normalizeCountryCode(data.passport_country);
  const city = normalizeCitySlug(data.passport_city);
  if (!country || !city) {
    throw new HttpsError(
      'invalid-argument',
      'passport_country and passport_city must be a valid ISO country and city slug.',
    );
  }
  return { country, city };
}

function assertNoTrustedUserLocationWrite(payload) {
  const forbidden = [
    'location',
    'location_text',
    'home_country',
    'home_city',
    'home_geo_updated_at',
    'latitude',
    'longitude',
    'lat',
    'lng',
    'geohash',
    'resonance_access',
    'super_resonance_balance',
  ];
  for (const key of forbidden) {
    if (Object.prototype.hasOwnProperty.call(payload, key)) {
      throw new Error(`passport payload must not include ${key}`);
    }
  }
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object }} [deps]
 */
async function handleGetDiscoverPassport(request, deps = {}) {
  const uid = requireAuthUid(request);
  const db = resolveDb(deps);
  const [entitlement, passportSnap] = await Promise.all([
    readEntitlement(db, uid),
    db.doc(passportPath(uid)).get(),
  ]);
  const stored =
    passportSnap && passportSnap.exists ? passportSnap.data() : null;
  return publicGetResult(entitlement.resonance_access === true, stored);
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object, serverTimestamp?: Function }} [deps]
 */
async function handleSetDiscoverPassport(request, deps = {}) {
  const uid = requireAuthUid(request);
  const data = requestData(request);
  const dest = parseDestination(data);
  const db = resolveDb(deps);
  const entitlement = await readEntitlement(db, uid);
  if (entitlement.resonance_access !== true) {
    refuseResonanceRequired();
  }
  const payload = {
    passport_enabled: true,
    passport_country: dest.country,
    passport_city: dest.city,
    updated_at: timestamp(deps),
    schema_version: SCHEMA_VERSION,
  };
  assertNoTrustedUserLocationWrite(payload);
  await db.doc(passportPath(uid)).set(payload, { merge: true });
  return publicGetResult(true, payload);
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object, serverTimestamp?: Function }} [deps]
 */
async function handleDisableDiscoverPassport(request, deps = {}) {
  const uid = requireAuthUid(request);
  const db = resolveDb(deps);
  const [entitlement, passportSnap] = await Promise.all([
    readEntitlement(db, uid),
    db.doc(passportPath(uid)).get(),
  ]);
  const stored =
    passportSnap && passportSnap.exists ? passportSnap.data() || {} : {};
  const payload = {
    passport_enabled: false,
    updated_at: timestamp(deps),
    schema_version: SCHEMA_VERSION,
  };
  assertNoTrustedUserLocationWrite(payload);
  await db.doc(passportPath(uid)).set(payload, { merge: true });
  return publicGetResult(entitlement.resonance_access === true, {
    ...stored,
    ...payload,
  });
}

module.exports = {
  SCHEMA_VERSION,
  GET_CALLABLE_NAME,
  SET_CALLABLE_NAME,
  DISABLE_CALLABLE_NAME,
  PUBLIC_GET_KEYS,
  passportPath,
  handleGetDiscoverPassport,
  handleSetDiscoverPassport,
  handleDisableDiscoverPassport,
};
