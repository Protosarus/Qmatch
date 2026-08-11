import '../../assessment/domain/profile/qmatch_profile_contract.dart';
import '../../assessment/domain/profile/qmatch_profile_models.dart';

/// Frozen structural Matching production-candidate (group-normalized 20D).
///
/// Status: [policyStatus] = `production_candidate_not_live`.
/// Weights are frozen. Formula is group-normalized per-module MSE with
/// missing-module omission + weight renormalization and no imputation.
///
/// Explicit non-goals / prohibited in this structural core:
/// Persona, archetype, quantum, RVI, similarity %, thresholds,
/// Discover ranking/UI coupling.
///
/// Related roles (outside this core):
/// - equal-20D shadow (`canonical_20d_shadow_distance_v1`) = baseline only
/// - legacy `CompatibilityScoring` = remains live Discover ranking
class Canonical20dGroupNormalizedShadowContract {
  Canonical20dGroupNormalizedShadowContract._();

  static const String scoringVersion =
      'canonical_20d_group_normalized_shadow_distance_v1';

  static const String policyVersion =
      'structural_matching_production_candidate_policy_v1';

  /// Frozen rollout status. Not live in Discover ranking/UI.
  static const String policyStatus = 'production_candidate_not_live';

  static const String registryVersion =
      QmatchProfileContract.registryVersion;

  /// Weights are frozen under [policyVersion]; not open for ad-hoc tuning.
  static const bool weightsFrozen = true;

  /// Still shadow-only — must not drive Discover ranking or UI.
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
