import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/debug/qmatch_perf.dart';
import '../../../core/utils/compatibility_scoring.dart';
import '../../../core/utils/firestore_paths.dart';
import '../../matching/domain/l3_soft_preference_signal.dart';
import '../../matching/services/swipe_service.dart';
import '../../safety/services/safety_service.dart';
import '../domain/discover_eligible_query_plan.dart';
import '../domain/discover_passport_snapshot.dart';
import '../models/discover_user_model.dart';
import 'discover_canonical_20d_shadow.dart';
import 'discover_l1_eligibility_gate.dart';
import 'discover_l3_soft_preference_shadow.dart';
import 'discover_passport_client.dart';
import 'discover_ranking_mode.dart';
import 'discover_shadow_distance_attacher.dart';
import 'discover_stage_b2_dual_path_collector.dart';
import 'discover_stage_b2_trusted_l2_client.dart';
import 'discover_structural_l2_ranking.dart';

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
    DiscoverRankingMode rankingMode = DiscoverRankingMode.active,
    DiscoverPassportClient? passportClient,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _swipeService = swipeService ?? SwipeService(auth: auth),
        _safetyService = safetyService ?? SafetyService(auth: auth),
        _loadCanonicalProfile = loadCanonicalProfile,
        _shadowAttacher =
            shadowAttacher ?? const DiscoverShadowDistanceAttacher(),
        _l3ShadowAttacher =
            l3ShadowAttacher ?? const DiscoverL3SoftPreferenceShadowAttacher(),
        // Peer canonical_v1 GETs are debug-only. Release never attempts them.
        _enableShadowDiagnostics = enableShadowDiagnostics && kDebugMode,
        _stageB2Collector = stageB2Collector ??
            DiscoverStageB2DualPathCollector(
              enabled: enableStageB2DualPathCollector &&
                  (kDebugMode || allowStageB2OutsideDebug),
            ),
        _allowStageB2OutsideDebug = allowStageB2OutsideDebug,
        _stageB2TrustedL2 =
            stageB2TrustedL2Client ?? DiscoverStageB2TrustedL2Client(),
        _rankingMode = rankingMode,
        _passportClient = passportClient ?? DiscoverPassportClient();

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
  final DiscoverRankingMode _rankingMode;
  final DiscoverPassportClient _passportClient;
  int _shadowGeneration = 0;

  /// Active ranking mode for this service instance.
  DiscoverRankingMode get rankingMode => _rankingMode;

  /// Last trusted Passport snapshot used for Discover eligibility.
  DiscoverPassportSnapshot lastPassportSnapshot =
      DiscoverPassportSnapshot.worldwide;

  /// Last Discover geography plan (OFF = global, ON = dest or empty).
  DiscoverEligibleQueryPlan lastQueryPlan =
      const DiscoverEligibleQueryPlan.worldwide();

  /// In-memory shadow diagnostics from the last [getCandidates] call.
  /// Not persisted. Not used for ranking or displayed compatibility.
  Map<String, DiscoverShadowDistanceDiagnostic> lastShadowDiagnostics =
      const {};

  /// In-memory L3 v1 profile soft-preference diagnostics (age / interests
  /// production diagnostics; distance evaluated but not production-promoted)
  /// from the last [getCandidates] call.
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

  /// Export last L3 v1 diagnostic map (debug), or null if empty.
  Map<String, dynamic>? exportLastL3SoftPreferenceDiagnosticsMap() {
    if (lastL3SoftPreferenceDiagnostics.isEmpty) return null;
    return {
      'export_version': 'discover_l3_soft_preference_shadow_session_v1',
      'policy_status': L3SoftPreferenceSignalContract.policyStatus,
      'shadow_only': true,
      'affects_discover_ranking': false,
      'is_l1_eligibility_gate': false,
      'combined_l3_score': null,
      'weights': false,
      'looking_for_active': false,
      'relationship_values_active': false,
      'age_production_promoted':
          L3SoftPreferenceSignalContract.ageProductionPromoted,
      'interests_production_promoted':
          L3SoftPreferenceSignalContract.interestsProductionPromoted,
      'distance_production_promoted':
          L3SoftPreferenceSignalContract.distanceProductionPromoted,
      'pair_count': lastL3SoftPreferenceDiagnostics.length,
      'pairs': [
        for (final d in lastL3SoftPreferenceDiagnostics.values) d.toExportMap(),
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
    final shadowGeneration = ++_shadowGeneration;

    final passport = await _passportClient.get();
    lastPassportSnapshot = passport;
    final plan = DiscoverEligibleQueryPlan.fromPassport(passport);
    lastQueryPlan = plan;

    // Prefer discover_eligible to avoid composite index needs.
    // TODO: Backfill discover_eligible for existing users if needed.
    final batchSize = (limit * 3).clamp(30, 120);
    final started = await QmatchPerf.trace('discover.firestore_batch', () {
      return Future.wait<Object?>([
        QmatchPerf.trace(
          'discover.me_get',
          () => FirestorePaths.userDoc(currentUid).get(),
        ),
        QmatchPerf.trace(
          'discover.swipes_get',
          () => _swipeService.getMySwipedUserIds(),
        ),
        QmatchPerf.trace(
          'discover.blocks_get',
          () => _loadBlockedByMe(),
        ),
        QmatchPerf.trace(
          'discover.eligible_query',
          () {
            if (plan.skipEligibleQuery) {
              return Future<QuerySnapshot<Map<String, dynamic>>?>.value(null);
            }
            Query<Map<String, dynamic>> query = FirestorePaths.users()
                .where('discover_eligible', isEqualTo: true);
            if (plan.usesDestinationFilter) {
              query = query
                  .where('home_country', isEqualTo: plan.country)
                  .where('home_city', isEqualTo: plan.city);
            }
            return query.limit(batchSize).get();
          },
        ),
      ]);
    });

    final meDoc = started[0] as DocumentSnapshot<Map<String, dynamic>>;
    final meData =
        Map<String, dynamic>.from(meDoc.data() ?? <String, dynamic>{});
    final swiped = started[1] as Set<String>;
    final blockedByMe = started[2] as Set<String>;
    final snapshot = started[3] as QuerySnapshot<Map<String, dynamic>>?;

    final attachLegacyUi = _rankingMode.usesLegacyCompatibilityScoring;
    final needLegacyCompat = attachLegacyUi || _stageB2Collector.enabled;
    if (needLegacyCompat) {
      await _hydrateViewerLegacyFrequencyMirrors(
        meData: meData,
        currentUid: currentUid,
      );
    }

    final out = <DiscoverUserModel>[];
    // Raw user-doc maps for post-rank L3 soft preference shadow only.
    final candidateUserData = <String, Map<String, dynamic>>{};
    var excludedSelf = 0;
    var excludedSwiped = 0;
    var excludedBlockedByMe = 0;
    var excludedInactive = 0;
    var excludedIncompleteProfile = 0;
    var excludedAssessmentIncomplete = 0;
    var excludedMissingPhoto = 0;

    final docs = snapshot?.docs ??
        const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    QmatchPerf.traceSync('discover.l1_local', () {
      if (_stageB2Collector.enabled) {
        _stageB2Collector.beginSession(viewerUid: currentUid);
      } else {
        _stageB2Collector.reset();
      }

      for (final doc in docs) {
        if (doc.id == currentUid) {
          excludedSelf++;
          continue;
        }
        if (swiped.contains(doc.id)) {
          excludedSwiped++;
          continue;
        }
        // Viewer-block only (owner-readable). Reverse-block is Admin-omitted
        // on the trusted L2 callable — never GET peer block docs.
        if (DiscoverL1EligibilityGate.excludedByBlocks(
          viewerBlockedCandidate: blockedByMe.contains(doc.id),
          candidateBlockedViewer: false,
        )) {
          excludedBlockedByMe++;
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

        CompatibilityResult? compat;
        if (needLegacyCompat) {
          compat = CompatibilityScoring.calculateCompatibility(
            me: meData,
            candidate: {
              ...data,
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
        }

        candidateUserData[doc.id] = Map<String, dynamic>.from(data);
        if (attachLegacyUi && compat != null) {
          out.add(
            candidate.copyWith(
              compatibilityScore: compat.available ? compat.scoreTotal : null,
              compatibilityLabel: compat.label,
              compatibilityReasons: compat.reasons,
            ),
          );
        } else {
          // structural_l2_v1: do not attach legacy % as if it were L2.
          out.add(candidate);
        }
      }

      if (kDebugMode) {
        debugPrint(
          'Discover L1: fetched=${snapshot?.docs.length ?? 0} '
          'self=$excludedSelf swiped=$excludedSwiped '
          'blocked_by_me=$excludedBlockedByMe '
          'inactive=$excludedInactive '
          'incomplete_profile=$excludedIncompleteProfile '
          'assessment_incomplete=$excludedAssessmentIncomplete '
          'missing_photo=$excludedMissingPhoto '
          'l1_eligible=${out.length}',
        );
      }
    });

    var ranked = out;
    Map<String, DiscoverStageB2TrustedPairResult> trustedByUid = const {};

    // Trusted candidate_uids is authoritative for both structural_l2_v1
    // and legacy_v1. Callable failure fail-closes (no unverified L1 batch).
    final batch = await QmatchPerf.trace(
      'discover.l2_callable',
      () => _trustedL2Batch(
        ranked.map((c) => c.uid).toList(growable: false),
      ),
    );
    ranked = QmatchPerf.traceSync('discover.cpu_rank', () {
      ranked = DiscoverStructuralL2Ranking.applyTrustedMembership(
        candidates: ranked,
        callableFailed: batch.callableFailed,
        returnedUids: batch.returnedUids,
      );
      final pairsByUid = batch.callableFailed
          ? const <String, DiscoverStageB2TrustedPairResult>{}
          : batch.pairsByUid;
      if (_rankingMode.usesTrustedStructuralL2) {
        ranked = DiscoverStructuralL2Ranking.rankL1Batch(
          l1Eligible: ranked,
          pairsByUid: pairsByUid,
        );
      } else {
        ranked.sort((a, b) {
          return CompatibilityScoring.compareDiscoverCandidates(
            aScore: a.compatibilityScore,
            bScore: b.compatibilityScore,
            aLastActiveMs: a.lastActiveAt?.millisecondsSinceEpoch ?? 0,
            bLastActiveMs: b.lastActiveAt?.millisecondsSinceEpoch ?? 0,
          );
        });
      }
      return ranked;
    });
    if (!batch.callableFailed) {
      trustedByUid = batch.pairsByUid;
    }

    // Shadow diagnostics AFTER ranking — never reorder / rescore.
    // Debug peer canonical_v1 reads must not delay the trusted deck.
    _scheduleShadowDiagnostics(
      generation: shadowGeneration,
      meUid: currentUid,
      meUserData: meData,
      rankedCandidates: ranked,
      candidateUserData: candidateUserData,
      trustedPairsByUid: trustedByUid,
    );

    return ranked;
  }

  /// Legacy CompatibilityScoring only: fill missing user-doc Frequency mirrors
  /// from `assessments/frequency`. Not used for L1 gates or trusted L2.
  Future<void> _hydrateViewerLegacyFrequencyMirrors({
    required Map<String, dynamic> meData,
    required String currentUid,
  }) async {
    if (meData['frequency_type'] != null &&
        meData['frequency_tags'] != null &&
        meData['frequency_vector'] != null) {
      return;
    }
    try {
      final freqDoc = await FirestorePaths.userDoc(currentUid)
          .collection('assessments')
          .doc('frequency')
          .get();
      final freq = freqDoc.data();
      if (freq == null) return;
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
      meData['frequency_vector'] ??= freq['vector'] ?? freq['frequency_vector'];
    } catch (_) {
      // ignore for MVP
    }
  }

  Future<DiscoverStageB2TrustedBatch> _trustedL2Batch(List<String> uids) async {
    if (uids.isEmpty) {
      return const DiscoverStageB2TrustedBatch(
        returnedUids: [],
        pairs: [],
        callableFailed: false,
      );
    }
    try {
      return await _stageB2TrustedL2.compareForL1Batch(candidateUids: uids);
    } catch (e, st) {
      debugPrint('Discover trusted membership fail-closed: $e\n$st');
      return DiscoverStageB2TrustedBatch.callableFailed(uids);
    }
  }

  /// Debug/export shadow only. Never ranks. Never awaited on the deck path.
  void _scheduleShadowDiagnostics({
    required int generation,
    required String meUid,
    required Map<String, dynamic> meUserData,
    required List<DiscoverUserModel> rankedCandidates,
    required Map<String, Map<String, dynamic>> candidateUserData,
    required Map<String, DiscoverStageB2TrustedPairResult> trustedPairsByUid,
  }) {
    final wantEqualShadow = _enableShadowDiagnostics;
    final wantStageB2 = _stageB2Collector.enabled;
    if ((!wantEqualShadow && !wantStageB2) || rankedCandidates.isEmpty) {
      lastShadowDiagnostics = const {};
      lastL3SoftPreferenceDiagnostics = const {};
      if (!wantStageB2) _stageB2Collector.reset();
      return;
    }
    unawaited(
      _computeShadowDiagnostics(
        generation: generation,
        meUid: meUid,
        meUserData: meUserData,
        rankedCandidates: List<DiscoverUserModel>.of(rankedCandidates),
        candidateUserData: Map<String, Map<String, dynamic>>.of(
          candidateUserData,
        ),
        trustedPairsByUid: trustedPairsByUid,
      ),
    );
  }

  Future<void> _computeShadowDiagnostics({
    required int generation,
    required String meUid,
    required Map<String, dynamic> meUserData,
    required List<DiscoverUserModel> rankedCandidates,
    required Map<String, Map<String, dynamic>> candidateUserData,
    Map<String, DiscoverStageB2TrustedPairResult> trustedPairsByUid = const {},
  }) async {
    final wantEqualShadow = _enableShadowDiagnostics;
    final wantStageB2 = _stageB2Collector.enabled;
    if ((!wantEqualShadow && !wantStageB2) || rankedCandidates.isEmpty) {
      if (generation != _shadowGeneration) return;
      lastShadowDiagnostics = const {};
      lastL3SoftPreferenceDiagnostics = const {};
      if (!wantStageB2) _stageB2Collector.reset();
      return;
    }

    try {
      if (wantEqualShadow) {
        final meProfile = await _canonicalProfile(meUid);
        final candidateProfiles = <String, Map<String, dynamic>?>{};

        // Debug-only peer canonical_v1 reads for already-selected candidates.
        // Production (kDebugMode == false) never enters this branch.
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
        final attached = _shadowAttacher.attach(
          rankedCandidates: rankedCandidates,
          meCanonicalProfile: meProfile,
          candidateCanonicalProfiles: candidateProfiles,
        );
        final l3Attached = _l3ShadowAttacher.attach(
          meUserData: meUserData,
          rankedCandidates: rankedCandidates,
          candidateUserData: candidateUserData,
        );

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
        if (generation != _shadowGeneration) return;
        lastShadowDiagnostics = attached.diagnostics;
        lastL3SoftPreferenceDiagnostics = l3Attached.diagnostics;
      } else {
        if (generation != _shadowGeneration) return;
        lastShadowDiagnostics = const {};
        lastL3SoftPreferenceDiagnostics = const {};
      }

      if (wantStageB2) {
        if (generation != _shadowGeneration) return;
        final uids = rankedCandidates.map((c) => c.uid).toList(growable: false);
        var byUid = trustedPairsByUid;
        if (byUid.isEmpty) {
          final batch = await _trustedL2Batch(uids);
          if (generation != _shadowGeneration) return;
          byUid = batch.pairsByUid;
        }
        final trusted = [
          for (final uid in uids)
            byUid[uid] ??
                DiscoverStageB2TrustedPairResult.unavailable(
                  'trusted_l2_callable_failed',
                ),
        ];
        _stageB2Collector.finalizeTrustedBatch(
          rankedCandidates: rankedCandidates,
          trustedPairs: trusted,
        );
      }
    } catch (e, st) {
      debugPrint('Discover shadow 20D diagnostics skipped: $e\n$st');
      if (generation != _shadowGeneration) return;
      lastShadowDiagnostics = const {};
      lastL3SoftPreferenceDiagnostics = const {};
      if (wantStageB2) {
        _stageB2Collector.reset();
      }
    }
  }

  Future<Set<String>> _loadBlockedByMe() async {
    try {
      return await _safetyService.getMyBlockedUserIds();
    } catch (_) {
      return <String>{};
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
