import 'dart:convert';
import 'dart:io';

import 'core_method_v2_validation.dart';
import 'partner_dimension_preference.dart';

class PartnerPreferenceFitConfig {
  final String configId;
  final String configVersion;
  final String registryVersion;
  final String status;
  final String calibrationStatus;
  final String runtimeStatus;
  final bool productionApproved;
  final bool scientificallyValidated;
  final String aggregationMode;
  final String mutualAggregationMode;
  final String flexibilityMapping;
  final double minimumFlexibilityScale;
  final double maximumFlexibilityScale;
  final double importanceMin;
  final double importanceMax;
  final double flexibilityMin;
  final double flexibilityMax;
  final double scoreMin;
  final double scoreMax;
  final double confidenceMin;
  final double confidenceMax;
  final int minimumComparablePreferences;
  final List<String> supportedPreferenceModes;
  final String inferredPreferencePolicy;
  final String openPreferencePolicy;
  final String missingPreferencePolicy;
  final String zeroEffectiveWeightPolicy;
  final String versionCompatibilityPolicy;
  final String complementarityStatus;
  final String personaInputStatus;
  final String aiScoringStatus;

  PartnerPreferenceFitConfig({
    required this.configId,
    required this.configVersion,
    required this.registryVersion,
    required this.status,
    required this.calibrationStatus,
    required this.runtimeStatus,
    required this.productionApproved,
    required this.scientificallyValidated,
    required this.aggregationMode,
    required this.mutualAggregationMode,
    required this.flexibilityMapping,
    required this.minimumFlexibilityScale,
    required this.maximumFlexibilityScale,
    required this.importanceMin,
    required this.importanceMax,
    required this.flexibilityMin,
    required this.flexibilityMax,
    required this.scoreMin,
    required this.scoreMax,
    required this.confidenceMin,
    required this.confidenceMax,
    required this.minimumComparablePreferences,
    required this.supportedPreferenceModes,
    required this.inferredPreferencePolicy,
    required this.openPreferencePolicy,
    required this.missingPreferencePolicy,
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
    cmRequire(aggregationMode == 'confidence_weighted_mean', 'aggregation_mode',
        'unexpected', aggregationMode);
    cmRequire(mutualAggregationMode == 'geometric_mean',
        'mutual_aggregation_mode', 'unexpected', mutualAggregationMode);
    cmRequire(flexibilityMapping == 'linear_scale', 'flexibility_mapping',
        'unexpected', flexibilityMapping);
    cmRequire(
      minimumFlexibilityScale.isFinite && minimumFlexibilityScale > 0,
      'minimum_flexibility_scale',
      'invalid',
      '$minimumFlexibilityScale',
    );
    cmRequire(
      maximumFlexibilityScale.isFinite &&
          maximumFlexibilityScale >= minimumFlexibilityScale,
      'maximum_flexibility_scale',
      'invalid',
      '$maximumFlexibilityScale',
    );
    cmRequire(
        minimumComparablePreferences >= 1,
        'minimum_comparable_preferences',
        'invalid',
        '$minimumComparablePreferences');
    cmRequire(inferredPreferencePolicy == 'prohibited_by_default',
        'inferred_preference_policy', 'unexpected', inferredPreferencePolicy);
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
    for (final m in [
      'range',
      'similarity_to_self',
      'open',
      'unavailable',
    ]) {
      cmRequire(supportedPreferenceModes.contains(m),
          'supported_preference_modes', 'missing_mode', m);
    }
  }

  double flexibilityScale(double flexibility) =>
      minimumFlexibilityScale +
      flexibility * (maximumFlexibilityScale - minimumFlexibilityScale);

  bool supportsMode(PreferenceMode mode) =>
      supportedPreferenceModes.contains(mode.wire);

  factory PartnerPreferenceFitConfig.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> bounds(String key) =>
        Map<String, dynamic>.from(j[key] as Map? ?? {});
    final modes = [
      for (final e in (j['supported_preference_modes'] as List?) ?? const [])
        e.toString(),
    ]..sort();
    final ib = bounds('importance_bounds');
    final fb = bounds('flexibility_bounds');
    final sb = bounds('score_bounds');
    final cb = bounds('confidence_bounds');
    return PartnerPreferenceFitConfig(
      configId: j['config_id']?.toString() ?? '',
      configVersion: j['config_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      calibrationStatus: j['calibration_status']?.toString() ?? '',
      runtimeStatus: j['runtime_status']?.toString() ?? '',
      productionApproved: j['production_approved'] == true,
      scientificallyValidated: j['scientifically_validated'] == true,
      aggregationMode: j['aggregation_mode']?.toString() ?? '',
      mutualAggregationMode: j['mutual_aggregation_mode']?.toString() ?? '',
      flexibilityMapping: j['flexibility_mapping']?.toString() ?? '',
      minimumFlexibilityScale:
          (j['minimum_flexibility_scale'] as num?)?.toDouble() ?? double.nan,
      maximumFlexibilityScale:
          (j['maximum_flexibility_scale'] as num?)?.toDouble() ?? double.nan,
      importanceMin: (ib['min'] as num?)?.toDouble() ?? 0,
      importanceMax: (ib['max'] as num?)?.toDouble() ?? 1,
      flexibilityMin: (fb['min'] as num?)?.toDouble() ?? 0,
      flexibilityMax: (fb['max'] as num?)?.toDouble() ?? 1,
      scoreMin: (sb['min'] as num?)?.toDouble() ?? 0,
      scoreMax: (sb['max'] as num?)?.toDouble() ?? 1,
      confidenceMin: (cb['min'] as num?)?.toDouble() ?? 0,
      confidenceMax: (cb['max'] as num?)?.toDouble() ?? 1,
      minimumComparablePreferences:
          (j['minimum_comparable_preferences'] as num?)?.toInt() ?? 0,
      supportedPreferenceModes: modes,
      inferredPreferencePolicy:
          j['inferred_preference_policy']?.toString() ?? '',
      openPreferencePolicy: j['open_preference_policy']?.toString() ?? '',
      missingPreferencePolicy: j['missing_preference_policy']?.toString() ?? '',
      zeroEffectiveWeightPolicy:
          j['zero_effective_weight_policy']?.toString() ?? '',
      versionCompatibilityPolicy:
          j['version_compatibility_policy']?.toString() ?? '',
      complementarityStatus: j['complementarity_status']?.toString() ?? '',
      personaInputStatus: j['persona_input_status']?.toString() ?? '',
      aiScoringStatus: j['ai_scoring_status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'config_id': configId,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'status': status,
        'calibration_status': calibrationStatus,
        'runtime_status': runtimeStatus,
        'production_approved': productionApproved,
        'scientifically_validated': scientificallyValidated,
        'aggregation_mode': aggregationMode,
        'mutual_aggregation_mode': mutualAggregationMode,
        'flexibility_mapping': flexibilityMapping,
        'minimum_flexibility_scale': minimumFlexibilityScale,
        'maximum_flexibility_scale': maximumFlexibilityScale,
        'importance_bounds': {'min': importanceMin, 'max': importanceMax},
        'flexibility_bounds': {'min': flexibilityMin, 'max': flexibilityMax},
        'score_bounds': {'min': scoreMin, 'max': scoreMax},
        'confidence_bounds': {'min': confidenceMin, 'max': confidenceMax},
        'minimum_comparable_preferences': minimumComparablePreferences,
        'supported_preference_modes': supportedPreferenceModes,
        'inferred_preference_policy': inferredPreferencePolicy,
        'open_preference_policy': openPreferencePolicy,
        'missing_preference_policy': missingPreferencePolicy,
        'zero_effective_weight_policy': zeroEffectiveWeightPolicy,
        'version_compatibility_policy': versionCompatibilityPolicy,
        'complementarity_status': complementarityStatus,
        'persona_input_status': personaInputStatus,
        'ai_scoring_status': aiScoringStatus,
      });

  static PartnerPreferenceFitConfig parseJsonString(String text) =>
      PartnerPreferenceFitConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(text) as Map),
      );

  static PartnerPreferenceFitConfig loadFile(String path) =>
      parseJsonString(File(path).readAsStringSync());
}
