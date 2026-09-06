/**
 * Trusted Frequency V1 finalize (`admin_finalize_frequency_v1`).
 *
 * Authenticates, structurally validates a locked 50-item Frequency V1 session,
 * and writes users/{uid}.assessment_verification_v1.frequency via Admin SDK.
 * Does not score, store answers, grant Discover, or finalize IQ/EQ/V2.
 *
 * assessment_verification_v1.frequency is Frequency V1 only.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const { requireVerifiedProductUid } = require('./verified_product_auth');
const {
  validateAssessmentFinalizeSession,
} = require('./assessment_finalize_validation_v1');
const {
  deriveProgressionFlow,
  resolveTrustedFlow,
  preserveGrantReason,
} = require('./assessment_verification_flow_v1');

const CALLABLE_NAME = 'finalizeFrequency';
const REGION = 'europe-west1';
const SOURCE = 'admin_finalize_frequency_v1';
const VERIFICATION_SCHEMA = 'assessment_verification_v1';
const CATALOG_VERSION = 'assessment_finalize_catalog_v1';
const FROZEN_USER_KEYS = Object.freeze([
  'test_completed',
  'test_completed_at',
  'assessment_flow_completed',
  'assessment_flow_version',
  'profile_completed',
  'discover_eligible',
  'active',
  'account_deletion_requested',
  'iq_completed',
  'eq_completed',
]);

function requireAuthUid(request) {
  return requireVerifiedProductUid(
    request,
    'Authentication required to finalize Frequency.',
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
      assessment_type: 'frequency',
      ...event,
    }),
  );
}

function throwValidationError(code) {
  throw new HttpsError(
    'invalid-argument',
    'Frequency session is not structurally complete.',
    { code },
  );
}

function copyTrustedModule(mod) {
  if (!mod || typeof mod !== 'object' || Array.isArray(mod)) return undefined;
  return { ...mod };
}

function buildFrequencyVerifiedState(session, verifiedAt) {
  return {
    status: 'verified',
    source: SOURCE,
    session_id: session.sessionId,
    bank_version: session.bankVersion,
    bank_locale: session.bankLocale,
    catalog_version: session.catalogVersion,
    selection_policy_version: session.selectionPolicyVersion,
    verified_at: verifiedAt,
  };
}

function buildVerificationMap(existing, frequencyState, flow, grantReason) {
  const next = {
    schema_version: VERIFICATION_SCHEMA,
    frequency: frequencyState,
    flow,
    grant_reason: grantReason,
    catalog_version: CATALOG_VERSION,
  };
  const iq = copyTrustedModule(existing && existing.iq);
  const eq = copyTrustedModule(existing && existing.eq);
  if (iq) next.iq = iq;
  if (eq) next.eq = eq;
  return next;
}

function publicResult({ flow, idempotent }) {
  return {
    ok: true,
    assessment_type: 'frequency',
    status: 'verified',
    flow,
    idempotent,
  };
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object, serverTimestamp?: Function, log?: Function }} [deps]
 */
async function handleFinalizeFrequency(request, deps = {}) {
  const uid = requireAuthUid(request);
  const payload = request.data;
  const validation = validateAssessmentFinalizeSession(payload);
  if (!validation.ok) {
    logSafe(deps, {
      uid,
      ok: false,
      validation_code: validation.code,
    });
    throwValidationError(validation.code);
  }

  const session = validation.session;
  if (session.assessmentType !== 'frequency') {
    logSafe(deps, {
      uid,
      ok: false,
      validation_code: 'UNSUPPORTED_ASSESSMENT_TYPE',
    });
    throwValidationError('UNSUPPORTED_ASSESSMENT_TYPE');
  }
  if (session.ownerUid !== uid) {
    logSafe(deps, { uid, ok: false, validation_code: 'OWNER_MISMATCH' });
    throw new HttpsError(
      'permission-denied',
      'Cannot finalize another user\'s Frequency session.',
    );
  }

  const db = resolveDb(deps);
  const userRef = db.doc(`users/${uid}`);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) {
      throw new HttpsError('not-found', 'User not found.');
    }
    const user = snap.data() || {};
    const existing = user.assessment_verification_v1;
    const existingMap =
      existing && typeof existing === 'object' && !Array.isArray(existing)
        ? existing
        : null;
    const currentFrequency = existingMap && existingMap.frequency;

    if (currentFrequency && currentFrequency.status === 'verified') {
      if (currentFrequency.session_id === session.sessionId) {
        const flow = resolveTrustedFlow(
          existingMap.flow,
          deriveProgressionFlow(existingMap),
        );
        if (user.frequency_completed !== true) {
          tx.update(userRef, { frequency_completed: true });
        }
        return publicResult({ flow, idempotent: true });
      }
      throw new HttpsError(
        'failed-precondition',
        'Frequency is already verified for a different session.',
        { code: 'FREQUENCY_ALREADY_VERIFIED' },
      );
    }

    const verifiedAt = timestamp(deps);
    const frequencyState = buildFrequencyVerifiedState(session, verifiedAt);
    const nextModules = {
      iq: existingMap && existingMap.iq,
      eq: existingMap && existingMap.eq,
      frequency: frequencyState,
    };
    const derived = deriveProgressionFlow(nextModules);
    const flow = resolveTrustedFlow(existingMap && existingMap.flow, derived);
    const grantReason = preserveGrantReason(existingMap, flow, SOURCE);
    const verification = buildVerificationMap(
      existingMap,
      frequencyState,
      flow,
      grantReason,
    );

    tx.update(userRef, {
      assessment_verification_v1: verification,
      frequency_completed: true,
    });

    return publicResult({ flow, idempotent: false });
  });

  logSafe(deps, {
    uid,
    ok: true,
    validation_code: null,
    idempotent: result.idempotent,
    flow: result.flow,
  });
  return result;
}

module.exports = {
  CALLABLE_NAME,
  REGION,
  SOURCE,
  VERIFICATION_SCHEMA,
  FROZEN_USER_KEYS,
  handleFinalizeFrequency,
};
