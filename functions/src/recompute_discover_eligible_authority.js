/**
 * Trusted Discover eligibility writers (source-prep, not deployed in 8C.1).
 *
 * Both user-document and Frequency V2 result paths use the same derivation
 * and may write only `discover_eligible`.
 */

'use strict';

const contract = require('./frequency_behavior_v2_contract');
const {
  parseFrequencyV2Snapshot,
} = require('./frequency_behavior_v2_result_parser');
const {
  ASSESSMENT_GRANT_POLICY_VERSION,
  hasTrustedAssessmentDiscoverGrant,
  planDiscoverEligibleWriteWithProof,
} = require('./discover_eligibility');

const USER_WRITE_POLICY = 'trusted_discover_eligibility_authority_v1';
const FREQUENCY_V2_WRITE_POLICY =
  'trusted_discover_eligibility_frequency_v2_authority_v1';

function frequencyV2Path(uid) {
  return `users/${uid}/assessments/${contract.RESULT_DOC_ID}`;
}

function userPath(uid) {
  return `users/${uid}`;
}

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return require('firebase-admin/firestore').getFirestore();
}

async function loadFrequencyV2Parsed(db, uid) {
  const snap = await db.doc(frequencyV2Path(uid)).get();
  return parseFrequencyV2Snapshot(snap);
}

/**
 * User write: V1/grandfather can derive without a V2 read. Otherwise Admin-read
 * users/{uid}/assessments/frequency_v2 and apply PATH B if the parser accepts it.
 */
async function handleRecomputeDiscoverEligibleOnUserWrite(event, deps = {}) {
  const afterSnap = event.data && event.data.after;
  if (!afterSnap || !afterSnap.exists) {
    return null;
  }
  const beforeSnap = event.data && event.data.before;
  const beforeData =
    beforeSnap && beforeSnap.exists ? beforeSnap.data() : null;
  const afterData = afterSnap.data() || {};
  const uid = event.params && event.params.uid;

  let frequencyV2Result = { ok: false, code: 'not_consulted' };
  if (!hasTrustedAssessmentDiscoverGrant(afterData)) {
    const db = resolveDb(deps);
    frequencyV2Result = await loadFrequencyV2Parsed(db, uid);
  }

  const plan = planDiscoverEligibleWriteWithProof(beforeData, afterData, {
    frequencyV2Result,
  });
  if (!plan.shouldWrite) {
    return null;
  }

  const db = resolveDb(deps);
  await db.doc(afterSnap.ref.path).update({
    discover_eligible: plan.derived,
  });
  return {
    uid,
    discover_eligible: plan.derived,
    policy: USER_WRITE_POLICY,
    grant_policy: ASSESSMENT_GRANT_POLICY_VERSION,
  };
}

/**
 * Frequency V2 result write: read current user document + this result.
 * Writes only discover_eligible. No completion / verification / canonical writes.
 */
async function handleRecomputeDiscoverEligibleOnFrequencyV2Write(
  event,
  deps = {},
) {
  const uid = event.params && event.params.uid;
  if (!uid) return null;
  const db = resolveDb(deps);
  const userSnap = await db.doc(userPath(uid)).get();
  if (!userSnap || !userSnap.exists) {
    return null;
  }
  const userData = userSnap.data() || {};
  const afterSnap = event.data && event.data.after;
  const frequencyV2Result = parseFrequencyV2Snapshot(afterSnap);
  const plan = planDiscoverEligibleWriteWithProof(userData, userData, {
    frequencyV2Result,
  });
  if (!plan.shouldWrite) {
    return null;
  }
  await db.doc(userPath(uid)).update({
    discover_eligible: plan.derived,
  });
  return {
    uid,
    discover_eligible: plan.derived,
    policy: FREQUENCY_V2_WRITE_POLICY,
    grant_policy: ASSESSMENT_GRANT_POLICY_VERSION,
  };
}

module.exports = {
  USER_WRITE_POLICY,
  FREQUENCY_V2_WRITE_POLICY,
  frequencyV2Path,
  handleRecomputeDiscoverEligibleOnUserWrite,
  handleRecomputeDiscoverEligibleOnFrequencyV2Write,
};
