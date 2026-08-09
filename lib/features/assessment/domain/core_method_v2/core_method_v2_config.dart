import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'core_method_v2_validation.dart';

class CoreMethodV2Config {
  final String configId;
  final String configVersion;
  final String registryVersion;
  final String status;
  final String calibrationStatus;
  final bool offlineOnly;
  final bool productionApproved;
  final bool scientificallyValidated;
  final Map<String, double> moduleWeights;
  final double weightSumTolerance;
  final double scoreMin;
  final double scoreMax;
  final double confidenceMin;
  final double confidenceMax;
  final double neutralScore;
  final Map<String, int> minimumComparableDimensionsPerModule;
  final String missingDataPolicy;
  final String confidenceAdjustmentPolicyId;
  final String complementarityStatus;
  final String timeLayerStatus;
  final String aiScoringStatus;

  CoreMethodV2Config({
    required this.configId,
    required this.configVersion,
    required this.registryVersion,
    required this.status,
    required this.calibrationStatus,
    required this.offlineOnly,
    required this.productionApproved,
    required this.scientificallyValidated,
    required this.moduleWeights,
    required this.weightSumTolerance,
    required this.scoreMin,
    required this.scoreMax,
    required this.confidenceMin,
    required this.confidenceMax,
    required this.neutralScore,
    required this.minimumComparableDimensionsPerModule,
    required this.missingDataPolicy,
    required this.confidenceAdjustmentPolicyId,
    required this.complementarityStatus,
    required this.timeLayerStatus,
    required this.aiScoringStatus,
  }) {
    validate();
  }

  void validate() {
    cmRequire(status == 'provisional', 'status', 'must_be_provisional', status);
    cmRequire(calibrationStatus == 'uncalibrated', 'calibration_status',
        'must_be_uncalibrated', calibrationStatus);
    cmRequire(offlineOnly, 'offline_only', 'must_be_true', 'offline only');
    cmRequire(!productionApproved, 'production_approved', 'must_be_false',
        'not production approved');
    cmRequire(!scientificallyValidated, 'scientifically_validated',
        'must_be_false', 'not scientifically validated');
    cmRequire(
      complementarityStatus == 'disabled_pending_calibration',
      'complementarity_status',
      'must_be_disabled',
      complementarityStatus,
    );
    cmRequire(timeLayerStatus == 'disabled', 'time_layer_status',
        'must_be_disabled', timeLayerStatus);
    cmRequire(aiScoringStatus == 'prohibited', 'ai_scoring_status',
        'must_be_prohibited', aiScoringStatus);
    final sum = moduleWeights.values.fold<double>(0, (a, b) => a + b);
    cmRequire(
      (sum - 1.0).abs() <= weightSumTolerance ||
          math.max((sum - 1.0).abs(), 0) <= weightSumTolerance,
      'module_weights',
      'weight_sum',
      'weights must sum to 1 within tolerance (sum=$sum)',
    );
    cmRequireFinite01(neutralScore, 'neutral_score', allowNull: false);
  }

  factory CoreMethodV2Config.fromJson(Map<String, dynamic> j) {
    final weightsRaw =
        Map<String, dynamic>.from(j['module_weights'] as Map? ?? {});
    final weightKeys = weightsRaw.keys.toList()..sort();
    final weights = <String, double>{
      for (final k in weightKeys) k: (weightsRaw[k] as num).toDouble(),
    };
    final minsRaw = Map<String, dynamic>.from(
      j['minimum_comparable_dimensions_per_module'] as Map? ?? {},
    );
    final minKeys = minsRaw.keys.toList()..sort();
    final mins = <String, int>{
      for (final k in minKeys) k: (minsRaw[k] as num).toInt(),
    };
    final scoreBounds =
        Map<String, dynamic>.from(j['score_bounds'] as Map? ?? {});
    final confBounds =
        Map<String, dynamic>.from(j['confidence_bounds'] as Map? ?? {});
    return CoreMethodV2Config(
      configId: j['config_id']?.toString() ?? '',
      configVersion: j['config_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      calibrationStatus: j['calibration_status']?.toString() ?? '',
      offlineOnly: j['offline_only'] == true,
      productionApproved: j['production_approved'] == true,
      scientificallyValidated: j['scientifically_validated'] == true,
      moduleWeights: weights,
      weightSumTolerance:
          (j['weight_sum_tolerance'] as num?)?.toDouble() ?? 1e-9,
      scoreMin: (scoreBounds['min'] as num?)?.toDouble() ?? 0,
      scoreMax: (scoreBounds['max'] as num?)?.toDouble() ?? 1,
      confidenceMin: (confBounds['min'] as num?)?.toDouble() ?? 0,
      confidenceMax: (confBounds['max'] as num?)?.toDouble() ?? 1,
      neutralScore: (j['neutral_score'] as num?)?.toDouble() ?? double.nan,
      minimumComparableDimensionsPerModule: mins,
      missingDataPolicy: j['missing_data_policy']?.toString() ?? '',
      confidenceAdjustmentPolicyId:
          j['confidence_adjustment_policy_id']?.toString() ?? '',
      complementarityStatus: j['complementarity_status']?.toString() ?? '',
      timeLayerStatus: j['time_layer_status']?.toString() ?? '',
      aiScoringStatus: j['ai_scoring_status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final wKeys = moduleWeights.keys.toList()..sort();
    final mKeys = minimumComparableDimensionsPerModule.keys.toList()..sort();
    return cmSortedMap({
      'config_id': configId,
      'config_version': configVersion,
      'registry_version': registryVersion,
      'status': status,
      'calibration_status': calibrationStatus,
      'offline_only': offlineOnly,
      'production_approved': productionApproved,
      'scientifically_validated': scientificallyValidated,
      'module_weights': {for (final k in wKeys) k: moduleWeights[k]},
      'weight_sum_tolerance': weightSumTolerance,
      'score_bounds': {'min': scoreMin, 'max': scoreMax},
      'confidence_bounds': {'min': confidenceMin, 'max': confidenceMax},
      'neutral_score': neutralScore,
      'minimum_comparable_dimensions_per_module': {
        for (final k in mKeys) k: minimumComparableDimensionsPerModule[k],
      },
      'missing_data_policy': missingDataPolicy,
      'confidence_adjustment_policy_id': confidenceAdjustmentPolicyId,
      'complementarity_status': complementarityStatus,
      'time_layer_status': timeLayerStatus,
      'ai_scoring_status': aiScoringStatus,
    });
  }

  static CoreMethodV2Config parseJsonString(String text) =>
      CoreMethodV2Config.fromJson(
        Map<String, dynamic>.from(jsonDecode(text) as Map),
      );

  static CoreMethodV2Config loadFile(String path) =>
      parseJsonString(File(path).readAsStringSync());
}
