import '../models/match_model.dart';
import 'like_match_outcome.dart';
import 'match_create_lifecycle_gate.dart';

/// Plan for atomic Like → mutual-match evaluation (`like_match_atomicity_v1` +
/// `stale_user_match_eligibility_v1`).
class LikeMatchAtomicPlan {
  const LikeMatchAtomicPlan({
    required this.persistOwnLike,
    required this.matchDecision,
  });

  /// When false, a stale/invalid card must not write a new Like.
  final bool persistOwnLike;

  final MatchCreateLifecycleDecision matchDecision;

  bool get writeMatchArtifacts =>
      matchDecision == MatchCreateLifecycleDecision.createNew;

  bool get matched => MatchCreateLifecycleGate.isSuccess(matchDecision);

  /// Public UX/service outcome (dialog only for [LikeMatchOutcome.createdNewMatch]).
  LikeMatchOutcome get outcome => LikeMatchOutcomeMapper.fromDecision(matchDecision);
}

/// Maps lifecycle decisions → [LikeMatchOutcome] for Discover UX.
class LikeMatchOutcomeMapper {
  LikeMatchOutcomeMapper._();

  static LikeMatchOutcome fromDecision(MatchCreateLifecycleDecision decision) {
    switch (decision) {
      case MatchCreateLifecycleDecision.createNew:
        return LikeMatchOutcome.createdNewMatch;
      case MatchCreateLifecycleDecision.idempotentActiveSuccess:
        return LikeMatchOutcome.existingActiveMatch;
      case MatchCreateLifecycleDecision.refuseUnmatchedExists:
      case MatchCreateLifecycleDecision.refuseBlockedExists:
      case MatchCreateLifecycleDecision.refuseExistingNonActive:
      case MatchCreateLifecycleDecision.refuseBlockEitherDirection:
      case MatchCreateLifecycleDecision.refuseNonMutualLike:
      case MatchCreateLifecycleDecision.refuseInvalidLiveUser:
        return LikeMatchOutcome.noMatch;
    }
  }
}

/// Pure Like→match atomicity helper (testable, no I/O).
class LikeMatchAtomicityGate {
  LikeMatchAtomicityGate._();

  static const String policyVersion = 'like_match_atomicity_v1';

  /// Plan a Like inside one transaction.
  ///
  /// When [viewerLiveEligible] or [targetLiveEligible] is false:
  /// - never persist a new Like
  /// - never create a match
  /// - if an **active** match already exists, return idempotent success (chat
  ///   untouched)
  static LikeMatchAtomicPlan planLike({
    required bool matchExists,
    required String? matchState,
    required bool viewerBlockedCandidate,
    required bool candidateBlockedViewer,
    required bool viewerLikesCandidatePending,
    required bool candidateLikesViewer,
    required bool viewerLiveEligible,
    required bool targetLiveEligible,
  }) {
    if (!viewerLiveEligible || !targetLiveEligible) {
      final alreadyActive =
          matchExists && matchState == MatchState.active.name;
      return LikeMatchAtomicPlan(
        persistOwnLike: false,
        matchDecision: alreadyActive
            ? MatchCreateLifecycleDecision.idempotentActiveSuccess
            : MatchCreateLifecycleDecision.refuseInvalidLiveUser,
      );
    }

    final decision = MatchCreateLifecycleGate.decide(
      matchExists: matchExists,
      matchState: matchState,
      viewerBlockedCandidate: viewerBlockedCandidate,
      candidateBlockedViewer: candidateBlockedViewer,
      viewerLikesCandidate: viewerLikesCandidatePending,
      candidateLikesViewer: candidateLikesViewer,
    );
    return LikeMatchAtomicPlan(
      persistOwnLike: true,
      matchDecision: decision,
    );
  }

  /// Pass only mutates the viewer's swipe doc — never match/thread.
  static bool passMayMutateMatchOrThread() => false;
}
