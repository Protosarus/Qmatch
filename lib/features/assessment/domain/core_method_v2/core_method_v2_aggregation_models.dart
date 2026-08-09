import 'dart:convert';

import 'compatibility_result_contracts.dart';
import 'core_method_v2_validation.dart';
import 'hard_constraint.dart';

/// Synthetic / resolved component input for aggregation (allows S_c = 0).
class CoreMethodComponentInput {
  final String componentId;
  final double? score;
  final double? confidence;
  final String sourceStatus;
  final String? sourceConfigVersion;
  final String? sourceRegistryVersion;
  final bool sourcePresent;
  final bool markedInvalid;
  final List<String> sourceDiagnosticCodes;

  const CoreMethodComponentInput({
    required this.componentId,
    required this.score,
    required this.confidence,
    required this.sourceStatus,
    required this.sourceConfigVersion,
    required this.sourceRegistryVersion,
    required this.sourcePresent,
    this.markedInvalid = false,
    this.sourceDiagnosticCodes = const [],
  });

  factory CoreMethodComponentInput.fromJson(Map<String, dynamic> j) =>
      CoreMethodComponentInput(
        componentId: j['component_id']?.toString() ?? '',
        score: (j['score'] as num?)?.toDouble(),
        confidence: (j['confidence'] as num?)?.toDouble(),
        sourceStatus: j['source_status']?.toString() ?? '',
        sourceConfigVersion: j['source_config_version']?.toString(),
        sourceRegistryVersion: j['source_registry_version']?.toString(),
        sourcePresent: j['source_present'] != false,
        markedInvalid: j['marked_invalid'] == true,
        sourceDiagnosticCodes: [
          for (final e in (j['source_diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'component_id': componentId,
        'score': score,
        'confidence': confidence,
        'source_status': sourceStatus,
        'source_config_version': sourceConfigVersion,
        'source_registry_version': sourceRegistryVersion,
        'source_present': sourcePresent,
        'marked_invalid': markedInvalid,
        'source_diagnostic_codes': sourceDiagnosticCodes,
      });
}

enum CoreMethodComponentInclusionStatus {
  included,
  excluded,
  invalid,
}

extension CoreMethodComponentInclusionStatusX
    on CoreMethodComponentInclusionStatus {
  String get wire {
    switch (this) {
      case CoreMethodComponentInclusionStatus.included:
        return 'included';
      case CoreMethodComponentInclusionStatus.excluded:
        return 'excluded';
      case CoreMethodComponentInclusionStatus.invalid:
        return 'invalid';
    }
  }
}

CoreMethodComponentInclusionStatus parseCoreMethodComponentInclusionStatus(
    String raw) {
  switch (raw) {
    case 'included':
      return CoreMethodComponentInclusionStatus.included;
    case 'excluded':
      return CoreMethodComponentInclusionStatus.excluded;
    case 'invalid':
      return CoreMethodComponentInclusionStatus.invalid;
    default:
      throw CoreMethodValidationException('unknown inclusion status', [
        CoreMethodValidationError(
          fieldPath: 'inclusion_status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

class CoreMethodComponentContribution {
  final String componentId;
  final double configuredWeight;
  final double? availableWeightNormalizationFactor;
  final double? normalizedAvailableWeight;
  final double? rawComponentScore;
  final double? componentEvidenceConfidence;
  final double? weightedRawContribution;
  final double? weightedConfidenceContribution;
  final String sourceStatus;
  final String? sourceConfigVersion;
  final String? sourceRegistryVersion;
  final CoreMethodComponentInclusionStatus inclusionStatus;
  final String? exclusionReason;
  final List<String> diagnosticCodes;

  CoreMethodComponentContribution({
    required this.componentId,
    required this.configuredWeight,
    required this.availableWeightNormalizationFactor,
    required this.normalizedAvailableWeight,
    required this.rawComponentScore,
    required this.componentEvidenceConfidence,
    required this.weightedRawContribution,
    required this.weightedConfidenceContribution,
    required this.sourceStatus,
    required this.sourceConfigVersion,
    required this.sourceRegistryVersion,
    required this.inclusionStatus,
    required this.exclusionReason,
    required this.diagnosticCodes,
  });

  factory CoreMethodComponentContribution.fromJson(Map<String, dynamic> j) =>
      CoreMethodComponentContribution(
        componentId: j['component_id']?.toString() ?? '',
        configuredWeight: (j['configured_weight'] as num).toDouble(),
        availableWeightNormalizationFactor:
            (j['available_weight_normalization_factor'] as num?)?.toDouble(),
        normalizedAvailableWeight:
            (j['normalized_available_weight'] as num?)?.toDouble(),
        rawComponentScore: (j['raw_component_score'] as num?)?.toDouble(),
        componentEvidenceConfidence:
            (j['component_evidence_confidence'] as num?)?.toDouble(),
        weightedRawContribution:
            (j['weighted_raw_contribution'] as num?)?.toDouble(),
        weightedConfidenceContribution:
            (j['weighted_confidence_contribution'] as num?)?.toDouble(),
        sourceStatus: j['source_status']?.toString() ?? '',
        sourceConfigVersion: j['source_config_version']?.toString(),
        sourceRegistryVersion: j['source_registry_version']?.toString(),
        inclusionStatus: parseCoreMethodComponentInclusionStatus(
          j['inclusion_status']?.toString() ?? '',
        ),
        exclusionReason: j['exclusion_reason']?.toString(),
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'component_id': componentId,
        'configured_weight': configuredWeight,
        'available_weight_normalization_factor':
            availableWeightNormalizationFactor,
        'normalized_available_weight': normalizedAvailableWeight,
        'raw_component_score': rawComponentScore,
        'component_evidence_confidence': componentEvidenceConfidence,
        'weighted_raw_contribution': weightedRawContribution,
        'weighted_confidence_contribution': weightedConfidenceContribution,
        'source_status': sourceStatus,
        'source_config_version': sourceConfigVersion,
        'source_registry_version': sourceRegistryVersion,
        'inclusion_status': inclusionStatus.wire,
        'exclusion_reason': exclusionReason,
        'diagnostic_codes': diagnosticCodes,
      });
}

class CoreMethodSoftConflictSummary {
  final int lowCount;
  final int moderateCount;
  final int highCount;
  final double? highestMutualSeverity;
  final List<String> affectedFieldIds;
  final List<String> diagnosticCodes;
  final bool softConflictPenaltyApplied;

  const CoreMethodSoftConflictSummary({
    required this.lowCount,
    required this.moderateCount,
    required this.highCount,
    required this.highestMutualSeverity,
    required this.affectedFieldIds,
    required this.diagnosticCodes,
    this.softConflictPenaltyApplied = false,
  });

  factory CoreMethodSoftConflictSummary.fromJson(Map<String, dynamic> j) =>
      CoreMethodSoftConflictSummary(
        lowCount: (j['low_count'] as num?)?.toInt() ?? 0,
        moderateCount: (j['moderate_count'] as num?)?.toInt() ?? 0,
        highCount: (j['high_count'] as num?)?.toInt() ?? 0,
        highestMutualSeverity:
            (j['highest_mutual_severity'] as num?)?.toDouble(),
        affectedFieldIds: [
          for (final e in (j['affected_field_ids'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        softConflictPenaltyApplied: j['soft_conflict_penalty_applied'] == true,
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'low_count': lowCount,
        'moderate_count': moderateCount,
        'high_count': highCount,
        'highest_mutual_severity': highestMutualSeverity,
        'affected_field_ids': affectedFieldIds,
        'diagnostic_codes': diagnosticCodes,
        'soft_conflict_penalty_applied': softConflictPenaltyApplied,
      });
}

class CoreMethodAsymmetrySummary {
  final double? preferenceDirectionalAsymmetry;
  final double? valueDirectionalAsymmetry;
  final List<String> diagnosticCodes;
  final bool asymmetryPenaltyApplied;

  const CoreMethodAsymmetrySummary({
    required this.preferenceDirectionalAsymmetry,
    required this.valueDirectionalAsymmetry,
    required this.diagnosticCodes,
    this.asymmetryPenaltyApplied = false,
  });

  factory CoreMethodAsymmetrySummary.fromJson(Map<String, dynamic> j) =>
      CoreMethodAsymmetrySummary(
        preferenceDirectionalAsymmetry:
            (j['preference_directional_asymmetry'] as num?)?.toDouble(),
        valueDirectionalAsymmetry:
            (j['value_directional_asymmetry'] as num?)?.toDouble(),
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        asymmetryPenaltyApplied: j['asymmetry_penalty_applied'] == true,
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'preference_directional_asymmetry': preferenceDirectionalAsymmetry,
        'value_directional_asymmetry': valueDirectionalAsymmetry,
        'diagnostic_codes': diagnosticCodes,
        'asymmetry_penalty_applied': asymmetryPenaltyApplied,
      });
}

class CoreMethodAggregationDiagnostics {
  final List<String> diagnosticCodes;
  final CoreMethodSoftConflictSummary softConflictSummary;
  final CoreMethodAsymmetrySummary asymmetrySummary;
  final List<String> missingComponentIds;
  final List<String> excludedComponentIds;
  final List<String> failedHardConstraintIds;
  final bool complementarityApplied;
  final bool temporalLayerApplied;
  final bool personaInputUsed;
  final bool frequencyTypeUsed;
  final bool aiScoringUsed;
  final bool softConflictPenaltyApplied;
  final bool asymmetryPenaltyApplied;

  const CoreMethodAggregationDiagnostics({
    required this.diagnosticCodes,
    required this.softConflictSummary,
    required this.asymmetrySummary,
    required this.missingComponentIds,
    required this.excludedComponentIds,
    required this.failedHardConstraintIds,
    this.complementarityApplied = false,
    this.temporalLayerApplied = false,
    this.personaInputUsed = false,
    this.frequencyTypeUsed = false,
    this.aiScoringUsed = false,
    this.softConflictPenaltyApplied = false,
    this.asymmetryPenaltyApplied = false,
  });

  factory CoreMethodAggregationDiagnostics.fromJson(Map<String, dynamic> j) =>
      CoreMethodAggregationDiagnostics(
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        softConflictSummary: CoreMethodSoftConflictSummary.fromJson(
          Map<String, dynamic>.from(j['soft_conflict_summary'] as Map? ?? {}),
        ),
        asymmetrySummary: CoreMethodAsymmetrySummary.fromJson(
          Map<String, dynamic>.from(j['asymmetry_summary'] as Map? ?? {}),
        ),
        missingComponentIds: [
          for (final e in (j['missing_component_ids'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        excludedComponentIds: [
          for (final e in (j['excluded_component_ids'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        failedHardConstraintIds: [
          for (final e
              in (j['failed_hard_constraint_ids'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        complementarityApplied: j['complementarity_applied'] == true,
        temporalLayerApplied: j['temporal_layer_applied'] == true,
        personaInputUsed: j['persona_input_used'] == true,
        frequencyTypeUsed: j['frequency_type_used'] == true,
        aiScoringUsed: j['ai_scoring_used'] == true,
        softConflictPenaltyApplied: j['soft_conflict_penalty_applied'] == true,
        asymmetryPenaltyApplied: j['asymmetry_penalty_applied'] == true,
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'diagnostic_codes': diagnosticCodes,
        'soft_conflict_summary': softConflictSummary.toJson(),
        'asymmetry_summary': asymmetrySummary.toJson(),
        'missing_component_ids': missingComponentIds,
        'excluded_component_ids': excludedComponentIds,
        'failed_hard_constraint_ids': failedHardConstraintIds,
        'complementarity_applied': complementarityApplied,
        'temporal_layer_applied': temporalLayerApplied,
        'persona_input_used': personaInputUsed,
        'frequency_type_used': frequencyTypeUsed,
        'ai_scoring_used': aiScoringUsed,
        'soft_conflict_penalty_applied': softConflictPenaltyApplied,
        'asymmetry_penalty_applied': asymmetryPenaltyApplied,
      });
}

class CoreMethodOverallScoreResult {
  final double? rawScore;
  final double? confidenceAdjustedScore;
  final double neutralScore;
  final double? overallEvidenceConfidence;
  final double? availableComponentMeanConfidence;
  final double availableConfiguredWeightMass;
  final int configuredComponentCount;
  final int availableComponentCount;
  final List<String> includedComponentIds;
  final List<CoreMethodComponentContribution> componentContributions;
  final HardConstraintOutcome hardConstraintOutcome;
  final bool mathematicallyAvailable;
  final bool internallyPublishableForReview;
  final bool productionPublishable;
  final bool publishable;
  final bool rankingEligible;
  final bool liveRankingEligible;
  final bool productionApproved;
  final CompatibilityEvaluationStatus evaluationStatus;
  final String configVersion;
  final String registryVersion;
  final DateTime? evaluationTimestamp;
  final String deterministicFingerprint;
  final List<String> diagnosticCodes;
  final CoreMethodAggregationDiagnostics diagnostics;

  CoreMethodOverallScoreResult({
    required this.rawScore,
    required this.confidenceAdjustedScore,
    required this.neutralScore,
    required this.overallEvidenceConfidence,
    required this.availableComponentMeanConfidence,
    required this.availableConfiguredWeightMass,
    required this.configuredComponentCount,
    required this.availableComponentCount,
    required this.includedComponentIds,
    required this.componentContributions,
    required this.hardConstraintOutcome,
    required this.mathematicallyAvailable,
    required this.internallyPublishableForReview,
    required this.productionPublishable,
    required this.publishable,
    required this.rankingEligible,
    required this.liveRankingEligible,
    required this.productionApproved,
    required this.evaluationStatus,
    required this.configVersion,
    required this.registryVersion,
    required this.evaluationTimestamp,
    required this.deterministicFingerprint,
    required this.diagnosticCodes,
    required this.diagnostics,
  }) {
    if (rawScore != null) {
      cmRequireFinite01(rawScore, 'rawScore', allowNull: false);
    }
    if (confidenceAdjustedScore != null) {
      cmRequireFinite01(
        confidenceAdjustedScore,
        'confidenceAdjustedScore',
        allowNull: false,
      );
    }
    if (evaluationStatus ==
        CompatibilityEvaluationStatus.blockedByHardConstraint) {
      cmRequire(
        rawScore == null && confidenceAdjustedScore == null,
        'rawScore',
        'fabricated_blocked_score',
        'blocked result must not fabricate an overall score',
      );
    }
    if (evaluationStatus ==
        CompatibilityEvaluationStatus.insufficientEvidence) {
      cmRequire(
        rawScore == null && confidenceAdjustedScore == null,
        'rawScore',
        'fabricated_insufficient_score',
        'insufficient evidence must not fabricate overall scores',
      );
    }
    cmRequire(!productionPublishable, 'productionPublishable', 'must_be_false',
        'offline-only');
    cmRequire(!productionApproved, 'productionApproved', 'must_be_false',
        'offline-only');
    cmRequire(
        !rankingEligible, 'rankingEligible', 'must_be_false', 'offline-only');
    cmRequire(!liveRankingEligible, 'liveRankingEligible', 'must_be_false',
        'offline-only');
  }

  factory CoreMethodOverallScoreResult.fromJson(Map<String, dynamic> j) =>
      CoreMethodOverallScoreResult(
        rawScore: (j['raw_score'] as num?)?.toDouble(),
        confidenceAdjustedScore:
            (j['confidence_adjusted_score'] as num?)?.toDouble(),
        neutralScore: (j['neutral_score'] as num).toDouble(),
        overallEvidenceConfidence:
            (j['overall_evidence_confidence'] as num?)?.toDouble(),
        availableComponentMeanConfidence:
            (j['available_component_mean_confidence'] as num?)?.toDouble(),
        availableConfiguredWeightMass:
            (j['available_configured_weight_mass'] as num).toDouble(),
        configuredComponentCount:
            (j['configured_component_count'] as num).toInt(),
        availableComponentCount:
            (j['available_component_count'] as num).toInt(),
        includedComponentIds: [
          for (final e in (j['included_component_ids'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        componentContributions: [
          for (final e in (j['component_contributions'] as List?) ?? const [])
            CoreMethodComponentContribution.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        hardConstraintOutcome: parseHardConstraintOutcome(
          j['hard_constraint_outcome']?.toString() ?? '',
        ),
        mathematicallyAvailable: j['mathematically_available'] == true,
        internallyPublishableForReview:
            j['internally_publishable_for_review'] == true,
        productionPublishable: j['production_publishable'] == true,
        publishable: j['publishable'] == true,
        rankingEligible: j['ranking_eligible'] == true,
        liveRankingEligible: j['live_ranking_eligible'] == true,
        productionApproved: j['production_approved'] == true,
        evaluationStatus: parseCompatibilityEvaluationStatus(
          j['evaluation_status']?.toString() ?? '',
        ),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
        evaluationTimestamp: j['evaluation_timestamp'] == null
            ? null
            : DateTime.parse(j['evaluation_timestamp'].toString()),
        deterministicFingerprint:
            j['deterministic_fingerprint']?.toString() ?? '',
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        diagnostics: CoreMethodAggregationDiagnostics.fromJson(
          Map<String, dynamic>.from(j['diagnostics'] as Map? ?? {}),
        ),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'raw_score': rawScore,
        'confidence_adjusted_score': confidenceAdjustedScore,
        'neutral_score': neutralScore,
        'overall_evidence_confidence': overallEvidenceConfidence,
        'available_component_mean_confidence': availableComponentMeanConfidence,
        'available_configured_weight_mass': availableConfiguredWeightMass,
        'configured_component_count': configuredComponentCount,
        'available_component_count': availableComponentCount,
        'included_component_ids': includedComponentIds,
        'component_contributions': [
          for (final c in componentContributions) c.toJson(),
        ],
        'hard_constraint_outcome': hardConstraintOutcome.wire,
        'mathematically_available': mathematicallyAvailable,
        'internally_publishable_for_review': internallyPublishableForReview,
        'production_publishable': productionPublishable,
        'publishable': publishable,
        'ranking_eligible': rankingEligible,
        'live_ranking_eligible': liveRankingEligible,
        'production_approved': productionApproved,
        'evaluation_status': evaluationStatus.wire,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'evaluation_timestamp': evaluationTimestamp?.toIso8601String(),
        'deterministic_fingerprint': deterministicFingerprint,
        'diagnostic_codes': diagnosticCodes,
        'diagnostics': diagnostics.toJson(),
      });
}

/// Full offline evaluation container. No persona / Frequency type / AI /
/// Firestore / production ranking fields.
class CoreMethodV2EvaluationResult {
  final Map<String, dynamic>? structuralProfileResultJson;
  final Map<String, dynamic>? mutualPreferenceResultJson;
  final Map<String, dynamic>? relationshipCompatibilityLayerResultJson;
  final CoreMethodOverallScoreResult overallScoreResult;
  final List<String> missingComponents;
  final CoreMethodSoftConflictSummary softConflictSummary;
  final CoreMethodAsymmetrySummary asymmetrySummary;
  final String aggregationConfigVersion;
  final String registryVersion;
  final DateTime? evaluationTimestamp;
  final String deterministicFingerprint;

  CoreMethodV2EvaluationResult({
    required this.structuralProfileResultJson,
    required this.mutualPreferenceResultJson,
    required this.relationshipCompatibilityLayerResultJson,
    required this.overallScoreResult,
    required this.missingComponents,
    required this.softConflictSummary,
    required this.asymmetrySummary,
    required this.aggregationConfigVersion,
    required this.registryVersion,
    required this.evaluationTimestamp,
    required this.deterministicFingerprint,
  });

  factory CoreMethodV2EvaluationResult.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic>? maybeMap(String key) {
      final raw = j[key];
      if (raw == null) return null;
      return Map<String, dynamic>.from(raw as Map);
    }

    return CoreMethodV2EvaluationResult(
      structuralProfileResultJson: maybeMap('structural_profile_result'),
      mutualPreferenceResultJson: maybeMap('mutual_preference_result'),
      relationshipCompatibilityLayerResultJson:
          maybeMap('relationship_compatibility_layer_result'),
      overallScoreResult: CoreMethodOverallScoreResult.fromJson(
        Map<String, dynamic>.from(j['overall_score_result'] as Map),
      ),
      missingComponents: [
        for (final e in (j['missing_components'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
      softConflictSummary: CoreMethodSoftConflictSummary.fromJson(
        Map<String, dynamic>.from(j['soft_conflict_summary'] as Map? ?? {}),
      ),
      asymmetrySummary: CoreMethodAsymmetrySummary.fromJson(
        Map<String, dynamic>.from(j['asymmetry_summary'] as Map? ?? {}),
      ),
      aggregationConfigVersion:
          j['aggregation_config_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      evaluationTimestamp: j['evaluation_timestamp'] == null
          ? null
          : DateTime.parse(j['evaluation_timestamp'].toString()),
      deterministicFingerprint:
          j['deterministic_fingerprint']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'structural_profile_result': structuralProfileResultJson,
        'mutual_preference_result': mutualPreferenceResultJson,
        'relationship_compatibility_layer_result':
            relationshipCompatibilityLayerResultJson,
        'overall_score_result': overallScoreResult.toJson(),
        'missing_components': missingComponents,
        'soft_conflict_summary': softConflictSummary.toJson(),
        'asymmetry_summary': asymmetrySummary.toJson(),
        'aggregation_config_version': aggregationConfigVersion,
        'registry_version': registryVersion,
        'evaluation_timestamp': evaluationTimestamp?.toIso8601String(),
        'deterministic_fingerprint': deterministicFingerprint,
      });

  static String fingerprintOf(Map<String, dynamic> json) {
    final overall = Map<String, dynamic>.from(
      (json['overall_score_result'] as Map?) ?? {},
    );
    overall['deterministic_fingerprint'] = null;
    final encoded = jsonEncode(cmSortedMap({
      ...json,
      'deterministic_fingerprint': null,
      'overall_score_result': overall,
    }));
    var hash = 0xcbf29ce484222325;
    for (final unit in encoded.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
