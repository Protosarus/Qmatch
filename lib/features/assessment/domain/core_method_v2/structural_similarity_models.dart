import 'assessment_module_id.dart';
import 'core_method_v2_validation.dart';

enum StructuralModuleStatus {
  complete,
  partial,
  insufficientEvidence,
  invalidInput,
}

StructuralModuleStatus parseStructuralModuleStatus(String raw) {
  switch (raw) {
    case 'complete':
      return StructuralModuleStatus.complete;
    case 'partial':
      return StructuralModuleStatus.partial;
    case 'insufficient_evidence':
      return StructuralModuleStatus.insufficientEvidence;
    case 'invalid_input':
      return StructuralModuleStatus.invalidInput;
    default:
      throw CoreMethodValidationException('unknown structural module status', [
        CoreMethodValidationError(
          fieldPath: 'status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

extension StructuralModuleStatusX on StructuralModuleStatus {
  String get wire {
    switch (this) {
      case StructuralModuleStatus.complete:
        return 'complete';
      case StructuralModuleStatus.partial:
        return 'partial';
      case StructuralModuleStatus.insufficientEvidence:
        return 'insufficient_evidence';
      case StructuralModuleStatus.invalidInput:
        return 'invalid_input';
    }
  }
}

enum StructuralProfileStatus {
  complete,
  partial,
  insufficientEvidence,
  invalidInput,
}

StructuralProfileStatus parseStructuralProfileStatus(String raw) {
  switch (raw) {
    case 'complete':
      return StructuralProfileStatus.complete;
    case 'partial':
      return StructuralProfileStatus.partial;
    case 'insufficient_evidence':
      return StructuralProfileStatus.insufficientEvidence;
    case 'invalid_input':
      return StructuralProfileStatus.invalidInput;
    default:
      throw CoreMethodValidationException('unknown structural profile status', [
        CoreMethodValidationError(
          fieldPath: 'overall_status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

extension StructuralProfileStatusX on StructuralProfileStatus {
  String get wire {
    switch (this) {
      case StructuralProfileStatus.complete:
        return 'complete';
      case StructuralProfileStatus.partial:
        return 'partial';
      case StructuralProfileStatus.insufficientEvidence:
        return 'insufficient_evidence';
      case StructuralProfileStatus.invalidInput:
        return 'invalid_input';
    }
  }
}

class StructuralSimilarityExclusion {
  final String dimensionId;
  final String reasonCode;
  final String explanation;

  const StructuralSimilarityExclusion({
    required this.dimensionId,
    required this.reasonCode,
    required this.explanation,
  });

  factory StructuralSimilarityExclusion.fromJson(Map<String, dynamic> j) =>
      StructuralSimilarityExclusion(
        dimensionId: j['dimension_id']?.toString() ?? '',
        reasonCode: j['reason_code']?.toString() ?? '',
        explanation: j['explanation']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'dimension_id': dimensionId,
        'reason_code': reasonCode,
        'explanation': explanation,
      });
}

class StructuralSimilarityDiagnostics {
  final List<String> codes;
  final List<String> closeHighConfidenceDimensions;
  final List<String> distantHighConfidenceDimensions;
  final List<String> closeLowConfidenceDimensions;
  final List<String> distantLowConfidenceDimensions;
  final List<String> notes;

  const StructuralSimilarityDiagnostics({
    required this.codes,
    required this.closeHighConfidenceDimensions,
    required this.distantHighConfidenceDimensions,
    required this.closeLowConfidenceDimensions,
    required this.distantLowConfidenceDimensions,
    required this.notes,
  });

  factory StructuralSimilarityDiagnostics.empty() =>
      const StructuralSimilarityDiagnostics(
        codes: [],
        closeHighConfidenceDimensions: [],
        distantHighConfidenceDimensions: [],
        closeLowConfidenceDimensions: [],
        distantLowConfidenceDimensions: [],
        notes: [],
      );

  factory StructuralSimilarityDiagnostics.fromJson(Map<String, dynamic> j) =>
      StructuralSimilarityDiagnostics(
        codes: _sortedStrings(j['codes']),
        closeHighConfidenceDimensions:
            _sortedStrings(j['close_high_confidence_dimensions']),
        distantHighConfidenceDimensions:
            _sortedStrings(j['distant_high_confidence_dimensions']),
        closeLowConfidenceDimensions:
            _sortedStrings(j['close_low_confidence_dimensions']),
        distantLowConfidenceDimensions:
            _sortedStrings(j['distant_low_confidence_dimensions']),
        notes: _sortedStrings(j['notes']),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'codes': codes,
        'close_high_confidence_dimensions': closeHighConfidenceDimensions,
        'distant_high_confidence_dimensions': distantHighConfidenceDimensions,
        'close_low_confidence_dimensions': closeLowConfidenceDimensions,
        'distant_low_confidence_dimensions': distantLowConfidenceDimensions,
        'notes': notes,
      });
}

List<String> _sortedStrings(Object? raw) {
  final list = [
    for (final e in (raw as List?) ?? const []) e.toString(),
  ]..sort();
  return list;
}

class StructuralDimensionComparison {
  final String dimensionId;
  final AssessmentModuleId module;
  final double subjectAScore;
  final double subjectBScore;
  final double absoluteDifference;
  final double subjectAConfidence;
  final double subjectBConfidence;
  final double pairConfidence;
  final double baseWeight;
  final double effectiveWeight;
  final double squaredDifference;
  final double weightedSquaredContribution;
  final String registryVersion;
  final List<String> scoringContractVersions;

  StructuralDimensionComparison({
    required this.dimensionId,
    required this.module,
    required this.subjectAScore,
    required this.subjectBScore,
    required this.absoluteDifference,
    required this.subjectAConfidence,
    required this.subjectBConfidence,
    required this.pairConfidence,
    required this.baseWeight,
    required this.effectiveWeight,
    required this.squaredDifference,
    required this.weightedSquaredContribution,
    required this.registryVersion,
    required this.scoringContractVersions,
  });

  factory StructuralDimensionComparison.fromJson(Map<String, dynamic> j) =>
      StructuralDimensionComparison(
        dimensionId: j['dimension_id']?.toString() ?? '',
        module: parseAssessmentModuleId(j['module']?.toString() ?? ''),
        subjectAScore: (j['subject_a_score'] as num).toDouble(),
        subjectBScore: (j['subject_b_score'] as num).toDouble(),
        absoluteDifference: (j['absolute_difference'] as num).toDouble(),
        subjectAConfidence: (j['subject_a_confidence'] as num).toDouble(),
        subjectBConfidence: (j['subject_b_confidence'] as num).toDouble(),
        pairConfidence: (j['pair_confidence'] as num).toDouble(),
        baseWeight: (j['base_weight'] as num).toDouble(),
        effectiveWeight: (j['effective_weight'] as num).toDouble(),
        squaredDifference: (j['squared_difference'] as num).toDouble(),
        weightedSquaredContribution:
            (j['weighted_squared_contribution'] as num).toDouble(),
        registryVersion: j['registry_version']?.toString() ?? '',
        scoringContractVersions: _sortedStrings(j['scoring_contract_versions']),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'dimension_id': dimensionId,
        'module': module.wire,
        'subject_a_score': subjectAScore,
        'subject_b_score': subjectBScore,
        'absolute_difference': absoluteDifference,
        'subject_a_confidence': subjectAConfidence,
        'subject_b_confidence': subjectBConfidence,
        'pair_confidence': pairConfidence,
        'base_weight': baseWeight,
        'effective_weight': effectiveWeight,
        'squared_difference': squaredDifference,
        'weighted_squared_contribution': weightedSquaredContribution,
        'registry_version': registryVersion,
        'scoring_contract_versions': scoringContractVersions,
      });
}

class StructuralModuleSimilarityResult {
  final AssessmentModuleId module;
  final double? similarityScore;
  final double? distanceSquared;
  final double? distance;
  final int comparableDimensionCount;
  final int eligibleDimensionCount;
  final int totalActiveModuleDimensionCount;
  final List<String> comparableDimensionIds;
  final List<StructuralSimilarityExclusion> excludedDimensions;
  final List<StructuralDimensionComparison> dimensionComparisons;
  final double unweightedCoverage;
  final double weightedCoverage;
  final double? meanPairConfidence;
  final double? evidenceConfidence;
  final double effectiveWeightSum;
  final double scaleParameter;
  final StructuralModuleStatus status;
  final String configVersion;
  final String registryVersion;
  final StructuralSimilarityDiagnostics diagnostics;

  StructuralModuleSimilarityResult({
    required this.module,
    required this.similarityScore,
    required this.distanceSquared,
    required this.distance,
    required this.comparableDimensionCount,
    required this.eligibleDimensionCount,
    required this.totalActiveModuleDimensionCount,
    required this.comparableDimensionIds,
    required this.excludedDimensions,
    required this.dimensionComparisons,
    required this.unweightedCoverage,
    required this.weightedCoverage,
    required this.meanPairConfidence,
    required this.evidenceConfidence,
    required this.effectiveWeightSum,
    required this.scaleParameter,
    required this.status,
    required this.configVersion,
    required this.registryVersion,
    required this.diagnostics,
  }) {
    if (similarityScore != null) {
      cmRequire(
        similarityScore!.isFinite &&
            similarityScore! > 0 &&
            similarityScore! <= 1,
        'similarityScore',
        'out_of_bounds',
        '$similarityScore',
      );
    }
    if (distanceSquared != null) {
      cmRequire(
        distanceSquared!.isFinite &&
            distanceSquared! >= 0 &&
            distanceSquared! <= 1,
        'distanceSquared',
        'out_of_bounds',
        '$distanceSquared',
      );
    }
  }

  factory StructuralModuleSimilarityResult.fromJson(Map<String, dynamic> j) =>
      StructuralModuleSimilarityResult(
        module: parseAssessmentModuleId(j['module']?.toString() ?? ''),
        similarityScore: (j['similarity_score'] as num?)?.toDouble(),
        distanceSquared: (j['distance_squared'] as num?)?.toDouble(),
        distance: (j['distance'] as num?)?.toDouble(),
        comparableDimensionCount:
            (j['comparable_dimension_count'] as num?)?.toInt() ?? 0,
        eligibleDimensionCount:
            (j['eligible_dimension_count'] as num?)?.toInt() ?? 0,
        totalActiveModuleDimensionCount:
            (j['total_active_module_dimension_count'] as num?)?.toInt() ?? 0,
        comparableDimensionIds: _sortedStrings(j['comparable_dimension_ids']),
        excludedDimensions: [
          for (final e in (j['excluded_dimensions'] as List?) ?? const [])
            StructuralSimilarityExclusion.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        dimensionComparisons: [
          for (final e in (j['dimension_comparisons'] as List?) ?? const [])
            StructuralDimensionComparison.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        unweightedCoverage: (j['unweighted_coverage'] as num).toDouble(),
        weightedCoverage: (j['weighted_coverage'] as num).toDouble(),
        meanPairConfidence: (j['mean_pair_confidence'] as num?)?.toDouble(),
        evidenceConfidence: (j['evidence_confidence'] as num?)?.toDouble(),
        effectiveWeightSum: (j['effective_weight_sum'] as num).toDouble(),
        scaleParameter: (j['scale_parameter'] as num).toDouble(),
        status: parseStructuralModuleStatus(j['status']?.toString() ?? ''),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
        diagnostics: StructuralSimilarityDiagnostics.fromJson(
          Map<String, dynamic>.from(j['diagnostics'] as Map? ?? {}),
        ),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'module': module.wire,
        'similarity_score': similarityScore,
        'distance_squared': distanceSquared,
        'distance': distance,
        'comparable_dimension_count': comparableDimensionCount,
        'eligible_dimension_count': eligibleDimensionCount,
        'total_active_module_dimension_count': totalActiveModuleDimensionCount,
        'comparable_dimension_ids': comparableDimensionIds,
        'excluded_dimensions': [
          for (final e in excludedDimensions) e.toJson(),
        ],
        'dimension_comparisons': [
          for (final c in dimensionComparisons) c.toJson(),
        ],
        'unweighted_coverage': unweightedCoverage,
        'weighted_coverage': weightedCoverage,
        'mean_pair_confidence': meanPairConfidence,
        'evidence_confidence': evidenceConfidence,
        'effective_weight_sum': effectiveWeightSum,
        'scale_parameter': scaleParameter,
        'status': status.wire,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'diagnostics': diagnostics.toJson(),
      });
}

class StructuralProfileSimilarityResult {
  final StructuralModuleSimilarityResult? iq;
  final StructuralModuleSimilarityResult? eq;
  final StructuralModuleSimilarityResult? frequency;
  final List<String> evaluatedModules;
  final List<String> missingModules;
  final String configVersion;
  final String registryVersion;
  final DateTime? evaluationTimestamp;
  final String deterministicFingerprint;
  final StructuralProfileStatus overallStatus;

  StructuralProfileSimilarityResult({
    required this.iq,
    required this.eq,
    required this.frequency,
    required this.evaluatedModules,
    required this.missingModules,
    required this.configVersion,
    required this.registryVersion,
    required this.evaluationTimestamp,
    required this.deterministicFingerprint,
    required this.overallStatus,
  });

  factory StructuralProfileSimilarityResult.fromJson(Map<String, dynamic> j) {
    StructuralModuleSimilarityResult? mod(String key) {
      final raw = j[key];
      if (raw == null) return null;
      return StructuralModuleSimilarityResult.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
    }

    return StructuralProfileSimilarityResult(
      iq: mod('iq'),
      eq: mod('eq'),
      frequency: mod('frequency'),
      evaluatedModules: _sortedStrings(j['evaluated_modules']),
      missingModules: _sortedStrings(j['missing_modules']),
      configVersion: j['config_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      evaluationTimestamp: j['evaluation_timestamp'] == null
          ? null
          : DateTime.parse(j['evaluation_timestamp'].toString()),
      deterministicFingerprint:
          j['deterministic_fingerprint']?.toString() ?? '',
      overallStatus: parseStructuralProfileStatus(
        j['overall_status']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'iq': iq?.toJson(),
        'eq': eq?.toJson(),
        'frequency': frequency?.toJson(),
        'evaluated_modules': evaluatedModules,
        'missing_modules': missingModules,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'evaluation_timestamp': evaluationTimestamp?.toIso8601String(),
        'deterministic_fingerprint': deterministicFingerprint,
        'overall_status': overallStatus.wire,
      });
}
