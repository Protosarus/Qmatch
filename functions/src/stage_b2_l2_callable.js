/**
 * Trusted Stage B2 L2 callable.
 *
 * Admin-reads owner-only canonical_v1 for viewer + L1 candidate UIDs.
 * Returns pair diagnostics only — never peer 20D vectors.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const {
  compareMeasuredPresence,
  measuredScoresFromCanonicalProfile,
  SCORING_VERSION,
} = require('./canonical_20d_group_normalized_shadow');

const CALLABLE_NAME = 'compareStageB2Structural';
const MAX_CANDIDATE_UIDS = 120;
const PUBLIC_PAIR_KEYS = Object.freeze([
  'available',
  'structural_distance',
  'total_coverage',
  'comparable_dimensions',
  'unavailable_reason',
]);

function requireAuthUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Authentication required for Stage B2 structural comparison.',
    );
  }
  return uid;
}

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return require('firebase-admin/firestore').getFirestore();
}

function canonicalPath(uid) {
  return `users/${uid}/profiles/canonical_v1`;
}

function publicUnavailable(reason) {
  return sanitizePair({
    available: false,
    total_coverage: 0.0,
    comparable_dimensions: 0,
    unavailable_reason: reason,
  });
}

function toPublicPair(result) {
  if (!result.available) {
    return publicUnavailable('no_shared_measured_modules');
  }
  return sanitizePair({
    available: true,
    structural_distance: result.combinedDistance,
    total_coverage: result.totalCoverage,
    comparable_dimensions: result.totalComparableDimensionCount,
  });
}

function sanitizePair(pair) {
  const out = {};
  for (const key of PUBLIC_PAIR_KEYS) {
    if (pair[key] !== undefined) out[key] = pair[key];
  }
  return out;
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: { doc: Function } }} [deps]
 */
async function handleCompareStageB2Structural(request, deps = {}) {
  const viewerUid = requireAuthUid(request);
  const data = request.data && typeof request.data === 'object' ? request.data : {};
  const raw = data.candidate_uids;
  if (!Array.isArray(raw)) {
    throw new HttpsError(
      'invalid-argument',
      'candidate_uids must be an array of L1 Discover candidate ids.',
    );
  }
  if (raw.length > MAX_CANDIDATE_UIDS) {
    throw new HttpsError(
      'invalid-argument',
      `candidate_uids exceeds max ${MAX_CANDIDATE_UIDS}.`,
    );
  }

  const candidateUids = [];
  for (const item of raw) {
    if (typeof item !== 'string' || item.length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'candidate_uids must contain only non-empty strings.',
      );
    }
    candidateUids.push(item);
  }

  const db = resolveDb(deps);
  const viewerSnap = await db.doc(canonicalPath(viewerUid)).get();
  const viewerScores = measuredScoresFromCanonicalProfile(
    viewerSnap.exists ? viewerSnap.data() : null,
  );

  const candidateSnaps = await Promise.all(
    candidateUids.map((uid) => db.doc(canonicalPath(uid)).get()),
  );

  const pairs = [];
  for (let i = 0; i < candidateUids.length; i++) {
    if (!viewerScores) {
      pairs.push(publicUnavailable('viewer_canonical_profile_missing'));
      continue;
    }
    const candSnap = candidateSnaps[i];
    const candScores = measuredScoresFromCanonicalProfile(
      candSnap && candSnap.exists ? candSnap.data() : null,
    );
    if (!candScores) {
      pairs.push(publicUnavailable('candidate_canonical_profile_missing'));
      continue;
    }
    pairs.push(toPublicPair(compareMeasuredPresence(viewerScores, candScores)));
  }

  return { pairs };
}

module.exports = {
  CALLABLE_NAME,
  MAX_CANDIDATE_UIDS,
  PUBLIC_PAIR_KEYS,
  SCORING_VERSION,
  handleCompareStageB2Structural,
  sanitizePair,
  toPublicPair,
  publicUnavailable,
};
