/**
 * Trusted Discover eligibility derivation (`trusted_discover_eligibility_authority_v1`).
 *
 * Canonical:
 *   account_deletion_requested != true &&
 *   active == true &&
 *   profile_completed == true &&
 *   hasValidPhoto &&
 *   hasTrustedAssessmentDiscoverGrant
 *
 * Assessment grant is Admin-owned verification only:
 *   trusted IQ + EQ + Frequency V1 modules
 *   OR pre_c2_preserved + pre_trust_migration_preserved
 *
 * Client flags (test_completed / assessment_flow_completed) and
 * flow=complete alone are not proof. Frequency V2 is not a grant path.
 *
 * Missing required data => false.
 * Deletion soft-marker or inactive => false.
 *
 * Pure helpers only — no I/O. Safe for unit tests and Cloud Functions.
 */

'use strict';

const {
  hasTrustedV1Battery,
  hasPreTrustMigrationGrant,
} = require('./assessment_verification_flow_v1');

/** Fields that can change derived discover_eligible. */
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

/**
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
 * @returns {boolean}
 */
function deriveDiscoverEligible(data) {
  if (!data || typeof data !== 'object') return false;

  // Soft deletion / leave Discover immediately.
  if (data.account_deletion_requested === true) return false;

  // Strict: missing active is not eligible.
  if (data.active !== true) return false;
  if (data.profile_completed !== true) return false;
  if (!hasValidPhoto(data)) return false;
  if (!hasTrustedAssessmentDiscoverGrant(data)) return false;

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
  void beforeData;
  const derived = deriveDiscoverEligible(afterData);
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
  hasValidPhoto,
  hasTrustedAssessmentDiscoverGrant,
  deriveDiscoverEligible,
  planDiscoverEligibleWrite,
  relevantFieldsChanged,
};
