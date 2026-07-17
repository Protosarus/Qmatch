import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_paths.dart';
import 'match_service.dart';
import '../models/swipe_model.dart';

class SwipeService {
  final FirebaseAuth _auth;
  final MatchService _matchService;

  SwipeService({
    FirebaseAuth? auth,
    MatchService? matchService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _matchService = matchService ?? MatchService(auth: auth),
        super();

  Future<void> passUser(String targetUid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    if (targetUid == me.uid) {
      throw StateError('Cannot swipe on yourself.');
    }

    await FirestorePaths.userSwipeDoc(me.uid, targetUid).set({
      'from_uid': me.uid,
      'target_uid': targetUid,
      'direction': SwipeDirection.pass.name,
      'source': 'discover',
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> likeUser(String targetUid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    if (targetUid == me.uid) {
      throw StateError('Cannot swipe on yourself.');
    }

    await FirestorePaths.userSwipeDoc(me.uid, targetUid).set({
      'from_uid': me.uid,
      'target_uid': targetUid,
      'direction': SwipeDirection.like.name,
      'source': 'discover',
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return _matchService.createMatchIfMutualLike(targetUid);
  }

  Future<Set<String>> getMySwipedUserIds() async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final snap = await FirestorePaths.userSwipes(me.uid).get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<SwipeModel?> getSwipeForTarget(String targetUid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final doc = await FirestorePaths.userSwipeDoc(me.uid, targetUid).get();
    final data = doc.data();
    if (data == null) return null;
    return SwipeModel.fromFirestore(data);
  }
}
