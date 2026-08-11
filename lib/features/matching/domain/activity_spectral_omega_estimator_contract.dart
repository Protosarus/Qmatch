/// Shadow-only global activity spectral omega estimator contract.
///
/// Detects Class B period \(T^\star\) from binned activity periodogram.
/// Never attaches to Frequency modes; never uses cadence/questionnaire fallback.
/// Near-24h / near-7d peaks are [ActivitySpectralOmegaStatus.civilCollision]
/// and must not emit Class B \(\omega\) (Class A civil oscillator path).
class ActivitySpectralOmegaEstimatorContract {
  ActivitySpectralOmegaEstimatorContract._();

  static const String scoringVersion =
      'periodicity_omega_estimator_activity_spectral_v1';
  static const String policyVersion = 'periodicity_omega_estimator_contract_v1';
  static const String policyStatus = 'shadow_only_not_live';

  static const bool shadowOnly = true;
  static const bool gatesCalibrated = false;
  static const bool attachesToFrequencyModes = false;
  static const bool cadenceFallbackAllowed = false;
  static const bool questionnaireOmegaAllowed = false;
  static const bool liveDiscoverRanking = false;

  static const String streamId = 'global_activity';
  static const String oscillatorIdPrefix = 'activity_spectral';

  /// Default bin width Δ.
  static const Duration binWidth = Duration(hours: 1);

  /// Secondary bin width for sensitivity check.
  static const Duration sensitivityBinWidth = Duration(hours: 2);

  static const int minEventsOk = 30;
  static const int minEventsSparse = 12;
  static const Duration minWindowOk = Duration(days: 14);
  static const Duration minWindowSparse = Duration(days: 7);
  static const double minCyclesOk = 3.0;

  /// Validated against `activity_spectral_omega_stress_v1`:
  /// random FP SNRs were ≤12.6 while noisy/clean accept SNRs were ≥~170.
  /// Provisional (gates_calibrated=false); raised from 6.0 to cut FPR without
  /// harming clean recall.
  static const double snrOk = 20.0;
  static const double snrSparse = 3.0;

  static const double splitHalfRelativeTolerance = 0.10;
  static const double binSensitivityRelativeTolerance = 0.10;

  /// Integer-harmonic ratio tolerance for T↔T/2↔T/3 family clustering.
  static const double harmonicRatioTolerance = 0.12;

  /// Prefer fundamental only if its SNR is within this factor of the family's
  /// strongest peak (leakage-consistent support).
  static const double fundamentalSupportSnrRatio = 3.0;

  /// Secondary non-harmonic peak ≥ this SNR competes with the primary family.
  static const double competingPeakSnrMin = 8.0;

  /// Primary/secondary SNR prominence; below this → competing ambiguity.
  /// Validated so 9h+14h dual streams reject while single clean streams pass.
  static const double competingProminenceSnrRatio = 4.0;

  static const double civilCollisionRelativeTolerance = 0.10;

  static const Duration minPeriodFloor = Duration(hours: 6);
  static const Duration maxPeriodCap = Duration(days: 14);

  static const Duration civilDay = Duration(days: 1);
  static const Duration civilWeek = Duration(days: 7);

  static const String reasonInsufficientEvents = 'insufficient_events';
  static const String reasonInsufficientWindow = 'insufficient_window';
  static const String reasonNoAdmissiblePeak = 'no_admissible_peak';
  static const String reasonLowSnr = 'low_snr';
  static const String reasonSplitHalfUnstable = 'split_half_unstable';
  static const String reasonBinSensitivity = 'bin_size_sensitivity';
  static const String reasonHarmonicAmbiguity = 'harmonic_ambiguity';
  static const String reasonMultiplePeaks = 'multiple_competing_peaks';
  static const String reasonCivilCollision = 'civil_collision';
  static const String reasonInsufficientCycles = 'insufficient_cycles';
  static const String reasonEmptyTimestamps = 'empty_timestamps';
  static const String reasonInvalidWindow = 'invalid_window';
}
