import 'canonical_dimension_registry.dart';
import 'canonical_user_assessment_profile.dart';
import 'core_method_v2_validation.dart';
import 'hard_constraint.dart';
import 'partner_preference_profile.dart';
import 'relationship_value_models.dart';
import 'relationship_value_registry.dart';

/// Pure domain snapshot for one side of a pair comparison.
/// Never requires Firebase / live user objects.
class CompatibilitySubjectSnapshot {
  final String subjectId;
  final CanonicalUserAssessmentProfile assessmentProfile;
  final PartnerPreferenceProfile partnerPreferenceProfile;
  final RelationshipValueProfile relationshipValueProfile;
  final List<HardConstraint> hardConstraints;
  final String snapshotVersion;
  final DateTime? createdAt;

  CompatibilitySubjectSnapshot({
    required this.subjectId,
    required this.assessmentProfile,
    required this.partnerPreferenceProfile,
    required this.relationshipValueProfile,
    required this.hardConstraints,
    required this.snapshotVersion,
    required this.createdAt,
  });

  void validate({
    required CanonicalDimensionRegistry dimensionRegistry,
    required RelationshipValueRegistry valueRegistry,
  }) {
    assessmentProfile.validate(dimensionRegistry);
    partnerPreferenceProfile.validate(dimensionRegistry);
    relationshipValueProfile.validate(valueRegistry);
    for (final c in hardConstraints) {
      c.validate(valueRegistry);
    }
  }

  factory CompatibilitySubjectSnapshot.fromJson(
    Map<String, dynamic> j, {
    required CanonicalDimensionRegistry dimensionRegistry,
    required RelationshipValueRegistry valueRegistry,
  }) {
    final snap = CompatibilitySubjectSnapshot(
      subjectId: j['subject_id']?.toString() ?? '',
      assessmentProfile: CanonicalUserAssessmentProfile.fromJson(
        Map<String, dynamic>.from(j['assessment_profile'] as Map),
        registry: dimensionRegistry,
      ),
      partnerPreferenceProfile: PartnerPreferenceProfile.fromJson(
        Map<String, dynamic>.from(j['partner_preference_profile'] as Map),
        registry: dimensionRegistry,
      ),
      relationshipValueProfile: RelationshipValueProfile.fromJson(
        Map<String, dynamic>.from(j['relationship_value_profile'] as Map),
        registry: valueRegistry,
      ),
      hardConstraints: [
        for (final e in (j['hard_constraints'] as List?) ?? const [])
          HardConstraint.fromJson(
            Map<String, dynamic>.from(e as Map),
            registry: valueRegistry,
          ),
      ],
      snapshotVersion: j['snapshot_version']?.toString() ?? '',
      createdAt: j['created_at'] == null
          ? null
          : DateTime.parse(j['created_at'].toString()),
    );
    snap.validate(
      dimensionRegistry: dimensionRegistry,
      valueRegistry: valueRegistry,
    );
    return snap;
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'subject_id': subjectId,
        'assessment_profile': assessmentProfile.toJson(),
        'partner_preference_profile': partnerPreferenceProfile.toJson(),
        'relationship_value_profile': relationshipValueProfile.toJson(),
        'hard_constraints': [for (final c in hardConstraints) c.toJson()],
        'snapshot_version': snapshotVersion,
        'created_at': createdAt?.toIso8601String(),
      });
}

enum CompatibilityEvaluationMode { shadow, offline, productionProhibited }

CompatibilityEvaluationMode parseCompatibilityEvaluationMode(String raw) {
  switch (raw) {
    case 'shadow':
      return CompatibilityEvaluationMode.shadow;
    case 'offline':
      return CompatibilityEvaluationMode.offline;
    case 'production_prohibited':
      return CompatibilityEvaluationMode.productionProhibited;
    default:
      throw CoreMethodValidationException('unknown evaluation mode', [
        CoreMethodValidationError(
          fieldPath: 'evaluation_mode',
          reasonCode: 'unknown_mode',
          explanation: raw,
        ),
      ]);
  }
}

extension CompatibilityEvaluationModeX on CompatibilityEvaluationMode {
  String get wire {
    switch (this) {
      case CompatibilityEvaluationMode.shadow:
        return 'shadow';
      case CompatibilityEvaluationMode.offline:
        return 'offline';
      case CompatibilityEvaluationMode.productionProhibited:
        return 'production_prohibited';
    }
  }
}

/// Ordered pair input. A/B order is preserved for directional preference fit.
class CompatibilityPairInput {
  final CompatibilitySubjectSnapshot subjectA;
  final CompatibilitySubjectSnapshot subjectB;
  final String registryVersion;
  final String compatibilityConfigVersion;
  final DateTime? evaluationTimestamp;
  final CompatibilityEvaluationMode evaluationMode;

  CompatibilityPairInput({
    required this.subjectA,
    required this.subjectB,
    required this.registryVersion,
    required this.compatibilityConfigVersion,
    required this.evaluationTimestamp,
    required this.evaluationMode,
  });

  void validate({
    required CanonicalDimensionRegistry dimensionRegistry,
    required RelationshipValueRegistry valueRegistry,
  }) {
    subjectA.validate(
      dimensionRegistry: dimensionRegistry,
      valueRegistry: valueRegistry,
    );
    subjectB.validate(
      dimensionRegistry: dimensionRegistry,
      valueRegistry: valueRegistry,
    );
  }

  factory CompatibilityPairInput.fromJson(
    Map<String, dynamic> j, {
    required CanonicalDimensionRegistry dimensionRegistry,
    required RelationshipValueRegistry valueRegistry,
  }) {
    final input = CompatibilityPairInput(
      subjectA: CompatibilitySubjectSnapshot.fromJson(
        Map<String, dynamic>.from(j['subject_a'] as Map),
        dimensionRegistry: dimensionRegistry,
        valueRegistry: valueRegistry,
      ),
      subjectB: CompatibilitySubjectSnapshot.fromJson(
        Map<String, dynamic>.from(j['subject_b'] as Map),
        dimensionRegistry: dimensionRegistry,
        valueRegistry: valueRegistry,
      ),
      registryVersion: j['registry_version']?.toString() ?? '',
      compatibilityConfigVersion:
          j['compatibility_config_version']?.toString() ?? '',
      evaluationTimestamp: j['evaluation_timestamp'] == null
          ? null
          : DateTime.parse(j['evaluation_timestamp'].toString()),
      evaluationMode: parseCompatibilityEvaluationMode(
        j['evaluation_mode']?.toString() ?? '',
      ),
    );
    input.validate(
      dimensionRegistry: dimensionRegistry,
      valueRegistry: valueRegistry,
    );
    return input;
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'subject_a': subjectA.toJson(),
        'subject_b': subjectB.toJson(),
        'registry_version': registryVersion,
        'compatibility_config_version': compatibilityConfigVersion,
        'evaluation_timestamp': evaluationTimestamp?.toIso8601String(),
        'evaluation_mode': evaluationMode.wire,
      });
}
