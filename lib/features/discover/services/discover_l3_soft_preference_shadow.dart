import 'package:cloud_firestore/cloud_firestore.dart';

import '../../matching/domain/l3_soft_preference_signal.dart';
import '../models/discover_user_model.dart';

/// Parses L3 soft-preference inputs from a `users/{uid}` map.
///
/// **No imputation:** missing keys stay null (never invent age=18, age_range,
/// distance_preference, empty interests, or geo).
class DiscoverL3SoftPreferenceInputParser {
  const DiscoverL3SoftPreferenceInputParser();

  int? age(Map<String, dynamic> data) {
    final v = data['age'];
    if (v is num) return v.toInt();
    return null;
  }

  List<int>? ageRange(Map<String, dynamic> data) {
    if (!data.containsKey('age_range')) return null;
    final raw = data['age_range'];
    if (raw is! List) return const <int>[];
    final out = <int>[];
    for (final e in raw) {
      if (e is! num) return const <int>[];
      out.add(e.toInt());
    }
    return out;
  }

  L3LatLng? location(Map<String, dynamic> data) {
    if (!data.containsKey('location')) return null;
    final raw = data['location'];
    if (raw is GeoPoint) {
      return L3LatLng(latitude: raw.latitude, longitude: raw.longitude);
    }
    if (raw is Map) {
      final lat = raw['latitude'] ?? raw['lat'];
      final lng = raw['longitude'] ?? raw['lng'] ?? raw['lon'];
      if (lat is num && lng is num) {
        return L3LatLng(latitude: lat.toDouble(), longitude: lng.toDouble());
      }
    }
    return null;
  }

  int? distancePreferenceKm(Map<String, dynamic> data) {
    if (!data.containsKey('distance_preference')) return null;
    final v = data['distance_preference'];
    if (v is num) return v.toInt();
    return null;
  }

  /// Null when the `interests` key is absent (missing). Present empty list is
  /// empty — not imputed from absent.
  List<String>? interests(Map<String, dynamic> data) {
    if (!data.containsKey('interests')) return null;
    final raw = data['interests'];
    if (raw is! List) return null;
    return [
      for (final e in raw)
        if (e != null) e.toString(),
    ];
  }

}

/// Per-candidate L3 soft preference shadow diagnostic (in-memory / debug).
///
/// Separate signals only — never a combined L3 score or weights.
class DiscoverL3SoftPreferencePairDiagnostic {
  const DiscoverL3SoftPreferencePairDiagnostic({
    required this.candidateUid,
    required this.legacyRank,
    required this.age,
    required this.distance,
    required this.interests,
  });

  final String candidateUid;

  /// 1-based position in the **already ranked** Discover list.
  final int legacyRank;

  final L3AgePreferenceSoftResult age;
  final L3DistancePreferenceSoftResult distance;
  final L3InterestsOverlapSoftResult interests;

  Map<String, dynamic> toExportMap() => {
        'candidate_uid': candidateUid,
        'legacy_rank': legacyRank,
        'shadow_only': true,
        'affects_discover_ranking': false,
        'is_l1_eligibility_gate': false,
        'combined_l3_score': null,
        'looking_for_active': false,
        'l3_age_preference_soft_v1': age.toWireMap(),
        'l3_distance_preference_soft_v1': distance.toWireMap(),
        'l3_interests_overlap_soft_v1': interests.toWireMap(),
      };
}

/// Attaches L3 soft preference shadow diagnostics **after** legacy ranking.
///
/// Never reorders candidates and never touches live compatibility scores / L1.
class DiscoverL3SoftPreferenceShadowAttacher {
  const DiscoverL3SoftPreferenceShadowAttacher({
    L3SoftPreferenceSignalMatcher matcher =
        const L3SoftPreferenceSignalMatcher(),
    DiscoverL3SoftPreferenceInputParser parser =
        const DiscoverL3SoftPreferenceInputParser(),
  })  : _matcher = matcher,
        _parser = parser;

  final L3SoftPreferenceSignalMatcher _matcher;
  final DiscoverL3SoftPreferenceInputParser _parser;

  /// Returns ranked list unchanged + uid→L3 diagnostic map.
  ({
    List<DiscoverUserModel> candidates,
    Map<String, DiscoverL3SoftPreferencePairDiagnostic> diagnostics,
  }) attach({
    required Map<String, dynamic> meUserData,
    required List<DiscoverUserModel> rankedCandidates,
    required Map<String, Map<String, dynamic>> candidateUserData,
  }) {
    final diagnostics = <String, DiscoverL3SoftPreferencePairDiagnostic>{};

    final ageA = _parser.age(meUserData);
    final rangeA = _parser.ageRange(meUserData);
    final locA = _parser.location(meUserData);
    final distA = _parser.distancePreferenceKm(meUserData);
    final interestsA = _parser.interests(meUserData);

    for (var i = 0; i < rankedCandidates.length; i++) {
      final candidate = rankedCandidates[i];
      final data = candidateUserData[candidate.uid] ?? const <String, dynamic>{};

      final age = _matcher.compareAge(
        ageA: ageA,
        ageB: _parser.age(data),
        ageRangeA: rangeA,
        ageRangeB: _parser.ageRange(data),
      );
      final distance = _matcher.compareDistance(
        locationA: locA,
        locationB: _parser.location(data),
        distancePreferenceAKm: distA,
        distancePreferenceBKm: _parser.distancePreferenceKm(data),
      );
      final interests = _matcher.compareInterests(
        interestsA: interestsA,
        interestsB: _parser.interests(data),
      );

      diagnostics[candidate.uid] = DiscoverL3SoftPreferencePairDiagnostic(
        candidateUid: candidate.uid,
        legacyRank: i + 1,
        age: age,
        distance: distance,
        interests: interests,
      );
    }

    return (
      candidates: List<DiscoverUserModel>.unmodifiable(rankedCandidates),
      diagnostics: Map.unmodifiable(diagnostics),
    );
  }
}
