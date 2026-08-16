import 'l3_soft_preference_signal_contract.dart';

/// WGS84 coordinate pair for distance soft signal (no Firestore dependency).
class L3LatLng {
  const L3LatLng({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class L3AgePreferenceSoftResult {
  const L3AgePreferenceSoftResult({
    required this.available,
    required this.unavailableReason,
    required this.aAcceptsB,
    required this.bAcceptsA,
    required this.mutualFit,
    required this.ageA,
    required this.ageB,
    required this.rangeA,
    required this.rangeB,
  });

  final bool available;
  final String? unavailableReason;
  final bool? aAcceptsB;
  final bool? bAcceptsA;
  final bool? mutualFit;
  final int? ageA;
  final int? ageB;
  final List<int>? rangeA;
  final List<int>? rangeB;

  /// Frozen diagnostic taxonomy: mutual fit vs known mismatch vs unknown.
  /// Not a ranking key.
  String get diagnosticClass {
    if (!available) {
      return L3SoftPreferenceSignalContract.ageDiagnosticUnknown;
    }
    if (mutualFit == true) {
      return L3SoftPreferenceSignalContract.ageDiagnosticMutualFit;
    }
    return L3SoftPreferenceSignalContract.ageDiagnosticKnownMismatch;
  }

  Map<String, dynamic> toWireMap() => {
        'scoring_version': L3SoftPreferenceSignalContract.ageScoringVersion,
        'policy_version': L3SoftPreferenceSignalContract.policyVersion,
        'policy_status': L3SoftPreferenceSignalContract.policyStatus,
        'shadow_only': L3SoftPreferenceSignalContract.shadowOnly,
        'affects_discover_ranking':
            L3SoftPreferenceSignalContract.affectsDiscoverRanking,
        'is_l1_eligibility_gate':
            L3SoftPreferenceSignalContract.isL1EligibilityGate,
        'production_promoted':
            L3SoftPreferenceSignalContract.ageProductionPromoted,
        'available': available,
        'diagnostic_class': diagnosticClass,
        if (unavailableReason != null) 'unavailable_reason': unavailableReason,
        if (aAcceptsB != null) 'a_accepts_b': aAcceptsB,
        if (bAcceptsA != null) 'b_accepts_a': bAcceptsA,
        if (mutualFit != null) 'mutual_fit': mutualFit,
        if (ageA != null) 'age_a': ageA,
        if (ageB != null) 'age_b': ageB,
        if (rangeA != null) 'range_a': rangeA,
        if (rangeB != null) 'range_b': rangeB,
      };
}

class L3DistancePreferenceSoftResult {
  const L3DistancePreferenceSoftResult({
    required this.available,
    required this.unavailableReason,
    required this.distanceKm,
    required this.capAKm,
    required this.capBKm,
    required this.mutualCapKm,
    required this.withinACap,
    required this.withinBCap,
    required this.withinMutualCap,
  });

  final bool available;
  final String? unavailableReason;
  final double? distanceKm;
  final int? capAKm;
  final int? capBKm;
  final int? mutualCapKm;
  final bool? withinACap;
  final bool? withinBCap;
  final bool? withinMutualCap;

  Map<String, dynamic> toWireMap() => {
        'scoring_version':
            L3SoftPreferenceSignalContract.distanceScoringVersion,
        'policy_version': L3SoftPreferenceSignalContract.policyVersion,
        'policy_status': L3SoftPreferenceSignalContract.policyStatus,
        'shadow_only': L3SoftPreferenceSignalContract.shadowOnly,
        'affects_discover_ranking':
            L3SoftPreferenceSignalContract.affectsDiscoverRanking,
        'is_l1_eligibility_gate':
            L3SoftPreferenceSignalContract.isL1EligibilityGate,
        'production_promoted':
            L3SoftPreferenceSignalContract.distanceProductionPromoted,
        'available': available,
        if (unavailableReason != null) 'unavailable_reason': unavailableReason,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (capAKm != null) 'cap_a_km': capAKm,
        if (capBKm != null) 'cap_b_km': capBKm,
        if (mutualCapKm != null) 'mutual_cap_km': mutualCapKm,
        if (withinACap != null) 'within_a_cap': withinACap,
        if (withinBCap != null) 'within_b_cap': withinBCap,
        if (withinMutualCap != null) 'within_mutual_cap': withinMutualCap,
      };
}

class L3InterestsOverlapSoftResult {
  const L3InterestsOverlapSoftResult({
    required this.available,
    required this.unavailableReason,
    required this.overlapCount,
    required this.unionCount,
    required this.jaccard,
  });

  final bool available;
  final String? unavailableReason;
  final int? overlapCount;
  final int? unionCount;
  final double? jaccard;

  Map<String, dynamic> toWireMap() => {
        'scoring_version':
            L3SoftPreferenceSignalContract.interestsScoringVersion,
        'policy_version': L3SoftPreferenceSignalContract.policyVersion,
        'policy_status': L3SoftPreferenceSignalContract.policyStatus,
        'shadow_only': L3SoftPreferenceSignalContract.shadowOnly,
        'affects_discover_ranking':
            L3SoftPreferenceSignalContract.affectsDiscoverRanking,
        'is_l1_eligibility_gate':
            L3SoftPreferenceSignalContract.isL1EligibilityGate,
        'production_promoted':
            L3SoftPreferenceSignalContract.interestsProductionPromoted,
        'available': available,
        if (unavailableReason != null) 'unavailable_reason': unavailableReason,
        if (overlapCount != null) 'overlap_count': overlapCount,
        if (unionCount != null) 'union_count': unionCount,
        if (jaccard != null) 'jaccard': jaccard,
      };
}
