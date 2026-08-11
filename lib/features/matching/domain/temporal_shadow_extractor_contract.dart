/// Shadow-only temporal feature extraction contract (v1).
///
/// Offline diagnostics from existing thread message metadata only.
/// No Discover ranking/UI, Persona, quantum, RVI, omega, or questionnaire
/// temporal fabrication.
class TemporalShadowExtractorContract {
  TemporalShadowExtractorContract._();

  static const String scoringVersion = 'temporal_feature_extraction_v1';
  static const String policyStatus = 'specification_only_not_live';
  static const bool shadowOnly = true;
  static const bool gatesCalibrated = false;
  static const bool omegaEnabled = false;
  static const String circadianOscillatorId = 'circadian_24h';
  static const String systemSenderId = 'system';

  /// Provisional reply-gap timeout (not calibrated).
  static const Duration replyTimeout = Duration(hours: 24);

  static const Duration oneDay = Duration(days: 1);
  static const Duration threeDays = Duration(days: 3);
  static const Duration sevenDays = Duration(days: 7);

  static const double circadianOkR = 0.35;
  static const double circadianSparseR = 0.20;
}
