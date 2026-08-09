/// Canonical Frequency 6D scoring policy (P2C-2A-8R1).
///
/// Uncalibrated launch policy: every explicit delta contribution uses a_ij = 1.
/// Does not invent q_i, d_ij, or e_ij.
class FrequencyScoringContract {
  FrequencyScoringContract._();

  static const String schemaVersion =
      'qmatch_frequency_canonical_scoring_result_v1';

  /// Uncalibrated signed-evidence mean; not empirically weighted.
  static const String scoringPolicyVersion =
      'frequency_6d_uncalibrated_signed_evidence_v1';

  static const String calibrationStatus = 'uncalibrated';
  static const String reliabilityStatus = 'not_calibrated';
  static const String rviRuntimeGate = 'NOT_CALIBRATED / NOT_ACTIVE';
}

enum FrequencyCalibrationStatus {
  uncalibrated('uncalibrated');

  const FrequencyCalibrationStatus(this.wireValue);
  final String wireValue;
}

enum FrequencyReliabilityStatus {
  notCalibrated('not_calibrated');

  const FrequencyReliabilityStatus(this.wireValue);
  final String wireValue;
}

enum FrequencyDimensionEvidenceStatus {
  measured('measured'),
  insufficientEvidence('insufficient_evidence');

  const FrequencyDimensionEvidenceStatus(this.wireValue);
  final String wireValue;
}
