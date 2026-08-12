import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../models/match_model.dart';
import 'match_close_lifecycle_gate.dart';
import 'match_create_lifecycle_gate.dart';

class MatchService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  MatchService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super();

  /// Creates a match+thread when mutual likes exist and no block applies.
  ///
  /// Lifecycle (`match_create_lifecycle_v1`):
  /// - existing **active** match → idempotent `true`
  /// - existing **unmatched** → `false` (no auto-reactivate)
  /// - existing **blocked** / unknown state → `false`
  /// - block either direction → `false`
  /// - new create requires **both** current likes
  ///
  /// Document existence alone never means an active match.
  Future<bool> createMatchIfMutualLike(String targetUid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    if (targetUid == me.uid) {
      throw StateError('Cannot create a match with yourself.');
    }

    final currentUid = me.uid;
    final userA = currentUid.compareTo(targetUid) <= 0 ? currentUid : targetUid;
    final userB = currentUid.compareTo(targetUid) <= 0 ? targetUid : currentUid;

    final matchId = FirestorePaths.deterministicMatchId(currentUid, targetUid);
    final threadId = FirestorePaths.deterministicThreadId(currentUid, targetUid);

    final ownSwipeRef = FirestorePaths.userSwipeDoc(currentUid, targetUid);
    final reverseSwipeRef = FirestorePaths.userSwipeDoc(targetUid, currentUid);
    final viewerBlockRef = FirestorePaths.userBlockDoc(currentUid, targetUid);
    final reverseBlockRef = FirestorePaths.userBlockDoc(targetUid, currentUid);
    final matchRef = FirestorePaths.matchDoc(matchId);
    final threadRef = FirestorePaths.threadDoc(threadId);
    // Fixed id so rules can allow bootstrap without open sender_id==system spoof.
    final messageRef =
        FirestorePaths.threadMessages(threadId).doc('system_match_v1');

    return _firestore.runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      final ownSwipeSnap = await tx.get(ownSwipeRef);
      final reverseSwipeSnap = await tx.get(reverseSwipeRef);
      final viewerBlockSnap = await tx.get(viewerBlockRef);
      final reverseBlockSnap = await tx.get(reverseBlockRef);

      final decision = MatchCreateLifecycleGate.decide(
        matchExists: matchSnap.exists,
        matchState: matchSnap.data()?['state'] as String?,
        viewerBlockedCandidate: viewerBlockSnap.exists,
        candidateBlockedViewer: reverseBlockSnap.exists,
        viewerLikesCandidate: MatchCreateLifecycleGate.isLikeDirection(
          ownSwipeSnap.data()?['direction'] as String?,
        ),
        candidateLikesViewer: MatchCreateLifecycleGate.isLikeDirection(
          reverseSwipeSnap.data()?['direction'] as String?,
        ),
      );

      if (decision == MatchCreateLifecycleDecision.idempotentActiveSuccess) {
        return true;
      }
      if (decision != MatchCreateLifecycleDecision.createNew) {
        return false;
      }

      // Create match doc
      tx.set(matchRef, {
        'match_id': matchId,
        'user_a': userA,
        'user_b': userB,
        'users': [userA, userB],
        'created_at': FieldValue.serverTimestamp(),
        'created_by': 'system',
        'thread_id': threadId,
        'state': MatchState.active.name,
        'last_activity_at': FieldValue.serverTimestamp(),
        'compat': <String, dynamic>{},
        'reveal': {
          'blur_level': 3,
          'consent_a': false,
          'consent_b': false,
          'requested_by': null,
          'requested_at': null,
          'revealed_at': null,
        },
      });

      // Create thread doc (deterministic id mirrors match id)
      tx.set(threadRef, {
        'thread_id': threadId,
        'match_id': matchId,
        'participants': [userA, userB],
        'created_at': FieldValue.serverTimestamp(),
        'last_message_at': FieldValue.serverTimestamp(),
        'last_message_preview': 'You matched!',
        'last_message_sender': 'system',
        'unread_counts': {userA: 0, userB: 0},
        'text_count_total': 0,
        'text_count_by_uid': {userA: 0, userB: 0},
        'status': 'active',
      }, SetOptions(merge: true));

      // First system message
      tx.set(messageRef, {
        'thread_id': threadId,
        'sender_id': 'system',
        'type': 'system',
        'text': 'You matched!',
        'created_at': FieldValue.serverTimestamp(),
        'client_created_at': DateTime.now().millisecondsSinceEpoch,
        'read_by': <String, dynamic>{},
        'moderation': null,
      });

      return true;
    });
  }

  Stream<List<MatchModel>> getMyMatchesStream() {
    final me = _auth.currentUser;
    if (me == null) return const Stream<List<MatchModel>>.empty();

    // Keep query simple to avoid composite index requirements in MVP.
    return FirestorePaths.matches().where('users', arrayContains: me.uid).snapshots().map(
      (snapshot) {
        final items = snapshot.docs
            .map((d) => MatchModel.fromFirestore(d.id, d.data()))
            .where((m) => m.state == MatchState.active)
            .toList();

        items.sort((a, b) {
          final aTs = a.lastActivityAt?.millisecondsSinceEpoch ?? 0;
          final bTs = b.lastActivityAt?.millisecondsSinceEpoch ?? 0;
          return bTs.compareTo(aTs);
        });

        return items;
      },
    );
  }

  /// Atomically close match + thread as `unmatched` / `closed`.
  ///
  /// Idempotent if already closed. Never reactivates. Missing thread is OK
  /// (match still closes). Uses deterministic `thread_id == matchId` fallback.
  Future<void> unmatch(String matchId) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    if (matchId.trim().isEmpty) {
      throw StateError('matchId is required.');
    }

    await _closeRelationshipInTransaction(
      actorUid: me.uid,
      matchId: matchId.trim(),
      target: MatchCloseTarget.unmatched,
      explicitThreadId: null,
      includeBlockDoc: false,
      blockedUid: null,
      blockReason: null,
    );
  }

  /// Shared atomic close used by unmatch and [SafetyService.blockUser].
  ///
  /// When [includeBlockDoc] is true, also writes `users/{actor}/blocks/{blockedUid}`
  /// in the same transaction.
  Future<void> closeRelationshipInTransaction({
    required String actorUid,
    required String matchId,
    required MatchCloseTarget target,
    String? explicitThreadId,
    bool includeBlockDoc = false,
    String? blockedUid,
    String? blockReason,
  }) {
    return _closeRelationshipInTransaction(
      actorUid: actorUid,
      matchId: matchId,
      target: target,
      explicitThreadId: explicitThreadId,
      includeBlockDoc: includeBlockDoc,
      blockedUid: blockedUid,
      blockReason: blockReason,
    );
  }

  Future<void> _closeRelationshipInTransaction({
    required String actorUid,
    required String matchId,
    required MatchCloseTarget target,
    required String? explicitThreadId,
    required bool includeBlockDoc,
    required String? blockedUid,
    required String? blockReason,
  }) async {
    final matchRef = FirestorePaths.matchDoc(matchId);

    await _firestore.runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      final matchData = matchSnap.data();
      final matchExists = matchSnap.exists && matchData != null;

      final users = matchExists
          ? List<String>.from((matchData!['users'] as List?) ?? const [])
          : const <String>[];
      final actorIsMatchMember = users.contains(actorUid);

      final resolvedThreadId = MatchCloseLifecycleGate.resolveThreadId(
        matchId: matchId,
        matchThreadId: matchExists ? matchData!['thread_id'] as String? : null,
        explicitThreadId: explicitThreadId,
      );
      final threadRef = FirestorePaths.threadDoc(resolvedThreadId);
      final threadSnap = await tx.get(threadRef);
      final threadData = threadSnap.data();
      final threadExists = threadSnap.exists && threadData != null;
      final participants = threadExists
          ? List<String>.from(
              (threadData!['participants'] as List?) ?? const [],
            )
          : const <String>[];
      final actorIsThreadParticipant = participants.contains(actorUid);

      final plan = MatchCloseLifecycleGate.plan(
        matchExists: matchExists,
        currentMatchState:
            matchExists ? matchData!['state'] as String? : null,
        actorIsMatchMember: actorIsMatchMember,
        target: target,
        threadExists: threadExists,
        actorIsThreadParticipant: actorIsThreadParticipant,
        currentThreadStatus:
            threadExists ? threadData!['status'] as String? : null,
      );

      if (plan.refuseNotMember) {
        throw StateError('Current user is not a participant of this match.');
      }

      if (includeBlockDoc) {
        final targetUid = blockedUid;
        if (targetUid == null || targetUid.isEmpty) {
          throw StateError('blockedUid is required when writing a block.');
        }
        tx.set(
          FirestorePaths.userBlockDoc(actorUid, targetUid),
          {
            'blocked_uid': targetUid,
            'created_at': FieldValue.serverTimestamp(),
            'reason': blockReason,
          },
          SetOptions(merge: true),
        );
      }

      if (plan.updateMatch) {
        final payload = <String, dynamic>{
          'state': plan.newMatchState,
          'last_activity_at': FieldValue.serverTimestamp(),
        };
        if (target == MatchCloseTarget.unmatched) {
          payload['unmatched_by'] = actorUid;
          payload['unmatched_at'] = FieldValue.serverTimestamp();
        } else {
          payload['blocked_by'] = actorUid;
          payload['blocked_at'] = FieldValue.serverTimestamp();
        }
        tx.set(matchRef, payload, SetOptions(merge: true));
      }

      if (plan.updateThread) {
        tx.set(
          threadRef,
          {
            'status': 'closed',
            'closed_at': FieldValue.serverTimestamp(),
            'closed_by': actorUid,
            'closed_reason': plan.threadClosedReason,
          },
          SetOptions(merge: true),
        );
      }
    });
  }
}
