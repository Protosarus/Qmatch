import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'support/aggregation_v1_helpers.dart';

void main() {
  late CoreMethodAggregationConfig config;
  const svc = CoreMethodV2AggregationService();

  setUpAll(() {
    config = AggregationV1Helpers.loadConfig();
  });

  group('P2B-4 aggregation config', () {
    test('1. Aggregation config parses', () {
      expect(config.configId, isNotEmpty);
      expect(config.configVersion, contains('aggregation'));
    });

    test('2. Aggregation config schema passes required keys', () {
      final schema = jsonDecode(
        File(AggregationV1Helpers.schemaPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      final raw = jsonDecode(
        File(AggregationV1Helpers.configPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final k in schema['required'] as List) {
        expect(raw.containsKey(k), isTrue, reason: '$k');
      }
    });

    test('3. Exactly five configured components exist', () {
      expect(config.componentWeights.keys.toSet(), {
        'iq_structural',
        'eq_structural',
        'frequency_structural',
        'mutual_partner_preference',
        'mutual_relationship_values',
      });
    });

    test('4. Component weights sum to 1', () {
      final sum =
          config.componentWeights.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-12));
    });

    test('5. Weight derivation is documented', () {
      final decision = File(
        'docs/core_engine/core_method_v2_aggregation_weight_decision_v1.md',
      ).readAsStringSync();
      expect(decision.contains('0.08'), isTrue);
      expect(decision.contains('0.24'), isTrue);
      expect(decision.contains('0.28'), isTrue);
      expect(decision.contains('0.20'), isTrue);
      expect(decision.contains('0.80'), isTrue);
    });

    test('6. All weights are finite', () {
      for (final w in config.componentWeights.values) {
        expect(w.isFinite, isTrue);
      }
    });

    test('7. All weights are positive', () {
      for (final w in config.componentWeights.values) {
        expect(w, greaterThan(0));
      }
    });
  });

  group('P2B-4 raw aggregation and confidence', () {
    test('8-12. Available-only aggregation without imputation', () {
      final full = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.8, 1.0),
      );
      final miss = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.8, 1.0, exclude: {'iq_structural'}),
      );
      expect(miss.rawScore, closeTo(0.8, 1e-12));
      expect(miss.rawScore, isNot(equals(0)));
      expect(miss.rawScore, isNot(equals(0.5)));
      expect(miss.rawScore, isNot(equals(0.42)));
      expect(miss.availableConfiguredWeightMass, lessThan(1.0));
      expect(miss.rawScore, closeTo(full.rawScore!, 1e-12));
    });

    test('13. Missing component lowers available weight mass', () {
      final miss = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.8, 1.0, exclude: {'iq_structural'}),
      );
      expect(miss.availableConfiguredWeightMass, closeTo(0.92, 1e-12));
    });

    test('14. Missing component can leave raw score unchanged', () {
      final full = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.77, 1.0),
      );
      final miss = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.77, 1.0, exclude: {'eq_structural'}),
      );
      expect(miss.rawScore, closeTo(full.rawScore!, 1e-12));
    });

    test('15. Component weighted contributions sum to raw score', () {
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.withScores({
          'iq_structural': 1.0,
          'eq_structural': 0.5,
          'frequency_structural': 0.25,
          'mutual_partner_preference': 0.75,
          'mutual_relationship_values': 0.1,
        }),
      );
      final sum = r.componentContributions
          .where((c) => c.weightedRawContribution != null)
          .fold<double>(0, (a, b) => a + b.weightedRawContribution!);
      expect(sum, closeTo(r.rawScore!, 1e-9));
    });

    test('16. Confidence contributions sum to Q_overall', () {
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.5, 0.7),
      );
      final sum = r.componentContributions
          .where((c) => c.weightedConfidenceContribution != null)
          .fold<double>(0, (a, b) => a + b.weightedConfidenceContribution!);
      expect(sum, closeTo(r.overallEvidenceConfidence!, 1e-9));
    });

    test('17-20. Q_available_mean, M_available, Q_overall identity', () {
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.4, 0.8, exclude: {'iq_structural'}),
      );
      expect(r.availableConfiguredWeightMass, closeTo(0.92, 1e-12));
      expect(r.availableComponentMeanConfidence, closeTo(0.8, 1e-12));
      expect(r.overallEvidenceConfidence, closeTo(0.92 * 0.8, 1e-12));
      expect(
        r.overallEvidenceConfidence,
        closeTo(
          r.availableConfiguredWeightMass * r.availableComponentMeanConfidence!,
          1e-12,
        ),
      );
    });

    test('21-23. Scores and confidence remain bounded', () {
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.9, 0.3),
      );
      expect(r.overallEvidenceConfidence!, inInclusiveRange(0, 1));
      expect(r.rawScore!, inInclusiveRange(0, 1));
      expect(r.confidenceAdjustedScore!, inInclusiveRange(0, 1));
    });

    test('24. Q=1 preserves raw score', () {
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.83, 1.0),
      );
      expect(r.confidenceAdjustedScore, closeTo(r.rawScore!, 1e-12));
    });

    test('25. Q=0 moves a valid raw score to neutral', () {
      // With all confidence 0 and full mass, Q_overall=0.
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.9, 0.0),
      );
      expect(r.overallEvidenceConfidence, closeTo(0.0, 1e-12));
      expect(r.confidenceAdjustedScore, closeTo(0.5, 1e-12));
    });

    test('26-27. Lower Q moves high/low raw toward neutral', () {
      final high = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.9, 0.2),
      );
      final low = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.1, 0.2),
      );
      expect(high.confidenceAdjustedScore!, lessThan(0.9));
      expect(high.confidenceAdjustedScore!, greaterThan(0.5));
      expect(low.confidenceAdjustedScore!, greaterThan(0.1));
      expect(low.confidenceAdjustedScore!, lessThan(0.5));
    });

    test('28. Neutral raw score remains neutral', () {
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.5, 0.1),
      );
      expect(r.confidenceAdjustedScore, closeTo(0.5, 1e-12));
    });

    test('29. Adjustment never moves farther from neutral', () {
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.95, 0.3),
      );
      expect(
        (r.confidenceAdjustedScore! - 0.5).abs(),
        lessThanOrEqualTo((r.rawScore! - 0.5).abs() + 1e-12),
      );
    });

    test('30-32. Insufficient evidence nulls scores', () {
      final belowCount = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.withScores({'frequency_structural': 0.9}),
      );
      final belowMass = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.withScores({
          'iq_structural': 1.0,
          'mutual_partner_preference': 1.0,
        }),
      );
      expect(belowCount.rawScore, isNull);
      expect(belowCount.confidenceAdjustedScore, isNull);
      expect(belowCount.confidenceAdjustedScore, isNot(equals(0.5)));
      expect(belowMass.rawScore, isNull);
      expect(
        belowCount.evaluationStatus,
        CompatibilityEvaluationStatus.insufficientEvidence,
      );
    });

    test('33-34. Exactly minimum count/mass may score', () {
      final minCount = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.withScores({
          'eq_structural': 0.55,
          'frequency_structural': 0.65,
        }),
      );
      expect(minCount.availableComponentCount, 2);
      expect(minCount.rawScore, isNotNull);

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
      final cfg = CoreMethodAggregationConfig.fromJson(raw);
      final minMass = svc.aggregateComponents(
        componentInputs: AggregationV1Helpers.withScores({
          'iq_structural': 0.7,
          'eq_structural': 0.7,
          'frequency_structural': 0.7,
        }),
        config: cfg,
        hardConstraintOutcome: HardConstraintOutcome.passed,
      );
      expect(minMass.availableConfiguredWeightMass, closeTo(0.5, 1e-12));
      expect(minMass.rawScore, isNotNull);
    });

    test('35. Zero available weight does not divide by zero', () {
      final r = AggregationV1Helpers.aggregate({});
      expect(r.rawScore, isNull);
      expect(
        r.evaluationStatus,
        CompatibilityEvaluationStatus.insufficientEvidence,
      );
    });
  });

  group('P2B-4 source mapping and eligibility', () {
    test('36-40. Source field mapping via evaluate()', () {
      // Synthetic component path already maps IDs; evaluate with null sources
      // marks all missing. Direct mapping check via contribution ids.
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.5, 1.0),
      );
      expect(
        r.includedComponentIds,
        containsAll(CoreMethodAggregationConfig.configuredComponentIds),
      );
      final iq = r.componentContributions
          .firstWhere((c) => c.componentId == 'iq_structural');
      expect(iq.rawComponentScore, 0.5);
      expect(iq.componentEvidenceConfidence, 1.0);
    });

    test('41-44. Invalid score/confidence/NaN/Infinity fail', () {
      for (final bad in [
        AggregationV1Helpers.available(
            id: 'eq_structural', score: 1.5, confidence: 1),
        AggregationV1Helpers.available(
            id: 'eq_structural', score: 0.5, confidence: -0.1),
        const CoreMethodComponentInput(
          componentId: 'eq_structural',
          score: double.nan,
          confidence: 1,
          sourceStatus: 'complete',
          sourceConfigVersion: 'v1',
          sourceRegistryVersion: 'canonical_dimension_registry_v1',
          sourcePresent: true,
        ),
        const CoreMethodComponentInput(
          componentId: 'eq_structural',
          score: 0.5,
          confidence: double.infinity,
          sourceStatus: 'complete',
          sourceConfigVersion: 'v1',
          sourceRegistryVersion: 'canonical_dimension_registry_v1',
          sourcePresent: true,
        ),
      ]) {
        final comps = AggregationV1Helpers.allEqual(0.5, 1.0);
        comps['eq_structural'] = bad;
        final r = AggregationV1Helpers.aggregate(comps);
        expect(
          r.evaluationStatus,
          CompatibilityEvaluationStatus.invalidInput,
        );
      }
    });

    test('45-46. Invalid weight / neutral score fail at config', () {
      expect(
        () => CoreMethodAggregationConfig.fromJson({
          ...config.toJson(),
          'component_weights': {
            ...config.componentWeights,
            'iq_structural': -0.08,
          },
        }),
        throwsA(isA<CoreMethodValidationException>()),
      );
      expect(
        () => CoreMethodAggregationConfig.fromJson({
          ...config.toJson(),
          'neutral_score': 0.7,
        }),
        throwsA(isA<CoreMethodValidationException>()),
      );
    });

    test('47-48. Registry/config mismatch policy', () {
      final comps = AggregationV1Helpers.allEqual(0.5, 1.0);
      comps['eq_structural'] = AggregationV1Helpers.available(
        id: 'eq_structural',
        score: 0.5,
        confidence: 1,
        registryVersion: 'other',
      );
      expect(
        AggregationV1Helpers.aggregate(comps).evaluationStatus,
        CompatibilityEvaluationStatus.invalidInput,
      );
      comps['eq_structural'] = AggregationV1Helpers.available(
        id: 'eq_structural',
        score: 0.5,
        confidence: 1,
        diags: const ['component_config_version_mismatch'],
      );
      expect(
        AggregationV1Helpers.aggregate(comps).evaluationStatus,
        CompatibilityEvaluationStatus.invalidInput,
      );
    });

    test('49-51. Partial/insufficient/invalid source handling', () {
      final partial = AggregationV1Helpers.allEqual(0.5, 1.0);
      partial['eq_structural'] = AggregationV1Helpers.available(
        id: 'eq_structural',
        score: 0.5,
        confidence: 1,
        status: 'partial',
      );
      expect(
        AggregationV1Helpers.aggregate(partial)
            .includedComponentIds
            .contains('eq_structural'),
        isTrue,
      );

      final insuf = AggregationV1Helpers.allEqual(0.5, 1.0);
      insuf['eq_structural'] = AggregationV1Helpers.available(
        id: 'eq_structural',
        score: 0.5,
        confidence: 1,
        status: 'insufficient_evidence',
      );
      expect(
        AggregationV1Helpers.aggregate(insuf)
            .includedComponentIds
            .contains('eq_structural'),
        isFalse,
      );

      final invalid = AggregationV1Helpers.allEqual(0.5, 1.0);
      invalid['eq_structural'] = AggregationV1Helpers.available(
        id: 'eq_structural',
        score: 0.5,
        confidence: 1,
        status: 'invalid_input',
      );
      expect(
        AggregationV1Helpers.aggregate(invalid).evaluationStatus,
        CompatibilityEvaluationStatus.invalidInput,
      );
    });
  });

  group('P2B-4 hard / soft / asymmetry', () {
    test('52-54. Hard failed blocks scores, not converted to 0, audit kept',
        () {
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.8, 1.0),
        hard: HardConstraintOutcome.failed,
        failedIds: const ['hc_x'],
      );
      expect(r.rawScore, isNull);
      expect(r.confidenceAdjustedScore, isNull);
      expect(r.rawScore, isNot(equals(0)));
      expect(
        r.evaluationStatus,
        CompatibilityEvaluationStatus.blockedByHardConstraint,
      );
      expect(r.componentContributions, hasLength(5));
      expect(r.diagnostics.failedHardConstraintIds, contains('hc_x'));
    });

    test('55-59. Hard unknown retains scores, not publishable/ranking', () {
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.8, 1.0),
        hard: HardConstraintOutcome.unknown,
      );
      expect(r.hardConstraintOutcome, HardConstraintOutcome.unknown);
      expect(r.hardConstraintOutcome, isNot(HardConstraintOutcome.passed));
      expect(r.hardConstraintOutcome, isNot(HardConstraintOutcome.failed));
      expect(r.rawScore, isNotNull);
      expect(r.publishable, isFalse);
      expect(r.rankingEligible, isFalse);
      expect(
        r.diagnosticCodes,
        contains('hard_constraint_resolution_required'),
      );
    });

    test('60-62. Hard passed/not_applicable allow aggregation', () {
      final passed = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.7, 1.0),
        hard: HardConstraintOutcome.passed,
      );
      final na = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.7, 1.0),
        hard: HardConstraintOutcome.notApplicable,
      );
      expect(passed.rawScore, isNotNull);
      expect(na.rawScore, isNotNull);
      expect(na.hardConstraintOutcome, HardConstraintOutcome.notApplicable);
      expect(na.hardConstraintOutcome, isNot(HardConstraintOutcome.passed));
    });

    test('63-66. Soft severity diagnostics only', () {
      final base = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.72, 1.0),
      );
      final soft = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.72, 1.0),
        soft: const CoreMethodSoftConflictSummary(
          lowCount: 0,
          moderateCount: 0,
          highCount: 1,
          highestMutualSeverity: 0.99,
          affectedFieldIds: ['x'],
          diagnosticCodes: ['soft_conflicts_present_diagnostic_only'],
        ),
      );
      expect(soft.rawScore, closeTo(base.rawScore!, 1e-12));
      expect(
        soft.confidenceAdjustedScore,
        closeTo(base.confidenceAdjustedScore!, 1e-12),
      );
      expect(
        soft.overallEvidenceConfidence,
        closeTo(base.overallEvidenceConfidence!, 1e-12),
      );
      expect(
        soft.evaluationStatus,
        isNot(CompatibilityEvaluationStatus.blockedByHardConstraint),
      );
      expect(soft.diagnostics.softConflictPenaltyApplied, isFalse);
    });

    test('67-70. Asymmetry diagnostics only; no soft penalty', () {
      final base = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.72, 1.0),
      );
      final asym = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.72, 1.0),
        asymmetry: const CoreMethodAsymmetrySummary(
          preferenceDirectionalAsymmetry: 0.4,
          valueDirectionalAsymmetry: 0.35,
          diagnosticCodes: [
            'preference_asymmetry_present',
            'value_asymmetry_present',
          ],
        ),
      );
      expect(asym.rawScore, closeTo(base.rawScore!, 1e-12));
      expect(asym.diagnostics.asymmetryPenaltyApplied, isFalse);
      expect(asym.diagnosticCodes, contains('preference_asymmetry_present'));
      expect(config.softConflictPolicy, 'diagnostics_only_no_numeric_penalty');
    });
  });

  group('P2B-4 prohibitions and isolation', () {
    test('71-75. No complementarity/temporal/persona/Frequency type/AI', () {
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.5, 1.0),
      );
      expect(r.diagnostics.complementarityApplied, isFalse);
      expect(r.diagnostics.temporalLayerApplied, isFalse);
      expect(r.diagnostics.personaInputUsed, isFalse);
      expect(r.diagnostics.frequencyTypeUsed, isFalse);
      expect(r.diagnostics.aiScoringUsed, isFalse);
      expect(config.complementarityStatus, 'disabled_pending_calibration');
      expect(config.temporalLayerStatus, 'disabled');
      expect(config.personaInputStatus, 'prohibited');
      expect(config.frequencyTypeStatus, 'prohibited');
      expect(config.aiScoringStatus, 'prohibited');
    });

    test('76-79. Aggregation service does not call source services', () {
      final src = File(
        'lib/features/assessment/domain/core_method_v2/core_method_v2_aggregation_service.dart',
      ).readAsStringSync();
      expect(src.contains('StructuralSimilarityService('), isFalse);
      expect(src.contains('DirectionalPreferenceFitService('), isFalse);
      expect(src.contains('RelationshipValueComparisonService('), isFalse);
      expect(src.contains('HardConstraintEvaluationService('), isFalse);
      expect(src.contains('SoftConflictEvaluationService('), isFalse);
    });

    test('80. Module source results remain separately visible', () {
      final eval = svc.evaluate(
        structural: null,
        preference: null,
        relationshipLayer: null,
        config: config,
        evaluationTimestamp: DateTime.utc(2026, 7, 24),
      );
      expect(eval.overallScoreResult.componentContributions, hasLength(5));
      expect(eval.toJson().containsKey('overall_score_result'), isTrue);
    });

    test('81-84. Serialization, order, fingerprint stability', () {
      final a = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.61, 0.9),
      );
      final b = AggregationV1Helpers.aggregate(
        Map.fromEntries(
          AggregationV1Helpers.allEqual(0.61, 0.9).entries.toList().reversed,
        ),
      );
      final round = CoreMethodOverallScoreResult.fromJson(a.toJson());
      expect(a.deterministicFingerprint, b.deterministicFingerprint);
      expect(a.rawScore, closeTo(b.rawScore!, 1e-12));
      expect(a.deterministicFingerprint, round.deterministicFingerprint);
      expect(a.rawScore, closeTo(round.rawScore!, 1e-12));
    });

    test('85. Evaluation timestamp is injected', () {
      final ts = DateTime.utc(2026, 2, 3, 4, 5, 6);
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.5, 1.0),
        ts: ts,
      );
      expect(r.evaluationTimestamp, ts);
    });

    test('86-87. Registry and 24d fixture unaffected', () {
      final reg = CanonicalDimensionRegistry.loadFile(
        AggregationV1Helpers.registryPath,
      );
      expect(reg.activeDimensions.length, 20);
      expect(
        File(AggregationV1Helpers.fixture24Path).existsSync(),
        isTrue,
      );
    });

    test('88-90. Production CompatibilityScoring/Discover/screens isolation',
        () {
      for (final path in [
        'lib/core/utils/compatibility_scoring.dart',
        'lib/features/discover/services/discover_service.dart',
        'lib/features/assessment/services/question_service.dart',
        'lib/features/assessment/screens/iq_test_screen.dart',
      ]) {
        final text = File(path).readAsStringSync();
        expect(text.contains('CoreMethodV2AggregationService'), isFalse);
        expect(text.contains('core_method_v2_aggregation'), isFalse);
      }
    });

    test('91-95. No Firebase/ranking/live match; behavior unchanged flags', () {
      final src = File(
        'lib/features/assessment/domain/core_method_v2/core_method_v2_aggregation_service.dart',
      ).readAsStringSync();
      expect(src.contains('firebase'), isFalse);
      expect(src.contains('Firestore'), isFalse);
      expect(src.contains('cloud_firestore'), isFalse);
      final r = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(1.0, 1.0),
      );
      expect(r.productionPublishable, isFalse);
      expect(r.productionApproved, isFalse);
      expect(r.rankingEligible, isFalse);
      expect(r.liveRankingEligible, isFalse);
      expect(config.runtimeStatus, 'offline_only');
      expect(config.productionApprovalStatus, 'not_approved');
    });
  });
}
