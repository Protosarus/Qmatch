import 'activity_spectral_omega_estimator_contract.dart';

/// Periodicity quality status for spectral omega detection.
enum ActivitySpectralOmegaStatus {
  ok,
  sparse,
  ambiguous,

  /// Near-24h / near-7d — not Class B; Class A civil oscillator path only.
  civilCollision,
  unavailable,
}

/// One spectral peak candidate (diagnostics).
class ActivitySpectralPeakCandidate {
  const ActivitySpectralPeakCandidate({
    required this.periodSeconds,
    required this.power,
    required this.snr,
  });

  final double periodSeconds;
  final double power;
  final double snr;

  Map<String, dynamic> toWireMap() => {
        'period_seconds': periodSeconds,
        'power': power,
        'snr': snr,
      };
}

/// Shadow-only spectral omega estimate on global activity timestamps.
class ActivitySpectralOmegaEstimate {
  const ActivitySpectralOmegaEstimate({
    required this.status,
    required this.reason,
    required this.eventCount,
    required this.windowSeconds,
    required this.binWidthSeconds,
    required this.periodSeconds,
    required this.omega,
    required this.snr,
    required this.splitHalfRelativeDelta,
    required this.binSensitivityRelativeDelta,
    required this.nearCivilCollision,
    required this.civilCollisionKind,
    required this.candidatePeaks,
    required this.oscillatorId,
  });

  final ActivitySpectralOmegaStatus status;
  final String? reason;
  final int eventCount;
  final double windowSeconds;
  final double binWidthSeconds;

  /// Detected \(T^\star\) when a peak was selected (may be non-ok diagnostic).
  final double? periodSeconds;

  /// \(2\pi/T^\star\) only when status is [ActivitySpectralOmegaStatus.ok].
  /// Never set for [ActivitySpectralOmegaStatus.civilCollision].
  final double? omega;

  final double? snr;
  final double? splitHalfRelativeDelta;
  final double? binSensitivityRelativeDelta;
  final bool nearCivilCollision;
  final String? civilCollisionKind;
  final List<ActivitySpectralPeakCandidate> candidatePeaks;
  final String? oscillatorId;

  bool get accepted =>
      status == ActivitySpectralOmegaStatus.ok &&
      periodSeconds != null &&
      omega != null;

  Map<String, dynamic> toWireMap() => {
        'scoring_version':
            ActivitySpectralOmegaEstimatorContract.scoringVersion,
        'policy_version': ActivitySpectralOmegaEstimatorContract.policyVersion,
        'policy_status': ActivitySpectralOmegaEstimatorContract.policyStatus,
        'shadow_only': ActivitySpectralOmegaEstimatorContract.shadowOnly,
        'gates_calibrated':
            ActivitySpectralOmegaEstimatorContract.gatesCalibrated,
        'attaches_to_frequency_modes':
            ActivitySpectralOmegaEstimatorContract.attachesToFrequencyModes,
        'cadence_fallback_allowed':
            ActivitySpectralOmegaEstimatorContract.cadenceFallbackAllowed,
        'l4_v1_role': ActivitySpectralOmegaEstimatorContract.l4V1Role,
        'production_promoted':
            ActivitySpectralOmegaEstimatorContract.productionPromoted,
        'stream_id': ActivitySpectralOmegaEstimatorContract.streamId,
        'status': status.name,
        if (reason != null) 'reason': reason,
        'event_count': eventCount,
        'window_seconds': windowSeconds,
        'bin_width_seconds': binWidthSeconds,
        if (periodSeconds != null) 'period_seconds': periodSeconds,
        if (omega != null) 'omega': omega,
        if (snr != null) 'snr': snr,
        if (splitHalfRelativeDelta != null)
          'split_half_relative_delta': splitHalfRelativeDelta,
        if (binSensitivityRelativeDelta != null)
          'bin_sensitivity_relative_delta': binSensitivityRelativeDelta,
        'near_civil_collision': nearCivilCollision,
        if (civilCollisionKind != null)
          'civil_collision_kind': civilCollisionKind,
        if (oscillatorId != null) 'oscillator_id': oscillatorId,
        'candidate_peaks': [
          for (final p in candidatePeaks) p.toWireMap(),
        ],
      };
}
