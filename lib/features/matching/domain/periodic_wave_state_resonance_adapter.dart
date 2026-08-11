import 'dart:math' as math;

import 'activity_spectral_omega_estimator_models.dart';
import 'periodic_wave_state_resonance_adapter_contract.dart';
import 'periodic_wave_state_resonance_adapter_models.dart';
import 'validated_periodic_phase_binder_models.dart';
import 'wave_state_modal_shadow_v2_compatibility.dart';
import 'wave_state_modal_shadow_v2_models.dart';

/// Shadow-only adapter binding an accepted Class-B spectral oscillator into
/// Wave-State v2 resonance math.
///
/// Flow:
/// 1. Reject non-ok / civilCollision / ambiguous / sparse omega (both sides).
/// 2. Require available [ValidatedPeriodicPhaseEstimate] on the **same**
///    oscillator / \(T^\star\) / \(\omega\) provenance.
/// 3. Gate pairwise [PhaseReferenceV2] via [WavePhaseReferenceCompatibilityV2].
/// 4. Compute signed \(r_{\mathrm{wave}}\), diagnostic \(c_{\mathrm{abs}}\),
///    \(c_{\mathrm{abs}}^{2}\) with modal amplitude envelope (not Frequency attach).
///
/// Structural distance stays decoupled. No Discover / Persona / RVI / density-matrix.
class PeriodicWaveStateResonanceAdapter {
  const PeriodicWaveStateResonanceAdapter({
    this.compatibility = const WavePhaseReferenceCompatibilityV2(),
  });

  final WavePhaseReferenceCompatibilityV2 compatibility;

  /// Pairwise resonance under validated periodic oscillators.
  ///
  /// [modalAmplitudesA] / [modalAmplitudesB] are envelope weights of equal
  /// length (not Frequency mode identities). A scalar may be passed as `[A]`.
  PeriodicWaveStateResonanceResult compare({
    required ActivitySpectralOmegaEstimate omegaA,
    required ValidatedPeriodicPhaseEstimate phaseA,
    required List<double> modalAmplitudesA,
    required ActivitySpectralOmegaEstimate omegaB,
    required ValidatedPeriodicPhaseEstimate phaseB,
    required List<double> modalAmplitudesB,
    double t = 0.0,
  }) {
    final sideA = _validateSide(omega: omegaA, phase: phaseA);
    if (sideA != null) {
      return _unavailable(reason: sideA, t: t);
    }
    final sideB = _validateSide(omega: omegaB, phase: phaseB);
    if (sideB != null) {
      return _unavailable(reason: sideB, t: t);
    }

    if (modalAmplitudesA.isEmpty || modalAmplitudesB.isEmpty) {
      return _unavailable(
        reason: PeriodicWaveStateResonanceAdapterContract.reasonEmptyAmplitudes,
        t: t,
        oscillatorId: phaseA.oscillatorId,
        periodSeconds: phaseA.periodSeconds,
        omega: phaseA.omega,
      );
    }
    if (modalAmplitudesA.length != modalAmplitudesB.length) {
      return _unavailable(
        reason: PeriodicWaveStateResonanceAdapterContract
            .reasonAmplitudeLengthMismatch,
        t: t,
        oscillatorId: phaseA.oscillatorId,
        periodSeconds: phaseA.periodSeconds,
        omega: phaseA.omega,
      );
    }

    final prefA = phaseA.phaseReference!;
    final prefB = phaseB.phaseReference!;
    final gate = compatibility.check(a: prefA, b: prefB);
    if (!gate.compatibleForSigned) {
      return PeriodicWaveStateResonanceResult(
        signedResonanceAvailable: false,
        rWave: null,
        unavailableReason: gate.reason ??
            PeriodicWaveStateResonanceAdapterContract.reasonPhaseIncompatible,
        cAbs: null,
        cAbsSq: null,
        phaseCompatibility: gate.status,
        compatibilityReason: gate.reason,
        overlapReal: null,
        overlapImag: null,
        normA: null,
        normB: null,
        evaluationTime: t,
        oscillatorId: prefA.oscillatorId,
        periodSeconds: prefA.periodSeconds,
        omega: prefA.resolvedOmega,
      );
    }

    final wa = prefA.resolvedOmega!;
    final wb = prefB.resolvedOmega!;
    final dPhi = prefA.phaseRadians - prefB.phaseRadians;
    final dOmega = wa - wb;

    final na = _l2(modalAmplitudesA);
    final nb = _l2(modalAmplitudesB);
    if (na <= 0.0 || nb <= 0.0) {
      return _unavailable(
        reason: PeriodicWaveStateResonanceAdapterContract.reasonZeroNorm,
        t: t,
        oscillatorId: prefA.oscillatorId,
        periodSeconds: prefA.periodSeconds,
        omega: wa,
      );
    }

    var re = 0.0;
    var im = 0.0;
    for (var i = 0; i < modalAmplitudesA.length; i++) {
      final theta = dOmega * t + dPhi;
      final w = modalAmplitudesA[i] * modalAmplitudesB[i];
      re += w * math.cos(theta);
      im += w * math.sin(theta);
    }
    final denom = na * nb;
    final rWave = re / denom;
    final imN = im / denom;
    final cAbs = math.sqrt(rWave * rWave + imN * imN);

    return PeriodicWaveStateResonanceResult(
      signedResonanceAvailable: true,
      rWave: rWave,
      unavailableReason: null,
      cAbs: cAbs,
      cAbsSq: cAbs * cAbs,
      phaseCompatibility: WavePhaseCompatibilityV2.compatible,
      compatibilityReason: null,
      overlapReal: re,
      overlapImag: im,
      normA: na,
      normB: nb,
      evaluationTime: t,
      oscillatorId: prefA.oscillatorId,
      periodSeconds: prefA.periodSeconds,
      omega: wa,
    );
  }

  /// Validate omega status + phase availability + same-oscillator provenance.
  static String? _validateSide({
    required ActivitySpectralOmegaEstimate omega,
    required ValidatedPeriodicPhaseEstimate phase,
  }) {
    switch (omega.status) {
      case ActivitySpectralOmegaStatus.civilCollision:
        return PeriodicWaveStateResonanceAdapterContract.reasonCivilCollision;
      case ActivitySpectralOmegaStatus.ambiguous:
        return PeriodicWaveStateResonanceAdapterContract.reasonOmegaAmbiguous;
      case ActivitySpectralOmegaStatus.sparse:
        return PeriodicWaveStateResonanceAdapterContract.reasonOmegaSparse;
      case ActivitySpectralOmegaStatus.unavailable:
        return PeriodicWaveStateResonanceAdapterContract.reasonOmegaUnavailable;
      case ActivitySpectralOmegaStatus.ok:
        break;
    }
    if (!omega.accepted ||
        omega.periodSeconds == null ||
        omega.omega == null ||
        omega.oscillatorId == null ||
        omega.oscillatorId!.isEmpty) {
      return PeriodicWaveStateResonanceAdapterContract.reasonOmegaNotOk;
    }
    if (!phase.available ||
        phase.phaseReference == null ||
        phase.omegaStatus != ActivitySpectralOmegaStatus.ok) {
      return PeriodicWaveStateResonanceAdapterContract.reasonPhaseUnavailable;
    }

    final pref = phase.phaseReference!;
    if (pref.phaseClass != WavePhaseClassV2.validatedPeriodic) {
      return PeriodicWaveStateResonanceAdapterContract.reasonProvenanceMismatch;
    }
    if (pref.oscillatorId != omega.oscillatorId ||
        phase.oscillatorId != omega.oscillatorId) {
      return PeriodicWaveStateResonanceAdapterContract.reasonProvenanceMismatch;
    }
    if (!_near(pref.periodSeconds, omega.periodSeconds) ||
        !_near(phase.periodSeconds, omega.periodSeconds)) {
      return PeriodicWaveStateResonanceAdapterContract.reasonProvenanceMismatch;
    }
    if (!_near(pref.resolvedOmega, omega.omega) ||
        !_near(phase.omega, omega.omega)) {
      return PeriodicWaveStateResonanceAdapterContract.reasonProvenanceMismatch;
    }
    return null;
  }

  static bool _near(double? a, double? b) {
    if (a == null || b == null || !a.isFinite || !b.isFinite) return false;
    final scale = math.max(a.abs(), math.max(b.abs(), 1.0));
    return (a - b).abs() <=
        PeriodicWaveStateResonanceAdapterContract.omegaRelativeTolerance * scale;
  }

  static double _l2(List<double> xs) {
    var s = 0.0;
    for (final x in xs) {
      s += x * x;
    }
    return math.sqrt(s);
  }

  static PeriodicWaveStateResonanceResult _unavailable({
    required String reason,
    required double t,
    String? oscillatorId,
    double? periodSeconds,
    double? omega,
  }) {
    return PeriodicWaveStateResonanceResult(
      signedResonanceAvailable: false,
      rWave: null,
      unavailableReason: reason,
      cAbs: null,
      cAbsSq: null,
      phaseCompatibility: null,
      compatibilityReason: null,
      overlapReal: null,
      overlapImag: null,
      normA: null,
      normB: null,
      evaluationTime: t,
      oscillatorId: oscillatorId,
      periodSeconds: periodSeconds,
      omega: omega,
    );
  }
}
