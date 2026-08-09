/// One Persona candidate under shadow distance scoring.
class PersonaShadowCandidate {
  const PersonaShadowCandidate({
    required this.personaId,
    required this.distance,
    required this.coreDistance,
    required this.levelDistance,
    required this.shapeDistance,
    required this.antiTraitPenalty,
    required this.minimumEvidencePenalty,
    required this.tieBreakRank,
    required this.levelByGroup,
    required this.shapeByGroup,
  });

  final String personaId;
  final double distance;
  final double coreDistance;
  final double levelDistance;
  final double shapeDistance;
  final double antiTraitPenalty;
  final double minimumEvidencePenalty;
  final int tieBreakRank;
  final Map<String, double> levelByGroup;
  final Map<String, double> shapeByGroup;
}

/// Shadow-only Persona result. Not a user-facing Persona assignment.
class PersonaShadowResult {
  const PersonaShadowResult({
    required this.scoringVersion,
    required this.prototypeVersion,
    required this.policyVersion,
    required this.configVersion,
    required this.primaryCandidateId,
    required this.secondaryCandidateId,
    required this.allPersonaDistances,
    required this.top2DistanceMargin,
    required this.candidates,
    required this.dimensionEvidenceSufficiency,
    required this.shadowOnly,
  });

  final String scoringVersion;
  final String prototypeVersion;
  final String policyVersion;
  final String configVersion;
  final String primaryCandidateId;
  final String secondaryCandidateId;
  final Map<String, double> allPersonaDistances;
  final double top2DistanceMargin;
  final List<PersonaShadowCandidate> candidates;
  final Map<String, double> dimensionEvidenceSufficiency;

  final bool shadowOnly;

  // Explicit non-production metadata (frozen for this phase).
  String get reliabilityStatus => 'not_calibrated';
  bool get reliabilityFactorApplied => false;
  String get shadowQualityPolicy => 'persona_shadow_evidence_only_v1';
  String get temperatureStatus => 'unresolved';
  bool get temperatureApplied => false;
  bool get affinityNotComputed => true;
  bool get confidenceNotComputed => true;
  String get confidenceStatus => 'not_calibrated';
  String get top2ThresholdStatus => 'unresolved';
  String get top2MarginBand => 'not_computed';
  String get alphaStatus => 'provisional_config';
  String get antiTraitPolicy => 'provisional_v2_existing_rules';
}
