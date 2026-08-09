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
    final meData =
        Map<String, dynamic>.from(meDoc.data() ?? <String, dynamic>{});

    // Frequency fallback: hydrate type/tags/score/vector from assessments/frequency
    // when user-doc mirrors are missing (legacy users).
    if (meData['frequency_type'] == null ||
        meData['frequency_tags'] == null ||
        meData['frequency_vector'] == null) {
      try {
        final freqDoc = await FirestorePaths.userDoc(currentUid)
            .collection('assessments')
            .doc('frequency')
            .get();
        final freq = freqDoc.data();
        if (freq != null) {
          final status = freq['status'] as String?;
          final ready = freq['canonical_profile_ready'] as bool? ?? false;
          final type = freq['type'] ?? freq['frequency_type'];
          // Never hydrate "Incomplete Frequency" / null type into mirrors.
          if (status != 'incomplete' &&
              ready &&
              type is String &&
              type.isNotEmpty &&
              type != 'Incomplete Frequency') {
            meData['frequency_type'] ??= type;
          }
          meData['frequency_tags'] ??= freq['tags'] ?? freq['frequency_tags'];
          if (status != 'incomplete' && ready) {
            meData['frequency_score'] ??= freq['scoreTotal'] ??
                freq['score_total'] ??
                freq['frequency_score'];
          }
          meData['frequency_vector'] ??=
              freq['vector'] ?? freq['frequency_vector'];
        }
      } catch (_) {
        // ignore for MVP
      }
    }

    final swiped = await _swipeService.getMySwipedUserIds();
    Set<String> blocked;
    try {
      blocked = await _safetyService.getMyBlockedUserIds();
    } catch (_) {
      blocked = <String>{};
    }
    // TODO: Server-side enforcement is needed later to fully exclude users who blocked the current user.

    // Prefer discover_eligible to avoid composite index needs.
    // TODO: Backfill discover_eligible for existing users if needed.
    final batchSize = (limit * 3).clamp(30, 120);
    final snapshot = await FirestorePaths.users()
        .where('discover_eligible', isEqualTo: true)
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
          // Unavailable → null (never 0.5 filler).
          compatibilityScore: compat.available ? compat.scoreTotal : null,
          compatibilityLabel: compat.label,
          compatibilityReasons: compat.reasons,
        ),
      );
    }

    // Temporary ordering (P1B-1.1): available compat first (desc), then
    // unavailable by recency. Does not pretend 50% compatibility.
    out.sort((a, b) {
      return CompatibilityScoring.compareDiscoverCandidates(
        aScore: a.compatibilityScore,
        bScore: b.compatibilityScore,
        aLastActiveMs: a.lastActiveAt?.millisecondsSinceEpoch ?? 0,
        bLastActiveMs: b.lastActiveAt?.millisecondsSinceEpoch ?? 0,
      );
    });

    return out;
  }
}
