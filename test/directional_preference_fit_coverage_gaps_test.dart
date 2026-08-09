import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'support/core_method_v2_helpers.dart';
import 'support/directional_preference_fit_helpers.dart';
import 'support/structural_similarity_helpers.dart';

/// Supplemental assertions for P2B-2.1 coverage gaps that were only named
/// (or bundled) in the original service tests without unique expects.
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

  test('17 importance changes cross-dimension influence', () {
    final d0 = eqDim(0);
    final d1 = eqDim(1);
    CompatibilitySubjectSnapshot owner(double i0) => subjectSnapshot(
          id: 'A',
          registry: registry,
          assessment: buildUserProfile(
            registry: registry,
            eq: buildModuleProfile(
              module: AssessmentModuleId.eq,
              registry: registry,
              measurements: {
                d0: ssPublished(
                    dimensionId: d0, module: AssessmentModuleId.eq, score: 0.5),
                d1: ssPublished(
                    dimensionId: d1, module: AssessmentModuleId.eq, score: 0.5),
              },
            ),
          ),
          preferences: prefsProfile(
            registry: registry,
            preferences: {
              d0: rangePref(
                  dimensionId: d0, min: 0.4, max: 0.6, importance: i0),
              d1: rangePref(
                  dimensionId: d1, min: 0.4, max: 0.6, importance: 0.5),
            },
          ),
        );
    final partner = subjectSnapshot(
      id: 'B',
      registry: registry,
      assessment: buildUserProfile(
        registry: registry,
        eq: buildModuleProfile(
          module: AssessmentModuleId.eq,
          registry: registry,
          measurements: {
            d0: ssPublished(
                dimensionId: d0, module: AssessmentModuleId.eq, score: 0.0),
            d1: ssPublished(
                dimensionId: d1, module: AssessmentModuleId.eq, score: 0.5),
          },
        ),
      ),
      preferences: prefsProfile(registry: registry, preferences: {}),
    );
    final high = service.evaluateDirectional(
      preferenceOwner: owner(0.95),
      evaluatedSubject: partner,
      registry: registry,
      config: config,
    );
    final low = service.evaluateDirectional(
      preferenceOwner: owner(0.1),
      evaluatedSubject: partner,
      registry: registry,
      config: config,
    );
    expect(high.rawFitScore! < low.rawFitScore!, isTrue);
  });

  test('18 confidence changes cross-dimension influence', () {
    final d0 = eqDim(0);
    final d1 = eqDim(1);
    final owner = subjectSnapshot(
      id: 'A',
      registry: registry,
      assessment: buildUserProfile(
        registry: registry,
        eq: buildModuleProfile(
          module: AssessmentModuleId.eq,
          registry: registry,
          measurements: {
            d0: ssPublished(
                dimensionId: d0, module: AssessmentModuleId.eq, score: 0.5),
            d1: ssPublished(
                dimensionId: d1, module: AssessmentModuleId.eq, score: 0.5),
          },
        ),
      ),
      preferences: prefsProfile(
        registry: registry,
        preferences: {
          d0: rangePref(dimensionId: d0, min: 0.4, max: 0.6, importance: 0.9),
          d1: rangePref(dimensionId: d1, min: 0.4, max: 0.6, importance: 0.5),
        },
      ),
    );
    CompatibilitySubjectSnapshot partner(double c0) => subjectSnapshot(
          id: 'B',
          registry: registry,
          assessment: buildUserProfile(
            registry: registry,
            eq: buildModuleProfile(
              module: AssessmentModuleId.eq,
              registry: registry,
              measurements: {
                d0: ssPublished(
                  dimensionId: d0,
                  module: AssessmentModuleId.eq,
                  score: 0.0,
                  confidence: c0,
                ),
                d1: ssPublished(
                  dimensionId: d1,
                  module: AssessmentModuleId.eq,
                  score: 0.5,
                  confidence: 0.9,
                ),
              },
            ),
          ),
          preferences: prefsProfile(registry: registry, preferences: {}),
        );
    final high = service.evaluateDirectional(
      preferenceOwner: owner,
      evaluatedSubject: partner(0.95),
      registry: registry,
      config: config,
    );
    final low = service.evaluateDirectional(
      preferenceOwner: owner,
      evaluatedSubject: partner(0.1),
      registry: registry,
      config: config,
    );
    expect(high.rawFitScore! < low.rawFitScore!, isTrue);
  });

  test('27 non-explicit preference is excluded', () {
    final dim = eqDim();
    final r = service.evaluateDirectional(
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
              explicitlyProvided: false,
            ),
          },
        ),
      ),
      evaluatedSubject: subjectSnapshot(
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
    expect(
      r.excludedPreferences
          .any((e) => e.reasonCode == 'preference_not_explicit'),
      isTrue,
    );
  });

  test('30 unpublished partner measurement is excluded', () {
    final dim = eqDim();
    final r = service.evaluateDirectional(
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
            dim: rangePref(dimensionId: dim, min: 0.4, max: 0.6),
          },
        ),
      ),
      evaluatedSubject: subjectSnapshot(
        id: 'B',
        registry: registry,
        assessment: buildUserProfile(
          registry: registry,
          eq: buildModuleProfile(
            module: AssessmentModuleId.eq,
            registry: registry,
            measurements: {
              dim: ssPublished(
                dimensionId: dim,
                module: AssessmentModuleId.eq,
                score: 0.5,
                publicationStatus:
                    DimensionPublicationStatus.insufficientEvidence,
              ),
            },
          ),
        ),
        preferences: prefsProfile(registry: registry, preferences: {}),
      ),
      registry: registry,
      config: config,
    );
    expect(
      r.excludedPreferences
          .any((e) => e.reasonCode == 'unpublished_partner_measurement'),
      isTrue,
    );
  });

  test('31 non-publishable partner measurement is excluded', () {
    final dim = eqDim();
    final r = service.evaluateDirectional(
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
            dim: rangePref(dimensionId: dim, min: 0.4, max: 0.6),
          },
        ),
      ),
      evaluatedSubject: subjectSnapshot(
        id: 'B',
        registry: registry,
        assessment: buildUserProfile(
          registry: registry,
          eq: buildModuleProfile(
            module: AssessmentModuleId.eq,
            registry: registry,
            measurements: {
              dim: DimensionMeasurement(
                dimensionId: dim,
                module: AssessmentModuleId.eq,
                normalizedScore: 0.5,
                confidence: 0.8,
                uncertainty: 0.2,
                primaryEvidenceCount: 1,
                secondaryEvidenceCount: 0,
                independentContextCount: 1,
                publicationStatus: DimensionPublicationStatus.published,
                publishability: false,
                sourceContentVersions: const [],
                measurementTimestamp: null,
                scoringContractVersion: 'trait_scoring_config_v1',
                registryVersion: registry.registryVersion,
              ),
            },
          ),
        ),
        preferences: prefsProfile(registry: registry, preferences: {}),
      ),
      registry: registry,
      config: config,
    );
    expect(
      r.excludedPreferences
          .any((e) => e.reasonCode == 'non_publishable_partner_measurement'),
      isTrue,
    );
  });

  test('32–37 invalid importance/flexibility/score/confidence/NaN/infinity',
      () {
    final dim = eqDim();

    final badImp = service.evaluateDirectional(
      preferenceOwner: subjectSnapshot(
        id: 'A',
        registry: registry,
        assessment: singleDimProfile(
          registry: registry,
          dimensionId: dim,
          module: AssessmentModuleId.eq,
          score: 0.5,
        ),
        preferences: PartnerPreferenceProfile(
          preferences: {
            dim: PartnerDimensionPreference(
              dimensionId: dim,
              preferredMin: 0.4,
              preferredMax: 0.6,
              importance: 1.5,
              flexibility: 0.5,
              preferenceMode: PreferenceMode.range,
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
          explicitlyAnsweredDimensions: [dim],
          openDimensions: const [],
          unavailableDimensions: const [],
        ),
      ),
      evaluatedSubject: subjectSnapshot(
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
    expect(
      badImp.excludedPreferences
          .any((e) => e.reasonCode == 'invalid_importance'),
      isTrue,
    );

    final flex = service.evaluateDirectional(
      preferenceOwner: CompatibilitySubjectSnapshot(
        subjectId: 'A',
        assessmentProfile: singleDimProfile(
          registry: registry,
          dimensionId: dim,
          module: AssessmentModuleId.eq,
          score: 0.5,
        ),
        partnerPreferenceProfile: PartnerPreferenceProfile(
          preferences: {
            dim: PartnerDimensionPreference(
              dimensionId: dim,
              preferredMin: 0.4,
              preferredMax: 0.6,
              importance: 0.8,
              flexibility: -0.2,
              preferenceMode: PreferenceMode.range,
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
          explicitlyAnsweredDimensions: [dim],
          openDimensions: const [],
          unavailableDimensions: const [],
        ),
        relationshipValueProfile: RelationshipValueProfile(
          responses: const {},
          profileVersion: 'v1',
          registryVersion: 'relationship_value_registry_v1',
          createdAt: null,
          updatedAt: null,
        ),
        hardConstraints: const [],
        snapshotVersion: 'v1',
        createdAt: null,
      ),
      evaluatedSubject: subjectSnapshot(
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
    expect(
      flex.excludedPreferences
          .any((e) => e.reasonCode == 'invalid_flexibility'),
      isTrue,
    );

    final badScore = service.evaluateDirectional(
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
            dim: rangePref(dimensionId: dim, min: 0.4, max: 0.6),
          },
        ),
      ),
      evaluatedSubject: subjectSnapshot(
        id: 'B',
        registry: registry,
        assessment: buildUserProfile(
          registry: registry,
          eq: buildModuleProfile(
            module: AssessmentModuleId.eq,
            registry: registry,
            measurements: {
              dim: DimensionMeasurement(
                dimensionId: dim,
                module: AssessmentModuleId.eq,
                normalizedScore: 1.5,
                confidence: 0.8,
                uncertainty: 0.2,
                primaryEvidenceCount: 1,
                secondaryEvidenceCount: 0,
                independentContextCount: 1,
                publicationStatus: DimensionPublicationStatus.published,
                publishability: true,
                sourceContentVersions: const [],
                measurementTimestamp: null,
                scoringContractVersion: 'trait_scoring_config_v1',
                registryVersion: registry.registryVersion,
              ),
            },
          ),
        ),
        preferences: prefsProfile(registry: registry, preferences: {}),
      ),
      registry: registry,
      config: config,
    );
    expect(
      badScore.excludedPreferences
          .any((e) => e.reasonCode == 'invalid_partner_score'),
      isTrue,
    );

    final nan = service.evaluateDirectional(
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
            dim: rangePref(dimensionId: dim, min: 0.4, max: 0.6),
          },
        ),
      ),
      evaluatedSubject: subjectSnapshot(
        id: 'B',
        registry: registry,
        assessment: buildUserProfile(
          registry: registry,
          eq: buildModuleProfile(
            module: AssessmentModuleId.eq,
            registry: registry,
            measurements: {
              dim: DimensionMeasurement(
                dimensionId: dim,
                module: AssessmentModuleId.eq,
                normalizedScore: double.nan,
                confidence: 0.8,
                uncertainty: 0.2,
                primaryEvidenceCount: 1,
                secondaryEvidenceCount: 0,
                independentContextCount: 1,
                publicationStatus: DimensionPublicationStatus.published,
                publishability: true,
                sourceContentVersions: const [],
                measurementTimestamp: null,
                scoringContractVersion: 'trait_scoring_config_v1',
                registryVersion: registry.registryVersion,
              ),
            },
          ),
        ),
        preferences: prefsProfile(registry: registry, preferences: {}),
      ),
      registry: registry,
      config: config,
    );
    expect(
      nan.excludedPreferences
          .any((e) => e.reasonCode == 'invalid_partner_score'),
      isTrue,
    );

    final inf = service.evaluateDirectional(
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
            dim: rangePref(dimensionId: dim, min: 0.4, max: 0.6),
          },
        ),
      ),
      evaluatedSubject: subjectSnapshot(
        id: 'B',
        registry: registry,
        assessment: buildUserProfile(
          registry: registry,
          eq: buildModuleProfile(
            module: AssessmentModuleId.eq,
            registry: registry,
            measurements: {
              dim: DimensionMeasurement(
                dimensionId: dim,
                module: AssessmentModuleId.eq,
                normalizedScore: 0.5,
                confidence: double.infinity,
                uncertainty: 0.2,
                primaryEvidenceCount: 1,
                secondaryEvidenceCount: 0,
                independentContextCount: 1,
                publicationStatus: DimensionPublicationStatus.published,
                publishability: true,
                sourceContentVersions: const [],
                measurementTimestamp: null,
                scoringContractVersion: 'trait_scoring_config_v1',
                registryVersion: registry.registryVersion,
              ),
            },
          ),
        ),
        preferences: prefsProfile(registry: registry, preferences: {}),
      ),
      registry: registry,
      config: config,
    );
    expect(
      inf.excludedPreferences
          .any((e) => e.reasonCode == 'invalid_partner_confidence'),
      isTrue,
    );
  });

  test('40 partial comparison reports exclusions', () {
    final d0 = eqDim(0);
    final d1 = eqDim(1);
    final r = service.evaluateDirectional(
      preferenceOwner: subjectSnapshot(
        id: 'A',
        registry: registry,
        assessment: singleDimProfile(
          registry: registry,
          dimensionId: d0,
          module: AssessmentModuleId.eq,
          score: 0.5,
        ),
        preferences: prefsProfile(
          registry: registry,
          preferences: {
            d0: rangePref(dimensionId: d0, min: 0.4, max: 0.6),
            d1: rangePref(dimensionId: d1, min: 0.4, max: 0.6),
          },
        ),
      ),
      evaluatedSubject: subjectSnapshot(
        id: 'B',
        registry: registry,
        assessment: singleDimProfile(
          registry: registry,
          dimensionId: d0,
          module: AssessmentModuleId.eq,
          score: 0.5,
        ),
        preferences: prefsProfile(registry: registry, preferences: {}),
      ),
      registry: registry,
      config: config,
    );
    expect(r.status, DirectionalPreferenceFitStatus.partial);
    expect(r.rawFitScore, isNotNull);
    expect(r.excludedPreferences, isNotEmpty);
    expect(
      r.excludedPreferences
          .any((e) => e.reasonCode == 'missing_partner_measurement'),
      isTrue,
    );
  });

  test('51–52 structural service not called; structural scores untouched', () {
    final src = File(
      '${cmRepoRoot()}/lib/features/assessment/domain/core_method_v2/directional_preference_fit_service.dart',
    ).readAsStringSync();
    expect(src.contains('StructuralSimilarityService'), isFalse);
    expect(src.contains('structural_similarity_service.dart'), isFalse);

    final dim = eqDim();
    final before = completeUniformProfile(registry: registry, score: 0.4);
    final owner = subjectSnapshot(
      id: 'A',
      registry: registry,
      assessment: before,
      preferences: prefsProfile(
        registry: registry,
        preferences: {
          dim: rangePref(dimensionId: dim, min: 0.3, max: 0.7),
        },
      ),
    );
    final partner = subjectSnapshot(
      id: 'B',
      registry: registry,
      assessment: completeUniformProfile(registry: registry, score: 0.5),
      preferences: prefsProfile(registry: registry, preferences: {}),
    );
    service.evaluateDirectional(
      preferenceOwner: owner,
      evaluatedSubject: partner,
      registry: registry,
      config: config,
    );
    expect(before.iq!.measurements.length, 4);
    expect(before.eq!.measurements.length, 10);
    expect(before.frequency!.measurements.length, 6);
    for (final m in before.publishedMeasurements.values) {
      expect(m.normalizedScore, 0.4);
    }
  });

  test('60 map order does not change results', () {
    final d0 = eqDim(0);
    final d1 = eqDim(1);
    final a1 = service.evaluateDirectional(
      preferenceOwner: subjectSnapshot(
        id: 'A',
        registry: registry,
        assessment: buildUserProfile(
          registry: registry,
          eq: buildModuleProfile(
            module: AssessmentModuleId.eq,
            registry: registry,
            measurements: {
              d0: ssPublished(
                  dimensionId: d0, module: AssessmentModuleId.eq, score: 0.5),
              d1: ssPublished(
                  dimensionId: d1, module: AssessmentModuleId.eq, score: 0.5),
            },
          ),
        ),
        preferences: prefsProfile(
          registry: registry,
          preferences: {
            d0: rangePref(dimensionId: d0, min: 0.4, max: 0.6, importance: 0.9),
            d1: rangePref(dimensionId: d1, min: 0.4, max: 0.6, importance: 0.4),
          },
        ),
      ),
      evaluatedSubject: subjectSnapshot(
        id: 'B',
        registry: registry,
        assessment: buildUserProfile(
          registry: registry,
          eq: buildModuleProfile(
            module: AssessmentModuleId.eq,
            registry: registry,
            measurements: {
              d0: ssPublished(
                  dimensionId: d0, module: AssessmentModuleId.eq, score: 0.1),
              d1: ssPublished(
                  dimensionId: d1, module: AssessmentModuleId.eq, score: 0.5),
            },
          ),
        ),
        preferences: prefsProfile(registry: registry, preferences: {}),
      ),
      registry: registry,
      config: config,
    );
    final a2 = service.evaluateDirectional(
      preferenceOwner: subjectSnapshot(
        id: 'A',
        registry: registry,
        assessment: buildUserProfile(
          registry: registry,
          eq: buildModuleProfile(
            module: AssessmentModuleId.eq,
            registry: registry,
            measurements: {
              d1: ssPublished(
                  dimensionId: d1, module: AssessmentModuleId.eq, score: 0.5),
              d0: ssPublished(
                  dimensionId: d0, module: AssessmentModuleId.eq, score: 0.5),
            },
          ),
        ),
        preferences: prefsProfile(
          registry: registry,
          preferences: {
            d1: rangePref(dimensionId: d1, min: 0.4, max: 0.6, importance: 0.4),
            d0: rangePref(dimensionId: d0, min: 0.4, max: 0.6, importance: 0.9),
          },
        ),
      ),
      evaluatedSubject: subjectSnapshot(
        id: 'B',
        registry: registry,
        assessment: buildUserProfile(
          registry: registry,
          eq: buildModuleProfile(
            module: AssessmentModuleId.eq,
            registry: registry,
            measurements: {
              d1: ssPublished(
                  dimensionId: d1, module: AssessmentModuleId.eq, score: 0.5),
              d0: ssPublished(
                  dimensionId: d0, module: AssessmentModuleId.eq, score: 0.1),
            },
          ),
        ),
        preferences: prefsProfile(registry: registry, preferences: {}),
      ),
      registry: registry,
      config: config,
    );
    expect(a1.rawFitScore, a2.rawFitScore);
    expect(a1.deterministicFingerprint, a2.deterministicFingerprint);
  });

  test('38 registry mismatch + mutual geometric mean check', () {
    final dim = eqDim();
    expect(
      () => service.evaluateDirectional(
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
              dim: rangePref(dimensionId: dim, min: 0.4, max: 0.6),
            },
          ),
        ),
        evaluatedSubject: subjectSnapshot(
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
        config: PartnerPreferenceFitConfig.fromJson({
          ...config.toJson(),
          'registry_version': 'wrong',
        }),
      ),
      throwsA(isA<CoreMethodValidationException>()),
    );

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
    final m = service.evaluateMutual(
      subjectA: a,
      subjectB: b,
      registry: registry,
      config: config,
    );
    expect(
      m.mutualRawFitScore,
      closeTo(
        math.sqrt(m.subjectAToBResult.rawFitScore! *
            m.subjectBToAResult.rawFitScore!),
        1e-12,
      ),
    );
  });
}
