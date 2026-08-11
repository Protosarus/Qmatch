import 'wave_state_modal_shadow_v2_contract.dart';
import 'wave_state_modal_shadow_v2_models.dart';

/// Result of pairwise [PhaseReferenceV2] compatibility.
class WavePhaseCompatibilityCheckV2 {
  const WavePhaseCompatibilityCheckV2({
    required this.compatibleForSigned,
    required this.status,
    required this.reason,
  });

  final bool compatibleForSigned;
  final WavePhaseCompatibilityV2 status;
  final String? reason;

  static const WavePhaseCompatibilityCheckV2 ok = WavePhaseCompatibilityCheckV2(
    compatibleForSigned: true,
    status: WavePhaseCompatibilityV2.compatible,
    reason: null,
  );
}

/// Pure pairwise phase-reference compatibility gate (policy v1).
class WavePhaseReferenceCompatibilityV2 {
  const WavePhaseReferenceCompatibilityV2();

  static const String reasonMissingProvenance = 'missing_phase_metadata';
  static const String reasonUnanchored = 'unanchored_phase';
  static const String reasonIncompatibleOscillator =
      'incompatible_oscillator_id';
  static const String reasonIncompatiblePeriod = 'incompatible_period';
  static const String reasonIncompatibleEpoch = 'incompatible_reference_epoch';
  static const String reasonIncompatibleTimeBasis = 'incompatible_time_basis';
  static const String reasonInsufficientQuality = 'phase_quality_insufficient';
  static const String reasonIncompatibleClass = 'incompatible_phase_class';
  static const String reasonQuestionnaire =
      'questionnaire_phase_forbidden';

  WavePhaseCompatibilityCheckV2 check({
    required PhaseReferenceV2 a,
    required PhaseReferenceV2 b,
  }) {
    final gapA = a.provenanceGapReason();
    final gapB = b.provenanceGapReason();
    if (gapA == reasonQuestionnaire || gapB == reasonQuestionnaire) {
      return const WavePhaseCompatibilityCheckV2(
        compatibleForSigned: false,
        status: WavePhaseCompatibilityV2.missingProvenance,
        reason: reasonQuestionnaire,
      );
    }
    if (gapA == reasonUnanchored || gapB == reasonUnanchored) {
      return const WavePhaseCompatibilityCheckV2(
        compatibleForSigned: false,
        status: WavePhaseCompatibilityV2.unanchored,
        reason: reasonUnanchored,
      );
    }
    if (gapA != null || gapB != null) {
      return WavePhaseCompatibilityCheckV2(
        compatibleForSigned: false,
        status: WavePhaseCompatibilityV2.missingProvenance,
        reason: gapA ?? gapB,
      );
    }

    if (a.phaseClass != b.phaseClass) {
      return const WavePhaseCompatibilityCheckV2(
        compatibleForSigned: false,
        status: WavePhaseCompatibilityV2.incompatible,
        reason: reasonIncompatibleClass,
      );
    }

    // Class A and B only beyond this point (unanchored already rejected).
    if (a.phaseClass != WavePhaseClassV2.externalAnchored &&
        a.phaseClass != WavePhaseClassV2.validatedPeriodic) {
      return const WavePhaseCompatibilityCheckV2(
        compatibleForSigned: false,
        status: WavePhaseCompatibilityV2.unanchored,
        reason: reasonUnanchored,
      );
    }

    if (a.oscillatorId != b.oscillatorId) {
      return const WavePhaseCompatibilityCheckV2(
        compatibleForSigned: false,
        status: WavePhaseCompatibilityV2.incompatible,
        reason: reasonIncompatibleOscillator,
      );
    }

    if (a.timeBasis != b.timeBasis) {
      return const WavePhaseCompatibilityCheckV2(
        compatibleForSigned: false,
        status: WavePhaseCompatibilityV2.incompatible,
        reason: reasonIncompatibleTimeBasis,
      );
    }

    if (!_omegaCompatible(a.resolvedOmega!, b.resolvedOmega!)) {
      return const WavePhaseCompatibilityCheckV2(
        compatibleForSigned: false,
        status: WavePhaseCompatibilityV2.incompatible,
        reason: reasonIncompatiblePeriod,
      );
    }

    if (a.phaseClass == WavePhaseClassV2.validatedPeriodic) {
      if (a.referenceEpoch != b.referenceEpoch) {
        return const WavePhaseCompatibilityCheckV2(
          compatibleForSigned: false,
          status: WavePhaseCompatibilityV2.incompatible,
          reason: reasonIncompatibleEpoch,
        );
      }
    }

    if (WaveStateModalShadowV2Contract.signedRequiresPeriodicityOk) {
      if (a.periodicityStatus != WavePeriodicityStatusV2.ok ||
          b.periodicityStatus != WavePeriodicityStatusV2.ok) {
        return const WavePhaseCompatibilityCheckV2(
          compatibleForSigned: false,
          status: WavePhaseCompatibilityV2.insufficientQuality,
          reason: reasonInsufficientQuality,
        );
      }
    }

    return WavePhaseCompatibilityCheckV2.ok;
  }

  static bool _omegaCompatible(double wa, double wb) {
    final scale = mathMax(wa.abs(), wb.abs(), 1.0);
    final tol =
        WaveStateModalShadowV2Contract.omegaRelativeTolerance * scale;
    return (wa - wb).abs() <= tol;
  }

  static double mathMax(double a, double b, double c) {
    var m = a;
    if (b > m) m = b;
    if (c > m) m = c;
    return m;
  }
}
