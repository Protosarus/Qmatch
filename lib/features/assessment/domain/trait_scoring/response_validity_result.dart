enum ResponseValidityStatusBand {
  insufficientEvidence,
  lowValidity,
  provisional,
  acceptableForShadowEvaluation,
}

class ResponseValidityResult {
  final String rviVersion;
  final double overallScore;
  final Map<String, double> componentScores;
  final List<String> availableComponents;
  final List<String> missingComponents;
  final ResponseValidityStatusBand status;
  final List<String> reasonCodes;
  final bool retestRecommended;
  final bool publishableRecommendation;

  const ResponseValidityResult({
    required this.rviVersion,
    required this.overallScore,
    required this.componentScores,
    required this.availableComponents,
    required this.missingComponents,
    required this.status,
    required this.reasonCodes,
    required this.retestRecommended,
    required this.publishableRecommendation,
  });
}
