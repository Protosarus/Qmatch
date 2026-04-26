import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';

class RevealService {
  final FirebaseAuth _auth;

  RevealService({
    FirebaseAuth? auth,
  })  : _auth = auth ?? FirebaseAuth.instance,
        super();

  Future<void> requestReveal(String matchId) async {
    final me = _auth.currentUser;
    if (me == null) return;

    // TODO: Set reveal.requested_by/requested_at and mark consent for requester.
    await FirestorePaths.matchDoc(matchId).set(
      {
        'reveal': {
          'requested_by': me.uid,
          'requested_at': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
  }

  Future<void> acceptReveal(String matchId) async {
    final me = _auth.currentUser;
    if (me == null) return;

    // TODO: Determine whether me is user_a/user_b and set consent_a/consent_b accordingly.
    // For now, just record an acceptance marker; rules/business logic will tighten later.
    await FirestorePaths.matchDoc(matchId).set(
      {
        'reveal': {
          'accepted_by': me.uid,
          'accepted_at': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
  }

  Future<void> rejectReveal(String matchId) async {
    final me = _auth.currentUser;
    if (me == null) return;

    // TODO: Clear request + record rejection.
    await FirestorePaths.matchDoc(matchId).set(
      {
        'reveal': {
          'rejected_by': me.uid,
          'rejected_at': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
  }

  Future<int> getBlurLevel(String matchId) async {
    final me = _auth.currentUser;
    if (me == null) return 3;

    // TODO: Read match reveal.blur_level; default 3.
    final doc = await FirestorePaths.matchDoc(matchId).get();
    final data = doc.data();
    final reveal = (data?['reveal'] as Map?)?.cast<String, dynamic>();
    return (reveal?['blur_level'] as num?)?.toInt() ?? 3;
  }

  Future<bool> canShowClearPhoto(String matchId) async {
    // TODO: Use both consents + blur_level == 0.
    final blur = await getBlurLevel(matchId);
    return blur <= 0;
  }
}

