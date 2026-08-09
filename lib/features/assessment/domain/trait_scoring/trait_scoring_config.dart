class DimensionRequirement {
  final String module;
  final double minimumPrimaryEvidence;
  final double minimumTotalEvidence;
  final double targetPrimaryEvidence;
  final double targetTotalEvidence;
  final double maximumSingleItemInfluence;
  final double minimumIndependentContexts;
  final double minimumReliability;
  final bool requiredForProfileReadiness;
  final bool requiredForPersona;

  const DimensionRequirement({
    required this.module,
    required this.minimumPrimaryEvidence,
    required this.minimumTotalEvidence,
    required this.targetPrimaryEvidence,
    required this.targetTotalEvidence,
    required this.maximumSingleItemInfluence,
    required this.minimumIndependentContexts,
    required this.minimumReliability,
    required this.requiredForProfileReadiness,
    required this.requiredForPersona,
  });
}

class TraitScoringConfig {
  final String schemaVersion;
  final String configVersion;
  final String status;
  final String dimensionRegistryVersion;
  final String questionSchemaVersion;
  final String traitScoringVersion;
  final String rviVersion;
  final Map<String, DimensionRequirement> dimensionRequirements;
  final Map<String, double> reliabilityWeights;
  final Map<String, double> rviWeights;
  final bool renormalizeReliabilityOverAvailable;
  final bool renormalizeRviOverAvailable;
  final double sameContextDiminishingFactor;
  final double defaultIqItemWeight;
  final bool enableCalibratedIqItemWeights;
  final double maxAbsPrimaryDelta;
  final int maxDimsPerOption;
  final double maxL1DeltaMagnitude;

  const TraitScoringConfig({
    required this.schemaVersion,
    required this.configVersion,
    required this.status,
    required this.dimensionRegistryVersion,
    required this.questionSchemaVersion,
    required this.traitScoringVersion,
    required this.rviVersion,
    required this.dimensionRequirements,
    required this.reliabilityWeights,
    required this.rviWeights,
    required this.renormalizeReliabilityOverAvailable,
    required this.renormalizeRviOverAvailable,
    required this.sameContextDiminishingFactor,
    required this.defaultIqItemWeight,
    required this.enableCalibratedIqItemWeights,
    required this.maxAbsPrimaryDelta,
    required this.maxDimsPerOption,
    required this.maxL1DeltaMagnitude,
  });

  DimensionRequirement requireDimension(String id) {
    final d = dimensionRequirements[id];
    if (d == null) {
      throw StateError('Unknown dimension requirement: $id');
    }
    return d;
  }
}
