import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../domain/temporal_shadow.dart';

/// Runtime Firestore → temporal shadow diagnostics (debug only).
///
/// Loads thread participants + message metadata fields only for analysis.
/// Does **not** persist derived features, mutate ranking, or include bodies in
/// diagnostic outputs. Message documents may still be read by the SDK; this
/// class projects only allowed keys into the bridge.
class TemporalShadowFirestoreDiagnostics {
  TemporalShadowFirestoreDiagnostics({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    TemporalShadowDiagnosticsBridge bridge =
        const TemporalShadowDiagnosticsBridge(),
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _bridge = bridge;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final TemporalShadowDiagnosticsBridge _bridge;

  /// Collect aggregate diagnostics for the signed-in user.
  ///
  /// Returns a clear no-data state when unauthenticated or no eligible threads.
  Future<TemporalShadowAggregateDiagnostics> collectForCurrentUser({
    Duration? localTimeZoneOffset,
    int maxThreads = 40,
    int maxMessagesPerThread = 500,
  }) async {
    final me = _auth.currentUser;
    if (me == null) {
      return TemporalShadowAggregateDiagnostics.noData('not_authenticated');
    }

    final threadSnap = await _firestore
        .collection(FirestorePaths.threads().path)
        .where('participants', arrayContains: me.uid)
        .limit(maxThreads)
        .get();

    if (threadSnap.docs.isEmpty) {
      return TemporalShadowAggregateDiagnostics.noData('no_threads');
    }

    final inputs = <TemporalShadowThreadInput>[];
    for (final doc in threadSnap.docs) {
      final data = doc.data();
      final participants = List<String>.from(
        (data['participants'] as List?) ?? const [],
      );
      if (!participants.contains(me.uid)) continue;

      final msgSnap = await FirestorePaths.threadMessages(doc.id)
          .orderBy('client_created_at', descending: false)
          .limit(maxMessagesPerThread)
          .get();

      final events = <TemporalShadowEvent>[];
      for (final m in msgSnap.docs) {
        final projected = _projectMessageFields(m.data());
        final event =
            TemporalShadowDiagnosticsBridge.eventFromFirestoreMessageData(
          projected,
        );
        if (event != null) events.add(event);
      }

      inputs.add(
        TemporalShadowThreadInput(
          threadId: doc.id,
          participants: participants,
          events: events,
        ),
      );
    }

    return _bridge.analyzeThreads(
      threads: inputs,
      localTimeZoneOffset: localTimeZoneOffset,
    );
  }

  /// Keep only allow-listed message fields before bridge projection.
  static Map<String, dynamic> _projectMessageFields(
    Map<String, dynamic> raw,
  ) {
    final out = <String, dynamic>{};
    for (final key
        in TemporalShadowDiagnosticsBridgeContract.allowedMessageFieldKeys) {
      if (raw.containsKey(key)) {
        out[key] = raw[key];
      }
    }
    return out;
  }
}
