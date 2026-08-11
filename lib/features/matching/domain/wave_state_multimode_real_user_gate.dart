import 'wave_state_amplitude_semantics_contract.dart';

/// Gate for Tier-2 multi-mode Wave-State real-user resonance.
///
/// Real-user path stays unavailable until genuinely mode-specific oscillators
/// and phase provenance exist. Copying global activity phase into Frequency
/// modes is always forbidden.
class WaveStateMultimodeRealUserGate {
  const WaveStateMultimodeRealUserGate();

  /// Whether signed multi-mode resonance may be used for real users.
  ///
  /// [hasModeSpecificOscillatorsForAllModes] must be true only when every
  /// Frequency mode in the comparable set has its own justified oscillator /
  /// phase provenance (not the global activity spectral / circadian clock).
  WaveStateMultimodeRealUserGateResult evaluate({
    required bool hasModeSpecificOscillatorsForAllModes,
    bool copiesGlobalActivityPhaseIntoFrequencyModes = false,
  }) {
    if (copiesGlobalActivityPhaseIntoFrequencyModes) {
      return const WaveStateMultimodeRealUserGateResult(
        available: false,
        reason: WaveStateAmplitudeSemanticsContract
            .reasonCopiesGlobalPhaseForbidden,
      );
    }
    if (!WaveStateAmplitudeSemanticsContract.tier2RealUserResonanceEnabled) {
      return const WaveStateMultimodeRealUserGateResult(
        available: false,
        reason: WaveStateAmplitudeSemanticsContract
            .reasonMultimodeRealUserUnavailable,
      );
    }
    if (WaveStateAmplitudeSemanticsContract
            .tier2RequiresModeSpecificOscillators &&
        !hasModeSpecificOscillatorsForAllModes) {
      return const WaveStateMultimodeRealUserGateResult(
        available: false,
        reason: WaveStateAmplitudeSemanticsContract
            .reasonMultimodeRealUserUnavailable,
      );
    }
    return const WaveStateMultimodeRealUserGateResult(
      available: true,
      reason: null,
    );
  }
}

class WaveStateMultimodeRealUserGateResult {
  const WaveStateMultimodeRealUserGateResult({
    required this.available,
    required this.reason,
  });

  final bool available;
  final String? reason;

  Map<String, dynamic> toWireMap() => {
        'tier': WaveStateAmplitudeSemanticsContract.tier2Id,
        'real_user_status':
            WaveStateAmplitudeSemanticsContract.tier2RealUserStatus,
        'real_user_resonance_enabled': WaveStateAmplitudeSemanticsContract
            .tier2RealUserResonanceEnabled,
        'requires_mode_specific_oscillators': WaveStateAmplitudeSemanticsContract
            .tier2RequiresModeSpecificOscillators,
        'may_copy_global_phase_to_frequency_modes':
            WaveStateAmplitudeSemanticsContract
                .tier2MayCopyGlobalPhaseToFrequencyModes,
        'c_abs_is_resonance': WaveStateAmplitudeSemanticsContract.cAbsIsResonance,
        'c_abs_is_amplitude_envelope_diagnostic_only':
            WaveStateAmplitudeSemanticsContract
                .cAbsIsAmplitudeEnvelopeDiagnosticOnly,
        'available': available,
        if (reason != null) 'reason': reason,
      };
}
