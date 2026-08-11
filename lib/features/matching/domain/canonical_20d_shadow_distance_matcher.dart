import 'dart:math' as math;

import 'canonical_20d_shadow_distance_contract.dart';
import 'canonical_20d_shadow_distance_result.dart';
import 'canonical_20d_shadow_subject.dart';

/// Shadow-only pairwise matcher over shared measured canonical 20D dimensions.
///
/// Formula (equal-weight mean squared Euclidean over comparable set \(K\)):
///
/// \[
/// d^{2} = \frac{1}{|K|}\sum_{k \in K}(\mu_{A,k}-\mu_{B,k})^{2},\quad
/// d = \sqrt{d^{2}}
/// \]
///
/// A dimension is comparable only when both subjects have a finite measured
/// score in \([0,1]\) and `evidence_count >= 1`. Missing dims are excluded —
/// never imputed as 0 / 0.5 / 50. Equal weights only — no confidence scaling,
/// no similarity transform, no Discover coupling.
class Canonical20dShadowDistanceMatcher {
  const Canonical20dShadowDistanceMatcher();

  Canonical20dShadowDistanceResult compare({
    required Canonical20dShadowSubject a,
    required Canonical20dShadowSubject b,
  }) {
    final comparableIds = <String>[];
    final excludedIds = <String>[];
    var sumSq = 0.0;

    for (final id in Canonical20dShadowDistanceContract.dimensionIds) {
      final muA = _validMeasuredScore(a.measuredScores[id]);
      final muB = _validMeasuredScore(b.measuredScores[id]);
      final nA = a.evidenceCounts[id] ?? 0;
      final nB = b.evidenceCounts[id] ?? 0;
      final evidenceOk =
          nA >= Canonical20dShadowDistanceContract.minEvidenceCount &&
              nB >= Canonical20dShadowDistanceContract.minEvidenceCount;

      if (muA == null || muB == null || !evidenceOk) {
        excludedIds.add(id);
        continue;
      }

      final delta = muA - muB;
      sumSq += delta * delta;
      comparableIds.add(id);
    }

    final registryCount =
        Canonical20dShadowDistanceContract.requiredDimensionCount;
    final k = comparableIds.length;
    final coverage = registryCount == 0 ? 0.0 : k / registryCount;

    if (k == 0) {
      return Canonical20dShadowDistanceResult(
        available: false,
        distanceSquared: null,
        distance: null,
        comparableDimensionCount: 0,
        registryDimensionCount: registryCount,
        unweightedCoverage: 0.0,
        comparableDimensionIds: const [],
        excludedDimensionIds: List.unmodifiable(excludedIds),
        scoringVersion: Canonical20dShadowDistanceContract.scoringVersion,
        registryVersion: Canonical20dShadowDistanceContract.registryVersion,
        shadowOnly: true,
      );
    }

    final d2 = sumSq / k;
    final d = math.sqrt(d2);
    return Canonical20dShadowDistanceResult(
      available: true,
      distanceSquared: d2,
      distance: d,
      comparableDimensionCount: k,
      registryDimensionCount: registryCount,
      unweightedCoverage: coverage,
      comparableDimensionIds: List.unmodifiable(comparableIds),
      excludedDimensionIds: List.unmodifiable(excludedIds),
      scoringVersion: Canonical20dShadowDistanceContract.scoringVersion,
      registryVersion: Canonical20dShadowDistanceContract.registryVersion,
      shadowOnly: true,
    );
  }

  /// Score present, finite, and in [0, 1]; otherwise not measured.
  static double? _validMeasuredScore(double? raw) {
    if (raw == null) return null;
    if (!raw.isFinite) return null;
    if (raw < 0.0 || raw > 1.0) return null;
    return raw;
  }
}
