import 'dart:math' as math;

import 'wave_state_modal_shadow_v2_compatibility.dart';
import 'wave_state_modal_shadow_v2_contract.dart';
import 'wave_state_modal_shadow_v2_models.dart';

/// Wave-State Modal Shadow v2 matcher (phase-reference policy aware).
///
/// Signed \(r_{\mathrm{wave}}\) only on provenance-compatible Class A/B modes.
/// Never gauge-fixes unanchored phase. Emits diagnostic \(c_{\mathrm{abs}}\) /
/// \(c_{\mathrm{abs}}^{2}\) without ranking use. Structural distance stays separate.
class WaveStateModalShadowV2Matcher {
  const WaveStateModalShadowV2Matcher({
    this.stringLength = WaveStateModalShadowV2Contract.defaultStringLength,
    this.compatibility = const WavePhaseReferenceCompatibilityV2(),
  });

  final double stringLength;
  final WavePhaseReferenceCompatibilityV2 compatibility;

  static const String reasonNoSignedCompatibleModes =
      'no_signed_compatible_modes';
  static const String reasonZeroNorm = 'zero_norm_wave_state';
  static const String reasonMissingAmplitude = 'missing_amplitude';

  /// Orthonormal string mode \(e_m(s)\).
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

  WaveStateModalShadowV2Result compare({
    required WaveStateModalSubjectV2 a,
    required WaveStateModalSubjectV2 b,
    double t = 0.0,
  }) {
    final signedIds = <String>[];
    final diagIds = <String>[];
    final excluded = <String>[];

    final signedAmpsA = <double>[];
    final signedAmpsB = <double>[];
    final signedDPhi = <double>[];
    final signedDOmega = <double>[];

    final diagAmpsA = <double>[];
    final diagAmpsB = <double>[];
    final diagDPhi = <double>[];
    final diagDOmega = <double>[];

    WavePhaseCompatibilityV2 aggregateCompat =
        WavePhaseCompatibilityV2.compatible;
    String? primaryUnsignedReason;
    var sawMissingAmp = false;

    void noteUnsigned(WavePhaseCompatibilityCheckV2 check) {
      primaryUnsignedReason ??= check.reason;
      if (check.status == WavePhaseCompatibilityV2.unanchored) {
        aggregateCompat = WavePhaseCompatibilityV2.unanchored;
      } else if (check.status == WavePhaseCompatibilityV2.insufficientQuality &&
          aggregateCompat != WavePhaseCompatibilityV2.unanchored) {
        aggregateCompat = WavePhaseCompatibilityV2.insufficientQuality;
      } else if (check.status == WavePhaseCompatibilityV2.missingProvenance &&
          aggregateCompat != WavePhaseCompatibilityV2.unanchored &&
          aggregateCompat != WavePhaseCompatibilityV2.insufficientQuality) {
        aggregateCompat = WavePhaseCompatibilityV2.missingProvenance;
      } else if (aggregateCompat == WavePhaseCompatibilityV2.compatible) {
        aggregateCompat = WavePhaseCompatibilityV2.incompatible;
      }
    }

    for (final id in WaveStateModalShadowV2Contract.frequencyDimensionIds) {
      final ma = a.mode(id);
      final mb = b.mode(id);
      final aAmp = ma?.hasAmplitude == true;
      final bAmp = mb?.hasAmplitude == true;

      if (!aAmp || !bAmp) {
        if ((aAmp || bAmp) && (!aAmp || !bAmp)) sawMissingAmp = true;
        excluded.add(id);
        continue;
      }

      final pa = ma!.phase;
      final pb = mb!.phase;
      if (pa == null || pb == null) {
        primaryUnsignedReason ??=
            WavePhaseReferenceCompatibilityV2.reasonMissingProvenance;
        if (aggregateCompat == WavePhaseCompatibilityV2.compatible) {
          aggregateCompat = WavePhaseCompatibilityV2.missingProvenance;
        }
        excluded.add(id);
        continue;
      }

      final numericOk = ma.hasNumericWaveInputs && mb.hasNumericWaveInputs;
      if (numericOk) {
        // Diagnostic magnitude may use numeric inputs without signed gate.
        diagIds.add(id);
        diagAmpsA.add(ma.amplitude!);
        diagAmpsB.add(mb.amplitude!);
        diagDPhi.add(pa.phaseRadians - pb.phaseRadians);
        diagDOmega.add(pa.resolvedOmega! - pb.resolvedOmega!);
      }

      final gate = compatibility.check(a: pa, b: pb);
      if (!gate.compatibleForSigned || !numericOk) {
        noteUnsigned(
          numericOk
              ? gate
              : WavePhaseCompatibilityCheckV2(
                  compatibleForSigned: false,
                  status: WavePhaseCompatibilityV2.missingProvenance,
                  reason: WavePhaseReferenceCompatibilityV2
                      .reasonMissingProvenance,
                ),
        );
        excluded.add(id);
        continue;
      }

      // Compatible Class A/B — retain global Δφ (no gauge fix).
      signedIds.add(id);
      signedAmpsA.add(ma.amplitude!);
      signedAmpsB.add(mb.amplitude!);
      signedDPhi.add(pa.phaseRadians - pb.phaseRadians);
      signedDOmega.add(pa.resolvedOmega! - pb.resolvedOmega!);
    }

    final signedCount = signedIds.length;
    final coverage =
        signedCount / WaveStateModalShadowV2Contract.registryModeCount;

    if (signedCount > 0) {
      final overlap = _overlap(
        ampsA: signedAmpsA,
        ampsB: signedAmpsB,
        dPhi: signedDPhi,
        dOmega: signedDOmega,
        t: t,
      );
      if (overlap == null) {
        return _result(
          signedAvailable: false,
          rWave: null,
          reason: reasonZeroNorm,
          cAbs: null,
          cAbsSq: null,
          phaseCompatibility: WavePhaseCompatibilityV2.compatible,
          overlapReal: null,
          overlapImag: null,
          normA: 0.0,
          normB: 0.0,
          signedCount: signedCount,
          diagCount: diagIds.length,
          coverage: coverage,
          signedIds: signedIds,
          excludedIds: excluded,
          t: t,
        );
      }
      return _result(
        signedAvailable: true,
        rWave: overlap.rWave,
        reason: null,
        cAbs: overlap.cAbs,
        cAbsSq: overlap.cAbsSq,
        phaseCompatibility: WavePhaseCompatibilityV2.compatible,
        overlapReal: overlap.re,
        overlapImag: overlap.im,
        normA: overlap.na,
        normB: overlap.nb,
        signedCount: signedCount,
        diagCount: diagIds.length,
        coverage: coverage,
        signedIds: signedIds,
        excludedIds: excluded,
        t: t,
      );
    }

    // No signed-compatible modes. Emit diagnostic |overlap| if numeric modes exist.
    String reason;
    if (primaryUnsignedReason != null) {
      reason = primaryUnsignedReason!;
    } else if (sawMissingAmp) {
      reason = reasonMissingAmplitude;
    } else {
      reason = reasonNoSignedCompatibleModes;
    }

    if (diagIds.isEmpty) {
      return _result(
        signedAvailable: false,
        rWave: null,
        reason: reason,
        cAbs: null,
        cAbsSq: null,
        phaseCompatibility: aggregateCompat == WavePhaseCompatibilityV2.compatible
            ? WavePhaseCompatibilityV2.missingProvenance
            : aggregateCompat,
        overlapReal: null,
        overlapImag: null,
        normA: null,
        normB: null,
        signedCount: 0,
        diagCount: 0,
        coverage: 0.0,
        signedIds: const [],
        excludedIds: excluded,
        t: t,
      );
    }

    final diag = _overlap(
      ampsA: diagAmpsA,
      ampsB: diagAmpsB,
      dPhi: diagDPhi,
      dOmega: diagDOmega,
      t: t,
    );
    return _result(
      signedAvailable: false,
      rWave: null,
      reason: reason,
      cAbs: diag?.cAbs,
      cAbsSq: diag?.cAbsSq,
      phaseCompatibility: aggregateCompat == WavePhaseCompatibilityV2.compatible
          ? WavePhaseCompatibilityV2.incompatible
          : aggregateCompat,
      overlapReal: diag?.re,
      overlapImag: diag?.im,
      normA: diag?.na,
      normB: diag?.nb,
      signedCount: 0,
      diagCount: diagIds.length,
      coverage: 0.0,
      signedIds: const [],
      excludedIds: excluded,
      t: t,
    );
  }

  _Overlap? _overlap({
    required List<double> ampsA,
    required List<double> ampsB,
    required List<double> dPhi,
    required List<double> dOmega,
    required double t,
  }) {
    final na = _l2(ampsA);
    final nb = _l2(ampsB);
    if (na <= 0.0 || nb <= 0.0) return null;
    var re = 0.0;
    var im = 0.0;
    for (var i = 0; i < ampsA.length; i++) {
      final theta = dOmega[i] * t + dPhi[i];
      final w = ampsA[i] * ampsB[i];
      re += w * math.cos(theta);
      im += w * math.sin(theta);
    }
    final denom = na * nb;
    final rWave = re / denom;
    final imN = im / denom;
    final cAbs = math.sqrt(rWave * rWave + imN * imN);
    return _Overlap(
      re: re,
      im: im,
      na: na,
      nb: nb,
      rWave: rWave,
      cAbs: cAbs,
      cAbsSq: cAbs * cAbs,
    );
  }

  WaveStateModalShadowV2Result _result({
    required bool signedAvailable,
    required double? rWave,
    required String? reason,
    required double? cAbs,
    required double? cAbsSq,
    required WavePhaseCompatibilityV2 phaseCompatibility,
    required double? overlapReal,
    required double? overlapImag,
    required double? normA,
    required double? normB,
    required int signedCount,
    required int diagCount,
    required double coverage,
    required List<String> signedIds,
    required List<String> excludedIds,
    required double t,
  }) {
    return WaveStateModalShadowV2Result(
      signedResonanceAvailable: signedAvailable,
      rWave: rWave,
      rWaveUnavailableReason: reason,
      cAbs: cAbs,
      cAbsSq: cAbsSq,
      cAbsDiagnosticOnly: true,
      phaseCompatibility: phaseCompatibility,
      overlapReal: overlapReal,
      overlapImag: overlapImag,
      normA: normA,
      normB: normB,
      signedSharedModeCount: signedCount,
      diagnosticSharedModeCount: diagCount,
      registryModeCount: WaveStateModalShadowV2Contract.registryModeCount,
      modalCoverageSigned: coverage,
      signedSharedModeIds: List.unmodifiable(signedIds),
      excludedModeIds: List.unmodifiable(excludedIds),
      evaluationTime: t,
      stringLength: stringLength,
      scoringVersion: WaveStateModalShadowV2Contract.scoringVersion,
      policyVersion: WaveStateModalShadowV2Contract.policyVersion,
      policyStatus: WaveStateModalShadowV2Contract.policyStatus,
      registryVersion: WaveStateModalShadowV2Contract.registryVersion,
      shadowOnly: WaveStateModalShadowV2Contract.shadowOnly,
      structuralDistanceCoupled:
          WaveStateModalShadowV2Contract.structuralDistanceCoupled,
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

class _Overlap {
  const _Overlap({
    required this.re,
    required this.im,
    required this.na,
    required this.nb,
    required this.rWave,
    required this.cAbs,
    required this.cAbsSq,
  });

  final double re;
  final double im;
  final double na;
  final double nb;
  final double rWave;
  final double cAbs;
  final double cAbsSq;
}
