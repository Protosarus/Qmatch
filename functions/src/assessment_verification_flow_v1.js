'use strict';

/**
 * Trusted assessment_verification_v1 flow derivation.
 *
 * Modules count as trusted when status is verified or grandfathered.
 * Preserved grant flows are never downgraded by a weaker derived progression.
 * Pure: no Firebase I/O.
 */

const TRUSTED_MODULE_STATUSES = new Set(['verified', 'grandfathered']);
const PRESERVED_GRANT_FLOWS = new Set([
  'complete',
  'legacy_iq_eq',
  'pre_c2_preserved',
]);

const FLOW_RANK = Object.freeze({
  none: 0,
  iq: 1,
  iq_eq: 2,
  legacy_iq_eq: 2,
  complete: 3,
  pre_c2_preserved: 3,
});

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function moduleIsTrusted(mod) {
  return isPlainObject(mod) && TRUSTED_MODULE_STATUSES.has(mod.status);
}

function deriveProgressionFlow(verification) {
  const map = isPlainObject(verification) ? verification : {};
  const iq = moduleIsTrusted(map.iq);
  const eq = moduleIsTrusted(map.eq);
  const frequency = moduleIsTrusted(map.frequency);
  if (iq && eq && frequency) return 'complete';
  if (iq && eq) return 'iq_eq';
  if (iq) return 'iq';
  return 'none';
}

function resolveTrustedFlow(existingFlow, derivedFlow) {
  const existing = typeof existingFlow === 'string' ? existingFlow : 'none';
  const derived = typeof derivedFlow === 'string' ? derivedFlow : 'none';
  if (PRESERVED_GRANT_FLOWS.has(existing)) {
    const existingRank = FLOW_RANK[existing] || 0;
    const derivedRank = FLOW_RANK[derived] || 0;
    if (derivedRank > existingRank) return derived;
    return existing;
  }
  return derived;
}

function preserveGrantReason(existing, resolvedFlow, source) {
  if (
    PRESERVED_GRANT_FLOWS.has(resolvedFlow) &&
    existing &&
    typeof existing.grant_reason === 'string' &&
    existing.grant_reason.trim() !== ''
  ) {
    return existing.grant_reason;
  }
  if (typeof source === 'string' && source.trim() !== '') {
    return source;
  }
  return 'admin_finalize_iq_v1';
}

module.exports = {
  TRUSTED_MODULE_STATUSES,
  PRESERVED_GRANT_FLOWS,
  FLOW_RANK,
  moduleIsTrusted,
  deriveProgressionFlow,
  resolveTrustedFlow,
  preserveGrantReason,
};
