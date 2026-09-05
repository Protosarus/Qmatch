/// Native Persona V2 assignment input.
///
/// IQ/EQ are unit scores in [0, 1]. Frequency V2 is already converted from
/// signed behavior into [0, 1]. No Frequency V1 6D fields are present.
class PersonaV2HandoffRequest {
  const PersonaV2HandoffRequest({
    required this.ownerUid,
    required this.dimensionScores,
    required this.dimensionEvidenceCounts,
    required this.iqScoringPolicyVersion,
    required this.eqScoringPolicyVersion,
    required this.frequencyV2ScoringPolicyVersion,
    required this.iqBankOrSessionVersion,
    required this.eqBankOrSessionVersion,
    required this.frequencyV2BankOrSessionVersion,
  });

  final String ownerUid;
  final Map<String, double> dimensionScores;
  final Map<String, int> dimensionEvidenceCounts;
  final String iqScoringPolicyVersion;
  final String eqScoringPolicyVersion;
  final String frequencyV2ScoringPolicyVersion;
  final String iqBankOrSessionVersion;
  final String eqBankOrSessionVersion;
  final String frequencyV2BankOrSessionVersion;
}
