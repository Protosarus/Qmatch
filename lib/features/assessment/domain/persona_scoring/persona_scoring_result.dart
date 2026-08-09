import 'persona_candidate_score.dart';
import 'persona_scoring_status.dart';

class PersonaConfidenceComponents {
  final double totalCoverage;
  final Map<String, double> groupCoverage;
  final double criticalDimensionCoverage;
  final double meanReliability;
  final ResponseValidityStatus responseValidityStatus;
  final double? top2Margin;
  final String prototypeCalibrationStatus;
  final bool provisionalCalibrationMarker;

  const PersonaConfidenceComponents({
    required this.totalCoverage,
    required this.groupCoverage,
    required this.criticalDimensionCoverage,
    required this.meanReliability,
    required this.responseValidityStatus,
    required this.top2Margin,
    required this.prototypeCalibrationStatus,
    required this.provisionalCalibrationMarker,
  });
}

/// Immutable scoring result. Similarity is NOT probability.
class PersonaScoringResult {
  final PersonaScoringStatus status;
  final String? primaryPersonaId;
  final String? secondaryPersonaId;
  final double? primarySimilarity;
  final double? secondarySimilarity;
  final double? top2Margin;
  final bool ambiguous;
  final bool insufficientEvidence;
  final double totalCoverage;
  final Map<String, double> groupCoverage;
  final List<String> missingDimensions;
  final List<String> unavailableGroups;
  final List<String> failedEvidenceRules;
  final List<String> reasonCodes;
  final PersonaConfidenceLevel confidenceLevel;
  final double confidenceScore;
  final PersonaConfidenceComponents confidenceComponents;
  final List<String> confidenceReasonCodes;
  final List<PersonaCandidateScore> candidates;
  final List<String> separatorTargetsForTopPair;
  final String ambiguityReason;
  final String scoringVersion;
  final String personaProfileVersion;
  final String personaScoringConfigVersion;
  final String dimensionRegistryVersion;
  final String calibrationStatus;
  final bool productionValid;
  final bool publishablePrimary;

  const PersonaScoringResult({
    required this.status,
    required this.primaryPersonaId,
    required this.secondaryPersonaId,
    required this.primarySimilarity,
    required this.secondarySimilarity,
    required this.top2Margin,
    required this.ambiguous,
    required this.insufficientEvidence,
    required this.totalCoverage,
    required this.groupCoverage,
    required this.missingDimensions,
    required this.unavailableGroups,
    required this.failedEvidenceRules,
    required this.reasonCodes,
    required this.confidenceLevel,
    required this.confidenceScore,
    required this.confidenceComponents,
    required this.confidenceReasonCodes,
    required this.candidates,
    required this.separatorTargetsForTopPair,
    required this.ambiguityReason,
    required this.scoringVersion,
    required this.personaProfileVersion,
    required this.personaScoringConfigVersion,
    required this.dimensionRegistryVersion,
    required this.calibrationStatus,
    required this.productionValid,
    required this.publishablePrimary,
  });

  /// Compact fingerprint line for simulator/service parity checks.
  String fingerprintLine() {
    return '$primaryPersonaId|$secondaryPersonaId|'
        '${primarySimilarity?.toStringAsFixed(8)}|$insufficientEvidence|'
        '${status.name}|${confidenceLevel.name}|'
        '${top2Margin?.toStringAsFixed(8)}';
  }
}
