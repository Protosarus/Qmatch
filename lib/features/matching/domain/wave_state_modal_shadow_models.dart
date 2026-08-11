import 'wave_state_modal_shadow_contract.dart';

/// Explicit per-mode inputs for the wave-state shadow model.
///
/// [amplitude] may come from measured Frequency scores.
/// [phaseRadians] and [omega] are **explicit inputs only** — never fabricated.
class WaveStateModalModeInput {
  const WaveStateModalModeInput({
    required this.modeId,
    this.amplitude,
    this.phaseRadians,
    this.omega,
  });

  final String modeId;

  /// \(A_{u,m}\) — measured Frequency amplitude when available.
  final double? amplitude;

  /// \(\phi_{u,m}\) in radians — unavailable unless explicitly provided.
  final double? phaseRadians;

  /// \(\omega_{u,m}\) — unavailable unless explicitly provided.
  final double? omega;

  bool get hasAmplitude =>
      amplitude != null && amplitude!.isFinite && amplitude! >= 0.0;

  bool get hasPhase => phaseRadians != null && phaseRadians!.isFinite;

  bool get hasOmega => omega != null && omega!.isFinite;

  /// Mode is usable for \(\Psi\) / complex overlap only when all three exist.
  bool get isWaveComplete => hasAmplitude && hasPhase && hasOmega;
}

/// One subject's modal wave-state inputs (6 Frequency modes).
class WaveStateModalSubject {
  WaveStateModalSubject({
    required Map<String, WaveStateModalModeInput> modesById,
  }) : modesById = Map.unmodifiable(modesById);

  final Map<String, WaveStateModalModeInput> modesById;

  /// Build from parallel maps. Missing keys mean unavailable (not fabricated).
  factory WaveStateModalSubject.fromMaps({
    Map<String, double>? amplitudes,
    Map<String, double>? phasesRadians,
    Map<String, double>? omegas,
  }) {
    final out = <String, WaveStateModalModeInput>{};
    for (final id in WaveStateModalShadowContract.frequencyDimensionIds) {
      out[id] = WaveStateModalModeInput(
        modeId: id,
        amplitude: amplitudes?[id],
        phaseRadians: phasesRadians?[id],
        omega: omegas?[id],
      );
    }
    return WaveStateModalSubject(modesById: out);
  }

  WaveStateModalModeInput? mode(String id) => modesById[id];
}

/// Complex sample of \(\Psi_u(s,t)\) (or unavailable).
class WaveStatePsiSample {
  const WaveStatePsiSample({
    required this.available,
    required this.real,
    required this.imag,
    required this.unavailableReason,
    required this.modeCountUsed,
  });

  final bool available;
  final double? real;
  final double? imag;
  final String? unavailableReason;
  final int modeCountUsed;

  static const WaveStatePsiSample unavailable = WaveStatePsiSample(
    available: false,
    real: null,
    imag: null,
    unavailableReason: 'no_complete_modes',
    modeCountUsed: 0,
  );
}

/// Shadow-only wave-state pairwise result.
///
/// Structural distance is intentionally **not** computed here.
class WaveStateModalShadowResult {
  const WaveStateModalShadowResult({
    required this.resonanceAvailable,
    required this.rWave,
    required this.overlapReal,
    required this.overlapImag,
    required this.normA,
    required this.normB,
    required this.sharedModeCount,
    required this.registryModeCount,
    required this.modalCoverage,
    required this.sharedModeIds,
    required this.excludedModeIds,
    required this.unavailableReason,
    required this.evaluationTime,
    required this.stringLength,
    required this.scoringVersion,
    required this.policyVersion,
    required this.policyStatus,
    required this.registryVersion,
    required this.shadowOnly,
    required this.structuralDistanceCoupled,
  });

  /// True when normalized complex overlap is defined.
  final bool resonanceAvailable;

  /// \(\mathrm{Re}\langle\Psi_a|\Psi_b\rangle / (\lVert\Psi_a\rVert\lVert\Psi_b\rVert)\).
  final double? rWave;

  /// Unnormalized \(\mathrm{Re}\langle\Psi_a|\Psi_b\rangle\).
  final double? overlapReal;

  /// Unnormalized \(\mathrm{Im}\langle\Psi_a|\Psi_b\rangle\).
  final double? overlapImag;

  final double? normA;
  final double? normB;

  final int sharedModeCount;
  final int registryModeCount;
  final double modalCoverage;
  final List<String> sharedModeIds;
  final List<String> excludedModeIds;
  final String? unavailableReason;
  final double evaluationTime;
  final double stringLength;

  final String scoringVersion;
  final String policyVersion;
  final String policyStatus;
  final String registryVersion;
  final bool shadowOnly;
  final bool structuralDistanceCoupled;

  Map<String, dynamic> toWireMap() => {
        'resonance_available': resonanceAvailable,
        if (rWave != null) 'r_wave': rWave,
        if (overlapReal != null) 'overlap_real': overlapReal,
        if (overlapImag != null) 'overlap_imag': overlapImag,
        if (normA != null) 'norm_a': normA,
        if (normB != null) 'norm_b': normB,
        'shared_mode_count': sharedModeCount,
        'registry_mode_count': registryModeCount,
        'modal_coverage': modalCoverage,
        'shared_mode_ids': sharedModeIds,
        'excluded_mode_ids': excludedModeIds,
        if (unavailableReason != null) 'unavailable_reason': unavailableReason,
        'evaluation_time': evaluationTime,
        'string_length': stringLength,
        'scoring_version': scoringVersion,
        'policy_version': policyVersion,
        'policy_status': policyStatus,
        'registry_version': registryVersion,
        'shadow_only': shadowOnly,
        'structural_distance_coupled': structuralDistanceCoupled,
        'persona_enabled': WaveStateModalShadowContract.personaEnabled,
        'rvi_enabled': WaveStateModalShadowContract.rviEnabled,
        'density_matrix_enabled':
            WaveStateModalShadowContract.densityMatrixEnabled,
        'fabricates_missing_phase':
            WaveStateModalShadowContract.fabricatesMissingPhase,
        'fabricates_missing_omega':
            WaveStateModalShadowContract.fabricatesMissingOmega,
        'live_discover_ranking':
            WaveStateModalShadowContract.liveDiscoverRanking,
      };
}
