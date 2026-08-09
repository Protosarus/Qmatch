import 'assessment_module_id.dart';
import 'canonical_dimension_registry.dart';
import 'core_method_v2_validation.dart';
import 'dimension_measurement.dart';
import 'dimension_publication_status.dart';
import 'module_assessment_profile.dart';

enum ProfileReadinessStatus {
  readyForShadowEvaluation,
  provisional,
  insufficientEvidence,
  incomplete,
}

ProfileReadinessStatus parseProfileReadinessStatus(String raw) {
  switch (raw) {
    case 'ready_for_shadow_evaluation':
      return ProfileReadinessStatus.readyForShadowEvaluation;
    case 'provisional':
      return ProfileReadinessStatus.provisional;
    case 'insufficient_evidence':
      return ProfileReadinessStatus.insufficientEvidence;
    case 'incomplete':
      return ProfileReadinessStatus.incomplete;
    default:
      throw CoreMethodValidationException('unknown readiness', [
        CoreMethodValidationError(
          fieldPath: 'profile_readiness_status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

extension ProfileReadinessStatusX on ProfileReadinessStatus {
  String get wire {
    switch (this) {
      case ProfileReadinessStatus.readyForShadowEvaluation:
        return 'ready_for_shadow_evaluation';
      case ProfileReadinessStatus.provisional:
        return 'provisional';
      case ProfileReadinessStatus.insufficientEvidence:
        return 'insufficient_evidence';
      case ProfileReadinessStatus.incomplete:
        return 'incomplete';
    }
  }
}

/// Aggregate assessment profile. Never contains persona ID or Frequency type.
class CanonicalUserAssessmentProfile {
  final String snapshotId;
  final String profileSchemaVersion;
  final String registryVersion;
  final ModuleAssessmentProfile? iq;
  final ModuleAssessmentProfile? eq;
  final ModuleAssessmentProfile? frequency;
  final Map<String, DimensionMeasurement> publishedMeasurements;
  final List<String> unavailableDimensions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> sourceAssessmentVersions;
  final double? overallAssessmentCoverage;
  final ProfileReadinessStatus profileReadinessStatus;

  CanonicalUserAssessmentProfile({
    required this.snapshotId,
    required this.profileSchemaVersion,
    required this.registryVersion,
    required this.iq,
    required this.eq,
    required this.frequency,
    required this.publishedMeasurements,
    required this.unavailableDimensions,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceAssessmentVersions,
    required this.overallAssessmentCoverage,
    required this.profileReadinessStatus,
  });

  /// Build flattened published measurements from module profiles.
  static Map<String, DimensionMeasurement> flattenPublished({
    ModuleAssessmentProfile? iq,
    ModuleAssessmentProfile? eq,
    ModuleAssessmentProfile? frequency,
  }) {
    final out = <String, DimensionMeasurement>{};
    for (final mod in [iq, eq, frequency]) {
      if (mod == null) continue;
      for (final e in mod.measurements.entries) {
        if (e.value.publicationStatus == DimensionPublicationStatus.published) {
          out[e.key] = e.value;
        }
      }
    }
    final keys = out.keys.toList()..sort();
    return {for (final k in keys) k: out[k]!};
  }

  void validate(CanonicalDimensionRegistry registry) {
    iq?.validate(registry);
    eq?.validate(registry);
    frequency?.validate(registry);
    cmRequire(iq == null || iq!.module == AssessmentModuleId.iq, 'iq', 'module',
        'iq');
    cmRequire(eq == null || eq!.module == AssessmentModuleId.eq, 'eq', 'module',
        'eq');
    cmRequire(
      frequency == null || frequency!.module == AssessmentModuleId.frequency,
      'frequency',
      'module',
      'frequency',
    );
    final expected = flattenPublished(iq: iq, eq: eq, frequency: frequency);
    cmRequire(
      publishedMeasurements.length == expected.length &&
          publishedMeasurements.keys.every(expected.containsKey),
      'publishedMeasurements',
      'flatten_mismatch',
      'published map must match flattened published module measurements',
    );
    if (overallAssessmentCoverage != null) {
      cmRequireFinite01(overallAssessmentCoverage, 'overallAssessmentCoverage',
          allowNull: false);
    }
  }

  factory CanonicalUserAssessmentProfile.fromJson(
    Map<String, dynamic> j, {
    required CanonicalDimensionRegistry registry,
  }) {
    ModuleAssessmentProfile? parseMod(String key) {
      final raw = j[key];
      if (raw == null) return null;
      return ModuleAssessmentProfile.fromJson(
        Map<String, dynamic>.from(raw as Map),
        registry: registry,
      );
    }

    final iq = parseMod('iq');
    final eq = parseMod('eq');
    final frequency = parseMod('frequency');
    final pubRaw =
        Map<String, dynamic>.from(j['published_measurements'] as Map? ?? {});
    final keys = pubRaw.keys.toList()..sort();
    final published = <String, DimensionMeasurement>{
      for (final k in keys)
        k: DimensionMeasurement.fromJson(
          Map<String, dynamic>.from(pubRaw[k] as Map),
          registry: registry,
        ),
    };
    final profile = CanonicalUserAssessmentProfile(
      snapshotId: j['snapshot_id']?.toString() ?? '',
      profileSchemaVersion: j['profile_schema_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      iq: iq,
      eq: eq,
      frequency: frequency,
      publishedMeasurements: published,
      unavailableDimensions: [
        for (final e in (j['unavailable_dimensions'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
      createdAt: j['created_at'] == null
          ? null
          : DateTime.parse(j['created_at'].toString()),
      updatedAt: j['updated_at'] == null
          ? null
          : DateTime.parse(j['updated_at'].toString()),
      sourceAssessmentVersions: [
        for (final e in (j['source_assessment_versions'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
      overallAssessmentCoverage:
          (j['overall_assessment_coverage'] as num?)?.toDouble(),
      profileReadinessStatus: parseProfileReadinessStatus(
        j['profile_readiness_status']?.toString() ?? '',
      ),
    );
    profile.validate(registry);
    return profile;
  }

  Map<String, dynamic> toJson() {
    final keys = publishedMeasurements.keys.toList()..sort();
    return cmSortedMap({
      'snapshot_id': snapshotId,
      'profile_schema_version': profileSchemaVersion,
      'registry_version': registryVersion,
      'iq': iq?.toJson(),
      'eq': eq?.toJson(),
      'frequency': frequency?.toJson(),
      'published_measurements': {
        for (final k in keys) k: publishedMeasurements[k]!.toJson(),
      },
      'unavailable_dimensions': unavailableDimensions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'source_assessment_versions': sourceAssessmentVersions,
      'overall_assessment_coverage': overallAssessmentCoverage,
      'profile_readiness_status': profileReadinessStatus.wire,
    });
  }
}
