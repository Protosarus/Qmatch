import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/firestore_paths.dart';
import 'match_service.dart';
import '../models/swipe_model.dart';
import 'like_match_atomicity_gate.dart';
import 'like_match_outcome.dart';

class SwipeService {
  final FirebaseAuth _auth;
  final MatchService _matchService;
  final FirebaseFunctions? _functions;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? _call;

  SwipeService({
    FirebaseAuth? auth,
    MatchService? matchService,
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    )? call,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _matchService = matchService ?? MatchService(auth: auth),
        _functions = functions,
        _call = call,
        super();

  // Legacy callable contract — preserved for compatibility/test injection.
  static const String rewindCallableName = 'rewindPass';
  static const String rewindLikeCallableName = 'rewindLike';

  // Current production endpoints, colocated with Firestore.
  static const String rewindCallableNameEu = 'rewindPassEu';
  static const String rewindLikeCallableNameEu = 'rewindLikeEu';
  static const String rewindCallableRegionEu = 'europe-west1';

  /// Pass: swipe-only write. Never mutates match/thread.
  Future<void> passUser(String targetUid) async {
    assert(
      !LikeMatchAtomicityGate.passMayMutateMatchOrThread(),
      'Pass must never mutate match/thread',
    );
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

  /// Like: trusted callable persists Like + evaluates mutual match.
  Future<LikeMatchResult> likeUser(String targetUid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    if (targetUid == me.uid) {
      throw StateError('Cannot swipe on yourself.');
    }

    return _matchService.likeAndMaybeCreateMatch(targetUid);
  }

  /// Rewinds only the authenticated user's own most-recently selected
  /// Discover Pass supplied by the caller.
  ///
  /// The trusted backend verifies that the stored swipe is actually a
  /// Discover `pass`. Likes, matches, threads and Super Resonance data are
  /// never deleted by this client.
  Future<bool> rewindPass(String targetUid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final normalizedTargetUid = targetUid.trim();
    if (normalizedTargetUid.isEmpty) {
      throw StateError('targetUid is required.');
    }
    if (normalizedTargetUid == me.uid) {
      throw StateError('Cannot Rewind yourself.');
    }

    final raw = await _invokeRewindCallable({
      'target_uid': normalizedTargetUid,
    });

    if (raw['rewound'] != true) {
      throw StateError(
        'Callable $rewindCallableName did not confirm the Rewind.',
      );
    }

    return true;
  }

  Future<Map<String, dynamic>> _invokeRewindCallable(
    Map<String, dynamic> data,
  ) {
    return _invokeCallable(rewindCallableName, data);
  }

  Future<Map<String, dynamic>> _invokeCallable(
    String callableName,
    Map<String, dynamic> data,
  ) async {
    final custom = _call;
    if (custom != null) {
      return custom(callableName, data);
    }

    final productionName = switch (callableName) {
      rewindCallableName => rewindCallableNameEu,
      rewindLikeCallableName => rewindLikeCallableNameEu,
      _ => callableName,
    };

    final functions = _functions ??
        FirebaseFunctions.instanceFor(
          region: rewindCallableRegionEu,
        );

    final result = await functions.httpsCallable(productionName).call(data);
    final payload = result.data;

    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }

    throw StateError(
      'Callable $callableName returned a non-map payload.',
    );
  }

  /// Rewinds the authenticated user's own one-sided Discover Like.
  ///
  /// The trusted backend refuses the operation if Match, Thread, or
  /// match-system-message artifacts already exist.
  Future<bool> rewindLike(String targetUid) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final normalizedTargetUid = targetUid.trim();
    if (normalizedTargetUid.isEmpty) {
      throw StateError('targetUid is required.');
    }
    if (normalizedTargetUid == me.uid) {
      throw StateError('Cannot Rewind yourself.');
    }

    final raw = await _invokeCallable(
      rewindLikeCallableName,
      {
        'target_uid': normalizedTargetUid,
      },
    );

    if (raw['rewound'] != true) {
      throw StateError(
        'Callable $rewindLikeCallableName did not confirm the Rewind.',
      );
    }

    return true;
  }

  Future<Set<String>> getMySwipedUserIds() async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final snapshot = await FirestorePaths.userSwipes(me.uid).get();
    debugPrint(
      'Discover swipe ids=${snapshot.docs.map((d) => d.id).toList()}',
    );
    return snapshot.docs.map((d) => d.id).toSet();
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
