/// Shadow-only pairwise distance output.
///
/// Raw structural distance + evidence coverage. No similarity %, confidence,
/// archetype, quantum, or RVI fields.
class Canonical20dShadowDistanceResult {
  const Canonical20dShadowDistanceResult({
    required this.available,
    required this.distanceSquared,
    required this.distance,
    required this.comparableDimensionCount,
    required this.registryDimensionCount,
    required this.unweightedCoverage,
    required this.comparableDimensionIds,
    required this.excludedDimensionIds,
    required this.scoringVersion,
    required this.registryVersion,
    required this.shadowOnly,
  });

  /// True when at least one shared measured+evidence dimension was compared.
  final bool available;

  /// Equal-weight mean squared Euclidean over comparable dims; null if unavailable.
  final double? distanceSquared;

  /// `sqrt(distanceSquared)`; null if unavailable.
  final double? distance;

  final int comparableDimensionCount;
  final int registryDimensionCount;

  /// `comparableDimensionCount / registryDimensionCount` (0 when registry empty).
  final double unweightedCoverage;

  /// Sorted comparable dimension ids.
  final List<String> comparableDimensionIds;

  /// Sorted registry dims excluded (missing/invalid score or evidence on either side).
  final List<String> excludedDimensionIds;

  final String scoringVersion;
  final String registryVersion;

  /// Always true for this matcher.
  final bool shadowOnly;

  /// Wire map for telemetry / future shadow persistence (no % / confidence).
  Map<String, dynamic> toWireMap() => {
        'available': available,
        if (distanceSquared != null) 'distance_squared': distanceSquared,
        if (distance != null) 'distance': distance,
        'comparable_dimension_count': comparableDimensionCount,
        'registry_dimension_count': registryDimensionCount,
        'unweighted_coverage': unweightedCoverage,
        'comparable_dimension_ids': comparableDimensionIds,
        'excluded_dimension_ids': excludedDimensionIds,
        'scoring_version': scoringVersion,
        'registry_version': registryVersion,
        'shadow_only': shadowOnly,
      };
}
