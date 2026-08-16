import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/canonical_20d_group_normalized_shadow.dart';

void main() {
  const matcher = Canonical20dGroupNormalizedShadowMatcher();
  const equalMatcher = Canonical20dShadowDistanceMatcher();
  final iq = Canonical20dGroupNormalizedShadowContract.iqDimensionIds;
  final eq = Canonical20dGroupNormalizedShadowContract.eqDimensionIds;
  final freq =
      Canonical20dGroupNormalizedShadowContract.frequencyDimensionIds;
  final all = [...iq, ...eq, ...freq];

  Canonical20dShadowSubject subject(Map<String, double> scores) {
    return Canonical20dShadowSubject(
      measuredScores: scores,
      evidenceCounts: const {},
    );
  }

  Map<String, double> fill(
    Iterable<String> ids,
    double v, {
    Map<String, double> extra = const {},
  }) =>
      {
        for (final id in ids) id: v,
        ...extra,
      };

  group('Canonical20dGroupNormalizedShadowMatcher', () {
    test('identical profiles → combined distance 0, full coverage', () {
      final a = subject(fill(all, 0.42));
      final b = subject(fill(all, 0.42));
      final r = matcher.compareMeasuredPresence(a: a, b: b);

      expect(r.available, isTrue);
      expect(r.combinedDistance, 0.0);
      expect(r.combinedDistanceSquared, 0.0);
      expect(r.iq.distance, 0.0);
      expect(r.eq.distance, 0.0);
      expect(r.frequency.distance, 0.0);
      expect(r.totalComparableDimensionCount, 20);
      expect(r.totalCoverage, 1.0);
      expect(r.provisional, isFalse);
      expect(r.shadowOnly, isTrue);
      expect(r.weightsFrozen, isTrue);
      expect(
        r.policyStatus,
        Canonical20dGroupNormalizedShadowContract.policyStatus,
      );
      expect(
        r.policyStatus,
        'production_candidate_not_live',
      );
      expect(
        r.policyVersion,
        Canonical20dGroupNormalizedShadowContract.policyVersion,
      );
      expect(
        r.scoringVersion,
        Canonical20dGroupNormalizedShadowContract.scoringVersion,
      );
      expect(
        r.iq.effectiveWeight + r.eq.effectiveWeight + r.frequency.effectiveWeight,
        closeTo(1.0, 1e-9),
      );
    });

    test('Frequency-dominant disagreement weighs Frequency more than equal-20D',
        () {
      final me = subject({
        ...fill(iq, 0.5),
        ...fill(eq, 0.5),
        ...fill(freq, 0.1),
      });
      final other = subject({
        ...fill(iq, 0.5),
        ...fill(eq, 0.5),
        ...fill(freq, 0.9),
      });

      final group = matcher.compareMeasuredPresence(a: me, b: other);
      final equal = equalMatcher.compareMeasuredPresence(a: me, b: other);

      expect(group.iq.distanceSquared, 0.0);
      expect(group.eq.distanceSquared, 0.0);
      expect(group.frequency.distanceSquared, closeTo(0.64, 1e-12));
      // Only Frequency contributes → effective weight 1.0 after renorm? 
      // All three available; combined = 0.466667 * 0.64
      expect(
        group.combinedDistanceSquared,
        closeTo(
          Canonical20dGroupNormalizedShadowContract.frequencyWeight * 0.64,
          1e-9,
        ),
      );
      // Equal-20D: 6/20 * 0.64 = 0.192
      expect(equal.distanceSquared, closeTo(0.192, 1e-12));
      expect(
        group.combinedDistanceSquared!,
        greaterThan(equal.distanceSquared!),
      );
    });

    test('EQ-dominant disagreement applies EQ module weight (below equal-20D)',
        () {
      // Provisional EQ weight 0.40 < equal-20D implicit EQ share 10/20=0.50.
      final me = subject({
        ...fill(iq, 0.5),
        ...fill(eq, 0.1),
        ...fill(freq, 0.5),
      });
      final other = subject({
        ...fill(iq, 0.5),
        ...fill(eq, 0.9),
        ...fill(freq, 0.5),
      });

      final group = matcher.compareMeasuredPresence(a: me, b: other);
      final equal = equalMatcher.compareMeasuredPresence(a: me, b: other);

      expect(group.eq.distanceSquared, closeTo(0.64, 1e-12));
      expect(group.iq.distanceSquared, 0.0);
      expect(group.frequency.distanceSquared, 0.0);
      expect(
        group.combinedDistanceSquared,
        closeTo(
          Canonical20dGroupNormalizedShadowContract.eqWeight * 0.64,
          1e-9,
        ),
      );
      // Equal-20D: 10/20 * 0.64 = 0.32 — group-normalized is lower.
      expect(equal.distanceSquared, closeTo(0.32, 1e-12));
      expect(
        group.combinedDistanceSquared!,
        lessThan(equal.distanceSquared!),
      );
    });

    test('missing module omits and renormalizes remaining weights', () {
      // No Frequency overlap — Frequency omitted.
      final me = subject({
        ...fill(iq, 0.2),
        ...fill(eq, 0.2),
        for (final id in freq.take(3)) id: 0.2,
      });
      final other = subject({
        ...fill(iq, 0.8),
        ...fill(eq, 0.8),
        for (final id in freq.skip(3)) id: 0.8,
      });

      final r = matcher.compareMeasuredPresence(a: me, b: other);
      expect(r.frequency.available, isFalse);
      expect(r.frequency.effectiveWeight, 0.0);
      expect(r.iq.available, isTrue);
      expect(r.eq.available, isTrue);

      final wIq = Canonical20dGroupNormalizedShadowContract.iqWeight;
      final wEq = Canonical20dGroupNormalizedShadowContract.eqWeight;
      final sum = wIq + wEq;
      expect(r.iq.effectiveWeight, closeTo(wIq / sum, 1e-12));
      expect(r.eq.effectiveWeight, closeTo(wEq / sum, 1e-12));
      expect(
        r.iq.effectiveWeight + r.eq.effectiveWeight,
        closeTo(1.0, 1e-12),
      );

      // Module d² = (0.2-0.8)^2 = 0.36
      expect(r.iq.distanceSquared, closeTo(0.36, 1e-12));
      expect(r.eq.distanceSquared, closeTo(0.36, 1e-12));
      expect(
        r.combinedDistanceSquared,
        closeTo(0.36, 1e-12),
      );
      expect(r.combinedDistance, closeTo(math.sqrt(0.36), 1e-12));
    });

    test('symmetry A↔B', () {
      final a = subject({
        for (var i = 0; i < all.length; i++)
          all[i]: (i % 5) / 4.0,
      });
      final b = subject({
        for (var i = 0; i < all.length; i++)
          all[i]: ((i + 3) % 7) / 6.0,
      });
      final ab = matcher.compareMeasuredPresence(a: a, b: b);
      final ba = matcher.compareMeasuredPresence(a: b, b: a);

      expect(ab.combinedDistanceSquared, ba.combinedDistanceSquared);
      expect(ab.combinedDistance, ba.combinedDistance);
      expect(ab.iq.distanceSquared, ba.iq.distanceSquared);
      expect(ab.eq.distanceSquared, ba.eq.distanceSquared);
      expect(ab.frequency.distanceSquared, ba.frequency.distanceSquared);
      expect(ab.totalCoverage, ba.totalCoverage);
    });

    test('frozen production-candidate policy weights and status', () {
      final w = Canonical20dGroupNormalizedShadowContract.moduleWeights;
      expect(
        w['iq']! + w['eq']! + w['frequency']!,
        closeTo(1.0, 1e-9),
      );
      expect(w['iq'], 0.133333);
      expect(w['eq'], 0.400000);
      expect(w['frequency'], 0.466667);
      expect(
        Canonical20dGroupNormalizedShadowContract.policyStatus,
        'production_candidate_not_live',
      );
      expect(Canonical20dGroupNormalizedShadowContract.weightsFrozen, isTrue);
      expect(Canonical20dGroupNormalizedShadowContract.shadowOnly, isTrue);
      expect(
        Canonical20dGroupNormalizedShadowContract.liveDiscoverRanking,
        isFalse,
      );
      expect(Canonical20dGroupNormalizedShadowContract.provisional, isFalse);
    });
  });

  group('isolation', () {
    test('keeps equal-20D matcher intact; no Discover/Persona coupling', () {
      final groupSrc = File(
        'lib/features/matching/domain/'
        'canonical_20d_group_normalized_shadow_matcher.dart',
      ).readAsStringSync();
      expect(groupSrc.contains('DiscoverService'), isFalse);
      expect(groupSrc.contains('persona_scoring'), isFalse);
      expect(groupSrc.contains('CompatibilityScoring'), isFalse);
      expect(groupSrc.contains('exp('), isFalse);

      final equalContract = File(
        'lib/features/matching/domain/'
        'canonical_20d_shadow_distance_contract.dart',
      ).readAsStringSync();
      expect(
        equalContract.contains('canonical_20d_shadow_distance_v1'),
        isTrue,
      );
      expect(equalContract.contains('baseline only'), isTrue);

      final policy = File(
        'docs/matching/'
        'qmatch_structural_matching_production_candidate_policy_v1.md',
      ).readAsStringSync();
      expect(policy.contains('production_candidate_not_live'), isTrue);
      expect(policy.contains('0.133333'), isTrue);
      expect(policy.contains('0.400000'), isTrue);
      expect(policy.contains('0.466667'), isTrue);
      expect(policy.contains('Baseline only'), isTrue);
      expect(policy.contains('structural_l2_v1'), isTrue);
      expect(policy.contains('compareStageB2Structural'), isTrue);
      expect(policy.contains('Rollback only'), isTrue);
      expect(policy.contains('legacy_v1'), isTrue);
      expect(
        policy.contains('does **not** rank Discover'),
        isTrue,
      );
      expect(policy.toLowerCase().contains('persona'), isTrue);
      expect(policy.toLowerCase().contains('quantum'), isTrue);
      expect(policy.toLowerCase().contains('rvi'), isTrue);

      final equalSrc = File(
        'lib/features/matching/domain/canonical_20d_shadow_distance_matcher.dart',
      ).readAsStringSync();
      expect(equalSrc.contains('group_normalized'), isFalse);

      final discover = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(discover.contains('group_normalized'), isFalse);
    });
  });
}
