/// L3 v1 production diagnostics — separate evaluators, no fusion, no ranking.
///
/// Spec: `qmatch_l3_soft_preference_signal_contract_v1`.
/// Discover L3 v1 = profile soft-preference signals only.
/// CM relationship/value fit is a future L3 extension, not this contract.
/// Never L1 eligibility. No combined score. No weights. `looking_for` inactive.
class L3SoftPreferenceSignalContract {
  L3SoftPreferenceSignalContract._();

  static const String policyVersion = 'l3_soft_preference_signal_contract_v1';
  static const String policyStatus = 'production_diagnostics_non_ranking_v1';

  static const String ageScoringVersion = 'l3_age_preference_soft_v1';
  static const String distanceScoringVersion = 'l3_distance_preference_soft_v1';
  static const String interestsScoringVersion = 'l3_interests_overlap_soft_v1';

  /// True = not a Discover ranker. Diagnostics may still be production-promoted.
  static const bool shadowOnly = true;
  static const bool affectsDiscoverRanking = false;
  static const bool combinedScoreAllowed = false;
  static const bool weightsAllowed = false;
  static const bool lookingForActive = false;
  static const bool relationshipValuesActive = false;
  static const bool genderInferenceAllowed = false;
  static const bool lifestyleSelfAttributesAreMatchingInputs = false;
  static const bool imputationAllowed = false;
  static const bool isL1EligibilityGate = false;

  /// Age + interests: production L3 diagnostics (still non-ranking).
  static const bool ageProductionPromoted = true;
  static const bool interestsProductionPromoted = true;

  /// Distance: evaluated as a diagnostic; not production-promoted until
  /// location privacy is solved.
  static const bool distanceProductionPromoted = false;

  /// Age diagnostic class (not a rank key).
  static const String ageDiagnosticMutualFit = 'mutual_fit';
  static const String ageDiagnosticKnownMismatch = 'known_mismatch';
  static const String ageDiagnosticUnknown = 'unknown';

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
