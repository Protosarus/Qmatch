import 'periodic_wave_state_resonance_adapter_contract.dart';
import 'wave_state_modal_shadow_v2_models.dart';

/// Shadow-only pairwise resonance under a shared Class-B periodic oscillator.
class PeriodicWaveStateResonanceResult {
  const PeriodicWaveStateResonanceResult({
    required this.signedResonanceAvailable,
    required this.rWave,
    required this.unavailableReason,
    required this.cAbs,
    required this.cAbsSq,
    required this.phaseCompatibility,
    required this.compatibilityReason,
    required this.overlapReal,
    required this.overlapImag,
    required this.normA,
    required this.normB,
    required this.evaluationTime,
    required this.oscillatorId,
    required this.periodSeconds,
    required this.omega,
  });

  final bool signedResonanceAvailable;
  final double? rWave;
  final String? unavailableReason;

  /// Diagnostic |normalized overlap|; never for ranking.
  final double? cAbs;
  final double? cAbsSq;

  final WavePhaseCompatibilityV2? phaseCompatibility;
  final String? compatibilityReason;

  final double? overlapReal;
  final double? overlapImag;
  final double? normA;
  final double? normB;

  final double evaluationTime;
  final String? oscillatorId;
  final double? periodSeconds;
  final double? omega;

  Map<String, dynamic> toWireMap() => {
        'scoring_version':
            PeriodicWaveStateResonanceAdapterContract.scoringVersion,
        'policy_version':
            PeriodicWaveStateResonanceAdapterContract.policyVersion,
        'wave_state_version':
            PeriodicWaveStateResonanceAdapterContract.waveStateVersion,
        'policy_status': PeriodicWaveStateResonanceAdapterContract.policyStatus,
        'shadow_only': PeriodicWaveStateResonanceAdapterContract.shadowOnly,
        'gates_calibrated':
            PeriodicWaveStateResonanceAdapterContract.gatesCalibrated,
        'attaches_to_frequency_modes':
            PeriodicWaveStateResonanceAdapterContract.attachesToFrequencyModes,
        'structural_distance_coupled': PeriodicWaveStateResonanceAdapterContract
            .structuralDistanceCoupled,
        'c_abs_diagnostic_only': true,
        'c_abs_used_for_ranking':
            PeriodicWaveStateResonanceAdapterContract.cAbsUsedForRanking,
        'live_discover_ranking':
            PeriodicWaveStateResonanceAdapterContract.liveDiscoverRanking,
        'persona_enabled':
            PeriodicWaveStateResonanceAdapterContract.personaEnabled,
        'rvi_enabled': PeriodicWaveStateResonanceAdapterContract.rviEnabled,
        'density_matrix_enabled':
            PeriodicWaveStateResonanceAdapterContract.densityMatrixEnabled,
        'signed_resonance_available': signedResonanceAvailable,
        if (rWave != null) 'r_wave': rWave,
        if (unavailableReason != null) 'unavailable_reason': unavailableReason,
        if (cAbs != null) 'c_abs': cAbs,
        if (cAbsSq != null) 'c_abs_sq': cAbsSq,
        if (phaseCompatibility != null)
          'phase_compatibility': phaseCompatibility!.name,
        if (compatibilityReason != null)
          'compatibility_reason': compatibilityReason,
        if (overlapReal != null) 'overlap_real': overlapReal,
        if (overlapImag != null) 'overlap_imag': overlapImag,
        if (normA != null) 'norm_a': normA,
        if (normB != null) 'norm_b': normB,
        'evaluation_time': evaluationTime,
        if (oscillatorId != null) 'oscillator_id': oscillatorId,
        if (periodSeconds != null) 'period_seconds': periodSeconds,
        if (omega != null) 'omega': omega,
      };
}
