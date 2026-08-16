import 'l4_temporal_diagnostics_contract.dart';

/// L4 v1 post-match temporal feature extraction.
///
/// Production diagnostics from existing thread message metadata only.
/// Class B omega is out of scope here (always unavailable).
/// No Discover ranking, Persona, questionnaire φ/ω, or pre-match inference.
class TemporalShadowExtractorContract {
  TemporalShadowExtractorContract._();

  static const String scoringVersion = 'temporal_feature_extraction_v1';
  static const String policyVersion =
      L4TemporalDiagnosticsContract.policyVersion;
  static const String policyStatus =
      L4TemporalDiagnosticsContract.policyStatus;
  static const bool shadowOnly = L4TemporalDiagnosticsContract.shadowOnly;
  static const bool gatesCalibrated =
      L4TemporalDiagnosticsContract.gatesCalibrated;
  static const bool omegaEnabled = false;
  static const bool affectsDiscoverRanking =
      L4TemporalDiagnosticsContract.affectsDiscoverRanking;
  static const String circadianOscillatorId =
      L4TemporalDiagnosticsContract.circadianOscillatorIdAlias;
  static const String systemSenderId = 'system';

  /// Provisional reply-gap timeout (not calibrated).
  static const Duration replyTimeout = Duration(hours: 24);

  static const Duration oneDay = Duration(days: 1);
  static const Duration threeDays = Duration(days: 3);
  static const Duration sevenDays = Duration(days: 7);

  static const double circadianOkR = 0.35;
  static const double circadianSparseR = 0.20;
}
