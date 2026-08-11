import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/canonical_20d_shadow_distance.dart';

void main() {
  const matcher = Canonical20dShadowDistanceMatcher();
  final ids = Canonical20dShadowDistanceContract.dimensionIds;

  Canonical20dShadowSubject subject(
    Map<String, double> scores, {
    Map<String, int>? evidence,
  }) {
    return Canonical20dShadowSubject(
      measuredScores: scores,
      evidenceCounts: evidence ??
          {
            for (final e in scores.entries)
              if (e.value.isFinite) e.key: 3,
          },
    );
  }

  Map<String, double> full(double v) => {
        for (final id in ids) id: v,
      };

  Map<String, double> patterned(double Function(int i) at) {
    final out = <String, double>{};
    for (var i = 0; i < ids.length; i++) {
      out[ids[i]] = at(i).clamp(0.0, 1.0);
    }
    return out;
  }

  group('Canonical20dShadowDistanceMatcher', () {
    test('identical 20D profiles → distance 0, full coverage', () {
      final a = subject(full(0.42));
      final b = subject(full(0.42));
      final r = matcher.compare(a: a, b: b);

      expect(r.available, isTrue);
      expect(r.distanceSquared, 0.0);
      expect(r.distance, 0.0);
      expect(r.comparableDimensionCount, 20);
      expect(r.unweightedCoverage, 1.0);
      expect(r.excludedDimensionIds, isEmpty);
      expect(r.shadowOnly, isTrue);
      expect(
        r.scoringVersion,
        Canonical20dShadowDistanceContract.scoringVersion,
      );
    });

    test('clearly different profiles → positive distance', () {
      final a = subject(full(0.0));
      final b = subject(full(1.0));
      final r = matcher.compare(a: a, b: b);

      expect(r.available, isTrue);
      expect(r.distanceSquared, closeTo(1.0, 1e-12));
      expect(r.distance, closeTo(1.0, 1e-12));
      expect(r.comparableDimensionCount, 20);
      expect(r.unweightedCoverage, 1.0);

      // Patterned profiles: mean squared of 0.1 steps.
      final p = subject(patterned((i) => i / 19.0));
      final q = subject(patterned((i) => 1.0 - i / 19.0));
      final r2 = matcher.compare(a: p, b: q);
      expect(r2.available, isTrue);
      expect(r2.distance!, greaterThan(0.5));
      expect(r2.distanceSquared!, lessThanOrEqualTo(1.0));
    });

    test('partial evidence compares only shared measured+evidence dims', () {
      final shared = ids.take(8).toList();
      final onlyA = ids.skip(8).take(4).toList();
      final scoresA = <String, double>{
        for (final id in shared) id: 0.2,
        for (final id in onlyA) id: 0.9,
      };
      final scoresB = <String, double>{
        for (final id in shared) id: 0.7,
      };
      final r = matcher.compare(
        a: subject(scoresA),
        b: subject(scoresB),
      );

      expect(r.available, isTrue);
      expect(r.comparableDimensionCount, 8);
      expect(r.comparableDimensionIds, shared);
      expect(r.unweightedCoverage, closeTo(8 / 20, 1e-12));
      // mean((0.2-0.7)^2) = 0.25 → d = 0.5
      expect(r.distanceSquared, closeTo(0.25, 1e-12));
      expect(r.distance, closeTo(0.5, 1e-12));
      expect(r.excludedDimensionIds, hasLength(12));
    });

    test('incomplete / no shared evidence → unavailable, no invented distance',
        () {
      final empty = matcher.compare(
        a: subject(const {}),
        b: subject(const {}),
      );
      expect(empty.available, isFalse);
      expect(empty.distance, isNull);
      expect(empty.distanceSquared, isNull);
      expect(empty.comparableDimensionCount, 0);
      expect(empty.unweightedCoverage, 0.0);
      expect(empty.excludedDimensionIds, hasLength(20));

      // Scores present but zero evidence on both → not comparable.
      final noEvidence = matcher.compare(
        a: Canonical20dShadowSubject(
          measuredScores: full(0.3),
          evidenceCounts: {for (final id in ids) id: 0},
        ),
        b: Canonical20dShadowSubject(
          measuredScores: full(0.8),
          evidenceCounts: {for (final id in ids) id: 0},
        ),
      );
      expect(noEvidence.available, isFalse);
      expect(noEvidence.distance, isNull);

      // Disjoint measured sets → no shared evidence.
      final left = subject({ids[0]: 0.1, ids[1]: 0.2});
      final right = subject({ids[2]: 0.9, ids[3]: 0.8});
      final disjoint = matcher.compare(a: left, b: right);
      expect(disjoint.available, isFalse);
      expect(disjoint.distance, isNull);
      expect(disjoint.comparableDimensionCount, 0);
    });

    test('symmetry A↔B', () {
      final a = subject(patterned((i) => (i % 5) / 4.0));
      final b = subject(patterned((i) => ((i + 2) % 7) / 6.0));
      final ab = matcher.compare(a: a, b: b);
      final ba = matcher.compare(a: b, b: a);

      expect(ab.available, ba.available);
      expect(ab.distanceSquared, ba.distanceSquared);
      expect(ab.distance, ba.distance);
      expect(ab.comparableDimensionCount, ba.comparableDimensionCount);
      expect(ab.comparableDimensionIds, ba.comparableDimensionIds);
      expect(ab.unweightedCoverage, ba.unweightedCoverage);
    });

    test('never imputes missing dims as 0 / 0.5 / 50', () {
      final a = subject({ids[0]: 1.0});
      final b = subject({ids[0]: 0.0, ids[1]: 0.5});
      final r = matcher.compare(a: a, b: b);
      // Only ids[0] shared — would be wrong if missing id treated as 0 vs 0.5.
      expect(r.comparableDimensionCount, 1);
      expect(r.distanceSquared, closeTo(1.0, 1e-12));
      expect(r.comparableDimensionIds, [ids[0]]);
    });

    test('rejects out-of-range scores; equal-weight RMSE formula check', () {
      final a = subject({
        ids[0]: 0.0,
        ids[1]: 0.0,
        ids[2]: 2.0, // invalid → excluded
      });
      final b = subject({
        ids[0]: 1.0,
        ids[1]: 0.0,
        ids[2]: 1.0,
      });
      final r = matcher.compare(a: a, b: b);
      expect(r.comparableDimensionCount, 2);
      // mean(1^2 + 0^2) = 0.5 → d = sqrt(0.5)
      expect(r.distanceSquared, closeTo(0.5, 1e-12));
      expect(r.distance, closeTo(math.sqrt(0.5), 1e-12));
    });
  });

  group('isolation', () {
    test('matcher source has no Discover/RBF/quantum/RVI coupling', () {
      final src = File(
        'lib/features/matching/domain/canonical_20d_shadow_distance_matcher.dart',
      ).readAsStringSync();
      expect(src.contains('persona_scoring'), isFalse);
      expect(src.contains('PersonaScoring'), isFalse);
      expect(src.contains('primary_persona_id'), isFalse);
      expect(src.contains('DiscoverService'), isFalse);
      expect(src.contains('CompatibilityScoring'), isFalse);
      expect(src.contains('exp('), isFalse);
      expect(src.toLowerCase().contains('gaussian'), isFalse);
      expect(src.toLowerCase().contains('rbf'), isFalse);
      expect(src.toLowerCase().contains('quantum'), isFalse);
      expect(src.toLowerCase().contains('rvi'), isFalse);
      expect(src.contains('archetype'), isFalse);
      expect(src.contains('missingSignalNeutral'), isFalse);
    });

    test('Discover service does not import shadow matcher', () {
      final discover = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(
        discover.contains('canonical_20d_shadow_distance'),
        isFalse,
      );
    });

    test('registry is exactly 4+10+6 canonical ids', () {
      expect(ids, hasLength(20));
      expect(
        ids.toSet(),
        {
          'logical_reasoning',
          'pattern_reasoning',
          'verbal_reasoning',
          'spatial_reasoning',
          'empathy',
          'perspective_taking',
          'self_awareness',
          'emotion_regulation',
          'emotional_openness',
          'boundary_setting',
          'assertiveness',
          'conflict_approach',
          'repair_orientation',
          'social_awareness',
          'depth_preference',
          'social_energy',
          'spontaneity',
          'stability',
          'disclosure_pace',
          'communication_pace',
        },
      );
    });
  });
}
