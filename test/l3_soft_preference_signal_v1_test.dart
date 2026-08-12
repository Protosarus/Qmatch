import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/l3_soft_preference_signal.dart';

void main() {
  const matcher = L3SoftPreferenceSignalMatcher();

  group('l3_age_preference_soft_v1', () {
    test('mutual fit — normal reciprocal', () {
      final r = matcher.compareAge(
        ageA: 30,
        ageB: 28,
        ageRangeA: const [25, 35],
        ageRangeB: const [27, 40],
      );
      expect(r.available, isTrue);
      expect(r.aAcceptsB, isTrue);
      expect(r.bAcceptsA, isTrue);
      expect(r.mutualFit, isTrue);
      expect(r.toWireMap()['scoring_version'], 'l3_age_preference_soft_v1');
      expect(r.toWireMap()['is_l1_eligibility_gate'], isFalse);
    });

    test('boundary inclusive min==max', () {
      final r = matcher.compareAge(
        ageA: 30,
        ageB: 30,
        ageRangeA: const [30, 30],
        ageRangeB: const [30, 30],
      );
      expect(r.available, isTrue);
      expect(r.mutualFit, isTrue);

      final miss = matcher.compareAge(
        ageA: 30,
        ageB: 31,
        ageRangeA: const [30, 30],
        ageRangeB: const [30, 30],
      );
      expect(miss.available, isTrue);
      expect(miss.aAcceptsB, isFalse);
      expect(miss.bAcceptsA, isTrue);
      expect(miss.mutualFit, isFalse);
    });

    test('asymmetric one-way only', () {
      final r = matcher.compareAge(
        ageA: 40,
        ageB: 25,
        ageRangeA: const [20, 30], // A accepts B
        ageRangeB: const [20, 30], // B does not accept A=40
      );
      expect(r.available, isTrue);
      expect(r.aAcceptsB, isTrue);
      expect(r.bAcceptsA, isFalse);
      expect(r.mutualFit, isFalse);
    });

    test('missing age / range / partial / invalid', () {
      expect(
        matcher
            .compareAge(
              ageA: null,
              ageB: 28,
              ageRangeA: const [25, 35],
              ageRangeB: const [25, 35],
            )
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonMissingAgeA,
      );
      expect(
        matcher
            .compareAge(
              ageA: 28,
              ageB: null,
              ageRangeA: const [25, 35],
              ageRangeB: const [25, 35],
            )
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonMissingAgeB,
      );
      expect(
        matcher
            .compareAge(
              ageA: 28,
              ageB: 30,
              ageRangeA: const [25, 35],
              ageRangeB: null,
            )
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonPartialAgePreference,
      );
      expect(
        matcher
            .compareAge(
              ageA: 28,
              ageB: 30,
              ageRangeA: const [35, 25],
              ageRangeB: const [25, 35],
            )
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonInvalidAgeRangeA,
      );
      expect(
        matcher
            .compareAge(
              ageA: 28,
              ageB: 30,
              ageRangeA: const [17, 40],
              ageRangeB: const [25, 35],
            )
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonInvalidAgeRangeA,
      );
    });
  });

  group('l3_distance_preference_soft_v1', () {
    // ~ Istanbul approximate points ~11 km apart
    const a = L3LatLng(latitude: 41.0082, longitude: 28.9784);
    const bNear = L3LatLng(latitude: 41.06, longitude: 29.01);
    const bFar = L3LatLng(latitude: 41.5, longitude: 29.5);

    test('within mutual cap — normal', () {
      final r = matcher.compareDistance(
        locationA: a,
        locationB: bNear,
        distancePreferenceAKm: 50,
        distancePreferenceBKm: 30,
      );
      expect(r.available, isTrue);
      expect(r.distanceKm, greaterThan(0));
      expect(r.mutualCapKm, 30);
      expect(r.withinMutualCap, isTrue);
      expect(r.withinACap, isTrue);
      expect(r.withinBCap, isTrue);
    });

    test('boundary: distance exactly at mutual cap counts within', () {
      // Construct B at known distance using haversine inverse approx:
      // use matcher distance then set cap equal.
      final d = L3SoftPreferenceSignalMatcher.haversineKm(a, bNear);
      final cap = d.ceil();
      final r = matcher.compareDistance(
        locationA: a,
        locationB: bNear,
        distancePreferenceAKm: cap.clamp(5, 100),
        distancePreferenceBKm: cap.clamp(5, 100),
      );
      expect(r.available, isTrue);
      expect(r.withinMutualCap, isTrue);
    });

    test('asymmetric caps — mutual uses min', () {
      final r = matcher.compareDistance(
        locationA: a,
        locationB: bFar,
        distancePreferenceAKm: 100,
        distancePreferenceBKm: 5,
      );
      expect(r.available, isTrue);
      expect(r.mutualCapKm, 5);
      expect(r.withinBCap, isFalse);
      expect(r.withinMutualCap, isFalse);
      // May or may not be within A's 100km depending on bFar.
      expect(r.distanceKm!, greaterThan(5));
    });

    test('same point distance 0', () {
      final r = matcher.compareDistance(
        locationA: a,
        locationB: a,
        distancePreferenceAKm: 5,
        distancePreferenceBKm: 5,
      );
      expect(r.available, isTrue);
      expect(r.distanceKm, closeTo(0.0, 1e-9));
      expect(r.withinMutualCap, isTrue);
    });

    test('missing / invalid / partial', () {
      expect(
        matcher
            .compareDistance(
              locationA: null,
              locationB: bNear,
              distancePreferenceAKm: 20,
              distancePreferenceBKm: 20,
            )
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonMissingLocationA,
      );
      expect(
        matcher
            .compareDistance(
              locationA: a,
              locationB: bNear,
              distancePreferenceAKm: 20,
              distancePreferenceBKm: null,
            )
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonPartialGeoOrPreference,
      );
      expect(
        matcher
            .compareDistance(
              locationA: a,
              locationB: bNear,
              distancePreferenceAKm: 4,
              distancePreferenceBKm: 20,
            )
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonInvalidDistancePreferenceA,
      );
      expect(
        matcher
            .compareDistance(
              locationA: const L3LatLng(latitude: 100, longitude: 0),
              locationB: bNear,
              distancePreferenceAKm: 20,
              distancePreferenceBKm: 20,
            )
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonInvalidLocationA,
      );
    });

    test('haversine roughly matches known short baseline', () {
      // 1 degree lat ≈ 111.2 km
      const p0 = L3LatLng(latitude: 0, longitude: 0);
      const p1 = L3LatLng(latitude: 1, longitude: 0);
      final d = L3SoftPreferenceSignalMatcher.haversineKm(p0, p1);
      expect(d, closeTo(111.2, 1.0));
    });
  });

  group('l3_interests_overlap_soft_v1', () {
    test('normal overlap Jaccard', () {
      final r = matcher.compareInterests(
        interestsA: const ['Music', 'Travel', 'Coding'],
        interestsB: const ['music', 'Hiking'],
      );
      expect(r.available, isTrue);
      expect(r.overlapCount, 1);
      expect(r.unionCount, 4);
      expect(r.jaccard, closeTo(0.25, 1e-12));
    });

    test('zero overlap nonempty', () {
      final r = matcher.compareInterests(
        interestsA: const ['a', 'b'],
        interestsB: const ['c', 'd'],
      );
      expect(r.available, isTrue);
      expect(r.jaccard, 0.0);
      expect(r.overlapCount, 0);
    });

    test('identical sets → 1', () {
      final r = matcher.compareInterests(
        interestsA: const ['x', 'y'],
        interestsB: const ['Y', 'x', 'y'],
      );
      expect(r.available, isTrue);
      expect(r.jaccard, 1.0);
    });

    test('empty union / missing', () {
      expect(
        matcher
            .compareInterests(interestsA: const [], interestsB: const ['  '])
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonEmptyUnion,
      );
      expect(
        matcher
            .compareInterests(interestsA: null, interestsB: const ['a'])
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonMissingInterestsA,
      );
      expect(
        matcher
            .compareInterests(interestsA: const ['a'], interestsB: null)
            .unavailableReason,
        L3SoftPreferenceSignalContract.reasonMissingInterestsB,
      );
    });
  });

  group('contract isolation', () {
    test('no Discover ranking / looking_for / combined score', () {
      expect(L3SoftPreferenceSignalContract.lookingForActive, isFalse);
      expect(L3SoftPreferenceSignalContract.combinedScoreAllowed, isFalse);
      expect(L3SoftPreferenceSignalContract.weightsAllowed, isFalse);
      expect(L3SoftPreferenceSignalContract.affectsDiscoverRanking, isFalse);
      expect(L3SoftPreferenceSignalContract.isL1EligibilityGate, isFalse);

      final matcherSrc = File(
        'lib/features/matching/domain/l3_soft_preference_signal_matcher.dart',
      ).readAsStringSync();
      expect(matcherSrc.contains('features/discover'), isFalse);
      expect(matcherSrc.contains('DiscoverService'), isFalse);
      expect(matcherSrc.contains('interested_in'), isFalse);
      // looking_for must remain inactive: no evaluator API for it
      expect(matcherSrc.contains('compareLookingFor'), isFalse);
      expect(matcherSrc.contains('lookingFor'), isFalse);
    });
  });
}
