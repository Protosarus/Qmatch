import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../../matching/services/match_close_lifecycle_gate.dart';
import '../../matching/services/match_service.dart';

class SafetyService {
  final FirebaseAuth _auth;
  final MatchService _matchService;

  SafetyService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    MatchService? matchService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _matchService = matchService ??
            MatchService(auth: auth, firestore: firestore);

  /// Block [blockedUid] and atomically close match+thread when known.
  ///
  /// Uses one Firestore transaction (block doc + match/thread close).
  /// Idempotent if already blocked/closed. Never reactivates.
  Future<void> blockUser({
    required String blockedUid,
    String? reason,
    String? matchId,
    String? threadId,
  }) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    if (blockedUid == me.uid) {
      throw StateError('Cannot block yourself.');
    }

    // Deterministic ids: threadId mirrors matchId when present.
    final effectiveMatchId = _effectiveMatchId(matchId, threadId);

    if (effectiveMatchId != null) {
      await _matchService.closeRelationshipInTransaction(
        actorUid: me.uid,
        matchId: effectiveMatchId,
        target: MatchCloseTarget.blocked,
        explicitThreadId: threadId,
        includeBlockDoc: true,
        blockedUid: blockedUid,
        blockReason: reason,
      );
      return;
    }

    // No match/thread context — block doc only.
    await FirestorePaths.userBlockDoc(me.uid, blockedUid).set(
      {
        'blocked_uid': blockedUid,
        'created_at': FieldValue.serverTimestamp(),
        'reason': reason,
      },
      SetOptions(merge: true),
    );
  }

  static String? _effectiveMatchId(String? matchId, String? threadId) {
    final m = matchId?.trim();
    if (m != null && m.isNotEmpty) return m;
    final t = threadId?.trim();
    if (t != null && t.isNotEmpty) return t;
    return null;
  }

  Future<void> reportUser({
    required String reportedUid,
    required String reason,
    String? details,
    String? matchId,
    String? threadId,
    String? messageId,
  }) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    if (reportedUid == me.uid) {
      throw StateError('Cannot report yourself.');
    }

    final ref = FirestorePaths.reports().doc();
    await ref.set({
      'reporter_uid': me.uid,
      'reported_uid': reportedUid,
      'match_id': matchId,
      'thread_id': threadId,
      'message_id': messageId,
      'created_at': FieldValue.serverTimestamp(),
      'reason': reason,
      'details': details,
      'status': 'new',
      'report_id': ref.id,
    });
  }

  Future<Set<String>> getMyBlockedUserIds() async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final snap = await FirestorePaths.userBlocks(me.uid).get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<bool> hasBlockedUser(String uid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    final doc = await FirestorePaths.userBlockDoc(me.uid, uid).get();
    return doc.exists;
  }

  /// True when [otherUid] has blocked the current user (reverse-block).
  ///
  /// L1 hard safety gate — Discover must exclude such candidates.
  Future<bool> isBlockedByUser(String otherUid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    if (otherUid == me.uid) return false;
    final doc = await FirestorePaths.userBlockDoc(otherUid, me.uid).get();
    return doc.exists;
  }

  /// Returns the subset of [candidateUids] who have blocked the current user.
  Future<Set<String>> getUidsWhoBlockedMe(
    Iterable<String> candidateUids,
  ) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    final uids = candidateUids.toList(growable: false);
    if (uids.isEmpty) return <String>{};

    final results = await Future.wait(
      uids.map((uid) async {
        if (uid == me.uid) return null;
        final doc = await FirestorePaths.userBlockDoc(uid, me.uid).get();
        return doc.exists ? uid : null;
      }),
    );
    return results.whereType<String>().toSet();
  }
}
