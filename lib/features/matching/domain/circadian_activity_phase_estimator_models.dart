import 'circadian_activity_phase_estimator_contract.dart';
import 'wave_state_modal_shadow_v2_models.dart';

/// Metadata-only timestamp event for circadian activity estimation.
class CircadianActivityTimestamp {
  const CircadianActivityTimestamp({required this.timestampMs});

  /// Epoch milliseconds (UTC instant).
  final int timestampMs;
}

/// Result of [CircadianActivityPhaseEstimator].
///
/// [phaseReference] is non-null **only** when provisional ok-gates pass.
/// Never represents a Frequency-mode phase.
class CircadianActivityPhaseEstimate {
  const CircadianActivityPhaseEstimate({
    required this.available,
    required this.unavailableReason,
    required this.eventCount,
    required this.distinctLocalDays,
    required this.thetaBar,
    required this.rBar,
    required this.phaseReference,
    required this.timezoneLabel,
    required this.localTimeZoneOffset,
  });

  final bool available;
  final String? unavailableReason;
  final int eventCount;
  final int distinctLocalDays;
  final double? thetaBar;
  final double? rBar;

  /// Valid [PhaseReferenceV2] only when [available] is true.
  final PhaseReferenceV2? phaseReference;

  final String? timezoneLabel;
  final Duration? localTimeZoneOffset;

  Map<String, dynamic> toWireMap() => {
        'scoring_version':
            CircadianActivityPhaseEstimatorContract.scoringVersion,
        'policy_version': CircadianActivityPhaseEstimatorContract.policyVersion,
        'policy_status': CircadianActivityPhaseEstimatorContract.policyStatus,
        'shadow_only': CircadianActivityPhaseEstimatorContract.shadowOnly,
        'gates_calibrated':
            CircadianActivityPhaseEstimatorContract.gatesCalibrated,
        'attaches_to_frequency_modes':
            CircadianActivityPhaseEstimatorContract.attachesToFrequencyModes,
        'feeds_six_mode_r_wave':
            CircadianActivityPhaseEstimatorContract.feedsSixModeRWave,
        'oscillator_id': CircadianActivityPhaseEstimatorContract.oscillatorId,
        'available': available,
        if (unavailableReason != null) 'unavailable_reason': unavailableReason,
        'event_count': eventCount,
        'distinct_local_days': distinctLocalDays,
        if (thetaBar != null) 'theta_bar': thetaBar,
        if (rBar != null) 'r_bar': rBar,
        if (phaseReference != null)
          'phase_reference': phaseReference!.toWireMap(),
        if (timezoneLabel != null) 'timezone': timezoneLabel,
        if (localTimeZoneOffset != null)
          'timezone_offset_seconds': localTimeZoneOffset!.inSeconds,
        'period_seconds': CircadianActivityPhaseEstimatorContract.periodSeconds,
        'omega_fixed_24h': CircadianActivityPhaseEstimatorContract.fixedOmega,
      };
}
