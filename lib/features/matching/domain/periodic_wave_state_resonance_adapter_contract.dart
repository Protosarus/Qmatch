/// Shadow-only adapter: validated periodic oscillator → Wave-State v2 resonance.
///
/// Uses [WavePhaseReferenceCompatibilityV2] + the v2 overlap formula.
/// Does **not** attach Class-B activity phase to Frequency 6D mode slots,
/// Discover, Persona, RVI, or density-matrix.
///
/// **Amplitude semantics v1:** this multi-amplitude envelope path is a
/// **research diagnostic**. Usable real-user shadow for the global activity
/// oscillator is [GlobalActivityPeriodicResonance] (phase alignment and
/// activity levels returned separately). \(c_{\mathrm{abs}}\) is amplitude-
/// envelope diagnostic only — never called resonance.
class PeriodicWaveStateResonanceAdapterContract {
  PeriodicWaveStateResonanceAdapterContract._();

  static const String scoringVersion =
      'periodic_wave_state_resonance_adapter_v1';
  static const String policyVersion = 'wave_phase_reference_policy_v1';
  static const String waveStateVersion = 'wave_state_modal_shadow_v2';
  static const String amplitudeSemanticsVersion =
      'wave_state_amplitude_semantics_v1';
  static const String policyStatus = 'shadow_only_not_live';

  static const bool shadowOnly = true;
  static const bool gatesCalibrated = false;
  static const bool attachesToFrequencyModes = false;
  static const bool liveDiscoverRanking = false;
  static const bool structuralDistanceCoupled = false;
  static const bool personaEnabled = false;
  static const bool rviEnabled = false;
  static const bool densityMatrixEnabled = false;
  static const bool cAbsUsedForRanking = false;
  static const bool cAbsIsResonance = false;
  static const bool cAbsIsAmplitudeEnvelopeDiagnosticOnly = true;

  /// Multi-amplitude fused path is research diagnostic, not Tier-1 usable API.
  static const bool researchEnvelopeDiagnosticOnly = true;
  static const bool realUserUsablePath = false;
  static const bool l5V1RetainedCandidate = false;
  static const bool fusedRWaveIsL5Score = false;

  static const bool fabricatesMissingPhase = false;
  static const bool fabricatesMissingOmega = false;

  static const double omegaRelativeTolerance = 1e-9;

  static const String reasonOmegaNotOk = 'omega_not_ok';
  static const String reasonCivilCollision = 'civil_collision';
  static const String reasonOmegaAmbiguous = 'omega_ambiguous';
  static const String reasonOmegaSparse = 'omega_sparse';
  static const String reasonOmegaUnavailable = 'omega_unavailable';
  static const String reasonPhaseUnavailable = 'phase_unavailable';
  static const String reasonProvenanceMismatch = 'oscillator_provenance_mismatch';
  static const String reasonAmplitudeLengthMismatch =
      'amplitude_length_mismatch';
  static const String reasonEmptyAmplitudes = 'empty_amplitudes';
  static const String reasonZeroNorm = 'zero_norm_wave_state';
  static const String reasonPhaseIncompatible = 'phase_incompatible';
}
