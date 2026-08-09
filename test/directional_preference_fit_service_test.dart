import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'support/core_method_v2_helpers.dart';
import 'support/directional_preference_fit_helpers.dart';
import 'support/structural_similarity_helpers.dart';

void main() {
  late CanonicalDimensionRegistry registry;
  late PartnerPreferenceFitConfig config;
  const service = DirectionalPreferenceFitService();

  setUpAll(() {
    registry = loadCanonicalDimensionRegistry();
    config = loadPreferenceFitConfig();
  });

  String eqDim([int i = 0]) =>
      registry.dimsForModule(AssessmentModuleId.eq)[i].dimensionId;

  CompatibilitySubjectSnapshot ownerWithRange({
    required String id,
    required double L,
    required double U,
    double importance = 0.8,
    double flexibility = 0.5,
    double selfScore = 0.5,
  }) {
    final dim = eqDim();
    return subjectSnapshot(
      id: id,
      registry: registry,
      assessment: singleDimProfile(
        registry: registry,
        dimensionId: dim,
        module: AssessmentModuleId.eq,
        score: selfScore,
      ),
      preferences: prefsProfile(
        registry: registry,
        preferences: {
          dim: rangePref(
            dimensionId: dim,
            min: L,
            max: U,
            importance: importance,
            flexibility: flexibility,
          ),
        },
      ),
    );
  }

  CompatibilitySubjectSnapshot partnerAt({
    required String id,
    required double score,
    double confidence = 0.8,
  }) {
    final dim = eqDim();
    return subjectSnapshot(
      id: id,
      registry: registry,
      assessment: singleDimProfile(
        registry: registry,
        dimensionId: dim,
        module: AssessmentModuleId.eq,
        score: score,
        confidence: confidence,
      ),
      preferences: prefsProfile(registry: registry, preferences: {}),
    );
  }

  group('config & registry', () {
    test('1–5 config, schema, 20/24 registry, no hardcoded 20', () {
      expect(config.status, 'provisional');
      expect(config.calibrationStatus, 'uncalibrated');
      expect(config.runtimeStatus, 'offline_only');
      expect(config.productionApproved, isFalse);
      expect(config.minimumFlexibilityScale, 0.10);
      expect(config.maximumFlexibilityScale, 0.35);
      expect(config.minimumComparablePreferences, 1);
      expect(config.inferredPreferencePolicy, 'prohibited_by_default');
      expect(config.complementarityStatus, 'disabled_pending_calibration');
      expect(config.personaInputStatus, 'prohibited');
      expect(config.aiScoringStatus, 'prohibited');
      expect(
        File(
          '${cmRepoRoot()}/assets/schemas/core_method_v2/directional_preference_fit_config_v1.schema.json',
        ).existsSync(),
        isTrue,
      );
      expect(registry.activeCount, 20);
      final f24 = load24dFixture();
      expect(f24.dimensions.length, 24);
      final cfg24 = PartnerPreferenceFitConfig.fromJson({
        ...config.toJson(),
        'registry_version': f24.registryVersion,
      });
      final dim = f24.dimsForModule(AssessmentModuleId.eq).first.dimensionId;
      final a = subjectSnapshot(
        id: 'A',
        registry: f24,
        assessment: singleDimProfile(
          registry: f24,
          dimensionId: dim,
          module: AssessmentModuleId.eq,
          score: 0.5,
        ),
        preferences: prefsProfile(
          registry: f24,
          preferences: {
            dim: rangePref(dimensionId: dim, min: 0.4, max: 0.6),
          },
        ),
      );
      final b = subjectSnapshot(
        id: 'B',
        registry: f24,
        assessment: singleDimProfile(
          registry: f24,
          dimensionId: dim,
          module: AssessmentModuleId.eq,
          score: 0.5,
        ),
        preferences: prefsProfile(registry: f24, preferences: {}),
      );
      final r = service.evaluateDirectional(
        preferenceOwner: a,
        evaluatedSubject: b,
        registry: f24,
        config: cfg24,
      );
      expect(r.rawFitScore, 1.0);
      for (final f in Directory(
        '${cmRepoRoot()}/lib/features/assessment/domain/core_method_v2',
      ).listSync().whereType<File>()) {
        if (!f.path.contains('directional_preference')) continue;
        expect(
          RegExp(r'dimensionCount\s*=\s*20').hasMatch(f.readAsStringSync()),
          isFalse,
        );
      }
    });
  });

  group('range mode', () {
    test('6–12 inside/boundary/distance/flexibility', () {
      final a = ownerWithRange(id: 'A', L: 0.4, U: 0.6, flexibility: 0.5);
      expect(
        service
            .evaluateDirectional(
              preferenceOwner: a,
              evaluatedSubject: partnerAt(id: 'B', score: 0.5),
              registry: registry,
              config: config,
            )
            .rawFitScore,
        1.0,
      );
      expect(
        service
            .evaluateDirectional(
              preferenceOwner: a,
              evaluatedSubject: partnerAt(id: 'B', score: 0.4),
              registry: registry,
              config: config,
            )
            .rawFitScore,
        1.0,
      );
      expect(
        service
            .evaluateDirectional(
              preferenceOwner: a,
              evaluatedSubject: partnerAt(id: 'B', score: 0.6),
              registry: registry,
              config: config,
            )
            .rawFitScore,
        1.0,
      );
      final near = service.evaluateDirectional(
        preferenceOwner: a,
        evaluatedSubject: partnerAt(id: 'B', score: 0.35),
        registry: registry,
        config: config,
      );
      final far = service.evaluateDirectional(
        preferenceOwner: a,
        evaluatedSubject: partnerAt(id: 'B', score: 0.0),
        registry: registry,
        config: config,
      );
      expect(near.rawFitScore! > far.rawFitScore!, isTrue);
      expect(near.rawFitScore! < 1.0, isTrue);

      final strict = service.evaluateDirectional(
        preferenceOwner:
            ownerWithRange(id: 'A', L: 0.4, U: 0.6, flexibility: 0.0),
        evaluatedSubject: partnerAt(id: 'B', score: 0.2),
        registry: registry,
        config: config,
      );
      final flex = service.evaluateDirectional(
        preferenceOwner:
            ownerWithRange(id: 'A', L: 0.4, U: 0.6, flexibility: 1.0),
        evaluatedSubject: partnerAt(id: 'B', score: 0.2),
        registry: registry,
        config: config,
      );
      expect(flex.rawFitScore! > strict.rawFitScore!, isTrue);
    });
  });

  group('similarity-to-self & confidence', () {
    test('13–20 similarity, mode confidence, importance, single-dim Q', () {
      final dim = eqDim();
      CompatibilitySubjectSnapshot ownerSim({
        required double selfScore,
        required double importance,
        double flexibility = 0.5,
      }) =>
          subjectSnapshot(
            id: 'A',
            registry: registry,
            assessment: singleDimProfile(
              registry: registry,
              dimensionId: dim,
              module: AssessmentModuleId.eq,
              score: selfScore,
              confidence: 0.9,
            ),
            preferences: prefsProfile(
              registry: registry,
              preferences: {
                dim: similarityPref(
                  dimensionId: dim,
                  importance: importance,
                  flexibility: flexibility,
                ),
              },
            ),
          );

      final identical = service.evaluateDirectional(
        preferenceOwner: ownerSim(selfScore: 0.55, importance: 0.8),
        evaluatedSubject: partnerAt(id: 'B', score: 0.55, confidence: 0.9),
        registry: registry,
        config: config,
      );
      expect(identical.rawFitScore, 1.0);
      expect(identical.dimensionFits.single.evidenceConfidence,
          closeTo(math.sqrt(0.9 * 0.9), 1e-12));

      final distant = service.evaluateDirectional(
        preferenceOwner: ownerSim(selfScore: 0.2, importance: 0.8),
        evaluatedSubject: partnerAt(id: 'B', score: 0.9, confidence: 0.9),
        registry: registry,
        config: config,
      );
      expect(distant.rawFitScore! < 1.0, isTrue);

      // Range uses partner confidence only
      final rangeFit = service.evaluateDirectional(
        preferenceOwner: ownerWithRange(id: 'A', L: 0.4, U: 0.6),
        evaluatedSubject: partnerAt(id: 'B', score: 0.5, confidence: 0.25),
        registry: registry,
        config: config,
      );
      expect(rangeFit.dimensionFits.single.evidenceConfidence, 0.25);

      // Single-dim confidence: S same, Q down
      final high = service.evaluateDirectional(
        preferenceOwner: ownerWithRange(id: 'A', L: 0.4, U: 0.6),
        evaluatedSubject: partnerAt(id: 'B', score: 0.1, confidence: 0.9),
        registry: registry,
        config: config,
      );
      final low = service.evaluateDirectional(
        preferenceOwner: ownerWithRange(id: 'A', L: 0.4, U: 0.6),
        evaluatedSubject: partnerAt(id: 'B', score: 0.1, confidence: 0.2),
        registry: registry,
        config: config,
      );
      expect(high.rawFitScore, closeTo(low.rawFitScore!, 1e-12));
      expect(high.evidenceConfidence! > low.evidenceConfidence!, isTrue);
    });
  });

  group('open / unavailable / missing / eligibility', () {
    test('21–31 open/unavailable/inference/missing/unpublished', () {
      final dim = eqDim();
      final openOwner = subjectSnapshot(
        id: 'A',
        registry: registry,
        assessment: singleDimProfile(
          registry: registry,
          dimensionId: dim,
          module: AssessmentModuleId.eq,
          score: 0.5,
        ),
        preferences: prefsProfile(
          registry: registry,
          preferences: {dim: openPref(dim)},
        ),
      );
      final openR = service.evaluateDirectional(
        preferenceOwner: openOwner,
        evaluatedSubject: partnerAt(id: 'B', score: 0.9),
        registry: registry,
        config: config,
      );
      expect(openR.rawFitScore, isNull);
      expect(openR.openPreferenceIds, contains(dim));
      expect(openR.declaredImportanceMass, 0);
      expect(jsonEncode(openR.toJson()).contains('"raw_dimension_fit":1'),
          isFalse);
      expect(jsonEncode(openR.toJson()).contains('"raw_dimension_fit":0.5'),
          isFalse);

      final unavail = service.evaluateDirectional(
        preferenceOwner: subjectSnapshot(
          id: 'A',
          registry: registry,
          assessment: singleDimProfile(
            registry: registry,
            dimensionId: dim,
            module: AssessmentModuleId.eq,
            score: 0.5,
          ),
          preferences: prefsProfile(
            registry: registry,
            preferences: {dim: unavailablePref(dim)},
          ),
        ),
        evaluatedSubject: partnerAt(id: 'B', score: 0.5),
        registry: registry,
        config: config,
      );
      expect(
        unavail.excludedPreferences
            .any((e) => e.reasonCode == 'preference_unavailable'),
        isTrue,
      );

      final inferred = service.evaluateDirectional(
        preferenceOwner: subjectSnapshot(
          id: 'A',
          registry: registry,
          assessment: singleDimProfile(
            registry: registry,
            dimensionId: dim,
            module: AssessmentModuleId.eq,
            score: 0.5,
          ),
          preferences: prefsProfile(
            registry: registry,
            preferences: {
              dim: rangePref(
                dimensionId: dim,
                min: 0.4,
                max: 0.6,
                source: 'inferred_from_self_score',
              ),
            },
          ),
        ),
        evaluatedSubject: partnerAt(id: 'B', score: 0.5),
        registry: registry,
        config: config,
      );
      expect(
        inferred.excludedPreferences
            .any((e) => e.reasonCode == 'inferred_preference_prohibited'),
        isTrue,
      );

      final missingPartner = service.evaluateDirectional(
        preferenceOwner: ownerWithRange(id: 'A', L: 0.4, U: 0.6),
        evaluatedSubject: subjectSnapshot(
          id: 'B',
          registry: registry,
          assessment: buildUserProfile(registry: registry),
          preferences: prefsProfile(registry: registry, preferences: {}),
        ),
        registry: registry,
        config: config,
      );
      expect(
        missingPartner.excludedPreferences
            .any((e) => e.reasonCode == 'missing_partner_measurement'),
        isTrue,
      );

      final simOwnerNoSelf = subjectSnapshot(
        id: 'A',
        registry: registry,
        assessment: buildUserProfile(registry: registry),
        preferences: prefsProfile(
          registry: registry,
          preferences: {dim: similarityPref(dimensionId: dim)},
        ),
      );
      final missSelf = service.evaluateDirectional(
        preferenceOwner: simOwnerNoSelf,
        evaluatedSubject: partnerAt(id: 'B', score: 0.5),
        registry: registry,
        config: config,
      );
      expect(
        missSelf.excludedPreferences
            .any((e) => e.reasonCode == 'missing_self_measurement'),
        isTrue,
      );
    });
  });

  group('invalid inputs & status', () {
    test('32–41 invalid bounds, zero weight, statuses', () {
      expect(
        () => PartnerPreferenceFitConfig.fromJson({
          ...config.toJson(),
          'minimum_flexibility_scale': 0,
        }),
        throwsA(isA<CoreMethodValidationException>()),
      );

      final dim = eqDim();
      final zeroImp = service.evaluateDirectional(
        preferenceOwner: subjectSnapshot(
          id: 'A',
          registry: registry,
          assessment: singleDimProfile(
            registry: registry,
            dimensionId: dim,
            module: AssessmentModuleId.eq,
            score: 0.5,
          ),
          preferences: prefsProfile(
            registry: registry,
            preferences: {
              dim: rangePref(
                dimensionId: dim,
                min: 0.4,
                max: 0.6,
                importance: 0.0,
              ),
            },
          ),
        ),
        evaluatedSubject: partnerAt(id: 'B', score: 0.5),
        registry: registry,
        config: config,
      );
      expect(
        zeroImp.excludedPreferences
            .any((e) => e.reasonCode == 'zero_importance'),
        isTrue,
      );
      expect(zeroImp.rawFitScore, isNull);

      final zeroQ = service.evaluateDirectional(
        preferenceOwner: ownerWithRange(id: 'A', L: 0.4, U: 0.6),
        evaluatedSubject: partnerAt(id: 'B', score: 0.5, confidence: 0.0),
        registry: registry,
        config: config,
      );
      expect(zeroQ.rawFitScore, isNull);
      expect(zeroQ.effectiveWeightSum, 0);

      final ok = service.evaluateDirectional(
        preferenceOwner: ownerWithRange(id: 'A', L: 0.4, U: 0.6),
        evaluatedSubject: partnerAt(id: 'B', score: 0.5),
        registry: registry,
        config: config,
      );
      expect(ok.status, DirectionalPreferenceFitStatus.complete);
      expect(ok.rawFitScore! >= 0 && ok.rawFitScore! <= 1, isTrue);
      expect(
          ok.evidenceConfidence! >= 0 && ok.evidenceConfidence! <= 1, isTrue);
    });
  });

  group('mutual & reversal', () {
    test('42–50 directional difference, mutual, asymmetry, one-way', () {
      final dim = eqDim();
      final a = subjectSnapshot(
        id: 'A',
        registry: registry,
        assessment: singleDimProfile(
          registry: registry,
          dimensionId: dim,
          module: AssessmentModuleId.eq,
          score: 0.5,
        ),
        preferences: prefsProfile(
          registry: registry,
          preferences: {
            dim: rangePref(dimensionId: dim, min: 0.4, max: 0.6),
          },
        ),
      );
      final b = subjectSnapshot(
        id: 'B',
        registry: registry,
        assessment: singleDimProfile(
          registry: registry,
          dimensionId: dim,
          module: AssessmentModuleId.eq,
          score: 0.5,
        ),
        preferences: prefsProfile(
          registry: registry,
          preferences: {
            dim: rangePref(dimensionId: dim, min: 0.8, max: 1.0),
          },
        ),
      );
      // A likes mid; B measured mid → A←B strong. B likes high; A measured mid → B←A weak.
      final mutual = service.evaluateMutual(
        subjectA: a,
        subjectB: b,
        registry: registry,
        config: config,
      );
      expect(mutual.subjectAToBResult.rawFitScore!, greaterThan(0.9));
      expect(mutual.subjectBToAResult.rawFitScore!,
          lessThan(mutual.subjectAToBResult.rawFitScore!));
      expect(
        mutual.mutualRawFitScore,
        closeTo(
          math.sqrt(mutual.subjectAToBResult.rawFitScore! *
              mutual.subjectBToAResult.rawFitScore!),
          1e-12,
        ),
      );
      expect(
        mutual.directionalAsymmetry,
        closeTo(
          (mutual.subjectAToBResult.rawFitScore! -
                  mutual.subjectBToAResult.rawFitScore!)
              .abs(),
          1e-12,
        ),
      );
      expect(
        mutual.mutualEvidenceConfidence,
        closeTo(
          math.sqrt(mutual.subjectAToBResult.evidenceConfidence! *
              mutual.subjectBToAResult.evidenceConfidence!),
          1e-12,
        ),
      );

      final reversed = service.evaluateMutual(
        subjectA: b,
        subjectB: a,
        registry: registry,
        config: config,
      );
      expect(reversed.subjectAToBResult.rawFitScore,
          mutual.subjectBToAResult.rawFitScore);
      expect(reversed.subjectBToAResult.rawFitScore,
          mutual.subjectAToBResult.rawFitScore);
      expect(reversed.mutualRawFitScore, mutual.mutualRawFitScore);
      expect(reversed.directionalAsymmetry, mutual.directionalAsymmetry);
      expect(
          reversed.deterministicFingerprint, mutual.deterministicFingerprint);

      final oneWay = service.evaluateMutual(
        subjectA: a,
        subjectB: subjectSnapshot(
          id: 'B',
          registry: registry,
          assessment: singleDimProfile(
            registry: registry,
            dimensionId: dim,
            module: AssessmentModuleId.eq,
            score: 0.5,
          ),
          preferences: prefsProfile(registry: registry, preferences: {}),
        ),
        registry: registry,
        config: config,
      );
      expect(oneWay.mutualRawFitScore, isNull);
      expect(oneWay.subjectAToBResult.rawFitScore, isNotNull);
    });
  });

  group('separation / determinism / integration', () {
    test('51–71 no structural aggregation; fingerprints; no production imports',
        () {
      final src = File(
        '${cmRepoRoot()}/lib/features/assessment/domain/core_method_v2/directional_preference_fit_service.dart',
      ).readAsStringSync();
      expect(src.contains('StructuralSimilarityService'), isFalse);
      expect(src.contains('cloud_firestore'), isFalse);
      expect(src.contains('PersonaScoringService'), isFalse);
      expect(src.contains('persona_id'), isFalse);

      final a = ownerWithRange(id: 'A', L: 0.3, U: 0.7);
      final b = partnerAt(id: 'B', score: 0.5);
      final r1 = service.evaluateDirectional(
        preferenceOwner: a,
        evaluatedSubject: b,
        registry: registry,
        config: config,
      );
      final r2 = DirectionalPreferenceFitResult.fromJson(r1.toJson());
      expect(fingerprint(r1.toJson()), fingerprint(r2.toJson()));
      expect(r1.deterministicFingerprint, isNotEmpty);

      final sum = r1.dimensionFits.fold<double>(
        0,
        (s, f) => s + f.weightedContribution,
      );
      expect(sum, closeTo(r1.rawFitScore! * r1.effectiveWeightSum, 1e-12));

      final j = r1.toJson();
      expect(j.containsKey('overall_compatibility_score'), isFalse);
      expect(j.containsKey('persona_id'), isFalse);
      expect(j.containsKey('frequency_type'), isFalse);
      expect(j.containsKey('values_score'), isFalse);

      for (final path in [
        'lib/core/utils/compatibility_scoring.dart',
        'lib/features/discover/services/discover_service.dart',
        'lib/features/assessment/services/question_service.dart',
      ]) {
        expect(
          File('${cmRepoRoot()}/$path')
              .readAsStringSync()
              .contains('DirectionalPreferenceFitService'),
          isFalse,
        );
      }
      for (final f in Directory(
        '${cmRepoRoot()}/lib/features/assessment/screens',
      ).listSync().whereType<File>()) {
        expect(
          f.readAsStringSync().contains('DirectionalPreferenceFitService'),
          isFalse,
        );
      }
    });
  });
}
