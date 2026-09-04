/**
 * Versioned Frequency V2 compatibility fusion (Phase 8B.2).
 *
 * Pure module. Does not access Firestore. Does not rank Discover.
 * Frequency V1 is never an input.
 */

'use strict';

const {
  IQ_WEIGHT,
  EQ_WEIGHT,
  IQ_EQ_WEIGHT_SUM,
} = require('./canonical_20d_group_normalized_shadow');

const POLICY_VERSION = 'qmatch_compatibility_fusion_v2_policy_v1';
const SCHEMA_VERSION = 'qmatch_compatibility_fusion_v2_schema_v1';

const NON_FREQUENCY_STRUCTURAL_WEIGHT = 0.5;
const FREQUENCY_V2_WEIGHT = 0.5;

if (
  Math.abs(
    NON_FREQUENCY_STRUCTURAL_WEIGHT + FREQUENCY_V2_WEIGHT - 1.0,
  ) > 1e-12
) {
  throw new Error('fusion_weights_must_sum_to_1');
}

const COMPATIBILITY_V2_PUBLIC_KEYS = Object.freeze([
  'available',
  'compatibility_index',
  'policy_version',
  'structural_fit',
  'frequency_fit',
  'structural_coverage',
  'frequency_pair_support',
  'unavailable_reason',
]);

function clamp01(value) {
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}

function isFiniteNumber(value) {
  return typeof value === 'number' && Number.isFinite(value);
}

function inClosedUnit(value) {
  return isFiniteNumber(value) && value >= 0 && value <= 1;
}

function derivedIqShareOfStructuralHalf() {
  return IQ_WEIGHT / IQ_EQ_WEIGHT_SUM;
}

function derivedEqShareOfStructuralHalf() {
  return EQ_WEIGHT / IQ_EQ_WEIGHT_SUM;
}

function derivedIqShareOfFinal() {
  return NON_FREQUENCY_STRUCTURAL_WEIGHT * derivedIqShareOfStructuralHalf();
}

function derivedEqShareOfFinal() {
  return NON_FREQUENCY_STRUCTURAL_WEIGHT * derivedEqShareOfStructuralHalf();
}

function nonFrequencyStructuralFitFromDistance(distance) {
  if (!isFiniteNumber(distance)) return null;
  return clamp01(1 - distance);
}

function frequencyV2UnavailableReason(frequencyV2) {
  if (frequencyV2 == null || typeof frequencyV2 !== 'object') {
    return 'frequency_v2_unavailable';
  }
  if (frequencyV2.available === false || frequencyV2.ok === false) {
    if (typeof frequencyV2.unavailable_reason === 'string') {
      return frequencyV2.unavailable_reason;
    }
    return 'frequency_v2_unavailable';
  }
  if (!inClosedUnit(frequencyV2.overall_supported_fit)) {
    return 'frequency_v2_unavailable';
  }
  return null;
}

function fuseCompatibilityV2(structural, frequencyV2) {
  const v2Reason = frequencyV2UnavailableReason(frequencyV2);
  if (v2Reason) {
    return unavailableFusion(v2Reason);
  }

  if (
    !structural ||
    structural.available !== true ||
    !isFiniteNumber(structural.combinedDistance)
  ) {
    return unavailableFusion('non_frequency_structural_unavailable');
  }

  const structuralFit = nonFrequencyStructuralFitFromDistance(
    structural.combinedDistance,
  );
  if (structuralFit == null) {
    return unavailableFusion('non_frequency_structural_unavailable');
  }

  const frequencyFit = frequencyV2.overall_supported_fit;
  const finalFit =
    NON_FREQUENCY_STRUCTURAL_WEIGHT * structuralFit +
    FREQUENCY_V2_WEIGHT * frequencyFit;
  const clampedFit = clamp01(finalFit);

  return {
    available: true,
    policy_version: POLICY_VERSION,
    schema_version: SCHEMA_VERSION,
    final_fit: clampedFit,
    compatibility_index: 100 * clampedFit,
    non_frequency_structural_fit: structuralFit,
    frequency_v2_fit: frequencyFit,
    structural_coverage: isFiniteNumber(structural.totalCoverage)
      ? structural.totalCoverage
      : 0,
    frequency_pair_support: inClosedUnit(frequencyV2.overall_pair_support)
      ? frequencyV2.overall_pair_support
      : null,
  };
}

function unavailableFusion(reason) {
  return {
    available: false,
    policy_version: POLICY_VERSION,
    schema_version: SCHEMA_VERSION,
    final_fit: null,
    compatibility_index: null,
    non_frequency_structural_fit: null,
    frequency_v2_fit: null,
    structural_coverage: null,
    frequency_pair_support: null,
    unavailable_reason: reason,
  };
}

function sanitizeCompatibilityV2Public(pair) {
  const out = {};
  for (const key of COMPATIBILITY_V2_PUBLIC_KEYS) {
    if (pair[key] !== undefined) out[key] = pair[key];
  }
  return out;
}

function publicCompatibilityV2(fusion) {
  if (!fusion || fusion.available !== true) {
    return sanitizeCompatibilityV2Public({
      available: false,
      policy_version: POLICY_VERSION,
      unavailable_reason:
        (fusion && fusion.unavailable_reason) ||
        'frequency_v2_unavailable',
    });
  }
  return sanitizeCompatibilityV2Public({
    available: true,
    compatibility_index: fusion.compatibility_index,
    policy_version: fusion.policy_version,
    structural_fit: fusion.non_frequency_structural_fit,
    frequency_fit: fusion.frequency_v2_fit,
    structural_coverage: fusion.structural_coverage,
    frequency_pair_support: fusion.frequency_pair_support,
  });
}

module.exports = {
  POLICY_VERSION,
  SCHEMA_VERSION,
  NON_FREQUENCY_STRUCTURAL_WEIGHT,
  FREQUENCY_V2_WEIGHT,
  COMPATIBILITY_V2_PUBLIC_KEYS,
  clamp01,
  derivedIqShareOfStructuralHalf,
  derivedEqShareOfStructuralHalf,
  derivedIqShareOfFinal,
  derivedEqShareOfFinal,
  nonFrequencyStructuralFitFromDistance,
  fuseCompatibilityV2,
  publicCompatibilityV2,
  sanitizeCompatibilityV2Public,
};
