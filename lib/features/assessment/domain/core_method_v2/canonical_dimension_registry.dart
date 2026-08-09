import 'dart:convert';
import 'dart:io';

import 'assessment_module_id.dart';
import 'core_method_v2_validation.dart';

class CanonicalDimensionDefinition {
  final String dimensionId;
  final AssessmentModuleId module;
  final String status;
  final String registryVersion;
  final int displayOrder;
  final double normalizedScoreMin;
  final double normalizedScoreMax;
  final bool supportsPartnerPreference;
  final bool supportsSimilarity;
  final bool supportsComplementarity;
  final bool supportsHardConstraint;
  final String defaultMatchingRole;
  final String currentCalibrationStatus;
  final String description;
  final List<String> prohibitedInterpretations;

  const CanonicalDimensionDefinition({
    required this.dimensionId,
    required this.module,
    required this.status,
    required this.registryVersion,
    required this.displayOrder,
    required this.normalizedScoreMin,
    required this.normalizedScoreMax,
    required this.supportsPartnerPreference,
    required this.supportsSimilarity,
    required this.supportsComplementarity,
    required this.supportsHardConstraint,
    required this.defaultMatchingRole,
    required this.currentCalibrationStatus,
    required this.description,
    required this.prohibitedInterpretations,
  });

  bool get isActive => status == 'active';

  factory CanonicalDimensionDefinition.fromJson(Map<String, dynamic> j) {
    final id = j['dimension_id']?.toString() ?? '';
    cmRequire(
        id.isNotEmpty, 'dimension_id', 'missing', 'dimension_id required');
    final module = parseAssessmentModuleId(j['module']?.toString() ?? '');
    final min = (j['normalized_score_min'] as num?)?.toDouble();
    final max = (j['normalized_score_max'] as num?)?.toDouble();
    cmRequireFinite01(min, 'normalized_score_min', allowNull: false);
    cmRequireFinite01(max, 'normalized_score_max', allowNull: false);
    cmRequire(min! <= max!, 'normalized_score', 'range', 'min must be <= max');
    return CanonicalDimensionDefinition(
      dimensionId: id,
      module: module,
      status: j['status']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      displayOrder: (j['display_order'] as num?)?.toInt() ?? 0,
      normalizedScoreMin: min,
      normalizedScoreMax: max,
      supportsPartnerPreference: j['supports_partner_preference'] == true,
      supportsSimilarity: j['supports_similarity'] == true,
      supportsComplementarity: j['supports_complementarity'] == true,
      supportsHardConstraint: j['supports_hard_constraint'] == true,
      defaultMatchingRole: j['default_matching_role']?.toString() ?? '',
      currentCalibrationStatus:
          j['current_calibration_status']?.toString() ?? 'uncalibrated',
      description: j['description']?.toString() ?? '',
      prohibitedInterpretations: [
        for (final e in (j['prohibited_interpretations'] as List?) ?? const [])
          e.toString(),
      ],
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'dimension_id': dimensionId,
        'module': module.wire,
        'status': status,
        'registry_version': registryVersion,
        'display_order': displayOrder,
        'normalized_score_min': normalizedScoreMin,
        'normalized_score_max': normalizedScoreMax,
        'supports_partner_preference': supportsPartnerPreference,
        'supports_similarity': supportsSimilarity,
        'supports_complementarity': supportsComplementarity,
        'supports_hard_constraint': supportsHardConstraint,
        'default_matching_role': defaultMatchingRole,
        'current_calibration_status': currentCalibrationStatus,
        'description': description,
        'prohibited_interpretations': prohibitedInterpretations,
      });
}

/// Registry-driven dimension catalog. Never depends on a hardcoded count of 20.
class CanonicalDimensionRegistry {
  final String registryId;
  final String registryVersion;
  final String status;
  final List<CanonicalDimensionDefinition> dimensions;

  CanonicalDimensionRegistry({
    required this.registryId,
    required this.registryVersion,
    required this.status,
    required this.dimensions,
  }) {
    final seen = <String>{};
    for (final d in dimensions) {
      cmRequire(
        seen.add(d.dimensionId),
        'dimensions',
        'duplicate_dimension',
        d.dimensionId,
      );
    }
  }

  List<CanonicalDimensionDefinition> get activeDimensions => [
        for (final d in dimensions)
          if (d.isActive) d
      ];

  int get activeCount => activeDimensions.length;

  Map<String, CanonicalDimensionDefinition> get dimensionsById => {
        for (final d in dimensions) d.dimensionId: d,
      };

  bool contains(String dimensionId) => dimensionsById.containsKey(dimensionId);

  /// Strict: unknown IDs fail. Use [contains] + optional forward-compatible
  /// validation on consumers when a newer registry supersedes this one.
  CanonicalDimensionDefinition require(String dimensionId) {
    final d = dimensionsById[dimensionId];
    if (d == null) {
      throw CoreMethodValidationException(
        'unknown dimension',
        [
          CoreMethodValidationError(
            fieldPath: 'dimension_id',
            reasonCode: 'unknown_dimension',
            explanation: dimensionId,
          ),
        ],
      );
    }
    return d;
  }

  List<CanonicalDimensionDefinition> dimsForModule(AssessmentModuleId module) =>
      [
        for (final d in activeDimensions)
          if (d.module == module) d,
      ];

  factory CanonicalDimensionRegistry.fromJson(Map<String, dynamic> j) {
    final dims = [
      for (final e in (j['dimensions'] as List?) ?? const [])
        CanonicalDimensionDefinition.fromJson(
            Map<String, dynamic>.from(e as Map)),
    ];
    // Sort by display_order for stable iteration; count is registry-derived.
    dims.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return CanonicalDimensionRegistry(
      registryId: j['registry_id']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      dimensions: dims,
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'registry_id': registryId,
        'registry_version': registryVersion,
        'schema_version': registryVersion,
        'status': status,
        'active_dimension_count': activeCount,
        'dimensions': [for (final d in dimensions) d.toJson()],
      });

  static CanonicalDimensionRegistry parseJsonString(String text) =>
      CanonicalDimensionRegistry.fromJson(
        Map<String, dynamic>.from(jsonDecode(text) as Map),
      );

  static CanonicalDimensionRegistry loadFile(String path) =>
      parseJsonString(File(path).readAsStringSync());
}
