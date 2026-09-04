'use strict';

const assert = require('assert');
const {
  IQ_IDS,
  EQ_IDS,
  FREQUENCY_IDS,
  DIMENSION_IDS,
  IQ_WEIGHT,
  EQ_WEIGHT,
  FREQUENCY_WEIGHT,
  SCORING_VERSION,
  POLICY_STATUS,
  compareMeasuredPresence,
  compareIqEqMeasuredPresence,
  measuredScoresFromCanonicalProfile,
  IQ_EQ_REGISTRY,
  IQ_EQ_WEIGHT_SUM,
} = require('../src/canonical_20d_group_normalized_shadow');

function fill(ids, v) {
  const out = {};
  for (const id of ids) out[id] = v;
  return out;
}

describe('canonical_20d_group_normalized_shadow_distance_v1 Dart parity', () => {
  it('frozen IDs and weights match Dart contract', () => {
    assert.deepStrictEqual(IQ_IDS, [
      'logical_reasoning',
      'pattern_reasoning',
      'verbal_reasoning',
      'spatial_reasoning',
    ]);
    assert.strictEqual(EQ_IDS.length, 10);
    assert.strictEqual(FREQUENCY_IDS.length, 6);
    assert.strictEqual(DIMENSION_IDS.length, 20);
    assert.strictEqual(IQ_WEIGHT, 0.133333);
    assert.strictEqual(EQ_WEIGHT, 0.400000);
    assert.strictEqual(FREQUENCY_WEIGHT, 0.466667);
    assert.ok(Math.abs(IQ_WEIGHT + EQ_WEIGHT + FREQUENCY_WEIGHT - 1.0) < 1e-9);
    assert.strictEqual(
      SCORING_VERSION,
      'canonical_20d_group_normalized_shadow_distance_v1',
    );
    assert.strictEqual(POLICY_STATUS, 'production_candidate_not_live');
  });

  it('identical profiles → combined distance 0, full coverage', () => {
    const a = fill(DIMENSION_IDS, 0.42);
    const r = compareMeasuredPresence(a, { ...a });
    assert.strictEqual(r.available, true);
    assert.strictEqual(r.combinedDistance, 0.0);
    assert.strictEqual(r.combinedDistanceSquared, 0.0);
    assert.strictEqual(r.iq.distance, 0.0);
    assert.strictEqual(r.eq.distance, 0.0);
    assert.strictEqual(r.frequency.distance, 0.0);
    assert.strictEqual(r.totalComparableDimensionCount, 20);
    assert.strictEqual(r.totalCoverage, 1.0);
    assert.ok(
      Math.abs(
        r.iq.effectiveWeight + r.eq.effectiveWeight + r.frequency.effectiveWeight - 1.0,
      ) < 1e-9,
    );
  });

  it('Frequency-dominant disagreement weighs Frequency more than equal-20D', () => {
    const me = {
      ...fill(IQ_IDS, 0.5),
      ...fill(EQ_IDS, 0.5),
      ...fill(FREQUENCY_IDS, 0.1),
    };
    const other = {
      ...fill(IQ_IDS, 0.5),
      ...fill(EQ_IDS, 0.5),
      ...fill(FREQUENCY_IDS, 0.9),
    };
    const group = compareMeasuredPresence(me, other);
    assert.strictEqual(group.iq.distanceSquared, 0.0);
    assert.strictEqual(group.eq.distanceSquared, 0.0);
    assert.ok(Math.abs(group.frequency.distanceSquared - 0.64) < 1e-12);
    assert.ok(
      Math.abs(group.combinedDistanceSquared - FREQUENCY_WEIGHT * 0.64) < 1e-9,
    );
    const equalD2 = (6 / 20) * 0.64;
    assert.ok(group.combinedDistanceSquared > equalD2);
  });

  it('EQ-dominant disagreement applies EQ module weight (below equal-20D)', () => {
    const me = {
      ...fill(IQ_IDS, 0.5),
      ...fill(EQ_IDS, 0.1),
      ...fill(FREQUENCY_IDS, 0.5),
    };
    const other = {
      ...fill(IQ_IDS, 0.5),
      ...fill(EQ_IDS, 0.9),
      ...fill(FREQUENCY_IDS, 0.5),
    };
    const group = compareMeasuredPresence(me, other);
    assert.ok(Math.abs(group.eq.distanceSquared - 0.64) < 1e-12);
    assert.strictEqual(group.iq.distanceSquared, 0.0);
    assert.strictEqual(group.frequency.distanceSquared, 0.0);
    assert.ok(Math.abs(group.combinedDistanceSquared - EQ_WEIGHT * 0.64) < 1e-9);
    const equalD2 = (10 / 20) * 0.64;
    assert.ok(group.combinedDistanceSquared < equalD2);
  });

  it('missing module omits and renormalizes remaining weights', () => {
    const me = {
      ...fill(IQ_IDS, 0.2),
      ...fill(EQ_IDS, 0.2),
    };
    FREQUENCY_IDS.slice(0, 3).forEach((id) => {
      me[id] = 0.2;
    });
    const other = {
      ...fill(IQ_IDS, 0.8),
      ...fill(EQ_IDS, 0.8),
    };
    FREQUENCY_IDS.slice(3).forEach((id) => {
      other[id] = 0.8;
    });

    const r = compareMeasuredPresence(me, other);
    assert.strictEqual(r.frequency.available, false);
    assert.strictEqual(r.frequency.effectiveWeight, 0.0);
    assert.strictEqual(r.iq.available, true);
    assert.strictEqual(r.eq.available, true);
    const sum = IQ_WEIGHT + EQ_WEIGHT;
    assert.ok(Math.abs(r.iq.effectiveWeight - IQ_WEIGHT / sum) < 1e-12);
    assert.ok(Math.abs(r.eq.effectiveWeight - EQ_WEIGHT / sum) < 1e-12);
    assert.ok(
      Math.abs(r.iq.effectiveWeight + r.eq.effectiveWeight - 1.0) < 1e-12,
    );
    assert.ok(Math.abs(r.iq.distanceSquared - 0.36) < 1e-12);
    assert.ok(Math.abs(r.eq.distanceSquared - 0.36) < 1e-12);
    assert.ok(Math.abs(r.combinedDistanceSquared - 0.36) < 1e-12);
    assert.ok(Math.abs(r.combinedDistance - Math.sqrt(0.36)) < 1e-12);
  });

  it('symmetry A↔B', () => {
    const a = {};
    const b = {};
    DIMENSION_IDS.forEach((id, i) => {
      a[id] = (i % 5) / 4.0;
      b[id] = ((i + 3) % 7) / 6.0;
    });
    const ab = compareMeasuredPresence(a, b);
    const ba = compareMeasuredPresence(b, a);
    assert.strictEqual(ab.combinedDistanceSquared, ba.combinedDistanceSquared);
    assert.strictEqual(ab.combinedDistance, ba.combinedDistance);
    assert.strictEqual(ab.iq.distanceSquared, ba.iq.distanceSquared);
    assert.strictEqual(ab.eq.distanceSquared, ba.eq.distanceSquared);
    assert.strictEqual(ab.frequency.distanceSquared, ba.frequency.distanceSquared);
    assert.strictEqual(ab.totalCoverage, ba.totalCoverage);
  });

  it('no shared modules → unavailable, not a 0.5 fill', () => {
    const a = fill(IQ_IDS, 0.4);
    const b = fill(EQ_IDS, 0.4);
    const r = compareMeasuredPresence(a, b);
    assert.strictEqual(r.available, false);
    assert.strictEqual(r.combinedDistance, null);
    assert.strictEqual(r.combinedDistanceSquared, null);
    assert.strictEqual(r.totalCoverage, 0.0);
  });

  it('out-of-range scores are excluded, never imputed', () => {
    const a = { logical_reasoning: 1.2, empathy: 0.4 };
    const b = { logical_reasoning: 0.5, empathy: 0.4 };
    const r = compareMeasuredPresence(a, b);
    assert.strictEqual(r.iq.available, false);
    assert.strictEqual(r.eq.available, true);
    assert.strictEqual(r.eq.distanceSquared, 0.0);
  });

  it('canonical_v1 parse skips unmeasured / unknown ids', () => {
    const scores = measuredScoresFromCanonicalProfile({
      measured_dimensions: [
        {
          dimension_id: 'empathy',
          measurement_state: 'measured',
          value: 0.3,
        },
        {
          dimension_id: 'empathy',
          measurement_state: 'not_measured',
          value: 0.9,
        },
        {
          dimension_id: 'not_a_dim',
          measurement_state: 'measured',
          value: 0.5,
        },
      ],
    });
    assert.deepStrictEqual(scores, { empathy: 0.3 });
    assert.strictEqual(measuredScoresFromCanonicalProfile(null), null);
    assert.strictEqual(
      measuredScoresFromCanonicalProfile({ measured_dimensions: [] }),
      null,
    );
  });
});

describe('compareIqEqMeasuredPresence (Frequency V1 excluded)', () => {
  it('derived IQ/EQ weights renormalize over frozen IQ+EQ only', () => {
    assert.strictEqual(IQ_EQ_REGISTRY, 14);
    assert.ok(Math.abs(IQ_EQ_WEIGHT_SUM - (IQ_WEIGHT + EQ_WEIGHT)) < 1e-12);
    const a = { ...fill(IQ_IDS, 0.5), ...fill(EQ_IDS, 0.5) };
    const r = compareIqEqMeasuredPresence(a, { ...a });
    assert.strictEqual(r.available, true);
    assert.strictEqual(r.frequency, undefined);
    assert.strictEqual(r.frequencyExcluded, true);
    assert.strictEqual(r.combinedDistance, 0.0);
    assert.strictEqual(r.totalComparableDimensionCount, 14);
    assert.strictEqual(r.totalRegistryDimensionCount, 14);
    assert.strictEqual(r.totalCoverage, 1.0);
    assert.ok(
      Math.abs(r.iq.effectiveWeight - IQ_WEIGHT / IQ_EQ_WEIGHT_SUM) < 1e-12,
    );
    assert.ok(
      Math.abs(r.eq.effectiveWeight - EQ_WEIGHT / IQ_EQ_WEIGHT_SUM) < 1e-12,
    );
    assert.ok(Math.abs(r.iq.effectiveWeight + r.eq.effectiveWeight - 1) < 1e-12);
  });

  it('identical IQ/EQ with opposite V1 Frequency stay structurally identical', () => {
    const iqEq = { ...fill(IQ_IDS, 0.4), ...fill(EQ_IDS, 0.6) };
    const a = { ...iqEq, ...fill(FREQUENCY_IDS, 0.05) };
    const b = { ...iqEq, ...fill(FREQUENCY_IDS, 0.95) };
    const iqeq = compareIqEqMeasuredPresence(a, b);
    const full = compareMeasuredPresence(a, b);
    assert.strictEqual(iqeq.available, true);
    assert.strictEqual(iqeq.combinedDistance, 0.0);
    assert.strictEqual(iqeq.iq.distance, 0.0);
    assert.strictEqual(iqeq.eq.distance, 0.0);
    assert.ok(full.combinedDistance > 0);
    assert.ok(full.frequency.distance > 0);
  });

  it('existing 20D compareMeasuredPresence is unchanged by Frequency disagreement', () => {
    const me = {
      ...fill(IQ_IDS, 0.5),
      ...fill(EQ_IDS, 0.5),
      ...fill(FREQUENCY_IDS, 0.1),
    };
    const other = {
      ...fill(IQ_IDS, 0.5),
      ...fill(EQ_IDS, 0.5),
      ...fill(FREQUENCY_IDS, 0.9),
    };
    const group = compareMeasuredPresence(me, other);
    assert.ok(Math.abs(group.combinedDistanceSquared - FREQUENCY_WEIGHT * 0.64) < 1e-9);
  });

  it('IQ missing / EQ present renormalizes the structural half onto EQ', () => {
    const a = fill(EQ_IDS, 0.2);
    const b = fill(EQ_IDS, 0.8);
    const r = compareIqEqMeasuredPresence(a, b);
    assert.strictEqual(r.available, true);
    assert.strictEqual(r.iq.available, false);
    assert.strictEqual(r.eq.available, true);
    assert.strictEqual(r.eq.effectiveWeight, 1.0);
    assert.ok(Math.abs(r.eq.distanceSquared - 0.36) < 1e-12);
    assert.ok(Math.abs(r.combinedDistanceSquared - 0.36) < 1e-12);
    assert.strictEqual(r.totalComparableDimensionCount, 10);
    assert.ok(Math.abs(r.totalCoverage - 10 / 14) < 1e-12);
  });

  it('EQ missing / IQ present renormalizes the structural half onto IQ', () => {
    const a = fill(IQ_IDS, 0.1);
    const b = fill(IQ_IDS, 0.9);
    const r = compareIqEqMeasuredPresence(a, b);
    assert.strictEqual(r.available, true);
    assert.strictEqual(r.eq.available, false);
    assert.strictEqual(r.iq.available, true);
    assert.strictEqual(r.iq.effectiveWeight, 1.0);
    assert.ok(Math.abs(r.iq.distanceSquared - 0.64) < 1e-12);
    assert.ok(Math.abs(r.combinedDistanceSquared - 0.64) < 1e-12);
    assert.strictEqual(r.totalComparableDimensionCount, 4);
    assert.ok(Math.abs(r.totalCoverage - 4 / 14) < 1e-12);
  });

  it('IQ+EQ both missing is unavailable and does not impute', () => {
    const a = fill(FREQUENCY_IDS, 0.1);
    const b = fill(FREQUENCY_IDS, 0.9);
    const r = compareIqEqMeasuredPresence(a, b);
    assert.strictEqual(r.available, false);
    assert.strictEqual(r.combinedDistance, null);
    assert.strictEqual(r.combinedDistanceSquared, null);
    assert.strictEqual(r.totalCoverage, 0.0);
    const full = compareMeasuredPresence(a, b);
    assert.strictEqual(full.available, true);
  });

  it('max IQ/EQ gap has combined distance 1', () => {
    const a = { ...fill(IQ_IDS, 0.0), ...fill(EQ_IDS, 0.0) };
    const b = { ...fill(IQ_IDS, 1.0), ...fill(EQ_IDS, 1.0) };
    const r = compareIqEqMeasuredPresence(a, b);
    assert.strictEqual(r.available, true);
    assert.ok(Math.abs(r.combinedDistance - 1.0) < 1e-12);
    assert.ok(r.combinedDistance <= 1.0);
  });
});
