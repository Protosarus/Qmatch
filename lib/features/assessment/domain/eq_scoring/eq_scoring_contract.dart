/// Canonical EQ 10D scoring policy (P2C-2A-7R1).
///
/// Uncalibrated launch policy: every explicit delta contribution uses a_ij = 1.
/// Does not invent q_i, d_ij, or e_ij.
class EqScoringContract {
  EqScoringContract._();

  static const String schemaVersion = 'qmatch_eq_canonical_scoring_result_v1';

  /// Uncalibrated signed-evidence mean; not empirically weighted.
  static const String scoringPolicyVersion =
      'eq_10d_uncalibrated_signed_evidence_v1';

  static const String calibrationStatus = 'uncalibrated';
  static const String reliabilityStatus = 'not_calibrated';
  static const String rviRuntimeGate = 'NOT_CALIBRATED / NOT_ACTIVE';
}

enum EqCalibrationStatus {
  uncalibrated('uncalibrated');

  const EqCalibrationStatus(this.wireValue);
  final String wireValue;
}

enum EqReliabilityStatus {
  notCalibrated('not_calibrated');

  const EqReliabilityStatus(this.wireValue);
  final String wireValue;
}

enum EqDimensionEvidenceStatus {
  measured('measured'),
  insufficientEvidence('insufficient_evidence');

  const EqDimensionEvidenceStatus(this.wireValue);
  final String wireValue;
}
