import 'dimension_score_result.dart';
import 'response_validity_result.dart';

enum ModuleTraitStatus {
  incomplete,
  insufficientEvidence,
  provisional,
  readyForShadowEvaluation,
}

class ModuleTraitResult {
  final String assessmentType;
  final String schemaVersion;
  final String contentVersion;
  final String traitScoringVersion;
  final String rviVersion;
  final String setId;
  final String locale;
  final int questionCount;
  final int answeredCount;
  final Map<String, Object?> rawAnswers;
  final int? legacyRawScore;
  final Map<String, double> dimensionScores;
  final Map<String, double> dimensionEvidenceCounts;
  final Map<String, double> dimensionPrimaryEvidenceCounts;
  final Map<String, double> dimensionSecondaryEvidenceCounts;
  final Map<String, double> dimensionIndependentContextCounts;
  final Map<String, double> dimensionEvidenceSufficiency;
  final Map<String, double> dimensionReliability;
  final List<String> missingDimensions;
  final List<String> insufficientDimensions;
  final ResponseValidityResult responseValidity;
  final bool canonicalProfileReady;
  final ModuleTraitStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> reasonCodes;
  final List<DimensionScoreResult> dimensionDetails;

  const ModuleTraitResult({
    required this.assessmentType,
    required this.schemaVersion,
    required this.contentVersion,
    required this.traitScoringVersion,
    required this.rviVersion,
    required this.setId,
    required this.locale,
    required this.questionCount,
    required this.answeredCount,
    required this.rawAnswers,
    required this.legacyRawScore,
    required this.dimensionScores,
    required this.dimensionEvidenceCounts,
    required this.dimensionPrimaryEvidenceCounts,
    required this.dimensionSecondaryEvidenceCounts,
    required this.dimensionIndependentContextCounts,
    required this.dimensionEvidenceSufficiency,
    required this.dimensionReliability,
    required this.missingDimensions,
    required this.insufficientDimensions,
    required this.responseValidity,
    required this.canonicalProfileReady,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.reasonCodes,
    required this.dimensionDetails,
  });
}

class TraitScoringResult {
  final ModuleTraitResult module;

  const TraitScoringResult({required this.module});
}
