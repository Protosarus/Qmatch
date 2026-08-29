/**
 * Trusted IQ finalize (`admin_finalize_iq_v1`).
 *
 * Authenticates, structurally validates a locked 25-item IQ session, and
 * writes users/{uid}.assessment_verification_v1.iq via Admin SDK.
 * Does not score, store answers, grant Discover, or finalize EQ/Frequency.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const {
  validateAssessmentFinalizeSession,
} = require('./assessment_finalize_validation_v1');
const {
  deriveProgressionFlow,
  resolveTrustedFlow,
  preserveGrantReason,
} = require('./assessment_verification_flow_v1');

const CALLABLE_NAME = 'finalizeIq';
const REGION = 'europe-west1';
const SOURCE = 'admin_finalize_iq_v1';
const VERIFICATION_SCHEMA = 'assessment_verification_v1';
const CATALOG_VERSION = 'assessment_finalize_catalog_v1';
const FROZEN_USER_KEYS = Object.freeze([
  'test_completed',
  'assessment_flow_completed',
  'profile_completed',
  'discover_eligible',
  'active',
  'account_deletion_requested',
  'eq_completed',
  'frequency_completed',
]);

function requireAuthUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Authentication required to finalize IQ.',
    );
  }
  return uid;
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
      assessment_type: 'iq',
      ...event,
    }),
  );
}

function throwValidationError(code) {
  throw new HttpsError(
    'invalid-argument',
    'IQ session is not structurally complete.',
    { code },
  );
}

function copyTrustedModule(mod) {
  if (!mod || typeof mod !== 'object' || Array.isArray(mod)) return undefined;
  return { ...mod };
}

function buildIqVerifiedState(session, verifiedAt) {
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

function buildVerificationMap(existing, iqState, flow, grantReason) {
  const next = {
    schema_version: VERIFICATION_SCHEMA,
    iq: iqState,
    flow,
    grant_reason: grantReason,
    catalog_version: CATALOG_VERSION,
  };
  const eq = copyTrustedModule(existing && existing.eq);
  const frequency = copyTrustedModule(existing && existing.frequency);
  if (eq) next.eq = eq;
  if (frequency) next.frequency = frequency;
  return next;
}

function publicResult({ flow, idempotent }) {
  return {
    ok: true,
    assessment_type: 'iq',
    status: 'verified',
    flow,
    idempotent,
  };
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object, serverTimestamp?: Function, log?: Function }} [deps]
 */
async function handleFinalizeIq(request, deps = {}) {
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
  if (session.assessmentType !== 'iq') {
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
      'Cannot finalize another user\'s IQ session.',
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
    const currentIq = existingMap && existingMap.iq;

    if (currentIq && currentIq.status === 'verified') {
      if (currentIq.session_id === session.sessionId) {
        const flow = resolveTrustedFlow(
          existingMap.flow,
          deriveProgressionFlow(existingMap),
        );
        if (user.iq_completed !== true) {
          tx.update(userRef, { iq_completed: true });
        }
        return publicResult({ flow, idempotent: true });
      }
      throw new HttpsError(
        'failed-precondition',
        'IQ is already verified for a different session.',
        { code: 'IQ_ALREADY_VERIFIED' },
      );
    }

    const verifiedAt = timestamp(deps);
    const iqState = buildIqVerifiedState(session, verifiedAt);
    const nextModules = {
      iq: iqState,
      eq: existingMap && existingMap.eq,
      frequency: existingMap && existingMap.frequency,
    };
    const derived = deriveProgressionFlow(nextModules);
    const flow = resolveTrustedFlow(existingMap && existingMap.flow, derived);
    const grantReason = preserveGrantReason(existingMap, flow);
    const verification = buildVerificationMap(
      existingMap,
      iqState,
      flow,
      grantReason,
    );

    tx.update(userRef, {
      assessment_verification_v1: verification,
      iq_completed: true,
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
  handleFinalizeIq,
};
