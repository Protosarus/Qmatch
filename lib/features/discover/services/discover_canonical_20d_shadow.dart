import '../../assessment/domain/profile/qmatch_profile_contract.dart';
import '../../assessment/domain/profile/qmatch_profile_models.dart';
import '../../matching/domain/canonical_20d_shadow_distance.dart';

/// Builds a shadow subject from `users/{uid}/profiles/canonical_v1` only.
///
/// Measured rows supply scores. Each valid measured score is treated as
/// `evidence_count = 1` for shadow diagnostics (profile load path does not
/// fetch assessment evidence docs). Missing dims stay absent — never 0/0.5/50.
class DiscoverCanonical20dShadowSubjectBuilder {
  DiscoverCanonical20dShadowSubjectBuilder._();

  static Canonical20dShadowSubject? fromCanonicalProfile(
    Map<String, dynamic>? profile,
  ) {
    if (profile == null) return null;
    final rows = profile['measured_dimensions'];
    if (rows is! List || rows.isEmpty) return null;

    final scores = <String, double>{};
    final evidence = <String, int>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final dim = QmatchProfileDimension.fromJson(
        Map<String, dynamic>.from(row),
      );
      if (dim.measurementState != QmatchMeasurementState.measured) continue;
      final value = dim.value;
      if (value == null || !value.isFinite || value < 0.0 || value > 1.0) {
        continue;
      }
      if (!Canonical20dShadowDistanceContract.dimensionIds.contains(
        dim.dimensionId,
      )) {
        continue;
      }
      scores[dim.dimensionId] = value;
      evidence[dim.dimensionId] = Canonical20dShadowDistanceContract.minEvidenceCount;
    }
    if (scores.isEmpty) return null;
    return Canonical20dShadowSubject(
      measuredScores: scores,
      evidenceCounts: evidence,
    );
  }
}

/// In-memory Discover shadow diagnostic (not shown in UI, not persisted).
class DiscoverShadowDistanceDiagnostic {
  const DiscoverShadowDistanceDiagnostic({
    required this.available,
    required this.distance,
    required this.comparableDimensionCount,
    required this.unweightedCoverage,
    required this.scoringVersion,
  });

  factory DiscoverShadowDistanceDiagnostic.fromResult(
    Canonical20dShadowDistanceResult result,
  ) {
    return DiscoverShadowDistanceDiagnostic(
      available: result.available,
      distance: result.distance,
      comparableDimensionCount: result.comparableDimensionCount,
      unweightedCoverage: result.unweightedCoverage,
      scoringVersion: result.scoringVersion,
    );
  }

  final bool available;
  final double? distance;
  final int comparableDimensionCount;
  final double unweightedCoverage;
  final String scoringVersion;
}
