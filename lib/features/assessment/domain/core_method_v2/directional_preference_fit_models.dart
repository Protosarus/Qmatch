import 'assessment_module_id.dart';
import 'core_method_v2_validation.dart';
import 'partner_dimension_preference.dart';

enum DirectionalPreferenceFitStatus {
  complete,
  partial,
  insufficientEvidence,
  invalidInput,
}

DirectionalPreferenceFitStatus parseDirectionalPreferenceFitStatus(String raw) {
  switch (raw) {
    case 'complete':
      return DirectionalPreferenceFitStatus.complete;
    case 'partial':
      return DirectionalPreferenceFitStatus.partial;
    case 'insufficient_evidence':
      return DirectionalPreferenceFitStatus.insufficientEvidence;
    case 'invalid_input':
      return DirectionalPreferenceFitStatus.invalidInput;
    default:
      throw CoreMethodValidationException('unknown directional status', [
        CoreMethodValidationError(
          fieldPath: 'status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

extension DirectionalPreferenceFitStatusX on DirectionalPreferenceFitStatus {
  String get wire {
    switch (this) {
      case DirectionalPreferenceFitStatus.complete:
        return 'complete';
      case DirectionalPreferenceFitStatus.partial:
        return 'partial';
      case DirectionalPreferenceFitStatus.insufficientEvidence:
        return 'insufficient_evidence';
      case DirectionalPreferenceFitStatus.invalidInput:
        return 'invalid_input';
    }
  }
}

enum MutualPreferenceFitStatus {
  complete,
  partial,
  insufficientEvidence,
  invalidInput,
}

MutualPreferenceFitStatus parseMutualPreferenceFitStatus(String raw) {
  switch (raw) {
    case 'complete':
      return MutualPreferenceFitStatus.complete;
    case 'partial':
      return MutualPreferenceFitStatus.partial;
    case 'insufficient_evidence':
      return MutualPreferenceFitStatus.insufficientEvidence;
    case 'invalid_input':
      return MutualPreferenceFitStatus.invalidInput;
    default:
      throw CoreMethodValidationException('unknown mutual status', [
        CoreMethodValidationError(
          fieldPath: 'status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

extension MutualPreferenceFitStatusX on MutualPreferenceFitStatus {
  String get wire {
    switch (this) {
      case MutualPreferenceFitStatus.complete:
        return 'complete';
      case MutualPreferenceFitStatus.partial:
        return 'partial';
      case MutualPreferenceFitStatus.insufficientEvidence:
        return 'insufficient_evidence';
      case MutualPreferenceFitStatus.invalidInput:
        return 'invalid_input';
    }
  }
}

class DirectionalPreferenceFitExclusion {
  final String dimensionId;
  final String reasonCode;
  final String explanation;

  const DirectionalPreferenceFitExclusion({
    required this.dimensionId,
    required this.reasonCode,
    required this.explanation,
  });

  factory DirectionalPreferenceFitExclusion.fromJson(Map<String, dynamic> j) =>
      DirectionalPreferenceFitExclusion(
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

class DirectionalPreferenceFitDiagnostics {
  final List<String> codes;
  final List<String> notes;

  const DirectionalPreferenceFitDiagnostics({
    required this.codes,
    required this.notes,
  });

  factory DirectionalPreferenceFitDiagnostics.empty() =>
      const DirectionalPreferenceFitDiagnostics(codes: [], notes: []);

  factory DirectionalPreferenceFitDiagnostics.fromJson(
          Map<String, dynamic> j) =>
      DirectionalPreferenceFitDiagnostics(
        codes: _sorted(j['codes']),
        notes: _sorted(j['notes']),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'codes': codes,
        'notes': notes,
      });
}

List<String> _sorted(Object? raw) {
  final list = [for (final e in (raw as List?) ?? const []) e.toString()]
    ..sort();
  return list;
}

class PreferenceDimensionFit {
  final String dimensionId;
  final AssessmentModuleId module;
  final PreferenceMode preferenceMode;
  final String preferenceOwnerId;
  final String evaluatedSubjectId;
  final double evaluatedScore;
  final double? selfScore;
  final double? preferredMin;
  final double? preferredMax;
  final double distanceToTarget;
  final double importance;
  final double flexibility;
  final double flexibilityScale;
  final double evidenceConfidence;
  final double rawDimensionFit;
  final double effectiveWeight;
  final double weightedContribution;
  final String registryVersion;
  final List<String> scoringContractVersions;
  final List<String> diagnosticCodes;

  PreferenceDimensionFit({
    required this.dimensionId,
    required this.module,
    required this.preferenceMode,
    required this.preferenceOwnerId,
    required this.evaluatedSubjectId,
    required this.evaluatedScore,
    required this.selfScore,
    required this.preferredMin,
    required this.preferredMax,
    required this.distanceToTarget,
    required this.importance,
    required this.flexibility,
    required this.flexibilityScale,
    required this.evidenceConfidence,
    required this.rawDimensionFit,
    required this.effectiveWeight,
    required this.weightedContribution,
    required this.registryVersion,
    required this.scoringContractVersions,
    required this.diagnosticCodes,
  });

  factory PreferenceDimensionFit.fromJson(Map<String, dynamic> j) =>
      PreferenceDimensionFit(
        dimensionId: j['dimension_id']?.toString() ?? '',
        module: parseAssessmentModuleId(j['module']?.toString() ?? ''),
        preferenceMode:
            parsePreferenceMode(j['preference_mode']?.toString() ?? ''),
        preferenceOwnerId: j['preference_owner_id']?.toString() ?? '',
        evaluatedSubjectId: j['evaluated_subject_id']?.toString() ?? '',
        evaluatedScore: (j['evaluated_score'] as num).toDouble(),
        selfScore: (j['self_score'] as num?)?.toDouble(),
        preferredMin: (j['preferred_min'] as num?)?.toDouble(),
        preferredMax: (j['preferred_max'] as num?)?.toDouble(),
        distanceToTarget: (j['distance_to_target'] as num).toDouble(),
        importance: (j['importance'] as num).toDouble(),
        flexibility: (j['flexibility'] as num).toDouble(),
        flexibilityScale: (j['flexibility_scale'] as num).toDouble(),
        evidenceConfidence: (j['evidence_confidence'] as num).toDouble(),
        rawDimensionFit: (j['raw_dimension_fit'] as num).toDouble(),
        effectiveWeight: (j['effective_weight'] as num).toDouble(),
        weightedContribution: (j['weighted_contribution'] as num).toDouble(),
        registryVersion: j['registry_version']?.toString() ?? '',
        scoringContractVersions: _sorted(j['scoring_contract_versions']),
        diagnosticCodes: _sorted(j['diagnostic_codes']),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'dimension_id': dimensionId,
        'module': module.wire,
        'preference_mode': preferenceMode.wire,
        'preference_owner_id': preferenceOwnerId,
        'evaluated_subject_id': evaluatedSubjectId,
        'evaluated_score': evaluatedScore,
        'self_score': selfScore,
        'preferred_min': preferredMin,
        'preferred_max': preferredMax,
        'distance_to_target': distanceToTarget,
        'importance': importance,
        'flexibility': flexibility,
        'flexibility_scale': flexibilityScale,
        'evidence_confidence': evidenceConfidence,
        'raw_dimension_fit': rawDimensionFit,
        'effective_weight': effectiveWeight,
        'weighted_contribution': weightedContribution,
        'registry_version': registryVersion,
        'scoring_contract_versions': scoringContractVersions,
        'diagnostic_codes': diagnosticCodes,
      });
}

/// Rich P2B-2 engine result for one preference direction (owner ← evaluated).
class DirectionalPreferenceFitResult {
  final String preferenceOwnerId;
  final String evaluatedSubjectId;
  final double? rawFitScore;
  final double? evidenceConfidence;
  final int declaredScoreablePreferenceCount;
  final int comparablePreferenceCount;
  final int explicitlyOpenPreferenceCount;
  final int unavailablePreferenceCount;
  final List<String> comparablePreferenceIds;
  final List<String> openPreferenceIds;
  final List<DirectionalPreferenceFitExclusion> excludedPreferences;
  final List<PreferenceDimensionFit> dimensionFits;
  final double declaredImportanceMass;
  final double comparableImportanceMass;
  final double effectiveWeightSum;
  final double? evaluationCoverage;
  final double profileDeclarationBreadth;
  final DirectionalPreferenceFitStatus status;
  final String configVersion;
  final String registryVersion;
  final String deterministicFingerprint;
  final DirectionalPreferenceFitDiagnostics diagnostics;

  DirectionalPreferenceFitResult({
    required this.preferenceOwnerId,
    required this.evaluatedSubjectId,
    required this.rawFitScore,
    required this.evidenceConfidence,
    required this.declaredScoreablePreferenceCount,
    required this.comparablePreferenceCount,
    required this.explicitlyOpenPreferenceCount,
    required this.unavailablePreferenceCount,
    required this.comparablePreferenceIds,
    required this.openPreferenceIds,
    required this.excludedPreferences,
    required this.dimensionFits,
    required this.declaredImportanceMass,
    required this.comparableImportanceMass,
    required this.effectiveWeightSum,
    required this.evaluationCoverage,
    required this.profileDeclarationBreadth,
    required this.status,
    required this.configVersion,
    required this.registryVersion,
    required this.deterministicFingerprint,
    required this.diagnostics,
  }) {
    if (rawFitScore != null) {
      cmRequireFinite01(rawFitScore, 'rawFitScore', allowNull: false);
    }
    if (evidenceConfidence != null) {
      cmRequireFinite01(evidenceConfidence, 'evidenceConfidence',
          allowNull: false);
    }
  }

  factory DirectionalPreferenceFitResult.fromJson(Map<String, dynamic> j) =>
      DirectionalPreferenceFitResult(
        preferenceOwnerId: j['preference_owner_id']?.toString() ?? '',
        evaluatedSubjectId: j['evaluated_subject_id']?.toString() ?? '',
        rawFitScore: (j['raw_fit_score'] as num?)?.toDouble(),
        evidenceConfidence: (j['evidence_confidence'] as num?)?.toDouble(),
        declaredScoreablePreferenceCount:
            (j['declared_scoreable_preference_count'] as num?)?.toInt() ?? 0,
        comparablePreferenceCount:
            (j['comparable_preference_count'] as num?)?.toInt() ?? 0,
        explicitlyOpenPreferenceCount:
            (j['explicitly_open_preference_count'] as num?)?.toInt() ?? 0,
        unavailablePreferenceCount:
            (j['unavailable_preference_count'] as num?)?.toInt() ?? 0,
        comparablePreferenceIds: _sorted(j['comparable_preference_ids']),
        openPreferenceIds: _sorted(j['open_preference_ids']),
        excludedPreferences: [
          for (final e in (j['excluded_preferences'] as List?) ?? const [])
            DirectionalPreferenceFitExclusion.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        dimensionFits: [
          for (final e in (j['dimension_fits'] as List?) ?? const [])
            PreferenceDimensionFit.fromJson(
                Map<String, dynamic>.from(e as Map)),
        ],
        declaredImportanceMass:
            (j['declared_importance_mass'] as num).toDouble(),
        comparableImportanceMass:
            (j['comparable_importance_mass'] as num).toDouble(),
        effectiveWeightSum: (j['effective_weight_sum'] as num).toDouble(),
        evaluationCoverage: (j['evaluation_coverage'] as num?)?.toDouble(),
        profileDeclarationBreadth:
            (j['profile_declaration_breadth'] as num).toDouble(),
        status:
            parseDirectionalPreferenceFitStatus(j['status']?.toString() ?? ''),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
        deterministicFingerprint:
            j['deterministic_fingerprint']?.toString() ?? '',
        diagnostics: DirectionalPreferenceFitDiagnostics.fromJson(
          Map<String, dynamic>.from(j['diagnostics'] as Map? ?? {}),
        ),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'preference_owner_id': preferenceOwnerId,
        'evaluated_subject_id': evaluatedSubjectId,
        'raw_fit_score': rawFitScore,
        'evidence_confidence': evidenceConfidence,
        'declared_scoreable_preference_count': declaredScoreablePreferenceCount,
        'comparable_preference_count': comparablePreferenceCount,
        'explicitly_open_preference_count': explicitlyOpenPreferenceCount,
        'unavailable_preference_count': unavailablePreferenceCount,
        'comparable_preference_ids': comparablePreferenceIds,
        'open_preference_ids': openPreferenceIds,
        'excluded_preferences': [
          for (final e in excludedPreferences) e.toJson(),
        ],
        'dimension_fits': [for (final f in dimensionFits) f.toJson()],
        'declared_importance_mass': declaredImportanceMass,
        'comparable_importance_mass': comparableImportanceMass,
        'effective_weight_sum': effectiveWeightSum,
        'evaluation_coverage': evaluationCoverage,
        'profile_declaration_breadth': profileDeclarationBreadth,
        'status': status.wire,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'deterministic_fingerprint': deterministicFingerprint,
        'diagnostics': diagnostics.toJson(),
      });
}

class MutualPreferenceFitResult {
  final DirectionalPreferenceFitResult subjectAToBResult;
  final DirectionalPreferenceFitResult subjectBToAResult;
  final double? mutualRawFitScore;
  final double? mutualEvidenceConfidence;
  final double? directionalAsymmetry;
  final MutualPreferenceFitStatus status;
  final String configVersion;
  final String registryVersion;
  final String deterministicFingerprint;
  final DirectionalPreferenceFitDiagnostics diagnostics;

  MutualPreferenceFitResult({
    required this.subjectAToBResult,
    required this.subjectBToAResult,
    required this.mutualRawFitScore,
    required this.mutualEvidenceConfidence,
    required this.directionalAsymmetry,
    required this.status,
    required this.configVersion,
    required this.registryVersion,
    required this.deterministicFingerprint,
    required this.diagnostics,
  }) {
    if (mutualRawFitScore != null) {
      cmRequireFinite01(mutualRawFitScore, 'mutualRawFitScore',
          allowNull: false);
    }
    if (mutualEvidenceConfidence != null) {
      cmRequireFinite01(mutualEvidenceConfidence, 'mutualEvidenceConfidence',
          allowNull: false);
    }
  }

  factory MutualPreferenceFitResult.fromJson(Map<String, dynamic> j) =>
      MutualPreferenceFitResult(
        subjectAToBResult: DirectionalPreferenceFitResult.fromJson(
          Map<String, dynamic>.from(j['subject_a_to_b_result'] as Map),
        ),
        subjectBToAResult: DirectionalPreferenceFitResult.fromJson(
          Map<String, dynamic>.from(j['subject_b_to_a_result'] as Map),
        ),
        mutualRawFitScore: (j['mutual_raw_fit_score'] as num?)?.toDouble(),
        mutualEvidenceConfidence:
            (j['mutual_evidence_confidence'] as num?)?.toDouble(),
        directionalAsymmetry: (j['directional_asymmetry'] as num?)?.toDouble(),
        status: parseMutualPreferenceFitStatus(j['status']?.toString() ?? ''),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
        deterministicFingerprint:
            j['deterministic_fingerprint']?.toString() ?? '',
        diagnostics: DirectionalPreferenceFitDiagnostics.fromJson(
          Map<String, dynamic>.from(j['diagnostics'] as Map? ?? {}),
        ),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'subject_a_to_b_result': subjectAToBResult.toJson(),
        'subject_b_to_a_result': subjectBToAResult.toJson(),
        'mutual_raw_fit_score': mutualRawFitScore,
        'mutual_evidence_confidence': mutualEvidenceConfidence,
        'directional_asymmetry': directionalAsymmetry,
        'status': status.wire,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'deterministic_fingerprint': deterministicFingerprint,
        'diagnostics': diagnostics.toJson(),
      });
}
