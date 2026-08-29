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
  ///
  /// Use this on full `users/{uid}` documents (owner, match validity).
  /// Discover peer candidates come from `public_profiles` and must use
  /// [passesPublicProfileLocalGates] instead — those snapshots omit
  /// `active` / completion mirrors.
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

  /// Client filters for a `public_profiles` candidate already returned by
  /// `discover_eligible == true`. Account completion is the backend query;
  /// do not require missing private L1 mirrors.
  static bool passesPublicProfileLocalGates({
    required bool discoverEligible,
    required bool hasPhoto,
  }) {
    if (discoverEligible != true) return false;
    if (!hasPhoto) return false;
    return true;
  }

  /// Viewer-block is a client L1 hard exclude. Reverse-block is Admin-omitted
  /// on trusted L2; pass [candidateBlockedViewer] only when already known.
  static bool excludedByBlocks({
    required bool viewerBlockedCandidate,
    required bool candidateBlockedViewer,
  }) =>
      viewerBlockedCandidate || candidateBlockedViewer;
}
