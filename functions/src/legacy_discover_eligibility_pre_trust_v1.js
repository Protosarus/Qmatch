/**
 * Frozen PRE-TRUST Discover eligibility (`legacy_discover_eligibility_pre_trust_v1`).
 *
 * Exact historical formula used by the completed 7G grandfather migration.
 * Must not track live Discover after the trusted-assessment cutover.
 *
 *   active == true &&
 *   (test_completed == true || assessment_flow_completed == true) &&
 *   profile_completed == true &&
 *   hasValidPhoto &&
 *   account_deletion_requested != true
 *
 * Pure — no I/O.
 */

'use strict';

const { hasValidPhoto } = require('./discover_eligibility');

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
  if (!hasValidPhoto(data)) return false;
  return true;
}

module.exports = {
  deriveLegacyDiscoverEligiblePreTrust,
};
