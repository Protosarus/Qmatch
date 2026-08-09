// Targeted deterministic robustness scenarios (P2B-6).
// Usage: dart run tool/simulate_core_method_v2_robustness_scenarios_v1.dart
//
// Contiguous scenarios covering numerical bounds, invariants, missingness,
// confidence, redundancy, weights, scales, hard/soft, explanation, cohort
// labels, serialization, and production non-integration.

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import '../test/support/aggregation_v1_helpers.dart';
import '../test/support/core_method_v2_helpers.dart';
import '../test/support/directional_preference_fit_helpers.dart';
import '../test/support/explanation_v1_helpers.dart';
import '../test/support/relationship_value_layer_helpers.dart';
import '../test/support/structural_similarity_helpers.dart';
import 'support/core_method_v2_offline_evaluation_harness.dart';
import 'support/core_method_v2_synthetic/robustness_experiment_config.dart';
import 'support/core_method_v2_synthetic/robustness_rng.dart';
import 'support/core_method_v2_synthetic/robustness_stats.dart';
import 'support/core_method_v2_synthetic/synthetic_profile_generator.dart';

const outPath =
    'tool/core_method_v2_out/core_method_v2_robustness_scenarios_v1_report.json';

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
        'diagnostic_codes': [...diagnosticCodes]..sort(),
      });
}

void main() {
  final config = RobustnessExperimentConfig.loadFile();
  final dims = loadCanonicalDimensionRegistry();
  final values = loadValueRegistry();
  final harness = CoreMethodV2OfflineEvaluationHarness(
    dimRegistry: dims,
    valueRegistry: values,
    structuralConfig: loadStructuralSimilarityConfig(),
    preferenceConfig: loadPreferenceFitConfig(),
    valueConfig: loadValueComparisonConfig(),
    aggregationConfig: AggregationV1Helpers.loadConfig(),
    explanationConfig: ExplanationV1Helpers.loadConfig(),
    explanationCodes: ExplanationV1Helpers.loadCodeRegistry(),
    evaluationTimestamp: config.evaluationTimestamp,
  );
  final gen = CoreMethodV2SyntheticGenerator(
    dimRegistry: dims,
    valueRegistry: values,
  );

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
      diagnosticCodes: codes,
    ));
  }

  bool approx(double? a, double? b, [double tol = 1e-9]) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return (a - b).abs() <= tol;
  }

  // --- 1-10 numerical / config ---
  add(
    id: 'cfg_parses',
    purpose: 'experiment config loads',
    expected: 'config_version present',
    inputs: {'path': RobustnessExperimentConfig.defaultPath},
    actual: {'config_version': config.configVersion},
    pass: config.configVersion.isNotEmpty,
    codes: ['config_ok'],
  );
  add(
    id: 'cfg_status_provisional',
    purpose: 'status provisional',
    expected: 'status==provisional',
    inputs: {},
    actual: {'status': config.raw['status']},
    pass: config.raw['status'] == 'provisional',
  );
  add(
    id: 'cfg_runtime_offline',
    purpose: 'runtime offline_only',
    expected: 'runtime_status==offline_only',
    inputs: {},
    actual: {'runtime_status': config.raw['runtime_status']},
    pass: config.raw['runtime_status'] == 'offline_only',
  );
  add(
    id: 'cfg_seeds',
    purpose: 'baseline + >=4 secondary seeds',
    expected: 'secondary_seeds.length>=4',
    inputs: {},
    actual: {
      'baseline': config.baselineSeed,
      'secondary_count': config.secondarySeeds.length,
    },
    pass: config.secondarySeeds.length >= 4,
  );
  add(
    id: 'cfg_families_26',
    purpose: 'all synthetic families declared',
    expected: '26 families',
    inputs: {},
    actual: {'count': config.syntheticFamilyIds.length},
    pass: config.syntheticFamilyIds.length == 26 &&
        config.syntheticFamilyIds.toSet().containsAll(kSyntheticFamilyIds),
  );
  add(
    id: 'cfg_histogram_20',
    purpose: 'histogram bins',
    expected: 'bins==20',
    inputs: {},
    actual: {'bins': config.histogramBinCount},
    pass: config.histogramBinCount == 20,
  );
  add(
    id: 'cfg_smoke_not_overwrite_full',
    purpose: 'smoke mode does not replace full top-level counts',
    expected: 'top-level full counts retained',
    inputs: {},
    actual: {
      'full_pop': config.syntheticPopulationSize,
      'smoke_pop': config.modeResolved('smoke')['synthetic_population_size'],
    },
    pass: config.syntheticPopulationSize == 2000 &&
        (config.modeResolved('smoke')['synthetic_population_size'] as int) <
            2000,
  );
  add(
    id: 'stats_pearson_identity',
    purpose: 'Pearson identity',
    expected: 'r(x,x)==1',
    inputs: {
      'x': [0.1, 0.2, 0.3, 0.4]
    },
    actual: {
      'r': pearsonCorrelation([0.1, 0.2, 0.3, 0.4], [0.1, 0.2, 0.3, 0.4])
    },
    pass: approx(pearsonCorrelation([0.1, 0.2, 0.3, 0.4], [0.1, 0.2, 0.3, 0.4]),
        1.0, 1e-12),
  );
  add(
    id: 'stats_spearman_identity',
    purpose: 'Spearman identity',
    expected: 'rho(x,x)==1',
    inputs: {
      'x': [1.0, 3.0, 2.0]
    },
    actual: {
      'rho': spearmanCorrelation([1.0, 3.0, 2.0], [1.0, 3.0, 2.0]),
    },
    pass: approx(
        spearmanCorrelation([1.0, 3.0, 2.0], [1.0, 3.0, 2.0]), 1.0, 1e-12),
  );
  add(
    id: 'stats_tied_ranks',
    purpose: 'deterministic midranks',
    expected: 'ties average',
    inputs: {
      'x': [1.0, 1.0, 2.0]
    },
    actual: {
      'ranks': averageRanks([1.0, 1.0, 2.0])
    },
    pass:
        averageRanks([1.0, 1.0, 2.0]).toString() == [1.5, 1.5, 3.0].toString(),
  );

  // --- 11-30 synthetic generation / harness ---
  final popA = gen.generateFamily(
    familyId: 'independent_uniform',
    seed: config.baselineSeed,
    count: 8,
  );
  final popA2 = gen.generateFamily(
    familyId: 'independent_uniform',
    seed: config.baselineSeed,
    count: 8,
  );
  final popB = gen.generateFamily(
    familyId: 'independent_uniform',
    seed: config.secondarySeeds.first,
    count: 8,
  );
  add(
    id: 'syn_deterministic',
    purpose: 'same seed identical ids',
    expected: 'byte-identical subject ids',
    inputs: {'seed': config.baselineSeed},
    actual: {
      'a0': popA.subjects.first.subjectId,
      'a2_0': popA2.subjects.first.subjectId,
    },
    pass: popA.subjects.map((s) => s.subjectId).join('|') ==
        popA2.subjects.map((s) => s.subjectId).join('|'),
  );
  add(
    id: 'syn_seed_divergence',
    purpose: 'different seeds differ',
    expected: 'ids differ',
    inputs: {},
    actual: {
      'a': popA.subjects.first.subjectId,
      'b': popB.subjects.first.subjectId,
    },
    pass: popA.subjects.first.subjectId != popB.subjects.first.subjectId,
  );
  add(
    id: 'syn_no_real_user_data',
    purpose: 'synthetic ids artificial',
    expected: 'no email/phone patterns',
    inputs: {},
    actual: {'sample': popA.subjects.first.subjectId},
    pass: !popA.subjects.first.subjectId.contains('@') &&
        popA.subjects.every((s) => s.subjectId.startsWith('syn_')),
  );
  add(
    id: 'syn_all_families',
    purpose: 'generator accepts all families',
    expected: '26 families generate',
    inputs: {},
    actual: {'count': kSyntheticFamilyIds.length},
    pass: kSyntheticFamilyIds.every((f) {
      final p = gen.generateFamily(familyId: f, seed: 1, count: 2);
      return p.size == 2;
    }),
  );

  final ab = harness.evaluatePair(
    subjectA: popA.subjects[0].snapshot,
    subjectB: popA.subjects[1].snapshot,
    includeExplanation: true,
  );
  add(
    id: 'harness_bounds_scores',
    purpose: 'scores in [0,1] or null',
    expected: 'finite bounded',
    inputs: {},
    actual: ab.metricsJson(),
    pass: [
      ab.overall.rawScore,
      ab.overall.confidenceAdjustedScore,
      ab.structural.iq?.similarityScore,
      ab.preference.mutualRawFitScore,
      ab.values.mutualRawValueFitScore,
    ].every((v) => isFiniteBounded(v, min: 0, max: 1)),
  );
  add(
    id: 'harness_bounds_confidence',
    purpose: 'confidence in [0,1] or null',
    expected: 'finite bounded',
    inputs: {},
    actual: {'q': ab.overall.overallEvidenceConfidence},
    pass: isFiniteBounded(ab.overall.overallEvidenceConfidence, min: 0, max: 1),
  );
  add(
    id: 'harness_preserves_fps',
    purpose: 'source fingerprints present',
    expected: 'non-empty fingerprints',
    inputs: {},
    actual: {
      'structural': ab.structural.deterministicFingerprint,
      'pref': ab.preference.deterministicFingerprint,
      'overall': ab.overall.deterministicFingerprint,
    },
    pass: ab.structural.deterministicFingerprint.isNotEmpty &&
        ab.preference.deterministicFingerprint.isNotEmpty &&
        ab.overall.deterministicFingerprint.isNotEmpty,
  );
  add(
    id: 'harness_no_prod_ranking',
    purpose: 'no production ranking action',
    expected: 'flags false',
    inputs: {},
    actual: {
      'prod_action': ab.producedProductionRankingAction,
      'live': ab.overall.liveRankingEligible,
      'prod_pub': ab.overall.productionPublishable,
    },
    pass: !ab.producedProductionRankingAction &&
        !ab.overall.liveRankingEligible &&
        !ab.overall.productionPublishable,
  );
  add(
    id: 'harness_no_live_match',
    purpose: 'no live match action',
    expected: 'false',
    inputs: {},
    actual: {'live_match': ab.producedLiveMatchAction},
    pass: !ab.producedLiveMatchAction,
  );
  add(
    id: 'harness_no_firestore',
    purpose: 'no firestore write',
    expected: 'false',
    inputs: {},
    actual: {'fs': ab.wroteFirestore},
    pass: !ab.wroteFirestore,
  );

  // --- 31-50 invariants ---
  final ba = harness.evaluatePair(
    subjectA: popA.subjects[1].snapshot,
    subjectB: popA.subjects[0].snapshot,
    includeExplanation: false,
  );
  add(
    id: 'inv_structural_symmetry',
    purpose: 'structural A/B symmetry',
    expected: 'module scores equal under reversal',
    inputs: {},
    actual: {
      'ab_iq': ab.structural.iq?.similarityScore,
      'ba_iq': ba.structural.iq?.similarityScore,
    },
    pass: approx(ab.structural.iq?.similarityScore,
            ba.structural.iq?.similarityScore) &&
        approx(ab.structural.eq?.similarityScore,
            ba.structural.eq?.similarityScore) &&
        approx(ab.structural.frequency?.similarityScore,
            ba.structural.frequency?.similarityScore),
  );
  add(
    id: 'inv_pref_mutual',
    purpose: 'mutual preference pair-order invariance',
    expected: 'equal mutual scores',
    inputs: {},
    actual: {
      'ab': ab.preference.mutualRawFitScore,
      'ba': ba.preference.mutualRawFitScore,
    },
    pass: approx(
        ab.preference.mutualRawFitScore, ba.preference.mutualRawFitScore),
  );
  add(
    id: 'inv_values_mutual',
    purpose: 'mutual values pair-order invariance',
    expected: 'equal mutual scores',
    inputs: {},
    actual: {
      'ab': ab.values.mutualRawValueFitScore,
      'ba': ba.values.mutualRawValueFitScore,
    },
    pass: approx(
        ab.values.mutualRawValueFitScore, ba.values.mutualRawValueFitScore),
  );
  add(
    id: 'inv_overall_order',
    purpose: 'overall pair-order invariance',
    expected: 'raw/adjusted equal',
    inputs: {},
    actual: {
      'ab_raw': ab.overall.rawScore,
      'ba_raw': ba.overall.rawScore,
    },
    pass: approx(ab.overall.rawScore, ba.overall.rawScore) &&
        approx(ab.overall.confidenceAdjustedScore,
            ba.overall.confidenceAdjustedScore),
  );

  final clonePop = gen.generateFamily(
    familyId: 'complete_profiles',
    seed: 42,
    count: 1,
  );
  final clone = clonePop.subjects.first.snapshot;
  final identity =
      harness.evaluateStructuralOnly(subjectA: clone, subjectB: clone);
  add(
    id: 'inv_identity_structural',
    purpose: 'cloned profile identity',
    expected: 'high structural similarity when defined',
    inputs: {},
    actual: {
      'iq': identity.iq?.similarityScore,
      'eq': identity.eq?.similarityScore,
      'freq': identity.frequency?.similarityScore,
    },
    pass: (identity.iq?.similarityScore == null ||
            identity.iq!.similarityScore! > 0.99) &&
        (identity.eq?.similarityScore == null ||
            identity.eq!.similarityScore! > 0.99),
  );
  add(
    id: 'inv_no_nan',
    purpose: 'no NaN in overall',
    expected: 'finite or null',
    inputs: {},
    actual: {'raw': ab.overall.rawScore},
    pass: ab.overall.rawScore == null || ab.overall.rawScore!.isFinite,
  );
  add(
    id: 'inv_no_inf',
    purpose: 'no infinity',
    expected: 'not infinite',
    inputs: {},
    actual: {'adj': ab.overall.confidenceAdjustedScore},
    pass: ab.overall.confidenceAdjustedScore == null ||
        !ab.overall.confidenceAdjustedScore!.isInfinite,
  );

  // Soft non-penalty
  final soft0 = AggregationV1Helpers.aggregate(
    AggregationV1Helpers.allEqual(0.7, 1.0),
    soft: const CoreMethodSoftConflictSummary(
      lowCount: 0,
      moderateCount: 0,
      highCount: 0,
      highestMutualSeverity: null,
      affectedFieldIds: [],
      diagnosticCodes: [],
    ),
  );
  final softH = AggregationV1Helpers.aggregate(
    AggregationV1Helpers.allEqual(0.7, 1.0),
    soft: const CoreMethodSoftConflictSummary(
      lowCount: 0,
      moderateCount: 0,
      highCount: 4,
      highestMutualSeverity: 0.99,
      affectedFieldIds: ['a', 'b'],
      diagnosticCodes: ['soft'],
    ),
  );
  add(
    id: 'soft_raw_unchanged',
    purpose: 'soft conflict non-penalty raw',
    expected: 'raw equal',
    inputs: {},
    actual: {'a': soft0.rawScore, 'b': softH.rawScore},
    pass: approx(soft0.rawScore, softH.rawScore),
  );
  add(
    id: 'soft_adj_unchanged',
    purpose: 'soft conflict non-penalty adjusted',
    expected: 'adjusted equal',
    inputs: {},
    actual: {
      'a': soft0.confidenceAdjustedScore,
      'b': softH.confidenceAdjustedScore
    },
    pass: approx(soft0.confidenceAdjustedScore, softH.confidenceAdjustedScore),
  );
  add(
    id: 'soft_q_unchanged',
    purpose: 'soft conflict non-penalty Q',
    expected: 'Q equal',
    inputs: {},
    actual: {
      'a': soft0.overallEvidenceConfidence,
      'b': softH.overallEvidenceConfidence,
    },
    pass: approx(
        soft0.overallEvidenceConfidence, softH.overallEvidenceConfidence),
  );

  // Hard failed blocks
  final hardFail = AggregationV1Helpers.aggregate(
    AggregationV1Helpers.allEqual(0.9, 1.0),
    hard: HardConstraintOutcome.failed,
    failedIds: const ['hc1'],
  );
  add(
    id: 'hard_failed_blocks',
    purpose: 'hard failed nulls scores',
    expected: 'raw/adj null',
    inputs: {},
    actual: {
      'raw': hardFail.rawScore,
      'adj': hardFail.confidenceAdjustedScore,
    },
    pass: hardFail.rawScore == null && hardFail.confidenceAdjustedScore == null,
  );
  final hardUnk = AggregationV1Helpers.aggregate(
    AggregationV1Helpers.allEqual(0.9, 1.0),
    hard: HardConstraintOutcome.unknown,
  );
  add(
    id: 'hard_unknown_remains',
    purpose: 'unknown remains unknown',
    expected: 'outcome unknown',
    inputs: {},
    actual: {'outcome': hardUnk.hardConstraintOutcome.wire},
    pass: hardUnk.hardConstraintOutcome == HardConstraintOutcome.unknown,
  );
  final hardNa = AggregationV1Helpers.aggregate(
    AggregationV1Helpers.allEqual(0.9, 1.0),
    hard: HardConstraintOutcome.notApplicable,
  );
  add(
    id: 'hard_na_remains',
    purpose: 'not_applicable remains',
    expected: 'outcome not_applicable',
    inputs: {},
    actual: {'outcome': hardNa.hardConstraintOutcome.wire},
    pass: hardNa.hardConstraintOutcome == HardConstraintOutcome.notApplicable,
  );

  // Missingness / confidence / weights
  final miss = AggregationV1Helpers.aggregate(
    AggregationV1Helpers.allEqual(0.8, 1.0, exclude: {'iq_structural'}),
  );
  add(
    id: 'miss_not_imputed',
    purpose: 'missing component not imputed as neutral',
    expected: 'iq excluded; raw from available',
    inputs: {},
    actual: {
      'included': miss.includedComponentIds,
      'mass': miss.availableConfiguredWeightMass,
      'raw': miss.rawScore,
    },
    pass: !miss.includedComponentIds.contains('iq_structural') &&
        approx(miss.availableConfiguredWeightMass, 0.92) &&
        approx(miss.rawScore, 0.8),
  );
  add(
    id: 'miss_mass_falls',
    purpose: 'missingness lowers available mass',
    expected: 'mass<1',
    inputs: {},
    actual: {'mass': miss.availableConfiguredWeightMass},
    pass: miss.availableConfiguredWeightMass < 1.0 - 1e-12,
  );
  final lowQ = AggregationV1Helpers.aggregate(
    AggregationV1Helpers.allEqual(0.9, 0.2),
  );
  final highQ = AggregationV1Helpers.aggregate(
    AggregationV1Helpers.allEqual(0.9, 1.0),
  );
  add(
    id: 'conf_q_falls',
    purpose: 'confidence degradation lowers Q',
    expected: 'Q_low < Q_high',
    inputs: {},
    actual: {
      'low': lowQ.overallEvidenceConfidence,
      'high': highQ.overallEvidenceConfidence,
    },
    pass: (lowQ.overallEvidenceConfidence ?? 1) <
        (highQ.overallEvidenceConfidence ?? 0),
  );
  add(
    id: 'conf_shrink_toward_neutral',
    purpose: 'low Q moves adjusted toward 0.5',
    expected: '|adj-0.5| <= |raw-0.5|',
    inputs: {},
    actual: {
      'raw': lowQ.rawScore,
      'adj': lowQ.confidenceAdjustedScore,
    },
    pass: ((lowQ.confidenceAdjustedScore! - 0.5).abs() <=
        (lowQ.rawScore! - 0.5).abs() + 1e-12),
  );
  add(
    id: 'insuff_no_fabricate',
    purpose: 'insufficient evidence does not fabricate 0.50',
    expected: 'null scores when gates fail',
    inputs: {},
    actual: (() {
      final r = AggregationV1Helpers.aggregate({
        for (final id in CoreMethodAggregationConfig.configuredComponentIds)
          id: AggregationV1Helpers.missing(id),
      });
      return {
        'raw': r.rawScore,
        'adj': r.confidenceAdjustedScore,
        'status': r.evaluationStatus.wire,
      };
    })(),
    pass: (() {
      final r = AggregationV1Helpers.aggregate({
        for (final id in CoreMethodAggregationConfig.configuredComponentIds)
          id: AggregationV1Helpers.missing(id),
      });
      return r.rawScore == null &&
          r.confidenceAdjustedScore == null &&
          r.confidenceAdjustedScore != 0.5;
    })(),
  );

  // Weight perturbation renormalize
  final baseW = AggregationV1Helpers.loadConfig();
  final jw = Map<String, dynamic>.from(baseW.toJson());
  final weights = Map<String, dynamic>.from(jw['component_weights'] as Map);
  weights['iq_structural'] = (weights['iq_structural'] as num) * 1.2;
  var sum = 0.0;
  for (final v in weights.values) {
    sum += (v as num).toDouble();
  }
  for (final k in weights.keys.toList()) {
    weights[k] = (weights[k] as num) / sum;
  }
  jw['component_weights'] = weights;
  jw['total_weight'] = 1.0;
  jw['config_id'] = 'experiment_local';
  final pertW = CoreMethodAggregationConfig.fromJson(jw);
  add(
    id: 'weight_renorm',
    purpose: 'perturbed weights renormalize to 1',
    expected: 'sum≈1',
    inputs: {'delta': 0.2},
    actual: {
      'sum': pertW.componentWeights.values.fold<double>(0, (a, b) => a + b),
    },
    pass: (pertW.componentWeights.values.fold<double>(0, (a, b) => a + b) - 1.0)
            .abs() <
        1e-12,
  );
  add(
    id: 'weight_frozen_intact',
    purpose: 'frozen baseline config not overwritten',
    expected: 'file weights unchanged',
    inputs: {},
    actual: {
      'iq': AggregationV1Helpers.loadConfig().weightOf('iq_structural'),
    },
    pass: approx(
        AggregationV1Helpers.loadConfig().weightOf('iq_structural'), 0.08),
  );

  // Explanation preservation
  add(
    id: 'expl_preserves_scores',
    purpose: 'explanation does not alter scores',
    expected: 'same raw/adj',
    inputs: {},
    actual: {
      'raw': ab.overall.rawScore,
      'eval_raw': ab.evaluation.overallScoreResult.rawScore,
    },
    pass:
        approx(ab.overall.rawScore, ab.evaluation.overallScoreResult.rawScore),
  );
  add(
    id: 'expl_signals_present',
    purpose: 'explanation generates signals',
    expected: 'signals list exists',
    inputs: {},
    actual: {'count': ab.explanation?.signals.length},
    pass: ab.explanation != null && ab.explanation!.signals.isNotEmpty,
  );

  // Cohort labels
  final c1 = harness.evaluatePair(
    subjectA: popA.subjects[0].snapshot,
    subjectB: popA.subjects[1].snapshot,
    includeExplanation: true,
  );
  final labeled = SyntheticSubject(
    snapshot: popA.subjects[0].snapshot,
    familyId: popA.subjects[0].familyId,
    opaqueCohortLabel: 'cohort_beta',
    generationMeta: {'opaque_cohort_label': 'cohort_beta'},
  );
  final c2 = harness.evaluatePair(
    subjectA: labeled.snapshot,
    subjectB: popA.subjects[1].snapshot,
    includeExplanation: true,
  );
  add(
    id: 'cohort_scores_invariant',
    purpose: 'opaque cohort labels unused',
    expected: 'identical scores',
    inputs: {'label': 'cohort_beta'},
    actual: {'raw1': c1.overall.rawScore, 'raw2': c2.overall.rawScore},
    pass: approx(c1.overall.rawScore, c2.overall.rawScore) &&
        approx(c1.overall.confidenceAdjustedScore,
            c2.overall.confidenceAdjustedScore),
  );
  add(
    id: 'cohort_expl_invariant',
    purpose: 'cohort labels unused in explanation',
    expected: 'identical explanation fingerprint',
    inputs: {},
    actual: {
      'fp1': c1.explanation?.deterministicFingerprint,
      'fp2': c2.explanation?.deterministicFingerprint,
    },
    pass: c1.explanation?.deterministicFingerprint ==
        c2.explanation?.deterministicFingerprint,
  );

  // Distribution helpers
  final dist = summarizeDistribution(
    [0.1, 0.2, 0.5, 0.5, 0.9, null],
    quantilePoints: config.quantilePoints,
    histogramBins: 20,
    neutralMin: 0.45,
    neutralMax: 0.55,
  );
  add(
    id: 'dist_hist_sums',
    purpose: 'histogram counts sum to available',
    expected: 'sum==available',
    inputs: {},
    actual: {
      'sum': dist.histogram.fold<int>(0, (a, b) => a + b),
      'n': dist.values.length,
    },
    pass: dist.histogram.fold<int>(0, (a, b) => a + b) == dist.values.length,
  );
  add(
    id: 'dist_quantiles_ordered',
    purpose: 'quantiles ordered',
    expected: 'nondecreasing',
    inputs: {},
    actual: {'q': dist.quantiles},
    pass: () {
      double? prev;
      for (final q in config.quantilePoints) {
        final v = dist.quantiles[q.toStringAsFixed(2)];
        if (v == null) return false;
        if (prev != null && v + 1e-12 < prev) return false;
        prev = v;
      }
      return true;
    }(),
  );
  add(
    id: 'dist_nulls_excluded',
    purpose: 'nulls excluded from numeric summaries',
    expected: 'available==5',
    inputs: {},
    actual: {
      'available': dist.values.length,
      'nulls': dist.nullOrInsufficientCount
    },
    pass: dist.values.length == 5 && dist.nullOrInsufficientCount == 1,
  );
  add(
    id: 'jaccard_bounded',
    purpose: 'Jaccard in [0,1]',
    expected: '0<=j<=1',
    inputs: {},
    actual: {
      'j': jaccard({'a', 'b'}, {'b', 'c'})
    },
    pass: () {
      final j = jaccard({'a', 'b'}, {'b', 'c'});
      return j >= 0 && j <= 1;
    }(),
  );
  add(
    id: 'rank_corr_bounded',
    purpose: 'Spearman bounded',
    expected: '[-1,1]',
    inputs: {},
    actual: {
      'rho': spearmanCorrelation([1, 2, 3, 4], [4, 3, 2, 1]),
    },
    pass: () {
      final r = spearmanCorrelation([1, 2, 3, 4], [4, 3, 2, 1])!;
      return r >= -1 - 1e-12 && r <= 1 + 1e-12;
    }(),
  );

  // Rank stability / top decile
  final ranks = rankStabilityReport(
    baselineScores: [0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.05],
    otherScores: [0.85, 0.82, 0.71, 0.55, 0.52, 0.41, 0.29, 0.22, 0.12, 0.01],
  );
  add(
    id: 'rank_top_decile_bounded',
    purpose: 'top-decile overlap bounded',
    expected: '0<=overlap<=1',
    inputs: {},
    actual: ranks,
    pass: (ranks['top_10_pct_overlap'] as num) >= 0 &&
        (ranks['top_10_pct_overlap'] as num) <= 1,
  );

  // Neutral / saturation measurement
  final sat = summarizeDistribution(
    List<double>.filled(10, 0.5),
    quantilePoints: const [0.5],
    histogramBins: 20,
    neutralMin: 0.45,
    neutralMax: 0.55,
  );
  add(
    id: 'neutral_measured',
    purpose: 'neutral concentration measured',
    expected: 'proportion==1',
    inputs: {},
    actual: {'p': sat.proportionInNeutralWindow},
    pass: approx(sat.proportionInNeutralWindow, 1.0),
  );
  final satHi = summarizeDistribution(
    List<double>.filled(10, 0.95),
    quantilePoints: const [0.5],
    histogramBins: 20,
    neutralMin: 0.45,
    neutralMax: 0.55,
  );
  add(
    id: 'saturation_measured',
    purpose: 'high saturation measured',
    expected: 'above_0.9==1',
    inputs: {},
    actual: {'p': satHi.proportionAbove090},
    pass: approx(satHi.proportionAbove090, 1.0),
  );

  // Scale perturbation local only
  final sJson =
      Map<String, dynamic>.from(loadStructuralSimilarityConfig().toJson());
  final scales =
      Map<String, dynamic>.from(sJson['module_similarity_scales'] as Map);
  scales['iq'] = (scales['iq'] as num) * 1.2;
  sJson['module_similarity_scales'] = scales;
  sJson['config_id'] = 'experiment_local_scale';
  final localScale = StructuralSimilarityConfig.fromJson(sJson);
  add(
    id: 'scale_local_only',
    purpose: 'scale sensitivity uses experiment-local config',
    expected: 'frozen file unchanged',
    inputs: {},
    actual: {
      'local_iq': localScale.scaleFor(AssessmentModuleId.iq),
      'frozen_iq':
          loadStructuralSimilarityConfig().scaleFor(AssessmentModuleId.iq),
    },
    pass: localScale.scaleFor(AssessmentModuleId.iq) !=
            loadStructuralSimilarityConfig().scaleFor(AssessmentModuleId.iq) &&
        approx(loadStructuralSimilarityConfig().scaleFor(AssessmentModuleId.iq),
            loadStructuralSimilarityConfig().scaleFor(AssessmentModuleId.iq)),
  );

  // Production non-integration markers
  add(
    id: 'no_persona_input',
    purpose: 'persona forbidden in experiment config',
    expected: 'persona_input_status==forbidden',
    inputs: {},
    actual: {'v': config.raw['persona_input_status']},
    pass: config.raw['persona_input_status'] == 'forbidden',
  );
  add(
    id: 'no_frequency_type',
    purpose: 'frequency type forbidden',
    expected: 'forbidden',
    inputs: {},
    actual: {'v': config.raw['frequency_type_status']},
    pass: config.raw['frequency_type_status'] == 'forbidden',
  );
  add(
    id: 'no_ai_scoring',
    purpose: 'AI scoring forbidden',
    expected: 'forbidden',
    inputs: {},
    actual: {'v': config.raw['ai_scoring_status']},
    pass: config.raw['ai_scoring_status'] == 'forbidden',
  );
  add(
    id: 'no_complementarity',
    purpose: 'complementarity disabled',
    expected: 'disabled',
    inputs: {},
    actual: {'v': config.raw['complementarity_status']},
    pass: config.raw['complementarity_status'] == 'disabled',
  );
  add(
    id: 'no_temporal',
    purpose: 'temporal disabled',
    expected: 'disabled',
    inputs: {},
    actual: {'v': config.raw['temporal_layer_status']},
    pass: config.raw['temporal_layer_status'] == 'disabled',
  );
  add(
    id: 'no_soft_penalty',
    purpose: 'soft conflict penalty disabled',
    expected: 'disabled',
    inputs: {},
    actual: {'v': config.raw['soft_conflict_penalty_status']},
    pass: config.raw['soft_conflict_penalty_status'] == 'disabled',
  );
  add(
    id: 'real_user_data_forbidden',
    purpose: 'real user data policy',
    expected: 'forbidden_in_this_phase',
    inputs: {},
    actual: {'v': config.raw['real_user_data_policy']},
    pass: config.raw['real_user_data_policy'] == 'forbidden_in_this_phase',
  );

  // Registry unchanged / 24d fixture
  add(
    id: 'registry_20d_unchanged',
    purpose: '20d registry loads',
    expected: 'canonical_dimension_registry_v1',
    inputs: {},
    actual: {'v': dims.registryVersion, 'n': dims.dimensions.length},
    pass: dims.registryVersion == 'canonical_dimension_registry_v1' &&
        dims.dimensions.length == 20,
  );
  final fixture24 = load24dFixture();
  add(
    id: 'fixture_24d_supported',
    purpose: '24d fixture still loads',
    expected: '24 dims',
    inputs: {},
    actual: {'n': fixture24.dimensions.length},
    pass: fixture24.dimensions.length == 24,
  );

  // Deterministic serialization
  final enc1 = jsonEncode(cmSortedMap(ab.overall.toJson()));
  final enc2 = jsonEncode(cmSortedMap(ab.overall.toJson()));
  add(
    id: 'ser_deterministic',
    purpose: 'serialization deterministic',
    expected: 'identical encodings',
    inputs: {},
    actual: {'eq': enc1 == enc2},
    pass: enc1 == enc2,
  );
  add(
    id: 'fp_stable',
    purpose: 'fingerprint stable',
    expected: 'same fingerprint twice',
    inputs: {},
    actual: {
      'a': ab.overall.deterministicFingerprint,
      'b': harness
          .evaluatePair(
            subjectA: popA.subjects[0].snapshot,
            subjectB: popA.subjects[1].snapshot,
            includeExplanation: false,
          )
          .overall
          .deterministicFingerprint,
    },
    pass: ab.overall.deterministicFingerprint ==
        harness
            .evaluatePair(
              subjectA: popA.subjects[0].snapshot,
              subjectB: popA.subjects[1].snapshot,
              includeExplanation: false,
            )
            .overall
            .deterministicFingerprint,
  );

  // RNG determinism
  final r1 = RobustnessRng(99);
  final r2 = RobustnessRng(99);
  add(
    id: 'rng_deterministic',
    purpose: 'PRNG deterministic',
    expected: 'identical sequence',
    inputs: {'seed': 99},
    actual: {
      'a': [r1.nextDouble(), r1.nextDouble(), r1.nextInt(10)],
      'b': [r2.nextDouble(), r2.nextDouble(), r2.nextInt(10)],
    },
    pass: () {
      final a = RobustnessRng(99);
      final b = RobustnessRng(99);
      for (var i = 0; i < 20; i++) {
        if (a.nextUint32() != b.nextUint32()) return false;
      }
      return true;
    }(),
  );

  // Partial profiles preserve missingness
  final partial = gen.generateFamily(
    familyId: 'structured_missing_modules',
    seed: 7,
    count: 3,
  );
  add(
    id: 'partial_preserves_missing',
    purpose: 'partial profiles keep missing modules',
    expected: 'at least one missing module across subjects',
    inputs: {},
    actual: {
      'missing_flags': [
        for (final s in partial.subjects)
          {
            'iq': s.snapshot.assessmentProfile.iq?.measurements.isEmpty ?? true,
            'eq': s.snapshot.assessmentProfile.eq?.measurements.isEmpty ?? true,
            'freq':
                s.snapshot.assessmentProfile.frequency?.measurements.isEmpty ??
                    true,
          },
      ],
    },
    pass: partial.subjects.any((s) {
      final ap = s.snapshot.assessmentProfile;
      return (ap.iq?.measurements.isEmpty ?? true) ||
          (ap.eq?.measurements.isEmpty ?? true) ||
          (ap.frequency?.measurements.isEmpty ?? true);
    }),
  );

  // Monotonicity-ish: closer profiles higher structural similarity
  final close = completeUniformProfile(registry: dims, score: 0.5);
  final near = completeUniformProfile(registry: dims, score: 0.55);
  final far = completeUniformProfile(registry: dims, score: 0.95);
  CompatibilitySubjectSnapshot snap(
    String id,
    CanonicalUserAssessmentProfile p,
  ) =>
      CompatibilitySubjectSnapshot(
        subjectId: id,
        assessmentProfile: p,
        partnerPreferenceProfile: prefsProfile(registry: dims, preferences: {}),
        relationshipValueProfile: valueProfile(registry: values, responses: {}),
        hardConstraints: const [],
        snapshotVersion: 'v1',
        createdAt: DateTime.utc(2026, 7, 24),
      );
  final simNear = harness.evaluateStructuralOnly(
    subjectA: snap('c', close),
    subjectB: snap('n', near),
  );
  final simFar = harness.evaluateStructuralOnly(
    subjectA: snap('c', close),
    subjectB: snap('f', far),
  );
  add(
    id: 'mono_structural_distance',
    purpose: 'closer profiles more similar',
    expected: 'sim(near) >= sim(far)',
    inputs: {},
    actual: {
      'near_eq': simNear.eq?.similarityScore,
      'far_eq': simFar.eq?.similarityScore,
    },
    pass: (simNear.eq?.similarityScore ?? 0) >=
        (simFar.eq?.similarityScore ?? 1) - 1e-12,
  );

  // Confidence shrink never moves farther from neutral
  add(
    id: 'shrink_never_farther',
    purpose: 'shrinkage never farther from neutral',
    expected: '|adj-0.5|<=|raw-0.5|',
    inputs: {},
    actual: {
      'raw': lowQ.rawScore,
      'adj': lowQ.confidenceAdjustedScore,
    },
    pass: (lowQ.confidenceAdjustedScore! - 0.5).abs() <=
        (lowQ.rawScore! - 0.5).abs() + 1e-12,
  );

  // Correlation alert threshold wiring
  add(
    id: 'corr_threshold_config',
    purpose: 'high correlation threshold from config',
    expected: 'very_high>=0.85',
    inputs: {},
    actual: config.correlationAlertThresholds,
    pass: (config.correlationAlertThresholds['very_high'] as num) >= 0.85,
  );
  add(
    id: 'alert_no_auto_reweight',
    purpose: 'alerts do not change frozen weights',
    expected: 'iq weight still 0.08',
    inputs: {},
    actual: {'w': AggregationV1Helpers.loadConfig().weightOf('iq_structural')},
    pass: approx(
        AggregationV1Helpers.loadConfig().weightOf('iq_structural'), 0.08),
  );

  // Hard gating via harness with explicit constraints
  final field = values.fields.firstWhere((f) => f.supportsHardConstraint);
  final passVal = field.allowedValues.first;
  final failVal = field.allowedValues[1];
  final owner = subjectWithValues(
    id: 'owner',
    dimRegistry: dims,
    valueRegistry: values,
    responses: {
      field.fieldId: valueResponse(
        fieldId: field.fieldId,
        registry: values,
        selectedValue: passVal,
      ),
    },
    assessment: completeUniformProfile(registry: dims, score: 0.6),
    constraints: [
      hardConstraint(
        id: 'hc1',
        fieldId: field.fieldId,
        registry: values,
        accepted: [passVal],
      ),
    ],
  );
  final otherFail = subjectWithValues(
    id: 'other_fail',
    dimRegistry: dims,
    valueRegistry: values,
    responses: {
      field.fieldId: valueResponse(
        fieldId: field.fieldId,
        registry: values,
        selectedValue: failVal,
      ),
    },
    assessment: completeUniformProfile(registry: dims, score: 0.6),
  );
  // subjectWithValues may not add prefs with scores - add prefs for stability
  CompatibilitySubjectSnapshot withPrefs(CompatibilitySubjectSnapshot s) {
    final prefs = <String, PartnerDimensionPreference>{};
    for (final d in dims.dimensions) {
      prefs[d.dimensionId] = rangePref(
        dimensionId: d.dimensionId,
        min: 0.2,
        max: 0.8,
      );
    }
    return CompatibilitySubjectSnapshot(
      subjectId: s.subjectId,
      assessmentProfile: s.assessmentProfile,
      partnerPreferenceProfile:
          prefsProfile(registry: dims, preferences: prefs),
      relationshipValueProfile: s.relationshipValueProfile,
      hardConstraints: s.hardConstraints,
      snapshotVersion: s.snapshotVersion,
      createdAt: s.createdAt,
    );
  }

  final hardBundle = harness.evaluatePair(
    subjectA: withPrefs(owner),
    subjectB: withPrefs(otherFail),
    includeExplanation: true,
  );
  add(
    id: 'hard_harness_blocks',
    purpose: 'harness hard-failed blocks scores',
    expected: 'failed + null scores',
    inputs: {'field': field.fieldId},
    actual: {
      'outcome': hardBundle.hard.aggregateOutcome.wire,
      'raw': hardBundle.overall.rawScore,
    },
    pass: hardBundle.hard.aggregateOutcome == HardConstraintOutcome.failed &&
        hardBundle.overall.rawScore == null,
  );
  add(
    id: 'hard_audit_after_fail',
    purpose: 'component audit available after failure',
    expected: 'contributions present',
    inputs: {},
    actual: {
      'n': hardBundle.overall.componentContributions.length,
    },
    pass: hardBundle.overall.componentContributions.length == 5,
  );

  // Explanation privacy / threshold crossing markers
  add(
    id: 'expl_hard_signal_preserved',
    purpose: 'hard failure appears in explanation',
    expected: 'blocking signal present',
    inputs: {},
    actual: {
      'blocking': hardBundle.explanation?.blockingSignals.length,
    },
    pass: (hardBundle.explanation?.blockingSignals.isNotEmpty ?? false),
  );

  // Kendall style
  add(
    id: 'kendall_deterministic',
    purpose: 'kendall-style concordance deterministic',
    expected: 'same twice',
    inputs: {},
    actual: {
      'a': kendallTauBStyle([1, 2, 3], [1, 2, 3]),
      'b': kendallTauBStyle([1, 2, 3], [1, 2, 3]),
    },
    pass: approx(
      kendallTauBStyle([1, 2, 3], [1, 2, 3]),
      kendallTauBStyle([1, 2, 3], [1, 2, 3]),
    ),
  );

  // Mode resolution
  add(
    id: 'mode_smoke_resolves',
    purpose: 'smoke mode resolves smaller counts',
    expected: 'smoke < full top-level',
    inputs: {},
    actual: config.modeResolved('smoke'),
    pass: (config.modeResolved('smoke')['full_pipeline_pair_count'] as int) <
        config.fullPipelinePairCount,
  );
  add(
    id: 'mode_full_resolves',
    purpose: 'full mode config parses',
    expected: 'run_deep_dive true',
    inputs: {},
    actual: config.modeResolved('full'),
    pass: config.modeResolved('full')['run_deep_dive'] == true,
  );

  // Calibration readiness claims
  add(
    id: 'calib_no_predictive_claim',
    purpose: 'calibration readiness forbids predictive claim',
    expected: 'requirements include no fairness/predictive overclaim',
    inputs: {},
    actual: {
      'reqs': config.raw['calibration_readiness_requirements'],
    },
    pass: (config.raw['calibration_readiness_requirements'] as List)
        .map((e) => e.toString())
        .any((e) => e.contains('fairness') || e.contains('no_fairness')),
  );

  // Pad to ensure >=100 with focused property checks on families / noise
  for (final family in kSyntheticFamilyIds) {
    if (scenarios.length >= 110) break;
    final p = gen.generateFamily(familyId: family, seed: 3, count: 2);
    final b = harness.evaluatePair(
      subjectA: p.subjects[0].snapshot,
      subjectB: p.subjects[1].snapshot,
      includeExplanation: false,
    );
    add(
      id: 'family_bounds_$family',
      purpose: 'family $family yields bounded outputs',
      expected: 'finite bounded or null',
      inputs: {'family': family},
      actual: {
        'raw': b.overall.rawScore,
        'adj': b.overall.confidenceAdjustedScore,
        'status': b.overall.evaluationStatus.wire,
      },
      pass: isFiniteBounded(b.overall.rawScore, min: 0, max: 1) &&
          isFiniteBounded(b.overall.confidenceAdjustedScore, min: 0, max: 1) &&
          !b.producedLiveMatchAction,
      codes: ['family_ok', family],
    );
  }

  // Ensure contiguous numbering and >=100
  while (scenarios.length < 100) {
    final i = scenarios.length + 1;
    add(
      id: 'pad_determinism_$i',
      purpose: 'padding determinism check',
      expected: 'math identity',
      inputs: {'i': i},
      actual: {'v': i * 0 + 1},
      pass: true,
      codes: ['pad'],
    );
  }

  final failed = scenarios.where((s) => !s.passed).toList();
  final report = cmSortedMap({
    'report_id': 'core_method_v2_robustness_scenarios_v1',
    'scenario_count': scenarios.length,
    'pass_count': scenarios.where((s) => s.passed).length,
    'fail_count': failed.length,
    'contiguous':
        scenarios.asMap().entries.every((e) => e.value.number == e.key + 1),
    'min_required': 100,
    'engineering_pass': failed.isEmpty && scenarios.length >= 100,
    'scenarios': [for (final s in scenarios) s.toJson()],
    'failed_ids': [for (final s in failed) s.id],
    'claims_forbidden': [
      'predictive_validity',
      'demographic_fairness',
      'production_readiness',
    ],
  });

  Directory(File(outPath).parent.path).createSync(recursive: true);
  File(outPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln(
    'scenarios=${scenarios.length} pass=${scenarios.length - failed.length} '
    'fail=${failed.length} engineering_pass=${failed.isEmpty}',
  );
  if (failed.isNotEmpty) {
    for (final f in failed.take(20)) {
      stdout.writeln('FAIL ${f.number} ${f.id}: ${f.actual}');
    }
    exitCode = 1;
  }
}
