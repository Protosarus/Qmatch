import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/compatibility_scoring.dart';
import '../../../core/utils/firestore_paths.dart';
import '../../matching/services/swipe_service.dart';
import '../../safety/services/safety_service.dart';
import '../models/discover_user_model.dart';

class DiscoverService {
  final FirebaseAuth _auth;
  final SwipeService _swipeService;
  final SafetyService _safetyService;

  DiscoverService({
    FirebaseAuth? auth,
    SwipeService? swipeService,
    SafetyService? safetyService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _swipeService = swipeService ?? SwipeService(auth: auth),
        _safetyService = safetyService ?? SafetyService(auth: auth);

  /// Loads candidate profiles for Discover (simple query + local filters).
  Future<List<DiscoverUserModel>> getCandidates({int limit = 30}) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }
    final currentUid = me.uid;

    final meDoc = await FirestorePaths.userDoc(currentUid).get();
    final meData = meDoc.data() ?? <String, dynamic>{};

    final swiped = await _swipeService.getMySwipedUserIds();
    Set<String> blocked;
    try {
      blocked = await _safetyService.getMyBlockedUserIds();
    } catch (_) {
      blocked = <String>{};
    }
    // TODO: Server-side enforcement is needed later to fully exclude users who blocked the current user.

    // Simple index-friendly query; local filters remove many rows — fetch a bit more than [limit].
    final batchSize = (limit * 3).clamp(30, 120);
    final snapshot = await FirestorePaths.users()
        .where('test_completed', isEqualTo: true)
        .where('profile_completed', isEqualTo: true)
        .limit(batchSize)
        .get();

    final out = <DiscoverUserModel>[];

    for (final doc in snapshot.docs) {
      if (doc.id == currentUid) continue;
      if (swiped.contains(doc.id)) continue;
      if (blocked.contains(doc.id)) continue;

      final data = doc.data();
      final candidate = DiscoverUserModel.fromFirestore(doc.id, data);

      if (candidate.active == false) continue;
      if (!candidate.testCompleted || !candidate.profileCompleted) continue;
      if (!candidate.hasPhoto) continue;

      final compat = CompatibilityScoring.calculateCompatibility(
        me: meData,
        candidate: {
          ...data,
          // Provide DateTime for recencyScore helper
          'last_active_at': (data['last_active_at'] is Timestamp)
              ? (data['last_active_at'] as Timestamp).toDate()
              : null,
        },
      );

      out.add(
        candidate.copyWith(
          compatibilityScore: compat.scoreTotal,
          compatibilityLabel: compat.label,
          compatibilityReasons: compat.reasons,
        ),
      );
    }

    out.sort((a, b) {
      final aScore = a.compatibilityScore ?? 0.5;
      final bScore = b.compatibilityScore ?? 0.5;
      final byScore = bScore.compareTo(aScore);
      if (byScore != 0) return byScore;

      final aTs = a.lastActiveAt?.millisecondsSinceEpoch ?? 0;
      final bTs = b.lastActiveAt?.millisecondsSinceEpoch ?? 0;
      return bTs.compareTo(aTs);
    });

    return out;
  }
}
