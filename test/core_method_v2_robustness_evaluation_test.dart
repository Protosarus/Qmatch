import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import '../tool/support/core_method_v2_offline_evaluation_harness.dart';
import '../tool/support/core_method_v2_synthetic/robustness_experiment_config.dart';
import '../tool/support/core_method_v2_synthetic/robustness_rng.dart';
import '../tool/support/core_method_v2_synthetic/robustness_stats.dart';
import '../tool/support/core_method_v2_synthetic/synthetic_profile_generator.dart';
import 'support/aggregation_v1_helpers.dart';
import 'support/core_method_v2_helpers.dart';
import 'support/directional_preference_fit_helpers.dart';
import 'support/explanation_v1_helpers.dart';
import 'support/relationship_value_layer_helpers.dart';
import 'support/structural_similarity_helpers.dart';

void main() {
  final config = RobustnessExperimentConfig.loadFile();
  final dims = loadCanonicalDimensionRegistry();
  final values = loadValueRegistry();
  final gen = CoreMethodV2SyntheticGenerator(
    dimRegistry: dims,
    valueRegistry: values,
  );
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

  group('P2B-6 robustness experiment config', () {
    test('1-2. config parses and schema keys present', () {
      expect(config.configVersion, isNotEmpty);
      final schema = jsonDecode(
        File(RobustnessExperimentConfig.schemaPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final k in schema['required'] as List) {
        expect(config.raw.containsKey(k.toString()), isTrue, reason: '$k');
      }
      expect(config.raw['status'], 'provisional');
      expect(config.raw['runtime_status'], 'offline_only');
    });

    test('72-73. smoke and full modes resolve; smoke does not replace full',
        () {
      final smoke = config.modeResolved('smoke');
      final full = config.modeResolved('full');
      expect(config.syntheticPopulationSize, 2000);
      expect(smoke['synthetic_population_size'], lessThan(2000));
      expect(full['run_deep_dive'], isTrue);
      expect(smoke['run_deep_dive'], isFalse);
    });
  });

  group('P2B-6 synthetic generation', () {
    test('3-5. deterministic same seed; different seeds differ', () {
      final a = gen.generateFamily(
        familyId: 'independent_uniform',
        seed: config.baselineSeed,
        count: 6,
      );
      final b = gen.generateFamily(
        familyId: 'independent_uniform',
        seed: config.baselineSeed,
        count: 6,
      );
      final c = gen.generateFamily(
        familyId: 'independent_uniform',
        seed: config.secondarySeeds.first,
        count: 6,
      );
      expect(
        a.subjects.map((s) => s.subjectId).toList(),
        b.subjects.map((s) => s.subjectId).toList(),
      );
      expect(a.subjects.first.subjectId, isNot(c.subjects.first.subjectId));
    });

    test('6-7,10. artificial ids; all families; partial missingness', () {
      expect(config.syntheticFamilyIds, hasLength(26));
      for (final f in kSyntheticFamilyIds) {
        final p = gen.generateFamily(familyId: f, seed: 11, count: 2);
        expect(p.size, 2);
        expect(p.subjects.every((s) => s.subjectId.startsWith('syn_')), isTrue);
        expect(p.subjects.every((s) => !s.subjectId.contains('@')), isTrue);
      }
      final partial = gen.generateFamily(
        familyId: 'structured_missing_modules',
        seed: 2,
        count: 3,
      );
      expect(
        partial.subjects.any((s) {
          final ap = s.snapshot.assessmentProfile;
          return (ap.iq?.measurements.isEmpty ?? true) ||
              (ap.eq?.measurements.isEmpty ?? true) ||
              (ap.frequency?.measurements.isEmpty ?? true);
        }),
        isTrue,
      );
    });
  });

  group('P2B-6 harness and bounds', () {
    test(
        '8-14,84-86. bounds, fingerprints, no production actions, no persona/freq/AI',
        () {
      final pop = gen.generateFamily(
        familyId: 'complete_profiles',
        seed: 5,
        count: 3,
      );
      final b = harness.evaluatePair(
        subjectA: pop.subjects[0].snapshot,
        subjectB: pop.subjects[1].snapshot,
        includeExplanation: true,
      );
      for (final v in [
        b.overall.rawScore,
        b.overall.confidenceAdjustedScore,
        b.overall.overallEvidenceConfidence,
        b.structural.eq?.similarityScore,
        b.preference.mutualRawFitScore,
        b.values.mutualRawValueFitScore,
      ]) {
        expect(isFiniteBounded(v, min: 0, max: 1), isTrue);
      }
      expect(b.structural.deterministicFingerprint, isNotEmpty);
      expect(b.overall.deterministicFingerprint, isNotEmpty);
      expect(b.producedProductionRankingAction, isFalse);
      expect(b.producedLiveMatchAction, isFalse);
      expect(b.wroteFirestore, isFalse);
      expect(b.overall.liveRankingEligible, isFalse);
      expect(b.overall.productionPublishable, isFalse);
      expect(config.raw['persona_input_status'], 'forbidden');
      expect(config.raw['frequency_type_status'], 'forbidden');
      expect(config.raw['ai_scoring_status'], 'forbidden');
      expect(config.raw['complementarity_status'], 'disabled');
      expect(config.raw['temporal_layer_status'], 'disabled');
    });
  });

  group('P2B-6 invariants', () {
    test('15-22,35-38. symmetry, mutual invariance, no NaN/Inf, cohort labels',
        () {
      final pop = gen.generateFamily(
        familyId: 'independent_uniform',
        seed: 9,
        count: 4,
      );
      final ab = harness.evaluatePair(
        subjectA: pop.subjects[0].snapshot,
        subjectB: pop.subjects[1].snapshot,
        includeExplanation: true,
      );
      final ba = harness.evaluatePair(
        subjectA: pop.subjects[1].snapshot,
        subjectB: pop.subjects[0].snapshot,
        includeExplanation: true,
      );
      expect(
        AggregationV1Helpers.nearly(
          ab.structural.eq?.similarityScore,
          ba.structural.eq?.similarityScore,
        ),
        isTrue,
      );
      expect(
        AggregationV1Helpers.nearly(
          ab.preference.mutualRawFitScore,
          ba.preference.mutualRawFitScore,
        ),
        isTrue,
      );
      expect(
        AggregationV1Helpers.nearly(
          ab.values.mutualRawValueFitScore,
          ba.values.mutualRawValueFitScore,
        ),
        isTrue,
      );
      expect(
        AggregationV1Helpers.nearly(ab.overall.rawScore, ba.overall.rawScore),
        isTrue,
      );
      expect(
          ab.overall.rawScore == null || ab.overall.rawScore!.isFinite, isTrue);
      expect(
        ab.overall.confidenceAdjustedScore == null ||
            !ab.overall.confidenceAdjustedScore!.isInfinite,
        isTrue,
      );

      final labeled = SyntheticSubject(
        snapshot: pop.subjects[0].snapshot,
        familyId: pop.subjects[0].familyId,
        opaqueCohortLabel: 'cohort_gamma',
        generationMeta: const {'opaque_cohort_label': 'cohort_gamma'},
      );
      final relabeled = harness.evaluatePair(
        subjectA: labeled.snapshot,
        subjectB: pop.subjects[1].snapshot,
        includeExplanation: true,
      );
      expect(
        AggregationV1Helpers.nearly(
          ab.overall.rawScore,
          relabeled.overall.rawScore,
        ),
        isTrue,
      );
      expect(
        ab.explanation?.deterministicFingerprint,
        relabeled.explanation?.deterministicFingerprint,
      );
    });

    test('19. identity pair structural similarity high when defined', () {
      final pop = gen.generateFamily(
        familyId: 'complete_profiles',
        seed: 1,
        count: 1,
      );
      final s = pop.subjects.first.snapshot;
      final r = harness.evaluateStructuralOnly(subjectA: s, subjectB: s);
      if (r.eq?.similarityScore != null) {
        expect(r.eq!.similarityScore!, greaterThan(0.99));
      }
    });
  });

  group('P2B-6 missingness confidence soft hard explanation', () {
    test('23-34. missingness, confidence shrink, soft non-penalty, hard block',
        () {
      final miss = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.8, 1.0, exclude: {'iq_structural'}),
      );
      expect(miss.includedComponentIds.contains('iq_structural'), isFalse);
      expect(miss.availableConfiguredWeightMass, closeTo(0.92, 1e-12));
      expect(miss.rawScore, closeTo(0.8, 1e-12));

      final lowQ = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.9, 0.2),
      );
      final highQ = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.9, 1.0),
      );
      expect(
        lowQ.overallEvidenceConfidence! < highQ.overallEvidenceConfidence!,
        isTrue,
      );
      expect(
        (lowQ.confidenceAdjustedScore! - 0.5).abs(),
        lessThanOrEqualTo((lowQ.rawScore! - 0.5).abs() + 1e-12),
      );

      final empty = AggregationV1Helpers.aggregate({
        for (final id in CoreMethodAggregationConfig.configuredComponentIds)
          id: AggregationV1Helpers.missing(id),
      });
      expect(empty.rawScore, isNull);
      expect(empty.confidenceAdjustedScore, isNull);

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
          moderateCount: 1,
          highCount: 3,
          highestMutualSeverity: 0.9,
          affectedFieldIds: ['x'],
          diagnosticCodes: ['soft'],
        ),
      );
      expect(soft0.rawScore, softH.rawScore);
      expect(soft0.confidenceAdjustedScore, softH.confidenceAdjustedScore);
      expect(soft0.overallEvidenceConfidence, softH.overallEvidenceConfidence);

      final failed = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.9, 1.0),
        hard: HardConstraintOutcome.failed,
        failedIds: const ['hc'],
      );
      expect(failed.rawScore, isNull);
      expect(failed.confidenceAdjustedScore, isNull);
      expect(
        AggregationV1Helpers.aggregate(
          AggregationV1Helpers.allEqual(0.9, 1.0),
          hard: HardConstraintOutcome.unknown,
        ).hardConstraintOutcome,
        HardConstraintOutcome.unknown,
      );
      expect(
        AggregationV1Helpers.aggregate(
          AggregationV1Helpers.allEqual(0.9, 1.0),
          hard: HardConstraintOutcome.notApplicable,
        ).hardConstraintOutcome,
        HardConstraintOutcome.notApplicable,
      );
    });

    test('35-36. explanation does not alter source scores/contributions', () {
      final pop = gen.generateFamily(
        familyId: 'independent_uniform',
        seed: 4,
        count: 2,
      );
      final b = harness.evaluatePair(
        subjectA: pop.subjects[0].snapshot,
        subjectB: pop.subjects[1].snapshot,
        includeExplanation: true,
      );
      expect(b.explanation, isNotNull);
      expect(b.evaluation.overallScoreResult.rawScore, b.overall.rawScore);
      expect(
        b.evaluation.overallScoreResult.componentContributions.length,
        b.overall.componentContributions.length,
      );
    });
  });

  group('P2B-6 stats weight scale rank', () {
    test('39-47,62-67. correlations, weights, ranks, jaccard', () {
      expect(
        pearsonCorrelation([1, 2, 3], [1, 2, 3]),
        closeTo(1.0, 1e-12),
      );
      expect(
        spearmanCorrelation([1, 3, 2], [1, 3, 2]),
        closeTo(1.0, 1e-12),
      );
      expect(averageRanks([1.0, 1.0, 2.0]), [1.5, 1.5, 3.0]);
      final j = jaccard({'a', 'b'}, {'b'});
      expect(j >= 0 && j <= 1, isTrue);

      final base = AggregationV1Helpers.loadConfig();
      final raw = Map<String, dynamic>.from(base.toJson());
      final w = Map<String, dynamic>.from(raw['component_weights'] as Map);
      w['eq_structural'] = (w['eq_structural'] as num) * 1.2;
      var sum = 0.0;
      for (final v in w.values) {
        sum += (v as num).toDouble();
      }
      for (final k in w.keys.toList()) {
        w[k] = (w[k] as num) / sum;
      }
      raw['component_weights'] = w;
      raw['total_weight'] = 1.0;
      raw['config_id'] = 'local';
      final local = CoreMethodAggregationConfig.fromJson(raw);
      expect(
        local.componentWeights.values.fold<double>(0, (a, b) => a + b),
        closeTo(1.0, 1e-12),
      );
      expect(AggregationV1Helpers.loadConfig().weightOf('iq_structural'), 0.08);

      final rs = rankStabilityReport(
        baselineScores: [0.9, 0.7, 0.5, 0.3],
        otherScores: [0.85, 0.75, 0.45, 0.35],
      );
      expect(rs['spearman'], isNotNull);
      expect((rs['top_10_pct_overlap'] as num) <= 1, isTrue);
    });

    test('48-54. neutral, saturation, histogram, quantiles', () {
      final d = summarizeDistribution(
        [0.1, 0.5, 0.5, 0.95, null],
        quantilePoints: config.quantilePoints,
        histogramBins: 20,
        neutralMin: 0.45,
        neutralMax: 0.55,
      );
      expect(d.values.length, 4);
      expect(d.nullOrInsufficientCount, 1);
      expect(d.histogram.fold<int>(0, (a, b) => a + b), d.values.length);
      double? prev;
      for (final q in config.quantilePoints) {
        final v = d.quantiles[q.toStringAsFixed(2)]!;
        if (prev != null) expect(v + 1e-12, greaterThanOrEqualTo(prev));
        prev = v;
      }
      expect(
        summarizeDistribution(
          List.filled(5, 0.5),
          quantilePoints: const [0.5],
          histogramBins: 20,
          neutralMin: 0.45,
          neutralMax: 0.55,
        ).proportionInNeutralWindow,
        closeTo(1.0, 1e-12),
      );
    });
  });

  group('P2B-6 registries and serialization', () {
    test('97-100. 20d unchanged, 24d fixture, deterministic ser/fp', () {
      expect(dims.registryVersion, 'canonical_dimension_registry_v1');
      expect(dims.dimensions.length, 20);
      expect(load24dFixture().dimensions.length, 24);
      final pop = gen.generateFamily(
        familyId: 'independent_uniform',
        seed: 8,
        count: 2,
      );
      final a = harness.evaluatePair(
        subjectA: pop.subjects[0].snapshot,
        subjectB: pop.subjects[1].snapshot,
      );
      final b = harness.evaluatePair(
        subjectA: pop.subjects[0].snapshot,
        subjectB: pop.subjects[1].snapshot,
      );
      expect(a.overall.deterministicFingerprint,
          b.overall.deterministicFingerprint);
      expect(
        jsonEncode(cmSortedMap(a.overall.toJson())),
        jsonEncode(cmSortedMap(b.overall.toJson())),
      );
      final r1 = RobustnessRng(123);
      final r2 = RobustnessRng(123);
      for (var i = 0; i < 10; i++) {
        expect(r1.nextUint32(), r2.nextUint32());
      }
    });

    test(
        '87-96. production non-integration markers in config and harness flags',
        () {
      expect(config.raw['real_user_data_policy'], 'forbidden_in_this_phase');
      expect(config.raw['production_approval_status'], 'not_approved');
      final pop = gen.generateFamily(
        familyId: 'independent_uniform',
        seed: 1,
        count: 2,
      );
      final b = harness.evaluatePair(
        subjectA: pop.subjects[0].snapshot,
        subjectB: pop.subjects[1].snapshot,
      );
      expect(b.producedProductionRankingAction, isFalse);
      expect(b.producedLiveMatchAction, isFalse);
      expect(b.wroteFirestore, isFalse);
    });
  });
}
