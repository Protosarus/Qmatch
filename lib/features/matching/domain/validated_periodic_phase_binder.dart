import 'dart:math' as math;

import 'activity_spectral_omega_estimator_models.dart';
import 'validated_periodic_phase_binder_contract.dart';
import 'validated_periodic_phase_binder_models.dart';
import 'wave_state_modal_shadow_v2_models.dart';

/// Shadow-only Class-B phase binder on an accepted activity spectral oscillator.
///
/// For accepted \(T^\star\) from [ActivitySpectralOmegaEstimate]:
/// 1. Shared reference epoch (default: window start UTC).
/// 2. Fold \(t\) modulo \(T^\star\).
/// 3. Circular mean \(\bar\theta\) and resultant length \(\bar R\).
/// 4. Emit [PhaseReferenceV2] with `phase_class = validatedPeriodic`.
///
/// Phase and ω always come from the **same** accepted oscillator_id / \(T^\star\).
/// Does not attach to Frequency modes or Discover.
class ValidatedPeriodicPhaseBinder {
  const ValidatedPeriodicPhaseBinder();

  /// Bind Class-B phase when [omegaEstimate] status is `ok`.
  ///
  /// [referenceEpochMs] defaults to [windowStartMs] (deterministic pairwise
  /// epoch policy [ValidatedPeriodicPhaseBinderContract.referenceEpochPolicy]).
  ValidatedPeriodicPhaseEstimate bind({
    required ActivitySpectralOmegaEstimate omegaEstimate,
    required List<int> timestampsMs,
    required int windowStartMs,
    required int windowEndMs,
    int? referenceEpochMs,
  }) {
    final rejection = _rejectReason(omegaEstimate);
    if (rejection != null) {
      return ValidatedPeriodicPhaseEstimate(
        available: false,
        unavailableReason: rejection,
        eventCount: timestampsMs.length,
        thetaBar: null,
        rBar: null,
        periodSeconds: omegaEstimate.periodSeconds,
        omega: null,
        oscillatorId: omegaEstimate.oscillatorId,
        referenceEpoch: null,
        referenceEpochMs: null,
        phaseReference: null,
        omegaStatus: omegaEstimate.status,
      );
    }

    if (windowEndMs <= windowStartMs) {
      return ValidatedPeriodicPhaseEstimate(
        available: false,
        unavailableReason:
            ValidatedPeriodicPhaseBinderContract.reasonInvalidWindow,
        eventCount: timestampsMs.length,
        thetaBar: null,
        rBar: null,
        periodSeconds: omegaEstimate.periodSeconds,
        omega: omegaEstimate.omega,
        oscillatorId: omegaEstimate.oscillatorId,
        referenceEpoch: null,
        referenceEpochMs: null,
        phaseReference: null,
        omegaStatus: omegaEstimate.status,
      );
    }

    final T = omegaEstimate.periodSeconds!;
    final w = omegaEstimate.omega!;
    final oscId = omegaEstimate.oscillatorId!;

    // Same oscillator: ω must match 2π/T*.
    final expectedW = 2 * math.pi / T;
    if ((w - expectedW).abs() / expectedW > 1e-6) {
      return ValidatedPeriodicPhaseEstimate(
        available: false,
        unavailableReason:
            ValidatedPeriodicPhaseBinderContract.reasonOmegaMismatch,
        eventCount: timestampsMs.length,
        thetaBar: null,
        rBar: null,
        periodSeconds: T,
        omega: w,
        oscillatorId: oscId,
        referenceEpoch: null,
        referenceEpochMs: null,
        phaseReference: null,
        omegaStatus: omegaEstimate.status,
      );
    }

    final epochMs = referenceEpochMs ?? windowStartMs;
    final epochIso = _utcIso(epochMs);

    final inWindow = [
      for (final t in timestampsMs)
        if (t >= windowStartMs && t <= windowEndMs) t,
    ];

    if (inWindow.length < ValidatedPeriodicPhaseBinderContract.minEventsOk) {
      return ValidatedPeriodicPhaseEstimate(
        available: false,
        unavailableReason:
            ValidatedPeriodicPhaseBinderContract.reasonInsufficientEvents,
        eventCount: inWindow.length,
        thetaBar: null,
        rBar: null,
        periodSeconds: T,
        omega: w,
        oscillatorId: oscId,
        referenceEpoch: epochIso,
        referenceEpochMs: epochMs,
        phaseReference: null,
        omegaStatus: omegaEstimate.status,
      );
    }

    var c = 0.0;
    var s = 0.0;
    for (final t in inWindow) {
      final theta = foldPhaseRadians(
        timestampMs: t,
        referenceEpochMs: epochMs,
        periodSeconds: T,
      );
      c += math.cos(theta);
      s += math.sin(theta);
    }
    final n = inWindow.length;
    c /= n;
    s /= n;
    final rBar = math.sqrt(c * c + s * s);
    final thetaBar = math.atan2(s, c);

    if (rBar < ValidatedPeriodicPhaseBinderContract.minRBarOk) {
      return ValidatedPeriodicPhaseEstimate(
        available: false,
        unavailableReason:
            ValidatedPeriodicPhaseBinderContract.reasonLowConcentration,
        eventCount: n,
        thetaBar: thetaBar,
        rBar: rBar,
        periodSeconds: T,
        omega: w,
        oscillatorId: oscId,
        referenceEpoch: epochIso,
        referenceEpochMs: epochMs,
        phaseReference: null,
        omegaStatus: omegaEstimate.status,
      );
    }

    final phase = PhaseReferenceV2(
      oscillatorId: oscId,
      phaseRadians: thetaBar,
      phaseClass: WavePhaseClassV2.validatedPeriodic,
      timeBasis: WavePhaseTimeBasisV2.utc,
      periodicityStatus: WavePeriodicityStatusV2.ok,
      periodSeconds: T,
      omega: w,
      referenceEpoch: epochIso,
      timezone: null,
      source: ValidatedPeriodicPhaseBinderContract.sourceId,
    );

    return ValidatedPeriodicPhaseEstimate(
      available: true,
      unavailableReason: null,
      eventCount: n,
      thetaBar: thetaBar,
      rBar: rBar,
      periodSeconds: T,
      omega: w,
      oscillatorId: oscId,
      referenceEpoch: epochIso,
      referenceEpochMs: epochMs,
      phaseReference: phase,
      omegaStatus: omegaEstimate.status,
    );
  }

  /// Fold timestamp onto \([0,2\pi)\) relative to [referenceEpochMs] and \(T^\star\).
  ///
  /// \[
  /// \tau = ((t - t_0)/1000) \bmod T^\star,\qquad
  /// \theta = 2\pi\,\tau / T^\star
  /// \]
  static double foldPhaseRadians({
    required int timestampMs,
    required int referenceEpochMs,
    required double periodSeconds,
  }) {
    final elapsedSec = (timestampMs - referenceEpochMs) / 1000.0;
    final tau = _positiveMod(elapsedSec, periodSeconds);
    return 2 * math.pi * (tau / periodSeconds);
  }

  static String? _rejectReason(ActivitySpectralOmegaEstimate e) {
    switch (e.status) {
      case ActivitySpectralOmegaStatus.civilCollision:
        return ValidatedPeriodicPhaseBinderContract.reasonCivilCollision;
      case ActivitySpectralOmegaStatus.ambiguous:
        return ValidatedPeriodicPhaseBinderContract.reasonOmegaAmbiguous;
      case ActivitySpectralOmegaStatus.sparse:
        return ValidatedPeriodicPhaseBinderContract.reasonOmegaSparse;
      case ActivitySpectralOmegaStatus.unavailable:
        return ValidatedPeriodicPhaseBinderContract.reasonOmegaUnavailable;
      case ActivitySpectralOmegaStatus.ok:
        break;
    }
    if (!e.accepted) {
      return ValidatedPeriodicPhaseBinderContract.reasonOmegaNotOk;
    }
    if (e.periodSeconds == null ||
        !e.periodSeconds!.isFinite ||
        e.periodSeconds! <= 0) {
      return ValidatedPeriodicPhaseBinderContract.reasonMissingPeriod;
    }
    if (e.omega == null || !e.omega!.isFinite) {
      return ValidatedPeriodicPhaseBinderContract.reasonOmegaNotOk;
    }
    if (e.oscillatorId == null || e.oscillatorId!.isEmpty) {
      return ValidatedPeriodicPhaseBinderContract.reasonMissingOscillator;
    }
    return null;
  }

  static double _positiveMod(double x, double m) {
    if (m <= 0) return 0.0;
    final r = x % m;
    return r < 0 ? r + m : r;
  }

  static String _utcIso(int epochMs) {
    return DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true)
        .toIso8601String();
  }
}
