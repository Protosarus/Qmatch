/// Per-module structural distance for group-normalized shadow Matching.
class Canonical20dGroupModuleDistance {
  const Canonical20dGroupModuleDistance({
    required this.moduleId,
    required this.available,
    required this.distanceSquared,
    required this.distance,
    required this.comparableDimensionCount,
    required this.registryDimensionCount,
    required this.coverage,
    required this.configuredWeight,
    required this.effectiveWeight,
  });

  final String moduleId;
  final bool available;
  final double? distanceSquared;
  final double? distance;
  final int comparableDimensionCount;
  final int registryDimensionCount;

  /// comparable / registry for this module.
  final double coverage;

  /// Configured provisional weight before omission renormalization.
  final double configuredWeight;

  /// Weight used in the combined mix (0 when omitted).
  final double effectiveWeight;

  Map<String, dynamic> toWireMap() => {
        'module_id': moduleId,
        'available': available,
        if (distanceSquared != null) 'distance_squared': distanceSquared,
        if (distance != null) 'distance': distance,
        'comparable_dimension_count': comparableDimensionCount,
        'registry_dimension_count': registryDimensionCount,
        'coverage': coverage,
        'configured_weight': configuredWeight,
        'effective_weight': effectiveWeight,
      };
}

/// Group-normalized structural shadow result (raw distances only).
class Canonical20dGroupNormalizedShadowResult {
  const Canonical20dGroupNormalizedShadowResult({
    required this.available,
    required this.iq,
    required this.eq,
    required this.frequency,
    required this.combinedDistanceSquared,
    required this.combinedDistance,
    required this.totalComparableDimensionCount,
    required this.totalRegistryDimensionCount,
    required this.totalCoverage,
    required this.scoringVersion,
    required this.registryVersion,
    required this.provisional,
    required this.shadowOnly,
  });

  final bool available;
  final Canonical20dGroupModuleDistance iq;
  final Canonical20dGroupModuleDistance eq;
  final Canonical20dGroupModuleDistance frequency;

  final double? combinedDistanceSquared;
  final double? combinedDistance;

  final int totalComparableDimensionCount;
  final int totalRegistryDimensionCount;

  /// totalComparable / 20.
  final double totalCoverage;

  final String scoringVersion;
  final String registryVersion;
  final bool provisional;
  final bool shadowOnly;

  Map<String, dynamic> toWireMap() => {
        'available': available,
        'iq': iq.toWireMap(),
        'eq': eq.toWireMap(),
        'frequency': frequency.toWireMap(),
        if (combinedDistanceSquared != null)
          'combined_distance_squared': combinedDistanceSquared,
        if (combinedDistance != null) 'combined_distance': combinedDistance,
        'total_comparable_dimension_count': totalComparableDimensionCount,
        'total_registry_dimension_count': totalRegistryDimensionCount,
        'total_coverage': totalCoverage,
        'scoring_version': scoringVersion,
        'registry_version': registryVersion,
        'provisional': provisional,
        'shadow_only': shadowOnly,
      };
}
