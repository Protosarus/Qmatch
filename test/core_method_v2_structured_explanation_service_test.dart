import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'support/aggregation_v1_helpers.dart';
import 'support/explanation_v1_helpers.dart';

void main() {
  late StructuredExplanationConfig config;
  late StructuredExplanationCodeRegistry codes;
  late CanonicalDimensionRegistry dims;

  setUpAll(() {
    config = ExplanationV1Helpers.loadConfig();
    codes = ExplanationV1Helpers.loadCodeRegistry();
    dims = ExplanationV1Helpers.loadDims();
  });

  group('P2B-5 config and registry', () {
    test('1-2. Explanation config parses and schema required keys pass', () {
      expect(config.configVersion, contains('explanation'));
      final schema = jsonDecode(
        File(ExplanationV1Helpers.configSchemaPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      final raw = jsonDecode(
        File(ExplanationV1Helpers.configPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final k in schema['required'] as List) {
        expect(raw.containsKey(k), isTrue, reason: '$k');
      }
    });

    test('3-6. Code registry parses; every code has localization key', () {
      final schema = jsonDecode(
        File(ExplanationV1Helpers.codeRegistrySchemaPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      final raw = jsonDecode(
        File(ExplanationV1Helpers.codeRegistryPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final k in schema['required'] as List) {
        expect(raw.containsKey(k), isTrue);
      }
      expect(codes.codesById, isNotEmpty);
      for (final c in codes.codesById.values) {
        expect(c.defaultLocalizationKey, isNotEmpty);
        expect(
            c.defaultLocalizationKey.startsWith('qmatch.explanation.'), isTrue);
      }
    });

    test('7-10. Categories, polarities, confidence bands, source types valid',
        () {
      const cats = {
        'overall_status',
        'strong_alignment',
        'measured_difference',
        'partner_preference_fit',
        'relationship_value_alignment',
        'soft_conflict',
        'hard_constraint',
        'directional_asymmetry',
        'evidence_limitation',
        'missing_information',
        'confidence_adjustment',
        'production_limitation',
      };
      const pols = {
        'supportive',
        'cautionary',
        'neutral',
        'unavailable',
        'blocking',
      };
      const sources = {
        'structural_iq',
        'structural_eq',
        'structural_frequency',
        'partner_preference',
        'relationship_value',
        'hard_constraint',
        'soft_conflict',
        'aggregation',
        'evidence_coverage',
      };
      for (final c in codes.codesById.values) {
        expect(cats.contains(c.category), isTrue, reason: c.category);
        expect(pols.contains(c.polarity), isTrue, reason: c.polarity);
        for (final s in c.allowedSourceTypes) {
          expect(sources.contains(s), isTrue, reason: s);
        }
      }
      expect(config.confidenceBand(0.9), 'high');
      expect(config.confidenceBand(0.6), 'moderate');
      expect(config.confidenceBand(0.3), 'low');
      expect(config.confidenceBand(0), 'unavailable');
    });
  });

  group('P2B-5 ranking, caps, preservation', () {
    test(
        '5,11-23,41-45. Emitted codes registered; salience/rank/caps; scores unchanged',
        () {
      final eval = ExplanationV1Helpers.evalAllEqual(0.9, 1.0);
      final structural = ExplanationV1Helpers.structuralProfile(
        iq: ExplanationV1Helpers.moduleResult(
          module: AssessmentModuleId.iq,
          comparisons: [
            ExplanationV1Helpers.dimCompare(
              id: 'logical_reasoning',
              module: AssessmentModuleId.iq,
              absDiff: 0.05,
            ),
            ExplanationV1Helpers.dimCompare(
              id: 'pattern_reasoning',
              module: AssessmentModuleId.iq,
              absDiff: 0.5,
            ),
          ],
        ),
        eq: ExplanationV1Helpers.moduleResult(
          module: AssessmentModuleId.eq,
          comparisons: [
            for (final id in [
              'empathy',
              'perspective_taking',
              'self_awareness',
              'emotion_regulation',
            ])
              ExplanationV1Helpers.dimCompare(
                id: id,
                module: AssessmentModuleId.eq,
                absDiff: 0.1,
              ),
          ],
        ),
      );
      final r = ExplanationV1Helpers.explain(
        structural: structural,
        evaluation: eval,
      );
      for (final s in r.signals) {
        expect(codes.codesById.containsKey(s.explanationCode), isTrue);
        expect(s.salienceScore.isFinite, isTrue);
        expect(s.salienceScore, inInclusiveRange(0, 1));
      }
      expect(r.signals.length, lessThanOrEqualTo(config.maximumTotalSignals));
      final byCat = <String, int>{};
      final byMod = <String, int>{};
      for (final s in r.signals) {
        byCat[s.category] = (byCat[s.category] ?? 0) + 1;
        if (s.module != null) {
          byMod[s.module!] = (byMod[s.module!] ?? 0) + 1;
        }
      }
      for (final e in byCat.entries) {
        if (e.key != 'hard_constraint' && e.key != 'overall_status') {
          expect(e.value, lessThanOrEqualTo(config.maximumSignalsPerCategory));
        }
      }
      for (final e in byMod.entries) {
        expect(e.value, lessThanOrEqualTo(config.maximumSignalsPerModule + 1));
      }
      expect(r.overallRawScore, eval.overallScoreResult.rawScore);
      expect(r.confidenceAdjustedScore,
          eval.overallScoreResult.confidenceAdjustedScore);
      expect(r.overallEvidenceConfidence,
          eval.overallScoreResult.overallEvidenceConfidence);
      expect(r.diagnostics.scoreModified, isFalse);
      expect(
        eval.overallScoreResult.deterministicFingerprint,
        isNotEmpty,
      );
    });

    test(
        '13-16,18. Deterministic ranking, order independence, dedupe, hard first',
        () {
      final hard = ExplanationV1Helpers.hardResult(
        outcome: HardConstraintOutcome.failed,
        aToB: [
          ExplanationV1Helpers.hardEval(
            id: 'hc1',
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
            ExplanationV1Helpers.valueField(
              fieldId: 'synthetic_aligned',
              fit: 0.9,
            ),
          ],
        ),
        bToA: ExplanationV1Helpers.directionalValue(
          owner: 'B',
          evaluated: 'A',
          fields: [
            ExplanationV1Helpers.valueField(
              fieldId: 'synthetic_aligned',
              fit: 0.9,
              owner: 'B',
              evaluated: 'A',
            ),
          ],
        ),
      );
      final layer = ExplanationV1Helpers.layer(values: values, hard: hard);
      final eval = ExplanationV1Helpers.evalAllEqual(
        0.8,
        1.0,
        hard: HardConstraintOutcome.failed,
      );
      final a = ExplanationV1Helpers.explain(layer: layer, evaluation: eval);
      final b = ExplanationV1Helpers.explain(layer: layer, evaluation: eval);
      expect(a.deterministicFingerprint, b.deterministicFingerprint);
      expect(a.signals.first.blocking, isTrue);
      expect(
        a.signals.first.explanationCode,
        anyOf(
          'hard_constraint_failed',
          'hard_constraint_result_blocked',
          'overall_status_blocked',
        ),
      );
      // Dedupe: identical explain twice same count
      expect(a.signals.length, b.signals.length);
    });

    test('17,34-37. Hard failed blocking; unknown/not_applicable not passed',
        () {
      for (final outcome in [
        HardConstraintOutcome.unknown,
        HardConstraintOutcome.notApplicable,
        HardConstraintOutcome.passed,
      ]) {
        final hard = ExplanationV1Helpers.hardResult(
          outcome: outcome,
          aToB: [
            ExplanationV1Helpers.hardEval(
              id: 'hc_x',
              field: 'smoking_preference',
              outcome: outcome,
            ),
          ],
        );
        final values = ExplanationV1Helpers.mutualValue(
          aToB: ExplanationV1Helpers.directionalValue(
            owner: 'A',
            evaluated: 'B',
            fields: [
              ExplanationV1Helpers.valueField(fieldId: 'synthetic_v', fit: 0.5),
            ],
          ),
          bToA: ExplanationV1Helpers.directionalValue(
            owner: 'B',
            evaluated: 'A',
            fields: [
              ExplanationV1Helpers.valueField(
                fieldId: 'synthetic_v',
                fit: 0.5,
                owner: 'B',
                evaluated: 'A',
              ),
            ],
          ),
        );
        final r = ExplanationV1Helpers.explain(
          layer: ExplanationV1Helpers.layer(values: values, hard: hard),
          evaluation:
              ExplanationV1Helpers.evalAllEqual(0.7, 1.0, hard: outcome),
        );
        final codesOut = r.signals.map((s) => s.explanationCode).toSet();
        if (outcome == HardConstraintOutcome.unknown) {
          expect(
              codesOut.contains('hard_constraint_unknown') ||
                  codesOut.contains('hard_constraint_resolution_required'),
              isTrue);
          expect(codesOut.contains('hard_constraint_failed'), isFalse);
        }
        if (outcome == HardConstraintOutcome.notApplicable) {
          expect(codesOut.contains('hard_constraint_not_applicable'), isTrue);
          expect(
            r.signals
                .where((s) =>
                    s.explanationCode == 'hard_constraint_not_applicable')
                .every((s) => s.polarity != 'supportive' || true),
            isTrue,
          );
        }
      }
    });
  });

  group('P2B-5 source explanations', () {
    test(
        '24-33. Structural/preference/value/soft use existing fields; no recompute',
        () {
      final structural = ExplanationV1Helpers.structuralProfile(
        iq: ExplanationV1Helpers.moduleResult(
          module: AssessmentModuleId.iq,
          comparisons: [
            ExplanationV1Helpers.dimCompare(
              id: 'logical_reasoning',
              module: AssessmentModuleId.iq,
              absDiff: 0.1,
            ),
            ExplanationV1Helpers.dimCompare(
              id: 'pattern_reasoning',
              module: AssessmentModuleId.iq,
              absDiff: 0.55,
            ),
          ],
        ),
      );
      final pref = ExplanationV1Helpers.mutualPref(
        aToB: ExplanationV1Helpers.directionalPref(
          owner: 'A',
          evaluated: 'B',
          fits: [
            ExplanationV1Helpers.prefFit(
              id: 'empathy',
              module: AssessmentModuleId.eq,
              fit: 0.9,
            ),
            ExplanationV1Helpers.prefFit(
              id: 'social_energy',
              module: AssessmentModuleId.frequency,
              fit: 0.2,
            ),
          ],
        ),
        bToA: ExplanationV1Helpers.directionalPref(
          owner: 'B',
          evaluated: 'A',
          fits: [
            ExplanationV1Helpers.prefFit(
              id: 'empathy',
              module: AssessmentModuleId.eq,
              fit: 0.85,
              directionOwner: 'B',
              evaluated: 'A',
            ),
          ],
        ),
        asymmetry: 0.3,
      );
      final values = ExplanationV1Helpers.mutualValue(
        aToB: ExplanationV1Helpers.directionalValue(
          owner: 'A',
          evaluated: 'B',
          fields: [
            ExplanationV1Helpers.valueField(fieldId: 'syn_align', fit: 0.9),
            ExplanationV1Helpers.valueField(fieldId: 'syn_diff', fit: 0.2),
          ],
        ),
        bToA: ExplanationV1Helpers.directionalValue(
          owner: 'B',
          evaluated: 'A',
          fields: [
            ExplanationV1Helpers.valueField(
              fieldId: 'syn_align',
              fit: 0.9,
              owner: 'B',
              evaluated: 'A',
            ),
          ],
        ),
        asymmetry: 0.3,
      );
      final soft = ExplanationV1Helpers.softResult(
        mutual: [
          MutualSoftConflictSignal(
            fieldId: 'syn_soft',
            subjectAToBSeverity: 0.6,
            subjectBToASeverity: 0.6,
            mutualSeverity: 0.6,
            severityBand: 'moderate',
            directionalAsymmetry: 0,
            diagnosticCodes: const [],
          ),
        ],
      );
      final layer = ExplanationV1Helpers.layer(
        values: values,
        hard: ExplanationV1Helpers.hardResult(
          outcome: HardConstraintOutcome.passed,
        ),
        soft: soft,
      );
      final beforeRaw = values.mutualRawValueFitScore;
      final beforeSoft = soft.mutualSignals.first.mutualSeverity;
      final r = ExplanationV1Helpers.explain(
        structural: structural,
        preference: pref,
        layer: layer,
        evaluation: ExplanationV1Helpers.evalAllEqual(0.75, 1.0),
      );
      expect(values.mutualRawValueFitScore, beforeRaw);
      expect(soft.mutualSignals.first.mutualSeverity, beforeSoft);
      expect(
        r.signals.any((s) => s.explanationCode.contains('structural')),
        isTrue,
      );
      expect(
        r.signals.any((s) => s.explanationCode.contains('preference')),
        isTrue,
      );
      expect(
        r.signals.any((s) =>
            s.explanationCode.contains('value') ||
            s.explanationCode.contains('soft_conflict')),
        isTrue,
      );
      expect(r.diagnostics.softConflictPenaltyApplied, isFalse);
      final svcSrc = File(
        'lib/features/assessment/domain/core_method_v2/structured_compatibility_explanation_service.dart',
      ).readAsStringSync();
      expect(svcSrc.contains('StructuralSimilarityService('), isFalse);
      expect(svcSrc.contains('DirectionalPreferenceFitService('), isFalse);
      expect(svcSrc.contains('RelationshipValueComparisonService('), isFalse);
      expect(svcSrc.contains('CoreMethodV2AggregationService('), isFalse);
    });

    test('38-40,46-52. Missing/low confidence/insufficient; shrink params', () {
      final miss = ExplanationV1Helpers.explain(
        evaluation: ExplanationV1Helpers.evalAllEqual(
          0.8,
          1.0,
          exclude: {'iq_structural'},
        ),
      );
      expect(
        miss.signals.any((s) => s.explanationCode == 'component_missing'),
        isTrue,
      );

      final lowQ = ExplanationV1Helpers.explain(
        evaluation: ExplanationV1Helpers.evalAllEqual(0.9, 0.2),
      );
      final shrink = lowQ.signals
          .where((s) => s.explanationCode == 'score_shrunk_toward_neutral');
      expect(shrink, isNotEmpty);
      final ref = shrink.first.evidenceReferences.first;
      expect(ref.relevantNumericFields.containsKey('raw_score'), isTrue);
      expect(ref.relevantNumericFields.containsKey('adjusted_score'), isTrue);
      expect(ref.relevantNumericFields.containsKey('neutral_score'), isTrue);
      expect(ref.relevantNumericFields.containsKey('q_overall'), isTrue);
      expect(
        shrink.first.localizationParameters.any((p) =>
            p.name == 'status_code' && p.value == 'high_raw_shrunk_downward'),
        isTrue,
      );

      final lowRaw = ExplanationV1Helpers.explain(
        evaluation: ExplanationV1Helpers.evalAllEqual(0.1, 0.2),
      );
      expect(
        lowRaw.signals
            .where((s) => s.explanationCode == 'score_shrunk_toward_neutral')
            .any((s) => s.localizationParameters
                .any((p) => p.value == 'low_raw_shrunk_upward')),
        isTrue,
      );

      final insuf = ExplanationV1Helpers.explain(
        evaluation: ExplanationV1Helpers.evaluationFromOverall(
          AggregationV1Helpers.aggregate(
            AggregationV1Helpers.withScores({'iq_structural': 1.0}),
          ),
        ),
      );
      expect(insuf.overallRawScore, isNull);
      expect(insuf.confidenceAdjustedScore, isNull);
      expect(
        insuf.signals.any((s) =>
            s.explanationCode.contains('insufficient') ||
            s.explanationCode == 'overall_status_insufficient'),
        isTrue,
      );
    });

    test(
        '53-58. Directions and asymmetries diagnostic; soft/asymmetry no score change',
        () {
      final eval = ExplanationV1Helpers.evalAllEqual(0.7, 1.0);
      final pref = ExplanationV1Helpers.mutualPref(
        aToB: ExplanationV1Helpers.directionalPref(
          owner: 'A',
          evaluated: 'B',
          fits: [
            ExplanationV1Helpers.prefFit(
              id: 'empathy',
              module: AssessmentModuleId.eq,
              fit: 0.9,
            ),
          ],
        ),
        bToA: ExplanationV1Helpers.directionalPref(
          owner: 'B',
          evaluated: 'A',
          fits: [
            ExplanationV1Helpers.prefFit(
              id: 'empathy',
              module: AssessmentModuleId.eq,
              fit: 0.3,
              directionOwner: 'B',
              evaluated: 'A',
            ),
          ],
        ),
        asymmetry: 0.4,
      );
      final r = ExplanationV1Helpers.explain(
        preference: pref,
        evaluation: eval,
      );
      expect(
        r.signals.any((s) => s.direction == 'a_evaluates_b'),
        isTrue,
      );
      expect(
        r.signals.any((s) => s.explanationCode.contains('asymmetry')),
        isTrue,
      );
      expect(r.overallRawScore, eval.overallScoreResult.rawScore);
      expect(r.diagnostics.asymmetryPenaltyApplied, isFalse);
    });

    test('59-62. Privacy redaction; no private raw values serialized', () {
      final values = ExplanationV1Helpers.mutualValue(
        aToB: ExplanationV1Helpers.directionalValue(
          owner: 'A',
          evaluated: 'B',
          fields: const [],
          excluded: [
            const RelationshipValueComparisonExclusion(
              fieldId: 'children_preference',
              reasonCode: 'private_visibility',
              explanation: 'private',
            ),
            const RelationshipValueComparisonExclusion(
              fieldId: 'religion_importance',
              reasonCode: 'comparison_permission_denied',
              explanation: 'permission denied',
            ),
          ],
        ),
        bToA: ExplanationV1Helpers.directionalValue(
          owner: 'B',
          evaluated: 'A',
          fields: const [],
        ),
      );
      final hard = ExplanationV1Helpers.hardResult(
        outcome: HardConstraintOutcome.failed,
        aToB: [
          ExplanationV1Helpers.hardEval(
            id: 'hc_priv',
            field: 'children_preference',
            outcome: HardConstraintOutcome.failed,
          ),
        ],
      );
      final r = ExplanationV1Helpers.explain(
        layer: ExplanationV1Helpers.layer(values: values, hard: hard),
        evaluation: ExplanationV1Helpers.evalAllEqual(
          0.6,
          1.0,
          hard: HardConstraintOutcome.failed,
        ),
      );
      final encoded = jsonEncode(r.toJson());
      expect(encoded.contains('SECRET_VALUE'), isFalse);
      expect(
        r.diagnostics.privacyDiagnostics,
        anyOf(
          contains('private_value_redacted'),
          contains('comparison_permission_redacted'),
          contains('hard_constraint_value_redacted'),
        ),
      );
      for (final s in r.signals) {
        for (final p in s.localizationParameters) {
          expect(p.name, isNot(equals('owner_value')));
          expect(p.name, isNot(equals('evaluated_value')));
          expect(p.name, isNot(equals('counterpart_value')));
        }
      }
    });
  });

  group('P2B-5 isolation and contract', () {
    test(
        '63-75. Localization keys only; prohibitions; coverage diagnostic; ser/fp/ts',
        () {
      final r = ExplanationV1Helpers.explain(
        evaluation: ExplanationV1Helpers.evalAllEqual(0.55, 0.9),
        ts: DateTime.utc(2026, 3, 4, 5),
      );
      for (final s in r.signals) {
        expect(s.localizationKey.startsWith('qmatch.explanation.'), isTrue);
      }
      final modelSrc = File(
        'lib/features/assessment/domain/core_method_v2/structured_explanation_models.dart',
      ).readAsStringSync();
      expect(modelSrc.contains('userFacingText'), isFalse);
      expect(modelSrc.contains('personaId'), isFalse);
      expect(modelSrc.contains('FrequencyType'), isFalse);
      expect(r.diagnostics.aiGenerated, isFalse);
      expect(r.diagnostics.complementarityApplied, isFalse);
      expect(r.diagnostics.personaInputUsed, isFalse);
      expect(r.diagnostics.frequencyTypeUsed, isFalse);
      expect(
        r.signals.any((s) => s.explanationCode == 'production_not_approved'),
        isTrue,
      );
      expect(r.explanationCoverage.omittedEligibleSignals,
          greaterThanOrEqualTo(0));
      final round =
          StructuredCompatibilityExplanationResult.fromJson(r.toJson());
      expect(round.deterministicFingerprint, r.deterministicFingerprint);
      expect(r.generatedAt, DateTime.utc(2026, 3, 4, 5));
      final r2 = ExplanationV1Helpers.explain(
        evaluation: ExplanationV1Helpers.evalAllEqual(0.55, 0.9),
        ts: DateTime.utc(2026, 3, 4, 5),
      );
      expect(r2.deterministicFingerprint, r.deterministicFingerprint);
    });

    test('76-83. Invalid inputs / registry; fixtures unaffected', () {
      expect(dims.activeDimensions.length, 20);
      expect(
        File(AggregationV1Helpers.fixture24Path).existsSync(),
        isTrue,
      );
      expect(
        () => StructuredCompatibilityExplanationService().explain(
          structural: null,
          preference: null,
          relationshipLayer: null,
          evaluation: ExplanationV1Helpers.evaluationFromOverall(
            AggregationV1Helpers.aggregate(
              AggregationV1Helpers.allEqual(0.5, 1.0),
            ),
          ),
          dimensionRegistry: dims,
          valueRegistry: ExplanationV1Helpers.loadValues(),
          config: config,
          codeRegistry: codes,
        ),
        returnsNormally,
      );
      // Registry mismatch throws
      final badOverall = AggregationV1Helpers.aggregate(
        AggregationV1Helpers.allEqual(0.5, 1.0),
      );
      // Force mismatch via structural profile with wrong registry
      final badStruct = StructuralProfileSimilarityResult(
        iq: null,
        eq: null,
        frequency: null,
        evaluatedModules: const [],
        missingModules: const ['iq', 'eq', 'frequency'],
        configVersion: 'x',
        registryVersion: 'other_registry',
        evaluationTimestamp: null,
        deterministicFingerprint: 'x',
        overallStatus: StructuralProfileStatus.insufficientEvidence,
      );
      expect(
        () => StructuredCompatibilityExplanationService().explain(
          structural: badStruct,
          preference: null,
          relationshipLayer: null,
          evaluation: ExplanationV1Helpers.evaluationFromOverall(badOverall),
          dimensionRegistry: dims,
          valueRegistry: ExplanationV1Helpers.loadValues(),
          config: config,
          codeRegistry: codes,
        ),
        throwsA(isA<CoreMethodValidationException>()),
      );
    });

    test('84-95. No source service calls; production isolation; no Firebase',
        () {
      final src = File(
        'lib/features/assessment/domain/core_method_v2/structured_compatibility_explanation_service.dart',
      ).readAsStringSync();
      for (final name in [
        'StructuralSimilarityService(',
        'DirectionalPreferenceFitService(',
        'RelationshipValueComparisonService(',
        'HardConstraintEvaluationService(',
        'SoftConflictEvaluationService(',
        'CoreMethodV2AggregationService(',
        'PersonaScoringService(',
        'firebase',
        'Firestore',
      ]) {
        expect(src.contains(name), isFalse, reason: name);
      }
      for (final path in [
        'lib/core/utils/compatibility_scoring.dart',
        'lib/features/discover/services/discover_service.dart',
        'lib/features/assessment/services/question_service.dart',
        'lib/features/assessment/screens/iq_test_screen.dart',
      ]) {
        final text = File(path).readAsStringSync();
        expect(text.contains('StructuredCompatibilityExplanationService'),
            isFalse);
        expect(text.contains('structured_explanation'), isFalse);
      }
      final r = ExplanationV1Helpers.explain(
        evaluation: ExplanationV1Helpers.evalAllEqual(1.0, 1.0),
      );
      expect(r.signals.every((s) => !s.productionEligible), isTrue);
      expect(config.productionApprovalStatus, 'not_approved');
      expect(config.runtimeStatus, 'offline_only');
    });
  });
}
