import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/utils/compatibility_scoring.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/services/discover_ranking_mode.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_dual_path_collector.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_trusted_l2_client.dart';
import 'package:qmatch/features/discover/services/discover_structural_l2_ranking.dart';
import 'package:qmatch/features/matching/domain/canonical_20d_group_normalized_shadow_contract.dart';

DiscoverUserModel _candidate({
  required String uid,
  DateTime? lastActive,
  double? legacyScore,
}) {
  return DiscoverUserModel(
    uid: uid,
    name: uid,
    age: 28,
    profilePhotoUrl: 'https://example.com/$uid.jpg',
    profileCompleted: true,
    testCompleted: true,
    lastActiveAt: lastActive == null ? null : Timestamp.fromDate(lastActive),
    compatibilityScore: legacyScore,
  );
}

DiscoverStageB2TrustedPairResult _l2({
  required bool available,
  double? distance,
  String reason = 'candidate_canonical_profile_missing',
}) {
  if (!available) {
    return DiscoverStageB2TrustedPairResult.unavailable(reason);
  }
  return DiscoverStageB2TrustedPairResult(
    available: true,
    structuralDistance: distance,
    totalCoverage: 1.0,
    comparableDimensions: 20,
  );
}

void main() {
  final t0 = DateTime.utc(2026, 8, 16, 12);
  final tFresh = t0;
  final tStale = t0.subtract(const Duration(days: 90));

  group('DiscoverRankingMode', () {
    test('active production mode is structural_l2_v1', () {
      expect(DiscoverRankingMode.active, DiscoverRankingMode.structuralL2V1);
      expect(DiscoverRankingMode.active.wireValue, 'structural_l2_v1');
      expect(DiscoverRankingMode.legacyV1.wireValue, 'legacy_v1');
      expect(DiscoverRankingMode.fromWire('legacy_v1'),
          DiscoverRankingMode.legacyV1);
      expect(DiscoverRankingMode.fromWire('structural_l2_v1'),
          DiscoverRankingMode.structuralL2V1);
      expect(DiscoverRankingMode.fromWire('nope'), isNull);
      expect(
        Canonical20dGroupNormalizedShadowContract.liveDiscoverRanking,
        isFalse,
      );
    });
  });

  group('DiscoverStructuralL2Ranking', () {
    test('smaller structural_distance ranks first; L1 set unchanged', () {
      final l1 = [
        _candidate(uid: 'far', lastActive: tFresh),
        _candidate(uid: 'near', lastActive: tStale),
        _candidate(uid: 'mid', lastActive: tFresh),
      ];
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: l1,
        pairsByUid: {
          'far': _l2(available: true, distance: 0.40),
          'near': _l2(available: true, distance: 0.0),
          'mid': _l2(available: true, distance: 0.18),
        },
      );
      expect(ranked.map((c) => c.uid).toList(), ['near', 'mid', 'far']);
      expect(ranked.map((c) => c.uid).toSet(), l1.map((c) => c.uid).toSet());
      expect(ranked, hasLength(l1.length));
    });

    test('absent last_active_at falls through to uid tiebreak', () {
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: [
          _candidate(uid: 'zeta'),
          _candidate(uid: 'alpha'),
        ],
        pairsByUid: {
          'zeta': _l2(available: true, distance: 0.10),
          'alpha': _l2(available: true, distance: 0.10),
        },
      );
      expect(ranked.map((c) => c.uid).toList(), ['alpha', 'zeta']);
      expect(ranked.every((c) => c.lastActiveAt == null), isTrue);
    });

    test('available L2 ranks before unavailable; missing is not 0 or 0.5', () {
      final l1 = [
        _candidate(uid: 'missing', lastActive: tFresh),
        _candidate(uid: 'far', lastActive: tStale),
      ];
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: l1,
        pairsByUid: {
          'missing': _l2(available: false),
          'far': _l2(available: true, distance: 0.40),
        },
      );
      expect(ranked.map((c) => c.uid).toList(), ['far', 'missing']);
    });

    test('available distance 0 (clone) still ranks before unavailable', () {
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: [
          _candidate(uid: 'missing', lastActive: tFresh),
          _candidate(uid: 'clone', lastActive: tStale),
        ],
        pairsByUid: {
          'missing': _l2(available: false),
          'clone': _l2(available: true, distance: 0.0),
        },
      );
      expect(ranked.map((c) => c.uid).toList(), ['clone', 'missing']);
    });

    test('available:true without distance is not rankable (not 0)', () {
      expect(_l2(available: true, distance: null).isRankable, isFalse);
      expect(_l2(available: true, distance: double.nan).isRankable, isFalse);
      expect(_l2(available: true, distance: 0.0).isRankable, isTrue);
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: [
          _candidate(uid: 'broken', lastActive: tFresh),
          _candidate(uid: 'ok', lastActive: tStale),
        ],
        pairsByUid: {
          'broken': _l2(available: true, distance: null),
          'ok': _l2(available: true, distance: 0.25),
        },
      );
      expect(ranked.map((c) => c.uid).toList(), ['ok', 'broken']);
    });

    test('unavailable candidates use recency only', () {
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: [
          _candidate(uid: 'old', lastActive: tStale),
          _candidate(uid: 'new', lastActive: tFresh),
        ],
        pairsByUid: {
          'old': _l2(available: false),
          'new': _l2(available: false, reason: 'trusted_l2_callable_failed'),
        },
      );
      expect(ranked.map((c) => c.uid).toList(), ['new', 'old']);
    });

    test('dropOmittedUids removes reverse-blocked UIDs; L2 order unchanged', () {
      final l1 = [
        _candidate(uid: 'far', lastActive: tFresh),
        _candidate(uid: 'blocked_me', lastActive: tFresh),
        _candidate(uid: 'near', lastActive: tStale),
      ];
      final dropped = DiscoverStructuralL2Ranking.dropOmittedUids(
        candidates: l1,
        returnedUids: ['far', 'near'],
      );
      expect(dropped.map((c) => c.uid).toList(), ['far', 'near']);
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: dropped,
        pairsByUid: {
          'far': _l2(available: true, distance: 0.40),
          'near': _l2(available: true, distance: 0.0),
        },
      );
      expect(ranked.map((c) => c.uid).toList(), ['near', 'far']);
      expect(ranked.any((c) => c.uid == 'blocked_me'), isFalse);
    });

    test('callable failure fail-closes — no unverified L1 candidate is shown',
        () {
      final l1 = [
        _candidate(uid: 'a', lastActive: tFresh, legacyScore: 0.9),
        _candidate(uid: 'b', lastActive: tStale, legacyScore: 0.1),
      ];
      final failed = DiscoverStageB2TrustedBatch.callableFailed(
        l1.map((c) => c.uid).toList(),
      );
      // Trap: failed batch still echoes request UIDs. Must not treat as verified.
      expect(failed.returnedUids, ['a', 'b']);
      final shown = DiscoverStructuralL2Ranking.applyTrustedMembership(
        candidates: l1,
        callableFailed: failed.callableFailed,
        returnedUids: failed.returnedUids,
      );
      expect(shown, isEmpty);
      expect(
        DiscoverStructuralL2Ranking.rankL1Batch(
          l1Eligible: shown,
          pairsByUid: failed.pairsByUid,
        ),
        isEmpty,
      );
    });

    test('legacy_v1 orders by CompatibilityScoring only after trusted omit', () {
      final l1 = [
        _candidate(uid: 'blocked_me', lastActive: tFresh, legacyScore: 0.95),
        _candidate(uid: 'near', lastActive: tStale, legacyScore: 0.20),
        _candidate(uid: 'mid', lastActive: tFresh, legacyScore: 0.50),
      ];
      final verified = DiscoverStructuralL2Ranking.applyTrustedMembership(
        candidates: l1,
        callableFailed: false,
        returnedUids: ['near', 'mid'],
      );
      expect(verified.map((c) => c.uid).toList(), ['near', 'mid']);
      expect(verified.any((c) => c.uid == 'blocked_me'), isFalse);

      final legacy = List<DiscoverUserModel>.of(verified)
        ..sort(
          (a, b) => CompatibilityScoring.compareDiscoverCandidates(
            aScore: a.compatibilityScore,
            bScore: b.compatibilityScore,
            aLastActiveMs: a.lastActiveAt?.millisecondsSinceEpoch ?? 0,
            bLastActiveMs: b.lastActiveAt?.millisecondsSinceEpoch ?? 0,
          ),
        );
      expect(legacy.map((c) => c.uid).toList(), ['mid', 'near']);
    });

    test('structural_l2_v1 success path still ranks by distance after omit', () {
      final l1 = [
        _candidate(uid: 'far', lastActive: tFresh),
        _candidate(uid: 'blocked_me', lastActive: tFresh),
        _candidate(uid: 'near', lastActive: tStale),
      ];
      final verified = DiscoverStructuralL2Ranking.applyTrustedMembership(
        candidates: l1,
        callableFailed: false,
        returnedUids: ['far', 'near'],
      );
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: verified,
        pairsByUid: {
          'far': _l2(available: true, distance: 0.40),
          'near': _l2(available: true, distance: 0.0),
        },
      );
      expect(ranked.map((c) => c.uid).toList(), ['near', 'far']);
      expect(ranked.any((c) => c.uid == 'blocked_me'), isFalse);
    });

    test('failed/missing pair for a uid is recency fallback, not dropped', () {
      final l1 = [
        _candidate(uid: 'a', lastActive: tStale),
        _candidate(uid: 'b', lastActive: tFresh),
      ];
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: l1,
        pairsByUid: {
          'a': _l2(available: true, distance: 0.12),
        },
      );
      expect(ranked.map((c) => c.uid).toList(), ['a', 'b']);
      expect(ranked, hasLength(2));
    });

    test('legacy CompatibilityScoring order can diverge from L2', () {
      final l1 = [
        _candidate(uid: 'stale_clone', lastActive: tStale, legacyScore: 0.40),
        _candidate(uid: 'fresh_far', lastActive: tFresh, legacyScore: 0.80),
      ];
      final legacy = List<DiscoverUserModel>.of(l1)
        ..sort(
          (a, b) => CompatibilityScoring.compareDiscoverCandidates(
            aScore: a.compatibilityScore,
            bScore: b.compatibilityScore,
            aLastActiveMs: a.lastActiveAt?.millisecondsSinceEpoch ?? 0,
            bLastActiveMs: b.lastActiveAt?.millisecondsSinceEpoch ?? 0,
          ),
        );
      final l2 = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: l1,
        pairsByUid: {
          'stale_clone': _l2(available: true, distance: 0.0),
          'fresh_far': _l2(available: true, distance: 0.40),
        },
      );
      expect(legacy.map((c) => c.uid).toList(), ['fresh_far', 'stale_clone']);
      expect(l2.map((c) => c.uid).toList(), ['stale_clone', 'fresh_far']);
    });
  });

  group('cutover isolation / UI', () {
    test('L2 ranker has no Persona/RVI/L3/L4/L5 and no neutral fill', () {
      final src = File(
        'lib/features/discover/services/discover_structural_l2_ranking.dart',
      ).readAsStringSync();
      expect(src.contains('persona'), isFalse);
      expect(src.contains('rvi'), isFalse);
      expect(src.contains('l3_soft'), isFalse);
      expect(src.contains('wave_state'), isFalse);
      expect(src.contains('temporal'), isFalse);
      expect(src.contains('CompatibilityScoring'), isFalse);
      expect(src.contains('0.5'), isFalse);
      expect(src.contains('0.42'), isFalse);
      expect(src.contains('quantum'), isFalse);
      expect(src.contains('canonical_v1'), isFalse);
    });

    test('DiscoverService default is L2; legacy % only on rollback path', () {
      final service = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(service.contains('DiscoverRankingMode.active'), isTrue);
      expect(service.contains('usesTrustedStructuralL2'), isTrue);
      expect(service.contains('usesLegacyCompatibilityScoring'), isTrue);
      expect(service.contains('rankL1Batch'), isTrue);
      expect(service.contains('applyTrustedMembership'), isTrue);
      expect(service.contains('dropOmittedUids'), isFalse);
      expect(
        service.indexOf('applyTrustedMembership') <
            service.indexOf('rankL1Batch'),
        isTrue,
      );
      expect(
        service.indexOf('applyTrustedMembership') <
            service.indexOf('compareDiscoverCandidates'),
        isTrue,
      );
      expect(service.contains('fail-closed'), isTrue);
      expect(service.contains('ranking fallback (recency)'), isFalse);
      expect(
        service.contains('do not attach legacy % as if it were L2'),
        isTrue,
      );
      expect(service.contains('persona_scoring'), isFalse);
      expect(service.contains('group_normalized'), isFalse);

      final attachLegacy = service.indexOf('attachLegacyUi && compat != null');
      final copyWithScore =
          service.indexOf('compatibilityScore: compat.available');
      final l2Add = service.indexOf('out.add(candidate);');
      expect(attachLegacy, greaterThanOrEqualTo(0));
      expect(copyWithScore, greaterThan(attachLegacy));
      expect(l2Add, greaterThan(copyWithScore));
    });

    test('candidate card does not invent an L2 percent from distance', () {
      final card = File(
        'lib/features/discover/widgets/qmatch_candidate_card.dart',
      ).readAsStringSync();
      expect(card.contains('structural_distance'), isTrue);
      expect(card.contains('structuralDistance'), isFalse);
      expect(card.contains('discoverPercentCompatibility'), isTrue);
      expect(card.contains('showLegacyCompatibilityUi = false'), isTrue);
    });

    test('Frequency hydrate and legacy UI are gated off the L2 path', () {
      final service = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(service.contains('needLegacyCompat'), isTrue);
      expect(
        service.contains('_hydrateViewerLegacyFrequencyMirrors'),
        isTrue,
      );
      final needIdx = service.indexOf(
        'final needLegacyCompat = attachLegacyUi || _stageB2Collector.enabled;',
      );
      final hydrateIdx = service.indexOf(
        'if (needLegacyCompat) {\n      await _hydrateViewerLegacyFrequencyMirrors(',
      );
      expect(needIdx, greaterThanOrEqualTo(0));
      expect(hydrateIdx, greaterThan(needIdx));

      final screen = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('showLegacyCompatibilityUi:'), isTrue);
      expect(screen.contains('usesLegacyCompatibilityScoring'), isTrue);
    });

    test('Frequency V2 diagnostic is not a ranking input', () {
      final ranking = File(
        'lib/features/discover/services/discover_structural_l2_ranking.dart',
      ).readAsStringSync();
      expect(ranking.contains('frequency_fit_index'), isFalse);
      expect(ranking.contains('frequencyV2'), isFalse);
      expect(ranking.contains('frequency_v2'), isFalse);
      expect(ranking.contains('compatibility_index'), isFalse);
      expect(ranking.contains('compatibilityV2'), isFalse);
      expect(ranking.contains('compatibility_v2'), isFalse);

      final a = _candidate(uid: 'a', lastActive: tStale);
      final b = _candidate(uid: 'b', lastActive: tStale);
      final highV2 = DiscoverStageB2TrustedPairResult(
        available: true,
        structuralDistance: 0.4,
        totalCoverage: 1,
        comparableDimensions: 20,
        frequencyV2: const DiscoverStageB2FrequencyV2Diagnostic(
          available: true,
          frequencyFitIndex: 99,
          overallSupportedFit: 0.99,
          overallPairSupport: 1,
          pairFitVersion: 'frequency_behavior_v2_pair_fit_v1',
        ),
      );
      final lowV2 = DiscoverStageB2TrustedPairResult(
        available: true,
        structuralDistance: 0.1,
        totalCoverage: 1,
        comparableDimensions: 20,
        frequencyV2: const DiscoverStageB2FrequencyV2Diagnostic(
          available: true,
          frequencyFitIndex: 1,
          overallSupportedFit: 0.01,
          overallPairSupport: 1,
          pairFitVersion: 'frequency_behavior_v2_pair_fit_v1',
        ),
      );
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: [a, b],
        pairsByUid: {'a': highV2, 'b': lowV2},
      );
      expect(ranked.map((c) => c.uid).toList(), ['b', 'a']);
    });

    test('compatibility fusion diagnostic is not a ranking input', () {
      final a = _candidate(uid: 'a', lastActive: tStale);
      final b = _candidate(uid: 'b', lastActive: tStale);
      final highFusion = DiscoverStageB2TrustedPairResult(
        available: true,
        structuralDistance: 0.4,
        totalCoverage: 1,
        comparableDimensions: 20,
        compatibilityV2: const DiscoverStageB2CompatibilityV2Diagnostic(
          available: true,
          compatibilityIndex: 99,
          policyVersion: 'qmatch_compatibility_fusion_v2_policy_v1',
          structuralFit: 0.5,
          frequencyFit: 0.99,
          structuralCoverage: 1,
          frequencyPairSupport: 1,
        ),
      );
      final lowFusion = DiscoverStageB2TrustedPairResult(
        available: true,
        structuralDistance: 0.1,
        totalCoverage: 1,
        comparableDimensions: 20,
        compatibilityV2: const DiscoverStageB2CompatibilityV2Diagnostic(
          available: true,
          compatibilityIndex: 1,
          policyVersion: 'qmatch_compatibility_fusion_v2_policy_v1',
          structuralFit: 0.9,
          frequencyFit: 0.01,
          structuralCoverage: 1,
          frequencyPairSupport: 1,
        ),
      );
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: [a, b],
        pairsByUid: {'a': highFusion, 'b': lowFusion},
      );
      expect(ranked.map((c) => c.uid).toList(), ['b', 'a']);
    });
  });
}
