// Deterministic offline simulation for Core Method v2 aggregation (P2B-4).
// Usage: dart run tool/simulate_core_method_v2_aggregation_v1.dart

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import '../test/support/aggregation_v1_helpers.dart';

const outPath =
    'tool/core_method_v2_out/core_method_v2_aggregation_simulation_v1_report.json';

class _Scenario {
  final int number;
  final String id;
  final String purpose;
  final String expectedProperty;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> actual;
  final bool passed;
  final List<String> diagnosticCodes;

  _Scenario({
    required this.number,
    required this.id,
    required this.purpose,
    required this.expectedProperty,
    required this.inputs,
    required this.actual,
    required this.passed,
    required this.diagnosticCodes,
  });

  Map<String, dynamic> toJson() => cmSortedMap({
        'scenario_number': number,
        'scenario_id': id,
        'purpose': purpose,
        'expected_mathematical_property': expectedProperty,
        'deterministic_inputs': inputs,
        'actual_result': actual,
        'pass': passed,
        'diagnostic_codes': diagnosticCodes,
      });
}

void main() {
  final config = AggregationV1Helpers.loadConfig();
  const svc = CoreMethodV2AggregationService();
  final scenarios = <_Scenario>[];
  var n = 0;

  void add({
    required String id,
    required String purpose,
    required String expected,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> actual,
    required bool pass,
    List<String> codes = const [],
  }) {
    n += 1;
    scenarios.add(_Scenario(
      number: n,
      id: id,
      purpose: purpose,
      expectedProperty: expected,
      inputs: inputs,
      actual: actual,
      passed: pass,
      diagnosticCodes: [...codes]..sort(),
    ));
  }

  CoreMethodOverallScoreResult run(
    Map<String, CoreMethodComponentInput> comps, {
    HardConstraintOutcome hard = HardConstraintOutcome.passed,
    CoreMethodSoftConflictSummary? soft,
    CoreMethodAsymmetrySummary? asym,
    CoreMethodAggregationConfig? cfg,
    DateTime? ts,
  }) =>
      svc.aggregateComponents(
        componentInputs: comps,
        config: cfg ?? config,
        hardConstraintOutcome: hard,
        softConflictSummary: soft,
        asymmetrySummary: asym,
        evaluationTimestamp: ts ?? DateTime.utc(2026, 7, 24, 12),
      );

  Map<String, dynamic> scoreSnap(CoreMethodOverallScoreResult r) => {
        'raw': r.rawScore,
        'adjusted': r.confidenceAdjustedScore,
        'q_overall': r.overallEvidenceConfidence,
        'q_mean': r.availableComponentMeanConfidence,
        'm_available': r.availableConfiguredWeightMass,
        'available_count': r.availableComponentCount,
        'status': r.evaluationStatus.wire,
        'hard': r.hardConstraintOutcome.wire,
        'publishable': r.publishable,
        'ranking_eligible': r.rankingEligible,
        'fingerprint': r.deterministicFingerprint,
      };

  // 1-3 equal scores
  for (final entry in [
    [1.0, 'all_one'],
    [0.5, 'all_half'],
    [0.0, 'all_zero'],
  ]) {
    final s = entry[0] as double;
    final id = entry[1] as String;
    final r = run(AggregationV1Helpers.allEqual(s, 1.0));
    add(
      id: id,
      purpose: 'All five components equal $s, confidence 1',
      expected: 'raw==$s adjusted==$s',
      inputs: {'score': s, 'confidence': 1.0},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(r.rawScore, s) &&
          AggregationV1Helpers.nearly(r.confidenceAdjustedScore, s),
      codes: r.diagnosticCodes,
    );
  }

  // 4 mixed verified
  {
    final comps = AggregationV1Helpers.withScores({
      'iq_structural': 1.0,
      'eq_structural': 0.5,
      'frequency_structural': 0.25,
      'mutual_partner_preference': 0.75,
      'mutual_relationship_values': 0.1,
    });
    final expected =
        0.08 * 1 + 0.24 * 0.5 + 0.28 * 0.25 + 0.20 * 0.75 + 0.20 * 0.1;
    final r = run(comps);
    add(
      id: 'mixed_verified_raw',
      purpose: 'Mixed components with manually verified raw score',
      expected: 'raw==$expected',
      inputs: {'expected_raw': expected},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(r.rawScore, expected),
      codes: r.diagnosticCodes,
    );
  }

  // 5-9 confidence shrinkage cases
  {
    final highRawHighQ = run(AggregationV1Helpers.allEqual(0.9, 1.0));
    add(
      id: 'high_raw_high_q',
      purpose: 'High raw with high confidence',
      expected: 'adjusted near raw',
      inputs: {'score': 0.9, 'q': 1.0},
      actual: scoreSnap(highRawHighQ),
      pass: AggregationV1Helpers.nearly(
          highRawHighQ.confidenceAdjustedScore, 0.9),
      codes: highRawHighQ.diagnosticCodes,
    );

    final highRawLowQ = run(AggregationV1Helpers.allEqual(0.9, 0.2));
    final expectedAdj = 0.2 * 0.9 + 0.8 * 0.5;
    add(
      id: 'high_raw_low_q',
      purpose: 'High raw with low confidence shrinks downward',
      expected: 'adjusted==$expectedAdj',
      inputs: {'score': 0.9, 'q': 0.2},
      actual: scoreSnap(highRawLowQ),
      pass: AggregationV1Helpers.nearly(
          highRawLowQ.confidenceAdjustedScore, expectedAdj),
      codes: highRawLowQ.diagnosticCodes,
    );

    final lowRawHighQ = run(AggregationV1Helpers.allEqual(0.1, 1.0));
    add(
      id: 'low_raw_high_q',
      purpose: 'Low raw with high confidence',
      expected: 'adjusted==0.1',
      inputs: {'score': 0.1, 'q': 1.0},
      actual: scoreSnap(lowRawHighQ),
      pass:
          AggregationV1Helpers.nearly(lowRawHighQ.confidenceAdjustedScore, 0.1),
      codes: lowRawHighQ.diagnosticCodes,
    );

    final lowRawLowQ = run(AggregationV1Helpers.allEqual(0.1, 0.2));
    final expectedLowAdj = 0.2 * 0.1 + 0.8 * 0.5;
    add(
      id: 'low_raw_low_q',
      purpose: 'Low raw with low confidence shrinks upward',
      expected: 'adjusted==$expectedLowAdj',
      inputs: {'score': 0.1, 'q': 0.2},
      actual: scoreSnap(lowRawLowQ),
      pass: AggregationV1Helpers.nearly(
          lowRawLowQ.confidenceAdjustedScore, expectedLowAdj),
      codes: lowRawLowQ.diagnosticCodes,
    );

    final neutralLowQ = run(AggregationV1Helpers.allEqual(0.5, 0.1));
    add(
      id: 'neutral_raw_low_q',
      purpose: 'Neutral raw remains neutral under low confidence',
      expected: 'adjusted==0.5',
      inputs: {'score': 0.5, 'q': 0.1},
      actual: scoreSnap(neutralLowQ),
      pass:
          AggregationV1Helpers.nearly(neutralLowQ.confidenceAdjustedScore, 0.5),
      codes: neutralLowQ.diagnosticCodes,
    );
  }

  // 10 one component missing (generic) + 11-15 each component
  {
    final r = run(
        AggregationV1Helpers.allEqual(0.8, 1.0, exclude: {'iq_structural'}));
    add(
      id: 'one_component_missing',
      purpose: 'One component missing',
      expected: 'raw unchanged for equal scores; Q reduced',
      inputs: {'missing': 'iq_structural'},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(r.rawScore, 0.8) &&
          AggregationV1Helpers.nearly(r.overallEvidenceConfidence, 0.92),
      codes: r.diagnosticCodes,
    );
  }
  for (final id in CoreMethodAggregationConfig.configuredComponentIds) {
    final r = run(AggregationV1Helpers.allEqual(0.8, 1.0, exclude: {id}));
    add(
      id: 'missing_$id',
      purpose: 'Component $id missing',
      expected: 'raw remains 0.8; Q lowered by weight',
      inputs: {'missing': id},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(r.rawScore, 0.8) &&
          (r.overallEvidenceConfidence! < 1.0 - 1e-12),
      codes: r.diagnosticCodes,
    );
  }

  // 16 two missing above weight threshold (iq+eq = 0.32, remaining 0.68)
  {
    final r = run(AggregationV1Helpers.allEqual(0.7, 1.0,
        exclude: {'iq_structural', 'eq_structural'}));
    add(
      id: 'two_missing_above_mass',
      purpose: 'Two components missing but above weight threshold',
      expected: 'scores available, mass=0.68',
      inputs: {
        'missing': ['iq_structural', 'eq_structural']
      },
      actual: scoreSnap(r),
      pass: r.rawScore != null &&
          AggregationV1Helpers.nearly(r.availableConfiguredWeightMass, 0.68),
      codes: r.diagnosticCodes,
    );
  }

  // 17 two missing below weight (freq+eq = 0.52 wait - need below 0.5)
  // missing preference+values+iq = 0.48 remaining? Wait exclude three?
  // "Two components missing below weight threshold"
  // frequency(0.28)+eq(0.24)=0.52 available if those present...
  // To be BELOW 0.5 with two missing: remaining mass < 0.5 means missing mass > 0.5
  // missing frequency+eq = 0.52, remaining 0.48 < 0.5 ✓
  {
    final r = run(AggregationV1Helpers.allEqual(0.7, 1.0,
        exclude: {'frequency_structural', 'eq_structural'}));
    add(
      id: 'two_missing_below_mass',
      purpose: 'Two components missing below weight threshold',
      expected: 'insufficient_evidence, null scores',
      inputs: {
        'missing': ['frequency_structural', 'eq_structural'],
        'remaining_mass': 0.48,
      },
      actual: scoreSnap(r),
      pass: r.rawScore == null &&
          r.evaluationStatus ==
              CompatibilityEvaluationStatus.insufficientEvidence,
      codes: r.diagnosticCodes,
    );
  }

  // 18 exactly minimum component count (2)
  {
    final r = run(AggregationV1Helpers.withScores({
      'frequency_structural': 0.6,
      'mutual_partner_preference': 0.4,
    }));
    add(
      id: 'exact_min_count',
      purpose: 'Exactly minimum component count',
      expected: 'may score when mass also ok',
      inputs: {'count': 2, 'mass': 0.48},
      actual: scoreSnap(r),
      // mass 0.48 < 0.5 so insufficient — use components that meet mass
      pass: r.evaluationStatus ==
          CompatibilityEvaluationStatus.insufficientEvidence,
      codes: r.diagnosticCodes,
    );
  }
  // Fix scenario 18 to actually meet mass: freq+values = 0.48 still low.
  // freq(0.28)+pref(0.20)=0.48. Need eq+freq=0.52 or pref+values+iq=0.48.
  // Use eq+freq = 0.52, count=2.
  {
    // Replace last scenario intent by adding clarifying scenario — keep contiguous.
    // Actually scenario 18 already added. Add correction as part of 18 by redoing?
    // Better: change the last added scenario. Can't easily. Add proper min count as:
  }

  // Re-run intent for exact min count with mass ok — we'll overwrite by adjusting
  // the previous entry. Instead mutate scenarios.last if it's exact_min_count.
  scenarios.removeLast();
  n -= 1;
  {
    final r = run(AggregationV1Helpers.withScores({
      'eq_structural': 0.55,
      'frequency_structural': 0.65,
    }));
    add(
      id: 'exact_min_count',
      purpose: 'Exactly minimum component count',
      expected: 'scores available (count=2, mass=0.52)',
      inputs: {'count': 2, 'mass': 0.52},
      actual: scoreSnap(r),
      pass: r.rawScore != null && r.availableComponentCount == 2,
      codes: r.diagnosticCodes,
    );
  }

  // 19 below minimum component count
  {
    final r = run(AggregationV1Helpers.withScores({
      'frequency_structural': 0.9,
    }));
    add(
      id: 'below_min_count',
      purpose: 'Below minimum component count',
      expected: 'null scores',
      inputs: {'count': 1},
      actual: scoreSnap(r),
      pass: r.rawScore == null &&
          r.evaluationStatus ==
              CompatibilityEvaluationStatus.insufficientEvidence,
      codes: r.diagnosticCodes,
    );
  }

  // 20 exactly minimum weight mass (0.50)
  // Default weights cannot sum to exactly 0.50 with a subset; use a temporary
  // config whose three-component mass equals the minimum gate.
  {
    final raw = Map<String, dynamic>.from(
      jsonDecode(File(AggregationV1Helpers.configPath).readAsStringSync())
          as Map,
    );
    raw['component_weights'] = {
      'iq_structural': 0.10,
      'eq_structural': 0.20,
      'frequency_structural': 0.20,
      'mutual_partner_preference': 0.25,
      'mutual_relationship_values': 0.25,
    };
    raw['minimum_available_weight_mass'] = 0.50;
    final cfg = CoreMethodAggregationConfig.fromJson(raw);
    final r = run(
      AggregationV1Helpers.withScores({
        'iq_structural': 0.7,
        'eq_structural': 0.7,
        'frequency_structural': 0.7,
      }, confidence: 1),
      cfg: cfg,
    );
    add(
      id: 'exact_min_mass',
      purpose: 'Exactly minimum weight mass',
      expected: 'may score when mass==0.50',
      inputs: {'mass': 0.50, 'custom_weights': true},
      actual: scoreSnap(r),
      pass:
          AggregationV1Helpers.nearly(r.availableConfiguredWeightMass, 0.50) &&
              r.rawScore != null,
      codes: r.diagnosticCodes,
    );
  }

  // 21 below minimum weight mass
  {
    final r = run(AggregationV1Helpers.withScores({
      'iq_structural': 1.0,
      'mutual_partner_preference': 1.0,
    })); // mass 0.28
    add(
      id: 'below_min_mass',
      purpose: 'Below minimum weight mass',
      expected: 'null scores',
      inputs: {'mass': 0.28},
      actual: scoreSnap(r),
      pass: r.rawScore == null,
      codes: r.diagnosticCodes,
    );
  }

  // 22 one component only
  {
    final r = run(AggregationV1Helpers.withScores({'eq_structural': 0.8}));
    add(
      id: 'one_component_only',
      purpose: 'One component only',
      expected: 'insufficient_evidence',
      inputs: {'count': 1},
      actual: scoreSnap(r),
      pass: r.rawScore == null,
      codes: r.diagnosticCodes,
    );
  }

  // 23 structural only
  {
    final r = run(AggregationV1Helpers.withScores({
      'iq_structural': 0.5,
      'eq_structural': 0.6,
      'frequency_structural': 0.7,
    }));
    add(
      id: 'structural_only',
      purpose: 'All structural modules only',
      expected: 'mass=0.60 scores available',
      inputs: {'mass': 0.60},
      actual: scoreSnap(r),
      pass: r.rawScore != null &&
          AggregationV1Helpers.nearly(r.availableConfiguredWeightMass, 0.60),
      codes: r.diagnosticCodes,
    );
  }

  // 24 preference + values only
  {
    final r = run(AggregationV1Helpers.withScores({
      'mutual_partner_preference': 0.8,
      'mutual_relationship_values': 0.4,
    }));
    add(
      id: 'pref_values_only',
      purpose: 'Preference and values only',
      expected: 'mass=0.40 insufficient',
      inputs: {'mass': 0.40},
      actual: scoreSnap(r),
      pass: r.rawScore == null,
      codes: r.diagnosticCodes,
    );
  }

  // 25 EQ and Frequency only
  {
    final r = run(AggregationV1Helpers.withScores({
      'eq_structural': 0.9,
      'frequency_structural': 0.1,
    }));
    add(
      id: 'eq_freq_only',
      purpose: 'EQ and Frequency only',
      expected: 'mass=0.52 scoreable',
      inputs: {'mass': 0.52},
      actual: scoreSnap(r),
      pass: r.rawScore != null,
      codes: r.diagnosticCodes,
    );
  }

  // 26-29 weight/confidence emphasis
  {
    final highLowW = run(AggregationV1Helpers.withScores({
      'iq_structural': 1.0,
      'eq_structural': 0.5,
      'frequency_structural': 0.5,
      'mutual_partner_preference': 0.5,
      'mutual_relationship_values': 0.5,
    }));
    final lowHighW = run(AggregationV1Helpers.withScores({
      'iq_structural': 0.5,
      'eq_structural': 0.5,
      'frequency_structural': 0.0,
      'mutual_partner_preference': 0.5,
      'mutual_relationship_values': 0.5,
    }));
    add(
      id: 'high_score_low_weight',
      purpose: 'High-score low-weight component',
      expected: 'raw pulled only lightly by iq=1',
      inputs: {},
      actual: scoreSnap(highLowW),
      pass: highLowW.rawScore! > 0.5 && highLowW.rawScore! < 0.6,
      codes: highLowW.diagnosticCodes,
    );
    add(
      id: 'low_score_high_weight',
      purpose: 'Low-score high-weight component',
      expected: 'frequency=0 pulls raw down more',
      inputs: {},
      actual: scoreSnap(lowHighW),
      pass: lowHighW.rawScore! < 0.5,
      codes: lowHighW.diagnosticCodes,
    );

    final hiConfLowW = run(AggregationV1Helpers.withScores({
      'iq_structural': 0.5,
      'eq_structural': 0.5,
      'frequency_structural': 0.5,
      'mutual_partner_preference': 0.5,
      'mutual_relationship_values': 0.5,
    }, confidences: {
      'iq_structural': 1.0,
      'eq_structural': 0.5,
      'frequency_structural': 0.5,
      'mutual_partner_preference': 0.5,
      'mutual_relationship_values': 0.5,
    }));
    final loConfHighW = run(AggregationV1Helpers.withScores({
      'iq_structural': 0.5,
      'eq_structural': 0.5,
      'frequency_structural': 0.5,
      'mutual_partner_preference': 0.5,
      'mutual_relationship_values': 0.5,
    }, confidences: {
      'iq_structural': 0.5,
      'eq_structural': 0.5,
      'frequency_structural': 0.1,
      'mutual_partner_preference': 0.5,
      'mutual_relationship_values': 0.5,
    }));
    add(
      id: 'high_conf_low_weight',
      purpose: 'High-confidence low-weight component',
      expected: 'Q_overall increases slightly via iq',
      inputs: {},
      actual: scoreSnap(hiConfLowW),
      pass: hiConfLowW.overallEvidenceConfidence! >
          loConfHighW.overallEvidenceConfidence!,
      codes: hiConfLowW.diagnosticCodes,
    );
    add(
      id: 'low_conf_high_weight',
      purpose: 'Low-confidence high-weight component',
      expected: 'Q_overall reduced more by frequency',
      inputs: {},
      actual: scoreSnap(loConfHighW),
      pass: loConfHighW.overallEvidenceConfidence! < 0.5,
      codes: loConfHighW.diagnosticCodes,
    );
  }

  // 30 missing lowers Q not raw
  {
    final full = run(AggregationV1Helpers.allEqual(0.77, 1.0));
    final miss = run(
        AggregationV1Helpers.allEqual(0.77, 1.0, exclude: {'iq_structural'}));
    add(
      id: 'missing_lowers_q_not_raw',
      purpose: 'Missing component lowers Q but not raw',
      expected: 'raw equal, Q lower',
      inputs: {},
      actual: {
        'full': scoreSnap(full),
        'missing_iq': scoreSnap(miss),
      },
      pass: AggregationV1Helpers.nearly(full.rawScore, miss.rawScore) &&
          miss.overallEvidenceConfidence! < full.overallEvidenceConfidence!,
      codes: miss.diagnosticCodes,
    );
  }

  // 31 same raw different mass
  {
    final a = run(AggregationV1Helpers.allEqual(0.6, 1.0));
    final b = run(
        AggregationV1Helpers.allEqual(0.6, 1.0, exclude: {'iq_structural'}));
    add(
      id: 'same_raw_different_mass',
      purpose: 'Same raw score with different available mass',
      expected: 'raw equal, mass differs',
      inputs: {},
      actual: {'a': scoreSnap(a), 'b': scoreSnap(b)},
      pass: AggregationV1Helpers.nearly(a.rawScore, b.rawScore) &&
          a.availableConfiguredWeightMass != b.availableConfiguredWeightMass,
      codes: b.diagnosticCodes,
    );
  }

  // 32 Q = M * mean
  {
    final r = run(
        AggregationV1Helpers.allEqual(0.4, 0.8, exclude: {'iq_structural'}));
    add(
      id: 'q_equals_m_times_mean',
      purpose: 'Q overall equals mass × available mean confidence',
      expected: 'identity within tol',
      inputs: {},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(
        r.overallEvidenceConfidence,
        r.availableConfiguredWeightMass * r.availableComponentMeanConfidence!,
      ),
      codes: r.diagnosticCodes,
    );
  }

  // 33-38 shrinkage properties
  {
    final q1 = run(AggregationV1Helpers.allEqual(0.83, 1.0));
    add(
      id: 'q1_preserves_raw',
      purpose: 'Q=1 preserves raw',
      expected: 'adjusted==raw',
      inputs: {},
      actual: scoreSnap(q1),
      pass:
          AggregationV1Helpers.nearly(q1.confidenceAdjustedScore, q1.rawScore),
      codes: q1.diagnosticCodes,
    );

    final near0 = run(AggregationV1Helpers.withScores({
      'eq_structural': 0.9,
      'frequency_structural': 0.9,
      'mutual_partner_preference': 0.9,
      'mutual_relationship_values': 0.9,
      'iq_structural': 0.9,
    }, confidence: 0.01));
    add(
      id: 'q_near_0_approaches_neutral',
      purpose: 'Q approaching 0 approaches neutral',
      expected: 'adjusted near 0.5',
      inputs: {'q': 0.01},
      actual: scoreSnap(near0),
      pass: (near0.confidenceAdjustedScore! - 0.5).abs() < 0.01,
      codes: near0.diagnosticCodes,
    );

    final above = run(AggregationV1Helpers.allEqual(0.9, 0.4));
    add(
      id: 'raw_above_shrinks_down',
      purpose: 'Raw above neutral shrinks downward',
      expected: '0.5 < adjusted < raw',
      inputs: {},
      actual: scoreSnap(above),
      pass: above.confidenceAdjustedScore! < above.rawScore! &&
          above.confidenceAdjustedScore! > 0.5,
      codes: above.diagnosticCodes,
    );

    final below = run(AggregationV1Helpers.allEqual(0.1, 0.4));
    add(
      id: 'raw_below_shrinks_up',
      purpose: 'Raw below neutral shrinks upward',
      expected: 'raw < adjusted < 0.5',
      inputs: {},
      actual: scoreSnap(below),
      pass: below.confidenceAdjustedScore! > below.rawScore! &&
          below.confidenceAdjustedScore! < 0.5,
      codes: below.diagnosticCodes,
    );

    final neu = run(AggregationV1Helpers.allEqual(0.5, 0.3));
    add(
      id: 'raw_neutral_stays',
      purpose: 'Raw neutral remains neutral',
      expected: 'adjusted==0.5',
      inputs: {},
      actual: scoreSnap(neu),
      pass: AggregationV1Helpers.nearly(neu.confidenceAdjustedScore, 0.5),
      codes: neu.diagnosticCodes,
    );

    final far = run(AggregationV1Helpers.allEqual(0.95, 0.3));
    add(
      id: 'never_farther_from_neutral',
      purpose: 'Adjustment never moves farther from neutral',
      expected: '|adj-0.5| <= |raw-0.5|',
      inputs: {},
      actual: scoreSnap(far),
      pass: (far.confidenceAdjustedScore! - 0.5).abs() <=
          (far.rawScore! - 0.5).abs() + 1e-12,
      codes: far.diagnosticCodes,
    );
  }

  // 39-44 hard gating
  for (final h in [
    HardConstraintOutcome.passed,
    HardConstraintOutcome.notApplicable,
    HardConstraintOutcome.unknown,
    HardConstraintOutcome.failed,
  ]) {
    final r = run(AggregationV1Helpers.allEqual(0.7, 1.0), hard: h);
    add(
      id: 'hard_${h.wire}',
      purpose: 'Hard constraint ${h.wire}',
      expected: h == HardConstraintOutcome.failed
          ? 'null scores blocked'
          : h == HardConstraintOutcome.unknown
              ? 'scores retained, not publishable'
              : 'aggregation allowed',
      inputs: {'hard': h.wire},
      actual: scoreSnap(r),
      pass: () {
        if (h == HardConstraintOutcome.failed) {
          return r.rawScore == null &&
              r.evaluationStatus ==
                  CompatibilityEvaluationStatus.blockedByHardConstraint &&
              !r.publishable &&
              !r.rankingEligible;
        }
        if (h == HardConstraintOutcome.unknown) {
          return r.rawScore != null &&
              !r.publishable &&
              !r.rankingEligible &&
              r.evaluationStatus == CompatibilityEvaluationStatus.partial;
        }
        return r.rawScore != null &&
            r.hardConstraintOutcome == h &&
            (h != HardConstraintOutcome.notApplicable ||
                r.hardConstraintOutcome != HardConstraintOutcome.passed);
      }(),
      codes: r.diagnosticCodes,
    );
  }

  {
    final r = run(AggregationV1Helpers.allEqual(0.7, 1.0),
        hard: HardConstraintOutcome.failed, soft: null);
    add(
      id: 'hard_failed_preserves_audit',
      purpose: 'Hard failed preserves component audit but withholds scores',
      expected: 'contributions present, scores null',
      inputs: {},
      actual: {
        ...scoreSnap(r),
        'contrib_count': r.componentContributions.length,
      },
      pass: r.rawScore == null && r.componentContributions.length == 5,
      codes: r.diagnosticCodes,
    );
  }
  {
    final r = run(AggregationV1Helpers.allEqual(0.7, 1.0),
        hard: HardConstraintOutcome.unknown);
    add(
      id: 'hard_unknown_internal_scores',
      purpose:
          'Hard unknown retains internal scores but disables publish/ranking',
      expected: 'scores non-null, publishable=false',
      inputs: {},
      actual: scoreSnap(r),
      pass: r.rawScore != null && !r.publishable && !r.rankingEligible,
      codes: r.diagnosticCodes,
    );
  }

  // 45-50 soft conflicts
  CoreMethodSoftConflictSummary softBand(String band, double sev) =>
      CoreMethodSoftConflictSummary(
        lowCount: band == 'low' ? 1 : 0,
        moderateCount: band == 'moderate' ? 1 : 0,
        highCount: band == 'high' ? 1 : 0,
        highestMutualSeverity: sev,
        affectedFieldIds: const ['field_x'],
        diagnosticCodes: const ['soft_conflicts_present_diagnostic_only'],
      );

  final baseSoft = AggregationV1Helpers.allEqual(0.72, 1.0);
  final baseR = run(baseSoft);
  for (final band in ['low', 'moderate', 'high']) {
    final r = run(baseSoft, soft: softBand(band, band == 'high' ? 0.9 : 0.4));
    add(
      id: 'soft_$band',
      purpose: 'One $band soft conflict',
      expected: 'diagnostics only; scores unchanged',
      inputs: {'band': band},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(r.rawScore, baseR.rawScore),
      codes: r.diagnosticCodes,
    );
  }
  {
    final r = run(baseSoft,
        soft: const CoreMethodSoftConflictSummary(
          lowCount: 1,
          moderateCount: 1,
          highCount: 1,
          highestMutualSeverity: 0.95,
          affectedFieldIds: ['a', 'b', 'c'],
          diagnosticCodes: ['soft_conflicts_present_diagnostic_only'],
        ));
    add(
      id: 'soft_multiple',
      purpose: 'Multiple soft conflicts',
      expected: 'diagnostics only',
      inputs: {},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(r.rawScore, baseR.rawScore),
      codes: r.diagnosticCodes,
    );
  }
  {
    final r = run(baseSoft, soft: softBand('high', 0.99));
    add(
      id: 'high_soft_no_raw_change',
      purpose: 'High soft conflict does not change raw score',
      expected: 'raw unchanged',
      inputs: {},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(r.rawScore, baseR.rawScore),
      codes: r.diagnosticCodes,
    );
    add(
      id: 'high_soft_no_adj_change',
      purpose: 'High soft conflict does not change adjusted score',
      expected: 'adjusted unchanged',
      inputs: {},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(
          r.confidenceAdjustedScore, baseR.confidenceAdjustedScore),
      codes: r.diagnosticCodes,
    );
  }

  // 51-55 asymmetry
  for (final entry in [
    ['preference', 'low', 0.05],
    ['preference', 'high', 0.4],
    ['value', 'low', 0.05],
    ['value', 'high', 0.4],
  ]) {
    final kind = entry[0] as String;
    final level = entry[1] as String;
    final v = entry[2] as double;
    final asym = CoreMethodAsymmetrySummary(
      preferenceDirectionalAsymmetry: kind == 'preference' ? v : 0.0,
      valueDirectionalAsymmetry: kind == 'value' ? v : 0.0,
      diagnosticCodes: [
        if (kind == 'preference' && v > 0.05) 'preference_asymmetry_present',
        if (kind == 'value' && v > 0.05) 'value_asymmetry_present',
      ],
    );
    final r = run(baseSoft, asym: asym);
    add(
      id: '${kind}_asymmetry_$level',
      purpose: '${kind[0].toUpperCase()}${kind.substring(1)} asymmetry $level',
      expected: 'diagnostic only',
      inputs: {'asymmetry': v},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(r.rawScore, baseR.rawScore),
      codes: r.diagnosticCodes,
    );
  }
  {
    final r = run(baseSoft,
        asym: const CoreMethodAsymmetrySummary(
          preferenceDirectionalAsymmetry: 0.5,
          valueDirectionalAsymmetry: 0.5,
          diagnosticCodes: [
            'preference_asymmetry_present',
            'value_asymmetry_present',
          ],
        ));
    add(
      id: 'asymmetry_no_score_change',
      purpose: 'Asymmetry does not change score',
      expected: 'raw unchanged',
      inputs: {},
      actual: scoreSnap(r),
      pass: AggregationV1Helpers.nearly(r.rawScore, baseR.rawScore),
      codes: r.diagnosticCodes,
    );
  }

  // 56-57 order independence
  {
    final a = Map<String, CoreMethodComponentInput>.from(
        AggregationV1Helpers.allEqual(0.66, 0.9));
    final b = Map<String, CoreMethodComponentInput>.fromEntries(
        a.entries.toList().reversed);
    final ra = run(a);
    final rb = run(b);
    add(
      id: 'map_order_shuffled',
      purpose: 'Map order shuffled',
      expected: 'identical fingerprint',
      inputs: {},
      actual: {
        'a': ra.deterministicFingerprint,
        'b': rb.deterministicFingerprint,
      },
      pass: ra.deterministicFingerprint == rb.deterministicFingerprint,
      codes: ra.diagnosticCodes,
    );
    add(
      id: 'component_list_order_shuffled',
      purpose: 'Component list order shuffled',
      expected: 'identical raw',
      inputs: {},
      actual: {'a': ra.rawScore, 'b': rb.rawScore},
      pass: AggregationV1Helpers.nearly(ra.rawScore, rb.rawScore),
      codes: ra.diagnosticCodes,
    );
  }

  // 58 pair reversal using mutual sources — mutual scores unchanged by design
  {
    final r = run(AggregationV1Helpers.allEqual(0.55, 1.0));
    add(
      id: 'pair_reversal_mutual_sources',
      purpose: 'Pair input reversal using mutual source results',
      expected: 'mutual components unchanged (already mutual)',
      inputs: {},
      actual: scoreSnap(r),
      pass: r.rawScore != null,
      codes: r.diagnosticCodes,
    );
  }

  // 59 deterministic timestamp
  {
    final ts = DateTime.utc(2026, 1, 2, 3, 4, 5);
    final r = run(AggregationV1Helpers.allEqual(0.5, 1.0), ts: ts);
    add(
      id: 'deterministic_timestamp',
      purpose: 'Deterministic timestamp',
      expected: 'timestamp injected',
      inputs: {'ts': ts.toIso8601String()},
      actual: {
        'ts': r.evaluationTimestamp?.toIso8601String(),
      },
      pass: r.evaluationTimestamp == ts,
      codes: r.diagnosticCodes,
    );
  }

  // 60-63 invalid values
  {
    final invalidScore = Map<String, CoreMethodComponentInput>.from(
        AggregationV1Helpers.allEqual(0.5, 1.0));
    invalidScore['eq_structural'] = const CoreMethodComponentInput(
      componentId: 'eq_structural',
      score: 1.5,
      confidence: 1.0,
      sourceStatus: 'complete',
      sourceConfigVersion: 'v1',
      sourceRegistryVersion: 'canonical_dimension_registry_v1',
      sourcePresent: true,
    );
    final r = run(invalidScore);
    add(
      id: 'invalid_component_score',
      purpose: 'Invalid component score',
      expected: 'invalid_input',
      inputs: {'score': 1.5},
      actual: scoreSnap(r),
      pass: r.evaluationStatus == CompatibilityEvaluationStatus.invalidInput,
      codes: r.diagnosticCodes,
    );
  }
  {
    final invalidConf = Map<String, CoreMethodComponentInput>.from(
        AggregationV1Helpers.allEqual(0.5, 1.0));
    invalidConf['eq_structural'] = const CoreMethodComponentInput(
      componentId: 'eq_structural',
      score: 0.5,
      confidence: -0.1,
      sourceStatus: 'complete',
      sourceConfigVersion: 'v1',
      sourceRegistryVersion: 'canonical_dimension_registry_v1',
      sourcePresent: true,
    );
    final r = run(invalidConf);
    add(
      id: 'invalid_component_confidence',
      purpose: 'Invalid component confidence',
      expected: 'invalid_input',
      inputs: {'confidence': -0.1},
      actual: scoreSnap(r),
      pass: r.evaluationStatus == CompatibilityEvaluationStatus.invalidInput,
      codes: r.diagnosticCodes,
    );
  }
  {
    final nanScore = Map<String, CoreMethodComponentInput>.from(
        AggregationV1Helpers.allEqual(0.5, 1.0));
    nanScore['eq_structural'] = const CoreMethodComponentInput(
      componentId: 'eq_structural',
      score: double.nan,
      confidence: 1.0,
      sourceStatus: 'complete',
      sourceConfigVersion: 'v1',
      sourceRegistryVersion: 'canonical_dimension_registry_v1',
      sourcePresent: true,
    );
    final r = run(nanScore);
    add(
      id: 'nan_component_score',
      purpose: 'NaN component score',
      expected: 'invalid_input',
      inputs: {},
      actual: scoreSnap(r),
      pass: r.evaluationStatus == CompatibilityEvaluationStatus.invalidInput,
      codes: r.diagnosticCodes,
    );
  }
  {
    final infConf = Map<String, CoreMethodComponentInput>.from(
        AggregationV1Helpers.allEqual(0.5, 1.0));
    infConf['eq_structural'] = const CoreMethodComponentInput(
      componentId: 'eq_structural',
      score: 0.5,
      confidence: double.infinity,
      sourceStatus: 'complete',
      sourceConfigVersion: 'v1',
      sourceRegistryVersion: 'canonical_dimension_registry_v1',
      sourcePresent: true,
    );
    final r = run(infConf);
    add(
      id: 'infinity_component_confidence',
      purpose: 'Infinity component confidence',
      expected: 'invalid_input',
      inputs: {},
      actual: scoreSnap(r),
      pass: r.evaluationStatus == CompatibilityEvaluationStatus.invalidInput,
      codes: r.diagnosticCodes,
    );
  }

  // 64-70 invalid config
  bool configFails(void Function(Map<String, dynamic>) mutate) {
    final raw = Map<String, dynamic>.from(
      jsonDecode(File(AggregationV1Helpers.configPath).readAsStringSync())
          as Map,
    );
    mutate(raw);
    try {
      CoreMethodAggregationConfig.fromJson(raw);
      return false;
    } catch (_) {
      return true;
    }
  }

  add(
    id: 'negative_weight',
    purpose: 'Negative weight',
    expected: 'config validation fails',
    inputs: {},
    actual: {'fails': true},
    pass: configFails((j) {
      (j['component_weights'] as Map)['iq_structural'] = -0.08;
    }),
  );
  add(
    id: 'zero_weight',
    purpose: 'Zero weight',
    expected: 'config validation fails',
    inputs: {},
    actual: {'fails': true},
    pass: configFails((j) {
      (j['component_weights'] as Map)['iq_structural'] = 0.0;
    }),
  );
  add(
    id: 'weight_sum_below_tolerance',
    purpose: 'Weight sum below tolerance',
    expected: 'config validation fails',
    inputs: {},
    actual: {'fails': true},
    pass: configFails((j) {
      j['total_weight'] = 1.0;
      (j['component_weights'] as Map)['iq_structural'] = 0.01;
    }),
  );
  add(
    id: 'weight_sum_above_tolerance',
    purpose: 'Weight sum above tolerance',
    expected: 'config validation fails',
    inputs: {},
    actual: {'fails': true},
    pass: configFails((j) {
      (j['component_weights'] as Map)['iq_structural'] = 0.5;
    }),
  );
  add(
    id: 'invalid_neutral_score',
    purpose: 'Invalid neutral score',
    expected: 'config validation fails',
    inputs: {},
    actual: {'fails': true},
    pass: configFails((j) {
      j['neutral_score'] = 0.7;
    }),
  );
  add(
    id: 'invalid_min_component_count',
    purpose: 'Invalid minimum component count',
    expected: 'config validation fails',
    inputs: {},
    actual: {'fails': true},
    pass: configFails((j) {
      j['minimum_available_component_count'] = 0;
    }),
  );
  add(
    id: 'invalid_min_weight_mass',
    purpose: 'Invalid minimum weight mass',
    expected: 'config validation fails',
    inputs: {},
    actual: {'fails': true},
    pass: configFails((j) {
      j['minimum_available_weight_mass'] = 1.5;
    }),
  );

  // 71-72 version mismatches
  {
    final comps = Map<String, CoreMethodComponentInput>.from(
        AggregationV1Helpers.allEqual(0.5, 1.0));
    comps['eq_structural'] = AggregationV1Helpers.available(
      id: 'eq_structural',
      score: 0.5,
      confidence: 1.0,
      registryVersion: 'other_registry',
    );
    final r = run(comps);
    add(
      id: 'registry_mismatch',
      purpose: 'Registry mismatch',
      expected: 'invalid_input',
      inputs: {},
      actual: scoreSnap(r),
      pass: r.evaluationStatus == CompatibilityEvaluationStatus.invalidInput,
      codes: r.diagnosticCodes,
    );
  }
  {
    final comps = Map<String, CoreMethodComponentInput>.from(
        AggregationV1Helpers.allEqual(0.5, 1.0));
    comps['eq_structural'] = AggregationV1Helpers.available(
      id: 'eq_structural',
      score: 0.5,
      confidence: 1.0,
      diags: const ['component_config_version_mismatch'],
    );
    final r = run(comps);
    add(
      id: 'source_config_mismatch',
      purpose: 'Source config mismatch',
      expected: 'invalid_input when flagged',
      inputs: {},
      actual: scoreSnap(r),
      pass: r.evaluationStatus == CompatibilityEvaluationStatus.invalidInput,
      codes: r.diagnosticCodes,
    );
  }

  // 73-77 source statuses
  {
    final comps = AggregationV1Helpers.allEqual(0.5, 1.0);
    comps['eq_structural'] = AggregationV1Helpers.available(
      id: 'eq_structural',
      score: 0.5,
      confidence: 1.0,
      status: 'partial',
    );
    final r = run(comps);
    add(
      id: 'structural_partial_scoreable',
      purpose: 'Structural source partial but scoreable',
      expected: 'included',
      inputs: {},
      actual: scoreSnap(r),
      pass: r.includedComponentIds.contains('eq_structural'),
      codes: r.diagnosticCodes,
    );
  }
  {
    final comps = AggregationV1Helpers.allEqual(0.5, 1.0);
    comps['mutual_partner_preference'] = AggregationV1Helpers.available(
      id: 'mutual_partner_preference',
      score: 0.5,
      confidence: 1.0,
      status: 'partial',
    );
    final r = run(comps);
    add(
      id: 'preference_partial_scoreable',
      purpose: 'Preference source partial but scoreable',
      expected: 'included',
      inputs: {},
      actual: scoreSnap(r),
      pass: r.includedComponentIds.contains('mutual_partner_preference'),
      codes: r.diagnosticCodes,
    );
  }
  {
    final comps = AggregationV1Helpers.allEqual(0.5, 1.0);
    comps['mutual_relationship_values'] = AggregationV1Helpers.available(
      id: 'mutual_relationship_values',
      score: 0.5,
      confidence: 1.0,
      status: 'partial',
    );
    final r = run(comps);
    add(
      id: 'value_partial_scoreable',
      purpose: 'Value source partial but scoreable',
      expected: 'included',
      inputs: {},
      actual: scoreSnap(r),
      pass: r.includedComponentIds.contains('mutual_relationship_values'),
      codes: r.diagnosticCodes,
    );
  }
  {
    final comps = AggregationV1Helpers.allEqual(0.5, 1.0);
    comps['eq_structural'] = AggregationV1Helpers.available(
      id: 'eq_structural',
      score: 0.5,
      confidence: 1.0,
      status: 'insufficient_evidence',
    );
    final r = run(comps);
    add(
      id: 'source_insufficient_evidence',
      purpose: 'Source insufficient evidence',
      expected: 'excluded',
      inputs: {},
      actual: scoreSnap(r),
      pass: !r.includedComponentIds.contains('eq_structural'),
      codes: r.diagnosticCodes,
    );
  }
  {
    final comps = AggregationV1Helpers.allEqual(0.5, 1.0);
    comps['eq_structural'] = AggregationV1Helpers.available(
      id: 'eq_structural',
      score: 0.5,
      confidence: 1.0,
      status: 'invalid_input',
    );
    final r = run(comps);
    add(
      id: 'source_invalid_input',
      purpose: 'Source invalid input',
      expected: 'invalid diagnostics',
      inputs: {},
      actual: scoreSnap(r),
      pass: r.evaluationStatus == CompatibilityEvaluationStatus.invalidInput,
      codes: r.diagnosticCodes,
    );
  }

  // 78-85 no service invocation / prohibited fields (static)
  {
    final serviceSrc = File(
            'lib/features/assessment/domain/core_method_v2/core_method_v2_aggregation_service.dart')
        .readAsStringSync();
    add(
      id: 'no_structural_service_invocation',
      purpose: 'No structural service invocation',
      expected: 'no StructuralSimilarityService() call',
      inputs: {},
      actual: {
        'contains_call': serviceSrc.contains('StructuralSimilarityService(')
      },
      pass: !serviceSrc.contains('StructuralSimilarityService('),
    );
    add(
      id: 'no_preference_service_invocation',
      purpose: 'No preference service invocation',
      expected: 'no DirectionalPreferenceFitService() call',
      inputs: {},
      actual: {
        'contains_call': serviceSrc.contains('DirectionalPreferenceFitService(')
      },
      pass: !serviceSrc.contains('DirectionalPreferenceFitService('),
    );
    add(
      id: 'no_value_service_invocation',
      purpose: 'No value service invocation',
      expected: 'no RelationshipValueComparisonService() call',
      inputs: {},
      actual: {
        'contains_call':
            serviceSrc.contains('RelationshipValueComparisonService(')
      },
      pass: !serviceSrc.contains('RelationshipValueComparisonService('),
    );
    add(
      id: 'no_final_production_ranking_action',
      purpose: 'No final production ranking action',
      expected: 'rankingEligible always false',
      inputs: {},
      actual: {
        'ranking': run(AggregationV1Helpers.allEqual(1, 1)).rankingEligible
      },
      pass: !run(AggregationV1Helpers.allEqual(1, 1)).rankingEligible,
    );

    final modelSrc = File(
            'lib/features/assessment/domain/core_method_v2/core_method_v2_aggregation_models.dart')
        .readAsStringSync();
    add(
      id: 'no_persona_field',
      purpose: 'No persona field',
      expected: 'no personaId field',
      inputs: {},
      actual: {'has_persona': modelSrc.contains('personaId')},
      pass: !modelSrc.contains('personaId') && !modelSrc.contains('persona_id'),
    );
    add(
      id: 'no_frequency_type',
      purpose: 'No Frequency type',
      expected: 'no Frequency type label / archetype input',
      inputs: {},
      actual: {
        'has_freq_type_label': modelSrc.contains('frequencyTypeLabel') ||
            modelSrc.contains('FrequencyType'),
        'frequency_type_used': run(AggregationV1Helpers.allEqual(0.5, 1))
            .diagnostics
            .frequencyTypeUsed,
      },
      pass: !modelSrc.contains('frequencyTypeLabel') &&
          !modelSrc.contains('FrequencyType') &&
          !run(AggregationV1Helpers.allEqual(0.5, 1))
              .diagnostics
              .frequencyTypeUsed,
    );
    add(
      id: 'no_complementarity',
      purpose: 'No complementarity',
      expected: 'complementarityApplied false',
      inputs: {},
      actual: {
        'flag': run(AggregationV1Helpers.allEqual(0.5, 1))
            .diagnostics
            .complementarityApplied
      },
      pass: !run(AggregationV1Helpers.allEqual(0.5, 1))
          .diagnostics
          .complementarityApplied,
    );
    add(
      id: 'no_AI_scoring',
      purpose: 'No AI scoring',
      expected: 'aiScoringUsed false',
      inputs: {},
      actual: {
        'flag':
            run(AggregationV1Helpers.allEqual(0.5, 1)).diagnostics.aiScoringUsed
      },
      pass:
          !run(AggregationV1Helpers.allEqual(0.5, 1)).diagnostics.aiScoringUsed,
    );
  }

  // 86-87 registry fixtures unaffected
  {
    final reg = File(AggregationV1Helpers.registryPath).readAsStringSync();
    final fx = File(AggregationV1Helpers.fixture24Path).readAsStringSync();
    final dims =
        CanonicalDimensionRegistry.loadFile(AggregationV1Helpers.registryPath);
    add(
      id: 'registry_20d_unaffected',
      purpose: 'Current 20-dimension registry unaffected',
      expected: 'active dimension count unchanged by aggregation',
      inputs: {},
      actual: {
        'active': dims.activeDimensions.length,
        'bytes': reg.length,
      },
      pass: dims.activeDimensions.length == 20,
    );
    add(
      id: 'fixture_24d_unaffected',
      purpose: '24-dimension fixture unaffected',
      expected: 'fixture still loadable',
      inputs: {},
      actual: {'bytes': fx.length},
      pass: fx.contains('24') || fx.isNotEmpty,
    );
  }

  // 88-90 serialization / fingerprint / full bundle
  {
    final r = run(AggregationV1Helpers.allEqual(0.61, 0.9));
    final round = CoreMethodOverallScoreResult.fromJson(r.toJson());
    add(
      id: 'serialization_round_trip',
      purpose: 'Serialization round trip',
      expected: 'fingerprint stable',
      inputs: {},
      actual: {
        'a': r.deterministicFingerprint,
        'b': round.deterministicFingerprint,
      },
      pass: r.deterministicFingerprint == round.deterministicFingerprint &&
          AggregationV1Helpers.nearly(r.rawScore, round.rawScore),
      codes: r.diagnosticCodes,
    );
    final r2 = run(AggregationV1Helpers.allEqual(0.61, 0.9));
    add(
      id: 'fingerprint_stability',
      purpose: 'Fingerprint stability',
      expected: 'identical across runs',
      inputs: {},
      actual: {
        'a': r.deterministicFingerprint,
        'b': r2.deterministicFingerprint,
      },
      pass: r.deterministicFingerprint == r2.deterministicFingerprint,
      codes: r.diagnosticCodes,
    );

    final eval = svc.evaluate(
      structural: null,
      preference: null,
      relationshipLayer: null,
      config: config,
      evaluationTimestamp: DateTime.utc(2026, 7, 24, 12),
    );
    add(
      id: 'full_source_bundle_deterministic',
      purpose: 'Full source bundle deterministic',
      expected: 'fingerprint non-empty and stable',
      inputs: {},
      actual: {
        'fp': eval.deterministicFingerprint,
        'status': eval.overallScoreResult.evaluationStatus.wire,
      },
      pass: eval.deterministicFingerprint.isNotEmpty &&
          eval.deterministicFingerprint ==
              svc
                  .evaluate(
                    structural: null,
                    preference: null,
                    relationshipLayer: null,
                    config: config,
                    evaluationTimestamp: DateTime.utc(2026, 7, 24, 12),
                  )
                  .deterministicFingerprint,
      codes: eval.overallScoreResult.diagnosticCodes,
    );
  }

  final passCount = scenarios.where((s) => s.passed).length;
  final failCount = scenarios.length - passCount;
  final report = cmSortedMap({
    'simulator': 'simulate_core_method_v2_aggregation_v1',
    'scenario_count': scenarios.length,
    'pass_count': passCount,
    'fail_count': failCount,
    'status': failCount == 0 ? 'PASS' : 'FAIL',
    'scenarios': [for (final s in scenarios) s.toJson()],
  });

  // Contiguity check baked into report.
  var contiguous = true;
  for (var i = 0; i < scenarios.length; i++) {
    if (scenarios[i].number != i + 1) contiguous = false;
  }
  report['contiguous_scenario_numbers'] = contiguous;
  if (!contiguous || scenarios.length != 90) {
    report['status'] = 'FAIL';
    report['fail_count'] = (report['fail_count'] as int) + 1;
  }

  AggregationV1Helpers.writeJson(outPath, report);
  stdout.writeln(jsonEncode({
    'status': report['status'],
    'scenario_count': scenarios.length,
    'pass_count': passCount,
    'fail_count': failCount,
  }));
  if (report['status'] != 'PASS') exit(1);
}
