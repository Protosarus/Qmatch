import 'dart:math' as math;

import 'activity_spectral_omega_estimator_models.dart';
import 'global_activity_periodic_resonance_models.dart';
import 'periodic_wave_state_resonance_adapter_contract.dart';
import 'validated_periodic_phase_binder_models.dart';
import 'wave_state_amplitude_semantics_contract.dart';
import 'wave_state_modal_shadow_v2_compatibility.dart';
import 'wave_state_modal_shadow_v2_models.dart';

/// Tier-1 usable shadow: global periodic activity oscillator.
///
/// \[
/// z_u(t)=A_u\exp\!\big(i(\omega t+\phi_u)\big)
/// \]
///
/// For compatible same-\(\omega\) pairs returns **separately**:
/// - [GlobalActivityPeriodicResonanceResult.phaseAlignment] \(=\cos(\Delta\phi)\)
/// - [GlobalActivityPeriodicResonanceResult.activityLevelA] / B
/// - [GlobalActivityPeriodicResonanceResult.activityLevelGap] \(=|A_u-A_v|\)
///
/// Does **not** fuse activity level into phase alignment.
/// Does **not** attach to Frequency modes or Discover.
class GlobalActivityPeriodicResonance {
  const GlobalActivityPeriodicResonance({
    this.compatibility = const WavePhaseReferenceCompatibilityV2(),
  });

  final WavePhaseReferenceCompatibilityV2 compatibility;

  GlobalActivityPeriodicResonanceResult compare({
    required ActivitySpectralOmegaEstimate omegaA,
    required ValidatedPeriodicPhaseEstimate phaseA,
    required double activityLevelA,
    required ActivitySpectralOmegaEstimate omegaB,
    required ValidatedPeriodicPhaseEstimate phaseB,
    required double activityLevelB,
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

    if (!(activityLevelA.isFinite && activityLevelA > 0) ||
        !(activityLevelB.isFinite && activityLevelB > 0)) {
      return _unavailable(
        reason: GlobalActivityPeriodicResonanceContract
            .reasonNonPositiveActivityLevel,
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
      return GlobalActivityPeriodicResonanceResult(
        available: false,
        unavailableReason: gate.reason ??
            PeriodicWaveStateResonanceAdapterContract.reasonPhaseIncompatible,
        phaseAlignment: null,
        activityLevelA: null,
        activityLevelB: null,
        activityLevelGap: null,
        deltaPhi: null,
        oscillatorId: prefA.oscillatorId,
        periodSeconds: prefA.periodSeconds,
        omega: prefA.resolvedOmega,
        evaluationTime: t,
        phaseCompatibility: gate.status,
      );
    }

    final dPhi = prefA.phaseRadians - prefB.phaseRadians;
    // Same-ω compatible pairs: Δω≈0 ⇒ relative phase alignment is time-invariant.
    final phaseAlignment = math.cos(dPhi);

    return GlobalActivityPeriodicResonanceResult(
      available: true,
      unavailableReason: null,
      phaseAlignment: phaseAlignment,
      activityLevelA: activityLevelA,
      activityLevelB: activityLevelB,
      activityLevelGap: (activityLevelA - activityLevelB).abs(),
      deltaPhi: dPhi,
      oscillatorId: prefA.oscillatorId,
      periodSeconds: prefA.periodSeconds,
      omega: prefA.resolvedOmega,
      evaluationTime: t,
      phaseCompatibility: WavePhaseCompatibilityV2.compatible,
    );
  }

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
        !_near(phase.periodSeconds, omega.periodSeconds) ||
        !_near(pref.resolvedOmega, omega.omega) ||
        !_near(phase.omega, omega.omega)) {
      return PeriodicWaveStateResonanceAdapterContract.reasonProvenanceMismatch;
    }
    return null;
  }

  static bool _near(double? a, double? b) {
    if (a == null || b == null || !a.isFinite || !b.isFinite) return false;
    final scale = math.max(a.abs(), math.max(b.abs(), 1.0));
    return (a - b).abs() <=
        PeriodicWaveStateResonanceAdapterContract.omegaRelativeTolerance *
            scale;
  }

  static GlobalActivityPeriodicResonanceResult _unavailable({
    required String reason,
    required double t,
    String? oscillatorId,
    double? periodSeconds,
    double? omega,
  }) {
    return GlobalActivityPeriodicResonanceResult(
      available: false,
      unavailableReason: reason,
      phaseAlignment: null,
      activityLevelA: null,
      activityLevelB: null,
      activityLevelGap: null,
      deltaPhi: null,
      oscillatorId: oscillatorId,
      periodSeconds: periodSeconds,
      omega: omega,
      evaluationTime: t,
      phaseCompatibility: null,
    );
  }
}
