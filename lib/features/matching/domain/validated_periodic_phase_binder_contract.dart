import 'l4_temporal_diagnostics_contract.dart';

/// Research-shadow Class-B validated periodic phase binder.
///
/// Not L4 v1 production-promoted. Binds phase on the same accepted oscillator
/// from [ActivitySpectralOmegaEstimator]. Never Discover / Frequency modes.
class ValidatedPeriodicPhaseBinderContract {
  ValidatedPeriodicPhaseBinderContract._();

  static const String scoringVersion =
      'validated_periodic_phase_binder_activity_spectral_v1';
  static const String policyVersion = 'periodicity_omega_estimator_contract_v1';
  static const String policyStatus = 'shadow_only_not_live';
  static const String l4V1Role = 'research_shadow';
  static const bool productionPromoted =
      L4TemporalDiagnosticsContract.periodicPhaseProductionPromoted;

  static const bool shadowOnly = true;
  static const bool gatesCalibrated =
      L4TemporalDiagnosticsContract.gatesCalibrated;
  static const bool attachesToFrequencyModes = false;
  static const bool feedsSixModeRWave = false;
  static const bool liveDiscoverRanking = false;
  static const bool questionnairePhaseAllowed = false;

  static const String sourceId =
      'validated_periodic_phase_binder_activity_spectral_v1';

  /// Provisional concentration gate (not calibrated).
  static const double minRBarOk = 0.35;

  /// Minimum events inside the fold window (omega ok already implies volume;
  /// this is a phase-side floor).
  static const int minEventsOk = 10;

  /// Deterministic Class-B epoch policy: UTC window start.
  static const String referenceEpochPolicy = 'window_start_utc';

  static const String reasonOmegaNotOk = 'omega_not_ok';
  static const String reasonCivilCollision = 'civil_collision';
  static const String reasonOmegaAmbiguous = 'omega_ambiguous';
  static const String reasonOmegaSparse = 'omega_sparse';
  static const String reasonOmegaUnavailable = 'omega_unavailable';
  static const String reasonMissingOscillator = 'missing_oscillator_id';
  static const String reasonMissingPeriod = 'missing_period';
  static const String reasonInsufficientEvents = 'insufficient_events';
  static const String reasonLowConcentration = 'low_resultant_length';
  static const String reasonInvalidWindow = 'invalid_window';
  static const String reasonOmegaMismatch = 'omega_period_mismatch';
}
