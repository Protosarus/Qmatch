/// L3 soft preference shadow signals v1 — separate evaluators, no fusion.
///
/// Spec: `qmatch_l3_soft_preference_signal_contract_v1`.
/// Never L1 eligibility. No combined score. No weights. `looking_for` inactive.
class L3SoftPreferenceSignalContract {
  L3SoftPreferenceSignalContract._();

  static const String policyVersion = 'l3_soft_preference_signal_contract_v1';
  static const String policyStatus = 'shadow_only_not_live';

  static const String ageScoringVersion = 'l3_age_preference_soft_v1';
  static const String distanceScoringVersion = 'l3_distance_preference_soft_v1';
  static const String interestsScoringVersion = 'l3_interests_overlap_soft_v1';

  static const bool shadowOnly = true;
  static const bool affectsDiscoverRanking = false;
  static const bool combinedScoreAllowed = false;
  static const bool weightsAllowed = false;
  static const bool lookingForActive = false;
  static const bool genderInferenceAllowed = false;
  static const bool imputationAllowed = false;
  static const bool isL1EligibilityGate = false;

  /// Setup UI band for age_range.
  static const int ageRangeMinBound = 18;
  static const int ageRangeMaxBound = 80;

  /// Setup UI band for distance_preference (km).
  static const int distancePrefMinKm = 5;
  static const int distancePrefMaxKm = 100;

  // --- Age reasons ---
  static const String reasonMissingAgeA = 'missing_age_a';
  static const String reasonMissingAgeB = 'missing_age_b';
  static const String reasonMissingAgeRangeA = 'missing_age_range_a';
  static const String reasonMissingAgeRangeB = 'missing_age_range_b';
  static const String reasonInvalidAgeRangeA = 'invalid_age_range_a';
  static const String reasonInvalidAgeRangeB = 'invalid_age_range_b';
  static const String reasonPartialAgePreference = 'partial_preference';

  // --- Distance reasons ---
  static const String reasonMissingLocationA = 'missing_location_a';
  static const String reasonMissingLocationB = 'missing_location_b';
  static const String reasonInvalidLocationA = 'invalid_location_a';
  static const String reasonInvalidLocationB = 'invalid_location_b';
  static const String reasonMissingDistancePreferenceA =
      'missing_distance_preference_a';
  static const String reasonMissingDistancePreferenceB =
      'missing_distance_preference_b';
  static const String reasonInvalidDistancePreferenceA =
      'invalid_distance_preference_a';
  static const String reasonInvalidDistancePreferenceB =
      'invalid_distance_preference_b';
  static const String reasonPartialGeoOrPreference = 'partial_geo_or_preference';

  // --- Interests reasons ---
  static const String reasonMissingInterestsA = 'missing_interests_a';
  static const String reasonMissingInterestsB = 'missing_interests_b';
  static const String reasonEmptyUnion = 'empty_union';
}
