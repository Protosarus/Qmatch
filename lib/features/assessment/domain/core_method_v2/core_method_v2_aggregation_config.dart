import 'dart:convert';
import 'dart:io';

import 'core_method_v2_validation.dart';

class CoreMethodAggregationConfig {
  static const configuredComponentIds = [
    'iq_structural',
    'eq_structural',
    'frequency_structural',
    'mutual_partner_preference',
    'mutual_relationship_values',
  ];

  final String configId;
  final String configVersion;
  final String registryVersion;
  final String status;
  final String calibrationStatus;
  final String runtimeStatus;
  final String productionApprovalStatus;
  final bool scientificallyValidated;
  final Map<String, double> componentWeights;
  final double totalWeight;
  final double weightSumTolerance;
  final double scoreMin;
  final double scoreMax;
  final double confidenceMin;
  final double confidenceMax;
  final double neutralScore;
  final int minimumAvailableComponentCount;
  final double minimumAvailableWeightMass;
  final String rawAggregationMode;
  final String evidenceConfidenceMode;
  final String confidenceAdjustmentMode;
  final String missingComponentPolicy;
  final String hardConstraintFailedPolicy;
  final String hardConstraintUnknownPolicy;
  final String hardConstraintNotApplicablePolicy;
  final String softConflictPolicy;
  final String asymmetryPolicy;
  final String complementarityStatus;
  final String temporalLayerStatus;
  final String personaInputStatus;
  final String frequencyTypeStatus;
  final String aiScoringStatus;
  final String versionCompatibilityPolicy;

  CoreMethodAggregationConfig({
    required this.configId,
    required this.configVersion,
    required this.registryVersion,
    required this.status,
    required this.calibrationStatus,
    required this.runtimeStatus,
    required this.productionApprovalStatus,
    required this.scientificallyValidated,
    required this.componentWeights,
    required this.totalWeight,
    required this.weightSumTolerance,
    required this.scoreMin,
    required this.scoreMax,
    required this.confidenceMin,
    required this.confidenceMax,
    required this.neutralScore,
    required this.minimumAvailableComponentCount,
    required this.minimumAvailableWeightMass,
    required this.rawAggregationMode,
    required this.evidenceConfidenceMode,
    required this.confidenceAdjustmentMode,
    required this.missingComponentPolicy,
    required this.hardConstraintFailedPolicy,
    required this.hardConstraintUnknownPolicy,
    required this.hardConstraintNotApplicablePolicy,
    required this.softConflictPolicy,
    required this.asymmetryPolicy,
    required this.complementarityStatus,
    required this.temporalLayerStatus,
    required this.personaInputStatus,
    required this.frequencyTypeStatus,
    required this.aiScoringStatus,
    required this.versionCompatibilityPolicy,
  }) {
    validate();
  }

  double weightOf(String id) => componentWeights[id] ?? double.nan;

  void validate() {
    cmRequire(status == 'provisional', 'status', 'must_be_provisional', status);
    cmRequire(calibrationStatus == 'uncalibrated', 'calibration_status',
        'must_be_uncalibrated', calibrationStatus);
    cmRequire(runtimeStatus == 'offline_only', 'runtime_status',
        'must_be_offline_only', runtimeStatus);
    cmRequire(
        productionApprovalStatus == 'not_approved',
        'production_approval_status',
        'must_be_not_approved',
        productionApprovalStatus);
    cmRequire(!scientificallyValidated, 'scientifically_validated',
        'must_be_false', 'not scientifically validated');
    cmRequire(
      rawAggregationMode == 'available_component_weight_renormalization',
      'raw_aggregation_mode',
      'unexpected',
      rawAggregationMode,
    );
    cmRequire(
      evidenceConfidenceMode == 'full_configured_weight_mass',
      'evidence_confidence_mode',
      'unexpected',
      evidenceConfidenceMode,
    );
    cmRequire(
      confidenceAdjustmentMode == 'linear_shrinkage_to_neutral',
      'confidence_adjustment_mode',
      'unexpected',
      confidenceAdjustmentMode,
    );
    cmRequire(
      missingComponentPolicy == 'exclude_without_imputation',
      'missing_component_policy',
      'unexpected',
      missingComponentPolicy,
    );
    cmRequire(
      hardConstraintFailedPolicy == 'block_and_withhold_overall_scores',
      'hard_constraint_failed_policy',
      'unexpected',
      hardConstraintFailedPolicy,
    );
    cmRequire(
      softConflictPolicy == 'diagnostics_only_no_numeric_penalty',
      'soft_conflict_policy',
      'unexpected',
      softConflictPolicy,
    );
    cmRequire(asymmetryPolicy == 'diagnostics_only', 'asymmetry_policy',
        'unexpected', asymmetryPolicy);
    cmRequire(
      complementarityStatus == 'disabled_pending_calibration',
      'complementarity_status',
      'must_be_disabled',
      complementarityStatus,
    );
    cmRequire(temporalLayerStatus == 'disabled', 'temporal_layer_status',
        'must_be_disabled', temporalLayerStatus);
    cmRequire(personaInputStatus == 'prohibited', 'persona_input_status',
        'must_be_prohibited', personaInputStatus);
    cmRequire(frequencyTypeStatus == 'prohibited', 'frequency_type_status',
        'must_be_prohibited', frequencyTypeStatus);
    cmRequire(aiScoringStatus == 'prohibited', 'ai_scoring_status',
        'must_be_prohibited', aiScoringStatus);

    cmRequire(componentWeights.length == 5, 'component_weights', 'count',
        '${componentWeights.length}');
    for (final id in configuredComponentIds) {
      cmRequire(componentWeights.containsKey(id), 'component_weights',
          'missing_component', id);
      final w = componentWeights[id]!;
      cmRequire(
          w.isFinite && w > 0, 'component_weights.$id', 'invalid_weight', '$w');
    }
    final sum = componentWeights.values.fold<double>(0, (a, b) => a + b);
    cmRequire(
      (sum - totalWeight).abs() <= weightSumTolerance,
      'total_weight',
      'weight_sum_mismatch',
      'sum=$sum total=$totalWeight tol=$weightSumTolerance',
    );
    cmRequire(
      (sum - 1.0).abs() <= weightSumTolerance,
      'component_weights',
      'weight_sum_not_one',
      '$sum',
    );
    cmRequire(weightSumTolerance.isFinite && weightSumTolerance >= 0,
        'weight_sum_tolerance', 'invalid', '$weightSumTolerance');
    cmRequireFinite01(neutralScore, 'neutral_score', allowNull: false);
    cmRequire(
        neutralScore == 0.5, 'neutral_score', 'must_be_half', '$neutralScore');
    cmRequire(
        minimumAvailableComponentCount >= 1,
        'minimum_available_component_count',
        'invalid',
        '$minimumAvailableComponentCount');
    cmRequireFinite01(
        minimumAvailableWeightMass, 'minimum_available_weight_mass',
        allowNull: false);
    cmRequire(scoreMin == 0 && scoreMax == 1, 'score_bounds', 'unexpected',
        '$scoreMin..$scoreMax');
    cmRequire(confidenceMin == 0 && confidenceMax == 1, 'confidence_bounds',
        'unexpected', '$confidenceMin..$confidenceMax');
  }

  factory CoreMethodAggregationConfig.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> bounds(String key) =>
        Map<String, dynamic>.from(j[key] as Map? ?? {});
    final rawWeights =
        Map<String, dynamic>.from(j['component_weights'] as Map? ?? {});
    final keys = rawWeights.keys.toList()..sort();
    final sb = bounds('score_bounds');
    final cb = bounds('confidence_bounds');
    return CoreMethodAggregationConfig(
      configId: j['config_id']?.toString() ?? '',
      configVersion: j['config_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      calibrationStatus: j['calibration_status']?.toString() ?? '',
      runtimeStatus: j['runtime_status']?.toString() ?? '',
      productionApprovalStatus:
          j['production_approval_status']?.toString() ?? '',
      scientificallyValidated: j['scientifically_validated'] == true,
      componentWeights: {
        for (final k in keys) k: (rawWeights[k] as num).toDouble(),
      },
      totalWeight: (j['total_weight'] as num?)?.toDouble() ?? double.nan,
      weightSumTolerance:
          (j['weight_sum_tolerance'] as num?)?.toDouble() ?? double.nan,
      scoreMin: (sb['min'] as num?)?.toDouble() ?? 0,
      scoreMax: (sb['max'] as num?)?.toDouble() ?? 1,
      confidenceMin: (cb['min'] as num?)?.toDouble() ?? 0,
      confidenceMax: (cb['max'] as num?)?.toDouble() ?? 1,
      neutralScore: (j['neutral_score'] as num?)?.toDouble() ?? double.nan,
      minimumAvailableComponentCount:
          (j['minimum_available_component_count'] as num?)?.toInt() ?? 0,
      minimumAvailableWeightMass:
          (j['minimum_available_weight_mass'] as num?)?.toDouble() ??
              double.nan,
      rawAggregationMode: j['raw_aggregation_mode']?.toString() ?? '',
      evidenceConfidenceMode: j['evidence_confidence_mode']?.toString() ?? '',
      confidenceAdjustmentMode:
          j['confidence_adjustment_mode']?.toString() ?? '',
      missingComponentPolicy: j['missing_component_policy']?.toString() ?? '',
      hardConstraintFailedPolicy:
          j['hard_constraint_failed_policy']?.toString() ?? '',
      hardConstraintUnknownPolicy:
          j['hard_constraint_unknown_policy']?.toString() ?? '',
      hardConstraintNotApplicablePolicy:
          j['hard_constraint_not_applicable_policy']?.toString() ?? '',
      softConflictPolicy: j['soft_conflict_policy']?.toString() ?? '',
      asymmetryPolicy: j['asymmetry_policy']?.toString() ?? '',
      complementarityStatus: j['complementarity_status']?.toString() ?? '',
      temporalLayerStatus: j['temporal_layer_status']?.toString() ?? '',
      personaInputStatus: j['persona_input_status']?.toString() ?? '',
      frequencyTypeStatus: j['frequency_type_status']?.toString() ?? '',
      aiScoringStatus: j['ai_scoring_status']?.toString() ?? '',
      versionCompatibilityPolicy:
          j['version_compatibility_policy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'config_id': configId,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'status': status,
        'calibration_status': calibrationStatus,
        'runtime_status': runtimeStatus,
        'production_approval_status': productionApprovalStatus,
        'scientifically_validated': scientificallyValidated,
        'component_weights': {
          for (final k in (componentWeights.keys.toList()..sort()))
            k: componentWeights[k],
        },
        'total_weight': totalWeight,
        'weight_sum_tolerance': weightSumTolerance,
        'score_bounds': {'min': scoreMin, 'max': scoreMax},
        'confidence_bounds': {'min': confidenceMin, 'max': confidenceMax},
        'neutral_score': neutralScore,
        'minimum_available_component_count': minimumAvailableComponentCount,
        'minimum_available_weight_mass': minimumAvailableWeightMass,
        'raw_aggregation_mode': rawAggregationMode,
        'evidence_confidence_mode': evidenceConfidenceMode,
        'confidence_adjustment_mode': confidenceAdjustmentMode,
        'missing_component_policy': missingComponentPolicy,
        'hard_constraint_failed_policy': hardConstraintFailedPolicy,
        'hard_constraint_unknown_policy': hardConstraintUnknownPolicy,
        'hard_constraint_not_applicable_policy':
            hardConstraintNotApplicablePolicy,
        'soft_conflict_policy': softConflictPolicy,
        'asymmetry_policy': asymmetryPolicy,
        'complementarity_status': complementarityStatus,
        'temporal_layer_status': temporalLayerStatus,
        'persona_input_status': personaInputStatus,
        'frequency_type_status': frequencyTypeStatus,
        'ai_scoring_status': aiScoringStatus,
        'version_compatibility_policy': versionCompatibilityPolicy,
      });

  static CoreMethodAggregationConfig parseJsonString(String text) =>
      CoreMethodAggregationConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(text) as Map),
      );

  static CoreMethodAggregationConfig loadFile(String path) =>
      parseJsonString(File(path).readAsStringSync());
}
