/// One provisional anti-trait rule for a persona prototype.
class PersonaAntiTrait {
  final String dimensionId;
  final String direction; // below | above
  final double threshold;
  final double severity;
  final String rationale;
  final int minimumEvidenceRequired;

  const PersonaAntiTrait({
    required this.dimensionId,
    required this.direction,
    required this.threshold,
    required this.severity,
    required this.rationale,
    required this.minimumEvidenceRequired,
  });
}

/// Persona-specific minimum evidence requirements.
class PersonaMinimumEvidence {
  final List<String> requiredGroups;
  final Map<String, double> minimumGroupCoverage;
  final List<String> criticalDimensions;
  final int minimumEvidencePerCriticalDimension;
  final double minimumTotalCoverage;

  const PersonaMinimumEvidence({
    required this.requiredGroups,
    required this.minimumGroupCoverage,
    required this.criticalDimensions,
    required this.minimumEvidencePerCriticalDimension,
    required this.minimumTotalCoverage,
  });
}

/// Immutable provisional persona prototype (20D).
class PersonaPrototype {
  final String personaId;
  final Map<String, String> labels;
  final Map<String, double> targetVector;
  final Map<String, double> dimensionWeights;
  final List<String> primaryDimensions;
  final List<String> supportingDimensions;
  final List<String> neutralDimensions;
  final List<PersonaAntiTrait> antiTraits;
  final PersonaMinimumEvidence minimumEvidence;
  final List<String> closestCompetitors;
  final Map<String, List<String>> separatorTargets;
  final int tieBreakRank;
  final Map<String, String> rationale;
  final String status;

  const PersonaPrototype({
    required this.personaId,
    required this.labels,
    required this.targetVector,
    required this.dimensionWeights,
    required this.primaryDimensions,
    required this.supportingDimensions,
    required this.neutralDimensions,
    required this.antiTraits,
    required this.minimumEvidence,
    required this.closestCompetitors,
    required this.separatorTargets,
    required this.tieBreakRank,
    required this.rationale,
    required this.status,
  });
}

/// Validated catalog of prototypes + metadata.
class PersonaProfileCatalog {
  final String schemaVersion;
  final String personaProfileVersion;
  final String dimensionRegistryVersion;
  final String status;
  final String calibrationStatus;
  final List<String> dimensionOrder;
  final Map<String, double> groupWeights;
  final List<PersonaPrototype> personas;
  final Map<String, PersonaPrototype> byId;

  const PersonaProfileCatalog({
    required this.schemaVersion,
    required this.personaProfileVersion,
    required this.dimensionRegistryVersion,
    required this.status,
    required this.calibrationStatus,
    required this.dimensionOrder,
    required this.groupWeights,
    required this.personas,
    required this.byId,
  });

  bool get isSyntheticValidationOnly =>
      calibrationStatus == 'synthetic_validation_only' ||
      status == 'provisional';
}
