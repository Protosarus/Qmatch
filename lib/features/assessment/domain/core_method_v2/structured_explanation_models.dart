import 'dart:convert';

import 'compatibility_result_contracts.dart';
import 'core_method_v2_validation.dart';

class StructuredExplanationParameter {
  final String name;
  final String type;
  final Object? value;

  const StructuredExplanationParameter({
    required this.name,
    required this.type,
    required this.value,
  });

  factory StructuredExplanationParameter.fromJson(Map<String, dynamic> j) =>
      StructuredExplanationParameter(
        name: j['name']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        value: j['value'],
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'name': name,
        'type': type,
        'value': value,
      });
}

class StructuredExplanationEvidenceReference {
  final String sourceResultType;
  final String? sourceResultFingerprint;
  final String sourcePath;
  final Map<String, double?> relevantNumericFields;
  final String sourceStatus;
  final String? sourceConfigVersion;

  const StructuredExplanationEvidenceReference({
    required this.sourceResultType,
    required this.sourceResultFingerprint,
    required this.sourcePath,
    required this.relevantNumericFields,
    required this.sourceStatus,
    required this.sourceConfigVersion,
  });

  factory StructuredExplanationEvidenceReference.fromJson(
          Map<String, dynamic> j) =>
      StructuredExplanationEvidenceReference(
        sourceResultType: j['source_result_type']?.toString() ?? '',
        sourceResultFingerprint: j['source_result_fingerprint']?.toString(),
        sourcePath: j['source_path']?.toString() ?? '',
        relevantNumericFields: {
          for (final e
              in ((j['relevant_numeric_fields'] as Map?) ?? const {}).entries)
            e.key.toString(): (e.value as num?)?.toDouble(),
        },
        sourceStatus: j['source_status']?.toString() ?? '',
        sourceConfigVersion: j['source_config_version']?.toString(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'source_result_type': sourceResultType,
        'source_result_fingerprint': sourceResultFingerprint,
        'source_path': sourcePath,
        'relevant_numeric_fields': {
          for (final k in (relevantNumericFields.keys.toList()..sort()))
            k: relevantNumericFields[k],
        },
        'source_status': sourceStatus,
        'source_config_version': sourceConfigVersion,
      });
}

class StructuredCompatibilityExplanationSignal {
  final String signalId;
  final String explanationCode;
  final String category;
  final String polarity;
  final String sourceType;
  final String sourceComponentId;
  final String? dimensionId;
  final String? fieldId;
  final String? module;
  final String? direction;
  final double salienceScore;
  final double? evidenceConfidence;
  final String confidenceBand;
  final double? magnitude;
  final int rank;
  final String localizationKey;
  final List<StructuredExplanationParameter> localizationParameters;
  final List<StructuredExplanationEvidenceReference> evidenceReferences;
  final List<String> diagnosticCodes;
  final bool blocking;
  final bool displayEligible;
  final bool productionEligible;
  final String configVersion;
  final String registryVersion;

  StructuredCompatibilityExplanationSignal({
    required this.signalId,
    required this.explanationCode,
    required this.category,
    required this.polarity,
    required this.sourceType,
    required this.sourceComponentId,
    required this.dimensionId,
    required this.fieldId,
    required this.module,
    required this.direction,
    required this.salienceScore,
    required this.evidenceConfidence,
    required this.confidenceBand,
    required this.magnitude,
    required this.rank,
    required this.localizationKey,
    required this.localizationParameters,
    required this.evidenceReferences,
    required this.diagnosticCodes,
    required this.blocking,
    required this.displayEligible,
    required this.productionEligible,
    required this.configVersion,
    required this.registryVersion,
  }) {
    cmRequire(salienceScore.isFinite, 'salienceScore', 'non_finite',
        '$salienceScore');
    cmRequire(salienceScore >= 0 && salienceScore <= 1, 'salienceScore',
        'out_of_range', '$salienceScore');
    if (evidenceConfidence != null) {
      cmRequireFinite01(evidenceConfidence, 'evidenceConfidence',
          allowNull: false);
    }
    cmRequire(!productionEligible, 'productionEligible', 'must_be_false',
        'offline-only');
  }

  factory StructuredCompatibilityExplanationSignal.fromJson(
          Map<String, dynamic> j) =>
      StructuredCompatibilityExplanationSignal(
        signalId: j['signal_id']?.toString() ?? '',
        explanationCode: j['explanation_code']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        polarity: j['polarity']?.toString() ?? '',
        sourceType: j['source_type']?.toString() ?? '',
        sourceComponentId: j['source_component_id']?.toString() ?? '',
        dimensionId: j['dimension_id']?.toString(),
        fieldId: j['field_id']?.toString(),
        module: j['module']?.toString(),
        direction: j['direction']?.toString(),
        salienceScore: (j['salience_score'] as num).toDouble(),
        evidenceConfidence: (j['evidence_confidence'] as num?)?.toDouble(),
        confidenceBand: j['confidence_band']?.toString() ?? '',
        magnitude: (j['magnitude'] as num?)?.toDouble(),
        rank: (j['rank'] as num).toInt(),
        localizationKey: j['localization_key']?.toString() ?? '',
        localizationParameters: [
          for (final e in (j['localization_parameters'] as List?) ?? const [])
            StructuredExplanationParameter.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        evidenceReferences: [
          for (final e in (j['evidence_references'] as List?) ?? const [])
            StructuredExplanationEvidenceReference.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        blocking: j['blocking'] == true,
        displayEligible: j['display_eligible'] != false,
        productionEligible: j['production_eligible'] == true,
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'signal_id': signalId,
        'explanation_code': explanationCode,
        'category': category,
        'polarity': polarity,
        'source_type': sourceType,
        'source_component_id': sourceComponentId,
        'dimension_id': dimensionId,
        'field_id': fieldId,
        'module': module,
        'direction': direction,
        'salience_score': salienceScore,
        'evidence_confidence': evidenceConfidence,
        'confidence_band': confidenceBand,
        'magnitude': magnitude,
        'rank': rank,
        'localization_key': localizationKey,
        'localization_parameters': [
          for (final p in localizationParameters) p.toJson(),
        ],
        'evidence_references': [
          for (final r in evidenceReferences) r.toJson(),
        ],
        'diagnostic_codes': diagnosticCodes,
        'blocking': blocking,
        'display_eligible': displayEligible,
        'production_eligible': productionEligible,
        'config_version': configVersion,
        'registry_version': registryVersion,
      });
}

class StructuredExplanationCoverage {
  final int availableAggregationComponentsExplained;
  final int totalAvailableAggregationComponents;
  final int includedHighSalienceSourceSignals;
  final int omittedEligibleSignals;
  final int sourceExclusionsRepresented;
  final int missingComponentsRepresented;

  const StructuredExplanationCoverage({
    required this.availableAggregationComponentsExplained,
    required this.totalAvailableAggregationComponents,
    required this.includedHighSalienceSourceSignals,
    required this.omittedEligibleSignals,
    required this.sourceExclusionsRepresented,
    required this.missingComponentsRepresented,
  });

  factory StructuredExplanationCoverage.fromJson(Map<String, dynamic> j) =>
      StructuredExplanationCoverage(
        availableAggregationComponentsExplained:
            (j['available_aggregation_components_explained'] as num?)
                    ?.toInt() ??
                0,
        totalAvailableAggregationComponents:
            (j['total_available_aggregation_components'] as num?)?.toInt() ?? 0,
        includedHighSalienceSourceSignals:
            (j['included_high_salience_source_signals'] as num?)?.toInt() ?? 0,
        omittedEligibleSignals:
            (j['omitted_eligible_signals'] as num?)?.toInt() ?? 0,
        sourceExclusionsRepresented:
            (j['source_exclusions_represented'] as num?)?.toInt() ?? 0,
        missingComponentsRepresented:
            (j['missing_components_represented'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'available_aggregation_components_explained':
            availableAggregationComponentsExplained,
        'total_available_aggregation_components':
            totalAvailableAggregationComponents,
        'included_high_salience_source_signals':
            includedHighSalienceSourceSignals,
        'omitted_eligible_signals': omittedEligibleSignals,
        'source_exclusions_represented': sourceExclusionsRepresented,
        'missing_components_represented': missingComponentsRepresented,
      });
}

class StructuredExplanationDiagnostics {
  final List<String> diagnosticCodes;
  final bool scoreModified;
  final bool softConflictPenaltyApplied;
  final bool asymmetryPenaltyApplied;
  final bool complementarityApplied;
  final bool aiGenerated;
  final bool personaInputUsed;
  final bool frequencyTypeUsed;
  final List<String> privacyDiagnostics;

  const StructuredExplanationDiagnostics({
    required this.diagnosticCodes,
    this.scoreModified = false,
    this.softConflictPenaltyApplied = false,
    this.asymmetryPenaltyApplied = false,
    this.complementarityApplied = false,
    this.aiGenerated = false,
    this.personaInputUsed = false,
    this.frequencyTypeUsed = false,
    this.privacyDiagnostics = const [],
  });

  factory StructuredExplanationDiagnostics.fromJson(Map<String, dynamic> j) =>
      StructuredExplanationDiagnostics(
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        scoreModified: j['score_modified'] == true,
        softConflictPenaltyApplied: j['soft_conflict_penalty_applied'] == true,
        asymmetryPenaltyApplied: j['asymmetry_penalty_applied'] == true,
        complementarityApplied: j['complementarity_applied'] == true,
        aiGenerated: j['ai_generated'] == true,
        personaInputUsed: j['persona_input_used'] == true,
        frequencyTypeUsed: j['frequency_type_used'] == true,
        privacyDiagnostics: [
          for (final e in (j['privacy_diagnostics'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'diagnostic_codes': diagnosticCodes,
        'score_modified': scoreModified,
        'soft_conflict_penalty_applied': softConflictPenaltyApplied,
        'asymmetry_penalty_applied': asymmetryPenaltyApplied,
        'complementarity_applied': complementarityApplied,
        'ai_generated': aiGenerated,
        'persona_input_used': personaInputUsed,
        'frequency_type_used': frequencyTypeUsed,
        'privacy_diagnostics': privacyDiagnostics,
      });
}

class StructuredExplanationSummary {
  final int totalSignals;
  final int supportiveCount;
  final int cautionaryCount;
  final int blockingCount;
  final int evidenceLimitationCount;
  final List<String> topExplanationCodes;

  const StructuredExplanationSummary({
    required this.totalSignals,
    required this.supportiveCount,
    required this.cautionaryCount,
    required this.blockingCount,
    required this.evidenceLimitationCount,
    required this.topExplanationCodes,
  });

  factory StructuredExplanationSummary.fromJson(Map<String, dynamic> j) =>
      StructuredExplanationSummary(
        totalSignals: (j['total_signals'] as num?)?.toInt() ?? 0,
        supportiveCount: (j['supportive_count'] as num?)?.toInt() ?? 0,
        cautionaryCount: (j['cautionary_count'] as num?)?.toInt() ?? 0,
        blockingCount: (j['blocking_count'] as num?)?.toInt() ?? 0,
        evidenceLimitationCount:
            (j['evidence_limitation_count'] as num?)?.toInt() ?? 0,
        topExplanationCodes: [
          for (final e in (j['top_explanation_codes'] as List?) ?? const [])
            e.toString(),
        ],
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'total_signals': totalSignals,
        'supportive_count': supportiveCount,
        'cautionary_count': cautionaryCount,
        'blocking_count': blockingCount,
        'evidence_limitation_count': evidenceLimitationCount,
        'top_explanation_codes': topExplanationCodes,
      });
}

class StructuredCompatibilityExplanationResult {
  final CompatibilityEvaluationStatus evaluationStatus;
  final double? overallRawScore;
  final double? confidenceAdjustedScore;
  final double? overallEvidenceConfidence;
  final List<StructuredCompatibilityExplanationSignal> signals;
  final List<StructuredCompatibilityExplanationSignal> supportiveSignals;
  final List<StructuredCompatibilityExplanationSignal> cautionarySignals;
  final List<StructuredCompatibilityExplanationSignal> blockingSignals;
  final List<StructuredCompatibilityExplanationSignal>
      evidenceLimitationSignals;
  final int omittedSignalCount;
  final List<String> missingSourceComponents;
  final StructuredExplanationCoverage explanationCoverage;
  final StructuredExplanationSummary summary;
  final String deterministicFingerprint;
  final StructuredExplanationDiagnostics diagnostics;
  final String configVersion;
  final String registryVersion;
  final DateTime? generatedAt;

  StructuredCompatibilityExplanationResult({
    required this.evaluationStatus,
    required this.overallRawScore,
    required this.confidenceAdjustedScore,
    required this.overallEvidenceConfidence,
    required this.signals,
    required this.supportiveSignals,
    required this.cautionarySignals,
    required this.blockingSignals,
    required this.evidenceLimitationSignals,
    required this.omittedSignalCount,
    required this.missingSourceComponents,
    required this.explanationCoverage,
    required this.summary,
    required this.deterministicFingerprint,
    required this.diagnostics,
    required this.configVersion,
    required this.registryVersion,
    required this.generatedAt,
  }) {
    cmRequire(!diagnostics.scoreModified, 'diagnostics.scoreModified',
        'must_be_false', 'explanation must not modify scores');
    cmRequire(!diagnostics.aiGenerated, 'diagnostics.aiGenerated',
        'must_be_false', 'AI prohibited');
    cmRequire(!diagnostics.personaInputUsed, 'diagnostics.personaInputUsed',
        'must_be_false', 'persona prohibited');
    cmRequire(!diagnostics.frequencyTypeUsed, 'diagnostics.frequencyTypeUsed',
        'must_be_false', 'Frequency type prohibited');
  }

  factory StructuredCompatibilityExplanationResult.fromJson(
          Map<String, dynamic> j) =>
      StructuredCompatibilityExplanationResult(
        evaluationStatus: parseCompatibilityEvaluationStatus(
          j['evaluation_status']?.toString() ?? '',
        ),
        overallRawScore: (j['overall_raw_score'] as num?)?.toDouble(),
        confidenceAdjustedScore:
            (j['confidence_adjusted_score'] as num?)?.toDouble(),
        overallEvidenceConfidence:
            (j['overall_evidence_confidence'] as num?)?.toDouble(),
        signals: [
          for (final e in (j['signals'] as List?) ?? const [])
            StructuredCompatibilityExplanationSignal.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        supportiveSignals: [
          for (final e in (j['supportive_signals'] as List?) ?? const [])
            StructuredCompatibilityExplanationSignal.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        cautionarySignals: [
          for (final e in (j['cautionary_signals'] as List?) ?? const [])
            StructuredCompatibilityExplanationSignal.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        blockingSignals: [
          for (final e in (j['blocking_signals'] as List?) ?? const [])
            StructuredCompatibilityExplanationSignal.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        evidenceLimitationSignals: [
          for (final e
              in (j['evidence_limitation_signals'] as List?) ?? const [])
            StructuredCompatibilityExplanationSignal.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        omittedSignalCount: (j['omitted_signal_count'] as num?)?.toInt() ?? 0,
        missingSourceComponents: [
          for (final e in (j['missing_source_components'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        explanationCoverage: StructuredExplanationCoverage.fromJson(
          Map<String, dynamic>.from(j['explanation_coverage'] as Map? ?? {}),
        ),
        summary: StructuredExplanationSummary.fromJson(
          Map<String, dynamic>.from(j['summary'] as Map? ?? {}),
        ),
        deterministicFingerprint:
            j['deterministic_fingerprint']?.toString() ?? '',
        diagnostics: StructuredExplanationDiagnostics.fromJson(
          Map<String, dynamic>.from(j['diagnostics'] as Map? ?? {}),
        ),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
        generatedAt: j['generated_at'] == null
            ? null
            : DateTime.parse(j['generated_at'].toString()),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'evaluation_status': evaluationStatus.wire,
        'overall_raw_score': overallRawScore,
        'confidence_adjusted_score': confidenceAdjustedScore,
        'overall_evidence_confidence': overallEvidenceConfidence,
        'signals': [for (final s in signals) s.toJson()],
        'supportive_signals': [for (final s in supportiveSignals) s.toJson()],
        'cautionary_signals': [for (final s in cautionarySignals) s.toJson()],
        'blocking_signals': [for (final s in blockingSignals) s.toJson()],
        'evidence_limitation_signals': [
          for (final s in evidenceLimitationSignals) s.toJson(),
        ],
        'omitted_signal_count': omittedSignalCount,
        'missing_source_components': missingSourceComponents,
        'explanation_coverage': explanationCoverage.toJson(),
        'summary': summary.toJson(),
        'deterministic_fingerprint': deterministicFingerprint,
        'diagnostics': diagnostics.toJson(),
        'config_version': configVersion,
        'registry_version': registryVersion,
        'generated_at': generatedAt?.toIso8601String(),
      });

  static String fingerprintOf(Map<String, dynamic> json) {
    final encoded = jsonEncode(cmSortedMap({
      ...json,
      'deterministic_fingerprint': null,
    }));
    var hash = 0xcbf29ce484222325;
    for (final unit in encoded.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
