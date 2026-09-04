/**
 * Trusted Discover eligibility derivation (`trusted_discover_eligibility_authority_v1`).
 *
 * Canonical profile gate:
 *   account_deletion_requested != true &&
 *   active == true &&
 *   profile_completed == true &&
 *   hasValidPhoto &&
 *   hasTrustedAssessmentDiscoverGrant
 *
 * Assessment grant (`trusted_discover_assessment_grant_v2`):
 *   PATH A: trusted IQ + EQ + Frequency V1 modules
 *   PATH B: trusted IQ + EQ + valid authoritative Frequency V2 result
 *   PATH C: pre_c2_preserved + pre_trust_migration_preserved
 *
 * `assessment_verification_v1.frequency` remains Frequency V1 only.
 * Frequency V2 proof is users/{uid}/assessments/frequency_v2 parsed by the
 * strict result parser. It is never copied onto users/{uid}.
 *
 * Client flags (test_completed / assessment_flow_completed) and
 * flow=complete alone are not proof.
 *
 * Missing required data => false.
 * Deletion soft-marker or inactive => false.
 *
 * Pure helpers only — no I/O. Safe for unit tests and Cloud Functions.
 */

'use strict';

const {
  hasTrustedV1Battery,
  hasTrustedIqEq,
  hasPreTrustMigrationGrant,
} = require('./assessment_verification_flow_v1');

const ASSESSMENT_GRANT_POLICY_VERSION =
  'trusted_discover_assessment_grant_v2';

/** Fields that can change derived discover_eligible on users/{uid}. */
const RELEVANT_KEYS = Object.freeze([
  'active',
  'profile_completed',
  'profile_photo_url',
  'photos',
  'account_deletion_requested',
  'discover_eligible',
  'assessment_verification_v1',
]);

/**
 * Photo rule consistent with MatchLiveUserValidityGate / profile writes.
 *
 * hasPhoto when either:
 * - non-empty trimmed `profile_photo_url` (legacy photo-only profiles), or
 * - `photos` list contains a non-empty trimmed string URL
 *
 * Empty string / whitespace-only URL does **not** count (client clears stale
 * primary to `''` when all photos are removed).
 *
 * @param {Record<string, unknown>|null|undefined} data
 * @returns {boolean}
 */
function hasValidPhoto(data) {
  if (!data || typeof data !== 'object') return false;
  const url =
    typeof data.profile_photo_url === 'string'
      ? data.profile_photo_url.trim()
      : '';
  if (url.length > 0) return true;
  const photos = data.photos;
  if (!Array.isArray(photos)) return false;
  for (const p of photos) {
    if (typeof p === 'string' && p.trim().length > 0) return true;
  }
  return false;
}

function isTrustedFrequencyV2Proof(parsed) {
  return !!(parsed && parsed.ok === true);
}

/**
 * User-document-only grant: V1 battery or grandfather.
 * Cannot see Frequency V2 (cross-document). Kept for backward-compatible tests.
 *
 * @param {Record<string, unknown>|null|undefined} data
 * @returns {boolean}
 */
function hasTrustedAssessmentDiscoverGrant(data) {
  if (!data || typeof data !== 'object') return false;
  const verification = data.assessment_verification_v1;
  if (hasTrustedV1Battery(verification)) return true;
  if (hasPreTrustMigrationGrant(verification)) return true;
  return false;
}

/**
 * @param {Record<string, unknown>|null|undefined} data
 * @param {{ ok?: boolean }|null|undefined} frequencyV2Parsed
 * @returns {boolean}
 */
function hasTrustedAssessmentDiscoverGrantWithProof(data, frequencyV2Parsed) {
  if (!data || typeof data !== 'object') return false;
  const verification = data.assessment_verification_v1;
  if (hasTrustedV1Battery(verification)) return true;
  if (hasPreTrustMigrationGrant(verification)) return true;
  if (
    hasTrustedIqEq(verification) &&
    isTrustedFrequencyV2Proof(frequencyV2Parsed)
  ) {
    return true;
  }
  return false;
}

/**
 * User-only derivation (PATH A / PATH C). Does not accept V2 proof.
 *
 * @param {Record<string, unknown>|null|undefined} data
 * @returns {boolean}
 */
function deriveDiscoverEligible(data) {
  return deriveDiscoverEligibleWithAssessmentProof(data, {
    frequencyV2Result: { ok: false, code: 'not_consulted' },
  });
}

/**
 * Shared V1 / V2 / grandfather derivation.
 *
 * @param {Record<string, unknown>|null|undefined} data
 * @param {{ frequencyV2Result?: { ok?: boolean }|null }} [proof]
 * @returns {boolean}
 */
function deriveDiscoverEligibleWithAssessmentProof(data, proof) {
  if (!data || typeof data !== 'object') return false;

  if (data.account_deletion_requested === true) return false;
  if (data.active !== true) return false;
  if (data.profile_completed !== true) return false;
  if (!hasValidPhoto(data)) return false;

  const parsed = proof && proof.frequencyV2Result;
  if (!hasTrustedAssessmentDiscoverGrantWithProof(data, parsed)) return false;
  return true;
}

/**
 * Decide whether the trusted writer should update `discover_eligible`.
 *
 * Writes only when the derived value differs from the stored flag — this
 * stops onWrite → update → onWrite loops.
 *
 * @param {Record<string, unknown>|null|undefined} beforeData
 * @param {Record<string, unknown>|null|undefined} afterData
 * @returns {{ shouldWrite: boolean, derived: boolean, previous: boolean|undefined }}
 */
function planDiscoverEligibleWrite(beforeData, afterData) {
  return planDiscoverEligibleWriteWithProof(beforeData, afterData, {
    frequencyV2Result: { ok: false, code: 'not_consulted' },
  });
}

/**
 * @param {Record<string, unknown>|null|undefined} beforeData
 * @param {Record<string, unknown>|null|undefined} afterData
 * @param {{ frequencyV2Result?: { ok?: boolean }|null }} [proof]
 */
function planDiscoverEligibleWriteWithProof(beforeData, afterData, proof) {
  void beforeData;
  const derived = deriveDiscoverEligibleWithAssessmentProof(afterData, proof);
  const stored =
    afterData && typeof afterData === 'object'
      ? afterData.discover_eligible
      : undefined;
  return {
    shouldWrite: stored !== derived,
    derived,
    previous: typeof stored === 'boolean' ? stored : undefined,
  };
}

/**
 * Whether any eligibility-relevant field changed between snapshots.
 *
 * @param {Record<string, unknown>|null|undefined} beforeData
 * @param {Record<string, unknown>|null|undefined} afterData
 * @returns {boolean}
 */
function relevantFieldsChanged(beforeData, afterData) {
  const before = beforeData && typeof beforeData === 'object' ? beforeData : {};
  const after = afterData && typeof afterData === 'object' ? afterData : {};
  for (const key of RELEVANT_KEYS) {
    if (JSON.stringify(before[key]) !== JSON.stringify(after[key])) {
      return true;
    }
  }
  return false;
}

module.exports = {
  RELEVANT_KEYS,
  ASSESSMENT_GRANT_POLICY_VERSION,
  hasValidPhoto,
  isTrustedFrequencyV2Proof,
  hasTrustedAssessmentDiscoverGrant,
  hasTrustedAssessmentDiscoverGrantWithProof,
  deriveDiscoverEligible,
  deriveDiscoverEligibleWithAssessmentProof,
  planDiscoverEligibleWrite,
  planDiscoverEligibleWriteWithProof,
  relevantFieldsChanged,
};
