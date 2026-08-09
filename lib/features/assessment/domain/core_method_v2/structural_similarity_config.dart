import 'dart:convert';
import 'dart:io';

import 'assessment_module_id.dart';
import 'core_method_v2_validation.dart';

class StructuralSimilarityConfig {
  final String configId;
  final String configVersion;
  final String registryVersion;
  final String status;
  final String calibrationStatus;
  final String runtimeStatus;
  final bool productionApproved;
  final bool scientificallyValidated;
  final String distanceMetric;
  final String pairConfidenceMode;
  final String similarityKernel;
  final double defaultDimensionWeight;
  final Map<String, double> dimensionWeightOverrides;
  final Map<String, double> moduleSimilarityScales;
  final Map<String, int> minimumComparableDimensionsPerModule;
  final String? minimumComparableSource;
  final double scoreMin;
  final double scoreMax;
  final double confidenceMin;
  final double confidenceMax;
  final String missingDataPolicy;
  final String zeroEffectiveWeightPolicy;
  final String versionCompatibilityPolicy;
  final String complementarityStatus;
  final String personaInputStatus;
  final String aiScoringStatus;

  StructuralSimilarityConfig({
    required this.configId,
    required this.configVersion,
    required this.registryVersion,
    required this.status,
    required this.calibrationStatus,
    required this.runtimeStatus,
    required this.productionApproved,
    required this.scientificallyValidated,
    required this.distanceMetric,
    required this.pairConfidenceMode,
    required this.similarityKernel,
    required this.defaultDimensionWeight,
    required this.dimensionWeightOverrides,
    required this.moduleSimilarityScales,
    required this.minimumComparableDimensionsPerModule,
    required this.minimumComparableSource,
    required this.scoreMin,
    required this.scoreMax,
    required this.confidenceMin,
    required this.confidenceMax,
    required this.missingDataPolicy,
    required this.zeroEffectiveWeightPolicy,
    required this.versionCompatibilityPolicy,
    required this.complementarityStatus,
    required this.personaInputStatus,
    required this.aiScoringStatus,
  }) {
    validate();
  }

  void validate() {
    cmRequire(status == 'provisional', 'status', 'must_be_provisional', status);
    cmRequire(calibrationStatus == 'uncalibrated', 'calibration_status',
        'must_be_uncalibrated', calibrationStatus);
    cmRequire(runtimeStatus == 'offline_only', 'runtime_status',
        'must_be_offline_only', runtimeStatus);
    cmRequire(!productionApproved, 'production_approved', 'must_be_false',
        'not production approved');
    cmRequire(!scientificallyValidated, 'scientifically_validated',
        'must_be_false', 'not scientifically validated');
    cmRequire(
      distanceMetric == 'confidence_weighted_normalized_squared_euclidean',
      'distance_metric',
      'unexpected',
      distanceMetric,
    );
    cmRequire(pairConfidenceMode == 'geometric_mean', 'pair_confidence_mode',
        'unexpected', pairConfidenceMode);
    cmRequire(similarityKernel == 'gaussian_rbf', 'similarity_kernel',
        'unexpected', similarityKernel);
    cmRequire(
      defaultDimensionWeight.isFinite && defaultDimensionWeight >= 0,
      'default_dimension_weight',
      'invalid',
      '$defaultDimensionWeight',
    );
    for (final e in dimensionWeightOverrides.entries) {
      cmRequire(
        e.value.isFinite && e.value >= 0,
        'dimension_weight_overrides.${e.key}',
        'negative_or_non_finite',
        '${e.value}',
      );
    }
    for (final mod in ['iq', 'eq', 'frequency']) {
      final s = moduleSimilarityScales[mod];
      cmRequire(s != null && s.isFinite && s > 0,
          'module_similarity_scales.$mod', 'zero_or_invalid_scale', '$s');
      final min = minimumComparableDimensionsPerModule[mod];
      cmRequire(min != null && min >= 1, 'minimum_comparable.$mod', 'invalid',
          '$min');
    }
    cmRequire(
      complementarityStatus == 'disabled_pending_calibration',
      'complementarity_status',
      'must_be_disabled',
      complementarityStatus,
    );
    cmRequire(personaInputStatus == 'prohibited', 'persona_input_status',
        'must_be_prohibited', personaInputStatus);
    cmRequire(aiScoringStatus == 'prohibited', 'ai_scoring_status',
        'must_be_prohibited', aiScoringStatus);
  }

  double baseWeightFor(String dimensionId) =>
      dimensionWeightOverrides[dimensionId] ?? defaultDimensionWeight;

  double scaleFor(AssessmentModuleId module) {
    final s = moduleSimilarityScales[module.wire];
    cmRequire(s != null, 'module_similarity_scales', 'missing', module.wire);
    return s!;
  }

  int minimumComparableFor(AssessmentModuleId module) {
    final n = minimumComparableDimensionsPerModule[module.wire];
    cmRequire(n != null, 'minimum_comparable', 'missing', module.wire);
    return n!;
  }

  factory StructuralSimilarityConfig.fromJson(Map<String, dynamic> j) {
    final overridesRaw = Map<String, dynamic>.from(
      j['dimension_weight_overrides'] as Map? ?? {},
    );
    final oKeys = overridesRaw.keys.toList()..sort();
    final overrides = <String, double>{
      for (final k in oKeys) k: (overridesRaw[k] as num).toDouble(),
    };
    final scalesRaw =
        Map<String, dynamic>.from(j['module_similarity_scales'] as Map? ?? {});
    final sKeys = scalesRaw.keys.toList()..sort();
    final scales = <String, double>{
      for (final k in sKeys) k: (scalesRaw[k] as num).toDouble(),
    };
    final minsRaw = Map<String, dynamic>.from(
      j['minimum_comparable_dimensions_per_module'] as Map? ?? {},
    );
    final mKeys = minsRaw.keys.toList()..sort();
    final mins = <String, int>{
      for (final k in mKeys) k: (minsRaw[k] as num).toInt(),
    };
    final scoreBounds =
        Map<String, dynamic>.from(j['score_bounds'] as Map? ?? {});
    final confBounds =
        Map<String, dynamic>.from(j['confidence_bounds'] as Map? ?? {});
    return StructuralSimilarityConfig(
      configId: j['config_id']?.toString() ?? '',
      configVersion: j['config_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      calibrationStatus: j['calibration_status']?.toString() ?? '',
      runtimeStatus: j['runtime_status']?.toString() ?? '',
      productionApproved: j['production_approved'] == true,
      scientificallyValidated: j['scientifically_validated'] == true,
      distanceMetric: j['distance_metric']?.toString() ?? '',
      pairConfidenceMode: j['pair_confidence_mode']?.toString() ?? '',
      similarityKernel: j['similarity_kernel']?.toString() ?? '',
      defaultDimensionWeight:
          (j['default_dimension_weight'] as num?)?.toDouble() ?? double.nan,
      dimensionWeightOverrides: overrides,
      moduleSimilarityScales: scales,
      minimumComparableDimensionsPerModule: mins,
      minimumComparableSource: j['minimum_comparable_source']?.toString(),
      scoreMin: (scoreBounds['min'] as num?)?.toDouble() ?? 0,
      scoreMax: (scoreBounds['max'] as num?)?.toDouble() ?? 1,
      confidenceMin: (confBounds['min'] as num?)?.toDouble() ?? 0,
      confidenceMax: (confBounds['max'] as num?)?.toDouble() ?? 1,
      missingDataPolicy: j['missing_data_policy']?.toString() ?? '',
      zeroEffectiveWeightPolicy:
          j['zero_effective_weight_policy']?.toString() ?? '',
      versionCompatibilityPolicy:
          j['version_compatibility_policy']?.toString() ?? '',
      complementarityStatus: j['complementarity_status']?.toString() ?? '',
      personaInputStatus: j['persona_input_status']?.toString() ?? '',
      aiScoringStatus: j['ai_scoring_status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final oKeys = dimensionWeightOverrides.keys.toList()..sort();
    final sKeys = moduleSimilarityScales.keys.toList()..sort();
    final mKeys = minimumComparableDimensionsPerModule.keys.toList()..sort();
    return cmSortedMap({
      'config_id': configId,
      'config_version': configVersion,
      'registry_version': registryVersion,
      'status': status,
      'calibration_status': calibrationStatus,
      'runtime_status': runtimeStatus,
      'production_approved': productionApproved,
      'scientifically_validated': scientificallyValidated,
      'distance_metric': distanceMetric,
      'pair_confidence_mode': pairConfidenceMode,
      'similarity_kernel': similarityKernel,
      'default_dimension_weight': defaultDimensionWeight,
      'dimension_weight_overrides': {
        for (final k in oKeys) k: dimensionWeightOverrides[k],
      },
      'module_similarity_scales': {
        for (final k in sKeys) k: moduleSimilarityScales[k],
      },
      'minimum_comparable_dimensions_per_module': {
        for (final k in mKeys) k: minimumComparableDimensionsPerModule[k],
      },
      'minimum_comparable_source': minimumComparableSource,
      'score_bounds': {'min': scoreMin, 'max': scoreMax},
      'confidence_bounds': {'min': confidenceMin, 'max': confidenceMax},
      'missing_data_policy': missingDataPolicy,
      'zero_effective_weight_policy': zeroEffectiveWeightPolicy,
      'version_compatibility_policy': versionCompatibilityPolicy,
      'complementarity_status': complementarityStatus,
      'persona_input_status': personaInputStatus,
      'ai_scoring_status': aiScoringStatus,
    });
  }

  static StructuralSimilarityConfig parseJsonString(String text) =>
      StructuralSimilarityConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(text) as Map),
      );

  static StructuralSimilarityConfig loadFile(String path) =>
      parseJsonString(File(path).readAsStringSync());
}
