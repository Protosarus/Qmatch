import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/compatibility_scoring.dart';
import '../../../core/utils/firestore_paths.dart';
import '../../matching/services/swipe_service.dart';
import '../../safety/services/safety_service.dart';
import '../models/discover_user_model.dart';
import 'discover_canonical_20d_shadow.dart';
import 'discover_shadow_distance_attacher.dart';
import 'discover_stage_b2_dual_path_collector.dart';

class DiscoverService {
  DiscoverService({
    FirebaseAuth? auth,
    SwipeService? swipeService,
    SafetyService? safetyService,
    Future<Map<String, dynamic>?> Function(String uid)? loadCanonicalProfile,
    DiscoverShadowDistanceAttacher? shadowAttacher,
    bool enableShadowDiagnostics = true,
    DiscoverStageB2DualPathCollector? stageB2Collector,
    bool enableStageB2DualPathCollector = false,
    bool allowStageB2OutsideDebug = false,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _swipeService = swipeService ?? SwipeService(auth: auth),
        _safetyService = safetyService ?? SafetyService(auth: auth),
        _loadCanonicalProfile = loadCanonicalProfile,
        _shadowAttacher =
            shadowAttacher ?? const DiscoverShadowDistanceAttacher(),
        _enableShadowDiagnostics = enableShadowDiagnostics,
        _stageB2Collector = stageB2Collector ??
            DiscoverStageB2DualPathCollector(
              enabled: enableStageB2DualPathCollector &&
                  (kDebugMode || allowStageB2OutsideDebug),
            ),
        _allowStageB2OutsideDebug = allowStageB2OutsideDebug;

  final FirebaseAuth _auth;
  final SwipeService _swipeService;
  final SafetyService _safetyService;
  final Future<Map<String, dynamic>?> Function(String uid)?
      _loadCanonicalProfile;
  final DiscoverShadowDistanceAttacher _shadowAttacher;
  final bool _enableShadowDiagnostics;
  final DiscoverStageB2DualPathCollector _stageB2Collector;
  final bool _allowStageB2OutsideDebug;

  /// In-memory shadow diagnostics from the last [getCandidates] call.
  /// Not persisted. Not used for ranking or displayed compatibility.
  Map<String, DiscoverShadowDistanceDiagnostic> lastShadowDiagnostics =
      const {};

  /// Last Stage B2 dual-path session (null when collector disabled).
  DiscoverStageB2Session? get lastStageB2Session =>
      _stageB2Collector.lastSession;

  /// Whether Stage B2 collection is active for this service instance.
  bool get stageB2CollectorEnabled => _stageB2Collector.enabled;

  /// Export last Stage B2 session JSON (privacy-safe), or null.
  String? exportLastStageB2SessionJson({String indent = ' '}) =>
      _stageB2Collector.exportLastSessionJson(indent: indent);

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
    if (_stageB2Collector.enabled) {
      _stageB2Collector.beginSession(viewerUid: currentUid);
    } else {
      _stageB2Collector.reset();
    }

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

      if (_stageB2Collector.enabled) {
        _stageB2Collector.recordLegacyPair(
          candidateUid: doc.id,
          legacyAvailable: compat.available,
          legacyScore: compat.scoreTotal,
          legacyMissingReason: compat.reason,
        );
      }

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

    // Shadow diagnostics AFTER legacy ranking — never reorder / rescore.
    await _computeShadowDiagnostics(
      meUid: currentUid,
      rankedCandidates: out,
    );

    return out;
  }

  Future<void> _computeShadowDiagnostics({
    required String meUid,
    required List<DiscoverUserModel> rankedCandidates,
  }) async {
    final wantEqualShadow = _enableShadowDiagnostics;
    final wantStageB2 = _stageB2Collector.enabled;
    if ((!wantEqualShadow && !wantStageB2) || rankedCandidates.isEmpty) {
      lastShadowDiagnostics = const {};
      if (!wantStageB2) _stageB2Collector.reset();
      return;
    }

    try {
      final meProfile = await _canonicalProfile(meUid);
      final candidateProfiles = <String, Map<String, dynamic>?>{};

      // Parallel reads only for already-selected candidates (not the raw query
      // batch). Failures become null profiles → no diagnostic for that uid.
      final uids = rankedCandidates.map((c) => c.uid).toList(growable: false);
      final loaded = await Future.wait(
        uids.map((uid) async {
          try {
            return MapEntry(uid, await _canonicalProfile(uid));
          } catch (_) {
            return MapEntry(uid, null);
          }
        }),
      );
      for (final e in loaded) {
        candidateProfiles[e.key] = e.value;
      }

      if (wantEqualShadow) {
        final attached = _shadowAttacher.attach(
          rankedCandidates: rankedCandidates,
          meCanonicalProfile: meProfile,
          candidateCanonicalProfiles: candidateProfiles,
        );
        lastShadowDiagnostics = attached.diagnostics;

        // attached.candidates must keep live compat; assert in debug only.
        assert(attached.candidates.length == rankedCandidates.length);
        assert(() {
          for (var i = 0; i < rankedCandidates.length; i++) {
            final before = rankedCandidates[i];
            final after = attached.candidates[i];
            if (before.uid != after.uid ||
                before.compatibilityScore != after.compatibilityScore ||
                before.compatibilityLabel != after.compatibilityLabel) {
              return false;
            }
          }
          return true;
        }());
      } else {
        lastShadowDiagnostics = const {};
      }

      if (wantStageB2) {
        _stageB2Collector.finalizeBatch(
          rankedCandidates: rankedCandidates,
          meCanonicalProfile: meProfile,
          candidateCanonicalProfiles: candidateProfiles,
        );
      }
    } catch (e, st) {
      debugPrint('Discover shadow 20D diagnostics skipped: $e\n$st');
      lastShadowDiagnostics = const {};
      if (wantStageB2) {
        _stageB2Collector.reset();
      }
    }
  }

  Future<Map<String, dynamic>?> _canonicalProfile(String uid) async {
    final custom = _loadCanonicalProfile;
    if (custom != null) return custom(uid);
    final snap = await FirestorePaths.userCanonicalProfileDoc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  /// Exposed for tests: Stage B2 is gated by debug/internal flags.
  @visibleForTesting
  bool get debugAllowStageB2OutsideDebug => _allowStageB2OutsideDebug;
}
