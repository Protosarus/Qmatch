import 'dart:math' as math;

import 'wave_state_modal_shadow_contract.dart';
import 'wave_state_modal_shadow_models.dart';

/// Shadow-only string-inspired modal wave-state engine (v1).
///
/// \[
/// \Psi_u(s,t)
/// =\sum_m A_{u,m}\,e_m(s)\,
/// \exp\bigl(i(\omega_{u,m}\,t+\phi_{u,m})\bigr)
/// \]
///
/// with orthonormal modes
/// \[
/// e_m(s)=\sqrt{2/L}\,\sin(m\pi s/L).
/// \]
///
/// \(\phi\) and \(\omega\) are explicit inputs only — never fabricated.
/// Structural distance stays separate (not computed here).
class WaveStateModalShadowMatcher {
  const WaveStateModalShadowMatcher({
    this.stringLength = WaveStateModalShadowContract.defaultStringLength,
  });

  final double stringLength;

  static const String reasonNoCompleteSharedModes = 'no_complete_shared_modes';
  static const String reasonZeroNorm = 'zero_norm_wave_state';
  static const String reasonMissingPhase = 'missing_phase';
  static const String reasonMissingOmega = 'missing_omega';
  static const String reasonMissingAmplitude = 'missing_amplitude';

  /// Orthonormal string mode \(e_m(s)=\sqrt{2/L}\sin(m\pi s/L)\).
  double modeShape(int harmonicIndex, double s) {
    if (stringLength <= 0) {
      throw ArgumentError.value(stringLength, 'stringLength', 'must be > 0');
    }
    if (harmonicIndex < 1) {
      throw ArgumentError.value(harmonicIndex, 'harmonicIndex', 'must be >= 1');
    }
    final L = stringLength;
    return math.sqrt(2.0 / L) * math.sin(harmonicIndex * math.pi * s / L);
  }

  /// Evaluate \(\Psi_u(s,t)\) using only modes with explicit \(A,\phi,\omega\).
  WaveStatePsiSample evaluatePsi({
    required WaveStateModalSubject subject,
    required double s,
    required double t,
  }) {
    var re = 0.0;
    var im = 0.0;
    var used = 0;

    for (final id in WaveStateModalShadowContract.frequencyDimensionIds) {
      final mode = subject.mode(id);
      if (mode == null || !mode.isWaveComplete) continue;
      final m = WaveStateModalShadowContract.harmonicIndex(id);
      if (m == null) continue;

      final A = mode.amplitude!;
      final phase = mode.omega! * t + mode.phaseRadians!;
      final e = modeShape(m, s);
      re += A * e * math.cos(phase);
      im += A * e * math.sin(phase);
      used++;
    }

    if (used == 0) {
      return WaveStatePsiSample.unavailable;
    }
    return WaveStatePsiSample(
      available: true,
      real: re,
      imag: im,
      unavailableReason: null,
      modeCountUsed: used,
    );
  }

  /// Normalized complex state overlap / resonance at time [t].
  ///
  /// Requires shared modes where **both** sides have explicit \(A,\phi,\omega\).
  /// Never fabricates missing phase or omega.
  WaveStateModalShadowResult compare({
    required WaveStateModalSubject a,
    required WaveStateModalSubject b,
    double t = 0.0,
  }) {
    final sharedIds = <String>[];
    final excludedIds = <String>[];
    final ampsA = <double>[];
    final ampsB = <double>[];
    final deltaPhase = <double>[];
    final deltaOmega = <double>[];

    var sawMissingPhase = false;
    var sawMissingOmega = false;
    var sawMissingAmp = false;

    for (final id in WaveStateModalShadowContract.frequencyDimensionIds) {
      final ma = a.mode(id);
      final mb = b.mode(id);

      final aAmp = ma?.hasAmplitude == true;
      final bAmp = mb?.hasAmplitude == true;
      final aPhi = ma?.hasPhase == true;
      final bPhi = mb?.hasPhase == true;
      final aOm = ma?.hasOmega == true;
      final bOm = mb?.hasOmega == true;

      if (!aAmp || !bAmp) {
        if ((aAmp || bAmp) && (!aAmp || !bAmp)) {
          sawMissingAmp = true;
        }
        excludedIds.add(id);
        continue;
      }

      // Amplitudes present on both — require explicit phi + omega on both.
      if (!aPhi || !bPhi) {
        sawMissingPhase = true;
        excludedIds.add(id);
        continue;
      }
      if (!aOm || !bOm) {
        sawMissingOmega = true;
        excludedIds.add(id);
        continue;
      }

      sharedIds.add(id);
      ampsA.add(ma!.amplitude!);
      ampsB.add(mb!.amplitude!);
      deltaPhase.add(ma.phaseRadians! - mb.phaseRadians!);
      deltaOmega.add(ma.omega! - mb.omega!);
    }

    final sharedCount = sharedIds.length;
    final coverage =
        sharedCount / WaveStateModalShadowContract.registryModeCount;

    if (sharedCount == 0) {
      final reason = sawMissingPhase
          ? reasonMissingPhase
          : sawMissingOmega
              ? reasonMissingOmega
              : sawMissingAmp
                  ? reasonMissingAmplitude
                  : reasonNoCompleteSharedModes;
      return _unavailable(
        reason: reason,
        sharedModeCount: 0,
        modalCoverage: 0.0,
        sharedModeIds: const [],
        excludedModeIds: List.unmodifiable(excludedIds),
        t: t,
      );
    }

    final na = _l2(ampsA);
    final nb = _l2(ampsB);
    if (na <= 0.0 || nb <= 0.0) {
      return _unavailable(
        reason: reasonZeroNorm,
        sharedModeCount: sharedCount,
        modalCoverage: coverage,
        sharedModeIds: List.unmodifiable(sharedIds),
        excludedModeIds: List.unmodifiable(excludedIds),
        t: t,
        normA: na,
        normB: nb,
      );
    }

    // ⟨Ψ_a|Ψ_b⟩ = Σ A_a A_b exp(i (Δω t + Δφ))  (via orthonormal e_m)
    var overlapRe = 0.0;
    var overlapIm = 0.0;
    for (var i = 0; i < sharedCount; i++) {
      final theta = deltaOmega[i] * t + deltaPhase[i];
      final w = ampsA[i] * ampsB[i];
      overlapRe += w * math.cos(theta);
      overlapIm += w * math.sin(theta);
    }

    final rWave = overlapRe / (na * nb);

    return WaveStateModalShadowResult(
      resonanceAvailable: true,
      rWave: rWave,
      overlapReal: overlapRe,
      overlapImag: overlapIm,
      normA: na,
      normB: nb,
      sharedModeCount: sharedCount,
      registryModeCount: WaveStateModalShadowContract.registryModeCount,
      modalCoverage: coverage,
      sharedModeIds: List.unmodifiable(sharedIds),
      excludedModeIds: List.unmodifiable(excludedIds),
      unavailableReason: null,
      evaluationTime: t,
      stringLength: stringLength,
      scoringVersion: WaveStateModalShadowContract.scoringVersion,
      policyVersion: WaveStateModalShadowContract.policyVersion,
      policyStatus: WaveStateModalShadowContract.policyStatus,
      registryVersion: WaveStateModalShadowContract.registryVersion,
      shadowOnly: WaveStateModalShadowContract.shadowOnly,
      structuralDistanceCoupled:
          WaveStateModalShadowContract.structuralDistanceCoupled,
    );
  }

  WaveStateModalShadowResult _unavailable({
    required String reason,
    required int sharedModeCount,
    required double modalCoverage,
    required List<String> sharedModeIds,
    required List<String> excludedModeIds,
    required double t,
    double? normA,
    double? normB,
  }) {
    return WaveStateModalShadowResult(
      resonanceAvailable: false,
      rWave: null,
      overlapReal: null,
      overlapImag: null,
      normA: normA,
      normB: normB,
      sharedModeCount: sharedModeCount,
      registryModeCount: WaveStateModalShadowContract.registryModeCount,
      modalCoverage: modalCoverage,
      sharedModeIds: sharedModeIds,
      excludedModeIds: excludedModeIds,
      unavailableReason: reason,
      evaluationTime: t,
      stringLength: stringLength,
      scoringVersion: WaveStateModalShadowContract.scoringVersion,
      policyVersion: WaveStateModalShadowContract.policyVersion,
      policyStatus: WaveStateModalShadowContract.policyStatus,
      registryVersion: WaveStateModalShadowContract.registryVersion,
      shadowOnly: WaveStateModalShadowContract.shadowOnly,
      structuralDistanceCoupled:
          WaveStateModalShadowContract.structuralDistanceCoupled,
    );
  }

  static double _l2(List<double> xs) {
    var s = 0.0;
    for (final x in xs) {
      s += x * x;
    }
    return math.sqrt(s);
  }
}
