/// Structured explainability for one persona candidate (no NL claims).
class PersonaGroupDistanceBreakdown {
  final String group;
  final bool available;
  final double? levelDistance;
  final double? shapeDistance;
  final double? combinedDistance;
  final double configuredGroupWeight;
  final double appliedGroupWeight;

  const PersonaGroupDistanceBreakdown({
    required this.group,
    required this.available,
    required this.levelDistance,
    required this.shapeDistance,
    required this.combinedDistance,
    required this.configuredGroupWeight,
    required this.appliedGroupWeight,
  });
}

class AppliedAntiTraitEvidence {
  final String dimensionId;
  final String direction;
  final double threshold;
  final double observedValue;
  final double severity;
  final String rationale;

  const AppliedAntiTraitEvidence({
    required this.dimensionId,
    required this.direction,
    required this.threshold,
    required this.observedValue,
    required this.severity,
    required this.rationale,
  });
}

class PersonaCandidateScore {
  final String personaId;
  final double similarity;
  final double distance;
  final double baseDistance;
  final double antiTraitPenalty;
  final double missingEvidencePenalty;
  final int tieBreakRank;
  final bool eligibleForPublishableRanking;
  final bool nonPublishableDiagnosticOnly;
  final List<PersonaGroupDistanceBreakdown> groupDistances;
  final List<String> strongestSupportingDimensions;
  final List<String> strongestCounterEvidenceDimensions;
  final List<AppliedAntiTraitEvidence> appliedAntiTraits;
  final List<String> missingCriticalEvidence;
  final List<String> closestCompetitors;
  final Map<String, List<String>> separatorTargets;

  const PersonaCandidateScore({
    required this.personaId,
    required this.similarity,
    required this.distance,
    required this.baseDistance,
    required this.antiTraitPenalty,
    required this.missingEvidencePenalty,
    required this.tieBreakRank,
    required this.eligibleForPublishableRanking,
    required this.nonPublishableDiagnosticOnly,
    required this.groupDistances,
    required this.strongestSupportingDimensions,
    required this.strongestCounterEvidenceDimensions,
    required this.appliedAntiTraits,
    required this.missingCriticalEvidence,
    required this.closestCompetitors,
    required this.separatorTargets,
  });
}
