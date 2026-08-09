import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'support/core_method_v2_helpers.dart';

void main() {
  late CanonicalDimensionRegistry registry;
  late RelationshipValueRegistry values;
  late CoreMethodV2Config config;

  setUpAll(() {
    registry = loadCanonicalDimensionRegistry();
    values = loadValueRegistry();
    config = loadCoreMethodConfig();
  });

  group('canonical dimension registry', () {
    test('1–3 current registry has 20 unique active dims (4/10/6)', () {
      expect(registry.activeCount, 20);
      expect(registry.dimsForModule(AssessmentModuleId.iq).length, 4);
      expect(registry.dimsForModule(AssessmentModuleId.eq).length, 10);
      expect(registry.dimsForModule(AssessmentModuleId.frequency).length, 6);
      final ids = registry.activeDimensions.map((d) => d.dimensionId).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('4 24-dimension fixture parses without model-code changes', () {
      final fixture = load24dFixture();
      expect(fixture.dimensions.length, 24);
      expect(fixture.activeCount, 20);
      expect(fixture.contains('working_memory_placeholder'), isTrue);
    });

    test('5 no hardcoded dimensionCount = 20 in domain', () {
      final dir = Directory(
        '${cmRepoRoot()}/lib/features/assessment/domain/core_method_v2',
      );
      for (final f in dir.listSync().whereType<File>()) {
        expect(
          RegExp(r'dimensionCount\s*=\s*20').hasMatch(f.readAsStringSync()),
          isFalse,
          reason: f.path,
        );
      }
      // Behavioral count is registry-derived.
      expect(registry.activeCount, registry.activeDimensions.length);
    });
  });

  group('DimensionMeasurement', () {
    test('6 missing score preserved for unpublished', () {
      final m = unpublishedMeasurement(
        dimensionId: 'empathy',
        module: AssessmentModuleId.eq,
      );
      m.validate(registry);
      final j = m.toJson();
      expect(j['normalized_score'], isNull);
      final round = DimensionMeasurement.fromJson(j, registry: registry);
      expect(round.normalizedScore, isNull);
    });

    test('7 unpublished rejects fabricated numeric score', () {
      expect(
        () => unpublishedMeasurement(
          dimensionId: 'empathy',
          module: AssessmentModuleId.eq,
          fabricatedScore: 0.42,
        ).validate(registry),
        throwsA(isA<CoreMethodValidationException>()),
      );
    });

    test('8 published requires valid score', () {
      expect(
        () => DimensionMeasurement(
          dimensionId: 'empathy',
          module: AssessmentModuleId.eq,
          normalizedScore: null,
          confidence: 0.5,
          uncertainty: 0.5,
          primaryEvidenceCount: 1,
          secondaryEvidenceCount: 0,
          independentContextCount: 1,
          publicationStatus: DimensionPublicationStatus.published,
          publishability: true,
          sourceContentVersions: const [],
          measurementTimestamp: null,
          scoringContractVersion: 'v',
          registryVersion: 'v',
        ).validate(registry),
        throwsA(isA<CoreMethodValidationException>()),
      );
    });

    test('9 rejects NaN and infinity', () {
      expect(
        () => publishedMeasurement(
          dimensionId: 'empathy',
          module: AssessmentModuleId.eq,
        ).copyWithConfidence(double.nan).validate(registry),
        throwsA(isA<CoreMethodValidationException>()),
      );
      expect(
        () => publishedMeasurement(
          dimensionId: 'empathy',
          module: AssessmentModuleId.eq,
        ).copyWithConfidence(double.infinity).validate(registry),
        throwsA(isA<CoreMethodValidationException>()),
      );
    });

    test('10 dimension/module mismatch fails', () {
      expect(
        () => publishedMeasurement(
          dimensionId: 'empathy',
          module: AssessmentModuleId.iq,
        ).validate(registry),
        throwsA(isA<CoreMethodValidationException>()),
      );
    });
  });

  group('profiles', () {
    test('11 module profile accepts partial measurements', () {
      final mod = iqPartial(registry);
      mod.validate(registry);
      expect(mod.measurements.length, 1);
      expect(mod.completionStatus, ModuleCompletionStatus.partial);
    });

    test('12 module profile rejects cross-module dimensions', () {
      final bad = ModuleAssessmentProfile(
        module: AssessmentModuleId.iq,
        measurements: {
          'empathy': publishedMeasurement(
            dimensionId: 'empathy',
            module: AssessmentModuleId.eq,
          ),
        },
        assessmentFormId: null,
        contentVersion: null,
        scoringContractVersion: 'v',
        completionStatus: ModuleCompletionStatus.partial,
        completedAt: null,
        moduleConfidence: null,
        evidenceCoverage: null,
        unavailableDimensions: const [],
        validationIssues: const [],
        registryVersion: registry.registryVersion,
      );
      expect(() => bad.validate(registry),
          throwsA(isA<CoreMethodValidationException>()));
    });

    test('13–16 user profile flatten/persona/frequency-type rules', () {
      final iq = iqPartial(registry);
      final published = CanonicalUserAssessmentProfile.flattenPublished(iq: iq);
      final profile = CanonicalUserAssessmentProfile(
        snapshotId: 'snap-1',
        profileSchemaVersion: 'canonical_user_assessment_profile_v1',
        registryVersion: registry.registryVersion,
        iq: iq,
        eq: null,
        frequency: null,
        publishedMeasurements: published,
        unavailableDimensions: const ['empathy'],
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        sourceAssessmentVersions: const ['iq-test'],
        overallAssessmentCoverage: 0.05,
        profileReadinessStatus: ProfileReadinessStatus.provisional,
      );
      profile.validate(registry);
      expect(profile.publishedMeasurements.keys, ['logical_reasoning']);
      final json = profile.toJson();
      expect(json.containsKey('persona_id'), isFalse);
      expect(json.containsKey('personaId'), isFalse);
      expect(json.containsKey('frequency_type'), isFalse);
      expect(json.containsKey('frequencyType'), isFalse);
      expect(jsonEncode(json), isNot(contains('persona')));
    });
  });

  group('partner preferences', () {
    test('16 range validates min ≤ max', () {
      expect(
        () => PartnerDimensionPreference(
          dimensionId: 'empathy',
          preferredMin: 0.8,
          preferredMax: 0.2,
          importance: 0.5,
          flexibility: 0.5,
          preferenceMode: PreferenceMode.range,
          source: 'explicit_user',
          explicitlyProvided: true,
          updatedAt: null,
        ).validate(registry),
        throwsA(isA<CoreMethodValidationException>()),
      );
    });

    test('17–18 missing preference stays unavailable; not inferred from self',
        () {
      final pref = PartnerDimensionPreference(
        dimensionId: 'empathy',
        preferredMin: null,
        preferredMax: null,
        importance: null,
        flexibility: null,
        preferenceMode: PreferenceMode.unavailable,
        source: 'missing',
        explicitlyProvided: false,
        updatedAt: null,
      );
      pref.validate(registry);
      expect(pref.preferenceMode, PreferenceMode.unavailable);
      expect(pref.explicitlyProvided, isFalse);
      expect(pref.source, isNot('inferred_from_self_score'));
      final profile = PartnerPreferenceProfile(
        preferences: {'empathy': pref},
        profileVersion: 'partner_preference_profile_v1',
        registryVersion: registry.registryVersion,
        createdAt: null,
        updatedAt: null,
        completionStatus: PreferenceProfileCompletionStatus.partial,
        explicitlyAnsweredDimensions: const [],
        openDimensions: const [],
        unavailableDimensions: const ['empathy'],
      );
      profile.validate(registry);
    });
  });

  group('values and hard constraints', () {
    test('19–20 values registry parses; sensitive directly-asked-only', () {
      expect(values.fields, isNotEmpty);
      for (final f in values.fields) {
        expect(f.directlyAskedOnly, isTrue, reason: f.fieldId);
        expect(f.inferenceProhibited, isTrue, reason: f.fieldId);
      }
    });

    test('21–23 hard constraints explicit enablement / unsupported / unknown',
        () {
      // P2B-3: disabled constraints are valid objects (evaluate as
      // not_applicable). They must not throw merely for enabled=false.
      expect(
        () => HardConstraint(
          constraintId: 'c1',
          fieldId: 'relationship_intent',
          acceptedValues: const ['long_term'],
          rejectedValues: const [],
          explicitlyEnabled: false,
          source: 'user',
          updatedAt: null,
          registryVersion: values.registryVersion,
        ).validate(values),
        returnsNormally,
      );

      // career_priority supports soft only in registry — check field flags
      final career = values.require('career_priority');
      if (!career.supportsHardConstraint) {
        expect(
          () => HardConstraint(
            constraintId: 'c2',
            fieldId: 'career_priority',
            acceptedValues: career.allowedValues.take(1).toList(),
            rejectedValues: const [],
            explicitlyEnabled: true,
            source: 'user',
            updatedAt: null,
            registryVersion: values.registryVersion,
          ).validate(values),
          throwsA(isA<CoreMethodValidationException>()),
        );
      }

      final unknown = HardConstraintEvaluationResult(
        constraintId: 'c3',
        outcome: HardConstraintOutcome.unknown,
        explanationCode: 'counterpart_value_missing',
      );
      expect(unknown.outcome, HardConstraintOutcome.unknown);
      expect(unknown.toJson()['outcome'], 'unknown');
    });
  });

  group('pair and results', () {
    test('24 pair input preserves A/B direction', () {
      final a = _subject('A', registry, values);
      final b = _subject('B', registry, values);
      final pair = CompatibilityPairInput(
        subjectA: a,
        subjectB: b,
        registryVersion: registry.registryVersion,
        compatibilityConfigVersion: config.configVersion,
        evaluationTimestamp: DateTime.utc(2026, 1, 3),
        evaluationMode: CompatibilityEvaluationMode.offline,
      );
      pair.validate(dimensionRegistry: registry, valueRegistry: values);
      expect(pair.subjectA.subjectId, 'A');
      expect(pair.subjectB.subjectId, 'B');
      final json = pair.toJson();
      expect(json['subject_a']['subject_id'], 'A');
      expect(json['subject_b']['subject_id'], 'B');
    });

    test(
        '25–28 result separates score/confidence; blocked; partial; no persona',
        () {
      final confidence = CompatibilityConfidenceResult(
        evidenceConfidence: 0.4,
        evidenceCoverage: 0.3,
        policyId: 'confidence_adjust_v1_placeholder_disabled',
        status: 'partial',
      );
      final blocked = CompatibilityResult(
        overallRawScore: null,
        confidenceAdjustedScore: null,
        confidence: confidence,
        iq: null,
        eq: null,
        frequency: null,
        values: null,
        preferenceFitAFromB: null,
        preferenceFitBFromA: null,
        mutualPreferenceScore: null,
        hardConstraintOutcome: HardConstraintOutcome.failed,
        hardConstraintResults: const [
          HardConstraintEvaluationResult(
            constraintId: 'c',
            outcome: HardConstraintOutcome.failed,
          ),
        ],
        softConflictSignals: const [],
        strengths: const [],
        frictionAreas: const [],
        insufficientEvidenceDimensions: const ['empathy'],
        missingModules: const ['iq', 'eq', 'frequency'],
        explanationCodes: const ['hard_constraint_failed'],
        configVersion: config.configVersion,
        registryVersion: registry.registryVersion,
        evaluationStatus: CompatibilityEvaluationStatus.blockedByHardConstraint,
      );
      expect(blocked.overallRawScore, isNull);
      expect(blocked.confidence.evidenceConfidence, 0.4);
      expect(blocked.missingModules, containsAll(['iq', 'eq', 'frequency']));
      final j = blocked.toJson();
      expect(j.containsKey('persona_id'), isFalse);
      expect(j['overall_raw_score'], isNull);
      expect(j['confidence']['evidence_confidence'], 0.4);

      expect(
        () => CompatibilityResult(
          overallRawScore: 0.5,
          confidenceAdjustedScore: 0.5,
          confidence: confidence,
          iq: null,
          eq: null,
          frequency: null,
          values: null,
          preferenceFitAFromB: null,
          preferenceFitBFromA: null,
          mutualPreferenceScore: null,
          hardConstraintOutcome: HardConstraintOutcome.failed,
          hardConstraintResults: const [],
          softConflictSignals: const [],
          strengths: const [],
          frictionAreas: const [],
          insufficientEvidenceDimensions: const [],
          missingModules: const [],
          explanationCodes: const [],
          configVersion: 'v',
          registryVersion: 'v',
          evaluationStatus:
              CompatibilityEvaluationStatus.blockedByHardConstraint,
        ),
        throwsA(isA<CoreMethodValidationException>()),
      );
    });
  });

  group('config', () {
    test('29–33 weights/flags', () {
      final sum = config.moduleWeights.values.fold<double>(0, (a, b) => a + b);
      expect((sum - 1.0).abs() <= config.weightSumTolerance, isTrue);
      expect(config.calibrationStatus, 'uncalibrated');
      expect(config.offlineOnly, isTrue);
      expect(config.productionApproved, isFalse);
      expect(config.complementarityStatus, 'disabled_pending_calibration');
      expect(config.timeLayerStatus, 'disabled');
      expect(config.aiScoringStatus, 'prohibited');
    });
  });

  group('serialization', () {
    test('34–35 deterministic round trips; map order irrelevant', () {
      final m = publishedMeasurement(
        dimensionId: 'empathy',
        module: AssessmentModuleId.eq,
      );
      final a = fingerprint(m.toJson());
      final b = fingerprint(
        DimensionMeasurement.fromJson(m.toJson(), registry: registry).toJson(),
      );
      expect(a, b);

      final unordered = <String, dynamic>{
        'uncertainty': 0.3,
        'dimension_id': 'empathy',
        'module': 'eq',
        'normalized_score': 0.6,
        'confidence': 0.7,
        'primary_evidence_count': 2,
        'secondary_evidence_count': 1,
        'independent_context_count': 2,
        'publication_status': 'published',
        'publishability': true,
        'source_content_versions': ['test-v1'],
        'measurement_timestamp': '2026-01-01T00:00:00.000Z',
        'scoring_contract_version': 'trait_scoring_config_v1',
        'registry_version': 'canonical_dimension_registry_v1',
      };
      expect(
        fingerprint(
          DimensionMeasurement.fromJson(unordered, registry: registry).toJson(),
        ),
        a,
      );
    });
  });

  group('freeze + integration guards', () {
    test('36–38 freeze paths, SHA, no scientific validation claim', () {
      final freeze = loadFreezeManifest();
      expect(freeze.scientificallyValidated, isFalse);
      expect(freeze.psychometricallyCalibrated, isFalse);
      expect(freeze.expertApproved, isFalse);
      expect(freeze.productionReady, isFalse);
      final errs = freeze.verifyArtifactHashes(cmRepoRoot());
      expect(errs, isEmpty, reason: errs.map((e) => e.toJson()).toString());
      for (final a in freeze.artifacts) {
        expect(File('${cmRepoRoot()}/${a.path}').existsSync(), isTrue);
        expect(a.runtimeLoaded, isFalse);
        expect(a.productionWired, isFalse);
      }
      final md = File(
        '${cmRepoRoot()}/docs/core_engine/p2a_assessment_engineering_freeze_manifest_v1.md',
      ).readAsStringSync();
      expect(md.toLowerCase(), contains('not** mean'));
      expect(md.toLowerCase(), contains('scientifically validated'));
    });

    test('39–40 no Firebase deps; adapter plan unwired; no production imports',
        () {
      final dir = Directory(
        '${cmRepoRoot()}/lib/features/assessment/domain/core_method_v2',
      );
      for (final f in dir.listSync().whereType<File>()) {
        final text = f.readAsStringSync();
        expect(text.contains('cloud_firestore'), isFalse, reason: f.path);
        expect(text.contains('firebase_'), isFalse, reason: f.path);
        expect(text.contains('package:qmatch/features/discover'), isFalse);
      }
      expect(TraitScoringToDimensionMeasurementAdapterPlan.productionWired,
          isFalse);
      expect(TraitScoringToDimensionMeasurementAdapterPlan.status,
          'planned_not_wired');

      // New contracts are not referenced from production compatibility scorer.
      final prod = File(
        '${cmRepoRoot()}/lib/core/utils/compatibility_scoring.dart',
      ).readAsStringSync();
      expect(prod.contains('core_method_v2'), isFalse);
      expect(prod.contains('CompatibilityPairInput'), isFalse);
    });
  });
}

extension on DimensionMeasurement {
  DimensionMeasurement copyWithConfidence(double c) => DimensionMeasurement(
        dimensionId: dimensionId,
        module: module,
        normalizedScore: normalizedScore,
        confidence: c,
        uncertainty: uncertainty,
        primaryEvidenceCount: primaryEvidenceCount,
        secondaryEvidenceCount: secondaryEvidenceCount,
        independentContextCount: independentContextCount,
        publicationStatus: publicationStatus,
        publishability: publishability,
        sourceContentVersions: sourceContentVersions,
        measurementTimestamp: measurementTimestamp,
        scoringContractVersion: scoringContractVersion,
        registryVersion: registryVersion,
      );
}

CompatibilitySubjectSnapshot _subject(
  String id,
  CanonicalDimensionRegistry registry,
  RelationshipValueRegistry values,
) {
  final iq = iqPartial(registry);
  final published = CanonicalUserAssessmentProfile.flattenPublished(iq: iq);
  return CompatibilitySubjectSnapshot(
    subjectId: id,
    assessmentProfile: CanonicalUserAssessmentProfile(
      snapshotId: 'snap-$id',
      profileSchemaVersion: 'canonical_user_assessment_profile_v1',
      registryVersion: registry.registryVersion,
      iq: iq,
      eq: null,
      frequency: null,
      publishedMeasurements: published,
      unavailableDimensions: const [],
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sourceAssessmentVersions: const ['iq-test'],
      overallAssessmentCoverage: 0.05,
      profileReadinessStatus: ProfileReadinessStatus.provisional,
    ),
    partnerPreferenceProfile: PartnerPreferenceProfile(
      preferences: {
        'empathy': PartnerDimensionPreference(
          dimensionId: 'empathy',
          preferredMin: null,
          preferredMax: null,
          importance: null,
          flexibility: null,
          preferenceMode: PreferenceMode.open,
          source: 'explicit_user',
          explicitlyProvided: true,
          updatedAt: null,
        ),
      },
      profileVersion: 'v1',
      registryVersion: registry.registryVersion,
      createdAt: null,
      updatedAt: null,
      completionStatus: PreferenceProfileCompletionStatus.partial,
      explicitlyAnsweredDimensions: const ['empathy'],
      openDimensions: const ['empathy'],
      unavailableDimensions: const [],
    ),
    relationshipValueProfile: RelationshipValueProfile(
      responses: const {},
      profileVersion: 'v1',
      registryVersion: values.registryVersion,
      createdAt: null,
      updatedAt: null,
    ),
    hardConstraints: const [],
    snapshotVersion: 'v1',
    createdAt: DateTime.utc(2026, 1, 1),
  );
}
