import 'activity_spectral_omega_estimator_models.dart';
import 'wave_state_amplitude_semantics_contract.dart';
import 'wave_state_modal_shadow_v2_models.dart';

/// Tier-1 scalar result: phase alignment and activity levels stay separate.
class GlobalActivityPeriodicResonanceResult {
  const GlobalActivityPeriodicResonanceResult({
    required this.available,
    required this.unavailableReason,
    required this.phaseAlignment,
    required this.activityLevelA,
    required this.activityLevelB,
    required this.activityLevelGap,
    required this.deltaPhi,
    required this.oscillatorId,
    required this.periodSeconds,
    required this.omega,
    required this.evaluationTime,
    required this.phaseCompatibility,
  });

  final bool available;
  final String? unavailableReason;

  /// \(\cos(\Delta\phi)\) — never fused with activity levels.
  final double? phaseAlignment;

  final double? activityLevelA;
  final double? activityLevelB;

  /// \(|A_u - A_v|\) — separate diagnostic, not mixed into phase alignment.
  final double? activityLevelGap;

  final double? deltaPhi;
  final String? oscillatorId;
  final double? periodSeconds;
  final double? omega;
  final double evaluationTime;
  final WavePhaseCompatibilityV2? phaseCompatibility;

  Map<String, dynamic> toWireMap() => {
        'scoring_version': GlobalActivityPeriodicResonanceContract.scoringVersion,
        'semantics_version': WaveStateAmplitudeSemanticsContract.policyVersion,
        'tier': WaveStateAmplitudeSemanticsContract.tier1Id,
        'shadow_only': WaveStateAmplitudeSemanticsContract.shadowOnly,
        'gates_calibrated': WaveStateAmplitudeSemanticsContract.gatesCalibrated,
        'fuses_activity_into_phase_alignment': WaveStateAmplitudeSemanticsContract
            .tier1FusesActivityIntoPhaseAlignment,
        'attaches_to_frequency_modes': WaveStateAmplitudeSemanticsContract
            .tier1AttachesToFrequencyModes,
        'live_discover_ranking':
            WaveStateAmplitudeSemanticsContract.liveDiscoverRanking,
        'state_form': WaveStateAmplitudeSemanticsContract.tier1StateForm,
        'phase_alignment_formula':
            WaveStateAmplitudeSemanticsContract.tier1PhaseAlignmentFormula,
        'available': available,
        if (unavailableReason != null) 'unavailable_reason': unavailableReason,
        if (phaseAlignment != null) 'phase_alignment': phaseAlignment,
        if (activityLevelA != null) 'activity_level_A': activityLevelA,
        if (activityLevelB != null) 'activity_level_B': activityLevelB,
        if (activityLevelGap != null) 'activity_level_gap': activityLevelGap,
        if (deltaPhi != null) 'delta_phi': deltaPhi,
        if (oscillatorId != null) 'oscillator_id': oscillatorId,
        if (periodSeconds != null) 'period_seconds': periodSeconds,
        if (omega != null) 'omega': omega,
        'evaluation_time': evaluationTime,
        if (phaseCompatibility != null)
          'phase_compatibility': phaseCompatibility!.name,
        'omega_status_echo_required_ok': true,
      };
}

/// Contract ids for the Tier-1 scalar global activity oscillator.
class GlobalActivityPeriodicResonanceContract {
  GlobalActivityPeriodicResonanceContract._();

  static const String scoringVersion =
      'global_activity_periodic_resonance_v1';

  static const String reasonNonPositiveActivityLevel =
      'non_positive_activity_level';
}
