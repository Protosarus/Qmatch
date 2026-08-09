/// Traceable canonical assessment source required for Persona shadow scoring.
///
/// A bare 20D vector without this metadata is not shadow-eligible.
class PersonaShadowSourceEvidence {
  const PersonaShadowSourceEvidence({
    required this.ownerUid,
    required this.iqCompleted,
    required this.eqCompleted,
    required this.frequencyCompleted,
    required this.iqScoringPolicyVersion,
    required this.eqScoringPolicyVersion,
    required this.frequencyScoringPolicyVersion,
    required this.iqBankOrSessionVersion,
    required this.eqBankOrSessionVersion,
    required this.frequencyBankOrSessionVersion,
    required this.dimensionEvidenceCounts,
  });

  final String ownerUid;
  final bool iqCompleted;
  final bool eqCompleted;
  final bool frequencyCompleted;
  final String iqScoringPolicyVersion;
  final String eqScoringPolicyVersion;
  final String frequencyScoringPolicyVersion;
  final String iqBankOrSessionVersion;
  final String eqBankOrSessionVersion;
  final String frequencyBankOrSessionVersion;

  /// Per-dimension evidence counts `n_j` from canonical assessments.
  final Map<String, int> dimensionEvidenceCounts;

  bool get allModulesCompleted =>
      iqCompleted && eqCompleted && frequencyCompleted;

  bool get hasAuthenticatedOwner => ownerUid.trim().isNotEmpty;

  bool get hasPolicyVersions =>
      iqScoringPolicyVersion.trim().isNotEmpty &&
      eqScoringPolicyVersion.trim().isNotEmpty &&
      frequencyScoringPolicyVersion.trim().isNotEmpty;

  bool get hasBankOrSessionVersions =>
      iqBankOrSessionVersion.trim().isNotEmpty &&
      eqBankOrSessionVersion.trim().isNotEmpty &&
      frequencyBankOrSessionVersion.trim().isNotEmpty;
}

/// Typed failure codes for shadow scoring eligibility.
enum PersonaShadowFailureCode {
  missingSourceEvidence,
  ownerUnavailable,
  incompleteAssessments,
  missingPolicyVersions,
  missingBankOrSessionVersions,
  incompleteDimensionScores,
  unknownDimension,
  legacyDimensionAlias,
  outOfRangeScore,
  missingEvidenceCount,
  insufficientGroupEvidence,
  incompatiblePrototypeVersion,
  incompatibleConfig,
}

class PersonaShadowScoringException implements Exception {
  PersonaShadowScoringException(this.code, this.message);
  final PersonaShadowFailureCode code;
  final String message;

  @override
  String toString() => 'PersonaShadowScoringException($code): $message';
}

/// Input to [CanonicalPersonaShadowScorer].
class PersonaShadowInput {
  const PersonaShadowInput({
    required this.dimensionScores,
    required this.source,
    required this.dimensionRegistryVersion,
  });

  /// Canonical 20D scores in [0,1].
  final Map<String, double> dimensionScores;
  final PersonaShadowSourceEvidence source;
  final String dimensionRegistryVersion;
}
