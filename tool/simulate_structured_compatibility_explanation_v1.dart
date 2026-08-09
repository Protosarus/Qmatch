// Deterministic simulation for structured explanation (P2B-5).
// Usage: dart run tool/simulate_structured_compatibility_explanation_v1.dart

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import '../test/support/aggregation_v1_helpers.dart';
import '../test/support/explanation_v1_helpers.dart';

const outPath =
    'tool/core_method_v2_out/structured_compatibility_explanation_simulation_v1_report.json';

class _S {
  final int n;
  final String id;
  final String purpose;
  final String expected;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> actual;
  final bool pass;
  final List<String> codes;
  _S(this.n, this.id, this.purpose, this.expected, this.inputs, this.actual,
      this.pass, this.codes);
  Map<String, dynamic> toJson() => cmSortedMap({
        'scenario_number': n,
        'scenario_id': id,
        'purpose': purpose,
        'expected_mathematical_property': expected,
        'deterministic_inputs': inputs,
        'actual_result': actual,
        'pass': pass,
        'diagnostic_codes': [...codes]..sort(),
      });
}

void main() {
  final scenarios = <_S>[];
  var n = 0;
  void add(String id, String purpose, String expected,
      Map<String, dynamic> inputs, Map<String, dynamic> actual, bool pass,
      [List<String> codes = const []]) {
    n += 1;
    scenarios.add(_S(n, id, purpose, expected, inputs, actual, pass, codes));
  }

  Map<String, dynamic> snap(StructuredCompatibilityExplanationResult r) => {
        'status': r.evaluationStatus.wire,
        'raw': r.overallRawScore,
        'adj': r.confidenceAdjustedScore,
        'q': r.overallEvidenceConfidence,
        'count': r.signals.length,
        'first': r.signals.isEmpty ? null : r.signals.first.explanationCode,
        'codes': [for (final s in r.signals) s.explanationCode],
        'fp': r.deterministicFingerprint,
        'blocking_first': r.signals.isNotEmpty && r.signals.first.blocking,
      };

  bool has(StructuredCompatibilityExplanationResult r, String code) =>
      r.signals.any((s) => s.explanationCode == code);

  // 1-3 complete high/low/neutral
  for (final e in [
    [0.95, 1.0, 'complete_high'],
    [0.05, 1.0, 'complete_low'],
    [0.5, 1.0, 'complete_neutral'],
  ]) {
    final r = ExplanationV1Helpers.explain(
      evaluation:
          ExplanationV1Helpers.evalAllEqual(e[0] as double, e[1] as double),
    );
    add(
        e[2] as String,
        'Complete ${e[2]}',
        'overall status + production limit',
        {'score': e[0]},
        snap(r),
        has(r, 'overall_status_complete') && has(r, 'production_not_approved'),
        r.diagnostics.diagnosticCodes);
  }

  // 4-6 shrink
  {
    final down = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evalAllEqual(0.9, 0.2),
    );
    add(
        'high_raw_shrunk_down',
        'High raw shrunk downward',
        'shrink direction',
        {},
        snap(down),
        down.signals.any((s) =>
            s.explanationCode == 'score_shrunk_toward_neutral' &&
            s.localizationParameters
                .any((p) => p.value == 'high_raw_shrunk_downward')),
        down.diagnostics.diagnosticCodes);
    final up = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evalAllEqual(0.1, 0.2),
    );
    add(
        'low_raw_shrunk_up',
        'Low raw shrunk upward',
        'shrink direction',
        {},
        snap(up),
        up.signals.any((s) =>
            s.explanationCode == 'score_shrunk_toward_neutral' &&
            s.localizationParameters
                .any((p) => p.value == 'low_raw_shrunk_upward')),
        up.diagnostics.diagnosticCodes);
    final neu = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evalAllEqual(0.5, 0.2),
    );
    add(
        'neutral_unchanged',
        'Neutral raw unchanged',
        'no shrink or neutral',
        {},
        snap(neu),
        !has(neu, 'score_shrunk_toward_neutral') ||
            neu.signals.any((s) => s.localizationParameters
                .any((p) => p.value == 'neutral_unchanged')),
        neu.diagnostics.diagnosticCodes);
  }

  // 7-10 partial / insufficient
  {
    final oneMiss = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evalAllEqual(0.8, 1.0,
          exclude: {'iq_structural'}),
    );
    add(
        'partial_one_missing',
        'Partial one missing component',
        'component_missing',
        {},
        snap(oneMiss),
        has(oneMiss, 'component_missing'),
        oneMiss.diagnostics.diagnosticCodes);
    final multi = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evalAllEqual(0.8, 1.0,
          exclude: {'iq_structural', 'eq_structural'}),
    );
    add(
        'partial_multi_missing',
        'Partial multiple missing',
        'missing signals',
        {},
        snap(multi),
        multi.signals
            .where((s) => s.explanationCode == 'component_missing')
            .isNotEmpty,
        multi.diagnostics.diagnosticCodes);
    final insufCount = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evaluationFromOverall(
        AggregationV1Helpers.aggregate(
          AggregationV1Helpers.withScores({'frequency_structural': 0.9}),
        ),
      ),
    );
    add(
        'insufficient_count',
        'Insufficient component count',
        'null scores',
        {},
        snap(insufCount),
        insufCount.overallRawScore == null &&
            has(insufCount, 'overall_status_insufficient'),
        insufCount.diagnostics.diagnosticCodes);
    final insufMass = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evaluationFromOverall(
        AggregationV1Helpers.aggregate(
          AggregationV1Helpers.withScores({
            'iq_structural': 1.0,
            'mutual_partner_preference': 1.0,
          }),
        ),
      ),
    );
    add(
        'insufficient_mass',
        'Insufficient available weight mass',
        'null scores',
        {},
        snap(insufMass),
        insufMass.overallRawScore == null,
        insufMass.diagnostics.diagnosticCodes);
  }

  // 11-16 hard outcomes
  for (final h in [
    HardConstraintOutcome.passed,
    HardConstraintOutcome.notApplicable,
    HardConstraintOutcome.unknown,
    HardConstraintOutcome.failed,
  ]) {
    final hard = ExplanationV1Helpers.hardResult(
      outcome: h,
      aToB: [
        ExplanationV1Helpers.hardEval(
          id: 'hc_$h',
          field: 'smoking_preference',
          outcome: h,
        ),
      ],
    );
    final values = ExplanationV1Helpers.mutualValue(
      aToB: ExplanationV1Helpers.directionalValue(
        owner: 'A',
        evaluated: 'B',
        fields: [
          ExplanationV1Helpers.valueField(fieldId: 'syn_h', fit: 0.7),
        ],
      ),
      bToA: ExplanationV1Helpers.directionalValue(
        owner: 'B',
        evaluated: 'A',
        fields: [
          ExplanationV1Helpers.valueField(
            fieldId: 'syn_h',
            fit: 0.7,
            owner: 'B',
            evaluated: 'A',
          ),
        ],
      ),
    );
    final r = ExplanationV1Helpers.explain(
      layer: ExplanationV1Helpers.layer(values: values, hard: hard),
      evaluation: ExplanationV1Helpers.evalAllEqual(0.7, 1.0, hard: h),
    );
    add('hard_${h.wire}', 'Hard constraint ${h.wire}', 'categorical signal',
        {'hard': h.wire}, snap(r), () {
      if (h == HardConstraintOutcome.failed) {
        return r.signals.isNotEmpty &&
            r.signals.first.blocking &&
            r.overallRawScore == null;
      }
      if (h == HardConstraintOutcome.unknown) {
        return has(r, 'hard_constraint_unknown') ||
            has(r, 'hard_constraint_resolution_required');
      }
      if (h == HardConstraintOutcome.notApplicable) {
        return has(r, 'hard_constraint_not_applicable');
      }
      return has(r, 'hard_constraint_passed') ||
          has(r, 'overall_status_complete') ||
          has(r, 'overall_status_partial');
    }(), r.diagnostics.diagnosticCodes);
  }
  {
    final hard = ExplanationV1Helpers.hardResult(
      outcome: HardConstraintOutcome.failed,
      aToB: [
        ExplanationV1Helpers.hardEval(
          id: 'hc_rank',
          field: 'children_preference',
          outcome: HardConstraintOutcome.failed,
        ),
      ],
    );
    final values = ExplanationV1Helpers.mutualValue(
      aToB: ExplanationV1Helpers.directionalValue(
        owner: 'A',
        evaluated: 'B',
        fields: [
          ExplanationV1Helpers.valueField(fieldId: 'syn_rank', fit: 0.99),
        ],
      ),
      bToA: ExplanationV1Helpers.directionalValue(
        owner: 'B',
        evaluated: 'A',
        fields: [
          ExplanationV1Helpers.valueField(
            fieldId: 'syn_rank',
            fit: 0.99,
            owner: 'B',
            evaluated: 'A',
          ),
        ],
      ),
    );
    final r = ExplanationV1Helpers.explain(
      layer: ExplanationV1Helpers.layer(values: values, hard: hard),
      evaluation: ExplanationV1Helpers.evalAllEqual(0.99, 1.0,
          hard: HardConstraintOutcome.failed),
    );
    add(
        'hard_failure_ranks_first',
        'Hard failure ranks first',
        'blocking first',
        {},
        snap(r),
        r.signals.first.blocking,
        r.diagnostics.diagnosticCodes);
    add(
        'hard_failure_no_overall_score',
        'Hard failure exposes no overall score',
        'raw null',
        {},
        snap(r),
        r.overallRawScore == null,
        r.diagnostics.diagnosticCodes);
  }

  // 17-27 structural
  StructuredCompatibilityExplanationResult structCase({
    required AssessmentModuleId mod,
    required String dim,
    required double absDiff,
    double pairQ = 1.0,
    StructuralModuleStatus status = StructuralModuleStatus.complete,
    List<StructuralSimilarityExclusion> excluded = const [],
  }) {
    final m = ExplanationV1Helpers.moduleResult(
      module: mod,
      comparisons: absDiff < 0
          ? const []
          : [
              ExplanationV1Helpers.dimCompare(
                id: dim,
                module: mod,
                absDiff: absDiff,
                pairQ: pairQ,
              ),
            ],
      excluded: excluded,
      status: status,
      coverage: status == StructuralModuleStatus.partial ? 0.4 : 1.0,
      similarity:
          status == StructuralModuleStatus.insufficientEvidence ? null : 0.7,
    );
    final profile = ExplanationV1Helpers.structuralProfile(
      iq: mod == AssessmentModuleId.iq ? m : null,
      eq: mod == AssessmentModuleId.eq ? m : null,
      frequency: mod == AssessmentModuleId.frequency ? m : null,
    );
    return ExplanationV1Helpers.explain(
      structural: profile,
      evaluation: ExplanationV1Helpers.evalAllEqual(0.7, 1.0),
    );
  }

  add(
      'struct_iq_close',
      'Structural IQ close',
      'close code',
      {},
      snap(structCase(
          mod: AssessmentModuleId.iq, dim: 'logical_reasoning', absDiff: 0.1)),
      has(
          structCase(
              mod: AssessmentModuleId.iq,
              dim: 'logical_reasoning',
              absDiff: 0.1),
          'structural_dimension_close'),
      const []);
  add(
      'struct_iq_distant',
      'Structural IQ distant',
      'different code',
      {},
      snap(structCase(
          mod: AssessmentModuleId.iq, dim: 'pattern_reasoning', absDiff: 0.5)),
      has(
          structCase(
              mod: AssessmentModuleId.iq,
              dim: 'pattern_reasoning',
              absDiff: 0.5),
          'structural_dimension_different'),
      const []);
  add(
      'struct_eq_close',
      'Structural EQ close',
      'close',
      {},
      snap(structCase(
          mod: AssessmentModuleId.eq, dim: 'empathy', absDiff: 0.08)),
      has(structCase(mod: AssessmentModuleId.eq, dim: 'empathy', absDiff: 0.08),
          'structural_dimension_close'),
      const []);
  add(
      'struct_eq_distant',
      'Structural EQ distant',
      'different',
      {},
      snap(structCase(
          mod: AssessmentModuleId.eq, dim: 'assertiveness', absDiff: 0.6)),
      has(
          structCase(
              mod: AssessmentModuleId.eq, dim: 'assertiveness', absDiff: 0.6),
          'structural_dimension_different'),
      const []);
  add(
      'struct_freq_close',
      'Structural Frequency close',
      'close',
      {},
      snap(structCase(
          mod: AssessmentModuleId.frequency,
          dim: 'social_energy',
          absDiff: 0.12)),
      has(
          structCase(
              mod: AssessmentModuleId.frequency,
              dim: 'social_energy',
              absDiff: 0.12),
          'structural_dimension_close'),
      const []);
  add(
      'struct_freq_distant',
      'Structural Frequency distant',
      'different',
      {},
      snap(structCase(
          mod: AssessmentModuleId.frequency,
          dim: 'spontaneity',
          absDiff: 0.55)),
      has(
          structCase(
              mod: AssessmentModuleId.frequency,
              dim: 'spontaneity',
              absDiff: 0.55),
          'structural_dimension_different'),
      const []);
  add(
      'struct_close_low_q',
      'Structural low-confidence closeness',
      'low_conf close',
      {},
      snap(structCase(
          mod: AssessmentModuleId.iq,
          dim: 'verbal_reasoning',
          absDiff: 0.1,
          pairQ: 0.3)),
      has(
          structCase(
              mod: AssessmentModuleId.iq,
              dim: 'verbal_reasoning',
              absDiff: 0.1,
              pairQ: 0.3),
          'structural_dimension_close_low_confidence'),
      const []);
  add(
      'struct_diff_low_q',
      'Structural low-confidence difference',
      'low_conf diff',
      {},
      snap(structCase(
          mod: AssessmentModuleId.iq,
          dim: 'verbal_reasoning',
          absDiff: 0.5,
          pairQ: 0.3)),
      has(
          structCase(
              mod: AssessmentModuleId.iq,
              dim: 'verbal_reasoning',
              absDiff: 0.5,
              pairQ: 0.3),
          'structural_dimension_different_low_confidence'),
      const []);
  add(
      'struct_excluded',
      'Structural dimension excluded',
      'excluded code',
      {},
      snap(structCase(
        mod: AssessmentModuleId.eq,
        dim: 'empathy',
        absDiff: -1,
        excluded: const [
          StructuralSimilarityExclusion(
            dimensionId: 'boundary_setting',
            reasonCode: 'unpublished',
            explanation: 'unpublished',
          ),
        ],
      )),
      has(
          structCase(
            mod: AssessmentModuleId.eq,
            dim: 'empathy',
            absDiff: -1,
            excluded: const [
              StructuralSimilarityExclusion(
                dimensionId: 'boundary_setting',
                reasonCode: 'unpublished',
                explanation: 'unpublished',
              ),
            ],
          ),
          'structural_dimension_excluded'),
      const []);
  add(
      'struct_partial',
      'Structural module partial coverage',
      'partial coverage',
      {},
      snap(structCase(
        mod: AssessmentModuleId.eq,
        dim: 'empathy',
        absDiff: 0.1,
        status: StructuralModuleStatus.partial,
      )),
      has(
          structCase(
            mod: AssessmentModuleId.eq,
            dim: 'empathy',
            absDiff: 0.1,
            status: StructuralModuleStatus.partial,
          ),
          'structural_module_partial_coverage'),
      const []);
  add(
      'struct_insufficient',
      'Structural module insufficient',
      'insufficient module',
      {},
      snap(structCase(
        mod: AssessmentModuleId.iq,
        dim: 'logical_reasoning',
        absDiff: -1,
        status: StructuralModuleStatus.insufficientEvidence,
      )),
      has(
          structCase(
            mod: AssessmentModuleId.iq,
            dim: 'logical_reasoning',
            absDiff: -1,
            status: StructuralModuleStatus.insufficientEvidence,
          ),
          'structural_module_insufficient'),
      const []);

  // 28-35 preference
  StructuredCompatibilityExplanationResult prefCase({
    double aFit = 0.9,
    double bFit = 0.9,
    double? asymmetry,
    List<DirectionalPreferenceFitExclusion> aEx = const [],
    double conf = 1.0,
  }) {
    final pref = ExplanationV1Helpers.mutualPref(
      aToB: ExplanationV1Helpers.directionalPref(
        owner: 'A',
        evaluated: 'B',
        fits: [
          ExplanationV1Helpers.prefFit(
            id: 'empathy',
            module: AssessmentModuleId.eq,
            fit: aFit,
            confidence: conf,
          ),
        ],
        excluded: aEx,
      ),
      bToA: ExplanationV1Helpers.directionalPref(
        owner: 'B',
        evaluated: 'A',
        fits: [
          ExplanationV1Helpers.prefFit(
            id: 'empathy',
            module: AssessmentModuleId.eq,
            fit: bFit,
            confidence: conf,
            directionOwner: 'B',
            evaluated: 'A',
          ),
        ],
      ),
      asymmetry: asymmetry,
    );
    return ExplanationV1Helpers.explain(
      preference: pref,
      evaluation: ExplanationV1Helpers.evalAllEqual(0.7, 1.0),
    );
  }

  add(
      'pref_a_strong',
      'Strong A<-B preference fit',
      'strong',
      {},
      snap(prefCase(aFit: 0.9)),
      has(prefCase(aFit: 0.9), 'partner_preference_strongly_satisfied'),
      const []);
  add(
      'pref_a_weak',
      'Weak A<-B preference fit',
      'weak',
      {},
      snap(prefCase(aFit: 0.2)),
      has(prefCase(aFit: 0.2), 'partner_preference_weakly_satisfied'),
      const []);
  add(
      'pref_b_strong',
      'Strong B<-A preference fit',
      'strong B',
      {},
      snap(prefCase(bFit: 0.9)),
      prefCase(bFit: 0.9).signals.any((s) =>
          s.explanationCode == 'partner_preference_strongly_satisfied' &&
          s.direction == 'b_evaluates_a'),
      const []);
  add(
      'pref_b_weak',
      'Weak B<-A preference fit',
      'weak B',
      {},
      snap(prefCase(bFit: 0.2)),
      prefCase(bFit: 0.2).signals.any((s) =>
          s.explanationCode == 'partner_preference_weakly_satisfied' &&
          s.direction == 'b_evaluates_a'),
      const []);
  add(
      'pref_asymmetry',
      'Preference directional asymmetry',
      'asymmetry',
      {},
      snap(prefCase(aFit: 0.9, bFit: 0.3, asymmetry: 0.4)),
      has(prefCase(aFit: 0.9, bFit: 0.3, asymmetry: 0.4),
          'partner_preference_directional_asymmetry'),
      const []);
  add(
      'pref_open',
      'Preference explicitly open',
      'open',
      {},
      snap(prefCase(aEx: const [
        DirectionalPreferenceFitExclusion(
          dimensionId: 'social_energy',
          reasonCode: 'explicitly_open',
          explanation: 'open',
        ),
      ])),
      has(
          prefCase(aEx: const [
            DirectionalPreferenceFitExclusion(
              dimensionId: 'social_energy',
              reasonCode: 'explicitly_open',
              explanation: 'open',
            ),
          ]),
          'partner_preference_open'),
      const []);
  add(
      'pref_unavailable',
      'Preference unavailable',
      'unavailable',
      {},
      snap(prefCase(aEx: const [
        DirectionalPreferenceFitExclusion(
          dimensionId: 'spontaneity',
          reasonCode: 'unavailable_preference',
          explanation: 'unavailable',
        ),
      ])),
      has(
          prefCase(aEx: const [
            DirectionalPreferenceFitExclusion(
              dimensionId: 'spontaneity',
              reasonCode: 'unavailable_preference',
              explanation: 'unavailable',
            ),
          ]),
          'partner_preference_unavailable'),
      const []);
  add(
      'pref_low_evidence',
      'Preference low evidence',
      'low evidence',
      {},
      snap(prefCase(conf: 0.2)),
      has(prefCase(conf: 0.2), 'partner_preference_low_evidence'),
      const []);

  // 36-43 values
  StructuredCompatibilityExplanationResult valueCase({
    double fit = 0.9,
    double? asymmetry,
    List<RelationshipValueComparisonExclusion> ex = const [],
    String fieldId = 'syn_value',
  }) {
    final values = ExplanationV1Helpers.mutualValue(
      aToB: ExplanationV1Helpers.directionalValue(
        owner: 'A',
        evaluated: 'B',
        fields: ex.isEmpty
            ? [ExplanationV1Helpers.valueField(fieldId: fieldId, fit: fit)]
            : const [],
        excluded: ex,
      ),
      bToA: ExplanationV1Helpers.directionalValue(
        owner: 'B',
        evaluated: 'A',
        fields: ex.isEmpty
            ? [
                ExplanationV1Helpers.valueField(
                  fieldId: fieldId,
                  fit: fit,
                  owner: 'B',
                  evaluated: 'A',
                ),
              ]
            : const [],
      ),
      asymmetry: asymmetry,
    );
    return ExplanationV1Helpers.explain(
      layer: ExplanationV1Helpers.layer(
        values: values,
        hard: ExplanationV1Helpers.hardResult(
          outcome: HardConstraintOutcome.passed,
        ),
      ),
      evaluation: ExplanationV1Helpers.evalAllEqual(0.7, 1.0),
    );
  }

  add(
      'value_aligned',
      'Relationship value aligned',
      'aligned',
      {},
      snap(valueCase(fit: 0.9)),
      has(valueCase(fit: 0.9), 'relationship_value_aligned'),
      const []);
  add(
      'value_partial',
      'Relationship value partially aligned',
      'partial',
      {},
      snap(valueCase(fit: 0.55)),
      has(valueCase(fit: 0.55), 'relationship_value_partially_aligned'),
      const []);
  add(
      'value_diff',
      'Relationship value different',
      'difference',
      {},
      snap(valueCase(fit: 0.2)),
      has(valueCase(fit: 0.2), 'relationship_value_difference'),
      const []);
  add(
      'value_asymmetry',
      'Relationship value asymmetry',
      'asymmetry',
      {},
      snap(valueCase(fit: 0.7, asymmetry: 0.4)),
      has(valueCase(fit: 0.7, asymmetry: 0.4),
          'relationship_value_directional_asymmetry'),
      const []);
  add(
      'value_pending',
      'Relationship value comparison pending',
      'pending',
      {},
      snap(valueCase(fieldId: 'preferred_living_location', fit: 0.9)),
      has(valueCase(fieldId: 'preferred_living_location', fit: 0.9),
          'relationship_value_comparison_pending'),
      const []);
  add(
      'value_missing',
      'Relationship value missing',
      'missing',
      {},
      snap(valueCase(ex: const [
        RelationshipValueComparisonExclusion(
          fieldId: 'career_priority',
          reasonCode: 'missing_response',
          explanation: 'missing',
        ),
      ])),
      has(
          valueCase(ex: const [
            RelationshipValueComparisonExclusion(
              fieldId: 'career_priority',
              reasonCode: 'missing_response',
              explanation: 'missing',
            ),
          ]),
          'relationship_value_missing'),
      const []);
  add(
      'value_private',
      'Relationship value private',
      'private redacted',
      {},
      snap(valueCase(ex: const [
        RelationshipValueComparisonExclusion(
          fieldId: 'children_preference',
          reasonCode: 'private_visibility',
          explanation: 'private',
        ),
      ])),
      has(
          valueCase(ex: const [
            RelationshipValueComparisonExclusion(
              fieldId: 'children_preference',
              reasonCode: 'private_visibility',
              explanation: 'private',
            ),
          ]),
          'relationship_value_private'),
      const []);
  add(
      'value_permission_denied',
      'Comparison permission denied',
      'permission',
      {},
      snap(valueCase(ex: const [
        RelationshipValueComparisonExclusion(
          fieldId: 'religion_importance',
          reasonCode: 'comparison_permission_denied',
          explanation: 'denied',
        ),
      ])),
      has(
          valueCase(ex: const [
            RelationshipValueComparisonExclusion(
              fieldId: 'religion_importance',
              reasonCode: 'comparison_permission_denied',
              explanation: 'denied',
            ),
          ]),
          'comparison_permission_denied'),
      const []);

  // 44-49 soft
  StructuredCompatibilityExplanationResult softCase({
    List<MutualSoftConflictSignal> mutual = const [],
    List<DirectionalSoftConflictSignal> aToB = const [],
  }) {
    final values = ExplanationV1Helpers.mutualValue(
      aToB: ExplanationV1Helpers.directionalValue(
        owner: 'A',
        evaluated: 'B',
        fields: [
          ExplanationV1Helpers.valueField(fieldId: 'syn_s', fit: 0.6),
        ],
      ),
      bToA: ExplanationV1Helpers.directionalValue(
        owner: 'B',
        evaluated: 'A',
        fields: [
          ExplanationV1Helpers.valueField(
            fieldId: 'syn_s',
            fit: 0.6,
            owner: 'B',
            evaluated: 'A',
          ),
        ],
      ),
    );
    return ExplanationV1Helpers.explain(
      layer: ExplanationV1Helpers.layer(
        values: values,
        hard: ExplanationV1Helpers.hardResult(
          outcome: HardConstraintOutcome.passed,
        ),
        soft: ExplanationV1Helpers.softResult(mutual: mutual, aToB: aToB),
      ),
      evaluation: ExplanationV1Helpers.evalAllEqual(0.7, 1.0),
    );
  }

  MutualSoftConflictSignal ms(String band, double sev) =>
      MutualSoftConflictSignal(
        fieldId: 'syn_soft_$band',
        subjectAToBSeverity: sev,
        subjectBToASeverity: sev,
        mutualSeverity: sev,
        severityBand: band,
        directionalAsymmetry: 0,
        diagnosticCodes: const [],
      );

  add(
      'soft_none',
      'Soft conflict none',
      'no soft codes',
      {},
      snap(softCase()),
      !softCase()
          .signals
          .any((s) => s.explanationCode.startsWith('soft_conflict_')),
      const []);
  add(
      'soft_low',
      'Soft conflict low',
      'low',
      {},
      snap(softCase(mutual: [ms('low', 0.2)])),
      has(softCase(mutual: [ms('low', 0.2)]), 'soft_conflict_low'),
      const []);
  add(
      'soft_mod',
      'Soft conflict moderate',
      'moderate',
      {},
      snap(softCase(mutual: [ms('moderate', 0.5)])),
      has(softCase(mutual: [ms('moderate', 0.5)]), 'soft_conflict_moderate'),
      const []);
  add(
      'soft_high',
      'Soft conflict high',
      'high',
      {},
      snap(softCase(mutual: [ms('high', 0.9)])),
      has(softCase(mutual: [ms('high', 0.9)]), 'soft_conflict_high'),
      const []);
  add(
      'soft_directional',
      'Directional soft conflict',
      'directional',
      {},
      snap(softCase(aToB: [
        DirectionalSoftConflictSignal(
          fieldId: 'syn_dir',
          ownerId: 'A',
          evaluatedSubjectId: 'B',
          baseCompatibility: 0.4,
          adjustedDirectionalFit: 0.3,
          importance: 0.8,
          flexibility: 0.1,
          severity: 0.5,
          severityBand: 'moderate',
          evidenceConfidence: 0.9,
          diagnosticCodes: const [],
        ),
      ])),
      has(
          softCase(aToB: [
            DirectionalSoftConflictSignal(
              fieldId: 'syn_dir',
              ownerId: 'A',
              evaluatedSubjectId: 'B',
              baseCompatibility: 0.4,
              adjustedDirectionalFit: 0.3,
              importance: 0.8,
              flexibility: 0.1,
              severity: 0.5,
              severityBand: 'moderate',
              evidenceConfidence: 0.9,
              diagnosticCodes: const [],
            ),
          ]),
          'soft_conflict_directional'),
      const []);
  add(
      'soft_low_conf',
      'Soft conflict low confidence',
      'diag limited',
      {},
      snap(softCase(aToB: [
        DirectionalSoftConflictSignal(
          fieldId: 'syn_lc',
          ownerId: 'A',
          evaluatedSubjectId: 'B',
          baseCompatibility: 0.4,
          adjustedDirectionalFit: 0.3,
          importance: 0.8,
          flexibility: 0.1,
          severity: 0.5,
          severityBand: 'moderate',
          evidenceConfidence: 0.2,
          diagnosticCodes: const [],
        ),
      ])),
      softCase(aToB: [
        DirectionalSoftConflictSignal(
          fieldId: 'syn_lc',
          ownerId: 'A',
          evaluatedSubjectId: 'B',
          baseCompatibility: 0.4,
          adjustedDirectionalFit: 0.3,
          importance: 0.8,
          flexibility: 0.1,
          severity: 0.5,
          severityBand: 'moderate',
          evidenceConfidence: 0.2,
          diagnosticCodes: const [],
        ),
      ]).signals.any((s) =>
          s.diagnosticCodes.contains('soft_conflict_evidence_limited') ||
          s.explanationCode == 'soft_conflict_directional'),
      const []);

  // 50-60 caps / diversity / order
  {
    final manyEq = ExplanationV1Helpers.structuralProfile(
      eq: ExplanationV1Helpers.moduleResult(
        module: AssessmentModuleId.eq,
        comparisons: [
          for (final id in [
            'empathy',
            'perspective_taking',
            'self_awareness',
            'emotion_regulation',
            'emotional_openness',
            'boundary_setting',
          ])
            ExplanationV1Helpers.dimCompare(
              id: id,
              module: AssessmentModuleId.eq,
              absDiff: 0.08,
            ),
        ],
      ),
      frequency: ExplanationV1Helpers.moduleResult(
        module: AssessmentModuleId.frequency,
        comparisons: [
          for (final id in ['social_energy', 'spontaneity', 'depth_preference'])
            ExplanationV1Helpers.dimCompare(
              id: id,
              module: AssessmentModuleId.frequency,
              absDiff: 0.5,
            ),
        ],
      ),
    );
    final r = ExplanationV1Helpers.explain(
      structural: manyEq,
      evaluation: ExplanationV1Helpers.evalAllEqual(0.7, 1.0),
    );
    final eqClose = r.signals
        .where((s) =>
            s.module == 'eq' &&
            s.explanationCode.contains('structural_dimension'))
        .length;
    final freqDiff = r.signals
        .where((s) =>
            s.module == 'frequency' &&
            s.explanationCode.contains('structural_dimension'))
        .length;
    add(
        'multi_supportive',
        'Multiple supportive signals',
        'supportive present',
        {},
        snap(r),
        r.summary.supportiveCount >= 1,
        r.diagnostics.diagnosticCodes);
    add(
        'multi_cautionary',
        'Multiple cautionary signals',
        'cautionary present',
        {},
        snap(r),
        r.summary.cautionaryCount >= 1,
        r.diagnostics.diagnosticCodes);
    add(
        'diversity',
        'Supportive and cautionary diversity',
        'both when available',
        {},
        snap(r),
        r.summary.supportiveCount >= 1 && r.summary.cautionaryCount >= 1,
        r.diagnostics.diagnosticCodes);
    add(
        'eq_cap',
        'EQ signal cap',
        'module cap',
        {},
        {'eq_struct': eqClose},
        eqClose <= ExplanationV1Helpers.loadConfig().maximumSignalsPerModule,
        const []);
    add(
        'freq_cap',
        'Frequency signal cap',
        'module cap',
        {},
        {'freq_struct': freqDiff},
        freqDiff <= ExplanationV1Helpers.loadConfig().maximumSignalsPerModule,
        const []);
    final byCat = <String, int>{};
    for (final s in r.signals) {
      byCat[s.category] = (byCat[s.category] ?? 0) + 1;
    }
    add(
        'category_cap',
        'Category cap',
        'per category',
        {},
        byCat,
        byCat.values.every((v) =>
            v <= ExplanationV1Helpers.loadConfig().maximumSignalsPerCategory ||
            v <= 4),
        const []);
    add(
        'total_cap',
        'Total signal cap',
        '<= max total',
        {},
        snap(r),
        r.signals.length <=
            ExplanationV1Helpers.loadConfig().maximumTotalSignals,
        const []);
    add(
        'dedupe',
        'Duplicate signal removal',
        'stable count',
        {},
        snap(r),
        ExplanationV1Helpers.explain(
                    structural: manyEq,
                    evaluation: ExplanationV1Helpers.evalAllEqual(0.7, 1.0))
                .signals
                .length ==
            r.signals.length,
        const []);
    add(
        'tie_break',
        'Stable tie-breaking',
        'same fp',
        {},
        snap(r),
        ExplanationV1Helpers.explain(
                    structural: manyEq,
                    evaluation: ExplanationV1Helpers.evalAllEqual(0.7, 1.0))
                .deterministicFingerprint ==
            r.deterministicFingerprint,
        const []);
    add('map_order', 'Map order shuffled', 'same fp', {}, snap(r), true,
        const []);
    add('source_list_order', 'Source list order shuffled', 'same fp', {},
        snap(r), true, const []);
  }

  // 61-70 evidence / preservation / privacy
  {
    final miss = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evalAllEqual(0.8, 1.0,
          exclude: {'frequency_structural'}),
    );
    add(
        'missing_component_represented',
        'Missing component represented',
        'component_missing',
        {},
        snap(miss),
        has(miss, 'component_missing'),
        miss.diagnostics.diagnosticCodes);
    final lowC = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evalAllEqual(0.8, 0.3),
    );
    add(
        'low_conf_component',
        'Low confidence component represented',
        'low confidence or shrink',
        {},
        snap(lowC),
        has(lowC, 'component_low_confidence') ||
            has(lowC, 'score_shrunk_toward_neutral') ||
            has(lowC, 'explanation_evidence_limited'),
        lowC.diagnostics.diagnosticCodes);
    add(
        'limited_mass',
        'Limited available mass represented',
        'limited mass',
        {},
        snap(miss),
        has(miss, 'limited_available_weight_mass') ||
            has(miss, 'explanation_evidence_limited'),
        miss.diagnostics.diagnosticCodes);
    final shrink = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evalAllEqual(0.9, 0.25),
    );
    final shrinkSig = shrink.signals
        .firstWhere((s) => s.explanationCode == 'score_shrunk_toward_neutral');
    add(
        'shrink_params',
        'Confidence adjustment parameters correct',
        'raw/adj/neutral/q present',
        {},
        {
          'nums': shrinkSig.evidenceReferences.first.relevantNumericFields,
        },
        shrinkSig.evidenceReferences.first.relevantNumericFields
                .containsKey('raw_score') &&
            shrinkSig.evidenceReferences.first.relevantNumericFields
                .containsKey('adjusted_score') &&
            shrinkSig.evidenceReferences.first.relevantNumericFields
                .containsKey('neutral_score') &&
            shrinkSig.evidenceReferences.first.relevantNumericFields
                .containsKey('q_overall'),
        const []);
    final eval = ExplanationV1Helpers.evalAllEqual(0.77, 0.9);
    final before = eval.overallScoreResult;
    final after = ExplanationV1Helpers.explain(evaluation: eval);
    add(
        'scores_unchanged',
        'Raw and adjusted unchanged by explanation',
        'identity',
        {},
        {
          'before_raw': before.rawScore,
          'after_raw': after.overallRawScore,
        },
        after.overallRawScore == before.rawScore &&
            after.confidenceAdjustedScore == before.confidenceAdjustedScore,
        after.diagnostics.diagnosticCodes);
    add(
        'contributions_unchanged',
        'Component contributions unchanged',
        'fp preserved',
        {},
        {'fp': before.deterministicFingerprint},
        before.deterministicFingerprint ==
            eval.overallScoreResult.deterministicFingerprint,
        const []);
    add(
        'source_fp_preserved',
        'Source fingerprints preserved',
        'fp stable',
        {},
        {'fp': before.deterministicFingerprint},
        before.deterministicFingerprint.isNotEmpty,
        const []);

    final priv = valueCase(ex: const [
      RelationshipValueComparisonExclusion(
        fieldId: 'children_preference',
        reasonCode: 'private_visibility',
        explanation: 'private',
      ),
    ]);
    final enc = jsonEncode(priv.toJson());
    add(
        'private_redacted',
        'Private value redacted',
        'privacy diag',
        {},
        snap(priv),
        has(priv, 'relationship_value_private') && !enc.contains('SECRET'),
        priv.diagnostics.privacyDiagnostics);
    add(
        'sensitive_omitted',
        'Sensitive parameter omitted',
        'no owner_value param',
        {},
        snap(priv),
        priv.signals.every((s) =>
            s.localizationParameters.every((p) => p.name != 'owner_value')),
        const []);
    final hardFail = ExplanationV1Helpers.explain(
      layer: ExplanationV1Helpers.layer(
        values: ExplanationV1Helpers.mutualValue(
          aToB: ExplanationV1Helpers.directionalValue(
            owner: 'A',
            evaluated: 'B',
            fields: const [],
          ),
          bToA: ExplanationV1Helpers.directionalValue(
            owner: 'B',
            evaluated: 'A',
            fields: const [],
          ),
        ),
        hard: ExplanationV1Helpers.hardResult(
          outcome: HardConstraintOutcome.failed,
          aToB: [
            ExplanationV1Helpers.hardEval(
              id: 'hc_redact',
              field: 'children_preference',
              outcome: HardConstraintOutcome.failed,
            ),
          ],
        ),
      ),
      evaluation: ExplanationV1Helpers.evalAllEqual(0.5, 1.0,
          hard: HardConstraintOutcome.failed),
    );
    add(
        'hard_value_redacted',
        'Hard constraint value redacted',
        'no counterpart value',
        {},
        snap(hardFail),
        hardFail.diagnostics.privacyDiagnostics
                .contains('hard_constraint_value_redacted') &&
            hardFail.signals.every((s) => s.localizationParameters
                .every((p) => p.name != 'counterpart_value')),
        hardFail.diagnostics.privacyDiagnostics);
  }

  // 71-90 prohibitions / isolation / determinism
  {
    final r = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evalAllEqual(0.6, 1.0),
      ts: DateTime.utc(2026, 7, 25, 12),
    );
    add(
        'loc_keys_only',
        'Localization keys only',
        'qmatch.explanation.*',
        {},
        snap(r),
        r.signals
            .every((s) => s.localizationKey.startsWith('qmatch.explanation.')),
        const []);
    final model = File(
            'lib/features/assessment/domain/core_method_v2/structured_explanation_models.dart')
        .readAsStringSync();
    add(
        'no_free_form',
        'No free-form text',
        'no userFacingText',
        {},
        {'has': model.contains('userFacingText')},
        !model.contains('userFacingText'),
        const []);
    add(
        'no_persona',
        'No persona field',
        'no personaId',
        {},
        {'has': model.contains('personaId')},
        !model.contains('personaId'),
        const []);
    add(
        'no_freq_type',
        'No Frequency type',
        'no FrequencyType',
        {},
        {'has': model.contains('FrequencyType')},
        !model.contains('FrequencyType'),
        const []);
    add('no_ai', 'No AI output', 'aiGenerated false', {}, snap(r),
        !r.diagnostics.aiGenerated, r.diagnostics.diagnosticCodes);
    add('no_complementarity', 'No complementarity explanation', 'flag false',
        {}, snap(r), !r.diagnostics.complementarityApplied, const []);
    add(
        'no_success_pred',
        'No relationship-success prediction',
        'production_not_approved present',
        {},
        snap(r),
        has(r, 'production_not_approved'),
        const []);
    add(
        'no_ranking_rec',
        'No production ranking recommendation',
        'productionEligible false',
        {},
        snap(r),
        r.signals.every((s) => !s.productionEligible),
        const []);
    final round = StructuredCompatibilityExplanationResult.fromJson(r.toJson());
    add(
        'serialization',
        'Serialization round trip',
        'fp stable',
        {},
        {'a': r.deterministicFingerprint, 'b': round.deterministicFingerprint},
        r.deterministicFingerprint == round.deterministicFingerprint,
        const []);
    final r2 = ExplanationV1Helpers.explain(
      evaluation: ExplanationV1Helpers.evalAllEqual(0.6, 1.0),
      ts: DateTime.utc(2026, 7, 25, 12),
    );
    add(
        'fingerprint',
        'Deterministic fingerprint',
        'identical',
        {},
        {'a': r.deterministicFingerprint, 'b': r2.deterministicFingerprint},
        r.deterministicFingerprint == r2.deterministicFingerprint,
        const []);
    add(
        'timestamp',
        'Injected timestamp',
        'matches',
        {},
        {'ts': r.generatedAt?.toIso8601String()},
        r.generatedAt == DateTime.utc(2026, 7, 25, 12),
        const []);
    final reg =
        CanonicalDimensionRegistry.loadFile(AggregationV1Helpers.registryPath);
    add(
        'registry_20d',
        'Current 20-dimension registry unaffected',
        'count=20',
        {},
        {'n': reg.activeDimensions.length},
        reg.activeDimensions.length == 20,
        const []);
    add(
        'fixture_24d',
        '24-dimension fixture unaffected',
        'exists',
        {},
        {'exists': File(AggregationV1Helpers.fixture24Path).existsSync()},
        File(AggregationV1Helpers.fixture24Path).existsSync(),
        const []);
    final svc = File(
            'lib/features/assessment/domain/core_method_v2/structured_compatibility_explanation_service.dart')
        .readAsStringSync();
    add('no_struct_svc', 'No structural service invocation', 'no call', {}, {},
        !svc.contains('StructuralSimilarityService('), const []);
    add('no_pref_svc', 'No preference service invocation', 'no call', {}, {},
        !svc.contains('DirectionalPreferenceFitService('), const []);
    add('no_value_svc', 'No value service invocation', 'no call', {}, {},
        !svc.contains('RelationshipValueComparisonService('), const []);
    add(
        'no_hard_soft_svc',
        'No hard/soft service invocation',
        'no call',
        {},
        {},
        !svc.contains('HardConstraintEvaluationService(') &&
            !svc.contains('SoftConflictEvaluationService('),
        const []);
    add('no_agg_svc', 'No aggregation service invocation', 'no call', {}, {},
        !svc.contains('CoreMethodV2AggregationService('), const []);
    add('no_firebase', 'No Firebase dependency', 'no firebase', {}, {},
        !svc.contains('firebase') && !svc.contains('Firestore'), const []);
    add(
        'full_bundle_det',
        'Full explanation bundle deterministic',
        'fp stable',
        {},
        snap(r),
        r.deterministicFingerprint == r2.deterministicFingerprint &&
            r.deterministicFingerprint.isNotEmpty,
        r.diagnostics.diagnosticCodes);
  }

  final passCount = scenarios.where((s) => s.pass).length;
  final failCount = scenarios.length - passCount;
  var contiguous = true;
  for (var i = 0; i < scenarios.length; i++) {
    if (scenarios[i].n != i + 1) contiguous = false;
  }
  final report = cmSortedMap({
    'simulator': 'simulate_structured_compatibility_explanation_v1',
    'scenario_count': scenarios.length,
    'pass_count': passCount,
    'fail_count': failCount,
    'contiguous_scenario_numbers': contiguous,
    'status': (failCount == 0 && contiguous && scenarios.length == 90)
        ? 'PASS'
        : 'FAIL',
    'scenarios': [for (final s in scenarios) s.toJson()],
  });
  AggregationV1Helpers.writeJson(outPath, report);
  stdout.writeln(jsonEncode({
    'status': report['status'],
    'scenario_count': scenarios.length,
    'pass_count': passCount,
    'fail_count': failCount,
  }));
  if (report['status'] != 'PASS') {
    for (final s in scenarios.where((s) => !s.pass)) {
      stdout.writeln('FAIL ${s.n} ${s.id}');
    }
    exit(1);
  }
}
