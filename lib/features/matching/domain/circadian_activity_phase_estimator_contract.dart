import 'dart:math' as math;

import 'l4_temporal_diagnostics_contract.dart';

/// L4 v1 conditional Class A circadian diagnostic (global activity clock).
///
/// Emits [PhaseReferenceV2] for oscillator `circadian_activity_24h` only when
/// timezone + evidence gates pass. Never attaches to Frequency 6D modes.
/// Not a Discover ranker. `last_active_at` is not an input.
class CircadianActivityPhaseEstimatorContract {
  CircadianActivityPhaseEstimatorContract._();

  static const String scoringVersion =
      'temporal_phase_estimator_circadian_activity_v1';
  static const String policyVersion = 'temporal_phase_estimator_contract_v1';
  static const String policyStatus =
      L4TemporalDiagnosticsContract.policyStatus;
  static const String l4V1Role = 'conditional_diagnostic';

  static const bool shadowOnly = true;
  static const bool gatesCalibrated =
      L4TemporalDiagnosticsContract.gatesCalibrated;
  static const bool productionPromoted =
      L4TemporalDiagnosticsContract.circadianUnconditionalProductionPromoted;
  static const bool conditionalDiagnostic =
      L4TemporalDiagnosticsContract.circadianConditionalDiagnostic;
  static const bool attachesToFrequencyModes = false;
  static const bool feedsSixModeRWave = false;
  static const bool estimatesFreeOmega = false;
  static const bool questionnairePhaseAllowed = false;
  static const bool liveDiscoverRanking = false;

  static const String oscillatorId = 'circadian_activity_24h';
  static const String sourceId =
      'temporal_phase_estimator_circadian_activity_v1';

  static const double periodSeconds = 86400.0;
  static final double fixedOmega = 2 * math.pi / periodSeconds;

  /// Provisional gates (not calibrated).
  static const int minEventsOk = 10;
  static const int minDistinctLocalDaysOk = 4;
  static const double minRBarOk = 0.35;

  static const String reasonMissingTimezone = 'missing_timezone';
  static const String reasonInsufficientEvents = 'insufficient_events';
  static const String reasonInsufficientDays = 'insufficient_distinct_days';
  static const String reasonLowConcentration = 'low_resultant_length';
  static const String reasonNoEvents = 'no_events';
}
