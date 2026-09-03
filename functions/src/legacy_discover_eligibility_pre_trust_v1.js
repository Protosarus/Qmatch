/**
 * Frozen PRE-TRUST Discover eligibility (`legacy_discover_eligibility_pre_trust_v1`).
 *
 * Exact historical formula used by the completed 7G grandfather migration.
 * Must not track live Discover after the trusted-assessment cutover.
 *
 * This module is self-contained. It must not import
 * `discover_eligibility.js` or any other live eligibility helper.
 *
 *   active == true &&
 *   (test_completed == true || assessment_flow_completed == true) &&
 *   profile_completed == true &&
 *   legacyHasValidPhoto &&
 *   account_deletion_requested != true
 *
 * Pure — no I/O.
 */

'use strict';

/**
 * Frozen PRE-TRUST photo rule. Independent of live Discover eligibility.
 *
 * Valid photo if:
 * - `profile_photo_url` is a non-empty trimmed string, OR
 * - `photos` contains at least one non-empty trimmed string
 *
 * @param {Record<string, unknown>|null|undefined} data
 * @returns {boolean}
 */
function legacyHasValidPhoto(data) {
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
function deriveLegacyDiscoverEligiblePreTrust(data) {
  if (!data || typeof data !== 'object') return false;
  if (data.account_deletion_requested === true) return false;
  if (data.active !== true) return false;
  if (data.profile_completed !== true) return false;
  const assessmentsDone =
    data.test_completed === true || data.assessment_flow_completed === true;
  if (!assessmentsDone) return false;
  if (!legacyHasValidPhoto(data)) return false;
  return true;
}

module.exports = {
  legacyHasValidPhoto,
  deriveLegacyDiscoverEligiblePreTrust,
};
