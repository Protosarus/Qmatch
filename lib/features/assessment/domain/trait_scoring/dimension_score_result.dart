enum DimensionScoreStatus {
  unavailable,
  insufficient,
  provisional,
  readyForShadowEvaluation,
}

class DimensionEvidenceTrace {
  final String questionId;
  final String dimensionId;
  final double delta;
  final double evidenceStrength;
  final bool primary;
  final String contextIdentity;
  final bool reverseAligned;
  final double appliedWeight;

  const DimensionEvidenceTrace({
    required this.questionId,
    required this.dimensionId,
    required this.delta,
    required this.evidenceStrength,
    required this.primary,
    required this.contextIdentity,
    required this.reverseAligned,
    required this.appliedWeight,
  });
}

class DimensionScoreResult {
  final String dimensionId;
  final String module;
  final double? score;
  final double signedEvidenceMean;
  final double primaryEvidenceCount;
  final double secondaryEvidenceCount;
  final double totalEvidenceCount;
  final double independentContextCount;
  final double evidenceSufficiency;
  final double reliability;
  final DimensionScoreStatus status;
  final List<String> failedEvidenceRules;
  final List<DimensionEvidenceTrace> traces;
  final Map<String, double> reliabilityComponents;

  const DimensionScoreResult({
    required this.dimensionId,
    required this.module,
    required this.score,
    required this.signedEvidenceMean,
    required this.primaryEvidenceCount,
    required this.secondaryEvidenceCount,
    required this.totalEvidenceCount,
    required this.independentContextCount,
    required this.evidenceSufficiency,
    required this.reliability,
    required this.status,
    required this.failedEvidenceRules,
    required this.traces,
    required this.reliabilityComponents,
  });

  bool get publishable =>
      status == DimensionScoreStatus.readyForShadowEvaluation ||
      status == DimensionScoreStatus.provisional;
}
