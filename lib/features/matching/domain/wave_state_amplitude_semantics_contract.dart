import 'l4_temporal_diagnostics_contract.dart';

/// Wave-State amplitude semantics v1 — two-tier freeze.
///
/// L4 v1: Tier 1 global periodic activity oscillator is **research shadow**
/// (`phase_alignment`, activity amplitude). Not production-promoted.
/// Tier 2 multi-mode Wave-State is **research-only**, rejected from L5 v1
/// (do not copy global phase onto Frequency 6D).
class WaveStateAmplitudeSemanticsContract {
  WaveStateAmplitudeSemanticsContract._();

  static const String policyVersion = 'wave_state_amplitude_semantics_v1';
  static const String policyStatus = 'shadow_only_not_live';

  static const bool shadowOnly = true;
  static const bool gatesCalibrated = false;
  static const bool liveDiscoverRanking = false;
  static const bool personaEnabled = false;
  static const bool rviEnabled = false;
  static const bool densityMatrixEnabled = false;

  // --- Tier 1: global periodic activity oscillator (L4 research shadow) ---

  static const String tier1Id = 'global_activity_periodic_oscillator_v1';
  static const bool tier1UsableShadow = true;
  static const bool tier1L4ProductionPromoted =
      L4TemporalDiagnosticsContract
          .globalActivityOscillatorComparisonProductionPromoted;
  static const bool tier1L4ResearchShadow = true;
  static const bool tier1FusesActivityIntoPhaseAlignment = false;
  static const bool tier1AttachesToFrequencyModes = false;

  /// \(z_u(t)=A_u\exp(i(\omega t+\phi_u))\)
  static const String tier1StateForm = 'A * exp(i*(omega*t + phi))';

  /// Returned separately from activity levels — never fused.
  static const String tier1PhaseAlignmentFormula = 'cos(delta_phi)';

  // --- Tier 2: multi-mode Wave-State v2 (research-only; not L5 v1) ---

  static const String tier2Id = 'wave_state_modal_shadow_v2_multimode';
  static const bool tier2RealUserResonanceEnabled = false;
  static const bool tier2RequiresModeSpecificOscillators = true;
  static const bool tier2MayCopyGlobalPhaseToFrequencyModes = false;
  static const String tier2RealUserStatus = 'research_only_unavailable';
  static const bool tier2L5V1RetainedCandidate = false;
  static const bool fusedRWaveIsL5Score = false;

  /// \(c_{\mathrm{abs}}\) is amplitude-envelope diagnostic only — not resonance.
  static const bool cAbsIsResonance = false;
  static const bool cAbsIsAmplitudeEnvelopeDiagnosticOnly = true;

  static const String reasonMultimodeRealUserUnavailable =
      'multimode_requires_mode_specific_oscillators';
  static const String reasonCopiesGlobalPhaseForbidden =
      'global_activity_phase_must_not_copy_to_frequency_modes';
}
