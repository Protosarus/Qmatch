import 'dart:math' as math;

import 'canonical_20d_group_normalized_shadow_contract.dart';
import 'canonical_20d_group_normalized_shadow_result.dart';
import 'canonical_20d_shadow_subject.dart';

/// Structural Matching production-candidate matcher (group-normalized 20D).
///
/// Policy: `production_candidate_not_live` — frozen weights, not live ranking.
///
/// Per available module \(m\) over shared measured dims \(K_m\):
///
/// \[
/// d_m^{2}=\frac{1}{|K_m|}\sum_{k\in K_m}(\mu_{A,k}-\mu_{B,k})^{2}
/// \]
///
/// Combined over available modules \(A\) with frozen weights
/// \(w_{\mathrm{IQ}}=0.133333\), \(w_{\mathrm{EQ}}=0.400000\),
/// \(w_{\mathrm{F}}=0.466667\), renormalized when modules are omitted:
///
/// \[
/// d^{2}=\sum_{m\in A}\tilde{w}_m\,d_m^{2},\quad
/// \tilde{w}_m=\frac{w_m}{\sum_{j\in A}w_j},\quad
/// d=\sqrt{d^{2}}
/// \]
///
/// Missing dims are excluded — never 0 / 0.5 / 50. No Persona, archetype,
/// quantum, RVI, similarity %, Discover ranking/UI, or equal-20D replacement.
class Canonical20dGroupNormalizedShadowMatcher {
  const Canonical20dGroupNormalizedShadowMatcher();

  Canonical20dGroupNormalizedShadowResult compareMeasuredPresence({
    required Canonical20dShadowSubject a,
    required Canonical20dShadowSubject b,
  }) {
    final iq = _moduleDistance(
      moduleId: 'iq',
      dimensionIds: Canonical20dGroupNormalizedShadowContract.iqDimensionIds,
      configuredWeight: Canonical20dGroupNormalizedShadowContract.iqWeight,
      a: a,
      b: b,
    );
    final eq = _moduleDistance(
      moduleId: 'eq',
      dimensionIds: Canonical20dGroupNormalizedShadowContract.eqDimensionIds,
      configuredWeight: Canonical20dGroupNormalizedShadowContract.eqWeight,
      a: a,
      b: b,
    );
    final frequency = _moduleDistance(
      moduleId: 'frequency',
      dimensionIds:
          Canonical20dGroupNormalizedShadowContract.frequencyDimensionIds,
      configuredWeight:
          Canonical20dGroupNormalizedShadowContract.frequencyWeight,
      a: a,
      b: b,
    );

    final availableModules = <Canonical20dGroupModuleDistance>[
      if (iq.available) iq,
      if (eq.available) eq,
      if (frequency.available) frequency,
    ];

    final totalComparable = iq.comparableDimensionCount +
        eq.comparableDimensionCount +
        frequency.comparableDimensionCount;
    const totalRegistry = 20;
    final totalCoverage = totalComparable / totalRegistry;

    if (availableModules.isEmpty) {
      return Canonical20dGroupNormalizedShadowResult(
        available: false,
        iq: iq,
        eq: eq,
        frequency: frequency,
        combinedDistanceSquared: null,
        combinedDistance: null,
        totalComparableDimensionCount: 0,
        totalRegistryDimensionCount: totalRegistry,
        totalCoverage: 0.0,
        scoringVersion:
            Canonical20dGroupNormalizedShadowContract.scoringVersion,
        registryVersion:
            Canonical20dGroupNormalizedShadowContract.registryVersion,
        policyVersion: Canonical20dGroupNormalizedShadowContract.policyVersion,
        policyStatus: Canonical20dGroupNormalizedShadowContract.policyStatus,
        weightsFrozen:
            Canonical20dGroupNormalizedShadowContract.weightsFrozen,
        provisional: Canonical20dGroupNormalizedShadowContract.provisional,
        shadowOnly: Canonical20dGroupNormalizedShadowContract.shadowOnly,
      );
    }

    final weightSum = availableModules.fold<double>(
      0.0,
      (s, m) => s + m.configuredWeight,
    );

    var combinedSq = 0.0;
    Canonical20dGroupModuleDistance withEffective(
      Canonical20dGroupModuleDistance m,
    ) {
      if (!m.available || weightSum <= 0) {
        return m;
      }
      final effective = m.configuredWeight / weightSum;
      combinedSq += effective * m.distanceSquared!;
      return Canonical20dGroupModuleDistance(
        moduleId: m.moduleId,
        available: m.available,
        distanceSquared: m.distanceSquared,
        distance: m.distance,
        comparableDimensionCount: m.comparableDimensionCount,
        registryDimensionCount: m.registryDimensionCount,
        coverage: m.coverage,
        configuredWeight: m.configuredWeight,
        effectiveWeight: effective,
      );
    }

    final iqOut = withEffective(iq);
    final eqOut = withEffective(eq);
    final freqOut = withEffective(frequency);

    return Canonical20dGroupNormalizedShadowResult(
      available: true,
      iq: iqOut,
      eq: eqOut,
      frequency: freqOut,
      combinedDistanceSquared: combinedSq,
      combinedDistance: math.sqrt(combinedSq),
      totalComparableDimensionCount: totalComparable,
      totalRegistryDimensionCount: totalRegistry,
      totalCoverage: totalCoverage,
      scoringVersion: Canonical20dGroupNormalizedShadowContract.scoringVersion,
      registryVersion: Canonical20dGroupNormalizedShadowContract.registryVersion,
      policyVersion: Canonical20dGroupNormalizedShadowContract.policyVersion,
      policyStatus: Canonical20dGroupNormalizedShadowContract.policyStatus,
      weightsFrozen: Canonical20dGroupNormalizedShadowContract.weightsFrozen,
      provisional: Canonical20dGroupNormalizedShadowContract.provisional,
      shadowOnly: Canonical20dGroupNormalizedShadowContract.shadowOnly,
    );
  }

  Canonical20dGroupModuleDistance _moduleDistance({
    required String moduleId,
    required List<String> dimensionIds,
    required double configuredWeight,
    required Canonical20dShadowSubject a,
    required Canonical20dShadowSubject b,
  }) {
    var sumSq = 0.0;
    var n = 0;
    for (final id in dimensionIds) {
      final muA = _validMeasuredScore(a.measuredScores[id]);
      final muB = _validMeasuredScore(b.measuredScores[id]);
      if (muA == null || muB == null) continue;
      final delta = muA - muB;
      sumSq += delta * delta;
      n++;
    }

    final registryCount = dimensionIds.length;
    final coverage = registryCount == 0 ? 0.0 : n / registryCount;
    if (n == 0) {
      return Canonical20dGroupModuleDistance(
        moduleId: moduleId,
        available: false,
        distanceSquared: null,
        distance: null,
        comparableDimensionCount: 0,
        registryDimensionCount: registryCount,
        coverage: 0.0,
        configuredWeight: configuredWeight,
        effectiveWeight: 0.0,
      );
    }

    final d2 = sumSq / n;
    return Canonical20dGroupModuleDistance(
      moduleId: moduleId,
      available: true,
      distanceSquared: d2,
      distance: math.sqrt(d2),
      comparableDimensionCount: n,
      registryDimensionCount: registryCount,
      coverage: coverage,
      configuredWeight: configuredWeight,
      effectiveWeight: 0.0, // filled after renormalization
    );
  }

  static double? _validMeasuredScore(double? raw) {
    if (raw == null) return null;
    if (!raw.isFinite) return null;
    if (raw < 0.0 || raw > 1.0) return null;
    return raw;
  }
}
