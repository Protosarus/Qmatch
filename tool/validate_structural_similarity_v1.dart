// Offline validator for structural similarity v1 (P2B-1).
// Usage: dart run tool/validate_structural_similarity_v1.dart

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

const outPath =
    'tool/core_method_v2_out/validate_structural_similarity_v1_report.json';

void main() {
  final root = Directory.current.path;
  final findings = <Map<String, String>>[];
  void add(String sev, String code, String msg) =>
      findings.add({'severity': sev, 'code': code, 'message': msg});

  final paths = {
    'config': 'assets/data/core_method_v2/structural_similarity_config_v1.json',
    'schema':
        'assets/schemas/core_method_v2/structural_similarity_config_v1.schema.json',
    'registry':
        'assets/data/core_method_v2/canonical_dimension_registry_v1.json',
    'fixture24':
        'assets/data/core_method_v2/fixtures/canonical_dimension_registry_24d_fixture.json',
    'contract': 'docs/core_engine/structural_profile_similarity_contract_v1.md',
    'cmConfig': 'assets/data/core_method_v2/core_method_v2_config_v1.json',
  };
  for (final e in paths.entries) {
    if (!File('$root/${e.value}').existsSync()) {
      add('error', 'missing_${e.key}', e.value);
    }
  }

  StructuralSimilarityConfig? cfg;
  CanonicalDimensionRegistry? reg;
  try {
    cfg = StructuralSimilarityConfig.loadFile('$root/${paths['config']}');
  } catch (e) {
    add('error', 'config_parse', e.toString());
  }
  try {
    reg = CanonicalDimensionRegistry.loadFile('$root/${paths['registry']}');
  } catch (e) {
    add('error', 'registry_parse', e.toString());
  }

  if (cfg != null && reg != null) {
    if (cfg.registryVersion != reg.registryVersion) {
      add('error', 'registry_version', 'mismatch');
    }
    final cm = jsonDecode(
      File('$root/${paths['cmConfig']}').readAsStringSync(),
    ) as Map<String, dynamic>;
    final mins = Map<String, dynamic>.from(
      cm['minimum_comparable_dimensions_per_module'] as Map,
    );
    for (final m in ['iq', 'eq', 'frequency']) {
      if (cfg.minimumComparableDimensionsPerModule[m] !=
          (mins[m] as num).toInt()) {
        add('error', 'min_comparable_conflict', m);
      }
      final s = cfg.moduleSimilarityScales[m]!;
      if (!(s.isFinite && s > 0)) add('error', 'scale', m);
    }
    if (cfg.defaultDimensionWeight < 0 ||
        !cfg.defaultDimensionWeight.isFinite) {
      add('error', 'default_weight', '${cfg.defaultDimensionWeight}');
    }

    const service = StructuralSimilarityService();
    CanonicalUserAssessmentProfile uniform(
      CanonicalDimensionRegistry r,
      double score,
    ) {
      ModuleAssessmentProfile mod(AssessmentModuleId m, double s) {
        final dims = r.dimsForModule(m);
        return ModuleAssessmentProfile(
          module: m,
          measurements: {
            for (final d in dims)
              d.dimensionId: DimensionMeasurement(
                dimensionId: d.dimensionId,
                module: m,
                normalizedScore: s,
                confidence: 0.8,
                uncertainty: 0.2,
                primaryEvidenceCount: 2,
                secondaryEvidenceCount: 1,
                independentContextCount: 2,
                publicationStatus: DimensionPublicationStatus.published,
                publishability: true,
                sourceContentVersions: const ['v'],
                measurementTimestamp: DateTime.utc(2026, 1, 1),
                scoringContractVersion: 'trait_scoring_config_v1',
                registryVersion: r.registryVersion,
              ),
          },
          assessmentFormId: m.wire,
          contentVersion: 'v',
          scoringContractVersion: 'trait_scoring_config_v1',
          completionStatus: ModuleCompletionStatus.complete,
          completedAt: DateTime.utc(2026, 1, 1),
          moduleConfidence: 0.8,
          evidenceCoverage: 1,
          unavailableDimensions: const [],
          validationIssues: const [],
          registryVersion: r.registryVersion,
        );
      }

      final iq = mod(AssessmentModuleId.iq, score);
      final eq = mod(AssessmentModuleId.eq, score);
      final fr = mod(AssessmentModuleId.frequency, score);
      return CanonicalUserAssessmentProfile(
        snapshotId: 'v',
        profileSchemaVersion: 'v',
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
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        sourceAssessmentVersions: const ['v'],
        overallAssessmentCoverage: 1,
        profileReadinessStatus: ProfileReadinessStatus.provisional,
      );
    }

    final a = uniform(reg, 0.4);
    final bSame = uniform(reg, 0.4);
    final bFar = uniform(reg, 0.9);
    final identity = service.compare(
      subjectA: a,
      subjectB: bSame,
      registry: reg,
      config: cfg,
      evaluationTimestamp: DateTime.utc(2026, 1, 1),
    );
    final distant = service.compare(
      subjectA: a,
      subjectB: bFar,
      registry: reg,
      config: cfg,
      evaluationTimestamp: DateTime.utc(2026, 1, 1),
    );
    final reverse = service.compare(
      subjectA: bFar,
      subjectB: a,
      registry: reg,
      config: cfg,
      evaluationTimestamp: DateTime.utc(2026, 1, 1),
    );

    if (identity.iq?.similarityScore != 1.0) {
      add('error', 'identity', '${identity.iq?.similarityScore}');
    }
    if (identity.iq?.distanceSquared != 0.0) {
      add('error', 'identity_distance', '${identity.iq?.distanceSquared}');
    }
    if (distant.iq!.similarityScore != reverse.iq!.similarityScore) {
      add('error', 'symmetry', 'iq mismatch');
    }
    if (distant.iq!.similarityScore! >= identity.iq!.similarityScore!) {
      add('error', 'monotonicity', 'distant not lower');
    }
    for (final m in [distant.iq!, distant.eq!, distant.frequency!]) {
      if (!m.similarityScore!.isFinite ||
          m.similarityScore! <= 0 ||
          m.similarityScore! > 1) {
        add('error', 'similarity_bounds', m.module.wire);
      }
      if (!m.distanceSquared!.isFinite ||
          m.distanceSquared! < 0 ||
          m.distanceSquared! > 1) {
        add('error', 'distance_bounds', m.module.wire);
      }
    }

    // Insufficient evidence
    final oneDimA = CanonicalUserAssessmentProfile(
      snapshotId: 'v',
      profileSchemaVersion: 'v',
      registryVersion: reg.registryVersion,
      iq: ModuleAssessmentProfile(
        module: AssessmentModuleId.iq,
        measurements: {
          'logical_reasoning': DimensionMeasurement(
            dimensionId: 'logical_reasoning',
            module: AssessmentModuleId.iq,
            normalizedScore: 0.2,
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
            registryVersion: reg.registryVersion,
          ),
        },
        assessmentFormId: 'iq',
        contentVersion: 'v',
        scoringContractVersion: 'trait_scoring_config_v1',
        completionStatus: ModuleCompletionStatus.partial,
        completedAt: null,
        moduleConfidence: null,
        evidenceCoverage: null,
        unavailableDimensions: const [],
        validationIssues: const [],
        registryVersion: reg.registryVersion,
      ),
      eq: null,
      frequency: null,
      publishedMeasurements: CanonicalUserAssessmentProfile.flattenPublished(
        iq: ModuleAssessmentProfile(
          module: AssessmentModuleId.iq,
          measurements: {
            'logical_reasoning': DimensionMeasurement(
              dimensionId: 'logical_reasoning',
              module: AssessmentModuleId.iq,
              normalizedScore: 0.2,
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
              registryVersion: reg.registryVersion,
            ),
          },
          assessmentFormId: 'iq',
          contentVersion: 'v',
          scoringContractVersion: 'trait_scoring_config_v1',
          completionStatus: ModuleCompletionStatus.partial,
          completedAt: null,
          moduleConfidence: null,
          evidenceCoverage: null,
          unavailableDimensions: const [],
          validationIssues: const [],
          registryVersion: reg.registryVersion,
        ),
      ),
      unavailableDimensions: const [],
      createdAt: null,
      updatedAt: null,
      sourceAssessmentVersions: const [],
      overallAssessmentCoverage: null,
      profileReadinessStatus: ProfileReadinessStatus.incomplete,
    );
    final oneDimB = CanonicalUserAssessmentProfile(
      snapshotId: 'v2',
      profileSchemaVersion: 'v',
      registryVersion: reg.registryVersion,
      iq: ModuleAssessmentProfile(
        module: AssessmentModuleId.iq,
        measurements: {
          'logical_reasoning': DimensionMeasurement(
            dimensionId: 'logical_reasoning',
            module: AssessmentModuleId.iq,
            normalizedScore: 0.9,
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
            registryVersion: reg.registryVersion,
          ),
        },
        assessmentFormId: 'iq',
        contentVersion: 'v',
        scoringContractVersion: 'trait_scoring_config_v1',
        completionStatus: ModuleCompletionStatus.partial,
        completedAt: null,
        moduleConfidence: null,
        evidenceCoverage: null,
        unavailableDimensions: const [],
        validationIssues: const [],
        registryVersion: reg.registryVersion,
      ),
      eq: null,
      frequency: null,
      publishedMeasurements: const {},
      unavailableDimensions: const [],
      createdAt: null,
      updatedAt: null,
      sourceAssessmentVersions: const [],
      overallAssessmentCoverage: null,
      profileReadinessStatus: ProfileReadinessStatus.incomplete,
    );
    // Fix published map for B
    final oneDimBFixed = CanonicalUserAssessmentProfile(
      snapshotId: oneDimB.snapshotId,
      profileSchemaVersion: oneDimB.profileSchemaVersion,
      registryVersion: oneDimB.registryVersion,
      iq: oneDimB.iq,
      eq: null,
      frequency: null,
      publishedMeasurements: CanonicalUserAssessmentProfile.flattenPublished(
        iq: oneDimB.iq,
      ),
      unavailableDimensions: const [],
      createdAt: null,
      updatedAt: null,
      sourceAssessmentVersions: const [],
      overallAssessmentCoverage: null,
      profileReadinessStatus: ProfileReadinessStatus.incomplete,
    );
    final insuff = service.compare(
      subjectA: oneDimA,
      subjectB: oneDimBFixed,
      registry: reg,
      config: cfg,
      requestedModules: const [AssessmentModuleId.iq],
      evaluationTimestamp: DateTime.utc(2026, 1, 1),
    );
    if (insuff.iq?.similarityScore != null) {
      add('error', 'insufficient_should_be_null',
          '${insuff.iq?.similarityScore}');
    }

    // 24-dim fixture
    try {
      final f24 = CanonicalDimensionRegistry.loadFile(
        '$root/${paths['fixture24']}',
      );
      if (f24.dimensions.length != 24) {
        add('error', 'fixture24_count', '${f24.dimensions.length}');
      }
      final cfg24 = StructuralSimilarityConfig.fromJson({
        ...cfg.toJson(),
        'registry_version': f24.registryVersion,
      });
      final r24 = service.compare(
        subjectA: uniform(f24, 0.5),
        subjectB: uniform(f24, 0.5),
        registry: f24,
        config: cfg24,
        evaluationTimestamp: DateTime.utc(2026, 1, 1),
      );
      if (r24.iq?.similarityScore != 1.0) {
        add('error', 'fixture24_identity', '${r24.iq?.similarityScore}');
      }
    } catch (e) {
      add('error', 'fixture24', e.toString());
    }

    final resultJson = jsonEncode(distant.toJson());
    for (final bad in [
      'overall_compatibility',
      'persona_id',
      'frequency_type',
      'preference_score',
      'hard_constraint',
    ]) {
      if (resultJson.contains(bad)) add('error', 'forbidden_field', bad);
    }
  }

  // No production integration
  for (final rel in [
    'lib/core/utils/compatibility_scoring.dart',
    'lib/features/discover/services/discover_service.dart',
    'lib/features/assessment/services/question_service.dart',
  ]) {
    final t = File('$root/$rel').readAsStringSync();
    if (t.contains('StructuralSimilarityService')) {
      add('error', 'production_import', rel);
    }
  }
  for (final f in Directory(
    '$root/lib/features/assessment/domain/core_method_v2',
  ).listSync().whereType<File>()) {
    if (!f.path.contains('structural_similarity')) continue;
    final t = f.readAsStringSync();
    if (t.contains('cloud_firestore') || t.contains('firebase_')) {
      add('error', 'firebase_dep', f.path);
    }
    if (RegExp(r'dimensionCount\s*=\s*20').hasMatch(t)) {
      add('error', 'hardcoded_20', f.path);
    }
  }

  findings.sort((a, b) {
    final c = a['severity']!.compareTo(b['severity']!);
    if (c != 0) return c;
    final d = a['code']!.compareTo(b['code']!);
    if (d != 0) return d;
    return a['message']!.compareTo(b['message']!);
  });
  final errors = findings.where((f) => f['severity'] == 'error').length;
  final report = cmSortedMap({
    'validator': 'validate_structural_similarity_v1',
    'phase': 'P2B-1',
    'status': errors == 0 ? 'PASS' : 'FAIL',
    'error_count': errors,
    'finding_count': findings.length,
    'findings': findings,
    'pair_confidence_mode': cfg?.pairConfidenceMode,
    'identity_check': 'identical_profiles_similarity_1',
    'symmetry_check': 'ab_reversal',
    'monotonicity_check': 'larger_distance_lower_similarity',
  });

  Directory('$root/tool/core_method_v2_out').createSync(recursive: true);
  File('$root/$outPath').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln(jsonEncode({
    'status': report['status'],
    'error_count': errors,
    'report': '$root/$outPath',
  }));
  exit(errors == 0 ? 0 : 1);
}
