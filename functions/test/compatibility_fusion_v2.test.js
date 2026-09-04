'use strict';

const assert = require('assert');
const {
  IQ_IDS,
  EQ_IDS,
  FREQUENCY_IDS,
  IQ_WEIGHT,
  EQ_WEIGHT,
  compareIqEqMeasuredPresence,
  compareMeasuredPresence,
} = require('../src/canonical_20d_group_normalized_shadow');
const {
  POLICY_VERSION,
  SCHEMA_VERSION,
  NON_FREQUENCY_STRUCTURAL_WEIGHT,
  FREQUENCY_V2_WEIGHT,
  COMPATIBILITY_V2_PUBLIC_KEYS,
  derivedIqShareOfStructuralHalf,
  derivedEqShareOfStructuralHalf,
  derivedIqShareOfFinal,
  derivedEqShareOfFinal,
  fuseCompatibilityV2,
  publicCompatibilityV2,
} = require('../src/compatibility_fusion_v2');

function fill(ids, v) {
  const out = {};
  for (const id of ids) out[id] = v;
  return out;
}

function v2Fit(supported, support = 1) {
  return {
    available: true,
    overall_supported_fit: supported,
    overall_pair_support: support,
  };
}

describe('qmatch_compatibility_fusion_v2_policy_v1', () => {
  it('freezes policy, schema, and 50/50 weights', () => {
    assert.strictEqual(POLICY_VERSION, 'qmatch_compatibility_fusion_v2_policy_v1');
    assert.strictEqual(SCHEMA_VERSION, 'qmatch_compatibility_fusion_v2_schema_v1');
    assert.strictEqual(NON_FREQUENCY_STRUCTURAL_WEIGHT, 0.5);
    assert.strictEqual(FREQUENCY_V2_WEIGHT, 0.5);
    assert.strictEqual(
      NON_FREQUENCY_STRUCTURAL_WEIGHT + FREQUENCY_V2_WEIGHT,
      1,
    );
    assert.ok(
      Math.abs(derivedIqShareOfStructuralHalf() - IQ_WEIGHT / (IQ_WEIGHT + EQ_WEIGHT)) <
        1e-12,
    );
    assert.ok(
      Math.abs(derivedEqShareOfStructuralHalf() - EQ_WEIGHT / (IQ_WEIGHT + EQ_WEIGHT)) <
        1e-12,
    );
    assert.ok(Math.abs(derivedIqShareOfFinal() - 0.5 * derivedIqShareOfStructuralHalf()) < 1e-12);
    assert.ok(Math.abs(derivedEqShareOfFinal() - 0.5 * derivedEqShareOfStructuralHalf()) < 1e-12);
    assert.ok(Math.abs(derivedIqShareOfFinal() + derivedEqShareOfFinal() + FREQUENCY_V2_WEIGHT - 1) < 1e-12);
  });

  it('perfect IQ/EQ + perfect V2 → index 100', () => {
    const scores = { ...fill(IQ_IDS, 0.42), ...fill(EQ_IDS, 0.42) };
    const structural = compareIqEqMeasuredPresence(scores, { ...scores });
    const fusion = fuseCompatibilityV2(structural, v2Fit(1, 1));
    assert.strictEqual(fusion.available, true);
    assert.strictEqual(fusion.non_frequency_structural_fit, 1);
    assert.strictEqual(fusion.frequency_v2_fit, 1);
    assert.strictEqual(fusion.final_fit, 1);
    assert.strictEqual(fusion.compatibility_index, 100);
    const pub = publicCompatibilityV2(fusion);
    assert.strictEqual(pub.available, true);
    assert.strictEqual(pub.compatibility_index, 100);
    assert.strictEqual(pub.policy_version, POLICY_VERSION);
    assert.strictEqual(pub.structural_fit, 1);
    assert.strictEqual(pub.frequency_fit, 1);
    assert.strictEqual(pub.unavailable_reason, undefined);
  });

  it('max structural gap + max V2 gap/support → index 0', () => {
    const a = { ...fill(IQ_IDS, 0), ...fill(EQ_IDS, 0) };
    const b = { ...fill(IQ_IDS, 1), ...fill(EQ_IDS, 1) };
    const structural = compareIqEqMeasuredPresence(a, b);
    assert.ok(Math.abs(structural.combinedDistance - 1) < 1e-12);
    const fusion = fuseCompatibilityV2(structural, v2Fit(0, 1));
    assert.strictEqual(fusion.available, true);
    assert.strictEqual(fusion.non_frequency_structural_fit, 0);
    assert.strictEqual(fusion.frequency_v2_fit, 0);
    assert.strictEqual(fusion.final_fit, 0);
    assert.strictEqual(fusion.compatibility_index, 0);
  });

  it('same structural / poor frequency → Frequency contributes exactly 50%', () => {
    const scores = { ...fill(IQ_IDS, 0.5), ...fill(EQ_IDS, 0.5) };
    const structural = compareIqEqMeasuredPresence(scores, { ...scores });
    const fusion = fuseCompatibilityV2(structural, v2Fit(0, 1));
    assert.strictEqual(fusion.non_frequency_structural_fit, 1);
    assert.strictEqual(fusion.frequency_v2_fit, 0);
    assert.strictEqual(fusion.final_fit, 0.5);
    assert.strictEqual(fusion.compatibility_index, 50);
  });

  it('poor structural / same frequency → structural contributes exactly 50%', () => {
    const a = { ...fill(IQ_IDS, 0), ...fill(EQ_IDS, 0) };
    const b = { ...fill(IQ_IDS, 1), ...fill(EQ_IDS, 1) };
    const structural = compareIqEqMeasuredPresence(a, b);
    const fusion = fuseCompatibilityV2(structural, v2Fit(1, 1));
    assert.strictEqual(fusion.non_frequency_structural_fit, 0);
    assert.strictEqual(fusion.frequency_v2_fit, 1);
    assert.strictEqual(fusion.final_fit, 0.5);
    assert.strictEqual(fusion.compatibility_index, 50);
  });

  it('V2 zero support uses supported fit 0.5 (existing V2 policy)', () => {
    const scores = { ...fill(IQ_IDS, 0.3), ...fill(EQ_IDS, 0.3) };
    const structural = compareIqEqMeasuredPresence(scores, { ...scores });
    const fusion = fuseCompatibilityV2(structural, v2Fit(0.5, 0));
    assert.strictEqual(fusion.available, true);
    assert.strictEqual(fusion.frequency_v2_fit, 0.5);
    assert.strictEqual(fusion.frequency_pair_support, 0);
    assert.strictEqual(fusion.final_fit, 0.5 * 1 + 0.5 * 0.5);
    assert.strictEqual(fusion.compatibility_index, 75);
  });

  it('IQ missing / EQ present keeps the structural half via renormalization', () => {
    const structural = compareIqEqMeasuredPresence(
      fill(EQ_IDS, 0.7),
      fill(EQ_IDS, 0.7),
    );
    assert.strictEqual(structural.available, true);
    assert.strictEqual(structural.iq.available, false);
    const fusion = fuseCompatibilityV2(structural, v2Fit(1, 1));
    assert.strictEqual(fusion.available, true);
    assert.strictEqual(fusion.non_frequency_structural_fit, 1);
    assert.ok(Math.abs(fusion.structural_coverage - 10 / 14) < 1e-12);
  });

  it('EQ missing / IQ present keeps the structural half via renormalization', () => {
    const structural = compareIqEqMeasuredPresence(
      fill(IQ_IDS, 0.2),
      fill(IQ_IDS, 0.2),
    );
    assert.strictEqual(structural.available, true);
    assert.strictEqual(structural.eq.available, false);
    const fusion = fuseCompatibilityV2(structural, v2Fit(0.4, 1));
    assert.strictEqual(fusion.available, true);
    assert.strictEqual(fusion.non_frequency_structural_fit, 1);
    assert.strictEqual(fusion.final_fit, 0.5 * 1 + 0.5 * 0.4);
    assert.ok(Math.abs(fusion.structural_coverage - 4 / 14) < 1e-12);
  });

  it('IQ+EQ both missing → final unavailable', () => {
    const structural = compareIqEqMeasuredPresence(
      fill(FREQUENCY_IDS, 0.1),
      fill(FREQUENCY_IDS, 0.9),
    );
    const fusion = fuseCompatibilityV2(structural, v2Fit(1, 1));
    assert.strictEqual(fusion.available, false);
    assert.strictEqual(
      fusion.unavailable_reason,
      'non_frequency_structural_unavailable',
    );
    assert.strictEqual(fusion.compatibility_index, null);
  });

  it('V2 missing → final unavailable (no top-level renormalize)', () => {
    const scores = { ...fill(IQ_IDS, 0.5), ...fill(EQ_IDS, 0.5) };
    const structural = compareIqEqMeasuredPresence(scores, scores);
    const fusion = fuseCompatibilityV2(structural, {
      available: false,
      unavailable_reason: 'viewer_frequency_v2_missing',
    });
    assert.strictEqual(fusion.available, false);
    assert.strictEqual(fusion.unavailable_reason, 'viewer_frequency_v2_missing');
    assert.strictEqual(fusion.final_fit, null);
    assert.notStrictEqual(fusion.compatibility_index, 50);
  });

  it('V2 malformed → final unavailable', () => {
    const scores = { ...fill(IQ_IDS, 0.5), ...fill(EQ_IDS, 0.5) };
    const structural = compareIqEqMeasuredPresence(scores, scores);
    const fusion = fuseCompatibilityV2(structural, {
      available: false,
      unavailable_reason: 'candidate_frequency_v2_malformed',
    });
    assert.strictEqual(fusion.available, false);
    assert.strictEqual(
      fusion.unavailable_reason,
      'candidate_frequency_v2_malformed',
    );
  });

  it('out-of-range V2 supported fit is unavailable, not clamped into a score', () => {
    const scores = { ...fill(IQ_IDS, 0.5), ...fill(EQ_IDS, 0.5) };
    const structural = compareIqEqMeasuredPresence(scores, scores);
    const fusion = fuseCompatibilityV2(structural, v2Fit(1.2, 1));
    assert.strictEqual(fusion.available, false);
    assert.strictEqual(fusion.unavailable_reason, 'frequency_v2_unavailable');
  });

  it('does not double-count V1 Frequency: structural half ignores 6D Frequency', () => {
    const iqEq = { ...fill(IQ_IDS, 0.55), ...fill(EQ_IDS, 0.45) };
    const lowFreq = { ...iqEq, ...fill(FREQUENCY_IDS, 0.01) };
    const highFreq = { ...iqEq, ...fill(FREQUENCY_IDS, 0.99) };
    const iqeqLowHigh = compareIqEqMeasuredPresence(lowFreq, highFreq);
    const iqeqSame = compareIqEqMeasuredPresence(lowFreq, { ...lowFreq });
    const full = compareMeasuredPresence(lowFreq, highFreq);

    assert.strictEqual(iqeqLowHigh.combinedDistance, iqeqSame.combinedDistance);
    assert.strictEqual(iqeqLowHigh.combinedDistance, 0);
    assert.ok(full.combinedDistance > 0.3);

    const withPerfectV2 = fuseCompatibilityV2(iqeqLowHigh, v2Fit(1, 1));
    const withPoorV2 = fuseCompatibilityV2(iqeqLowHigh, v2Fit(0, 1));
    assert.strictEqual(withPerfectV2.non_frequency_structural_fit, 1);
    assert.strictEqual(withPoorV2.non_frequency_structural_fit, 1);
    assert.strictEqual(withPerfectV2.compatibility_index, 100);
    assert.strictEqual(withPoorV2.compatibility_index, 50);
    assert.notStrictEqual(
      withPerfectV2.compatibility_index,
      withPoorV2.compatibility_index,
    );
  });

  it('public diagnostic is privacy-safe and versioned', () => {
    const scores = { ...fill(IQ_IDS, 0.5), ...fill(EQ_IDS, 0.5) };
    const fusion = fuseCompatibilityV2(
      compareIqEqMeasuredPresence(scores, scores),
      v2Fit(0.8, 0.9),
    );
    const pub = publicCompatibilityV2(fusion);
    assert.deepStrictEqual(Object.keys(pub).sort(), [
      'available',
      'compatibility_index',
      'frequency_fit',
      'frequency_pair_support',
      'policy_version',
      'structural_coverage',
      'structural_fit',
    ].sort());
    for (const key of Object.keys(pub)) {
      assert.ok(COMPATIBILITY_V2_PUBLIC_KEYS.includes(key), key);
    }
    const blob = JSON.stringify(pub);
    assert.strictEqual(blob.includes('logical_reasoning'), false);
    assert.strictEqual(blob.includes('empathy'), false);
    assert.strictEqual(blob.includes('depth_preference'), false);
    assert.strictEqual(blob.includes('contact_need'), false);
    assert.strictEqual(blob.includes('normalized_behavior'), false);
    assert.strictEqual(blob.includes('uid'), false);
    assert.strictEqual(pub.uid, undefined);
    const missing = publicCompatibilityV2(
      fuseCompatibilityV2(compareIqEqMeasuredPresence(scores, scores), null),
    );
    assert.strictEqual(missing.available, false);
    assert.strictEqual(missing.unavailable_reason, 'frequency_v2_unavailable');
    assert.strictEqual(missing.compatibility_index, undefined);
  });
});
