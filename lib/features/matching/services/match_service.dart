import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../models/match_model.dart';
import 'match_close_lifecycle_gate.dart';
import 'like_match_atomicity_gate.dart';
import 'like_match_outcome.dart';

class MatchService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? _call;

  MatchService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    )? call,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions,
        _call = call,
        super();

  static const String likeCallableName = 'likeAndMaybeCreateMatch';

  /// Trusted Like → mutual-match evaluation (`like_match_atomicity_v1`).
  ///
  /// Client does not run the Firestore transaction. Admin callable reads
  /// match, swipes, both blocks, and both user docs; writes Like and
  /// match/thread/system_match_v1 when gates pass. Returns public outcome
  /// only — never block existence or reason.
  Future<LikeMatchOutcome> likeAndMaybeCreateMatch(String targetUid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    if (targetUid == me.uid) {
      throw StateError('Cannot create a match with yourself.');
    }

    final raw = await _invokeLikeCallable({
      'target_uid': targetUid,
    });
    return LikeMatchOutcomeMapper.fromWire(raw['outcome']);
  }

  Future<Map<String, dynamic>> _invokeLikeCallable(
    Map<String, dynamic> data,
  ) async {
    final custom = _call;
    if (custom != null) {
      return custom(likeCallableName, data);
    }
    final functions = _functions ?? FirebaseFunctions.instance;
    final result = await functions.httpsCallable(likeCallableName).call(data);
    final payload = result.data;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError('Callable $likeCallableName returned a non-map payload.');
  }

  /// Backward-compatible alias — prefer [likeAndMaybeCreateMatch].
  Future<LikeMatchOutcome> createMatchIfMutualLike(String targetUid) =>
      likeAndMaybeCreateMatch(targetUid);

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
