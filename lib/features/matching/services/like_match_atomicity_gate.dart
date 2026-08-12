import 'match_create_lifecycle_gate.dart';

/// Plan for atomic Like → mutual-match evaluation (`like_match_atomicity_v1`).
///
/// Own Like is always persisted in the same transaction as the evaluation.
/// Match artifacts are written only when [matchDecision] is [createNew].
class LikeMatchAtomicPlan {
  const LikeMatchAtomicPlan({
    required this.persistOwnLike,
    required this.matchDecision,
  });

  /// Always true for a Like action — Like must persist even when match is refused.
  final bool persistOwnLike;

  final MatchCreateLifecycleDecision matchDecision;

  bool get writeMatchArtifacts =>
      matchDecision == MatchCreateLifecycleDecision.createNew;

  bool get matched => MatchCreateLifecycleGate.isSuccess(matchDecision);
}

/// Pure Like→match atomicity helper (testable, no I/O).
class LikeMatchAtomicityGate {
  LikeMatchAtomicityGate._();

  static const String policyVersion = 'like_match_atomicity_v1';

  /// Plan a Like inside one transaction.
  ///
  /// [viewerLikesCandidatePending] is true when this transaction will write the
  /// viewer's Like (so mutual check does not depend on a prior separate write).
  static LikeMatchAtomicPlan planLike({
    required bool matchExists,
    required String? matchState,
    required bool viewerBlockedCandidate,
    required bool candidateBlockedViewer,
    required bool viewerLikesCandidatePending,
    required bool candidateLikesViewer,
  }) {
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
