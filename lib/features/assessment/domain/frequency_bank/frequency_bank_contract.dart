/// Offline Frequency bank contracts (P2C-2A-8R1 / R1A).
class FrequencyBankContract {
  FrequencyBankContract._();

  static const String schemaVersion = 'qmatch_frequency_bank_v1';
  static const String scoringPolicyVersion =
      'frequency_6d_uncalibrated_signed_evidence_v1';

  static const String trBankVersion = 'frequency_bank_tr_v1';
  static const String enBankVersion = 'frequency_bank_en_v1';

  static const String trAssetPath =
      'assets/data/assessment_v3/frequency/frequency_bank_tr_v1.json';
  static const String enAssetPath =
      'assets/data/assessment_v3/frequency/frequency_bank_en_v1.json';

  /// Offline pilot sources (not runtime candidates).
  static const String pilotTrPath =
      'assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json';

  /// Not registered in pubspec until live Frequency migration (R2+).
  static const bool registeredInPubspec = true;

  static const int sessionItemCount = 50;
  static const int coreItemCount = 30;
  static const int behavioralEquivalenceItemCount = 12;
  static const int separatorItemCount = 6;
  static const int qualityItemCount = 2;
  static const int primaryCoreItemsPerDimension = 5;
  static const int relatedItemsPerDimension = 2;
  static const int optionsPerItem = 4;
  static const int minSeparatorDimensions = 2;

  static const String statusRuntimeCandidate = 'runtime_candidate';
  static const String statusMathFixture = 'math_fixture';
  static const String calibrationUncalibrated = 'uncalibrated';
  static const String reliabilityNotCalibrated = 'not_calibrated';
  static const String rviGateNotActive = 'NOT_CALIBRATED / NOT_ACTIVE';

  static const String itemRoleCore = 'core';
  static const String itemRoleBehavioralEquivalence = 'behavioral_equivalence';
  static const String itemRoleSeparator = 'separator';
  static const String itemRoleQuality = 'response_quality';

  static const String separatorTypeDimensionBoundary = 'dimension_boundary';

  static const List<String> authoredSeparatorIds = [
    'freq_separator_depth_comm_v1',
    'freq_separator_social_stability_v1',
    'freq_separator_spontaneity_stability_v1',
    'freq_separator_disclosure_depth_v1',
    'freq_separator_comm_stability_v1',
    'freq_separator_social_disclosure_v1',
  ];

  static const List<String> authoredQualityIds = [
    'freq_quality_instruction_v1',
    'freq_quality_protocol_v1',
  ];
}
