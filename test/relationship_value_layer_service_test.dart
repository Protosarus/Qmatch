import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'support/core_method_v2_helpers.dart';
import 'support/relationship_value_layer_helpers.dart';

void main() {
  late CanonicalDimensionRegistry dims;
  late RelationshipValueRegistry values;
  late RelationshipValueComparisonConfig config;
  const valueService = RelationshipValueComparisonService();
  const hardService = HardConstraintEvaluationService();
  const softService = SoftConflictEvaluationService();

  setUpAll(() {
    dims = loadCanonicalDimensionRegistry();
    values = loadValueRegistry();
    config = loadValueComparisonConfig();
    config.validateAgainstRegistry(values);
  });

  test('1–7 config/schema/matrix validation', () {
    expect(config.status, 'provisional');
    expect(config.calibrationStatus, 'uncalibrated');
    expect(config.runtimeStatus, 'offline_only');
    expect(config.productionApproved, isFalse);
    expect(config.mutualAggregationMode, 'geometric_mean');
    expect(
      File(
        '${cmRepoRoot()}/assets/schemas/core_method_v2/relationship_value_comparison_config_v1.schema.json',
      ).existsSync(),
      isTrue,
    );
    for (final id in config.fieldRules.keys) {
      expect(values.fieldsById.containsKey(id), isTrue);
    }
    expect(
      () => RelationshipValueComparisonConfig.fromJson({
        ...config.toJson(),
        'field_rules': {
          ...config.toJson()['field_rules'] as Map,
          'monogamy_expectation': {
            'comparison_mode': 'categorical_compatibility_matrix',
            'directionality': 'symmetric',
            'provisional': true,
            'pending_expert_content_review': true,
            'production_approved': false,
            'matrix': {
              'directionality': 'symmetric',
              'cells': {
                'monogamous': {'monogamous': 1.0},
              },
            },
          },
        },
      }).validateAgainstRegistry(values),
      throwsA(isA<CoreMethodValidationException>()),
    );
  });

  test('8–15 exact/ordered/set modes', () {
    CompatibilitySubjectSnapshot pair(String a, {double flex = 0.0}) =>
        subjectWithValues(
          id: 'A',
          dimRegistry: dims,
          valueRegistry: values,
          responses: {
            'monogamy_expectation': valueResponse(
              fieldId: 'monogamy_expectation',
              registry: values,
              selectedValue: a,
              flexibility: flex,
            ),
          },
        );
    CompatibilitySubjectSnapshot bAt(String v) => subjectWithValues(
          id: 'B',
          dimRegistry: dims,
          valueRegistry: values,
          responses: {
            'monogamy_expectation': valueResponse(
              fieldId: 'monogamy_expectation',
              registry: values,
              selectedValue: v,
            ),
          },
        );
    expect(
      valueService
          .evaluateDirectional(
            preferenceOwner: pair('monogamous'),
            evaluatedSubject: bAt('monogamous'),
            registry: values,
            config: config,
          )
          .rawValueFitScore,
      1.0,
    );
    expect(
      valueService
          .evaluateDirectional(
            preferenceOwner: pair('monogamous'),
            evaluatedSubject: bAt('open_to_non_monogamy'),
            registry: values,
            config: config,
          )
          .rawValueFitScore,
      0.0,
    );

    final oSame = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'alcohol_preference': valueResponse(
            fieldId: 'alcohol_preference',
            registry: values,
            selectedValue: 'social',
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'alcohol_preference': valueResponse(
            fieldId: 'alcohol_preference',
            registry: values,
            selectedValue: 'social',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(oSame.rawValueFitScore, 1.0);
    final oAdj = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'alcohol_preference': valueResponse(
            fieldId: 'alcohol_preference',
            registry: values,
            selectedValue: 'none',
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'alcohol_preference': valueResponse(
            fieldId: 'alcohol_preference',
            registry: values,
            selectedValue: 'social',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    final oFar = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'alcohol_preference': valueResponse(
            fieldId: 'alcohol_preference',
            registry: values,
            selectedValue: 'none',
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'alcohol_preference': valueResponse(
            fieldId: 'alcohol_preference',
            registry: values,
            selectedValue: 'undecided',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(oAdj.rawValueFitScore! > oFar.rawValueFitScore!, isTrue);

    final setId = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'lifestyle_rhythm': valueResponse(
            fieldId: 'lifestyle_rhythm',
            registry: values,
            selectedValues: const ['mixed', 'flexible'],
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'lifestyle_rhythm': valueResponse(
            fieldId: 'lifestyle_rhythm',
            registry: values,
            selectedValues: const ['mixed', 'flexible'],
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(setId.rawValueFitScore, 1.0);
    final setPart = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'lifestyle_rhythm': valueResponse(
            fieldId: 'lifestyle_rhythm',
            registry: values,
            selectedValues: const ['mixed', 'flexible'],
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'lifestyle_rhythm': valueResponse(
            fieldId: 'lifestyle_rhythm',
            registry: values,
            selectedValues: const ['mixed', 'highly_structured'],
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(
        setPart.rawValueFitScore! > 0 && setPart.rawValueFitScore! < 1, isTrue);
    final setDis = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'lifestyle_rhythm': valueResponse(
            fieldId: 'lifestyle_rhythm',
            registry: values,
            selectedValues: const ['flexible'],
            flexibility: 0.0,
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'lifestyle_rhythm': valueResponse(
            fieldId: 'lifestyle_rhythm',
            registry: values,
            selectedValues: const ['highly_structured'],
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(setDis.rawValueFitScore, 0.0);
    final emptySet = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'lifestyle_rhythm': valueResponse(
            fieldId: 'lifestyle_rhythm',
            registry: values,
            selectedValues: const [],
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'lifestyle_rhythm': valueResponse(
            fieldId: 'lifestyle_rhythm',
            registry: values,
            selectedValues: const ['mixed'],
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(
      emptySet.excludedFields
          .any((e) => e.reasonCode == 'value_invalid_subject_a'),
      isTrue,
    );
  });

  test('16–25 flexibility/importance/mutual/reversal', () {
    DirectionalRelationshipValueResult dir({
      required double flex,
      required double imp,
      required String owner,
      required String other,
    }) =>
        valueService.evaluateDirectional(
          preferenceOwner: subjectWithValues(
            id: 'A',
            dimRegistry: dims,
            valueRegistry: values,
            responses: {
              'monogamy_expectation': valueResponse(
                fieldId: 'monogamy_expectation',
                registry: values,
                selectedValue: owner,
                importance: imp,
                flexibility: flex,
              ),
            },
          ),
          evaluatedSubject: subjectWithValues(
            id: 'B',
            dimRegistry: dims,
            valueRegistry: values,
            responses: {
              'monogamy_expectation': valueResponse(
                fieldId: 'monogamy_expectation',
                registry: values,
                selectedValue: other,
              ),
            },
          ),
          registry: values,
          config: config,
        );

    expect(
        dir(flex: 0, imp: 0.8, owner: 'monogamous', other: 'undecided')
            .rawValueFitScore,
        0.0);
    expect(
        dir(flex: 1, imp: 0.8, owner: 'monogamous', other: 'undecided')
            .rawValueFitScore,
        1.0);
    expect(
      dir(flex: 0.8, imp: 0.8, owner: 'monogamous', other: 'undecided')
              .rawValueFitScore! >
          dir(flex: 0.2, imp: 0.8, owner: 'monogamous', other: 'undecided')
              .rawValueFitScore!,
      isTrue,
    );

    final a = subjectWithValues(
      id: 'A',
      dimRegistry: dims,
      valueRegistry: values,
      responses: {
        'marriage_intent': valueResponse(
          fieldId: 'marriage_intent',
          registry: values,
          selectedValue: 'yes',
          importance: 0.9,
          flexibility: 0.0,
        ),
      },
    );
    final b = subjectWithValues(
      id: 'B',
      dimRegistry: dims,
      valueRegistry: values,
      responses: {
        'marriage_intent': valueResponse(
          fieldId: 'marriage_intent',
          registry: values,
          selectedValue: 'maybe',
          importance: 0.9,
          flexibility: 0.0,
        ),
      },
    );
    final mutual = valueService.evaluateMutual(
      subjectA: a,
      subjectB: b,
      registry: values,
      config: config,
    );
    expect(mutual.subjectAToBResult.rawValueFitScore,
        isNot(mutual.subjectBToAResult.rawValueFitScore));
    expect(
      mutual.mutualRawValueFitScore,
      closeTo(
        math.sqrt(mutual.subjectAToBResult.rawValueFitScore! *
            mutual.subjectBToAResult.rawValueFitScore!),
        1e-12,
      ),
    );
    final rev = valueService.evaluateMutual(
      subjectA: b,
      subjectB: a,
      registry: values,
      config: config,
    );
    expect(rev.subjectAToBResult.rawValueFitScore,
        mutual.subjectBToAResult.rawValueFitScore);
    expect(rev.mutualRawValueFitScore, mutual.mutualRawValueFitScore);
    expect(rev.directionalAsymmetry, mutual.directionalAsymmetry);
    expect(
      mutual.directionalAsymmetry,
      closeTo(
        (mutual.subjectAToBResult.rawValueFitScore! -
                mutual.subjectBToAResult.rawValueFitScore!)
            .abs(),
        1e-12,
      ),
    );
  });

  test('26–40 missing/private/permission/pending/invalids/bounds', () {
    final missing = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'monogamy_expectation': valueResponse(
            fieldId: 'monogamy_expectation',
            registry: values,
            selectedValue: 'monogamous',
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {},
      ),
      registry: values,
      config: config,
    );
    expect(missing.rawValueFitScore, isNull);
    expect(jsonHasForbiddenImputation(missing.toJson()), isFalse);
    expect(
      missing.excludedFields
          .any((e) => e.reasonCode == 'value_missing_subject_b'),
      isTrue,
    );

    final private = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'monogamy_expectation': valueResponse(
            fieldId: 'monogamy_expectation',
            registry: values,
            selectedValue: 'monogamous',
            visibilityPolicy: 'private',
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'monogamy_expectation': valueResponse(
            fieldId: 'monogamy_expectation',
            registry: values,
            selectedValue: 'monogamous',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(
      private.excludedFields
          .any((e) => e.reasonCode == 'visibility_policy_blocked'),
      isTrue,
    );

    final denied = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'monogamy_expectation': valueResponse(
            fieldId: 'monogamy_expectation',
            registry: values,
            selectedValue: 'monogamous',
            comparisonPermission: false,
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'monogamy_expectation': valueResponse(
            fieldId: 'monogamy_expectation',
            registry: values,
            selectedValue: 'monogamous',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(
      denied.excludedFields
          .any((e) => e.reasonCode == 'comparison_permission_denied'),
      isTrue,
    );

    final pending = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'preferred_living_location': valueResponse(
            fieldId: 'preferred_living_location',
            registry: values,
            selectedValue: 'same_city',
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'preferred_living_location': valueResponse(
            fieldId: 'preferred_living_location',
            registry: values,
            selectedValue: 'same_city',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(
      pending.excludedFields
          .any((e) => e.reasonCode == 'comparison_pending_review'),
      isTrue,
    );

    final zeroImp = valueService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'monogamy_expectation': valueResponse(
            fieldId: 'monogamy_expectation',
            registry: values,
            selectedValue: 'monogamous',
            importance: 0,
          ),
        },
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'monogamy_expectation': valueResponse(
            fieldId: 'monogamy_expectation',
            registry: values,
            selectedValue: 'monogamous',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(
      zeroImp.excludedFields.any((e) => e.reasonCode == 'zero_importance'),
      isTrue,
    );
  });

  test('41–55 hard constraints categorical outcomes', () {
    final disabled = hardService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {},
        constraints: [
          hardConstraint(
            id: 'c0',
            fieldId: 'smoking_preference',
            registry: values,
            accepted: const ['non_smoker_only'],
            enabled: false,
          ),
        ],
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'smoking_preference': valueResponse(
            fieldId: 'smoking_preference',
            registry: values,
            selectedValue: 'smokes',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(disabled.aggregateOutcome, HardConstraintOutcome.notApplicable);

    final passed = hardService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {},
        constraints: [
          hardConstraint(
            id: 'c1',
            fieldId: 'smoking_preference',
            registry: values,
            accepted: const ['non_smoker_only', 'ok_with_smoking'],
          ),
        ],
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'smoking_preference': valueResponse(
            fieldId: 'smoking_preference',
            registry: values,
            selectedValue: 'non_smoker_only',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(passed.aggregateOutcome, HardConstraintOutcome.passed);

    final failedReject = hardService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {},
        constraints: [
          hardConstraint(
            id: 'c2',
            fieldId: 'smoking_preference',
            registry: values,
            rejected: const ['smokes'],
          ),
        ],
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'smoking_preference': valueResponse(
            fieldId: 'smoking_preference',
            registry: values,
            selectedValue: 'smokes',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(failedReject.aggregateOutcome, HardConstraintOutcome.failed);

    final failedAccept = hardService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {},
        constraints: [
          hardConstraint(
            id: 'c3',
            fieldId: 'children_preference',
            registry: values,
            accepted: const ['want_children'],
          ),
        ],
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'children_preference': valueResponse(
            fieldId: 'children_preference',
            registry: values,
            selectedValue: 'do_not_want',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    expect(failedAccept.aggregateOutcome, HardConstraintOutcome.failed);

    final unknown = hardService.evaluateDirectional(
      preferenceOwner: subjectWithValues(
        id: 'A',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {},
        constraints: [
          hardConstraint(
            id: 'c4',
            fieldId: 'smoking_preference',
            registry: values,
            accepted: const ['non_smoker_only'],
          ),
        ],
      ),
      evaluatedSubject: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {},
      ),
      registry: values,
      config: config,
    );
    expect(unknown.aggregateOutcome, HardConstraintOutcome.unknown);
    expect(unknown.aggregateOutcome, isNot(HardConstraintOutcome.passed));
    expect(unknown.aggregateOutcome, isNot(HardConstraintOutcome.failed));
    expect(jsonEncode(unknown.toJson()).contains('hard_score'), isFalse);
  });

  test('56–70 soft severity + separation + no final score', () {
    final a = subjectWithValues(
      id: 'A',
      dimRegistry: dims,
      valueRegistry: values,
      responses: {
        'monogamy_expectation': valueResponse(
          fieldId: 'monogamy_expectation',
          registry: values,
          selectedValue: 'monogamous',
          importance: 0.9,
          flexibility: 0.1,
        ),
      },
    );
    final b = subjectWithValues(
      id: 'B',
      dimRegistry: dims,
      valueRegistry: values,
      responses: {
        'monogamy_expectation': valueResponse(
          fieldId: 'monogamy_expectation',
          registry: values,
          selectedValue: 'open_to_non_monogamy',
          importance: 0.9,
          flexibility: 0.1,
        ),
      },
    );
    final mutual = valueService.evaluateMutual(
      subjectA: a,
      subjectB: b,
      registry: values,
      config: config,
    );
    final soft = softService.evaluate(mutualValues: mutual, config: config);
    expect(soft.subjectAToBSignals.single.severity, greaterThan(0.6));
    expect(soft.mutualSignals.single.mutualSeverity,
        soft.subjectAToBSignals.single.severity);

    final aligned = valueService.evaluateMutual(
      subjectA: a,
      subjectB: subjectWithValues(
        id: 'B',
        dimRegistry: dims,
        valueRegistry: values,
        responses: {
          'monogamy_expectation': valueResponse(
            fieldId: 'monogamy_expectation',
            registry: values,
            selectedValue: 'monogamous',
          ),
        },
      ),
      registry: values,
      config: config,
    );
    final soft0 = softService.evaluate(mutualValues: aligned, config: config);
    expect(soft0.subjectAToBSignals.single.severity, 0);

    final layer = RelationshipCompatibilityLayerResult.assemble(
      mutualValueResult: mutual,
      mutualHardConstraintResult: hardService.evaluateMutual(
        subjectA: a,
        subjectB: b,
        registry: values,
        config: config,
      ),
      softConflictResult: soft,
    );
    expect(layer.toJson().containsKey('overall_compatibility_score'), isFalse);
    expect(layer.toJson().containsKey('persona_id'), isFalse);
    expect(layer.toJson().containsKey('frequency_type'), isFalse);

    final srcVal = File(
      '${cmRepoRoot()}/lib/features/assessment/domain/core_method_v2/relationship_value_comparison_service.dart',
    ).readAsStringSync();
    expect(srcVal.contains('structural_similarity_service.dart'), isFalse);
    expect(srcVal.contains('directional_preference_fit_service.dart'), isFalse);
    expect(srcVal.contains('cloud_firestore'), isFalse);
  });

  test('71–81 determinism / map order / no production imports', () {
    final a = subjectWithValues(
      id: 'A',
      dimRegistry: dims,
      valueRegistry: values,
      responses: {
        'alcohol_preference': valueResponse(
          fieldId: 'alcohol_preference',
          registry: values,
          selectedValue: 'social',
          importance: 0.7,
        ),
        'career_priority': valueResponse(
          fieldId: 'career_priority',
          registry: values,
          selectedValue: 'balanced',
          importance: 0.4,
        ),
      },
    );
    final b = subjectWithValues(
      id: 'B',
      dimRegistry: dims,
      valueRegistry: values,
      responses: {
        'career_priority': valueResponse(
          fieldId: 'career_priority',
          registry: values,
          selectedValue: 'very_high',
        ),
        'alcohol_preference': valueResponse(
          fieldId: 'alcohol_preference',
          registry: values,
          selectedValue: 'regular',
        ),
      },
    );
    final r1 = valueService.evaluateDirectional(
      preferenceOwner: a,
      evaluatedSubject: b,
      registry: values,
      config: config,
    );
    final r2 = DirectionalRelationshipValueResult.fromJson(r1.toJson());
    expect(r1.deterministicFingerprint, r2.deterministicFingerprint);
    expect(r1.rawValueFitScore, r2.rawValueFitScore);

    for (final path in [
      'lib/core/utils/compatibility_scoring.dart',
      'lib/features/discover/services/discover_service.dart',
      'lib/features/assessment/services/question_service.dart',
    ]) {
      final text = File('${cmRepoRoot()}/$path').readAsStringSync();
      expect(text.contains('RelationshipValueComparisonService'), isFalse);
      expect(text.contains('HardConstraintEvaluationService'), isFalse);
      expect(text.contains('SoftConflictEvaluationService'), isFalse);
    }
    expect(dims.activeCount, 20);
    final f24 = load24dFixture();
    expect(f24.dimensions.length, 24);
  });
}

bool jsonHasForbiddenImputation(Map<String, dynamic> j) {
  final s = jsonEncode(j);
  return s.contains('"raw_value_fit_score":0') ||
      s.contains('"raw_value_fit_score":0.5') ||
      s.contains('"raw_value_fit_score":0.42');
}
