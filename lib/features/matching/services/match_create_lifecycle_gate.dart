import '../models/match_model.dart';

/// Outcome of hardened match-create lifecycle evaluation.
///
/// Document existence alone is never treated as an active match.
enum MatchCreateLifecycleDecision {
  /// No match doc yet; mutual likes present; no blocks → create.
  createNew,

  /// Existing match with explicit `state == active` → idempotent success.
  idempotentActiveSuccess,

  /// Existing `unmatched` match — do not auto-reactivate.
  refuseUnmatchedExists,

  /// Existing `blocked` match — refuse.
  refuseBlockedExists,

  /// Existing doc with missing/unknown state — refuse (existence ≠ active).
  refuseExistingNonActive,

  /// Either direction has a block — refuse new create.
  refuseBlockEitherDirection,

  /// Current mutual likes not present — refuse.
  refuseNonMutualLike,
}

/// Pure gate for [MatchService.createMatchIfMutualLike] (testable, no I/O).
class MatchCreateLifecycleGate {
  MatchCreateLifecycleGate._();

  static const String policyVersion = 'match_create_lifecycle_v1';

  /// Decide whether to create, succeed idempotently, or refuse.
  ///
  /// [matchState] is the raw `state` field when [matchExists] is true.
  /// Only the literal [MatchState.active] name is treated as active.
  static MatchCreateLifecycleDecision decide({
    required bool matchExists,
    required String? matchState,
    required bool viewerBlockedCandidate,
    required bool candidateBlockedViewer,
    required bool viewerLikesCandidate,
    required bool candidateLikesViewer,
  }) {
    if (matchExists) {
      if (matchState == MatchState.active.name) {
        return MatchCreateLifecycleDecision.idempotentActiveSuccess;
      }
      if (matchState == MatchState.unmatched.name) {
        return MatchCreateLifecycleDecision.refuseUnmatchedExists;
      }
      if (matchState == MatchState.blocked.name) {
        return MatchCreateLifecycleDecision.refuseBlockedExists;
      }
      return MatchCreateLifecycleDecision.refuseExistingNonActive;
    }

    if (viewerBlockedCandidate || candidateBlockedViewer) {
      return MatchCreateLifecycleDecision.refuseBlockEitherDirection;
    }

    if (!viewerLikesCandidate || !candidateLikesViewer) {
      return MatchCreateLifecycleDecision.refuseNonMutualLike;
    }

    return MatchCreateLifecycleDecision.createNew;
  }

  /// Maps a decision to the public `bool` used by Discover UI.
  static bool isSuccess(MatchCreateLifecycleDecision decision) {
    switch (decision) {
      case MatchCreateLifecycleDecision.createNew:
      case MatchCreateLifecycleDecision.idempotentActiveSuccess:
        return true;
      case MatchCreateLifecycleDecision.refuseUnmatchedExists:
      case MatchCreateLifecycleDecision.refuseBlockedExists:
      case MatchCreateLifecycleDecision.refuseExistingNonActive:
      case MatchCreateLifecycleDecision.refuseBlockEitherDirection:
      case MatchCreateLifecycleDecision.refuseNonMutualLike:
        return false;
    }
  }

  static bool isLikeDirection(String? direction) => direction == 'like';
}
