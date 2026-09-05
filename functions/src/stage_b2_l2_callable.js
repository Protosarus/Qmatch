/**
 * Trusted Stage B2 L2 callable.
 *
 * Admin-reads owner-only canonical_v1 for viewer + L1 candidate UIDs.
 * Admin-omits reverse-blocked candidates (candidate blocked viewer).
 * Returns pair diagnostics only — never peer 20D vectors or block docs.
 *
 * Live ranking always Admin-reads Frequency V2 results and attaches
 * `compatibility_v2` (`qmatch_compatibility_fusion_v2_policy_v1`).
 * Optional `include_frequency_v2_diagnostics=true` still adds the nested
 * Frequency V2 aggregate diagnostic. V1 Frequency is never an input.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const {
  compareMeasuredPresence,
  compareIqEqMeasuredPresence,
  measuredScoresFromCanonicalProfile,
  SCORING_VERSION,
} = require('./canonical_20d_group_normalized_shadow');
const contract = require('./frequency_behavior_v2_contract');
const {
  parseFrequencyV2Snapshot,
  publicUnavailableReason,
} = require('./frequency_behavior_v2_result_parser');
const {
  fitFromParsedUsers,
  publicFrequencyV2FromFit,
  publicFrequencyV2Unavailable,
} = require('./frequency_behavior_v2_pair_fit');
const {
  fuseCompatibilityV2,
  publicCompatibilityV2,
} = require('./compatibility_fusion_v2');

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

function reverseBlockPath(candidateUid, viewerUid) {
  return `users/${candidateUid}/blocks/${viewerUid}`;
}

function frequencyV2Path(uid) {
  return `users/${uid}/assessments/${contract.RESULT_DOC_ID}`;
}

function wantsFrequencyV2Diagnostics(data) {
  return data.include_frequency_v2_diagnostics === true;
}

function wantsCompatibilityV2Diagnostics(data) {
  return data.include_compatibility_v2_diagnostics !== false;
}

function frequencyV2InputFromParsed(viewerParsed, candidateParsed) {
  const viewerReason = publicUnavailableReason(viewerParsed, 'viewer');
  if (viewerReason) {
    return { available: false, unavailable_reason: viewerReason };
  }
  const candidateReason = publicUnavailableReason(candidateParsed, 'candidate');
  if (candidateReason) {
    return { available: false, unavailable_reason: candidateReason };
  }
  const fit = fitFromParsedUsers(viewerParsed, candidateParsed);
  return {
    available: true,
    overall_supported_fit: fit.overall_supported_fit,
    overall_pair_support: fit.overall_pair_support,
  };
}

function attachFrequencyV2Diagnostic(pair, viewerParsed, candidateParsed) {
  const viewerReason = publicUnavailableReason(viewerParsed, 'viewer');
  if (viewerReason) {
    pair.frequency_v2 = publicFrequencyV2Unavailable(viewerReason);
    return pair;
  }
  const candidateReason = publicUnavailableReason(candidateParsed, 'candidate');
  if (candidateReason) {
    pair.frequency_v2 = publicFrequencyV2Unavailable(candidateReason);
    return pair;
  }
  pair.frequency_v2 = publicFrequencyV2FromFit(
    fitFromParsedUsers(viewerParsed, candidateParsed),
  );
  return pair;
}

function attachCompatibilityV2Diagnostic(
  pair,
  viewerScores,
  candScores,
  viewerParsed,
  candidateParsed,
) {
  const structural =
    viewerScores && candScores
      ? compareIqEqMeasuredPresence(viewerScores, candScores)
      : { available: false };
  pair.compatibility_v2 = publicCompatibilityV2(
    fuseCompatibilityV2(
      structural,
      frequencyV2InputFromParsed(viewerParsed, candidateParsed),
    ),
  );
  return pair;
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

const L2_TIMING_LOG_PREFIX = 'qmatch.l2';
const L2_TIMING_KEYS = Object.freeze([
  'handler_start_to_auth_ms',
  'viewer_canonical_get_ms',
  'candidate_canonical_gets_ms',
  'reverse_block_gets_ms',
  'membership_filter_ms',
  'scoring_cpu_ms',
  'response_serialization_ms',
  'total_handler_ms',
  'candidate_count',
]);

function nowMs() {
  return Number(process.hrtime.bigint()) / 1e6;
}

function elapsedMs(started) {
  return Math.max(0, Math.round(nowMs() - started));
}

function emptyTimings() {
  const out = {};
  for (const key of L2_TIMING_KEYS) out[key] = 0;
  return out;
}

function resolveLog(deps) {
  if (deps && typeof deps.log === 'function') return deps.log;
  return console.log;
}

/** Server logs only. Numbers + candidate_count. Never UIDs or profile data. */
function emitL2Timings(log, timings) {
  const out = {};
  for (const key of L2_TIMING_KEYS) {
    const value = timings[key];
    out[key] =
      typeof value === 'number' && Number.isFinite(value) ? value : 0;
  }
  log(`${L2_TIMING_LOG_PREFIX} ${JSON.stringify(out)}`);
}

/**
 * Admin BatchGetDocuments is one RPC per chunk. Chunks run in parallel so
 * 1+N+N docs stay one read round. Conservative 100-doc slices.
 */
const GET_ALL_CHUNK_SIZE = 100;

async function getAllSnaps(db, refs) {
  if (refs.length === 0) return [];
  if (typeof db.getAll === 'function') {
    if (refs.length <= GET_ALL_CHUNK_SIZE) {
      return db.getAll(...refs);
    }
    const groups = [];
    for (let i = 0; i < refs.length; i += GET_ALL_CHUNK_SIZE) {
      groups.push(db.getAll(...refs.slice(i, i + GET_ALL_CHUNK_SIZE)));
    }
    const parts = await Promise.all(groups);
    return parts.flat();
  }
  return Promise.all(refs.map((ref) => ref.get()));
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: { doc: Function, getAll?: Function }, log?: Function }} [deps]
 */
async function handleCompareStageB2Structural(request, deps = {}) {
  const started = nowMs();
  const timings = emptyTimings();
  const log = resolveLog(deps);
  try {
    const viewerUid = requireAuthUid(request);
    timings.handler_start_to_auth_ms = elapsedMs(started);
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
    timings.candidate_count = candidateUids.length;

    const includeFrequencyV2Public = wantsFrequencyV2Diagnostics(data);
    const includeCompatibilityV2 = wantsCompatibilityV2Diagnostics(data);
    const includeFrequencyV2Reads =
      includeFrequencyV2Public || includeCompatibilityV2;

    const db = resolveDb(deps);
    // Viewer canonical, candidate canonicals, and reverse-block exists-checks
    // have no data dependency. One BatchGet preserves the same snapshots.
    // V2 result docs are included in the same round only when V2 or
    // compatibility diagnostics are explicitly opted in. Compatibility
    // implies the V2 reads; it does not fetch a second round.
    const tBatchGet = nowMs();
    const refs = [
      db.doc(canonicalPath(viewerUid)),
      ...candidateUids.map((uid) => db.doc(canonicalPath(uid))),
      ...candidateUids.map((uid) =>
        db.doc(reverseBlockPath(uid, viewerUid)),
      ),
    ];
    if (includeFrequencyV2Reads) {
      refs.push(db.doc(frequencyV2Path(viewerUid)));
      for (const uid of candidateUids) {
        refs.push(db.doc(frequencyV2Path(uid)));
      }
    }
    const snaps = await getAllSnaps(db, refs);
    const batchMs = elapsedMs(tBatchGet);
    // Existing keys kept. Do not sum the three GET fields — IO is one round.
    timings.viewer_canonical_get_ms = 0;
    timings.candidate_canonical_gets_ms = batchMs;
    timings.reverse_block_gets_ms = 0;

    const n = candidateUids.length;
    const viewerSnap = snaps[0];
    const candidateSnaps = snaps.slice(1, 1 + n);
    const reverseBlockSnaps = snaps.slice(1 + n, 1 + n + n);
    const viewerV2Parsed = includeFrequencyV2Reads
      ? parseFrequencyV2Snapshot(snaps[1 + n + n])
      : null;
    const candidateV2Snaps = includeFrequencyV2Reads
      ? snaps.slice(2 + n + n, 2 + n + n + n)
      : [];

    const tViewerScores = nowMs();
    const viewerScores = measuredScoresFromCanonicalProfile(
      viewerSnap && viewerSnap.exists ? viewerSnap.data() : null,
    );
    let scoringMs = elapsedMs(tViewerScores);

    const includedUids = [];
    const pairs = [];
    let membershipMs = 0;
    for (let i = 0; i < candidateUids.length; i++) {
      const tMembership = nowMs();
      if (reverseBlockSnaps[i] && reverseBlockSnaps[i].exists) {
        // Omit entirely. Do not return a pair, reason, or block fields.
        membershipMs += elapsedMs(tMembership);
        continue;
      }
      includedUids.push(candidateUids[i]);
      membershipMs += elapsedMs(tMembership);

      const tScore = nowMs();
      const candSnap = candidateSnaps[i];
      const candScores = measuredScoresFromCanonicalProfile(
        candSnap && candSnap.exists ? candSnap.data() : null,
      );
      let pair;
      if (!viewerScores) {
        pair = publicUnavailable('viewer_canonical_profile_missing');
      } else if (!candScores) {
        pair = publicUnavailable('candidate_canonical_profile_missing');
      } else {
        pair = toPublicPair(
          compareMeasuredPresence(viewerScores, candScores),
        );
      }
      const candV2Parsed = includeFrequencyV2Reads
        ? parseFrequencyV2Snapshot(candidateV2Snaps[i])
        : null;
      if (includeFrequencyV2Public) {
        attachFrequencyV2Diagnostic(pair, viewerV2Parsed, candV2Parsed);
      }
      if (includeCompatibilityV2) {
        attachCompatibilityV2Diagnostic(
          pair,
          viewerScores,
          candScores,
          viewerV2Parsed,
          candV2Parsed,
        );
      }
      pairs.push(pair);
      scoringMs += elapsedMs(tScore);
    }
    timings.membership_filter_ms = membershipMs;
    timings.scoring_cpu_ms = scoringMs;

    const payload = { pairs, candidate_uids: includedUids };
    const tSerialize = nowMs();
    JSON.stringify(payload);
    timings.response_serialization_ms = elapsedMs(tSerialize);
    return payload;
  } finally {
    timings.total_handler_ms = elapsedMs(started);
    emitL2Timings(log, timings);
  }
}

module.exports = {
  CALLABLE_NAME,
  MAX_CANDIDATE_UIDS,
  PUBLIC_PAIR_KEYS,
  SCORING_VERSION,
  L2_TIMING_LOG_PREFIX,
  L2_TIMING_KEYS,
  GET_ALL_CHUNK_SIZE,
  handleCompareStageB2Structural,
  sanitizePair,
  toPublicPair,
  publicUnavailable,
  wantsFrequencyV2Diagnostics,
  wantsCompatibilityV2Diagnostics,
  frequencyV2Path,
};
