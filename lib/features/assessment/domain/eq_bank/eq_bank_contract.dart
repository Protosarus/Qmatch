/// Offline / runtime-candidate EQ bank contracts (P2C-2A-7R1).
class EqBankContract {
  EqBankContract._();

  static const String schemaVersion = 'qmatch_eq_bank_v1';
  static const String scoringPolicyVersion =
      'eq_10d_uncalibrated_signed_evidence_v1';

  static const String trBankVersion = 'eq_bank_tr_v1';
  static const String enBankVersion = 'eq_bank_en_v1';

  static const String trAssetPath =
      'assets/data/assessment_v3/eq/eq_bank_tr_v1.json';
  static const String enAssetPath =
      'assets/data/assessment_v3/eq/eq_bank_en_v1.json';

  /// Not registered in pubspec until live EQ migration (R2+).
  /// Offline tests load these via filesystem paths.
  static const bool registeredInPubspec = false;

  static const int sessionItemCount = 30;
  static const int primaryItemsPerDimension = 3;
  static const int optionsPerItem = 4;

  static const String statusRuntimeCandidate = 'runtime_candidate';
  static const String calibrationUncalibrated = 'uncalibrated';
  static const String reliabilityNotCalibrated = 'not_calibrated';
  static const String rviGateNotActive = 'NOT_CALIBRATED / NOT_ACTIVE';
}
