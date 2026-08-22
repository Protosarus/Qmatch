/**
 * Trusted Super Resonance receiver inbox (`listSuperResonanceInbox`).
 *
 * Admin-queries inbound active signals and returns public sender cards.
 * Visible to Free and Resonance. Never lists ordinary likes. Never leaks
 * swipe/block/assessment/entitlement payloads.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const {
  isValidLiveUser,
  deterministicMatchId,
} = require('./like_match_atomicity');
const {
  COLLECTION,
  STATUS_ACTIVE,
} = require('./super_resonance_signal');
const { getAllSnapsIsolating } = require('./alignment_signals_batch');

const CALLABLE_NAME = 'listSuperResonanceInbox';
/** Must match `exports.listSuperResonanceInbox` region in index.js. */
const DEPLOYED_REGION = 'us-central1';
const MAX_ITEMS = 50;
/** user + viewerSwipe + senderSwipe + match + viewerBlock + reverseBlock */
const ENRICHMENT_DOCS_PER_CANDIDATE = 6;
const PUBLIC_CARD_KEYS = Object.freeze([
  'uid',
  'name',
  'age',
  'photos',
  'profile_photo_url',
  'bio',
  'interests',
  'super_resonance',
  'created_at',
]);
const PUBLIC_RESULT_KEYS = Object.freeze(['items']);

function requireAuthUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Authentication required to list Super Resonance.',
    );
  }
  return uid;
}

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return require('firebase-admin/firestore').getFirestore();
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

function serializeCreatedAt(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  if (value && typeof value.seconds === 'number') {
    return value.seconds * 1000;
  }
  if (value && typeof value._seconds === 'number') {
    return value._seconds * 1000;
  }
  return 0;
}

function resolveFromUid(snap, viewerUid) {
  const data = snap && typeof snap.data === 'function' ? snap.data() : null;
  const fromUid =
    data && typeof data.from_uid === 'string' ? data.from_uid.trim() : '';
  const toUid =
    data && typeof data.to_uid === 'string' ? data.to_uid.trim() : '';
  if (!fromUid) return null;
  if (toUid && toUid !== viewerUid) return null;
  return fromUid;
}

/**
 * Public Super Resonance inbox card. Never copies IQ/EQ/Frequency/Persona/contact.
 * @param {string} uid
 * @param {Record<string, unknown>} data
 * @param {unknown} createdAt
 * @returns {Record<string, unknown>|null}
 */
function toPublicInboxCard(uid, data, createdAt) {
  if (!uid || !data || typeof data !== 'object') return null;
  const name = typeof data.name === 'string' ? data.name.trim() : '';
  if (!name) return null;
  const ageNum = typeof data.age === 'number' ? data.age : Number(data.age);
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
    super_resonance: true,
    created_at: serializeCreatedAt(createdAt),
  };
  const out = {};
  for (const key of PUBLIC_CARD_KEYS) {
    out[key] = card[key];
  }
  return out;
}

function senderPassedViewer(senderSwipeSnap) {
  if (!senderSwipeSnap || !senderSwipeSnap.exists) return false;
  const data = senderSwipeSnap.data() || {};
  return data.direction === 'pass';
}

/**
 * @param {object} args
 * @returns {boolean}
 */
function shouldIncludeSender(args) {
  const {
    senderUid,
    viewerUid,
    senderExists,
    senderData,
    viewerSwipeExists,
    senderPassed,
    matchExists,
    viewerBlockedSender,
    senderBlockedViewer,
  } = args;
  if (!senderUid || senderUid === viewerUid) return false;
  if (viewerSwipeExists) return false;
  if (senderPassed) return false;
  if (matchExists) return false;
  if (viewerBlockedSender || senderBlockedViewer) return false;
  if (!isValidLiveUser(senderExists, senderData)) return false;
  if (senderData && senderData.account_deletion_requested === true) {
    return false;
  }
  return toPublicInboxCard(senderUid, senderData, 0) != null;
}

function publicResult(items) {
  return { items };
}

/**
 * Build enrichment refs in sender order. Snapshot index = i * 6 + slot.
 * @param {object} db
 * @param {string} viewerUid
 * @param {Array<{ senderUid: string }>} senders
 */
function buildSenderEnrichmentRefs(db, viewerUid, senders) {
  const refs = [];
  for (const row of senders) {
    const senderUid = row.senderUid;
    const matchId = deterministicMatchId(viewerUid, senderUid);
    refs.push(
      db.doc(`users/${senderUid}`),
      db.doc(`users/${viewerUid}/swipes/${senderUid}`),
      db.doc(`users/${senderUid}/swipes/${viewerUid}`),
      db.doc(`matches/${matchId}`),
      db.doc(`users/${viewerUid}/blocks/${senderUid}`),
      db.doc(`users/${senderUid}/blocks/${viewerUid}`),
    );
  }
  return refs;
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object }} [deps]
 */
async function handleListSuperResonanceInbox(request, deps = {}) {
  const viewerUid = requireAuthUid(request);
  const db = resolveDb(deps);

  const inboundSnap = await db
    .collection(COLLECTION)
    .where('to_uid', '==', viewerUid)
    .where('status', '==', STATUS_ACTIVE)
    .orderBy('created_at', 'desc')
    .limit(MAX_ITEMS)
    .get();

  const senders = [];
  const seen = new Set();
  const docs = (inboundSnap && inboundSnap.docs) || [];
  for (const doc of docs) {
    const senderUid = resolveFromUid(doc, viewerUid);
    if (!senderUid || seen.has(senderUid)) continue;
    seen.add(senderUid);
    const data = doc.data() || {};
    senders.push({
      senderUid,
      createdAt: data.created_at,
    });
  }

  const refs = buildSenderEnrichmentRefs(db, viewerUid, senders);
  const snaps = await getAllSnapsIsolating(db, refs);

  const items = [];
  for (let i = 0; i < senders.length; i += 1) {
    try {
      const base = i * ENRICHMENT_DOCS_PER_CANDIDATE;
      const { senderUid, createdAt } = senders[i];
      const senderSnap = snaps[base];
      const viewerSwipeSnap = snaps[base + 1];
      const senderSwipeSnap = snaps[base + 2];
      const matchSnap = snaps[base + 3];
      const viewerBlockSnap = snaps[base + 4];
      const reverseBlockSnap = snaps[base + 5];
      const senderData =
        senderSnap && senderSnap.exists ? senderSnap.data() : null;
      if (
        !shouldIncludeSender({
          senderUid,
          viewerUid,
          senderExists: !!(senderSnap && senderSnap.exists),
          senderData,
          viewerSwipeExists: !!(viewerSwipeSnap && viewerSwipeSnap.exists),
          senderPassed: senderPassedViewer(senderSwipeSnap),
          matchExists: !!(matchSnap && matchSnap.exists),
          viewerBlockedSender: !!(viewerBlockSnap && viewerBlockSnap.exists),
          senderBlockedViewer: !!(
            reverseBlockSnap && reverseBlockSnap.exists
          ),
        })
      ) {
        continue;
      }
      const card = toPublicInboxCard(senderUid, senderData, createdAt);
      if (card) items.push(card);
    } catch (_) {
      // Preserve prior per-candidate omit-on-error semantics.
    }
  }

  return publicResult(items);
}

module.exports = {
  CALLABLE_NAME,
  DEPLOYED_REGION,
  MAX_ITEMS,
  ENRICHMENT_DOCS_PER_CANDIDATE,
  PUBLIC_CARD_KEYS,
  PUBLIC_RESULT_KEYS,
  requireAuthUid,
  resolveFromUid,
  toPublicInboxCard,
  shouldIncludeSender,
  buildSenderEnrichmentRefs,
  handleListSuperResonanceInbox,
};
