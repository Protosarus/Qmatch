import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../models/match_model.dart';

class MatchService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  MatchService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super();

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

    final reverseSwipeRef = FirestorePaths.userSwipeDoc(targetUid, currentUid);
    final matchRef = FirestorePaths.matchDoc(matchId);
    final threadRef = FirestorePaths.threadDoc(threadId);
    final messageRef = FirestorePaths.threadMessages(threadId).doc();

    return _firestore.runTransaction((tx) async {
      // 1) Check if already matched
      final matchSnap = await tx.get(matchRef);
      if (matchSnap.exists) {
        return true;
      }

      // 2) Check mutual like (reverse swipe must exist and be "like")
      final reverseSwipeSnap = await tx.get(reverseSwipeRef);
      final reverseData = reverseSwipeSnap.data();
      final reverseDirection = reverseData?['direction'] as String?;
      if (reverseDirection != 'like') {
        return false;
      }

      // 3) Create match doc
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

      // 4) Create thread doc
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

      // 5) Optional first system message
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

  Future<void> unmatch(String matchId) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final matchRef = FirestorePaths.matchDoc(matchId);
    final snap = await matchRef.get();
    final data = snap.data();
    if (data == null) return;

    final users = List<String>.from((data['users'] as List?) ?? const []);
    if (!users.contains(me.uid)) {
      throw StateError('Current user is not a participant of this match.');
    }

    final threadId = data['thread_id'] as String?;

    await matchRef.set({
      'state': MatchState.unmatched.name,
      'last_activity_at': FieldValue.serverTimestamp(),
      'unmatched_by': me.uid,
      'unmatched_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (threadId != null && threadId.isNotEmpty) {
      await FirestorePaths.threadDoc(threadId).set(
        {
          'status': 'closed',
          'closed_at': FieldValue.serverTimestamp(),
          'closed_by': me.uid,
          'closed_reason': 'unmatched',
        },
        SetOptions(merge: true),
      );
    }
  }
}

