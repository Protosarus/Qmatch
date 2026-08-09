import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'core_method_v2_helpers.dart';
import 'structural_similarity_helpers.dart';

PartnerPreferenceFitConfig loadPreferenceFitConfig() =>
    PartnerPreferenceFitConfig.loadFile(
      '${cmRepoRoot()}/assets/data/core_method_v2/directional_preference_fit_config_v1.json',
    );

PartnerDimensionPreference rangePref({
  required String dimensionId,
  required double min,
  required double max,
  double importance = 0.8,
  double flexibility = 0.5,
  bool explicitlyProvided = true,
  String source = 'explicit_user',
}) =>
    PartnerDimensionPreference(
      dimensionId: dimensionId,
      preferredMin: min,
      preferredMax: max,
      importance: importance,
      flexibility: flexibility,
      preferenceMode: PreferenceMode.range,
      source: source,
      explicitlyProvided: explicitlyProvided,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

PartnerDimensionPreference similarityPref({
  required String dimensionId,
  double importance = 0.8,
  double flexibility = 0.5,
  bool explicitlyProvided = true,
  String source = 'explicit_user',
}) =>
    PartnerDimensionPreference(
      dimensionId: dimensionId,
      preferredMin: null,
      preferredMax: null,
      importance: importance,
      flexibility: flexibility,
      preferenceMode: PreferenceMode.similarityToSelf,
      source: source,
      explicitlyProvided: explicitlyProvided,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

PartnerDimensionPreference openPref(String dimensionId) =>
    PartnerDimensionPreference(
      dimensionId: dimensionId,
      preferredMin: null,
      preferredMax: null,
      importance: null,
      flexibility: null,
      preferenceMode: PreferenceMode.open,
      source: 'explicit_user',
      explicitlyProvided: true,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

PartnerDimensionPreference unavailablePref(String dimensionId) =>
    PartnerDimensionPreference(
      dimensionId: dimensionId,
      preferredMin: null,
      preferredMax: null,
      importance: null,
      flexibility: null,
      preferenceMode: PreferenceMode.unavailable,
      source: 'missing',
      explicitlyProvided: false,
      updatedAt: null,
    );

PartnerPreferenceProfile prefsProfile({
  required CanonicalDimensionRegistry registry,
  required Map<String, PartnerDimensionPreference> preferences,
}) {
  final keys = preferences.keys.toList()..sort();
  final sorted = {for (final k in keys) k: preferences[k]!};
  final open = [
    for (final e in sorted.entries)
      if (e.value.preferenceMode == PreferenceMode.open) e.key,
  ]..sort();
  final unavailable = [
    for (final e in sorted.entries)
      if (e.value.preferenceMode == PreferenceMode.unavailable) e.key,
  ]..sort();
  final answered = [
    for (final e in sorted.entries)
      if (e.value.explicitlyProvided) e.key,
  ]..sort();
  return PartnerPreferenceProfile(
    preferences: sorted,
    profileVersion: 'partner_preference_profile_v1',
    registryVersion: registry.registryVersion,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    completionStatus: PreferenceProfileCompletionStatus.partial,
    explicitlyAnsweredDimensions: answered,
    openDimensions: open,
    unavailableDimensions: unavailable,
  );
}

CompatibilitySubjectSnapshot subjectSnapshot({
  required String id,
  required CanonicalDimensionRegistry registry,
  required CanonicalUserAssessmentProfile assessment,
  required PartnerPreferenceProfile preferences,
}) =>
    CompatibilitySubjectSnapshot(
      subjectId: id,
      assessmentProfile: assessment,
      partnerPreferenceProfile: preferences,
      relationshipValueProfile: RelationshipValueProfile(
        responses: const {},
        profileVersion: 'v1',
        registryVersion: 'relationship_value_registry_v1',
        createdAt: null,
        updatedAt: null,
      ),
      hardConstraints: const [],
      snapshotVersion: 'v1',
      createdAt: DateTime.utc(2026, 1, 1),
    );

CanonicalUserAssessmentProfile singleDimProfile({
  required CanonicalDimensionRegistry registry,
  required String dimensionId,
  required AssessmentModuleId module,
  required double score,
  double confidence = 0.8,
}) {
  final m = ssPublished(
    dimensionId: dimensionId,
    module: module,
    score: score,
    confidence: confidence,
  );
  final mod = buildModuleProfile(
    module: module,
    registry: registry,
    measurements: {dimensionId: m},
  );
  return buildUserProfile(
    registry: registry,
    iq: module == AssessmentModuleId.iq ? mod : null,
    eq: module == AssessmentModuleId.eq ? mod : null,
    frequency: module == AssessmentModuleId.frequency ? mod : null,
  );
}
