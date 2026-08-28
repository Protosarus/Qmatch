/**
 * Server-owned `public_profiles/{uid}` whitelist projection.
 *
 * Source of truth remains `users/{uid}`. This module copies only the
 * Discover/chat-safe fields. It never writes `users/{uid}` and never
 * recalculates `discover_eligible` (`trusted_discover_eligibility_authority_v1`).
 *
 * Writes use full document replacement (no merge) so removed optional
 * public fields disappear from the public snapshot.
 */

'use strict';

const { getFirestore } = require('firebase-admin/firestore');

const REGION = 'europe-west1';
const USER_DOCUMENT_PATH = 'users/{uid}';
const PUBLIC_PROFILES_COLLECTION = 'public_profiles';

/** Complete public whitelist. No other `users/{uid}` field may be copied. */
const PUBLIC_PROFILE_KEYS = Object.freeze([
  'discover_eligible',
  'home_country',
  'home_city',
  'name',
  'age',
  'bio',
  'photos',
  'profile_photo_url',
  'occupation',
  'company',
  'education',
  'school',
  'education_field',
  'anthem_title',
  'anthem_artist',
  'interests',
]);

function optionalTrimmedString(value) {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed ? trimmed : undefined;
}

function publicStringList(value) {
  if (!Array.isArray(value)) return [];
  const out = [];
  for (const item of value) {
    if (typeof item !== 'string') continue;
    const trimmed = item.trim();
    if (trimmed) out.push(trimmed);
  }
  return out;
}

function optionalAge(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.floor(value);
  }
  if (typeof value === 'string' && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return Math.floor(parsed);
  }
  return undefined;
}

/**
 * Build a brand-new public snapshot from an explicit whitelist.
 * Never spreads / clones the users document.
 *
 * @param {Record<string, unknown>|null|undefined} userData
 * @returns {Record<string, unknown>}
 */
function buildPublicProfileProjection(userData) {
  const src = userData && typeof userData === 'object' ? userData : {};
  const out = {};

  out.discover_eligible = src.discover_eligible === true;

  const homeCountry = optionalTrimmedString(src.home_country);
  if (homeCountry !== undefined) out.home_country = homeCountry;

  const homeCity = optionalTrimmedString(src.home_city);
  if (homeCity !== undefined) out.home_city = homeCity;

  const name = optionalTrimmedString(src.name);
  if (name !== undefined) out.name = name;

  const age = optionalAge(src.age);
  if (age !== undefined) out.age = age;

  const bio = optionalTrimmedString(src.bio);
  if (bio !== undefined) out.bio = bio;

  out.photos = publicStringList(src.photos);

  const profilePhotoUrl = optionalTrimmedString(src.profile_photo_url);
  if (profilePhotoUrl !== undefined) out.profile_photo_url = profilePhotoUrl;

  const occupation = optionalTrimmedString(src.occupation);
  if (occupation !== undefined) out.occupation = occupation;

  const company = optionalTrimmedString(src.company);
  if (company !== undefined) out.company = company;

  const education = optionalTrimmedString(src.education);
  if (education !== undefined) out.education = education;

  const school = optionalTrimmedString(src.school);
  if (school !== undefined) out.school = school;

  const educationField = optionalTrimmedString(src.education_field);
  if (educationField !== undefined) out.education_field = educationField;

  const anthemTitle = optionalTrimmedString(src.anthem_title);
  if (anthemTitle !== undefined) out.anthem_title = anthemTitle;

  const anthemArtist = optionalTrimmedString(src.anthem_artist);
  if (anthemArtist !== undefined) out.anthem_artist = anthemArtist;

  out.interests = publicStringList(src.interests);

  return out;
}

function snapExists(snap) {
  if (!snap) return false;
  if (typeof snap.exists === 'boolean') return snap.exists;
  if (typeof snap.data === 'function') {
    const data = snap.data();
    return data != null && typeof data === 'object';
  }
  return false;
}

function snapData(snap) {
  if (!snapExists(snap) || typeof snap.data !== 'function') return {};
  const data = snap.data();
  return data && typeof data === 'object' ? data : {};
}

function sortedClone(value) {
  if (Array.isArray(value)) {
    return value.map(sortedClone);
  }
  if (value && typeof value === 'object') {
    const out = {};
    for (const key of Object.keys(value).sort()) {
      out[key] = sortedClone(value[key]);
    }
    return out;
  }
  return value;
}

function projectionsEqual(a, b) {
  return JSON.stringify(sortedClone(a)) === JSON.stringify(sortedClone(b));
}

function publicProfileRef(db, uid) {
  return db.doc(`${PUBLIC_PROFILES_COLLECTION}/${uid}`);
}

/**
 * @param {object} event Firestore onDocumentWritten event
 * @param {{db?: FirebaseFirestore.Firestore}} [deps]
 */
async function handlePublicProfileUserWritten(event, deps = {}) {
  const db = deps.db || getFirestore();
  const uid =
    event && event.params && typeof event.params.uid === 'string'
      ? event.params.uid.trim()
      : '';
  if (!uid) {
    return { skipped: 'missing_uid' };
  }

  const afterSnap = event.data && event.data.after;
  const beforeSnap = event.data && event.data.before;
  const afterExists = snapExists(afterSnap);
  const beforeExists = snapExists(beforeSnap);

  let projection;
  if (afterExists) {
    projection = buildPublicProfileProjection(snapData(afterSnap));
  } else if (beforeExists) {
    projection = buildPublicProfileProjection(snapData(beforeSnap));
    projection.discover_eligible = false;
  } else {
    return { skipped: 'missing_user_snapshots' };
  }

  const ref = publicProfileRef(db, uid);
  const existingSnap = await ref.get();
  const existing = existingSnap.exists ? existingSnap.data() || {} : null;
  if (existing && projectionsEqual(existing, projection)) {
    return {
      skipped: 'unchanged',
      uid,
      discover_eligible: projection.discover_eligible,
    };
  }

  await ref.set(projection);

  return {
    skipped: null,
    uid,
    written: true,
    discover_eligible: projection.discover_eligible,
  };
}

module.exports = {
  REGION,
  USER_DOCUMENT_PATH,
  PUBLIC_PROFILES_COLLECTION,
  PUBLIC_PROFILE_KEYS,
  buildPublicProfileProjection,
  projectionsEqual,
  handlePublicProfileUserWritten,
};
