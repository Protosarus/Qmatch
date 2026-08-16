import 'dart:math' as math;

import 'l3_soft_preference_signal_contract.dart';
import 'l3_soft_preference_signal_models.dart';

/// L3 v1 profile soft-preference evaluators (separate signals, no fusion).
///
/// Production diagnostics for age + interests; distance is evaluated but not
/// production-promoted. Does **not** affect L1 eligibility or Discover ranking.
class L3SoftPreferenceSignalMatcher {
  const L3SoftPreferenceSignalMatcher();

  /// Reciprocal age preference soft signal.
  L3AgePreferenceSoftResult compareAge({
    required int? ageA,
    required int? ageB,
    required List<int>? ageRangeA,
    required List<int>? ageRangeB,
  }) {
    if (!_validAge(ageA)) {
      return _ageUnavailable(L3SoftPreferenceSignalContract.reasonMissingAgeA);
    }
    if (!_validAge(ageB)) {
      return _ageUnavailable(L3SoftPreferenceSignalContract.reasonMissingAgeB);
    }

    final rangeAPresent = ageRangeA != null;
    final rangeBPresent = ageRangeB != null;
    if (!rangeAPresent && !rangeBPresent) {
      return _ageUnavailable(
        L3SoftPreferenceSignalContract.reasonMissingAgeRangeA,
      );
    }
    if (rangeAPresent != rangeBPresent) {
      return _ageUnavailable(
        L3SoftPreferenceSignalContract.reasonPartialAgePreference,
      );
    }

    final parsedA = _parseAgeRange(ageRangeA!);
    if (parsedA == null) {
      return _ageUnavailable(
        L3SoftPreferenceSignalContract.reasonInvalidAgeRangeA,
      );
    }
    final parsedB = _parseAgeRange(ageRangeB!);
    if (parsedB == null) {
      return _ageUnavailable(
        L3SoftPreferenceSignalContract.reasonInvalidAgeRangeB,
      );
    }

    final aAcceptsB = _inRange(ageB!, parsedA);
    final bAcceptsA = _inRange(ageA!, parsedB);
    return L3AgePreferenceSoftResult(
      available: true,
      unavailableReason: null,
      aAcceptsB: aAcceptsB,
      bAcceptsA: bAcceptsA,
      mutualFit: aAcceptsB && bAcceptsA,
      ageA: ageA,
      ageB: ageB,
      rangeA: [parsedA.min, parsedA.max],
      rangeB: [parsedB.min, parsedB.max],
    );
  }

  /// Reciprocal distance preference soft signal (haversine km).
  L3DistancePreferenceSoftResult compareDistance({
    required L3LatLng? locationA,
    required L3LatLng? locationB,
    required int? distancePreferenceAKm,
    required int? distancePreferenceBKm,
  }) {
    if (locationA == null) {
      return _distanceUnavailable(
        L3SoftPreferenceSignalContract.reasonMissingLocationA,
      );
    }
    if (locationB == null) {
      return _distanceUnavailable(
        L3SoftPreferenceSignalContract.reasonMissingLocationB,
      );
    }
    if (!_validLatLng(locationA)) {
      return _distanceUnavailable(
        L3SoftPreferenceSignalContract.reasonInvalidLocationA,
      );
    }
    if (!_validLatLng(locationB)) {
      return _distanceUnavailable(
        L3SoftPreferenceSignalContract.reasonInvalidLocationB,
      );
    }

    final prefAPresent = distancePreferenceAKm != null;
    final prefBPresent = distancePreferenceBKm != null;
    if (!prefAPresent && !prefBPresent) {
      return _distanceUnavailable(
        L3SoftPreferenceSignalContract.reasonMissingDistancePreferenceA,
      );
    }
    if (prefAPresent != prefBPresent) {
      return _distanceUnavailable(
        L3SoftPreferenceSignalContract.reasonPartialGeoOrPreference,
      );
    }

    if (!_validDistancePref(distancePreferenceAKm!)) {
      return _distanceUnavailable(
        L3SoftPreferenceSignalContract.reasonInvalidDistancePreferenceA,
      );
    }
    if (!_validDistancePref(distancePreferenceBKm!)) {
      return _distanceUnavailable(
        L3SoftPreferenceSignalContract.reasonInvalidDistancePreferenceB,
      );
    }

    final d = haversineKm(locationA, locationB);
    final mutualCap = math.min(distancePreferenceAKm, distancePreferenceBKm);
    return L3DistancePreferenceSoftResult(
      available: true,
      unavailableReason: null,
      distanceKm: d,
      capAKm: distancePreferenceAKm,
      capBKm: distancePreferenceBKm,
      mutualCapKm: mutualCap,
      withinACap: d <= distancePreferenceAKm,
      withinBCap: d <= distancePreferenceBKm,
      withinMutualCap: d <= mutualCap,
    );
  }

  /// Symmetric interests Jaccard soft signal.
  L3InterestsOverlapSoftResult compareInterests({
    required List<String>? interestsA,
    required List<String>? interestsB,
  }) {
    if (interestsA == null) {
      return _interestsUnavailable(
        L3SoftPreferenceSignalContract.reasonMissingInterestsA,
      );
    }
    if (interestsB == null) {
      return _interestsUnavailable(
        L3SoftPreferenceSignalContract.reasonMissingInterestsB,
      );
    }

    final sa = _normalizeInterestSet(interestsA);
    final sb = _normalizeInterestSet(interestsB);
    final union = sa.union(sb);
    if (union.isEmpty) {
      return _interestsUnavailable(
        L3SoftPreferenceSignalContract.reasonEmptyUnion,
      );
    }
    final inter = sa.intersection(sb);
    return L3InterestsOverlapSoftResult(
      available: true,
      unavailableReason: null,
      overlapCount: inter.length,
      unionCount: union.length,
      jaccard: inter.length / union.length,
    );
  }

  /// Earth-mean-radius haversine distance in kilometers.
  static double haversineKm(L3LatLng a, L3LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusKm * c;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;

  static bool _validAge(int? age) =>
      age != null && age > 0 && age < 150;

  static bool _inRange(int age, ({int min, int max}) range) =>
      age >= range.min && age <= range.max;

  static ({int min, int max})? _parseAgeRange(List<int> raw) {
    if (raw.length != 2) return null;
    final min = raw[0];
    final max = raw[1];
    if (min > max) return null;
    if (min < L3SoftPreferenceSignalContract.ageRangeMinBound) return null;
    if (max > L3SoftPreferenceSignalContract.ageRangeMaxBound) return null;
    return (min: min, max: max);
  }

  static bool _validLatLng(L3LatLng p) {
    if (!p.latitude.isFinite || !p.longitude.isFinite) return false;
    if (p.latitude < -90 || p.latitude > 90) return false;
    if (p.longitude < -180 || p.longitude > 180) return false;
    return true;
  }

  static bool _validDistancePref(int km) =>
      km >= L3SoftPreferenceSignalContract.distancePrefMinKm &&
      km <= L3SoftPreferenceSignalContract.distancePrefMaxKm;

  static Set<String> _normalizeInterestSet(List<String> raw) => {
        for (final e in raw)
          if (e.trim().isNotEmpty) e.trim().toLowerCase(),
      };

  static L3AgePreferenceSoftResult _ageUnavailable(String reason) =>
      L3AgePreferenceSoftResult(
        available: false,
        unavailableReason: reason,
        aAcceptsB: null,
        bAcceptsA: null,
        mutualFit: null,
        ageA: null,
        ageB: null,
        rangeA: null,
        rangeB: null,
      );

  static L3DistancePreferenceSoftResult _distanceUnavailable(String reason) =>
      L3DistancePreferenceSoftResult(
        available: false,
        unavailableReason: reason,
        distanceKm: null,
        capAKm: null,
        capBKm: null,
        mutualCapKm: null,
        withinACap: null,
        withinBCap: null,
        withinMutualCap: null,
      );

  static L3InterestsOverlapSoftResult _interestsUnavailable(String reason) =>
      L3InterestsOverlapSoftResult(
        available: false,
        unavailableReason: reason,
        overlapCount: null,
        unionCount: null,
        jaccard: null,
      );
}
