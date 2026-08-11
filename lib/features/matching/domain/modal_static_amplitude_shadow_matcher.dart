import 'dart:math' as math;

import 'canonical_20d_shadow_subject.dart';
import 'modal_static_amplitude_shadow_contract.dart';
import 'modal_static_amplitude_shadow_result.dart';

/// Shadow-only static Frequency 6D modal amplitude matcher.
///
/// Over shared measured Frequency modes \(M\):
///
/// \[
/// r_{\mathrm{modal\_shape}}
/// =\frac{A\cdot B}{\lVert A\rVert_2\,\lVert B\rVert_2}
/// \quad\text{(requires }|M|\ge 2\text{ and both norms }>0\text{)}
/// \]
///
/// \[
/// d_{\mathrm{modal\_level}}
/// =\sqrt{\frac{1}{|M|}\sum_{m\in M}(A_m-B_m)^{2}}
/// \quad\text{(requires }|M|\ge 1\text{)}
/// \]
///
/// Outputs stay separate — never fused. No phase, omega, temporal fabrication,
/// Persona, quantum, RVI, or Discover ranking/UI.
class ModalStaticAmplitudeShadowMatcher {
  const ModalStaticAmplitudeShadowMatcher();

  static const String reasonInsufficientSharedModes =
      'insufficient_shared_modes_for_shape';
  static const String reasonZeroNorm = 'zero_norm_amplitude_vector';
  static const String reasonNoSharedModes = 'no_shared_modes';

  ModalStaticAmplitudeShadowResult compareMeasuredPresence({
    required Canonical20dShadowSubject a,
    required Canonical20dShadowSubject b,
  }) {
    final sharedIds = <String>[];
    final excludedIds = <String>[];
    final ampsA = <double>[];
    final ampsB = <double>[];

    for (final id
        in ModalStaticAmplitudeShadowContract.frequencyDimensionIds) {
      final muA = _validAmplitude(a.measuredScores[id]);
      final muB = _validAmplitude(b.measuredScores[id]);
      if (muA == null || muB == null) {
        excludedIds.add(id);
        continue;
      }
      sharedIds.add(id);
      ampsA.add(muA);
      ampsB.add(muB);
    }

    final sharedCount = sharedIds.length;
    const registryCount =
        ModalStaticAmplitudeShadowContract.registryModeCount;
    final coverage = sharedCount / registryCount;

    if (sharedCount == 0) {
      return _result(
        shapeAvailable: false,
        levelAvailable: false,
        rModalShape: null,
        dModalLevel: null,
        sharedModeCount: 0,
        modalCoverage: 0.0,
        sharedModeIds: const [],
        excludedModeIds: excludedIds,
        shapeUnavailableReason: reasonNoSharedModes,
      );
    }

    final dLevel = _rmse(ampsA, ampsB);
    final levelAvailable = dLevel != null;

    String? shapeReason;
    double? rShape;
    var shapeAvailable = false;

    if (sharedCount <
        ModalStaticAmplitudeShadowContract.minSharedModesForShape) {
      shapeReason = reasonInsufficientSharedModes;
    } else {
      final na = _l2(ampsA);
      final nb = _l2(ampsB);
      if (na <= 0.0 || nb <= 0.0) {
        shapeReason = reasonZeroNorm;
      } else {
        var dot = 0.0;
        for (var i = 0; i < ampsA.length; i++) {
          dot += ampsA[i] * ampsB[i];
        }
        rShape = dot / (na * nb);
        shapeAvailable = true;
      }
    }

    return _result(
      shapeAvailable: shapeAvailable,
      levelAvailable: levelAvailable,
      rModalShape: rShape,
      dModalLevel: dLevel,
      sharedModeCount: sharedCount,
      modalCoverage: coverage,
      sharedModeIds: List.unmodifiable(sharedIds),
      excludedModeIds: List.unmodifiable(excludedIds),
      shapeUnavailableReason: shapeReason,
    );
  }

  static ModalStaticAmplitudeShadowResult _result({
    required bool shapeAvailable,
    required bool levelAvailable,
    required double? rModalShape,
    required double? dModalLevel,
    required int sharedModeCount,
    required double modalCoverage,
    required List<String> sharedModeIds,
    required List<String> excludedModeIds,
    required String? shapeUnavailableReason,
  }) {
    return ModalStaticAmplitudeShadowResult(
      shapeAvailable: shapeAvailable,
      levelAvailable: levelAvailable,
      rModalShape: rModalShape,
      dModalLevel: dModalLevel,
      sharedModeCount: sharedModeCount,
      registryModeCount:
          ModalStaticAmplitudeShadowContract.registryModeCount,
      modalCoverage: modalCoverage,
      sharedModeIds: sharedModeIds,
      excludedModeIds: excludedModeIds,
      shapeUnavailableReason: shapeUnavailableReason,
      scoringVersion: ModalStaticAmplitudeShadowContract.scoringVersion,
      policyVersion: ModalStaticAmplitudeShadowContract.policyVersion,
      policyStatus: ModalStaticAmplitudeShadowContract.policyStatus,
      registryVersion: ModalStaticAmplitudeShadowContract.registryVersion,
      shadowOnly: ModalStaticAmplitudeShadowContract.shadowOnly,
      staticAmplitudeOnly:
          ModalStaticAmplitudeShadowContract.staticAmplitudeOnly,
      phaseEnabled: ModalStaticAmplitudeShadowContract.phaseEnabled,
      omegaEnabled: ModalStaticAmplitudeShadowContract.omegaEnabled,
    );
  }

  static double? _validAmplitude(double? raw) {
    if (raw == null) return null;
    if (!raw.isFinite) return null;
    if (raw < 0.0 || raw > 1.0) return null;
    return raw;
  }

  static double _l2(List<double> xs) {
    var s = 0.0;
    for (final x in xs) {
      s += x * x;
    }
    return math.sqrt(s);
  }

  static double? _rmse(List<double> a, List<double> b) {
    if (a.isEmpty || a.length != b.length) return null;
    var sumSq = 0.0;
    for (var i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      sumSq += d * d;
    }
    return math.sqrt(sumSq / a.length);
  }
}
