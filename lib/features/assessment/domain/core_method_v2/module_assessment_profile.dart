import 'assessment_module_id.dart';
import 'canonical_dimension_registry.dart';
import 'core_method_v2_validation.dart';
import 'dimension_measurement.dart';
import 'dimension_publication_status.dart';

enum ModuleCompletionStatus { complete, partial, incomplete, unavailable }

ModuleCompletionStatus parseModuleCompletionStatus(String raw) {
  switch (raw) {
    case 'complete':
      return ModuleCompletionStatus.complete;
    case 'partial':
      return ModuleCompletionStatus.partial;
    case 'incomplete':
      return ModuleCompletionStatus.incomplete;
    case 'unavailable':
      return ModuleCompletionStatus.unavailable;
    default:
      throw CoreMethodValidationException('unknown completion status', [
        CoreMethodValidationError(
          fieldPath: 'completion_status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

extension ModuleCompletionStatusX on ModuleCompletionStatus {
  String get wire {
    switch (this) {
      case ModuleCompletionStatus.complete:
        return 'complete';
      case ModuleCompletionStatus.partial:
        return 'partial';
      case ModuleCompletionStatus.incomplete:
        return 'incomplete';
      case ModuleCompletionStatus.unavailable:
        return 'unavailable';
    }
  }
}

class ModuleAssessmentProfile {
  final AssessmentModuleId module;
  final Map<String, DimensionMeasurement> measurements;
  final String? assessmentFormId;
  final String? contentVersion;
  final String scoringContractVersion;
  final ModuleCompletionStatus completionStatus;
  final DateTime? completedAt;
  final double? moduleConfidence;
  final double? evidenceCoverage;
  final List<String> unavailableDimensions;
  final List<String> validationIssues;
  final String registryVersion;

  ModuleAssessmentProfile({
    required this.module,
    required this.measurements,
    required this.assessmentFormId,
    required this.contentVersion,
    required this.scoringContractVersion,
    required this.completionStatus,
    required this.completedAt,
    required this.moduleConfidence,
    required this.evidenceCoverage,
    required this.unavailableDimensions,
    required this.validationIssues,
    required this.registryVersion,
  });

  void validate(CanonicalDimensionRegistry registry) {
    final allowed = {
      for (final d in registry.dimsForModule(module)) d.dimensionId,
    };
    for (final e in measurements.entries) {
      cmRequire(
          allowed.contains(e.key),
          'measurements',
          'cross_module_or_unknown',
          '${e.key} not an active ${module.wire} dimension');
      cmRequire(
          e.value.dimensionId == e.key, 'measurements', 'key_mismatch', e.key);
      cmRequire(
          e.value.module == module, 'measurements', 'module_mismatch', e.key);
      e.value.validate(registry);
    }
    if (moduleConfidence != null) {
      cmRequireFinite01(moduleConfidence, 'moduleConfidence', allowNull: false);
    }
    if (evidenceCoverage != null) {
      cmRequireFinite01(evidenceCoverage, 'evidenceCoverage', allowNull: false);
    }
  }

  factory ModuleAssessmentProfile.fromJson(
    Map<String, dynamic> j, {
    required CanonicalDimensionRegistry registry,
  }) {
    final module = parseAssessmentModuleId(j['module']?.toString() ?? '');
    final raw = Map<String, dynamic>.from(j['measurements'] as Map? ?? {});
    final keys = raw.keys.toList()..sort();
    final measurements = <String, DimensionMeasurement>{};
    for (final k in keys) {
      measurements[k] = DimensionMeasurement.fromJson(
        Map<String, dynamic>.from(raw[k] as Map),
        registry: registry,
      );
    }
    final profile = ModuleAssessmentProfile(
      module: module,
      measurements: measurements,
      assessmentFormId: j['assessment_form_id']?.toString(),
      contentVersion: j['content_version']?.toString(),
      scoringContractVersion: j['scoring_contract_version']?.toString() ?? '',
      completionStatus:
          parseModuleCompletionStatus(j['completion_status']?.toString() ?? ''),
      completedAt: j['completed_at'] == null
          ? null
          : DateTime.parse(j['completed_at'].toString()),
      moduleConfidence: (j['module_confidence'] as num?)?.toDouble(),
      evidenceCoverage: (j['evidence_coverage'] as num?)?.toDouble(),
      unavailableDimensions: [
        for (final e in (j['unavailable_dimensions'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
      validationIssues: [
        for (final e in (j['validation_issues'] as List?) ?? const [])
          e.toString(),
      ],
      registryVersion: j['registry_version']?.toString() ?? '',
    );
    profile.validate(registry);
    return profile;
  }

  Map<String, dynamic> toJson() {
    final keys = measurements.keys.toList()..sort();
    return cmSortedMap({
      'module': module.wire,
      'measurements': {
        for (final k in keys) k: measurements[k]!.toJson(),
      },
      'assessment_form_id': assessmentFormId,
      'content_version': contentVersion,
      'scoring_contract_version': scoringContractVersion,
      'completion_status': completionStatus.wire,
      'completed_at': completedAt?.toIso8601String(),
      'module_confidence': moduleConfidence,
      'evidence_coverage': evidenceCoverage,
      'unavailable_dimensions': unavailableDimensions,
      'validation_issues': validationIssues,
      'registry_version': registryVersion,
    });
  }

  List<String> get publishedDimensionIds => [
        for (final e in measurements.entries)
          if (e.value.publicationStatus == DimensionPublicationStatus.published)
            e.key,
      ]..sort();
}
