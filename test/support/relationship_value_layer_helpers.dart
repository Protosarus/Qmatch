import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'core_method_v2_helpers.dart';
import 'directional_preference_fit_helpers.dart';
import 'structural_similarity_helpers.dart';

RelationshipValueComparisonConfig loadValueComparisonConfig() =>
    RelationshipValueComparisonConfig.loadFile(
      '${cmRepoRoot()}/assets/data/core_method_v2/relationship_value_comparison_config_v1.json',
    );

RelationshipValueResponse valueResponse({
  required String fieldId,
  required RelationshipValueRegistry registry,
  String? selectedValue,
  List<String> selectedValues = const [],
  double importance = 0.8,
  double flexibility = 0.5,
  bool explicitlyProvided = true,
  bool comparisonPermission = true,
  String visibilityPolicy = 'internal_comparison_allowed',
}) =>
    RelationshipValueResponse(
      fieldId: fieldId,
      selectedValue: selectedValue,
      selectedValues: selectedValues,
      importance: importance,
      flexibility: flexibility,
      explicitlyProvided: explicitlyProvided,
      responseTimestamp: DateTime.utc(2026, 1, 1),
      registryVersion: registry.registryVersion,
      visibilityPolicy: visibilityPolicy,
      comparisonPermission: comparisonPermission,
    );

RelationshipValueProfile valueProfile({
  required RelationshipValueRegistry registry,
  required Map<String, RelationshipValueResponse> responses,
}) {
  final keys = responses.keys.toList()..sort();
  return RelationshipValueProfile(
    responses: {for (final k in keys) k: responses[k]!},
    profileVersion: 'relationship_value_profile_v1',
    registryVersion: registry.registryVersion,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

HardConstraint hardConstraint({
  required String id,
  required String fieldId,
  required RelationshipValueRegistry registry,
  List<String> accepted = const [],
  List<String> rejected = const [],
  bool enabled = true,
  String matchMode = 'any_allowed',
}) =>
    HardConstraint(
      constraintId: id,
      fieldId: fieldId,
      acceptedValues: accepted,
      rejectedValues: rejected,
      explicitlyEnabled: enabled,
      matchMode: matchMode,
      source: 'explicit_user',
      updatedAt: DateTime.utc(2026, 1, 1),
      registryVersion: registry.registryVersion,
    );

CompatibilitySubjectSnapshot subjectWithValues({
  required String id,
  required CanonicalDimensionRegistry dimRegistry,
  required RelationshipValueRegistry valueRegistry,
  required Map<String, RelationshipValueResponse> responses,
  List<HardConstraint> constraints = const [],
  CanonicalUserAssessmentProfile? assessment,
}) =>
    CompatibilitySubjectSnapshot(
      subjectId: id,
      assessmentProfile: assessment ?? buildUserProfile(registry: dimRegistry),
      partnerPreferenceProfile:
          prefsProfile(registry: dimRegistry, preferences: {}),
      relationshipValueProfile: valueProfile(
        registry: valueRegistry,
        responses: responses,
      ),
      hardConstraints: constraints,
      snapshotVersion: 'v1',
      createdAt: DateTime.utc(2026, 1, 1),
    );
