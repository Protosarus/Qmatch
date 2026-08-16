import '../../assessment/domain/profile/qmatch_profile_contract.dart';
import '../../assessment/domain/profile/qmatch_profile_models.dart';

/// Frozen structural Matching formula replica (group-normalized 20D).
///
/// This Dart matcher does **not** rank Discover ([liveDiscoverRanking] is
/// false). Discover ranking uses trusted backend `compareStageB2Structural`
/// under `structural_l2_v1`. [policyStatus] remains
/// `production_candidate_not_live` for this client module.
///
/// Weights are frozen. Formula is group-normalized per-module MSE with
/// missing-module omission + weight renormalization and no imputation.
///
/// Explicit non-goals / prohibited in this structural core:
/// Persona, archetype, quantum, RVI, similarity %, thresholds,
/// Discover ranking/UI coupling from this Dart matcher.
///
/// Related roles (outside this core):
/// - trusted backend L2 = live Discover structural ranking
/// - equal-20D shadow (`canonical_20d_shadow_distance_v1`) = baseline only
/// - legacy `CompatibilityScoring` = rollback-only Discover path (`legacy_v1`)
class Canonical20dGroupNormalizedShadowContract {
  Canonical20dGroupNormalizedShadowContract._();

  static const String scoringVersion =
      'canonical_20d_group_normalized_shadow_distance_v1';

  static const String policyVersion =
      'structural_matching_production_candidate_policy_v1';

  /// Status of **this Dart matcher**, not of Discover ranking.
  /// Discover ranking is trusted backend L2 (`structural_l2_v1`).
  static const String policyStatus = 'production_candidate_not_live';

  static const String registryVersion =
      QmatchProfileContract.registryVersion;

  /// Weights are frozen under [policyVersion]; not open for ad-hoc tuning.
  static const bool weightsFrozen = true;

  /// This Dart matcher remains a replica — must not drive Discover ranking.
  static const bool shadowOnly = true;

  /// Wire alias: candidate is not live; weights are frozen (not tunable).
  static const bool provisional = false;

  static const bool liveDiscoverRanking = false;

  static const List<String> iqDimensionIds = QmatchProfileTaxonomy.iq;
  static const List<String> eqDimensionIds = QmatchProfileTaxonomy.eq;
  static const List<String> frequencyDimensionIds =
      QmatchProfileTaxonomy.frequency;

  /// Frozen configured weights (sum = 1.0).
  static const double iqWeight = 0.133333;
  static const double eqWeight = 0.400000;
  static const double frequencyWeight = 0.466667;

  static const Map<String, double> moduleWeights = {
    'iq': iqWeight,
    'eq': eqWeight,
    'frequency': frequencyWeight,
  };
}
