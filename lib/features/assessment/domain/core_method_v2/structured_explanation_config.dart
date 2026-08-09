import 'dart:convert';
import 'dart:io';

import 'core_method_v2_validation.dart';

class StructuredExplanationConfig {
  final String configId;
  final String configVersion;
  final String registryVersion;
  final String status;
  final String calibrationStatus;
  final String runtimeStatus;
  final String productionApprovalStatus;
  final bool scientificallyValidated;
  final int maximumTotalSignals;
  final int maximumSignalsPerCategory;
  final int maximumSignalsPerModule;
  final double minimumSignalConfidence;
  final double highConfidenceThreshold;
  final double moderateConfidenceThreshold;
  final double structuralCloseThreshold;
  final double structuralDifferenceThreshold;
  final double preferenceStrongFitThreshold;
  final double preferenceWeakFitThreshold;
  final double valueStrongFitThreshold;
  final double valueWeakFitThreshold;
  final double asymmetryReportingThreshold;
  final double scoreDifferenceTolerance;
  final List<String> softConflictReportingBands;
  final String missingEvidenceReportingPolicy;
  final String hardConstraintReportingPolicy;
  final String confidenceAdjustmentReportingPolicy;
  final String deduplicationPolicy;
  final String diversityPolicy;
  final String tieBreakingPolicy;
  final String localizationMode;
  final String aiGenerationStatus;
  final String personaInputStatus;
  final String frequencyTypeStatus;
  final String complementarityStatus;
  final String versionCompatibilityPolicy;
  final List<String> categoryPriority;
  final List<String> sourceComponentOrder;

  StructuredExplanationConfig({
    required this.configId,
    required this.configVersion,
    required this.registryVersion,
    required this.status,
    required this.calibrationStatus,
    required this.runtimeStatus,
    required this.productionApprovalStatus,
    required this.scientificallyValidated,
    required this.maximumTotalSignals,
    required this.maximumSignalsPerCategory,
    required this.maximumSignalsPerModule,
    required this.minimumSignalConfidence,
    required this.highConfidenceThreshold,
    required this.moderateConfidenceThreshold,
    required this.structuralCloseThreshold,
    required this.structuralDifferenceThreshold,
    required this.preferenceStrongFitThreshold,
    required this.preferenceWeakFitThreshold,
    required this.valueStrongFitThreshold,
    required this.valueWeakFitThreshold,
    required this.asymmetryReportingThreshold,
    required this.scoreDifferenceTolerance,
    required this.softConflictReportingBands,
    required this.missingEvidenceReportingPolicy,
    required this.hardConstraintReportingPolicy,
    required this.confidenceAdjustmentReportingPolicy,
    required this.deduplicationPolicy,
    required this.diversityPolicy,
    required this.tieBreakingPolicy,
    required this.localizationMode,
    required this.aiGenerationStatus,
    required this.personaInputStatus,
    required this.frequencyTypeStatus,
    required this.complementarityStatus,
    required this.versionCompatibilityPolicy,
    required this.categoryPriority,
    required this.sourceComponentOrder,
  }) {
    validate();
  }

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
        'must_be_false', 'false');
    cmRequire(localizationMode == 'structured_code_and_parameters',
        'localization_mode', 'unexpected', localizationMode);
    cmRequire(aiGenerationStatus == 'prohibited', 'ai_generation_status',
        'must_be_prohibited', aiGenerationStatus);
    cmRequire(personaInputStatus == 'prohibited', 'persona_input_status',
        'must_be_prohibited', personaInputStatus);
    cmRequire(frequencyTypeStatus == 'prohibited', 'frequency_type_status',
        'must_be_prohibited', frequencyTypeStatus);
    cmRequire(complementarityStatus == 'disabled', 'complementarity_status',
        'must_be_disabled', complementarityStatus);
    cmRequire(maximumTotalSignals >= 1, 'maximum_total_signals', 'invalid',
        '$maximumTotalSignals');
    cmRequire(maximumSignalsPerCategory >= 1, 'maximum_signals_per_category',
        'invalid', '$maximumSignalsPerCategory');
    cmRequire(maximumSignalsPerModule >= 1, 'maximum_signals_per_module',
        'invalid', '$maximumSignalsPerModule');
    cmRequireFinite01(minimumSignalConfidence, 'minimum_signal_confidence',
        allowNull: false);
    cmRequireFinite01(highConfidenceThreshold, 'high_confidence_threshold',
        allowNull: false);
    cmRequireFinite01(
        moderateConfidenceThreshold, 'moderate_confidence_threshold',
        allowNull: false);
    cmRequire(
      highConfidenceThreshold >= moderateConfidenceThreshold,
      'high_confidence_threshold',
      'ordering',
      'high must be >= moderate',
    );
    cmRequire(categoryPriority.isNotEmpty, 'category_priority', 'empty', '');
    cmRequire(
        sourceComponentOrder.isNotEmpty, 'source_component_order', 'empty', '');
  }

  String confidenceBand(double? q) {
    if (q == null || !q.isFinite || q <= 0) return 'unavailable';
    if (q >= highConfidenceThreshold) return 'high';
    if (q >= moderateConfidenceThreshold) return 'moderate';
    return 'low';
  }

  factory StructuredExplanationConfig.fromJson(Map<String, dynamic> j) =>
      StructuredExplanationConfig(
        configId: j['config_id']?.toString() ?? '',
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        calibrationStatus: j['calibration_status']?.toString() ?? '',
        runtimeStatus: j['runtime_status']?.toString() ?? '',
        productionApprovalStatus:
            j['production_approval_status']?.toString() ?? '',
        scientificallyValidated: j['scientifically_validated'] == true,
        maximumTotalSignals: (j['maximum_total_signals'] as num).toInt(),
        maximumSignalsPerCategory:
            (j['maximum_signals_per_category'] as num).toInt(),
        maximumSignalsPerModule:
            (j['maximum_signals_per_module'] as num).toInt(),
        minimumSignalConfidence:
            (j['minimum_signal_confidence'] as num).toDouble(),
        highConfidenceThreshold:
            (j['high_confidence_threshold'] as num).toDouble(),
        moderateConfidenceThreshold:
            (j['moderate_confidence_threshold'] as num).toDouble(),
        structuralCloseThreshold:
            (j['structural_close_threshold'] as num).toDouble(),
        structuralDifferenceThreshold:
            (j['structural_difference_threshold'] as num).toDouble(),
        preferenceStrongFitThreshold:
            (j['preference_strong_fit_threshold'] as num).toDouble(),
        preferenceWeakFitThreshold:
            (j['preference_weak_fit_threshold'] as num).toDouble(),
        valueStrongFitThreshold:
            (j['value_strong_fit_threshold'] as num).toDouble(),
        valueWeakFitThreshold:
            (j['value_weak_fit_threshold'] as num).toDouble(),
        asymmetryReportingThreshold:
            (j['asymmetry_reporting_threshold'] as num).toDouble(),
        scoreDifferenceTolerance:
            (j['score_difference_tolerance'] as num).toDouble(),
        softConflictReportingBands: [
          for (final e
              in (j['soft_conflict_reporting_bands'] as List?) ?? const [])
            e.toString(),
        ],
        missingEvidenceReportingPolicy:
            j['missing_evidence_reporting_policy']?.toString() ?? '',
        hardConstraintReportingPolicy:
            j['hard_constraint_reporting_policy']?.toString() ?? '',
        confidenceAdjustmentReportingPolicy:
            j['confidence_adjustment_reporting_policy']?.toString() ?? '',
        deduplicationPolicy: j['deduplication_policy']?.toString() ?? '',
        diversityPolicy: j['diversity_policy']?.toString() ?? '',
        tieBreakingPolicy: j['tie_breaking_policy']?.toString() ?? '',
        localizationMode: j['localization_mode']?.toString() ?? '',
        aiGenerationStatus: j['ai_generation_status']?.toString() ?? '',
        personaInputStatus: j['persona_input_status']?.toString() ?? '',
        frequencyTypeStatus: j['frequency_type_status']?.toString() ?? '',
        complementarityStatus: j['complementarity_status']?.toString() ?? '',
        versionCompatibilityPolicy:
            j['version_compatibility_policy']?.toString() ?? '',
        categoryPriority: [
          for (final e in (j['category_priority'] as List?) ?? const [])
            e.toString(),
        ],
        sourceComponentOrder: [
          for (final e in (j['source_component_order'] as List?) ?? const [])
            e.toString(),
        ],
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'config_id': configId,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'status': status,
        'calibration_status': calibrationStatus,
        'runtime_status': runtimeStatus,
        'production_approval_status': productionApprovalStatus,
        'scientifically_validated': scientificallyValidated,
        'maximum_total_signals': maximumTotalSignals,
        'maximum_signals_per_category': maximumSignalsPerCategory,
        'maximum_signals_per_module': maximumSignalsPerModule,
        'minimum_signal_confidence': minimumSignalConfidence,
        'high_confidence_threshold': highConfidenceThreshold,
        'moderate_confidence_threshold': moderateConfidenceThreshold,
        'structural_close_threshold': structuralCloseThreshold,
        'structural_difference_threshold': structuralDifferenceThreshold,
        'preference_strong_fit_threshold': preferenceStrongFitThreshold,
        'preference_weak_fit_threshold': preferenceWeakFitThreshold,
        'value_strong_fit_threshold': valueStrongFitThreshold,
        'value_weak_fit_threshold': valueWeakFitThreshold,
        'asymmetry_reporting_threshold': asymmetryReportingThreshold,
        'score_difference_tolerance': scoreDifferenceTolerance,
        'soft_conflict_reporting_bands': softConflictReportingBands,
        'missing_evidence_reporting_policy': missingEvidenceReportingPolicy,
        'hard_constraint_reporting_policy': hardConstraintReportingPolicy,
        'confidence_adjustment_reporting_policy':
            confidenceAdjustmentReportingPolicy,
        'deduplication_policy': deduplicationPolicy,
        'diversity_policy': diversityPolicy,
        'tie_breaking_policy': tieBreakingPolicy,
        'localization_mode': localizationMode,
        'ai_generation_status': aiGenerationStatus,
        'persona_input_status': personaInputStatus,
        'frequency_type_status': frequencyTypeStatus,
        'complementarity_status': complementarityStatus,
        'version_compatibility_policy': versionCompatibilityPolicy,
        'category_priority': categoryPriority,
        'source_component_order': sourceComponentOrder,
      });

  static StructuredExplanationConfig loadFile(String path) =>
      StructuredExplanationConfig.fromJson(
        Map<String, dynamic>.from(
            jsonDecode(File(path).readAsStringSync()) as Map),
      );
}

class StructuredExplanationCodeDefinition {
  final String explanationCode;
  final String category;
  final String polarity;
  final String defaultLocalizationKey;
  final List<String> allowedSourceTypes;
  final List<String> requiredParameters;
  final List<String> optionalParameters;
  final bool blockingEligibility;
  final String privacyLevel;
  final String productionStatus;
  final String description;
  final List<String> prohibitedInterpretations;

  const StructuredExplanationCodeDefinition({
    required this.explanationCode,
    required this.category,
    required this.polarity,
    required this.defaultLocalizationKey,
    required this.allowedSourceTypes,
    required this.requiredParameters,
    required this.optionalParameters,
    required this.blockingEligibility,
    required this.privacyLevel,
    required this.productionStatus,
    required this.description,
    required this.prohibitedInterpretations,
  });

  factory StructuredExplanationCodeDefinition.fromJson(
          Map<String, dynamic> j) =>
      StructuredExplanationCodeDefinition(
        explanationCode: j['explanation_code']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        polarity: j['polarity']?.toString() ?? '',
        defaultLocalizationKey: j['default_localization_key']?.toString() ?? '',
        allowedSourceTypes: [
          for (final e in (j['allowed_source_types'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        requiredParameters: [
          for (final e in (j['required_parameters'] as List?) ?? const [])
            e.toString(),
        ],
        optionalParameters: [
          for (final e in (j['optional_parameters'] as List?) ?? const [])
            e.toString(),
        ],
        blockingEligibility: j['blocking_eligibility'] == true,
        privacyLevel: j['privacy_level']?.toString() ?? '',
        productionStatus: j['production_status']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        prohibitedInterpretations: [
          for (final e
              in (j['prohibited_interpretations'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'explanation_code': explanationCode,
        'category': category,
        'polarity': polarity,
        'default_localization_key': defaultLocalizationKey,
        'allowed_source_types': allowedSourceTypes,
        'required_parameters': requiredParameters,
        'optional_parameters': optionalParameters,
        'blocking_eligibility': blockingEligibility,
        'privacy_level': privacyLevel,
        'production_status': productionStatus,
        'description': description,
        'prohibited_interpretations': prohibitedInterpretations,
      });
}

class StructuredExplanationCodeRegistry {
  final String registryId;
  final String registryVersion;
  final String canonicalDimensionRegistryVersion;
  final String status;
  final String productionApprovalStatus;
  final Map<String, StructuredExplanationCodeDefinition> codesById;

  StructuredExplanationCodeRegistry({
    required this.registryId,
    required this.registryVersion,
    required this.canonicalDimensionRegistryVersion,
    required this.status,
    required this.productionApprovalStatus,
    required this.codesById,
  }) {
    cmRequire(status == 'provisional', 'status', 'must_be_provisional', status);
    cmRequire(
        productionApprovalStatus == 'not_approved',
        'production_approval_status',
        'must_be_not_approved',
        productionApprovalStatus);
    cmRequire(codesById.isNotEmpty, 'codes', 'empty', '');
    for (final c in codesById.values) {
      cmRequire(c.defaultLocalizationKey.isNotEmpty, c.explanationCode,
          'missing_localization_key', '');
    }
  }

  StructuredExplanationCodeDefinition require(String code) {
    final c = codesById[code];
    cmRequire(c != null, 'explanation_code', 'unknown_code', code);
    return c!;
  }

  factory StructuredExplanationCodeRegistry.fromJson(Map<String, dynamic> j) {
    final list = [
      for (final e in (j['codes'] as List?) ?? const [])
        StructuredExplanationCodeDefinition.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
    ];
    list.sort((a, b) => a.explanationCode.compareTo(b.explanationCode));
    return StructuredExplanationCodeRegistry(
      registryId: j['registry_id']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      canonicalDimensionRegistryVersion:
          j['canonical_dimension_registry_version']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      productionApprovalStatus:
          j['production_approval_status']?.toString() ?? '',
      codesById: {for (final c in list) c.explanationCode: c},
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'registry_id': registryId,
        'registry_version': registryVersion,
        'canonical_dimension_registry_version':
            canonicalDimensionRegistryVersion,
        'status': status,
        'production_approval_status': productionApprovalStatus,
        'codes': [
          for (final k in (codesById.keys.toList()..sort()))
            codesById[k]!.toJson(),
        ],
      });

  static StructuredExplanationCodeRegistry loadFile(String path) =>
      StructuredExplanationCodeRegistry.fromJson(
        Map<String, dynamic>.from(
            jsonDecode(File(path).readAsStringSync()) as Map),
      );
}
