import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../models/block_model.dart';
import '../models/report_model.dart';

class SafetyService {
  final FirebaseAuth _auth;

  SafetyService({
    FirebaseAuth? auth,
  })  : _auth = auth ?? FirebaseAuth.instance,
        super();

  Future<void> blockUser(String blockedUid, String? reason) async {
    final me = _auth.currentUser;
    if (me == null) return;

    // TODO: Also consider closing threads/matches at UI level later.
    final model = BlockModel(
      blockedUid: blockedUid,
      createdAt: Timestamp.now(),
      reason: reason,
    );
    await FirestorePaths.userBlockDoc(me.uid, blockedUid).set(
      model.toFirestore(),
      SetOptions(merge: true),
    );
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
    if (me == null) return;

    // TODO: Keep as write-only for client; admin review later.
    final ref = FirestorePaths.reports().doc();
    final model = ReportModel(
      reportId: ref.id,
      reporterUid: me.uid,
      reportedUid: reportedUid,
      matchId: matchId,
      threadId: threadId,
      messageId: messageId,
      reason: reason,
      details: details,
      createdAt: Timestamp.now(),
      status: 'new',
    );
    await ref.set(model.toFirestore());
  }

  Future<Set<String>> getMyBlockedUserIds() async {
    final me = _auth.currentUser;
    if (me == null) return <String>{};

    // TODO: paginate + cache.
    final snap = await FirestorePaths.userBlocks(me.uid).get();
    return snap.docs.map((d) => d.id).toSet();
  }
}

