import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/utils/compatibility_scoring.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/services/discover_ranking_mode.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_dual_path_collector.dart';
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
    });
  });
}
