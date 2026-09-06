/**
 * Trusted Who Liked You list (`listWhoLikedYou`).
 *
 * Admin-reads entitlement, collection-group inbound likes, liker users,
 * viewer swipes, matches, and both block docs.
 * Returns public profile cards only. Never block/swipe/assessment payloads.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const { requireVerifiedProductUid } = require('./verified_product_auth');
const { normalizeSnapshot } = require('./entitlement_access');
const {
  isValidLiveUser,
  deterministicMatchId,
} = require('./like_match_atomicity');
const { getAllSnapsIsolating } = require('./alignment_signals_batch');

const CALLABLE_NAME = 'listWhoLikedYou';
/** Must match `exports.listWhoLikedYou` region in index.js. */
const DEPLOYED_REGION = 'us-central1';
const MAX_ITEMS = 50;
/** user + viewerSwipe + match + viewerBlock + reverseBlock */
const ENRICHMENT_DOCS_PER_CANDIDATE = 5;
const PUBLIC_CARD_KEYS = Object.freeze([
  'uid',
  'name',
  'age',
  'photos',
  'profile_photo_url',
  'bio',
  'interests',
]);

function requireAuthUid(request) {
  return requireVerifiedProductUid(
    request,
    'Authentication required to list Who Liked You.',
  );
}

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return require('firebase-admin/firestore').getFirestore();
}

function denied() {
  return { resonance_access: false, items: [] };
}

function granted(items) {
  return { resonance_access: true, items };
}

/**
 * @param {object} snap
 * @returns {string|null}
 */
function resolveLikerUid(snap) {
  const data = snap && typeof snap.data === 'function' ? snap.data() : null;
  const fromUid =
    data && typeof data.from_uid === 'string' ? data.from_uid.trim() : '';
  const path =
    snap && snap.ref && typeof snap.ref.path === 'string' ? snap.ref.path : '';
  const parts = path.split('/').filter(Boolean);
  let pathUid = '';
  if (
    parts.length === 4 &&
    parts[0] === 'users' &&
    parts[2] === 'swipes'
  ) {
    pathUid = parts[1];
  }
  if (fromUid && pathUid && fromUid !== pathUid) return null;
  return fromUid || pathUid || null;
}

/**
 * @param {string} value
 * @returns {string[]}
 */
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

/**
 * Public Who Liked You card. Never copies IQ/EQ/Frequency/Persona/contact.
 * @param {string} uid
 * @param {Record<string, unknown>} data
 * @returns {Record<string, unknown>|null}
 */
function toPublicCard(uid, data) {
  if (!uid || !data || typeof data !== 'object') return null;
  const name = typeof data.name === 'string' ? data.name.trim() : '';
  if (!name) return null;
  const ageNum =
    typeof data.age === 'number' ? data.age : Number(data.age);
  const age = Number.isFinite(ageNum) ? Math.floor(ageNum) : NaN;
  if (!Number.isFinite(age) || age < 18) return null;

  const photos = publicStringList(data.photos);
  let primary =
    typeof data.profile_photo_url === 'string'
      ? data.profile_photo_url.trim()
      : '';
  if (!primary && photos.length) primary = photos[0];

  const card = {
    uid,
    name,
    age,
    photos,
    profile_photo_url: primary || null,
    bio: typeof data.bio === 'string' ? data.bio.trim() : '',
    interests: publicStringList(data.interests),
  };
  const out = {};
  for (const key of PUBLIC_CARD_KEYS) {
    out[key] = card[key];
  }
  return out;
}

/**
 * @param {object} args
 * @returns {boolean}
 */
function shouldIncludeLiker(args) {
  const {
    likerUid,
    viewerUid,
    likerExists,
    likerData,
    viewerSwipeExists,
    matchExists,
    viewerBlockedLiker,
    likerBlockedViewer,
  } = args;
  if (!likerUid || likerUid === viewerUid) return false;
  if (viewerSwipeExists) return false;
  if (matchExists) return false;
  if (viewerBlockedLiker || likerBlockedViewer) return false;
  if (!isValidLiveUser(likerExists, likerData)) return false;
  if (likerData && likerData.account_deletion_requested === true) {
    return false;
  }
  return toPublicCard(likerUid, likerData) != null;
}

/**
 * Build enrichment refs in candidate order. Snapshot index = i * 5 + slot.
 * @param {object} db
 * @param {string} viewerUid
 * @param {string[]} likerUids
 */
function buildLikerEnrichmentRefs(db, viewerUid, likerUids) {
  const refs = [];
  for (const likerUid of likerUids) {
    const matchId = deterministicMatchId(viewerUid, likerUid);
    refs.push(
      db.doc(`users/${likerUid}`),
      db.doc(`users/${viewerUid}/swipes/${likerUid}`),
      db.doc(`matches/${matchId}`),
      db.doc(`users/${viewerUid}/blocks/${likerUid}`),
      db.doc(`users/${likerUid}/blocks/${viewerUid}`),
    );
  }
  return refs;
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object }} [deps]
 */
async function handleListWhoLikedYou(request, deps = {}) {
  const viewerUid = requireAuthUid(request);
  const db = resolveDb(deps);

  const entitlementSnap = await db.doc(`entitlements/${viewerUid}`).get();
  const entitlement = normalizeSnapshot(
    viewerUid,
    entitlementSnap && entitlementSnap.exists ? entitlementSnap.data() : null,
  );
  if (entitlement.resonance_access !== true) {
    return denied();
  }

  const inboundSnap = await db
    .collectionGroup('swipes')
    .where('target_uid', '==', viewerUid)
    .where('direction', '==', 'like')
    .orderBy('created_at', 'desc')
    .limit(MAX_ITEMS)
    .get();

  const likerUids = [];
  const seen = new Set();
  const docs = (inboundSnap && inboundSnap.docs) || [];
  for (const doc of docs) {
    const likerUid = resolveLikerUid(doc);
    if (!likerUid || seen.has(likerUid)) continue;
    seen.add(likerUid);
    likerUids.push(likerUid);
  }

  const refs = buildLikerEnrichmentRefs(db, viewerUid, likerUids);
  const snaps = await getAllSnapsIsolating(db, refs);

  const items = [];
  for (let i = 0; i < likerUids.length; i += 1) {
    try {
      const base = i * ENRICHMENT_DOCS_PER_CANDIDATE;
      const likerUid = likerUids[i];
      const likerSnap = snaps[base];
      const viewerSwipeSnap = snaps[base + 1];
      const matchSnap = snaps[base + 2];
      const viewerBlockSnap = snaps[base + 3];
      const reverseBlockSnap = snaps[base + 4];
      const likerData =
        likerSnap && likerSnap.exists ? likerSnap.data() : null;
      if (
        !shouldIncludeLiker({
          likerUid,
          viewerUid,
          likerExists: !!(likerSnap && likerSnap.exists),
          likerData,
          viewerSwipeExists: !!(viewerSwipeSnap && viewerSwipeSnap.exists),
          matchExists: !!(matchSnap && matchSnap.exists),
          viewerBlockedLiker: !!(viewerBlockSnap && viewerBlockSnap.exists),
          likerBlockedViewer: !!(
            reverseBlockSnap && reverseBlockSnap.exists
          ),
        })
      ) {
        continue;
      }
      const card = toPublicCard(likerUid, likerData);
      if (card) items.push(card);
    } catch (_) {
      // Preserve prior per-candidate omit-on-error semantics.
    }
  }

  return granted(items);
}

module.exports = {
  CALLABLE_NAME,
  DEPLOYED_REGION,
  MAX_ITEMS,
  ENRICHMENT_DOCS_PER_CANDIDATE,
  PUBLIC_CARD_KEYS,
  requireAuthUid,
  resolveLikerUid,
  toPublicCard,
  shouldIncludeLiker,
  buildLikerEnrichmentRefs,
  handleListWhoLikedYou,
};
