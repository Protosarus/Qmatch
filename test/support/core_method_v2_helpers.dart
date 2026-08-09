import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

String cmRepoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('pubspec.yaml not found from ${Directory.current.path}');
    }
    dir = parent;
  }
}

CanonicalDimensionRegistry loadCanonicalDimensionRegistry() =>
    CanonicalDimensionRegistry.loadFile(
      '${cmRepoRoot()}/assets/data/core_method_v2/canonical_dimension_registry_v1.json',
    );

CanonicalDimensionRegistry load24dFixture() =>
    CanonicalDimensionRegistry.loadFile(
      '${cmRepoRoot()}/test/fixtures/core_method_v2/canonical_dimension_registry_24d_fixture.json',
    );

RelationshipValueRegistry loadValueRegistry() =>
    RelationshipValueRegistry.loadFile(
      '${cmRepoRoot()}/assets/data/core_method_v2/relationship_value_registry_v1.json',
    );

CoreMethodV2Config loadCoreMethodConfig() => CoreMethodV2Config.loadFile(
      '${cmRepoRoot()}/assets/data/core_method_v2/core_method_v2_config_v1.json',
    );

P2aAssessmentEngineeringFreezeManifest loadFreezeManifest() =>
    P2aAssessmentEngineeringFreezeManifest.loadFile(
      '${cmRepoRoot()}/assets/data/core_method_v2/p2a_assessment_engineering_freeze_manifest_v1.json',
    );

DimensionMeasurement publishedMeasurement({
  required String dimensionId,
  required AssessmentModuleId module,
  double score = 0.6,
}) =>
    DimensionMeasurement(
      dimensionId: dimensionId,
      module: module,
      normalizedScore: score,
      confidence: 0.7,
      uncertainty: 0.3,
      primaryEvidenceCount: 2,
      secondaryEvidenceCount: 1,
      independentContextCount: 2,
      publicationStatus: DimensionPublicationStatus.published,
      publishability: true,
      sourceContentVersions: const ['test-v1'],
      measurementTimestamp: DateTime.utc(2026, 1, 1),
      scoringContractVersion: 'trait_scoring_config_v1',
      registryVersion: 'canonical_dimension_registry_v1',
    );

DimensionMeasurement unpublishedMeasurement({
  required String dimensionId,
  required AssessmentModuleId module,
  double? fabricatedScore,
}) =>
    DimensionMeasurement(
      dimensionId: dimensionId,
      module: module,
      normalizedScore: fabricatedScore,
      confidence: 0.2,
      uncertainty: 0.8,
      primaryEvidenceCount: 0,
      secondaryEvidenceCount: 0,
      independentContextCount: 0,
      publicationStatus: DimensionPublicationStatus.insufficientEvidence,
      publishability: false,
      sourceContentVersions: const ['test-v1'],
      measurementTimestamp: null,
      scoringContractVersion: 'trait_scoring_config_v1',
      registryVersion: 'canonical_dimension_registry_v1',
    );

ModuleAssessmentProfile iqPartial(CanonicalDimensionRegistry registry) {
  final m = publishedMeasurement(
    dimensionId: 'logical_reasoning',
    module: AssessmentModuleId.iq,
  );
  m.validate(registry);
  return ModuleAssessmentProfile(
    module: AssessmentModuleId.iq,
    measurements: {'logical_reasoning': m},
    assessmentFormId: 'iq_test',
    contentVersion: 'iq-test',
    scoringContractVersion: 'trait_scoring_config_v1',
    completionStatus: ModuleCompletionStatus.partial,
    completedAt: DateTime.utc(2026, 1, 2),
    moduleConfidence: 0.4,
    evidenceCoverage: 0.25,
    unavailableDimensions: const [
      'pattern_reasoning',
      'verbal_reasoning',
      'spatial_reasoning',
    ],
    validationIssues: const [],
    registryVersion: registry.registryVersion,
  );
}

String fingerprint(Map<String, dynamic> json) => jsonEncode(cmSortedMap(json));
