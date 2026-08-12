/// Ratified L1 Discover eligibility helpers.
///
/// Policy: `matching_constraints_contract_v1` / `product_ratified_not_live`.
/// Mirrors canonical `discover_eligible` assessment completion:
/// `test_completed || assessment_flow_completed` (no new completion flag).
///
/// Block-by-me and reverse-block are both hard L1 safety excludes.
class DiscoverL1EligibilityGate {
  DiscoverL1EligibilityGate._();

  /// Canonical assessment-completion source (existing flags only).
  static bool assessmentsCompleted({
    required bool testCompleted,
    required bool assessmentFlowCompleted,
  }) =>
      testCompleted || assessmentFlowCompleted;

  /// Local re-check aligned with trusted Discover eligibility derivation
  /// (`trusted_discover_eligibility_authority_v1` / Cloud Function).
  static bool passesLocalAccountGates({
    required bool active,
    required bool profileCompleted,
    required bool testCompleted,
    required bool assessmentFlowCompleted,
    required bool hasPhoto,
  }) {
    if (!active) return false;
    if (!profileCompleted) return false;
    if (!hasPhoto) return false;
    return assessmentsCompleted(
      testCompleted: testCompleted,
      assessmentFlowCompleted: assessmentFlowCompleted,
    );
  }

  /// Hard L1 safety: either direction excludes the pair for the viewer.
  static bool excludedByBlocks({
    required bool viewerBlockedCandidate,
    required bool candidateBlockedViewer,
  }) =>
      viewerBlockedCandidate || candidateBlockedViewer;
}
