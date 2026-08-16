/**
 * Exact port of Dart
 * `Canonical20dGroupNormalizedShadowMatcher.compareMeasuredPresence`
 * scoring_version: canonical_20d_group_normalized_shadow_distance_v1
 *
 * Do not change weights, IDs, or missing-data rules.
 */

'use strict';

const SCORING_VERSION = 'canonical_20d_group_normalized_shadow_distance_v1';
const POLICY_VERSION = 'structural_matching_production_candidate_policy_v1';
const POLICY_STATUS = 'production_candidate_not_live';
const REGISTRY_VERSION = 'canonical_dimension_registry_v1';

const IQ_IDS = Object.freeze([
  'logical_reasoning',
  'pattern_reasoning',
  'verbal_reasoning',
  'spatial_reasoning',
]);
const EQ_IDS = Object.freeze([
  'empathy',
  'perspective_taking',
  'self_awareness',
  'emotion_regulation',
  'emotional_openness',
  'boundary_setting',
  'assertiveness',
  'conflict_approach',
  'repair_orientation',
  'social_awareness',
]);
const FREQUENCY_IDS = Object.freeze([
  'depth_preference',
  'social_energy',
  'spontaneity',
  'stability',
  'disclosure_pace',
  'communication_pace',
]);

const DIMENSION_IDS = Object.freeze([...IQ_IDS, ...EQ_IDS, ...FREQUENCY_IDS]);
const DIMENSION_SET = new Set(DIMENSION_IDS);

const IQ_WEIGHT = 0.133333;
const EQ_WEIGHT = 0.400000;
const FREQUENCY_WEIGHT = 0.466667;

const TOTAL_REGISTRY = 20;

/**
 * @param {unknown} raw
 * @returns {number|null}
 */
function validMeasuredScore(raw) {
  if (raw == null) return null;
  if (typeof raw !== 'number' || !Number.isFinite(raw)) return null;
  if (raw < 0.0 || raw > 1.0) return null;
  return raw;
}

/**
 * @param {string} moduleId
 * @param {readonly string[]} dimensionIds
 * @param {number} configuredWeight
 * @param {Record<string, number>} a
 * @param {Record<string, number>} b
 */
function moduleDistance(moduleId, dimensionIds, configuredWeight, a, b) {
  let sumSq = 0.0;
  let n = 0;
  for (const id of dimensionIds) {
    const muA = validMeasuredScore(a[id]);
    const muB = validMeasuredScore(b[id]);
    if (muA == null || muB == null) continue;
    const delta = muA - muB;
    sumSq += delta * delta;
    n += 1;
  }

  const registryCount = dimensionIds.length;
  const coverage = registryCount === 0 ? 0.0 : n / registryCount;
  if (n === 0) {
    return {
      moduleId,
      available: false,
      distanceSquared: null,
      distance: null,
      comparableDimensionCount: 0,
      registryDimensionCount: registryCount,
      coverage: 0.0,
      configuredWeight,
      effectiveWeight: 0.0,
    };
  }

  const d2 = sumSq / n;
  return {
    moduleId,
    available: true,
    distanceSquared: d2,
    distance: Math.sqrt(d2),
    comparableDimensionCount: n,
    registryDimensionCount: registryCount,
    coverage,
    configuredWeight,
    effectiveWeight: 0.0,
  };
}

/**
 * @param {Record<string, number>} a
 * @param {Record<string, number>} b
 */
function compareMeasuredPresence(a, b) {
  const iq = moduleDistance('iq', IQ_IDS, IQ_WEIGHT, a, b);
  const eq = moduleDistance('eq', EQ_IDS, EQ_WEIGHT, a, b);
  const frequency = moduleDistance(
    'frequency',
    FREQUENCY_IDS,
    FREQUENCY_WEIGHT,
    a,
    b,
  );

  const availableModules = [iq, eq, frequency].filter((m) => m.available);
  const totalComparable =
    iq.comparableDimensionCount +
    eq.comparableDimensionCount +
    frequency.comparableDimensionCount;
  const totalCoverage = totalComparable / TOTAL_REGISTRY;

  const base = {
    scoringVersion: SCORING_VERSION,
    registryVersion: REGISTRY_VERSION,
    policyVersion: POLICY_VERSION,
    policyStatus: POLICY_STATUS,
    weightsFrozen: true,
    provisional: false,
    shadowOnly: true,
  };

  if (availableModules.length === 0) {
    return {
      available: false,
      iq,
      eq,
      frequency,
      combinedDistanceSquared: null,
      combinedDistance: null,
      totalComparableDimensionCount: 0,
      totalRegistryDimensionCount: TOTAL_REGISTRY,
      totalCoverage: 0.0,
      ...base,
    };
  }

  const weightSum = availableModules.reduce(
    (s, m) => s + m.configuredWeight,
    0.0,
  );

  let combinedSq = 0.0;
  function withEffective(m) {
    if (!m.available || weightSum <= 0) return m;
    const effective = m.configuredWeight / weightSum;
    combinedSq += effective * m.distanceSquared;
    return { ...m, effectiveWeight: effective };
  }

  const iqOut = withEffective(iq);
  const eqOut = withEffective(eq);
  const freqOut = withEffective(frequency);

  return {
    available: true,
    iq: iqOut,
    eq: eqOut,
    frequency: freqOut,
    combinedDistanceSquared: combinedSq,
    combinedDistance: Math.sqrt(combinedSq),
    totalComparableDimensionCount: totalComparable,
    totalRegistryDimensionCount: TOTAL_REGISTRY,
    totalCoverage,
    ...base,
  };
}

/**
 * Parse `users/{uid}/profiles/canonical_v1` the same way as
 * DiscoverCanonical20dShadowSubjectBuilder.fromCanonicalProfile.
 * @param {Record<string, unknown>|null|undefined} profile
 * @returns {Record<string, number>|null}
 */
function measuredScoresFromCanonicalProfile(profile) {
  if (!profile || typeof profile !== 'object') return null;
  const rows = profile.measured_dimensions;
  if (!Array.isArray(rows) || rows.length === 0) return null;

  const scores = {};
  for (const row of rows) {
    if (!row || typeof row !== 'object') continue;
    if (row.measurement_state !== 'measured') continue;
    const id = row.dimension_id;
    if (typeof id !== 'string' || !DIMENSION_SET.has(id)) continue;
    const value = row.value;
    const numeric =
      typeof value === 'number'
        ? value
        : null;
    if (numeric == null || !Number.isFinite(numeric)) continue;
    if (numeric < 0.0 || numeric > 1.0) continue;
    scores[id] = numeric;
  }
  if (Object.keys(scores).length === 0) return null;
  return scores;
}

module.exports = {
  SCORING_VERSION,
  POLICY_VERSION,
  POLICY_STATUS,
  IQ_IDS,
  EQ_IDS,
  FREQUENCY_IDS,
  DIMENSION_IDS,
  IQ_WEIGHT,
  EQ_WEIGHT,
  FREQUENCY_WEIGHT,
  validMeasuredScore,
  compareMeasuredPresence,
  measuredScoresFromCanonicalProfile,
};
