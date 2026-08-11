import 'canonical_20d_shadow_distance_contract.dart';

/// One subject's measured canonical scores + evidence (no imputed missing dims).
///
/// Only include dimensions that are actually measured. Missing registry dims
/// are absent — never encoded as 0 / 0.5 / 50.
class Canonical20dShadowSubject {
  Canonical20dShadowSubject({
    required Map<String, double> measuredScores,
    required Map<String, int> evidenceCounts,
  })  : measuredScores = Map.unmodifiable(measuredScores),
        evidenceCounts = Map.unmodifiable(evidenceCounts);

  /// Measured scores in [0, 1], keyed by canonical dimension id.
  final Map<String, double> measuredScores;

  /// Per-dimension evidence counts `n_j` (typically from assessments).
  final Map<String, int> evidenceCounts;

  /// True when every registry dimension is measured with valid score + evidence.
  bool get isComplete20d {
    for (final id in Canonical20dShadowDistanceContract.dimensionIds) {
      final score = measuredScores[id];
      if (score == null || !score.isFinite || score < 0.0 || score > 1.0) {
        return false;
      }
      final n = evidenceCounts[id] ?? 0;
      if (n < Canonical20dShadowDistanceContract.minEvidenceCount) {
        return false;
      }
    }
    return measuredScores.length >=
        Canonical20dShadowDistanceContract.requiredDimensionCount;
  }
}
