'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const catalog = require('../src/frequency_behavior_v2_catalog_v1.generated');
const contract = require('../src/frequency_behavior_v2_contract');
const { composeManifest } = require('../src/frequency_behavior_v2_selector');
const { scoreSession, buildScoreSummary } = require('../src/frequency_behavior_v2_scorer');

const FIXTURE_PATH = path.join(
  __dirname,
  '../../test/fixtures/frequency_v2/phase7c_parity_fixtures.json',
);

function loadFixtures() {
  if (!fs.existsSync(FIXTURE_PATH)) {
    throw new Error(
      `missing ${FIXTURE_PATH}; run: dart run tool/frequency_behavior_v2/export_phase7c_parity_fixtures.dart`,
    );
  }
  return JSON.parse(fs.readFileSync(FIXTURE_PATH, 'utf8'));
}

function nearEqual(a, b, tol) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return Math.abs(a - b) <= tol;
}

function assertDimensionParity(actual, expected, tol, dimId) {
  const numericFields = [
    'raw_sum',
    'capacity',
    'normalized_behavior',
    'primary_signal_coverage',
    'absolute_selected_signal',
    'signal_utilization',
    'cross_context_consistency',
    'cross_context_coverage',
    'mean_diagnostic_value',
    'mean_behavioral_plausibility',
    'mean_ambiguity',
    'mean_social_desirability',
    'mean_obviousness',
    'mean_self_presentation_risk',
    'semantic_clarity',
    'evidence_quality',
    'primary_observability',
    'presentation_pressure',
    'presentation_adjustment',
    'context_component',
    'base_confidence',
    'provisional_confidence',
    'confidence_completeness',
  ];
  for (const field of numericFields) {
    assert.ok(
      nearEqual(actual[field], expected[field], tol),
      `${dimId}.${field}: js=${actual[field]} dart=${expected[field]}`,
    );
  }
  assert.deepStrictEqual(actual.confidence_flags, expected.confidence_flags);
  assert.strictEqual(
    actual.primary_question_count,
    expected.primary_question_count,
  );
  assert.strictEqual(
    actual.nonzero_primary_signal_count,
    expected.nonzero_primary_signal_count,
  );
}

describe('frequency_behavior_v2_scorer', () => {
  it('scores composed TR session with summary fields', () => {
    const bank = catalog.banks[contract.POOL_VERSION_TR];
    const manifest = composeManifest({
      bank,
      sessionSeed: 'phase7c-scorer-unit-001',
    });
    const responses = manifest.questions.map((q) => ({
      item_id: q.question_id,
      selected_option_id: q.presented_option_order[0],
    }));
    const result = scoreSession({ bank, responses, manifest });
    assert.strictEqual(result.ok, true);
    assert.strictEqual(result.dimensions.length, 12);
    assert.strictEqual(result.summary.measured_dimension_count, 12);
    assert.ok(result.summary.dimensions_with_behavior >= 1);
    assert.ok(
      result.summary.global_support == null ||
        (result.summary.global_support >= 0 && result.summary.global_support <= 1),
    );
  });

  it('buildScoreSummary matches dimension scores', () => {
    const bank = catalog.banks[contract.POOL_VERSION_TR];
    const manifest = composeManifest({
      bank,
      sessionSeed: 'phase7c-scorer-summary-001',
    });
    const responses = manifest.questions.map((q) => ({
      item_id: q.question_id,
      selected_option_id: q.presented_option_order[1],
    }));
    const result = scoreSession({ bank, responses, manifest });
    const rebuilt = buildScoreSummary(result.dimension_scores);
    assert.deepStrictEqual(rebuilt, result.summary);
  });

  it('rejects incompatible scoring policy', () => {
    const bank = JSON.parse(
      JSON.stringify(catalog.banks[contract.POOL_VERSION_TR]),
    );
    bank.scoring_policy_version = 'wrong';
    const result = scoreSession({ bank, responses: [], manifest: null });
    assert.strictEqual(result.ok, false);
  });
});

describe('frequency_behavior_v2_phase7c_dart_js_parity', () => {
  const doc = loadFixtures();
  const tol = doc.numeric_tolerance;

  it('fixture document declares tolerance and 5+ fixture types', () => {
    assert.strictEqual(doc.schema_version, 'frequency_behavior_v2_phase7c_parity_fixtures_v1');
    assert.ok(doc.fixture_count >= 5);
    assert.ok(doc.fixtures.length >= 5);
    const ids = new Set(doc.fixtures.map((f) => f.id));
    for (const required of [
      'tr_standard_seed',
      'tr_alternate_seed',
      'tr_first_option_pattern',
      'tr_mixed_responses',
      'en_locale_session',
    ]) {
      assert.ok(ids.has(required), `missing fixture ${required}`);
    }
  });

  for (const fixture of loadFixtures().fixtures) {
    it(`Dart/JS parity: ${fixture.id}`, () => {
      const bank = catalog.banks[fixture.bank_version];
      assert.ok(bank, fixture.bank_version);
      const manifest = composeManifest({
        bank,
        sessionSeed: fixture.session_seed,
        sessionId: fixture.session_id,
      });
      const responses = fixture.answers.map((a) => ({
        item_id: a.item_id,
        selected_option_id: a.selected_option_id,
      }));
      const result = scoreSession({ bank, responses, manifest });
      assert.strictEqual(result.ok, true, result.message);
      assert.strictEqual(result.scorer_version, fixture.expected.scorer_version);
      assert.strictEqual(
        result.confidence_model_version,
        fixture.expected.confidence_model_version,
      );

      const expectedByDim = {};
      for (const d of fixture.expected.dimensions) {
        expectedByDim[d.dimension_id] = d;
      }
      for (const actual of result.dimensions) {
        const expected = expectedByDim[actual.dimension_id];
        assert.ok(expected, actual.dimension_id);
        assertDimensionParity(actual, expected, tol, actual.dimension_id);
      }

      const s = result.summary;
      const e = fixture.expected.summary;
      assert.strictEqual(s.measured_dimension_count, e.measured_dimension_count);
      assert.strictEqual(s.dimensions_with_behavior, e.dimensions_with_behavior);
      assert.ok(nearEqual(s.global_support, e.global_support, tol));
    });
  }
});
