import 'assessment_module_id.dart';
import 'core_method_v2_validation.dart';
import 'hard_constraint.dart';
import 'soft_signals.dart';

enum CompatibilityEvaluationStatus {
  complete,
  partial,
  insufficientEvidence,
  blockedByHardConstraint,
  invalidInput,
}

CompatibilityEvaluationStatus parseCompatibilityEvaluationStatus(String raw) {
  switch (raw) {
    case 'complete':
      return CompatibilityEvaluationStatus.complete;
    case 'partial':
      return CompatibilityEvaluationStatus.partial;
    case 'insufficient_evidence':
      return CompatibilityEvaluationStatus.insufficientEvidence;
    case 'blocked_by_hard_constraint':
      return CompatibilityEvaluationStatus.blockedByHardConstraint;
    case 'invalid_input':
      return CompatibilityEvaluationStatus.invalidInput;
    default:
      throw CoreMethodValidationException('unknown evaluation status', [
        CoreMethodValidationError(
          fieldPath: 'evaluation_status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

extension CompatibilityEvaluationStatusX on CompatibilityEvaluationStatus {
  String get wire {
    switch (this) {
      case CompatibilityEvaluationStatus.complete:
        return 'complete';
      case CompatibilityEvaluationStatus.partial:
        return 'partial';
      case CompatibilityEvaluationStatus.insufficientEvidence:
        return 'insufficient_evidence';
      case CompatibilityEvaluationStatus.blockedByHardConstraint:
        return 'blocked_by_hard_constraint';
      case CompatibilityEvaluationStatus.invalidInput:
        return 'invalid_input';
    }
  }
}

class CompatibilityModuleResult {
  final CompatibilityModuleId module;
  final double? score;
  final double? confidence;
  final double? evidenceCoverage;
  final String status;
  final List<String> missingDimensions;

  CompatibilityModuleResult({
    required this.module,
    required this.score,
    required this.confidence,
    required this.evidenceCoverage,
    required this.status,
    required this.missingDimensions,
  }) {
    if (score != null) cmRequireFinite01(score, 'score', allowNull: false);
    if (confidence != null) {
      cmRequireFinite01(confidence, 'confidence', allowNull: false);
    }
    if (evidenceCoverage != null) {
      cmRequireFinite01(evidenceCoverage, 'evidenceCoverage', allowNull: false);
    }
  }

  factory CompatibilityModuleResult.fromJson(Map<String, dynamic> j) =>
      CompatibilityModuleResult(
        module: parseCompatibilityModuleId(j['module']?.toString() ?? ''),
        score: (j['score'] as num?)?.toDouble(),
        confidence: (j['confidence'] as num?)?.toDouble(),
        evidenceCoverage: (j['evidence_coverage'] as num?)?.toDouble(),
        status: j['status']?.toString() ?? '',
        missingDimensions: [
          for (final e in (j['missing_dimensions'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'module': module.wire,
        'score': score,
        'confidence': confidence,
        'evidence_coverage': evidenceCoverage,
        'status': status,
        'missing_dimensions': missingDimensions,
      });
}

/// Thin summary projection for later CompatibilityResult wiring (P2B-0).
/// Rich engine output lives in `DirectionalPreferenceFitResult` (P2B-2).
class DirectionalPreferenceFitSummary {
  final String directionLabel;
  final double? score;
  final double? confidence;
  final String status;

  DirectionalPreferenceFitSummary({
    required this.directionLabel,
    required this.score,
    required this.confidence,
    required this.status,
  }) {
    if (score != null) cmRequireFinite01(score, 'score', allowNull: false);
    if (confidence != null) {
      cmRequireFinite01(confidence, 'confidence', allowNull: false);
    }
  }

  factory DirectionalPreferenceFitSummary.fromJson(Map<String, dynamic> j) =>
      DirectionalPreferenceFitSummary(
        directionLabel: j['direction_label']?.toString() ?? '',
        score: (j['score'] as num?)?.toDouble(),
        confidence: (j['confidence'] as num?)?.toDouble(),
        status: j['status']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'direction_label': directionLabel,
        'score': score,
        'confidence': confidence,
        'status': status,
      });
}

class CompatibilityConfidenceResult {
  final double evidenceConfidence;
  final double evidenceCoverage;
  final String policyId;
  final String status;

  CompatibilityConfidenceResult({
    required this.evidenceConfidence,
    required this.evidenceCoverage,
    required this.policyId,
    required this.status,
  }) {
    cmRequireFinite01(evidenceConfidence, 'evidenceConfidence',
        allowNull: false);
    cmRequireFinite01(evidenceCoverage, 'evidenceCoverage', allowNull: false);
  }

  factory CompatibilityConfidenceResult.fromJson(Map<String, dynamic> j) =>
      CompatibilityConfidenceResult(
        evidenceConfidence: (j['evidence_confidence'] as num).toDouble(),
        evidenceCoverage: (j['evidence_coverage'] as num).toDouble(),
        policyId: j['policy_id']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'evidence_confidence': evidenceConfidence,
        'evidence_coverage': evidenceCoverage,
        'policy_id': policyId,
        'status': status,
      });
}

class CompatibilityExplanationSignal {
  final String code;
  final String category;
  final String severity;
  final List<String> relatedIds;

  CompatibilityExplanationSignal({
    required this.code,
    required this.category,
    required this.severity,
    required this.relatedIds,
  });

  factory CompatibilityExplanationSignal.fromJson(Map<String, dynamic> j) =>
      CompatibilityExplanationSignal(
        code: j['code']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        severity: j['severity']?.toString() ?? '',
        relatedIds: [
          for (final e in (j['related_ids'] as List?) ?? const []) e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'code': code,
        'category': category,
        'severity': severity,
        'related_ids': relatedIds,
      });
}

/// Result contract only — no formula execution in P2B-0.
/// Never contains persona IDs or Frequency type labels.
class CompatibilityResult {
  final double? overallRawScore;
  final double? confidenceAdjustedScore;
  final CompatibilityConfidenceResult confidence;
  final CompatibilityModuleResult? iq;
  final CompatibilityModuleResult? eq;
  final CompatibilityModuleResult? frequency;
  final CompatibilityModuleResult? values;
  final DirectionalPreferenceFitSummary? preferenceFitAFromB;
  final DirectionalPreferenceFitSummary? preferenceFitBFromA;
  final double? mutualPreferenceScore;
  final HardConstraintOutcome hardConstraintOutcome;
  final List<HardConstraintEvaluationResult> hardConstraintResults;
  final List<SoftConflictSignal> softConflictSignals;
  final List<CompatibilityExplanationSignal> strengths;
  final List<CompatibilityExplanationSignal> frictionAreas;
  final List<String> insufficientEvidenceDimensions;
  final List<String> missingModules;
  final List<String> explanationCodes;
  final String configVersion;
  final String registryVersion;
  final CompatibilityEvaluationStatus evaluationStatus;

  CompatibilityResult({
    required this.overallRawScore,
    required this.confidenceAdjustedScore,
    required this.confidence,
    required this.iq,
    required this.eq,
    required this.frequency,
    required this.values,
    required this.preferenceFitAFromB,
    required this.preferenceFitBFromA,
    required this.mutualPreferenceScore,
    required this.hardConstraintOutcome,
    required this.hardConstraintResults,
    required this.softConflictSignals,
    required this.strengths,
    required this.frictionAreas,
    required this.insufficientEvidenceDimensions,
    required this.missingModules,
    required this.explanationCodes,
    required this.configVersion,
    required this.registryVersion,
    required this.evaluationStatus,
  }) {
    if (overallRawScore != null) {
      cmRequireFinite01(overallRawScore, 'overallRawScore', allowNull: false);
    }
    if (confidenceAdjustedScore != null) {
      cmRequireFinite01(
        confidenceAdjustedScore,
        'confidenceAdjustedScore',
        allowNull: false,
      );
    }
    if (mutualPreferenceScore != null) {
      cmRequireFinite01(
        mutualPreferenceScore,
        'mutualPreferenceScore',
        allowNull: false,
      );
    }
    if (evaluationStatus ==
        CompatibilityEvaluationStatus.blockedByHardConstraint) {
      cmRequire(
        overallRawScore == null && confidenceAdjustedScore == null,
        'overallRawScore',
        'fabricated_blocked_score',
        'blocked result must not fabricate an overall score',
      );
    }
  }

  factory CompatibilityResult.fromJson(Map<String, dynamic> j) {
    CompatibilityModuleResult? mod(String key) {
      final raw = j[key];
      if (raw == null) return null;
      return CompatibilityModuleResult.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
    }

    DirectionalPreferenceFitSummary? dir(String key) {
      final raw = j[key];
      if (raw == null) return null;
      return DirectionalPreferenceFitSummary.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
    }

    return CompatibilityResult(
      overallRawScore: (j['overall_raw_score'] as num?)?.toDouble(),
      confidenceAdjustedScore:
          (j['confidence_adjusted_score'] as num?)?.toDouble(),
      confidence: CompatibilityConfidenceResult.fromJson(
        Map<String, dynamic>.from(j['confidence'] as Map),
      ),
      iq: mod('iq'),
      eq: mod('eq'),
      frequency: mod('frequency'),
      values: mod('values'),
      preferenceFitAFromB: dir('preference_fit_a_from_b'),
      preferenceFitBFromA: dir('preference_fit_b_from_a'),
      mutualPreferenceScore: (j['mutual_preference_score'] as num?)?.toDouble(),
      hardConstraintOutcome: parseHardConstraintOutcome(
        j['hard_constraint_outcome']?.toString() ?? '',
      ),
      hardConstraintResults: [
        for (final e in (j['hard_constraint_results'] as List?) ?? const [])
          HardConstraintEvaluationResult.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
      ],
      softConflictSignals: [
        for (final e in (j['soft_conflict_signals'] as List?) ?? const [])
          SoftConflictSignal.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
      strengths: [
        for (final e in (j['strengths'] as List?) ?? const [])
          CompatibilityExplanationSignal.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
      ],
      frictionAreas: [
        for (final e in (j['friction_areas'] as List?) ?? const [])
          CompatibilityExplanationSignal.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
      ],
      insufficientEvidenceDimensions: [
        for (final e
            in (j['insufficient_evidence_dimensions'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
      missingModules: [
        for (final e in (j['missing_modules'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
      explanationCodes: [
        for (final e in (j['explanation_codes'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
      configVersion: j['config_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      evaluationStatus: parseCompatibilityEvaluationStatus(
        j['evaluation_status']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'overall_raw_score': overallRawScore,
        'confidence_adjusted_score': confidenceAdjustedScore,
        'confidence': confidence.toJson(),
        'iq': iq?.toJson(),
        'eq': eq?.toJson(),
        'frequency': frequency?.toJson(),
        'values': values?.toJson(),
        'preference_fit_a_from_b': preferenceFitAFromB?.toJson(),
        'preference_fit_b_from_a': preferenceFitBFromA?.toJson(),
        'mutual_preference_score': mutualPreferenceScore,
        'hard_constraint_outcome': hardConstraintOutcome.wire,
        'hard_constraint_results': [
          for (final r in hardConstraintResults) r.toJson(),
        ],
        'soft_conflict_signals': [
          for (final s in softConflictSignals) s.toJson(),
        ],
        'strengths': [for (final s in strengths) s.toJson()],
        'friction_areas': [for (final f in frictionAreas) f.toJson()],
        'insufficient_evidence_dimensions': insufficientEvidenceDimensions,
        'missing_modules': missingModules,
        'explanation_codes': explanationCodes,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'evaluation_status': evaluationStatus.wire,
      });
}
