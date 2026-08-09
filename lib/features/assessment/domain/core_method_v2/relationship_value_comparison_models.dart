import 'core_method_v2_validation.dart';

enum DirectionalRelationshipValueStatus {
  complete,
  partial,
  insufficientEvidence,
  invalidInput,
}

DirectionalRelationshipValueStatus parseDirectionalRelationshipValueStatus(
    String raw) {
  switch (raw) {
    case 'complete':
      return DirectionalRelationshipValueStatus.complete;
    case 'partial':
      return DirectionalRelationshipValueStatus.partial;
    case 'insufficient_evidence':
      return DirectionalRelationshipValueStatus.insufficientEvidence;
    case 'invalid_input':
      return DirectionalRelationshipValueStatus.invalidInput;
    default:
      throw CoreMethodValidationException('unknown value status', [
        CoreMethodValidationError(
          fieldPath: 'status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

extension DirectionalRelationshipValueStatusX
    on DirectionalRelationshipValueStatus {
  String get wire {
    switch (this) {
      case DirectionalRelationshipValueStatus.complete:
        return 'complete';
      case DirectionalRelationshipValueStatus.partial:
        return 'partial';
      case DirectionalRelationshipValueStatus.insufficientEvidence:
        return 'insufficient_evidence';
      case DirectionalRelationshipValueStatus.invalidInput:
        return 'invalid_input';
    }
  }
}

enum MutualRelationshipValueStatus {
  complete,
  partial,
  insufficientEvidence,
  invalidInput,
}

MutualRelationshipValueStatus parseMutualRelationshipValueStatus(String raw) {
  switch (raw) {
    case 'complete':
      return MutualRelationshipValueStatus.complete;
    case 'partial':
      return MutualRelationshipValueStatus.partial;
    case 'insufficient_evidence':
      return MutualRelationshipValueStatus.insufficientEvidence;
    case 'invalid_input':
      return MutualRelationshipValueStatus.invalidInput;
    default:
      throw CoreMethodValidationException('unknown mutual value status', [
        CoreMethodValidationError(
          fieldPath: 'status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

extension MutualRelationshipValueStatusX on MutualRelationshipValueStatus {
  String get wire {
    switch (this) {
      case MutualRelationshipValueStatus.complete:
        return 'complete';
      case MutualRelationshipValueStatus.partial:
        return 'partial';
      case MutualRelationshipValueStatus.insufficientEvidence:
        return 'insufficient_evidence';
      case MutualRelationshipValueStatus.invalidInput:
        return 'invalid_input';
    }
  }
}

class RelationshipValueComparisonExclusion {
  final String fieldId;
  final String reasonCode;
  final String explanation;

  const RelationshipValueComparisonExclusion({
    required this.fieldId,
    required this.reasonCode,
    required this.explanation,
  });

  factory RelationshipValueComparisonExclusion.fromJson(
          Map<String, dynamic> j) =>
      RelationshipValueComparisonExclusion(
        fieldId: j['field_id']?.toString() ?? '',
        reasonCode: j['reason_code']?.toString() ?? '',
        explanation: j['explanation']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'field_id': fieldId,
        'reason_code': reasonCode,
        'explanation': explanation,
      });
}

class RelationshipValueFieldComparison {
  final String fieldId;
  final String comparisonMode;
  final String preferenceOwnerId;
  final String evaluatedSubjectId;
  final String? ownerValue;
  final List<String> ownerValues;
  final String? evaluatedValue;
  final List<String> evaluatedValues;
  final double baseCompatibility;
  final double ownerImportance;
  final double ownerFlexibility;
  final double adjustedDirectionalFit;
  final double evidenceConfidence;
  final double effectiveWeight;
  final double weightedContribution;
  final String registryVersion;
  final String configVersion;
  final List<String> diagnosticCodes;

  RelationshipValueFieldComparison({
    required this.fieldId,
    required this.comparisonMode,
    required this.preferenceOwnerId,
    required this.evaluatedSubjectId,
    required this.ownerValue,
    required this.ownerValues,
    required this.evaluatedValue,
    required this.evaluatedValues,
    required this.baseCompatibility,
    required this.ownerImportance,
    required this.ownerFlexibility,
    required this.adjustedDirectionalFit,
    required this.evidenceConfidence,
    required this.effectiveWeight,
    required this.weightedContribution,
    required this.registryVersion,
    required this.configVersion,
    required this.diagnosticCodes,
  }) {
    cmRequireFinite01(baseCompatibility, 'baseCompatibility', allowNull: false);
    cmRequireFinite01(adjustedDirectionalFit, 'adjustedDirectionalFit',
        allowNull: false);
    cmRequireFinite01(evidenceConfidence, 'evidenceConfidence',
        allowNull: false);
  }

  factory RelationshipValueFieldComparison.fromJson(Map<String, dynamic> j) =>
      RelationshipValueFieldComparison(
        fieldId: j['field_id']?.toString() ?? '',
        comparisonMode: j['comparison_mode']?.toString() ?? '',
        preferenceOwnerId: j['preference_owner_id']?.toString() ?? '',
        evaluatedSubjectId: j['evaluated_subject_id']?.toString() ?? '',
        ownerValue: j['owner_value']?.toString(),
        ownerValues: [
          for (final e in (j['owner_values'] as List?) ?? const [])
            e.toString(),
        ],
        evaluatedValue: j['evaluated_value']?.toString(),
        evaluatedValues: [
          for (final e in (j['evaluated_values'] as List?) ?? const [])
            e.toString(),
        ],
        baseCompatibility: (j['base_compatibility'] as num).toDouble(),
        ownerImportance: (j['owner_importance'] as num).toDouble(),
        ownerFlexibility: (j['owner_flexibility'] as num).toDouble(),
        adjustedDirectionalFit:
            (j['adjusted_directional_fit'] as num).toDouble(),
        evidenceConfidence: (j['evidence_confidence'] as num).toDouble(),
        effectiveWeight: (j['effective_weight'] as num).toDouble(),
        weightedContribution: (j['weighted_contribution'] as num).toDouble(),
        registryVersion: j['registry_version']?.toString() ?? '',
        configVersion: j['config_version']?.toString() ?? '',
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'field_id': fieldId,
        'comparison_mode': comparisonMode,
        'preference_owner_id': preferenceOwnerId,
        'evaluated_subject_id': evaluatedSubjectId,
        'owner_value': ownerValue,
        'owner_values': ownerValues,
        'evaluated_value': evaluatedValue,
        'evaluated_values': evaluatedValues,
        'base_compatibility': baseCompatibility,
        'owner_importance': ownerImportance,
        'owner_flexibility': ownerFlexibility,
        'adjusted_directional_fit': adjustedDirectionalFit,
        'evidence_confidence': evidenceConfidence,
        'effective_weight': effectiveWeight,
        'weighted_contribution': weightedContribution,
        'registry_version': registryVersion,
        'config_version': configVersion,
        'diagnostic_codes': diagnosticCodes,
      });
}

class DirectionalRelationshipValueResult {
  final String preferenceOwnerId;
  final String evaluatedSubjectId;
  final double? rawValueFitScore;
  final double? evidenceConfidence;
  final int comparableFieldCount;
  final int declaredScoreableFieldCount;
  final int explicitlyOpenOrFlexibleFieldCount;
  final List<String> comparableFieldIds;
  final List<RelationshipValueComparisonExclusion> excludedFields;
  final List<RelationshipValueFieldComparison> fieldComparisons;
  final double declaredImportanceMass;
  final double comparableImportanceMass;
  final double effectiveWeightSum;
  final double? evaluationCoverage;
  final DirectionalRelationshipValueStatus status;
  final String deterministicFingerprint;
  final List<String> diagnostics;
  final String configVersion;
  final String registryVersion;

  DirectionalRelationshipValueResult({
    required this.preferenceOwnerId,
    required this.evaluatedSubjectId,
    required this.rawValueFitScore,
    required this.evidenceConfidence,
    required this.comparableFieldCount,
    required this.declaredScoreableFieldCount,
    required this.explicitlyOpenOrFlexibleFieldCount,
    required this.comparableFieldIds,
    required this.excludedFields,
    required this.fieldComparisons,
    required this.declaredImportanceMass,
    required this.comparableImportanceMass,
    required this.effectiveWeightSum,
    required this.evaluationCoverage,
    required this.status,
    required this.deterministicFingerprint,
    required this.diagnostics,
    required this.configVersion,
    required this.registryVersion,
  }) {
    if (rawValueFitScore != null) {
      cmRequireFinite01(rawValueFitScore, 'rawValueFitScore', allowNull: false);
    }
    if (evidenceConfidence != null) {
      cmRequireFinite01(evidenceConfidence, 'evidenceConfidence',
          allowNull: false);
    }
  }

  factory DirectionalRelationshipValueResult.fromJson(Map<String, dynamic> j) =>
      DirectionalRelationshipValueResult(
        preferenceOwnerId: j['preference_owner_id']?.toString() ?? '',
        evaluatedSubjectId: j['evaluated_subject_id']?.toString() ?? '',
        rawValueFitScore: (j['raw_value_fit_score'] as num?)?.toDouble(),
        evidenceConfidence: (j['evidence_confidence'] as num?)?.toDouble(),
        comparableFieldCount:
            (j['comparable_field_count'] as num?)?.toInt() ?? 0,
        declaredScoreableFieldCount:
            (j['declared_scoreable_field_count'] as num?)?.toInt() ?? 0,
        explicitlyOpenOrFlexibleFieldCount:
            (j['explicitly_open_or_flexible_field_count'] as num?)?.toInt() ??
                0,
        comparableFieldIds: [
          for (final e in (j['comparable_field_ids'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        excludedFields: [
          for (final e in (j['excluded_fields'] as List?) ?? const [])
            RelationshipValueComparisonExclusion.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        fieldComparisons: [
          for (final e in (j['field_comparisons'] as List?) ?? const [])
            RelationshipValueFieldComparison.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        declaredImportanceMass:
            (j['declared_importance_mass'] as num?)?.toDouble() ?? 0,
        comparableImportanceMass:
            (j['comparable_importance_mass'] as num?)?.toDouble() ?? 0,
        effectiveWeightSum:
            (j['effective_weight_sum'] as num?)?.toDouble() ?? 0,
        evaluationCoverage: (j['evaluation_coverage'] as num?)?.toDouble(),
        status: parseDirectionalRelationshipValueStatus(
            j['status']?.toString() ?? ''),
        deterministicFingerprint:
            j['deterministic_fingerprint']?.toString() ?? '',
        diagnostics: [
          for (final e in (j['diagnostics'] as List?) ?? const []) e.toString(),
        ]..sort(),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'preference_owner_id': preferenceOwnerId,
        'evaluated_subject_id': evaluatedSubjectId,
        'raw_value_fit_score': rawValueFitScore,
        'evidence_confidence': evidenceConfidence,
        'comparable_field_count': comparableFieldCount,
        'declared_scoreable_field_count': declaredScoreableFieldCount,
        'explicitly_open_or_flexible_field_count':
            explicitlyOpenOrFlexibleFieldCount,
        'comparable_field_ids': comparableFieldIds,
        'excluded_fields': [for (final e in excludedFields) e.toJson()],
        'field_comparisons': [for (final f in fieldComparisons) f.toJson()],
        'declared_importance_mass': declaredImportanceMass,
        'comparable_importance_mass': comparableImportanceMass,
        'effective_weight_sum': effectiveWeightSum,
        'evaluation_coverage': evaluationCoverage,
        'status': status.wire,
        'deterministic_fingerprint': deterministicFingerprint,
        'diagnostics': diagnostics,
        'config_version': configVersion,
        'registry_version': registryVersion,
      });
}

class MutualRelationshipValueResult {
  final DirectionalRelationshipValueResult subjectAToBResult;
  final DirectionalRelationshipValueResult subjectBToAResult;
  final double? mutualRawValueFitScore;
  final double? mutualEvidenceConfidence;
  final double? directionalAsymmetry;
  final MutualRelationshipValueStatus status;
  final String configVersion;
  final String registryVersion;
  final String deterministicFingerprint;
  final List<String> diagnostics;

  MutualRelationshipValueResult({
    required this.subjectAToBResult,
    required this.subjectBToAResult,
    required this.mutualRawValueFitScore,
    required this.mutualEvidenceConfidence,
    required this.directionalAsymmetry,
    required this.status,
    required this.configVersion,
    required this.registryVersion,
    required this.deterministicFingerprint,
    required this.diagnostics,
  }) {
    if (mutualRawValueFitScore != null) {
      cmRequireFinite01(mutualRawValueFitScore, 'mutualRawValueFitScore',
          allowNull: false);
    }
    if (mutualEvidenceConfidence != null) {
      cmRequireFinite01(mutualEvidenceConfidence, 'mutualEvidenceConfidence',
          allowNull: false);
    }
    if (directionalAsymmetry != null) {
      cmRequireFinite01(directionalAsymmetry, 'directionalAsymmetry',
          allowNull: false);
    }
  }

  factory MutualRelationshipValueResult.fromJson(Map<String, dynamic> j) =>
      MutualRelationshipValueResult(
        subjectAToBResult: DirectionalRelationshipValueResult.fromJson(
          Map<String, dynamic>.from(j['subject_a_to_b_result'] as Map),
        ),
        subjectBToAResult: DirectionalRelationshipValueResult.fromJson(
          Map<String, dynamic>.from(j['subject_b_to_a_result'] as Map),
        ),
        mutualRawValueFitScore:
            (j['mutual_raw_value_fit_score'] as num?)?.toDouble(),
        mutualEvidenceConfidence:
            (j['mutual_evidence_confidence'] as num?)?.toDouble(),
        directionalAsymmetry: (j['directional_asymmetry'] as num?)?.toDouble(),
        status:
            parseMutualRelationshipValueStatus(j['status']?.toString() ?? ''),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
        deterministicFingerprint:
            j['deterministic_fingerprint']?.toString() ?? '',
        diagnostics: [
          for (final e in (j['diagnostics'] as List?) ?? const []) e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'subject_a_to_b_result': subjectAToBResult.toJson(),
        'subject_b_to_a_result': subjectBToAResult.toJson(),
        'mutual_raw_value_fit_score': mutualRawValueFitScore,
        'mutual_evidence_confidence': mutualEvidenceConfidence,
        'directional_asymmetry': directionalAsymmetry,
        'status': status.wire,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'deterministic_fingerprint': deterministicFingerprint,
        'diagnostics': diagnostics,
      });
}
