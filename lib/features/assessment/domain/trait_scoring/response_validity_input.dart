/// Optional precomputed or raw RVI observation bags for the engine.
class ResponseValidityInput {
  final Map<String, double>? semanticPairAgreements;
  final Map<String, double>? reversePairAgreements;
  final Map<String, double>? isomorphStability;
  final double? impressionRiskOverride;

  const ResponseValidityInput({
    this.semanticPairAgreements,
    this.reversePairAgreements,
    this.isomorphStability,
    this.impressionRiskOverride,
  });
}
