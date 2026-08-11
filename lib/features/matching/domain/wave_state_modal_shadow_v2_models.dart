import 'dart:math' as math;

import 'wave_state_modal_shadow_v2_contract.dart';

/// Phase class per wave_phase_reference_policy_v1.
enum WavePhaseClassV2 {
  externalAnchored,
  validatedPeriodic,
  unanchored,
}

/// Time basis for phase provenance.
enum WavePhaseTimeBasisV2 {
  localCivil,
  utc,
}

/// Periodicity / concentration quality gate.
enum WavePeriodicityStatusV2 {
  ok,
  sparse,
  unavailable,
}

/// Pairwise phase-compatibility outcome.
enum WavePhaseCompatibilityV2 {
  compatible,
  incompatible,
  unanchored,
  insufficientQuality,
  missingProvenance,
}

/// Provenanced phase input — never a bare float.
class PhaseReferenceV2 {
  const PhaseReferenceV2({
    required this.oscillatorId,
    required this.phaseRadians,
    required this.phaseClass,
    required this.timeBasis,
    required this.periodicityStatus,
    this.omega,
    this.periodSeconds,
    this.referenceEpoch,
    this.timezone,
    this.source,
  });

  final String oscillatorId;
  final double phaseRadians;
  final WavePhaseClassV2 phaseClass;
  final WavePhaseTimeBasisV2 timeBasis;
  final WavePeriodicityStatusV2 periodicityStatus;

  /// Angular frequency (rad / time-unit). Optional if [periodSeconds] set.
  final double? omega;

  /// Period in seconds. Optional if [omega] set.
  final double? periodSeconds;

  /// Required for [WavePhaseClassV2.validatedPeriodic].
  final String? referenceEpoch;

  /// Required when [timeBasis] is [WavePhaseTimeBasisV2.localCivil].
  final String? timezone;

  /// Estimator provenance. Must not be `questionnaire`.
  final String? source;

  double? get resolvedOmega {
    if (omega != null && omega!.isFinite) return omega;
    final T = periodSeconds;
    if (T != null && T.isFinite && T > 0) {
      return 2 * math.pi / T;
    }
    return null;
  }

  bool get hasFinitePhase => phaseRadians.isFinite;

  bool get hasResolvedOmega {
    final w = resolvedOmega;
    return w != null && w.isFinite;
  }

  /// Structural completeness of provenance fields (not pairwise compatibility).
  String? provenanceGapReason() {
    if (oscillatorId.isEmpty) return 'missing_phase_metadata';
    if (!hasFinitePhase) return 'missing_phase_metadata';
    if (!hasResolvedOmega) return 'missing_phase_metadata';
    if (source ==
        WaveStateModalShadowV2Contract.forbiddenPhaseSourceQuestionnaire) {
      return 'questionnaire_phase_forbidden';
    }
    if (timeBasis == WavePhaseTimeBasisV2.localCivil &&
        (timezone == null || timezone!.isEmpty)) {
      return 'missing_phase_metadata';
    }
    if (phaseClass == WavePhaseClassV2.validatedPeriodic &&
        (referenceEpoch == null || referenceEpoch!.isEmpty)) {
      return 'missing_phase_metadata';
    }
    if (phaseClass == WavePhaseClassV2.unanchored) {
      return 'unanchored_phase';
    }
    return null;
  }

  Map<String, dynamic> toWireMap() => {
        'oscillator_id': oscillatorId,
        'phase_radians': phaseRadians,
        'phase_class': phaseClass.name,
        'time_basis': timeBasis.name,
        'periodicity_status': periodicityStatus.name,
        if (omega != null) 'omega': omega,
        if (periodSeconds != null) 'period_seconds': periodSeconds,
        if (referenceEpoch != null) 'reference_epoch': referenceEpoch,
        if (timezone != null) 'timezone': timezone,
        if (source != null) 'source': source,
      };
}

/// Per-mode v2 input: amplitude + optional provenanced phase.
class WaveStateModeV2 {
  const WaveStateModeV2({
    required this.modeId,
    this.amplitude,
    this.phase,
  });

  final String modeId;
  final double? amplitude;
  final PhaseReferenceV2? phase;

  bool get hasAmplitude =>
      amplitude != null && amplitude!.isFinite && amplitude! >= 0.0;

  bool get hasNumericWaveInputs =>
      hasAmplitude &&
      phase != null &&
      phase!.hasFinitePhase &&
      phase!.hasResolvedOmega;
}

/// Subject bundle for v2.
class WaveStateModalSubjectV2 {
  WaveStateModalSubjectV2({
    required Map<String, WaveStateModeV2> modesById,
  }) : modesById = Map.unmodifiable(modesById);

  final Map<String, WaveStateModeV2> modesById;

  factory WaveStateModalSubjectV2.fromModes(Iterable<WaveStateModeV2> modes) {
    final out = <String, WaveStateModeV2>{};
    for (final id in WaveStateModalShadowV2Contract.frequencyDimensionIds) {
      out[id] = WaveStateModeV2(modeId: id);
    }
    for (final m in modes) {
      out[m.modeId] = m;
    }
    return WaveStateModalSubjectV2(modesById: out);
  }

  WaveStateModeV2? mode(String id) => modesById[id];
}

/// v2 pairwise result.
class WaveStateModalShadowV2Result {
  const WaveStateModalShadowV2Result({
    required this.signedResonanceAvailable,
    required this.rWave,
    required this.rWaveUnavailableReason,
    required this.cAbs,
    required this.cAbsSq,
    required this.cAbsDiagnosticOnly,
    required this.phaseCompatibility,
    required this.overlapReal,
    required this.overlapImag,
    required this.normA,
    required this.normB,
    required this.signedSharedModeCount,
    required this.diagnosticSharedModeCount,
    required this.registryModeCount,
    required this.modalCoverageSigned,
    required this.signedSharedModeIds,
    required this.excludedModeIds,
    required this.evaluationTime,
    required this.stringLength,
    required this.scoringVersion,
    required this.policyVersion,
    required this.policyStatus,
    required this.registryVersion,
    required this.shadowOnly,
    required this.structuralDistanceCoupled,
  });

  /// True only when signed Re is policy-valid.
  final bool signedResonanceAvailable;
  final double? rWave;
  final String? rWaveUnavailableReason;

  /// |normalized overlap| — diagnostic only, never ranking.
  final double? cAbs;
  final double? cAbsSq;
  final bool cAbsDiagnosticOnly;

  final WavePhaseCompatibilityV2 phaseCompatibility;

  final double? overlapReal;
  final double? overlapImag;
  final double? normA;
  final double? normB;

  final int signedSharedModeCount;
  final int diagnosticSharedModeCount;
  final int registryModeCount;
  final double modalCoverageSigned;
  final List<String> signedSharedModeIds;
  final List<String> excludedModeIds;

  final double evaluationTime;
  final double stringLength;

  final String scoringVersion;
  final String policyVersion;
  final String policyStatus;
  final String registryVersion;
  final bool shadowOnly;
  final bool structuralDistanceCoupled;

  Map<String, dynamic> toWireMap() => {
        'signed_resonance_available': signedResonanceAvailable,
        if (rWave != null) 'r_wave': rWave,
        if (rWaveUnavailableReason != null)
          'r_wave_unavailable_reason': rWaveUnavailableReason,
        if (cAbs != null) 'c_abs': cAbs,
        if (cAbsSq != null) 'c_abs_sq': cAbsSq,
        'c_abs_diagnostic_only': cAbsDiagnosticOnly,
        'c_abs_used_for_ranking':
            WaveStateModalShadowV2Contract.cAbsUsedForRanking,
        'phase_compatibility': phaseCompatibility.name,
        if (overlapReal != null) 'overlap_real': overlapReal,
        if (overlapImag != null) 'overlap_imag': overlapImag,
        if (normA != null) 'norm_a': normA,
        if (normB != null) 'norm_b': normB,
        'signed_shared_mode_count': signedSharedModeCount,
        'diagnostic_shared_mode_count': diagnosticSharedModeCount,
        'registry_mode_count': registryModeCount,
        'modal_coverage_signed': modalCoverageSigned,
        'signed_shared_mode_ids': signedSharedModeIds,
        'excluded_mode_ids': excludedModeIds,
        'evaluation_time': evaluationTime,
        'string_length': stringLength,
        'scoring_version': scoringVersion,
        'policy_version': policyVersion,
        'policy_status': policyStatus,
        'registry_version': registryVersion,
        'shadow_only': shadowOnly,
        'shadow_candidate': WaveStateModalShadowV2Contract.shadowCandidate,
        'structural_distance_coupled': structuralDistanceCoupled,
        'gauge_fixes_unanchored_phase':
            WaveStateModalShadowV2Contract.gaugeFixesUnanchoredPhase,
        'persona_enabled': WaveStateModalShadowV2Contract.personaEnabled,
        'rvi_enabled': WaveStateModalShadowV2Contract.rviEnabled,
        'density_matrix_enabled':
            WaveStateModalShadowV2Contract.densityMatrixEnabled,
        'live_discover_ranking':
            WaveStateModalShadowV2Contract.liveDiscoverRanking,
      };
}
