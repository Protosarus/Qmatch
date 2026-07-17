import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../models/reveal_state_model.dart';

class RevealService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  RevealService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<RevealStateModel?> getRevealState(String matchId) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final doc = await FirestorePaths.matchDoc(matchId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;

    final users = List<String>.from((data['users'] as List?) ?? const []);
    if (!users.contains(me.uid)) {
      throw StateError('Current user is not a participant of this match.');
    }

    return RevealStateModel.fromMap((data['reveal'] as Map?)?.cast<String, dynamic>());
  }

  Stream<RevealStateModel> getRevealStateStream(String matchId) {
    final me = _auth.currentUser;
    if (me == null) {
      return Stream<RevealStateModel>.error(StateError('User is not authenticated.'));
    }

    return FirestorePaths.matchDoc(matchId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return const RevealStateModel();

      final users = List<String>.from((data['users'] as List?) ?? const []);
      if (!users.contains(me.uid)) {
        throw StateError('Current user is not a participant of this match.');
      }

      final reveal = RevealStateModel.fromMap(
        (data['reveal'] as Map?)?.cast<String, dynamic>(),
      );

      // Safety: if revealedAt is set or both consents true -> treat as fully revealed.
      if (reveal.revealedAt != null || (reveal.consentA && reveal.consentB)) {
        return reveal.copyWith(blurLevel: 0);
      }

      return reveal;
    });
  }

  Future<int> updateBlurProgressFromMessages({
    required String matchId,
    required String threadId,
  }) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final matchSnap = await FirestorePaths.matchDoc(matchId).get();
    final matchData = matchSnap.data();
    if (!matchSnap.exists || matchData == null) {
      throw StateError('Match not found.');
    }

    final matchUsers = List<String>.from((matchData['users'] as List?) ?? const []);
    final userA = (matchData['user_a'] as String?) ?? (matchUsers.isNotEmpty ? matchUsers.first : '');
    final userB = (matchData['user_b'] as String?) ?? (matchUsers.length > 1 ? matchUsers[1] : '');
    if (!matchUsers.contains(me.uid)) {
      throw StateError('Current user is not a participant of this match.');
    }
    final matchState = (matchData['state'] as String?) ?? 'active';
    if (matchState != 'active') {
      return RevealStateModel.fromMap((matchData['reveal'] as Map?)?.cast<String, dynamic>())
          .blurLevel;
    }

    final threadSnap = await FirestorePaths.threadDoc(threadId).get();
    final threadData = threadSnap.data();
    if (!threadSnap.exists || threadData == null) {
      throw StateError('Thread not found.');
    }
    final participants = List<String>.from((threadData['participants'] as List?) ?? const []);
    if (!participants.contains(me.uid)) {
      throw StateError('Current user is not a participant of this thread.');
    }

    final current = RevealStateModel.fromMap((matchData['reveal'] as Map?)?.cast<String, dynamic>());
    final currentBlur = current.blurLevel.clamp(0, 3);

    // Never override full reveal.
    if (current.revealedAt != null || (current.consentA && current.consentB)) {
      if (currentBlur != 0) {
        await FirestorePaths.matchDoc(matchId).set(
          {
            'reveal': {
              'blur_level': 0,
            },
          },
          SetOptions(merge: true),
        );
      }
      return 0;
    }

    // Use thread-level counters (no message subcollection scan).
    final totalText = (threadData['text_count_total'] as num?)?.toInt() ?? 0;
    final byUidRaw = (threadData['text_count_by_uid'] as Map?)?.cast<String, dynamic>() ?? const {};
    final aCount = (byUidRaw[userA] as num?)?.toInt() ?? 0;
    final bCount = (byUidRaw[userB] as num?)?.toInt() ?? 0;

    int suggested = 3;
    if (totalText >= 5) suggested = 2;
    if (totalText >= 10 && aCount >= 2 && bCount >= 2) suggested = 1;

    // Only lower the blur level (never increase).
    if (suggested < currentBlur) {
      await FirestorePaths.matchDoc(matchId).set(
        {
          'reveal': {
            'blur_level': suggested,
          },
        },
        SetOptions(merge: true),
      );
      return suggested;
    }

    return currentBlur;
  }

  Future<void> requestReveal(String matchId) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final matchSnap = await FirestorePaths.matchDoc(matchId).get();
    final data = matchSnap.data();
    if (!matchSnap.exists || data == null) {
      throw StateError('Match not found.');
    }

    final matchState = (data['state'] as String?) ?? 'active';
    if (matchState != 'active') {
      throw StateError('Match is not active.');
    }

    final users = List<String>.from((data['users'] as List?) ?? const []);
    final userA = data['user_a'] as String?;
    final userB = data['user_b'] as String?;
    if (!users.contains(me.uid) || userA == null || userB == null) {
      throw StateError('Current user is not a participant of this match.');
    }

    final current = RevealStateModel.fromMap((data['reveal'] as Map?)?.cast<String, dynamic>());
    final blur = current.blurLevel.clamp(0, 3);
    if (blur > 1) {
      throw StateError('Reveal is not available yet.');
    }

    final iAmA = me.uid == userA;
    final nextConsentA = iAmA ? true : current.consentA;
    final nextConsentB = iAmA ? current.consentB : true;
    final bothConsented = nextConsentA && nextConsentB;

    final update = <String, dynamic>{
      'reveal.requested_by': me.uid,
      'reveal.requested_at': FieldValue.serverTimestamp(),
      'reveal.consent_a': nextConsentA,
      'reveal.consent_b': nextConsentB,
    };

    if (bothConsented) {
      update['reveal.blur_level'] = 0;
      update['reveal.revealed_at'] = FieldValue.serverTimestamp();
    }

    await FirestorePaths.matchDoc(matchId).update(update);
  }

  Future<void> acceptReveal(String matchId) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    await _firestore.runTransaction((tx) async {
      final ref = FirestorePaths.matchDoc(matchId);
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw StateError('Match not found.');
      }

      final matchState = (data['state'] as String?) ?? 'active';
      if (matchState != 'active') {
        throw StateError('Match is not active.');
      }

      final users = List<String>.from((data['users'] as List?) ?? const []);
      final userA = data['user_a'] as String?;
      final userB = data['user_b'] as String?;
      if (!users.contains(me.uid) || userA == null || userB == null) {
        throw StateError('Current user is not a participant of this match.');
      }

      final current = RevealStateModel.fromMap((data['reveal'] as Map?)?.cast<String, dynamic>());
      final iAmA = me.uid == userA;
      final nextConsentA = iAmA ? true : current.consentA;
      final nextConsentB = iAmA ? current.consentB : true;
      final bothConsented = nextConsentA && nextConsentB;

      final update = <String, dynamic>{
        'reveal.consent_a': nextConsentA,
        'reveal.consent_b': nextConsentB,
      };

      if (bothConsented) {
        update['reveal.blur_level'] = 0;
        update['reveal.revealed_at'] = FieldValue.serverTimestamp();
      }

      tx.update(ref, update);
    });
  }

  Future<void> rejectReveal(String matchId) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final matchSnap = await FirestorePaths.matchDoc(matchId).get();
    final data = matchSnap.data();
    if (!matchSnap.exists || data == null) {
      throw StateError('Match not found.');
    }

    final matchState = (data['state'] as String?) ?? 'active';
    if (matchState != 'active') {
      throw StateError('Match is not active.');
    }

    final users = List<String>.from((data['users'] as List?) ?? const []);
    if (!users.contains(me.uid)) {
      throw StateError('Current user is not a participant of this match.');
    }

    final current = RevealStateModel.fromMap((data['reveal'] as Map?)?.cast<String, dynamic>());
    // Only the non-requester can clear the pending request.
    if (current.requestedBy != null && current.requestedBy != me.uid) {
      await FirestorePaths.matchDoc(matchId).update({
        'reveal.requested_by': null,
        'reveal.requested_at': null,
      });
    }
  }

  Future<int> getBlurLevel(String matchId) async {
    final state = await getRevealState(matchId);
    return state?.blurLevel.clamp(0, 3) ?? 3;
  }

  Future<bool> canShowClearPhoto(String matchId) async {
    final state = await getRevealState(matchId);
    if (state == null) return false;
    final blurOk = (state.blurLevel.clamp(0, 3) == 0);
    final consentOk = (state.consentA && state.consentB) || state.revealedAt != null;
    return blurOk && consentOk;
  }
}
