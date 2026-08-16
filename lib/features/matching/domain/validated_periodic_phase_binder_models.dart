import 'activity_spectral_omega_estimator_models.dart';
import 'validated_periodic_phase_binder_contract.dart';
import 'wave_state_modal_shadow_v2_models.dart';

/// Shadow-only Class-B phase bind result on an accepted spectral oscillator.
class ValidatedPeriodicPhaseEstimate {
  const ValidatedPeriodicPhaseEstimate({
    required this.available,
    required this.unavailableReason,
    required this.eventCount,
    required this.thetaBar,
    required this.rBar,
    required this.periodSeconds,
    required this.omega,
    required this.oscillatorId,
    required this.referenceEpoch,
    required this.referenceEpochMs,
    required this.phaseReference,
    required this.omegaStatus,
  });

  final bool available;
  final String? unavailableReason;
  final int eventCount;

  /// Circular mean phase on folded \(T^\star\) (radians), when computed.
  final double? thetaBar;

  /// Resultant length \(\bar R\in[0,1]\).
  final double? rBar;

  final double? periodSeconds;
  final double? omega;
  final String? oscillatorId;

  /// ISO-8601 UTC reference epoch string (Class B required).
  final String? referenceEpoch;
  final int? referenceEpochMs;

  /// Valid [PhaseReferenceV2] only when [available] is true.
  final PhaseReferenceV2? phaseReference;

  /// Echo of upstream omega status for diagnostics.
  final ActivitySpectralOmegaStatus omegaStatus;

  Map<String, dynamic> toWireMap() => {
        'scoring_version': ValidatedPeriodicPhaseBinderContract.scoringVersion,
        'policy_version': ValidatedPeriodicPhaseBinderContract.policyVersion,
        'policy_status': ValidatedPeriodicPhaseBinderContract.policyStatus,
        'shadow_only': ValidatedPeriodicPhaseBinderContract.shadowOnly,
        'gates_calibrated':
            ValidatedPeriodicPhaseBinderContract.gatesCalibrated,
        'attaches_to_frequency_modes':
            ValidatedPeriodicPhaseBinderContract.attachesToFrequencyModes,
        'feeds_six_mode_r_wave':
            ValidatedPeriodicPhaseBinderContract.feedsSixModeRWave,
        'l4_v1_role': ValidatedPeriodicPhaseBinderContract.l4V1Role,
        'production_promoted':
            ValidatedPeriodicPhaseBinderContract.productionPromoted,
        'reference_epoch_policy':
            ValidatedPeriodicPhaseBinderContract.referenceEpochPolicy,
        'available': available,
        if (unavailableReason != null) 'unavailable_reason': unavailableReason,
        'event_count': eventCount,
        'omega_status': omegaStatus.name,
        if (thetaBar != null) 'theta_bar': thetaBar,
        if (rBar != null) 'r_bar': rBar,
        if (periodSeconds != null) 'period_seconds': periodSeconds,
        if (omega != null) 'omega': omega,
        if (oscillatorId != null) 'oscillator_id': oscillatorId,
        if (referenceEpoch != null) 'reference_epoch': referenceEpoch,
        if (referenceEpochMs != null) 'reference_epoch_ms': referenceEpochMs,
        if (phaseReference != null)
          'phase_reference': phaseReference!.toWireMap(),
      };
}
