import '../../assessment/domain/profile/qmatch_profile_contract.dart';
import '../../assessment/domain/profile/qmatch_profile_models.dart';

/// Frozen contracts for shadow-only canonical 20D pairwise distance.
///
/// Explicit non-goals: archetype/category, IQ/EQ bands, quantum, RVI,
/// Gaussian/RBF similarity %, Discover ranking, fake confidence / neutrals.
/// Narrative prototype assignment ids are never inputs or outputs.
class Canonical20dShadowDistanceContract {
  Canonical20dShadowDistanceContract._();

  static const String scoringVersion = 'canonical_20d_shadow_distance_v1';

  static const String registryVersion =
      QmatchProfileContract.registryVersion;

  static const int requiredDimensionCount =
      QmatchProfileContract.requiredDimensionCount;

  /// Canonical registry order (4 IQ + 10 EQ + 6 Frequency).
  static const List<String> dimensionIds = QmatchProfileTaxonomy.all;

  /// Minimum evidence_count on each side for a dimension to be comparable.
  static const int minEvidenceCount = 1;
}
