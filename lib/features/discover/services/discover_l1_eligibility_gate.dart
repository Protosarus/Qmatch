/// Ratified L1 Discover eligibility helpers.
///
/// Policy: `matching_constraints_contract_v1` / `product_ratified_not_live`.
/// Mirrors canonical `discover_eligible` assessment completion:
/// `test_completed || assessment_flow_completed` (no new completion flag).
///
/// Block-by-me is a client L1 hard exclude (owner-readable).
/// Reverse-block is Admin-omitted on the trusted L2 callable — clients
/// must not GET peer block docs.
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

  /// Viewer-block is a client L1 hard exclude. Reverse-block is Admin-omitted
  /// on trusted L2; pass [candidateBlockedViewer] only when already known.
  static bool excludedByBlocks({
    required bool viewerBlockedCandidate,
    required bool candidateBlockedViewer,
  }) =>
      viewerBlockedCandidate || candidateBlockedViewer;
}
