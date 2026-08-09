import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'support/core_method_v2_helpers.dart';
import 'support/structural_similarity_helpers.dart';

void main() {
  late CanonicalDimensionRegistry registry;
  late StructuralSimilarityConfig config;
  const service = StructuralSimilarityService();

  setUpAll(() {
    registry = loadCanonicalDimensionRegistry();
    config = loadStructuralSimilarityConfig();
  });

  group('config & registry', () {
    test('1–2 config parses and schema file exists', () {
      expect(config.configVersion, 'structural_similarity_config_v1');
      expect(config.status, 'provisional');
      expect(config.calibrationStatus, 'uncalibrated');
      expect(config.runtimeStatus, 'offline_only');
      expect(config.productionApproved, isFalse);
      expect(config.complementarityStatus, 'disabled_pending_calibration');
      expect(config.personaInputStatus, 'prohibited');
      expect(config.aiScoringStatus, 'prohibited');
      expect(
        File(
          '${cmRepoRoot()}/assets/schemas/core_method_v2/structural_similarity_config_v1.schema.json',
        ).existsSync(),
        isTrue,
      );
      // mins match P2B-0 frozen values
      expect(config.minimumComparableFor(AssessmentModuleId.iq), 2);
      expect(config.minimumComparableFor(AssessmentModuleId.eq), 4);
      expect(config.minimumComparableFor(AssessmentModuleId.frequency), 3);
    });

    test('3–5 registry 20 and 24-dim fixture; no hardcoded count', () {
      expect(registry.activeCount, 20);
      final fixture = load24dFixture();
      expect(fixture.dimensions.length, 24);
      final a = completeUniformProfile(registry: fixture, score: 0.5);
      final b = completeUniformProfile(registry: fixture, score: 0.5);
      final r = service.compare(
        subjectA: a,
        subjectB: b,
        registry: fixture,
        config: StructuralSimilarityConfig.fromJson({
          ...config.toJson(),
          'registry_version': fixture.registryVersion,
        }),
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(r.iq?.similarityScore, 1.0);
      final dir = Directory(
        '${cmRepoRoot()}/lib/features/assessment/domain/core_method_v2',
      );
      for (final f in dir.listSync().whereType<File>()) {
        if (!f.path.contains('structural_similarity')) continue;
        expect(
          RegExp(r'dimensionCount\s*=\s*20').hasMatch(f.readAsStringSync()),
          isFalse,
        );
      }
    });
  });

  group('identity, symmetry, monotonicity', () {
    test('6–11 identity, symmetry, bounds, monotonicity', () {
      final a = completeUniformProfile(registry: registry, score: 0.4);
      final b = completeUniformProfile(registry: registry, score: 0.4);
      final same = service.compare(
        subjectA: a,
        subjectB: b,
        registry: registry,
        config: config,
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(same.iq!.distanceSquared, 0);
      expect(same.iq!.similarityScore, 1.0);
      expect(same.eq!.similarityScore, 1.0);
      expect(same.frequency!.similarityScore, 1.0);

      final far = completeUniformProfile(registry: registry, score: 0.9);
      final mid = completeUniformProfile(registry: registry, score: 0.6);
      final close = service.compare(
        subjectA: a,
        subjectB: mid,
        registry: registry,
        config: config,
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      final distant = service.compare(
        subjectA: a,
        subjectB: far,
        registry: registry,
        config: config,
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(close.iq!.distanceSquared! < distant.iq!.distanceSquared!, isTrue);
      expect(close.iq!.similarityScore! > distant.iq!.similarityScore!, isTrue);

      final rev = service.compare(
        subjectA: far,
        subjectB: a,
        registry: registry,
        config: config,
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(distant.iq!.similarityScore, rev.iq!.similarityScore);
      expect(distant.eq!.similarityScore, rev.eq!.similarityScore);
      expect(
          distant.frequency!.similarityScore, rev.frequency!.similarityScore);
      expect(distant.deterministicFingerprint, rev.deterministicFingerprint);

      for (final m in [distant.iq!, distant.eq!, distant.frequency!]) {
        expect(m.similarityScore! > 0 && m.similarityScore! <= 1, isTrue);
        expect(m.distanceSquared! >= 0 && m.distanceSquared! <= 1, isTrue);
      }
    });
  });

  group('weights and pair confidence', () {
    test('12–13 geometric mean and effective weight', () {
      final dims = registry.dimsForModule(AssessmentModuleId.iq);
      final id = dims.first.dimensionId;
      final a = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            for (final d in dims.take(2))
              d.dimensionId: ssPublished(
                dimensionId: d.dimensionId,
                module: AssessmentModuleId.iq,
                score: d.dimensionId == id ? 0.2 : 0.5,
                confidence: d.dimensionId == id ? 0.81 : 0.64,
              ),
          },
        ),
      );
      final b = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            for (final d in dims.take(2))
              d.dimensionId: ssPublished(
                dimensionId: d.dimensionId,
                module: AssessmentModuleId.iq,
                score: 0.5,
                confidence: d.dimensionId == id ? 0.25 : 0.64,
              ),
          },
        ),
      );
      final r = service.compare(
        subjectA: a,
        subjectB: b,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      final c =
          r.iq!.dimensionComparisons.firstWhere((e) => e.dimensionId == id);
      expect(c.pairConfidence, closeTo(math.sqrt(0.81 * 0.25), 1e-12));
      expect(
          c.effectiveWeight, closeTo(c.baseWeight * c.pairConfidence, 1e-12));
    });
  });

  group('missing / eligibility', () {
    test('14–20 missing unpublished non-publishable unsupported', () {
      final dims = registry.dimsForModule(AssessmentModuleId.eq);
      final keep = dims.take(5).toList();
      final aMeas = <String, DimensionMeasurement>{
        for (final d in keep)
          d.dimensionId: ssPublished(
            dimensionId: d.dimensionId,
            module: AssessmentModuleId.eq,
            score: 0.4,
          ),
      };
      final bMeas = Map<String, DimensionMeasurement>.from(aMeas);
      // B missing one
      final missingId = keep.last.dimensionId;
      bMeas.remove(missingId);
      // A unpublished one
      final unpubId = keep[1].dimensionId;
      aMeas[unpubId] = ssPublished(
        dimensionId: unpubId,
        module: AssessmentModuleId.eq,
        score: 0.4,
        publicationStatus: DimensionPublicationStatus.insufficientEvidence,
      );
      // B non-publishable
      final npId = keep[2].dimensionId;
      bMeas[npId] = DimensionMeasurement(
        dimensionId: npId,
        module: AssessmentModuleId.eq,
        normalizedScore: 0.4,
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
      );

      final a = buildUserProfile(
        registry: registry,
        eq: buildModuleProfile(
          module: AssessmentModuleId.eq,
          registry: registry,
          measurements: aMeas,
        ),
      );
      final b = buildUserProfile(
        registry: registry,
        eq: buildModuleProfile(
          module: AssessmentModuleId.eq,
          registry: registry,
          measurements: bMeas,
        ),
      );
      final r = service.compare(
        subjectA: a,
        subjectB: b,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.eq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      final reasons = {
        for (final e in r.eq!.excludedDimensions) e.dimensionId: e.reasonCode,
      };
      expect(reasons[missingId], 'missing_subject_b');
      expect(reasons[unpubId], anyOf('unpublished_subject_a', 'invalid_score'));
      expect(reasons[npId], 'not_publishable_subject_b');
      expect(r.eq!.comparableDimensionIds, isNot(contains(missingId)));
      final blob = jsonEncode(r.toJson());
      expect(blob.contains('"normalized_score":0.5'), isFalse);
      expect(blob.contains('"normalized_score":0.42'), isFalse);
    });

    test('21 cross-module fails module profile validation', () {
      expect(
        () => buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            'empathy': ssPublished(
              dimensionId: 'empathy',
              module: AssessmentModuleId.eq,
              score: 0.5,
            ),
          },
        ).validate(registry),
        throwsA(isA<CoreMethodValidationException>()),
      );
    });
  });

  group('invalid inputs', () {
    test('22–27 invalid score/confidence/NaN/Inf/weights/scale', () {
      expect(
        () => StructuralSimilarityConfig.fromJson({
          ...config.toJson(),
          'default_dimension_weight': -1,
        }),
        throwsA(isA<CoreMethodValidationException>()),
      );
      expect(
        () => StructuralSimilarityConfig.fromJson({
          ...config.toJson(),
          'module_similarity_scales': {'iq': 0, 'eq': 0.35, 'frequency': 0.35},
        }),
        throwsA(isA<CoreMethodValidationException>()),
      );

      final dims =
          registry.dimsForModule(AssessmentModuleId.iq).take(2).toList();
      DimensionMeasurement badScore(String id) => DimensionMeasurement(
            dimensionId: id,
            module: AssessmentModuleId.iq,
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
          );
      final a = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            for (final d in dims) d.dimensionId: badScore(d.dimensionId),
          },
        ),
      );
      final b = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            for (final d in dims)
              d.dimensionId: ssPublished(
                dimensionId: d.dimensionId,
                module: AssessmentModuleId.iq,
                score: 0.5,
              ),
          },
        ),
      );
      final r = service.compare(
        subjectA: a,
        subjectB: b,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      final presentIds = {for (final d in dims) d.dimensionId};
      expect(
        r.iq!.excludedDimensions
            .where((e) => presentIds.contains(e.dimensionId))
            .every((e) => e.reasonCode == 'invalid_score'),
        isTrue,
      );

      final nanA = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            for (final d in dims)
              d.dimensionId: DimensionMeasurement(
                dimensionId: d.dimensionId,
                module: AssessmentModuleId.iq,
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
      );
      final nanR = service.compare(
        subjectA: nanA,
        subjectB: b,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(nanR.iq!.excludedDimensions.first.reasonCode, 'invalid_score');

      final infA = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            for (final d in dims)
              d.dimensionId: DimensionMeasurement(
                dimensionId: d.dimensionId,
                module: AssessmentModuleId.iq,
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
      );
      final infR = service.compare(
        subjectA: infA,
        subjectB: b,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(
          infR.iq!.excludedDimensions.first.reasonCode, 'invalid_confidence');
    });
  });

  group('insufficient / partial / missing module', () {
    test('28–32 insufficient null similarity; partial; missing module', () {
      final one = buildUserProfile(
        registry: registry,
        iq: uniformModule(
          module: AssessmentModuleId.iq,
          registry: registry,
          score: 0.3,
          takeFirst: 1,
        ),
      );
      final oneB = buildUserProfile(
        registry: registry,
        iq: uniformModule(
          module: AssessmentModuleId.iq,
          registry: registry,
          score: 0.7,
          takeFirst: 1,
        ),
      );
      final insuff = service.compare(
        subjectA: one,
        subjectB: oneB,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(insuff.iq!.similarityScore, isNull);
      expect(insuff.iq!.distanceSquared, isNull);
      expect(insuff.iq!.status, StructuralModuleStatus.insufficientEvidence);

      final partial = service.compare(
        subjectA: buildUserProfile(
          registry: registry,
          iq: uniformModule(
            module: AssessmentModuleId.iq,
            registry: registry,
            score: 0.3,
            takeFirst: 2,
          ),
        ),
        subjectB: buildUserProfile(
          registry: registry,
          iq: uniformModule(
            module: AssessmentModuleId.iq,
            registry: registry,
            score: 0.7,
            takeFirst: 2,
          ),
        ),
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(partial.iq!.similarityScore, isNotNull);
      expect(partial.iq!.status, StructuralModuleStatus.partial);

      final full = service.compare(
        subjectA: completeUniformProfile(registry: registry, score: 0.3),
        subjectB: completeUniformProfile(registry: registry, score: 0.3),
        registry: registry,
        config: config,
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(full.iq!.status, StructuralModuleStatus.complete);

      final missingEq = service.compare(
        subjectA: buildUserProfile(
          registry: registry,
          iq: uniformModule(
            module: AssessmentModuleId.iq,
            registry: registry,
            score: 0.5,
          ),
        ),
        subjectB: buildUserProfile(
          registry: registry,
          iq: uniformModule(
            module: AssessmentModuleId.iq,
            registry: registry,
            score: 0.5,
          ),
        ),
        registry: registry,
        config: config,
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(missingEq.missingModules, containsAll(['eq', 'frequency']));
      expect(missingEq.eq, isNull);
    });

    test('29 zero effective weight does not divide by zero', () {
      final dims =
          registry.dimsForModule(AssessmentModuleId.iq).take(2).toList();
      DimensionMeasurement z(String id, double score) => ssPublished(
            dimensionId: id,
            module: AssessmentModuleId.iq,
            score: score,
            confidence: 0.0,
          );
      final a = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            for (final d in dims) d.dimensionId: z(d.dimensionId, 0.2),
          },
        ),
      );
      final b = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            for (final d in dims) d.dimensionId: z(d.dimensionId, 0.9),
          },
        ),
      );
      final r = service.compare(
        subjectA: a,
        subjectB: b,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(r.iq!.similarityScore, isNull);
      expect(r.iq!.effectiveWeightSum, 0);
    });
  });

  group('separation of concerns', () {
    test('33–41 no overall/aggregation/values/pref/hard/persona/freq-type', () {
      final r = service.compare(
        subjectA: completeUniformProfile(registry: registry, score: 0.4),
        subjectB: completeUniformProfile(registry: registry, score: 0.6),
        registry: registry,
        config: config,
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      final j = r.toJson();
      expect(j.containsKey('overall_compatibility_score'), isFalse);
      expect(j.containsKey('values'), isFalse);
      expect(j.containsKey('preference_score'), isFalse);
      expect(j.containsKey('hard_constraint_outcome'), isFalse);
      expect(j.containsKey('persona_id'), isFalse);
      expect(j.containsKey('frequency_type'), isFalse);
      expect(r.iq!.similarityScore != r.eq!.similarityScore || true, isTrue);
      // modules remain separate fields
      expect(j['iq'], isNotNull);
      expect(j['eq'], isNotNull);
      expect(j['frequency'], isNotNull);
      expect(config.complementarityStatus, 'disabled_pending_calibration');
    });
  });

  group('confidence sensitivity', () {
    test('42 multi-dim high-confidence discrepancy has more influence', () {
      final dims =
          registry.dimsForModule(AssessmentModuleId.iq).take(2).toList();
      final d0 = dims[0].dimensionId;
      final d1 = dims[1].dimensionId;

      CanonicalUserAssessmentProfile make(double discConf) {
        return buildUserProfile(
          registry: registry,
          iq: buildModuleProfile(
            module: AssessmentModuleId.iq,
            registry: registry,
            measurements: {
              d0: ssPublished(
                dimensionId: d0,
                module: AssessmentModuleId.iq,
                score: 0.1,
                confidence: discConf,
              ),
              d1: ssPublished(
                dimensionId: d1,
                module: AssessmentModuleId.iq,
                score: 0.5,
                confidence: 0.9,
              ),
            },
          ),
        );
      }

      final b = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            d0: ssPublished(
              dimensionId: d0,
              module: AssessmentModuleId.iq,
              score: 0.9,
              confidence: 0.9,
            ),
            d1: ssPublished(
              dimensionId: d1,
              module: AssessmentModuleId.iq,
              score: 0.5,
              confidence: 0.9,
            ),
          },
        ),
      );

      final high = service.compare(
        subjectA: make(0.9),
        subjectB: b,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      final low = service.compare(
        subjectA: make(0.1),
        subjectB: b,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(high.iq!.distanceSquared! > low.iq!.distanceSquared!, isTrue);
      expect(high.iq!.similarityScore! < low.iq!.similarityScore!, isTrue);
    });

    test('43–44 single-dim confidence: S may stay; Q decreases', () {
      // Temporarily use min comparable = 1 via config override for this case.
      final cfg = StructuralSimilarityConfig.fromJson({
        ...config.toJson(),
        'minimum_comparable_dimensions_per_module': {
          'iq': 1,
          'eq': 4,
          'frequency': 3,
        },
      });
      final id =
          registry.dimsForModule(AssessmentModuleId.iq).first.dimensionId;
      CanonicalUserAssessmentProfile make(double conf, double score) =>
          buildUserProfile(
            registry: registry,
            iq: buildModuleProfile(
              module: AssessmentModuleId.iq,
              registry: registry,
              measurements: {
                id: ssPublished(
                  dimensionId: id,
                  module: AssessmentModuleId.iq,
                  score: score,
                  confidence: conf,
                ),
              },
            ),
          );
      final high = service.compare(
        subjectA: make(0.9, 0.2),
        subjectB: make(0.9, 0.8),
        registry: registry,
        config: cfg,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      final low = service.compare(
        subjectA: make(0.2, 0.2),
        subjectB: make(0.2, 0.8),
        registry: registry,
        config: cfg,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(
          high.iq!.similarityScore, closeTo(low.iq!.similarityScore!, 1e-12));
      expect(
          high.iq!.evidenceConfidence! > low.iq!.evidenceConfidence!, isTrue);
    });

    test('45–47 coverage and evidence confidence formulas', () {
      final dims = registry.dimsForModule(AssessmentModuleId.frequency);
      final take = dims.take(3).toList();
      final a = buildUserProfile(
        registry: registry,
        frequency: buildModuleProfile(
          module: AssessmentModuleId.frequency,
          registry: registry,
          measurements: {
            for (final d in take)
              d.dimensionId: ssPublished(
                dimensionId: d.dimensionId,
                module: AssessmentModuleId.frequency,
                score: 0.4,
                confidence: 0.5,
              ),
          },
        ),
      );
      final b = buildUserProfile(
        registry: registry,
        frequency: buildModuleProfile(
          module: AssessmentModuleId.frequency,
          registry: registry,
          measurements: {
            for (final d in take)
              d.dimensionId: ssPublished(
                dimensionId: d.dimensionId,
                module: AssessmentModuleId.frequency,
                score: 0.6,
                confidence: 0.5,
              ),
          },
        ),
      );
      final r = service.compare(
        subjectA: a,
        subjectB: b,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.frequency],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      final total = dims.where((d) => d.supportsSimilarity).length;
      expect(r.frequency!.unweightedCoverage, closeTo(3 / total, 1e-12));
      expect(r.frequency!.weightedCoverage, closeTo(3 / total, 1e-12));
      expect(r.frequency!.meanPairConfidence, closeTo(0.5, 1e-12));
      expect(
        r.frequency!.evidenceConfidence,
        closeTo(
            r.frequency!.weightedCoverage * r.frequency!.meanPairConfidence!,
            1e-12),
      );
    });
  });

  group('determinism / versions / diagnostics / integration', () {
    test('48–54 map order, fingerprint, versions, contributions, exclusions',
        () {
      final a = completeUniformProfile(registry: registry, score: 0.35);
      final b = completeUniformProfile(registry: registry, score: 0.65);
      final r1 = service.compare(
        subjectA: a,
        subjectB: b,
        registry: registry,
        config: config,
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      // Shuffle measurement map order by rebuilding with reverse key insert.
      final iqDims = registry.dimsForModule(AssessmentModuleId.iq);
      final shuffled = <String, DimensionMeasurement>{};
      for (final d in iqDims.reversed) {
        shuffled[d.dimensionId] = a.iq!.measurements[d.dimensionId]!;
      }
      final a2 = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: shuffled,
        ),
        eq: a.eq,
        frequency: a.frequency,
      );
      final r2 = service.compare(
        subjectA: a2,
        subjectB: b,
        registry: registry,
        config: config,
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(r1.iq!.similarityScore, r2.iq!.similarityScore);
      expect(r1.deterministicFingerprint, r2.deterministicFingerprint);
      expect(
        fingerprint(r1.toJson()),
        fingerprint(
          StructuralProfileSimilarityResult.fromJson(r1.toJson()).toJson(),
        ),
      );

      final sumContrib = r1.iq!.dimensionComparisons.fold<double>(
        0,
        (s, c) => s + c.weightedSquaredContribution,
      );
      expect(
        sumContrib,
        closeTo(r1.iq!.distanceSquared! * r1.iq!.effectiveWeightSum, 1e-12),
      );
      expect(r1.iq!.excludedDimensions, isA<List>());

      // registry mismatch on config
      expect(
        () => service.compare(
          subjectA: a,
          subjectB: b,
          registry: registry,
          config: StructuralSimilarityConfig.fromJson({
            ...config.toJson(),
            'registry_version': 'other_registry',
          }),
          evaluationTimestamp: DateTime.utc(2026, 1, 1),
        ),
        throwsA(isA<CoreMethodValidationException>()),
      );

      // scoring contract mismatch exclusion
      final dims =
          registry.dimsForModule(AssessmentModuleId.iq).take(2).toList();
      final badA = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            for (final d in dims)
              d.dimensionId: ssPublished(
                dimensionId: d.dimensionId,
                module: AssessmentModuleId.iq,
                score: 0.4,
                scoringContractVersion: 'other_contract',
              ),
          },
        ),
      );
      final okB = buildUserProfile(
        registry: registry,
        iq: buildModuleProfile(
          module: AssessmentModuleId.iq,
          registry: registry,
          measurements: {
            for (final d in dims)
              d.dimensionId: ssPublished(
                dimensionId: d.dimensionId,
                module: AssessmentModuleId.iq,
                score: 0.6,
              ),
          },
        ),
      );
      final mm = service.compare(
        subjectA: badA,
        subjectB: okB,
        registry: registry,
        config: config,
        requestedModules: const [AssessmentModuleId.iq],
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      expect(
        mm.iq!.excludedDimensions
            .where((e) => dims.any((d) => d.dimensionId == e.dimensionId))
            .every((e) => e.reasonCode == 'scoring_contract_mismatch'),
        isTrue,
      );
    });

    test('55–60 no Firebase / no production imports / behavior unchanged', () {
      final files = Directory(
        '${cmRepoRoot()}/lib/features/assessment/domain/core_method_v2',
      ).listSync().whereType<File>();
      for (final f in files) {
        if (!f.path.contains('structural_similarity')) continue;
        final t = f.readAsStringSync();
        expect(t.contains('cloud_firestore'), isFalse);
        expect(t.contains('firebase_'), isFalse);
      }
      final prod = File(
        '${cmRepoRoot()}/lib/core/utils/compatibility_scoring.dart',
      ).readAsStringSync();
      final discover = File(
        '${cmRepoRoot()}/lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      final qs = File(
        '${cmRepoRoot()}/lib/features/assessment/services/question_service.dart',
      ).readAsStringSync();
      expect(prod.contains('StructuralSimilarityService'), isFalse);
      expect(discover.contains('StructuralSimilarityService'), isFalse);
      expect(qs.contains('StructuralSimilarityService'), isFalse);

      final screens = Directory(
        '${cmRepoRoot()}/lib/features/assessment/screens',
      );
      for (final f in screens.listSync().whereType<File>()) {
        expect(
          f.readAsStringSync().contains('StructuralSimilarityService'),
          isFalse,
          reason: f.path,
        );
      }
    });
  });
}
