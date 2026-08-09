import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'core_method_v2_helpers.dart';

StructuralSimilarityConfig loadStructuralSimilarityConfig() =>
    StructuralSimilarityConfig.loadFile(
      '${cmRepoRoot()}/assets/data/core_method_v2/structural_similarity_config_v1.json',
    );

DimensionMeasurement ssPublished({
  required String dimensionId,
  required AssessmentModuleId module,
  required double score,
  double confidence = 0.8,
  String scoringContractVersion = 'trait_scoring_config_v1',
  String registryVersion = 'canonical_dimension_registry_v1',
  bool publishability = true,
  DimensionPublicationStatus publicationStatus =
      DimensionPublicationStatus.published,
}) =>
    DimensionMeasurement(
      dimensionId: dimensionId,
      module: module,
      normalizedScore: publicationStatus == DimensionPublicationStatus.published
          ? score
          : null,
      confidence: confidence,
      uncertainty: (1.0 - confidence).clamp(0.0, 1.0),
      primaryEvidenceCount: 2,
      secondaryEvidenceCount: 1,
      independentContextCount: 2,
      publicationStatus: publicationStatus,
      publishability: publishability,
      sourceContentVersions: const ['ss-sim-v1'],
      measurementTimestamp: DateTime.utc(2026, 1, 1),
      scoringContractVersion: scoringContractVersion,
      registryVersion: registryVersion,
    );

ModuleAssessmentProfile buildModuleProfile({
  required AssessmentModuleId module,
  required CanonicalDimensionRegistry registry,
  required Map<String, DimensionMeasurement> measurements,
  ModuleCompletionStatus completion = ModuleCompletionStatus.complete,
}) {
  final keys = measurements.keys.toList()..sort();
  final sorted = <String, DimensionMeasurement>{
    for (final k in keys) k: measurements[k]!,
  };
  final activeIds = {
    for (final d in registry.dimsForModule(module)) d.dimensionId,
  };
  final unavailable = [
    for (final id in activeIds)
      if (!sorted.containsKey(id)) id,
  ]..sort();
  return ModuleAssessmentProfile(
    module: module,
    measurements: sorted,
    assessmentFormId: '${module.wire}_ss',
    contentVersion: '${module.wire}-ss-v1',
    scoringContractVersion: 'trait_scoring_config_v1',
    completionStatus:
        unavailable.isEmpty ? completion : ModuleCompletionStatus.partial,
    completedAt: DateTime.utc(2026, 1, 2),
    moduleConfidence: 0.7,
    evidenceCoverage:
        sorted.length / (activeIds.isEmpty ? 1 : activeIds.length),
    unavailableDimensions: unavailable,
    validationIssues: const [],
    registryVersion: registry.registryVersion,
  );
}

CanonicalUserAssessmentProfile buildUserProfile({
  required CanonicalDimensionRegistry registry,
  ModuleAssessmentProfile? iq,
  ModuleAssessmentProfile? eq,
  ModuleAssessmentProfile? frequency,
}) {
  final published = CanonicalUserAssessmentProfile.flattenPublished(
    iq: iq,
    eq: eq,
    frequency: frequency,
  );
  return CanonicalUserAssessmentProfile(
    snapshotId: 'ss-snap',
    profileSchemaVersion: 'canonical_user_assessment_profile_v1',
    registryVersion: registry.registryVersion,
    iq: iq,
    eq: eq,
    frequency: frequency,
    publishedMeasurements: published,
    unavailableDimensions: const [],
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    sourceAssessmentVersions: const ['ss-v1'],
    overallAssessmentCoverage: 1.0,
    profileReadinessStatus: ProfileReadinessStatus.provisional,
  );
}

ModuleAssessmentProfile uniformModule({
  required AssessmentModuleId module,
  required CanonicalDimensionRegistry registry,
  required double score,
  double confidence = 0.8,
  int? takeFirst,
}) {
  final dims = registry.dimsForModule(module);
  final selected = takeFirst == null ? dims : dims.take(takeFirst).toList();
  final map = <String, DimensionMeasurement>{
    for (final d in selected)
      d.dimensionId: ssPublished(
        dimensionId: d.dimensionId,
        module: module,
        score: score,
        confidence: confidence,
      ),
  };
  return buildModuleProfile(
    module: module,
    registry: registry,
    measurements: map,
  );
}

CanonicalUserAssessmentProfile completeUniformProfile({
  required CanonicalDimensionRegistry registry,
  required double score,
  double confidence = 0.8,
}) =>
    buildUserProfile(
      registry: registry,
      iq: uniformModule(
        module: AssessmentModuleId.iq,
        registry: registry,
        score: score,
        confidence: confidence,
      ),
      eq: uniformModule(
        module: AssessmentModuleId.eq,
        registry: registry,
        score: score,
        confidence: confidence,
      ),
      frequency: uniformModule(
        module: AssessmentModuleId.frequency,
        registry: registry,
        score: score,
        confidence: confidence,
      ),
    );
