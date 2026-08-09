import 'assessment_module_id.dart';
import 'canonical_dimension_registry.dart';
import 'core_method_v2_validation.dart';
import 'dimension_publication_status.dart';

class DimensionMeasurement {
  final String dimensionId;
  final AssessmentModuleId module;
  final double? normalizedScore;
  final double confidence;
  final double uncertainty;
  final double primaryEvidenceCount;
  final double secondaryEvidenceCount;
  final double independentContextCount;
  final DimensionPublicationStatus publicationStatus;
  final bool publishability;
  final List<String> sourceContentVersions;
  final DateTime? measurementTimestamp;
  final String scoringContractVersion;
  final String registryVersion;

  const DimensionMeasurement({
    required this.dimensionId,
    required this.module,
    required this.normalizedScore,
    required this.confidence,
    required this.uncertainty,
    required this.primaryEvidenceCount,
    required this.secondaryEvidenceCount,
    required this.independentContextCount,
    required this.publicationStatus,
    required this.publishability,
    required this.sourceContentVersions,
    required this.measurementTimestamp,
    required this.scoringContractVersion,
    required this.registryVersion,
  });

  void validate(
    CanonicalDimensionRegistry? registry, {
    bool forwardCompatible = false,
  }) {
    cmRequireFinite01(confidence, 'confidence', allowNull: false);
    cmRequireFinite01(uncertainty, 'uncertainty', allowNull: false);
    cmRequire(primaryEvidenceCount >= 0, 'primaryEvidenceCount', 'negative',
        'must be >= 0');
    cmRequire(secondaryEvidenceCount >= 0, 'secondaryEvidenceCount', 'negative',
        'must be >= 0');
    cmRequire(independentContextCount >= 0, 'independentContextCount',
        'negative', 'must be >= 0');
    if (publicationStatus.isPublished) {
      cmRequireFinite01(normalizedScore, 'normalizedScore', allowNull: false);
      cmRequire(publishability, 'publishability', 'inconsistent',
          'published requires publishability');
    } else {
      cmRequire(normalizedScore == null, 'normalizedScore', 'fabricated_score',
          'unpublished measurement must not carry a numeric score');
    }
    if (registry != null) {
      if (!registry.contains(dimensionId)) {
        cmRequire(
          forwardCompatible,
          'dimensionId',
          'unknown_dimension',
          'unknown dimension $dimensionId (strict mode)',
        );
        return;
      }
      final def = registry.require(dimensionId);
      cmRequire(def.module == module, 'module', 'module_mismatch',
          'dimension $dimensionId belongs to ${def.module.wire}');
    }
  }

  factory DimensionMeasurement.fromJson(
    Map<String, dynamic> j, {
    CanonicalDimensionRegistry? registry,
    bool forwardCompatible = false,
  }) {
    final m = DimensionMeasurement(
      dimensionId: j['dimension_id']?.toString() ?? '',
      module: parseAssessmentModuleId(j['module']?.toString() ?? ''),
      normalizedScore: (j['normalized_score'] as num?)?.toDouble(),
      confidence: (j['confidence'] as num?)?.toDouble() ?? double.nan,
      uncertainty: (j['uncertainty'] as num?)?.toDouble() ?? double.nan,
      primaryEvidenceCount:
          (j['primary_evidence_count'] as num?)?.toDouble() ?? -1,
      secondaryEvidenceCount:
          (j['secondary_evidence_count'] as num?)?.toDouble() ?? -1,
      independentContextCount:
          (j['independent_context_count'] as num?)?.toDouble() ?? -1,
      publicationStatus: parseDimensionPublicationStatus(
        j['publication_status']?.toString() ?? '',
      ),
      publishability: j['publishability'] == true,
      sourceContentVersions: [
        for (final e in (j['source_content_versions'] as List?) ?? const [])
          e.toString(),
      ],
      measurementTimestamp: j['measurement_timestamp'] == null
          ? null
          : DateTime.parse(j['measurement_timestamp'].toString()),
      scoringContractVersion: j['scoring_contract_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
    );
    m.validate(registry, forwardCompatible: forwardCompatible);
    return m;
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'dimension_id': dimensionId,
        'module': module.wire,
        'normalized_score': normalizedScore,
        'confidence': confidence,
        'uncertainty': uncertainty,
        'primary_evidence_count': primaryEvidenceCount,
        'secondary_evidence_count': secondaryEvidenceCount,
        'independent_context_count': independentContextCount,
        'publication_status': publicationStatus.wire,
        'publishability': publishability,
        'source_content_versions': sourceContentVersions,
        'measurement_timestamp': measurementTimestamp?.toIso8601String(),
        'scoring_contract_version': scoringContractVersion,
        'registry_version': registryVersion,
      });
}
