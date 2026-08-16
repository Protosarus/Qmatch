import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/compatibility_scoring.dart';
import '../../../core/utils/firestore_paths.dart';
import '../../matching/services/swipe_service.dart';
import '../../safety/services/safety_service.dart';
import '../models/discover_user_model.dart';
import 'discover_canonical_20d_shadow.dart';
import 'discover_l1_eligibility_gate.dart';
import 'discover_l3_soft_preference_shadow.dart';
import 'discover_shadow_distance_attacher.dart';
import 'discover_stage_b2_dual_path_collector.dart';
import 'discover_stage_b2_trusted_l2_client.dart';

class DiscoverService {
  DiscoverService({
    FirebaseAuth? auth,
    SwipeService? swipeService,
    SafetyService? safetyService,
    Future<Map<String, dynamic>?> Function(String uid)? loadCanonicalProfile,
    DiscoverShadowDistanceAttacher? shadowAttacher,
    DiscoverL3SoftPreferenceShadowAttacher? l3ShadowAttacher,
    bool enableShadowDiagnostics = true,
    DiscoverStageB2DualPathCollector? stageB2Collector,
    bool enableStageB2DualPathCollector = false,
    bool allowStageB2OutsideDebug = false,
    DiscoverStageB2TrustedL2Client? stageB2TrustedL2Client,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _swipeService = swipeService ?? SwipeService(auth: auth),
        _safetyService = safetyService ?? SafetyService(auth: auth),
        _loadCanonicalProfile = loadCanonicalProfile,
        _shadowAttacher =
            shadowAttacher ?? const DiscoverShadowDistanceAttacher(),
        _l3ShadowAttacher =
            l3ShadowAttacher ?? const DiscoverL3SoftPreferenceShadowAttacher(),
        _enableShadowDiagnostics = enableShadowDiagnostics,
        _stageB2Collector = stageB2Collector ??
            DiscoverStageB2DualPathCollector(
              enabled: enableStageB2DualPathCollector &&
                  (kDebugMode || allowStageB2OutsideDebug),
            ),
        _allowStageB2OutsideDebug = allowStageB2OutsideDebug,
        _stageB2TrustedL2 =
            stageB2TrustedL2Client ?? DiscoverStageB2TrustedL2Client();

  final FirebaseAuth _auth;
  final SwipeService _swipeService;
  final SafetyService _safetyService;
  final Future<Map<String, dynamic>?> Function(String uid)?
      _loadCanonicalProfile;
  final DiscoverShadowDistanceAttacher _shadowAttacher;
  final DiscoverL3SoftPreferenceShadowAttacher _l3ShadowAttacher;
  final bool _enableShadowDiagnostics;
  final DiscoverStageB2DualPathCollector _stageB2Collector;
  final bool _allowStageB2OutsideDebug;
  final DiscoverStageB2TrustedL2Client _stageB2TrustedL2;

  /// In-memory shadow diagnostics from the last [getCandidates] call.
  /// Not persisted. Not used for ranking or displayed compatibility.
  Map<String, DiscoverShadowDistanceDiagnostic> lastShadowDiagnostics =
      const {};

  /// In-memory L3 soft preference shadow diagnostics (age / distance /
  /// interests) from the last [getCandidates] call.
  ///
  /// Not persisted. Never used for ranking, L1 eligibility, or UI %.
  Map<String, DiscoverL3SoftPreferencePairDiagnostic>
      lastL3SoftPreferenceDiagnostics = const {};

  /// Last Stage B2 dual-path session (null when collector disabled).
  DiscoverStageB2Session? get lastStageB2Session =>
      _stageB2Collector.lastSession;

  /// Whether Stage B2 collection is active for this service instance.
  bool get stageB2CollectorEnabled => _stageB2Collector.enabled;

  /// Export last Stage B2 session JSON (privacy-safe), or null.
  String? exportLastStageB2SessionJson({String indent = ' '}) =>
      _stageB2Collector.exportLastSessionJson(indent: indent);

  /// Export last L3 soft preference shadow map (debug), or null if empty.
  Map<String, dynamic>? exportLastL3SoftPreferenceDiagnosticsMap() {
    if (lastL3SoftPreferenceDiagnostics.isEmpty) return null;
    return {
      'export_version': 'discover_l3_soft_preference_shadow_session_v1',
      'shadow_only': true,
      'affects_discover_ranking': false,
      'is_l1_eligibility_gate': false,
      'combined_l3_score': null,
      'weights': false,
      'looking_for_active': false,
      'pair_count': lastL3SoftPreferenceDiagnostics.length,
      'pairs': [
        for (final d in lastL3SoftPreferenceDiagnostics.values)
          d.toExportMap(),
      ],
    };
  }

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
    Set<String> blockedByMe;
    try {
      blockedByMe = await _safetyService.getMyBlockedUserIds();
    } catch (_) {
      blockedByMe = <String>{};
    }

    // Prefer discover_eligible to avoid composite index needs.
    // TODO: Backfill discover_eligible for existing users if needed.
    final batchSize = (limit * 3).clamp(30, 120);
    final snapshot = await FirestorePaths.users()
        .where('discover_eligible', isEqualTo: true)
        .limit(batchSize)
        .get();

    // L1 reverse-block: candidates who blocked the viewer (hard exclude).
    Set<String> blockedMe;
    try {
      blockedMe = await _safetyService.getUidsWhoBlockedMe(
        snapshot.docs.map((d) => d.id),
      );
    } catch (_) {
      blockedMe = <String>{};
    }

    final out = <DiscoverUserModel>[];
    // Raw user-doc maps for post-rank L3 soft preference shadow only.
    final candidateUserData = <String, Map<String, dynamic>>{};
    if (_stageB2Collector.enabled) {
      _stageB2Collector.beginSession(viewerUid: currentUid);
    } else {
      _stageB2Collector.reset();
    }

    var excludedSelf = 0;
    var excludedSwiped = 0;
    var excludedBlockedByMe = 0;
    var excludedReverseBlocked = 0;
    var excludedInactive = 0;
    var excludedIncompleteProfile = 0;
    var excludedAssessmentIncomplete = 0;
    var excludedMissingPhoto = 0;

    for (final doc in snapshot.docs) {
      if (doc.id == currentUid) {
        excludedSelf++;
        continue;
      }
      if (swiped.contains(doc.id)) {
        excludedSwiped++;
        continue;
      }
      final viewerBlockedCandidate = blockedByMe.contains(doc.id);
      final candidateBlockedViewer = blockedMe.contains(doc.id);
      if (DiscoverL1EligibilityGate.excludedByBlocks(
        viewerBlockedCandidate: viewerBlockedCandidate,
        candidateBlockedViewer: candidateBlockedViewer,
      )) {
        if (viewerBlockedCandidate) {
          excludedBlockedByMe++;
        } else {
          excludedReverseBlocked++;
        }
        continue;
      }

      final data = doc.data();
      final candidate = DiscoverUserModel.fromFirestore(doc.id, data);

      if (!DiscoverL1EligibilityGate.passesLocalAccountGates(
        active: candidate.active,
        profileCompleted: candidate.profileCompleted,
        testCompleted: candidate.testCompleted,
        assessmentFlowCompleted: candidate.assessmentFlowCompleted,
        hasPhoto: candidate.hasPhoto,
      )) {
        if (!candidate.active) {
          excludedInactive++;
        } else if (!candidate.profileCompleted) {
          excludedIncompleteProfile++;
        } else if (!candidate.hasPhoto) {
          excludedMissingPhoto++;
        } else {
          excludedAssessmentIncomplete++;
        }
        continue;
      }

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

      candidateUserData[doc.id] = Map<String, dynamic>.from(data);
      out.add(
        candidate.copyWith(
          // Unavailable → null (never 0.5 filler).
          compatibilityScore: compat.available ? compat.scoreTotal : null,
          compatibilityLabel: compat.label,
          compatibilityReasons: compat.reasons,
        ),
      );
    }

    if (kDebugMode) {
      debugPrint(
        'Discover L1: fetched=${snapshot.docs.length} '
        'self=$excludedSelf swiped=$excludedSwiped '
        'blocked_by_me=$excludedBlockedByMe '
        'reverse_blocked=$excludedReverseBlocked '
        'inactive=$excludedInactive '
        'incomplete_profile=$excludedIncompleteProfile '
        'assessment_incomplete=$excludedAssessmentIncomplete '
        'missing_photo=$excludedMissingPhoto '
        'l1_eligible=${out.length}',
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
      meUserData: meData,
      rankedCandidates: out,
      candidateUserData: candidateUserData,
    );

    return out;
  }

  Future<void> _computeShadowDiagnostics({
    required String meUid,
    required Map<String, dynamic> meUserData,
    required List<DiscoverUserModel> rankedCandidates,
    required Map<String, Map<String, dynamic>> candidateUserData,
  }) async {
    final wantEqualShadow = _enableShadowDiagnostics;
    final wantStageB2 = _stageB2Collector.enabled;
    if ((!wantEqualShadow && !wantStageB2) || rankedCandidates.isEmpty) {
      lastShadowDiagnostics = const {};
      lastL3SoftPreferenceDiagnostics = const {};
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

        final l3Attached = _l3ShadowAttacher.attach(
          meUserData: meUserData,
          rankedCandidates: rankedCandidates,
          candidateUserData: candidateUserData,
        );
        lastL3SoftPreferenceDiagnostics = l3Attached.diagnostics;

        // attached.candidates must keep live compat; assert in debug only.
        assert(attached.candidates.length == rankedCandidates.length);
        assert(l3Attached.candidates.length == rankedCandidates.length);
        assert(() {
          for (var i = 0; i < rankedCandidates.length; i++) {
            final before = rankedCandidates[i];
            final after = attached.candidates[i];
            final afterL3 = l3Attached.candidates[i];
            if (before.uid != after.uid ||
                before.uid != afterL3.uid ||
                before.compatibilityScore != after.compatibilityScore ||
                before.compatibilityScore != afterL3.compatibilityScore ||
                before.compatibilityLabel != after.compatibilityLabel ||
                before.compatibilityLabel != afterL3.compatibilityLabel) {
              return false;
            }
          }
          return true;
        }());
      } else {
        lastShadowDiagnostics = const {};
        lastL3SoftPreferenceDiagnostics = const {};
      }

      if (wantStageB2) {
        final uids = rankedCandidates.map((c) => c.uid).toList(growable: false);
        List<DiscoverStageB2TrustedPairResult> trusted;
        try {
          trusted = await _stageB2TrustedL2.compareForL1Batch(
            candidateUids: uids,
          );
        } catch (e, st) {
          debugPrint('Discover Stage B2 trusted L2 skipped: $e\n$st');
          trusted = [
            for (final _ in uids)
              DiscoverStageB2TrustedPairResult.unavailable(
                'trusted_l2_callable_failed',
              ),
          ];
        }
        _stageB2Collector.finalizeTrustedBatch(
          rankedCandidates: rankedCandidates,
          trustedPairs: trusted,
        );
      }
    } catch (e, st) {
      debugPrint('Discover shadow 20D diagnostics skipped: $e\n$st');
      lastShadowDiagnostics = const {};
      lastL3SoftPreferenceDiagnostics = const {};
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
