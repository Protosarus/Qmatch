import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';

class SafetyService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  SafetyService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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

    final batch = _firestore.batch();

    // 1) Write block doc
    batch.set(
      FirestorePaths.userBlockDoc(me.uid, blockedUid),
      {
        'blocked_uid': blockedUid,
        'created_at': FieldValue.serverTimestamp(),
        'reason': reason,
      },
      SetOptions(merge: true),
    );

    // 2) Optionally update match state
    if (matchId != null && matchId.isNotEmpty) {
      final matchSnap = await FirestorePaths.matchDoc(matchId).get();
      final matchData = matchSnap.data();
      if (matchSnap.exists && matchData != null) {
        final users = List<String>.from((matchData['users'] as List?) ?? const []);
        if (!users.contains(me.uid)) {
          throw StateError('Current user is not a participant of this match.');
        }
        batch.set(
          FirestorePaths.matchDoc(matchId),
          {
            'state': 'blocked',
            'blocked_by': me.uid,
            'blocked_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }

    // 3) Optionally close thread
    if (threadId != null && threadId.isNotEmpty) {
      final threadSnap = await FirestorePaths.threadDoc(threadId).get();
      final threadData = threadSnap.data();
      if (threadSnap.exists && threadData != null) {
        final participants =
            List<String>.from((threadData['participants'] as List?) ?? const []);
        if (!participants.contains(me.uid)) {
          throw StateError('Current user is not a participant of this thread.');
        }
        batch.set(
          FirestorePaths.threadDoc(threadId),
          {
            'status': 'closed',
            'closed_by': me.uid,
            'closed_reason': 'blocked',
            'closed_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
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
      'reason': reason,
      'details': details,
      'created_at': FieldValue.serverTimestamp(),
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
}

