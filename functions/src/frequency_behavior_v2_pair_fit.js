/**
 * Server Frequency V2 pair-fit (mirrors Dart FrequencyBehaviorV2PairFitComputer).
 *
 * Uses persisted 12D normalized_behavior + support only.
 * Does not persist pair-fit, 24D state, or density matrices.
 */

'use strict';

const contract = require('./frequency_behavior_v2_contract');

function clamp01(value) {
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}

function policyForDimension(dimensionId) {
  if (contract.PAIR_FIT_LINEAR_POLICY_DIMENSION_SET.has(dimensionId)) {
    return contract.PAIR_FIT_POLICY_SIMILARITY_LINEAR;
  }
  if (contract.PAIR_FIT_TOLERANT_POLICY_DIMENSION_SET.has(dimensionId)) {
    return contract.PAIR_FIT_POLICY_SIMILARITY_TOLERANT;
  }
  throw new Error(`unknown_dimension_policy:${dimensionId}`);
}

function rawFitForPolicy(delta, policyType) {
  const halfDelta = clamp01(delta / 2);
  if (policyType === contract.PAIR_FIT_POLICY_SIMILARITY_LINEAR) {
    return 1 - halfDelta;
  }
  if (policyType === contract.PAIR_FIT_POLICY_SIMILARITY_TOLERANT) {
    return 1 - halfDelta * halfDelta;
  }
  throw new Error(`unknown_policy:${policyType}`);
}

function effectiveSupport(provisionalConfidence, confidenceCompleteness) {
  return provisionalConfidence * confidenceCompleteness;
}

function pairSupport(effectiveSupportA, effectiveSupportB) {
  return Math.sqrt(clamp01(effectiveSupportA * effectiveSupportB));
}

function supportedFit(rawFit, support) {
  return 0.5 + support * (rawFit - 0.5);
}

function dimensionFit(rowA, rowB) {
  const xA = rowA.normalized_behavior;
  const xB = rowB.normalized_behavior;
  const delta = Math.abs(xA - xB);
  const policyType = policyForDimension(rowA.dimension_id);
  const rawFit = rawFitForPolicy(delta, policyType);
  const support = pairSupport(
    effectiveSupport(
      rowA.provisional_confidence,
      rowA.confidence_completeness,
    ),
    effectiveSupport(
      rowB.provisional_confidence,
      rowB.confidence_completeness,
    ),
  );
  return {
    dimension_id: rowA.dimension_id,
    policy_type: policyType,
    raw_fit: rawFit,
    pair_support: support,
    supported_fit: supportedFit(rawFit, support),
  };
}

/**
 * @param {{ byDimension: Record<string, {
 *   dimension_id: string,
 *   normalized_behavior: number,
 *   provisional_confidence: number,
 *   confidence_completeness: number,
 * }> }} userA
 * @param {typeof userA} userB
 */
function fitFromParsedUsers(userA, userB) {
  const dimensions = [];
  let rawSum = 0;
  let supportedSum = 0;
  let supportSum = 0;
  for (const id of contract.CANONICAL_DIMENSIONS) {
    const row = dimensionFit(userA.byDimension[id], userB.byDimension[id]);
    dimensions.push(row);
    rawSum += row.raw_fit;
    supportedSum += row.supported_fit;
    supportSum += row.pair_support;
  }
  const n = contract.DIMENSION_COUNT;
  const overallRawFit = rawSum / n;
  const overallSupportedFit = supportedSum / n;
  const overallPairSupport = supportSum / n;
  return {
    ok: true,
    pair_fit_version: contract.PAIR_FIT_VERSION,
    pair_fit_policy_version: contract.PAIR_FIT_POLICY_VERSION,
    pair_relation_version: contract.PAIR_RELATION_VERSION,
    overall_raw_fit: overallRawFit,
    overall_supported_fit: overallSupportedFit,
    overall_pair_support: overallPairSupport,
    frequency_fit_index: 100 * overallSupportedFit,
    dimensions,
  };
}

const FREQUENCY_V2_PUBLIC_KEYS = Object.freeze([
  'available',
  'frequency_fit_index',
  'overall_supported_fit',
  'overall_pair_support',
  'pair_fit_version',
  'unavailable_reason',
]);

function sanitizeFrequencyV2Public(pair) {
  const out = {};
  for (const key of FREQUENCY_V2_PUBLIC_KEYS) {
    if (pair[key] !== undefined) out[key] = pair[key];
  }
  return out;
}

function publicFrequencyV2Unavailable(reason) {
  return sanitizeFrequencyV2Public({
    available: false,
    pair_fit_version: contract.PAIR_FIT_VERSION,
    unavailable_reason: reason,
  });
}

function publicFrequencyV2FromFit(fit) {
  return sanitizeFrequencyV2Public({
    available: true,
    frequency_fit_index: fit.frequency_fit_index,
    overall_supported_fit: fit.overall_supported_fit,
    overall_pair_support: fit.overall_pair_support,
    pair_fit_version: fit.pair_fit_version,
  });
}

module.exports = {
  clamp01,
  policyForDimension,
  rawFitForPolicy,
  effectiveSupport,
  pairSupport,
  supportedFit,
  dimensionFit,
  fitFromParsedUsers,
  FREQUENCY_V2_PUBLIC_KEYS,
  sanitizeFrequencyV2Public,
  publicFrequencyV2Unavailable,
  publicFrequencyV2FromFit,
};
