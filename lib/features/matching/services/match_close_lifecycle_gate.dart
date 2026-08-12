import '../models/match_model.dart';

/// Why a relationship is being closed.
enum MatchCloseTarget {
  unmatched,
  blocked,
}

/// Pure plan for closing match + thread without reactivation.
class MatchClosePlan {
  const MatchClosePlan({
    required this.updateMatch,
    required this.newMatchState,
    required this.updateThread,
    required this.threadClosedReason,
    required this.idempotent,
    required this.refuseNotMember,
  });

  /// When true, write match `state` to [newMatchState].
  final bool updateMatch;

  /// Next match state (`unmatched` / `blocked`), or null when not updating.
  final String? newMatchState;

  /// When true and thread exists + actor is participant, set thread `closed`.
  final bool updateThread;

  /// `closed_reason` for the thread write.
  final String threadClosedReason;

  /// Already in a compatible closed state (retry-safe no-op on match).
  final bool idempotent;

  /// Actor is not a member of the match (when match exists).
  final bool refuseNotMember;

  static const MatchClosePlan missingMatchCloseThreadOnly = MatchClosePlan(
    updateMatch: false,
    newMatchState: null,
    updateThread: true,
    threadClosedReason: 'blocked',
    idempotent: true,
    refuseNotMember: false,
  );
}

/// Pure close lifecycle for unmatch/block (testable, no I/O).
///
/// Never plans a transition back to `active`.
class MatchCloseLifecycleGate {
  MatchCloseLifecycleGate._();

  static const String policyVersion = 'match_close_lifecycle_v1';

  /// Resolve thread id: prefer match.thread_id, else deterministic matchId.
  static String resolveThreadId({
    required String matchId,
    String? matchThreadId,
    String? explicitThreadId,
  }) {
    final fromMatch = matchThreadId?.trim();
    if (fromMatch != null && fromMatch.isNotEmpty) return fromMatch;
    final explicit = explicitThreadId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return matchId;
  }

  static MatchClosePlan plan({
    required bool matchExists,
    required String? currentMatchState,
    required bool actorIsMatchMember,
    required MatchCloseTarget target,
    required bool threadExists,
    required bool actorIsThreadParticipant,
    required String? currentThreadStatus,
  }) {
    final threadReason =
        target == MatchCloseTarget.blocked ? 'blocked' : 'unmatched';

    if (matchExists && !actorIsMatchMember) {
      return MatchClosePlan(
        updateMatch: false,
        newMatchState: null,
        updateThread: false,
        threadClosedReason: threadReason,
        idempotent: false,
        refuseNotMember: true,
      );
    }

    if (!matchExists) {
      final shouldCloseThread = threadExists &&
          actorIsThreadParticipant &&
          currentThreadStatus != 'closed';
      return MatchClosePlan(
        updateMatch: false,
        newMatchState: null,
        updateThread: shouldCloseThread,
        threadClosedReason: threadReason,
        idempotent: true,
        refuseNotMember: false,
      );
    }

    final matchUpdate = _matchUpdate(
      current: currentMatchState,
      target: target,
    );

    final threadNeedsClose = threadExists &&
        actorIsThreadParticipant &&
        currentThreadStatus != 'closed';

    return MatchClosePlan(
      updateMatch: matchUpdate.update,
      newMatchState: matchUpdate.nextState,
      updateThread: threadNeedsClose,
      threadClosedReason: threadReason,
      idempotent: !matchUpdate.update && !threadNeedsClose,
      refuseNotMember: false,
    );
  }

  static ({bool update, String? nextState}) _matchUpdate({
    required String? current,
    required MatchCloseTarget target,
  }) {
    if (target == MatchCloseTarget.unmatched) {
      if (current == MatchState.active.name) {
        return (update: true, nextState: MatchState.unmatched.name);
      }
      // Already unmatched/blocked/unknown-closed → do not reopen or downgrade.
      return (update: false, nextState: null);
    }

    // blocked target
    if (current == MatchState.blocked.name) {
      return (update: false, nextState: null);
    }
    if (current == MatchState.active.name ||
        current == MatchState.unmatched.name) {
      return (update: true, nextState: MatchState.blocked.name);
    }
    // Unknown state: still close to blocked (one-way harden).
    return (update: true, nextState: MatchState.blocked.name);
  }
}
