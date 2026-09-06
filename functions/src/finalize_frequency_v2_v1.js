/**
 * Trusted Frequency V2 finalize (`admin_finalize_frequency_v2_v1`).
 *
 * Authenticates, validates a locked 50-item V2 session via the Phase 7C
 * validator, scores server-side, and Admin-writes
 * users/{uid}/assessments/frequency_v2 only.
 *
 * Does not write users/{uid}, V1 frequency, canonical_v1, Discover,
 * matching, or completion flags. V2 remains dormant (runtime_selectable=false).
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const { requireVerifiedProductUid } = require('./verified_product_auth');
const contract = require('./frequency_behavior_v2_contract');
const { scoreSession } = require('./frequency_behavior_v2_scorer');
const {
  ERROR_CODES,
  findForbiddenAuthorityKey,
  validateFrequencyV2Session,
} = require('./frequency_behavior_v2_session_validation');
const { sha256Canonical } = require('./canonical_json_sha256_v1');

const CALLABLE_NAME = 'finalizeFrequencyV2';
const REGION = 'europe-west1';
const SOURCE = 'admin_finalize_frequency_v2_v1';
const RESULT_SCHEMA_VERSION = 'qmatch_frequency_behavior_v2_result_v1';
const RESULT_DOC_ID = 'frequency_v2';
const RESULT_STATUS = 'completed';

const ERROR_SESSION_CONFLICT = 'FREQUENCY_V2_SESSION_CONFLICT';
const ERROR_ALREADY_FINALIZED = 'FREQUENCY_V2_ALREADY_FINALIZED';

/**
 * Additional client-authority keys rejected by this callable.
 * Phase 7C FORBIDDEN_AUTHORITY_KEYS remain mandatory and are not weakened.
 * These extras are scanned here so 7C's verified set stays unchanged.
 */
const EXTRA_FORBIDDEN_AUTHORITY_KEYS = Object.freeze([
  'confidence_completeness',
  'primary_signal_coverage',
  'behavioral_weights',
  'evidence',
  'evidence_priors',
  'signed_pole_state',
  'pole_amplitudes_24d',
  'state_vector_24d',
  'density_matrix',
  'frequency_fit_index',
  'result_sha256',
  'session_proof_sha256',
  'responses_sha256',
  'frequency_v2_completed',
  'discover_eligible',
  'frequency_vector',
  'verified_at',
  'created_at',
  'updated_at',
]);

const EXTRA_FORBIDDEN_SET = new Set(EXTRA_FORBIDDEN_AUTHORITY_KEYS);

const PERSISTED_FORBIDDEN_RESULT_KEYS = Object.freeze([
  'behavioral_mean_12d',
  'pair_fit',
  'pair_relation',
  'frequency_fit_index',
  'signed_pole_state',
  'pole_amplitudes_24d',
  'state_vector_24d',
  'density_matrix',
  'telemetry',
  'raw_sum',
  'capacity',
  'signal_utilization',
  'behavioral_weights',
  'evidence',
  'evidence_priors',
  'frequency_completed',
  'frequency_v2_completed',
  'test_completed',
  'assessment_flow_completed',
  'discover_eligible',
  'canonical_v1',
  'frequency_vector',
  'frequency_score',
]);

function requireAuthUid(request) {
  return requireVerifiedProductUid(
    request,
    'Authentication required to finalize Frequency V2.',
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

function logSafe(deps, event) {
  const log = deps && typeof deps.log === 'function' ? deps.log : console.log;
  log(
    JSON.stringify({
      policy: SOURCE,
      assessment_type: contract.ASSESSMENT_TYPE,
      ...event,
    }),
  );
}

function throwValidationError(code) {
  throw new HttpsError(
    'invalid-argument',
    'Frequency V2 session is not structurally complete.',
    { code },
  );
}

function findExtraForbiddenAuthorityKey(value, path) {
  if (value == null || typeof value !== 'object') return null;
  if (Array.isArray(value)) {
    for (let i = 0; i < value.length; i++) {
      const hit = findExtraForbiddenAuthorityKey(value[i], `${path}[${i}]`);
      if (hit) return hit;
    }
    return null;
  }
  for (const [key, child] of Object.entries(value)) {
    if (EXTRA_FORBIDDEN_SET.has(key)) {
      return { key, path: path ? `${path}.${key}` : key };
    }
    const hit = findExtraForbiddenAuthorityKey(
      child,
      path ? `${path}.${key}` : key,
    );
    if (hit) return hit;
  }
  return null;
}

function rejectClientAuthority(payload) {
  const extra = findExtraForbiddenAuthorityKey(payload, '');
  if (extra) {
    return {
      ok: false,
      code: ERROR_CODES.FORBIDDEN_AUTHORITY_FIELD,
      message: `forbidden authority field ${extra.key}`,
    };
  }
  const existing = findForbiddenAuthorityKey(payload, '');
  if (existing) {
    return {
      ok: false,
      code: ERROR_CODES.FORBIDDEN_AUTHORITY_FIELD,
      message: `forbidden authority field ${existing.key}`,
    };
  }
  return { ok: true };
}

function resultDocPath(uid) {
  return `users/${uid}/assessments/${RESULT_DOC_ID}`;
}

function buildVersionPins(bank) {
  const pins = {
    bank_version: bank.bank_version,
    bank_locale: bank.locale,
    selection_policy_version: contract.SELECTION_POLICY_VERSION,
    selector_version: contract.SELECTOR_VERSION,
    scoring_policy_version: contract.SCORING_POLICY_VERSION,
    scorer_version: contract.SCORER_VERSION,
    confidence_model_version: contract.CONFIDENCE_MODEL_VERSION,
    session_manifest_schema_version: contract.SESSION_MANIFEST_SCHEMA_VERSION,
    finalize_catalog_version: contract.CATALOG_VERSION,
  };
  if (bank.locale === contract.LOCALE_EN) {
    pins.translation_version =
      bank.translation_version || contract.TRANSLATION_VERSION_EN;
  }
  return pins;
}

function buildSessionProof(manifest, sessionSeed) {
  return {
    session_seed: sessionSeed,
    item_count: contract.SESSION_ITEM_COUNT,
    item_plans: manifest.questions.map((q, index) => ({
      item_id: q.question_id,
      presentation_index: index,
      presented_option_order: q.presented_option_order.slice(),
    })),
  };
}

function buildResponses(manifest, answers) {
  const selectedByItem = Object.create(null);
  for (const answer of answers) {
    selectedByItem[answer.item_id] = answer.selected_option_id;
  }
  return manifest.questions.map((q) => ({
    item_id: q.question_id,
    option_id: selectedByItem[q.question_id],
  }));
}

function persistDimension(scoreRow) {
  const row = {
    dimension_id: scoreRow.dimension_id,
  };
  if (scoreRow.normalized_behavior != null) {
    row.normalized_behavior = scoreRow.normalized_behavior;
  }
  if (scoreRow.provisional_confidence != null) {
    row.provisional_confidence = scoreRow.provisional_confidence;
  }
  if (
    Array.isArray(scoreRow.confidence_flags) &&
    scoreRow.confidence_flags.length > 0
  ) {
    row.confidence_flags = scoreRow.confidence_flags.slice();
  }
  if (scoreRow.cross_context_consistency != null) {
    row.cross_context_consistency = scoreRow.cross_context_consistency;
  }
  if (scoreRow.cross_context_coverage != null) {
    row.cross_context_coverage = scoreRow.cross_context_coverage;
  }
  if (scoreRow.confidence_completeness != null) {
    row.confidence_completeness = scoreRow.confidence_completeness;
  }
  if (scoreRow.primary_signal_coverage != null) {
    row.primary_signal_coverage = scoreRow.primary_signal_coverage;
  }
  return row;
}

function persistDimensions(scoreRows) {
  const byId = Object.create(null);
  for (const row of scoreRows) {
    byId[row.dimension_id] = row;
  }
  return contract.CANONICAL_DIMENSIONS.map((id) => {
    const scored = byId[id];
    if (!scored) {
      return { dimension_id: id };
    }
    return persistDimension(scored);
  });
}

function responsesHashPayload(responses) {
  return [...responses].sort((a, b) => {
    if (a.item_id < b.item_id) return -1;
    if (a.item_id > b.item_id) return 1;
    return 0;
  });
}

function buildIntegrity({ versionPins, sessionProof, responses, dimensions, summary }) {
  return {
    session_proof_sha256: sha256Canonical(sessionProof),
    responses_sha256: sha256Canonical(responsesHashPayload(responses)),
    result_sha256: sha256Canonical({
      version_pins: versionPins,
      dimensions,
      summary,
    }),
  };
}

function buildResultDocument({
  bank,
  manifest,
  payload,
  score,
  now,
}) {
  const versionPins = buildVersionPins(bank);
  const sessionProof = buildSessionProof(manifest, payload.session_seed);
  const responses = buildResponses(manifest, payload.answers);
  const dimensions = persistDimensions(score.dimensions || score.dimension_scores);
  const summary = {
    measured_dimension_count: score.summary.measured_dimension_count,
    dimensions_with_behavior: score.summary.dimensions_with_behavior,
    global_support: score.summary.global_support,
  };
  const integrity = buildIntegrity({
    versionPins,
    sessionProof,
    responses,
    dimensions,
    summary,
  });
  return {
    schema_version: RESULT_SCHEMA_VERSION,
    assessment_type: contract.ASSESSMENT_TYPE,
    status: RESULT_STATUS,
    source: SOURCE,
    session_id: payload.session_id,
    version_pins: versionPins,
    session_proof: sessionProof,
    responses,
    dimensions,
    summary,
    integrity,
    verified_at: now,
    created_at: now,
    updated_at: now,
  };
}

function sameDeterministicIdentity(existing, built) {
  const existingIntegrity = existing.integrity || {};
  const builtIntegrity = built.integrity || {};
  return (
    existing.session_id === built.session_id &&
    existingIntegrity.session_proof_sha256 ===
      builtIntegrity.session_proof_sha256 &&
    existingIntegrity.responses_sha256 === builtIntegrity.responses_sha256 &&
    existingIntegrity.result_sha256 === builtIntegrity.result_sha256
  );
}

function publicResult({ sessionId, idempotent }) {
  return {
    ok: true,
    assessment_type: contract.ASSESSMENT_TYPE,
    status: RESULT_STATUS,
    session_id: sessionId,
    idempotent,
  };
}

function scoreValidatedSession(bank, manifest, payload) {
  const responses = payload.answers.map((answer) => ({
    item_id: answer.item_id,
    selected_option_id: answer.selected_option_id,
  }));
  const score = scoreSession({
    bank,
    manifest,
    responses,
  });
  if (!score || score.ok !== true) {
    throw new HttpsError(
      'internal',
      'Frequency V2 server scoring failed after validation.',
    );
  }
  return score;
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object, serverTimestamp?: Function, log?: Function }} [deps]
 */
async function handleFinalizeFrequencyV2(request, deps = {}) {
  const uid = requireAuthUid(request);
  const payload = request.data;

  const authority = rejectClientAuthority(payload);
  if (!authority.ok) {
    logSafe(deps, {
      uid,
      ok: false,
      validation_code: authority.code,
    });
    throwValidationError(authority.code);
  }

  const validation = validateFrequencyV2Session(payload);
  if (!validation.ok) {
    logSafe(deps, {
      uid,
      ok: false,
      validation_code: validation.code,
    });
    throwValidationError(validation.code);
  }

  if (payload.owner_uid !== uid) {
    logSafe(deps, { uid, ok: false, validation_code: 'OWNER_MISMATCH' });
    throw new HttpsError(
      'permission-denied',
      "Cannot finalize another user's Frequency V2 session.",
    );
  }

  const score = scoreValidatedSession(
    validation.bank,
    validation.manifest,
    payload,
  );

  const db = resolveDb(deps);
  const resultRef = db.doc(resultDocPath(uid));
  const built = buildResultDocument({
    bank: validation.bank,
    manifest: validation.manifest,
    payload,
    score,
    now: timestamp(deps),
  });

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(resultRef);
    if (snap.exists) {
      const existing = snap.data() || {};
      if (existing.session_id === payload.session_id) {
        if (sameDeterministicIdentity(existing, built)) {
          return publicResult({
            sessionId: payload.session_id,
            idempotent: true,
          });
        }
        throw new HttpsError(
          'failed-precondition',
          'Frequency V2 session identity conflicts with an existing result.',
          { code: ERROR_SESSION_CONFLICT },
        );
      }
      throw new HttpsError(
        'failed-precondition',
        'Frequency V2 is already finalized for a different session.',
        { code: ERROR_ALREADY_FINALIZED },
      );
    }

    tx.set(resultRef, built);
    return publicResult({
      sessionId: payload.session_id,
      idempotent: false,
    });
  });

  logSafe(deps, {
    uid,
    ok: true,
    validation_code: null,
    idempotent: result.idempotent,
  });
  return result;
}

module.exports = {
  CALLABLE_NAME,
  REGION,
  SOURCE,
  RESULT_SCHEMA_VERSION,
  RESULT_DOC_ID,
  RESULT_STATUS,
  ERROR_SESSION_CONFLICT,
  ERROR_ALREADY_FINALIZED,
  EXTRA_FORBIDDEN_AUTHORITY_KEYS,
  PERSISTED_FORBIDDEN_RESULT_KEYS,
  handleFinalizeFrequencyV2,
  buildVersionPins,
  buildSessionProof,
  buildResponses,
  persistDimensions,
  buildIntegrity,
  buildResultDocument,
  responsesHashPayload,
  resultDocPath,
  canonicalIdentityHashes: buildIntegrity,
};
