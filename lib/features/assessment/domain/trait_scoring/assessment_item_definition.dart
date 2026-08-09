class AssessmentOptionDefinition {
  final String optionId;
  final Map<String, String> localizedText;
  final Map<String, double> dimensionDeltas;
  final double evidenceStrength;
  final String socialDesirabilityRisk;
  final double extremity;
  final String responseStyleRisk;
  final String status;
  final bool isCorrect; // IQ only

  const AssessmentOptionDefinition({
    required this.optionId,
    required this.localizedText,
    required this.dimensionDeltas,
    required this.evidenceStrength,
    required this.socialDesirabilityRisk,
    required this.extremity,
    required this.responseStyleRisk,
    required this.status,
    this.isCorrect = false,
  });
}

class AssessmentItemDefinition {
  final String questionId;
  final String module; // iq | eq | frequency
  final String schemaVersion;
  final String contentVersion;
  final String itemType;
  final String primaryDimension;
  final List<String> secondaryDimensions;
  final Map<String, String> prompt;
  final List<AssessmentOptionDefinition> options;
  final String? correctOptionId;
  final String? solutionMethod;
  final int? difficulty;
  final String? anchorGroup;
  final String? semanticPairId;
  final String? reversePairId;
  final String? behavioralIsomorphGroup;
  final List<String> separatorTargets;
  final List<String> responseValidityRoles;
  final String exposureClass;
  final String securityLevel;
  final double estimatedCompletionSeconds;
  final bool reverseScoredLikert;
  final Map<String, Map<String, double>>? scalePointDeltas;

  const AssessmentItemDefinition({
    required this.questionId,
    required this.module,
    required this.schemaVersion,
    required this.contentVersion,
    required this.itemType,
    required this.primaryDimension,
    required this.secondaryDimensions,
    required this.prompt,
    required this.options,
    this.correctOptionId,
    this.solutionMethod,
    this.difficulty,
    this.anchorGroup,
    this.semanticPairId,
    this.reversePairId,
    this.behavioralIsomorphGroup,
    this.separatorTargets = const [],
    this.responseValidityRoles = const [],
    required this.exposureClass,
    required this.securityLevel,
    required this.estimatedCompletionSeconds,
    this.reverseScoredLikert = false,
    this.scalePointDeltas,
  });

  String get contextIdentity =>
      behavioralIsomorphGroup ?? semanticPairId ?? reversePairId ?? questionId;
}
