import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../models/activity_event_model.dart';

class ActivityService {
  ActivityService({
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<List<ActivityEventModel>> getMyActivityStream() {
    final me = _auth.currentUser;

    if (me == null) {
      return Stream<List<ActivityEventModel>>.error(
        StateError('User is not authenticated.'),
      );
    }

    return FirestorePaths.userActivityFeed(me.uid)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ActivityEventModel.fromFirestore(
                  doc.id,
                  doc.data(),
                ),
              )
              .where(
                (event) =>
                    event.actorUid.isNotEmpty &&
                    event.type != ActivityEventType.unknown,
              )
              .toList(growable: false),
        );
  }
}
