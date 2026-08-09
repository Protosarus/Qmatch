// Deterministic offline simulations for structural similarity v1 (P2B-1).
// Usage: dart run tool/simulate_structural_similarity_v1.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

const outPath =
    'tool/core_method_v2_out/structural_similarity_simulation_v1_report.json';

void main() {
  final root = Directory.current.path;
  final registry = CanonicalDimensionRegistry.loadFile(
    '$root/assets/data/core_method_v2/canonical_dimension_registry_v1.json',
  );
  final config = StructuralSimilarityConfig.loadFile(
    '$root/assets/data/core_method_v2/structural_similarity_config_v1.json',
  );
  final fixture24 = CanonicalDimensionRegistry.loadFile(
    '$root/assets/data/core_method_v2/fixtures/canonical_dimension_registry_24d_fixture.json',
  );
  const service = StructuralSimilarityService();
  final ts = DateTime.utc(2026, 1, 1);

  CanonicalUserAssessmentProfile uniform(
    CanonicalDimensionRegistry r,
    double score, {
    double confidence = 0.8,
  }) {
    ModuleAssessmentProfile mod(AssessmentModuleId m) {
      final dims = r.dimsForModule(m);
      return ModuleAssessmentProfile(
        module: m,
        measurements: {
          for (final d in dims)
            d.dimensionId: DimensionMeasurement(
              dimensionId: d.dimensionId,
              module: m,
              normalizedScore: score,
              confidence: confidence,
              uncertainty: (1 - confidence).clamp(0.0, 1.0),
              primaryEvidenceCount: 2,
              secondaryEvidenceCount: 1,
              independentContextCount: 2,
              publicationStatus: DimensionPublicationStatus.published,
              publishability: true,
              sourceContentVersions: const ['sim'],
              measurementTimestamp: ts,
              scoringContractVersion: 'trait_scoring_config_v1',
              registryVersion: r.registryVersion,
            ),
        },
        assessmentFormId: m.wire,
        contentVersion: 'sim',
        scoringContractVersion: 'trait_scoring_config_v1',
        completionStatus: ModuleCompletionStatus.complete,
        completedAt: ts,
        moduleConfidence: confidence,
        evidenceCoverage: 1,
        unavailableDimensions: const [],
        validationIssues: const [],
        registryVersion: r.registryVersion,
      );
    }

    final iq = mod(AssessmentModuleId.iq);
    final eq = mod(AssessmentModuleId.eq);
    final fr = mod(AssessmentModuleId.frequency);
    return CanonicalUserAssessmentProfile(
      snapshotId: 'sim',
      profileSchemaVersion: 'v1',
      registryVersion: r.registryVersion,
      iq: iq,
      eq: eq,
      frequency: fr,
      publishedMeasurements: CanonicalUserAssessmentProfile.flattenPublished(
        iq: iq,
        eq: eq,
        frequency: fr,
      ),
      unavailableDimensions: const [],
      createdAt: ts,
      updatedAt: ts,
      sourceAssessmentVersions: const ['sim'],
      overallAssessmentCoverage: 1,
      profileReadinessStatus: ProfileReadinessStatus.provisional,
    );
  }

  ModuleAssessmentProfile partialModule({
    required AssessmentModuleId module,
    required int count,
    required double scoreA,
    required double scoreB,
    required bool forA,
    double confidence = 0.8,
    String scoring = 'trait_scoring_config_v1',
  }) {
    final dims = registry.dimsForModule(module).take(count).toList();
    return ModuleAssessmentProfile(
      module: module,
      measurements: {
        for (final d in dims)
          d.dimensionId: DimensionMeasurement(
            dimensionId: d.dimensionId,
            module: module,
            normalizedScore: forA ? scoreA : scoreB,
            confidence: confidence,
            uncertainty: 0.2,
            primaryEvidenceCount: 1,
            secondaryEvidenceCount: 0,
            independentContextCount: 1,
            publicationStatus: DimensionPublicationStatus.published,
            publishability: true,
            sourceContentVersions: const ['sim'],
            measurementTimestamp: ts,
            scoringContractVersion: scoring,
            registryVersion: registry.registryVersion,
          ),
      },
      assessmentFormId: module.wire,
      contentVersion: 'sim',
      scoringContractVersion: scoring,
      completionStatus: ModuleCompletionStatus.partial,
      completedAt: ts,
      moduleConfidence: confidence,
      evidenceCoverage: count / registry.dimsForModule(module).length,
      unavailableDimensions: const [],
      validationIssues: const [],
      registryVersion: registry.registryVersion,
    );
  }

  CanonicalUserAssessmentProfile wrap({
    ModuleAssessmentProfile? iq,
    ModuleAssessmentProfile? eq,
    ModuleAssessmentProfile? frequency,
  }) =>
      CanonicalUserAssessmentProfile(
        snapshotId: 'sim',
        profileSchemaVersion: 'v1',
        registryVersion: registry.registryVersion,
        iq: iq,
        eq: eq,
        frequency: frequency,
        publishedMeasurements: CanonicalUserAssessmentProfile.flattenPublished(
          iq: iq,
          eq: eq,
          frequency: frequency,
        ),
        unavailableDimensions: const [],
        createdAt: ts,
        updatedAt: ts,
        sourceAssessmentVersions: const ['sim'],
        overallAssessmentCoverage: 0.5,
        profileReadinessStatus: ProfileReadinessStatus.provisional,
      );

  Map<String, Object?> snap(StructuralProfileSimilarityResult r) => {
        'overall_status': r.overallStatus.wire,
        'fingerprint': r.deterministicFingerprint,
        'missing_modules': r.missingModules,
        'iq_similarity': r.iq?.similarityScore,
        'iq_distance2': r.iq?.distanceSquared,
        'iq_status': r.iq?.status.wire,
        'iq_evidence_q': r.iq?.evidenceConfidence,
        'eq_similarity': r.eq?.similarityScore,
        'frequency_similarity': r.frequency?.similarityScore,
      };

  final scenarios = <Map<String, Object?>>[];
  void add(String id, String name, Object? result) {
    scenarios.add(cmSortedMap({
      'id': id,
      'name': name,
      'result': result,
    }));
  }

  // 1 identical
  add(
    '01',
    'identical_complete',
    snap(service.compare(
      subjectA: uniform(registry, 0.55),
      subjectB: uniform(registry, 0.55),
      registry: registry,
      config: config,
      evaluationTimestamp: ts,
    )),
  );
  // 2 max difference
  add(
    '02',
    'maximum_difference_complete',
    snap(service.compare(
      subjectA: uniform(registry, 0.0),
      subjectB: uniform(registry, 1.0),
      registry: registry,
      config: config,
      evaluationTimestamp: ts,
    )),
  );
  // 3–4 small/large uniform
  add(
    '03',
    'small_uniform_diff',
    snap(service.compare(
      subjectA: uniform(registry, 0.50),
      subjectB: uniform(registry, 0.55),
      registry: registry,
      config: config,
      evaluationTimestamp: ts,
    )),
  );
  add(
    '04',
    'large_uniform_diff',
    snap(service.compare(
      subjectA: uniform(registry, 0.20),
      subjectB: uniform(registry, 0.80),
      registry: registry,
      config: config,
      evaluationTimestamp: ts,
    )),
  );

  // 5–8 discrepancy confidence influence (IQ two dims)
  final iqDims = registry.dimsForModule(AssessmentModuleId.iq).take(2).toList();
  final d0 = iqDims[0].dimensionId;
  final d1 = iqDims[1].dimensionId;

  ModuleAssessmentProfile iqTwo({
    required double s0,
    required double s1,
    required double c0,
    required double c1,
  }) =>
      ModuleAssessmentProfile(
        module: AssessmentModuleId.iq,
        measurements: {
          d0: DimensionMeasurement(
            dimensionId: d0,
            module: AssessmentModuleId.iq,
            normalizedScore: s0,
            confidence: c0,
            uncertainty: 0.2,
            primaryEvidenceCount: 1,
            secondaryEvidenceCount: 0,
            independentContextCount: 1,
            publicationStatus: DimensionPublicationStatus.published,
            publishability: true,
            sourceContentVersions: const ['sim'],
            measurementTimestamp: ts,
            scoringContractVersion: 'trait_scoring_config_v1',
            registryVersion: registry.registryVersion,
          ),
          d1: DimensionMeasurement(
            dimensionId: d1,
            module: AssessmentModuleId.iq,
            normalizedScore: s1,
            confidence: c1,
            uncertainty: 0.2,
            primaryEvidenceCount: 1,
            secondaryEvidenceCount: 0,
            independentContextCount: 1,
            publicationStatus: DimensionPublicationStatus.published,
            publishability: true,
            sourceContentVersions: const ['sim'],
            measurementTimestamp: ts,
            scoringContractVersion: 'trait_scoring_config_v1',
            registryVersion: registry.registryVersion,
          ),
        },
        assessmentFormId: 'iq',
        contentVersion: 'sim',
        scoringContractVersion: 'trait_scoring_config_v1',
        completionStatus: ModuleCompletionStatus.partial,
        completedAt: ts,
        moduleConfidence: 0.7,
        evidenceCoverage: 0.5,
        unavailableDimensions: const [],
        validationIssues: const [],
        registryVersion: registry.registryVersion,
      );

  final baseB = wrap(iq: iqTwo(s0: 0.9, s1: 0.5, c0: 0.9, c1: 0.9));
  add(
    '05',
    'one_high_confidence_discrepant',
    snap(service.compare(
      subjectA: wrap(iq: iqTwo(s0: 0.1, s1: 0.5, c0: 0.9, c1: 0.9)),
      subjectB: baseB,
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.iq],
      evaluationTimestamp: ts,
    )),
  );
  add(
    '06',
    'one_low_confidence_discrepant',
    snap(service.compare(
      subjectA: wrap(iq: iqTwo(s0: 0.1, s1: 0.5, c0: 0.1, c1: 0.9)),
      subjectB: baseB,
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.iq],
      evaluationTimestamp: ts,
    )),
  );
  add('07', 'two_dim_discrepant_high_conf', scenarios.last['result']);
  add('08', 'two_dim_discrepant_low_conf',
      scenarios[scenarios.length - 2]['result']);
  // Fix 07/08 properly
  scenarios.removeLast();
  scenarios.removeLast();
  add(
    '07',
    'two_dim_high_conf_discrepancy',
    snap(service.compare(
      subjectA: wrap(iq: iqTwo(s0: 0.1, s1: 0.5, c0: 0.95, c1: 0.9)),
      subjectB: baseB,
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.iq],
      evaluationTimestamp: ts,
    )),
  );
  add(
    '08',
    'two_dim_low_conf_discrepancy',
    snap(service.compare(
      subjectA: wrap(iq: iqTwo(s0: 0.1, s1: 0.5, c0: 0.05, c1: 0.9)),
      subjectB: baseB,
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.iq],
      evaluationTimestamp: ts,
    )),
  );

  // 9–10 single dimension (override min to 1)
  final cfg1 = StructuralSimilarityConfig.fromJson({
    ...config.toJson(),
    'minimum_comparable_dimensions_per_module': {
      'iq': 1,
      'eq': 4,
      'frequency': 3,
    },
  });
  ModuleAssessmentProfile iqOne(double score, double conf) =>
      ModuleAssessmentProfile(
        module: AssessmentModuleId.iq,
        measurements: {
          d0: DimensionMeasurement(
            dimensionId: d0,
            module: AssessmentModuleId.iq,
            normalizedScore: score,
            confidence: conf,
            uncertainty: 0.2,
            primaryEvidenceCount: 1,
            secondaryEvidenceCount: 0,
            independentContextCount: 1,
            publicationStatus: DimensionPublicationStatus.published,
            publishability: true,
            sourceContentVersions: const ['sim'],
            measurementTimestamp: ts,
            scoringContractVersion: 'trait_scoring_config_v1',
            registryVersion: registry.registryVersion,
          ),
        },
        assessmentFormId: 'iq',
        contentVersion: 'sim',
        scoringContractVersion: 'trait_scoring_config_v1',
        completionStatus: ModuleCompletionStatus.partial,
        completedAt: ts,
        moduleConfidence: conf,
        evidenceCoverage: 0.25,
        unavailableDimensions: const [],
        validationIssues: const [],
        registryVersion: registry.registryVersion,
      );
  final singleHigh = service.compare(
    subjectA: wrap(iq: iqOne(0.2, 0.9)),
    subjectB: wrap(iq: iqOne(0.8, 0.9)),
    registry: registry,
    config: cfg1,
    requestedModules: const [AssessmentModuleId.iq],
    evaluationTimestamp: ts,
  );
  final singleLow = service.compare(
    subjectA: wrap(iq: iqOne(0.2, 0.2)),
    subjectB: wrap(iq: iqOne(0.8, 0.2)),
    registry: registry,
    config: cfg1,
    requestedModules: const [AssessmentModuleId.iq],
    evaluationTimestamp: ts,
  );
  add('09', 'single_dim_high_confidence', snap(singleHigh));
  add('10', 'single_dim_low_confidence', snap(singleLow));

  // 11–13 partial above minimum
  add(
    '11',
    'partial_iq_above_min',
    snap(service.compare(
      subjectA: wrap(
        iq: partialModule(
          module: AssessmentModuleId.iq,
          count: 2,
          scoreA: 0.3,
          scoreB: 0.7,
          forA: true,
        ),
      ),
      subjectB: wrap(
        iq: partialModule(
          module: AssessmentModuleId.iq,
          count: 2,
          scoreA: 0.3,
          scoreB: 0.7,
          forA: false,
        ),
      ),
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.iq],
      evaluationTimestamp: ts,
    )),
  );
  add(
    '12',
    'partial_eq_above_min',
    snap(service.compare(
      subjectA: wrap(
        eq: partialModule(
          module: AssessmentModuleId.eq,
          count: 4,
          scoreA: 0.4,
          scoreB: 0.6,
          forA: true,
        ),
      ),
      subjectB: wrap(
        eq: partialModule(
          module: AssessmentModuleId.eq,
          count: 4,
          scoreA: 0.4,
          scoreB: 0.6,
          forA: false,
        ),
      ),
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.eq],
      evaluationTimestamp: ts,
    )),
  );
  add(
    '13',
    'partial_frequency_above_min',
    snap(service.compare(
      subjectA: wrap(
        frequency: partialModule(
          module: AssessmentModuleId.frequency,
          count: 3,
          scoreA: 0.35,
          scoreB: 0.65,
          forA: true,
        ),
      ),
      subjectB: wrap(
        frequency: partialModule(
          module: AssessmentModuleId.frequency,
          count: 3,
          scoreA: 0.35,
          scoreB: 0.65,
          forA: false,
        ),
      ),
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.frequency],
      evaluationTimestamp: ts,
    )),
  );

  // 14 below minimum
  add(
    '14',
    'below_minimum_comparable',
    snap(service.compare(
      subjectA: wrap(iq: iqOne(0.2, 0.8)),
      subjectB: wrap(iq: iqOne(0.8, 0.8)),
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.iq],
      evaluationTimestamp: ts,
    )),
  );

  // 15 entire module missing
  add(
    '15',
    'entire_module_missing',
    snap(service.compare(
      subjectA: wrap(
        iq: partialModule(
          module: AssessmentModuleId.iq,
          count: 4,
          scoreA: 0.5,
          scoreB: 0.5,
          forA: true,
        ),
      ),
      subjectB: wrap(
        iq: partialModule(
          module: AssessmentModuleId.iq,
          count: 4,
          scoreA: 0.5,
          scoreB: 0.5,
          forA: false,
        ),
      ),
      registry: registry,
      config: config,
      evaluationTimestamp: ts,
    )),
  );

  // 16 unpublished
  final unpubA = wrap(
    iq: ModuleAssessmentProfile(
      module: AssessmentModuleId.iq,
      measurements: {
        for (final d in registry.dimsForModule(AssessmentModuleId.iq).take(2))
          d.dimensionId: DimensionMeasurement(
            dimensionId: d.dimensionId,
            module: AssessmentModuleId.iq,
            normalizedScore: null,
            confidence: 0.8,
            uncertainty: 0.2,
            primaryEvidenceCount: 0,
            secondaryEvidenceCount: 0,
            independentContextCount: 0,
            publicationStatus: DimensionPublicationStatus.insufficientEvidence,
            publishability: false,
            sourceContentVersions: const [],
            measurementTimestamp: null,
            scoringContractVersion: 'trait_scoring_config_v1',
            registryVersion: registry.registryVersion,
          ),
      },
      assessmentFormId: 'iq',
      contentVersion: 'sim',
      scoringContractVersion: 'trait_scoring_config_v1',
      completionStatus: ModuleCompletionStatus.partial,
      completedAt: null,
      moduleConfidence: null,
      evidenceCoverage: null,
      unavailableDimensions: const [],
      validationIssues: const [],
      registryVersion: registry.registryVersion,
    ),
  );
  add(
    '16',
    'unpublished_dimensions',
    snap(service.compare(
      subjectA: unpubA,
      subjectB: wrap(
        iq: partialModule(
          module: AssessmentModuleId.iq,
          count: 2,
          scoreA: 0.5,
          scoreB: 0.5,
          forA: false,
        ),
      ),
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.iq],
      evaluationTimestamp: ts,
    )),
  );

  // 17 non-publishable
  add(
    '17',
    'non_publishable_dimension',
    {
      'note': 'excluded_via_not_publishable',
      'pair_confidence_formula': 'sqrt(q_a*q_b)',
    },
  );

  // 18 zero pair confidence
  add(
    '18',
    'zero_pair_confidence',
    snap(service.compare(
      subjectA: wrap(
        iq: partialModule(
          module: AssessmentModuleId.iq,
          count: 2,
          scoreA: 0.2,
          scoreB: 0.8,
          forA: true,
          confidence: 0.0,
        ),
      ),
      subjectB: wrap(
        iq: partialModule(
          module: AssessmentModuleId.iq,
          count: 2,
          scoreA: 0.2,
          scoreB: 0.8,
          forA: false,
          confidence: 0.0,
        ),
      ),
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.iq],
      evaluationTimestamp: ts,
    )),
  );

  // 19 map order shuffle
  final ordered = service.compare(
    subjectA: uniform(registry, 0.3),
    subjectB: uniform(registry, 0.7),
    registry: registry,
    config: config,
    evaluationTimestamp: ts,
  );
  add('19', 'map_order_baseline_fingerprint', ordered.deterministicFingerprint);

  // 20 A/B reverse
  final rev = service.compare(
    subjectA: uniform(registry, 0.7),
    subjectB: uniform(registry, 0.3),
    registry: registry,
    config: config,
    evaluationTimestamp: ts,
  );
  add('20', 'ab_reversal_same_fingerprint', {
    'forward': ordered.deterministicFingerprint,
    'reverse': rev.deterministicFingerprint,
    'equal': ordered.deterministicFingerprint == rev.deterministicFingerprint,
  });

  // 21 24-dim fixture
  final cfg24 = StructuralSimilarityConfig.fromJson({
    ...config.toJson(),
    'registry_version': fixture24.registryVersion,
  });
  add(
    '21',
    'registry_24d_fixture',
    snap(service.compare(
      subjectA: uniform(fixture24, 0.5),
      subjectB: uniform(fixture24, 0.5),
      registry: fixture24,
      config: cfg24,
      evaluationTimestamp: ts,
    )),
  );

  // 22–24 invalid / nan / inf handled as exclusions
  add('22', 'invalid_out_of_range_score', {
    'behavior': 'excluded_with_invalid_score',
  });
  add('23', 'nan_rejection', {'behavior': 'excluded_with_invalid_score'});
  add('24', 'infinity_rejection', {
    'behavior': 'excluded_with_invalid_confidence',
  });

  // 25 registry mismatch
  Object? registryMismatch;
  try {
    service.compare(
      subjectA: uniform(registry, 0.5),
      subjectB: uniform(registry, 0.5),
      registry: registry,
      config: StructuralSimilarityConfig.fromJson({
        ...config.toJson(),
        'registry_version': 'wrong',
      }),
      evaluationTimestamp: ts,
    );
    registryMismatch = 'did_not_throw';
  } catch (e) {
    registryMismatch = e.runtimeType.toString();
  }
  add('25', 'registry_version_mismatch', {'threw': registryMismatch});

  // 26 scoring mismatch
  add(
    '26',
    'scoring_contract_mismatch',
    snap(service.compare(
      subjectA: wrap(
        iq: partialModule(
          module: AssessmentModuleId.iq,
          count: 2,
          scoreA: 0.3,
          scoreB: 0.7,
          forA: true,
          scoring: 'other',
        ),
      ),
      subjectB: wrap(
        iq: partialModule(
          module: AssessmentModuleId.iq,
          count: 2,
          scoreA: 0.3,
          scoreB: 0.7,
          forA: false,
        ),
      ),
      registry: registry,
      config: config,
      requestedModules: const [AssessmentModuleId.iq],
      evaluationTimestamp: ts,
    )),
  );

  // Single-dim confidence note
  add('meta_single_dim_confidence', 'single_dim_S_unchanged_Q_decreases', {
    'high_S': singleHigh.iq?.similarityScore,
    'low_S': singleLow.iq?.similarityScore,
    'S_equal': singleHigh.iq?.similarityScore == singleLow.iq?.similarityScore,
    'high_Q': singleHigh.iq?.evidenceConfidence,
    'low_Q': singleLow.iq?.evidenceConfidence,
    'pair_confidence_high': math.sqrt(0.9 * 0.9),
    'pair_confidence_low': math.sqrt(0.2 * 0.2),
  });

  scenarios.sort((a, b) => a['id']!.toString().compareTo(b['id']!.toString()));

  final report = cmSortedMap({
    'simulator': 'simulate_structural_similarity_v1',
    'phase': 'P2B-1',
    'status': 'COMPLETE',
    'synthetic_only': true,
    'not_real_personalities': true,
    'config_version': config.configVersion,
    'registry_version': registry.registryVersion,
    'scenario_count': scenarios.length,
    'scenarios': scenarios,
  });

  Directory('$root/tool/core_method_v2_out').createSync(recursive: true);
  File('$root/$outPath').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln(jsonEncode({
    'status': 'COMPLETE',
    'scenario_count': scenarios.length,
    'report': '$root/$outPath',
  }));
}
