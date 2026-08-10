/// Runtime handoff request: complete canonical 20D + evidence + versions.
///
/// Does not load Firestore. Does not invent missing scores or evidence.
class PersonaRuntimeHandoffRequest {
  const PersonaRuntimeHandoffRequest({
    required this.ownerUid,
    required this.dimensionScores,
    required this.dimensionEvidenceCounts,
    required this.iqCompleted,
    required this.eqCompleted,
    required this.frequencyCompleted,
    required this.iqScoringPolicyVersion,
    required this.eqScoringPolicyVersion,
    required this.frequencyScoringPolicyVersion,
    required this.iqBankOrSessionVersion,
    required this.eqBankOrSessionVersion,
    required this.frequencyBankOrSessionVersion,
    required this.dimensionRegistryVersion,
  });

  final String ownerUid;

  /// Canonical 20D scores in [0, 1]. Must include every registry dimension.
  final Map<String, double> dimensionScores;

  /// Per-dimension evidence counts `n_j` (must cover all 20 dims).
  final Map<String, int> dimensionEvidenceCounts;

  final bool iqCompleted;
  final bool eqCompleted;
  final bool frequencyCompleted;

  final String iqScoringPolicyVersion;
  final String eqScoringPolicyVersion;
  final String frequencyScoringPolicyVersion;

  final String iqBankOrSessionVersion;
  final String eqBankOrSessionVersion;
  final String frequencyBankOrSessionVersion;

  final String dimensionRegistryVersion;
}
