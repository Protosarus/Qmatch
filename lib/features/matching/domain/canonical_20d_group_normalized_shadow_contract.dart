import '../../assessment/domain/profile/qmatch_profile_contract.dart';
import '../../assessment/domain/profile/qmatch_profile_models.dart';

/// Provisional group-normalized structural shadow Matching (offline / shadow-only).
///
/// Derived from CM v2 structural trio 0.08 / 0.24 / 0.28 renormalized to 1.0.
/// Explicit non-goals: Persona weights, archetype, quantum, RVI, Discover ranking,
/// similarity %, thresholds.
class Canonical20dGroupNormalizedShadowContract {
  Canonical20dGroupNormalizedShadowContract._();

  static const String scoringVersion =
      'canonical_20d_group_normalized_shadow_distance_v1';

  static const String registryVersion =
      QmatchProfileContract.registryVersion;

  static const bool provisional = true;
  static const bool shadowOnly = true;

  static const List<String> iqDimensionIds = QmatchProfileTaxonomy.iq;
  static const List<String> eqDimensionIds = QmatchProfileTaxonomy.eq;
  static const List<String> frequencyDimensionIds =
      QmatchProfileTaxonomy.frequency;

  /// Provisional configured weights (sum = 1.0).
  static const double iqWeight = 0.133333;
  static const double eqWeight = 0.400000;
  static const double frequencyWeight = 0.466667;

  static const Map<String, double> moduleWeights = {
    'iq': iqWeight,
    'eq': eqWeight,
    'frequency': frequencyWeight,
  };
}
