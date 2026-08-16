import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_dual_path_collector.dart';
import 'package:qmatch/features/matching/domain/canonical_20d_group_normalized_shadow.dart';

DiscoverUserModel _candidate({
  required String uid,
  double? score,
  String? label,
}) {
  return DiscoverUserModel(
    uid: uid,
    name: 'Name-$uid',
    age: 28,
    bio: 'secret bio must not export',
    profilePhotoUrl: 'https://example.com/$uid.jpg',
    profileCompleted: true,
    testCompleted: true,
    compatibilityScore: score,
    compatibilityLabel: label,
  );
}

Map<String, dynamic> _canonicalProfile(Map<String, double> scores) {
  return {
    'measured_dimensions': [
      for (final e in scores.entries)
        {
          'dimension_id': e.key,
          'module': 'iq',
          'measurement_state': 'measured',
          'value': e.value,
          'reliability_status': 'not_calibrated',
        },
    ],
  };
}

void main() {
  final ids = Canonical20dGroupNormalizedShadowContract.iqDimensionIds +
      Canonical20dGroupNormalizedShadowContract.eqDimensionIds +
      Canonical20dGroupNormalizedShadowContract.frequencyDimensionIds;

  group('DiscoverStageB2DualPathCollector', () {
    test('disabled by default — no session / export', () {
      final c = DiscoverStageB2DualPathCollector();
      expect(c.enabled, isFalse);
      c.beginSession(viewerUid: 'viewer');
      c.recordLegacyPair(
        candidateUid: 'a',
        legacyAvailable: true,
        legacyScore: 0.8,
        legacyMissingReason: null,
      );
      c.finalizeBatch(
        rankedCandidates: [_candidate(uid: 'a', score: 0.8)],
        meCanonicalProfile: _canonicalProfile({for (final id in ids) id: 0.4}),
        candidateCanonicalProfiles: {
          'a': _canonicalProfile({for (final id in ids) id: 0.4}),
        },
      );
      expect(c.lastSession, isNull);
      expect(c.exportLastSessionJson(), isNull);
    });

    test('records privacy-safe dual-path fields + ranks; no PII in export', () {
      var saltN = 0;
      final c = DiscoverStageB2DualPathCollector(
        enabled: true,
        sessionSaltFactory: () => 'fixed-salt-${saltN++}',
      );

      c.beginSession(viewerUid: 'viewer-raw-uid');
      c.recordLegacyPair(
        candidateUid: 'cand-near',
        legacyAvailable: true,
        legacyScore: 0.91,
        legacyMissingReason: null,
      );
      c.recordLegacyPair(
        candidateUid: 'cand-far',
        legacyAvailable: true,
        legacyScore: 0.55,
        legacyMissingReason: null,
      );
      c.recordLegacyPair(
        candidateUid: 'cand-sparse',
        legacyAvailable: false,
        legacyScore: null,
        legacyMissingReason: 'insufficient_frequency_evidence',
      );

      // Legacy authoritative order: near, far, sparse.
      final ranked = [
        _candidate(uid: 'cand-near', score: 0.91, label: 'strong'),
        _candidate(uid: 'cand-far', score: 0.55, label: 'good'),
        _candidate(
          uid: 'cand-sparse',
          score: null,
          label: 'insufficient_evidence',
        ),
      ];

      final me = _canonicalProfile({for (final id in ids) id: 0.45});
      final profiles = {
        'cand-near': _canonicalProfile({for (final id in ids) id: 0.45}),
        'cand-far': _canonicalProfile({for (final id in ids) id: 0.95}),
        'cand-sparse': _canonicalProfile({for (final id in ids) id: 0.46}),
      };

      c.finalizeBatch(
        rankedCandidates: ranked,
        meCanonicalProfile: me,
        candidateCanonicalProfiles: profiles,
      );

      final session = c.lastSession;
      expect(session, isNotNull);
      expect(session!.pairCount, 3);
      expect(session.pairs[0].legacyRank, 1);
      expect(session.pairs[1].legacyRank, 2);
      expect(session.pairs[2].legacyRank, 3);
      expect(session.pairs[0].legacyScore, 0.91);
      expect(session.pairs[2].legacyAvailable, isFalse);
      expect(
        session.pairs[2].legacyMissingReason,
        'insufficient_frequency_evidence',
      );

      // Near should be structurally closer than far → structural_rank 1.
      expect(session.pairs[0].structuralAvailable, isTrue);
      expect(session.pairs[1].structuralAvailable, isTrue);
      expect(
          session.pairs[0].structuralDistance,
          lessThan(
            session.pairs[1].structuralDistance!,
          ));
      expect(session.pairs[0].structuralRank, 1);

      final json = c.exportLastSessionJson();
      expect(json, isNotNull);
      final map = jsonDecode(json!) as Map<String, dynamic>;
      expect(map['export_version'], DiscoverStageB2Session.exportVersion);
      expect(map['shadow_only'], isTrue);
      expect(map['affects_discover_ranking'], isFalse);
      expect(map['legacy_authoritative'], isTrue);
      expect(map['imputation'], isFalse);
      expect(map['fusion_weights'], isFalse);
      expect(map['persona_included'], isFalse);
      expect(map['qi_included'], isFalse);
      expect(map['temporal_included'], isFalse);
      expect(map['privacy']['stores_raw_uid'], isFalse);
      expect(map['privacy']['stores_profile_text'], isFalse);
      expect(map['privacy']['stores_message_content'], isFalse);
      expect(map['privacy']['stores_raw_answers'], isFalse);

      final blob = json;
      expect(blob.contains('viewer-raw-uid'), isFalse);
      expect(blob.contains('cand-near'), isFalse);
      expect(blob.contains('cand-far'), isFalse);
      expect(blob.contains('secret bio'), isFalse);
      expect(blob.contains('Name-'), isFalse);
      expect(blob.contains('example.com'), isFalse);
      expect(map['session_id'], isA<String>());
      expect(map['viewer_anon_id'], isA<String>());
      expect((map['pairs'] as List).length, 3);
      final p0 = (map['pairs'] as List).first as Map<String, dynamic>;
      expect(p0.containsKey('legacy_score'), isTrue);
      expect(p0.containsKey('D_structural'), isTrue);
      expect(p0.containsKey('legacy_rank'), isTrue);
      expect(p0.containsKey('structural_rank'), isTrue);
    });

    test('missing canonical profile → structural unavailable reason', () {
      final c = DiscoverStageB2DualPathCollector(
        enabled: true,
        sessionSaltFactory: () => 'salt-missing',
      );
      c.beginSession(viewerUid: 'v');
      c.recordLegacyPair(
        candidateUid: 'c1',
        legacyAvailable: true,
        legacyScore: 0.7,
        legacyMissingReason: null,
      );
      c.finalizeBatch(
        rankedCandidates: [_candidate(uid: 'c1', score: 0.7)],
        meCanonicalProfile: null,
        candidateCanonicalProfiles: const {'c1': null},
      );
      final p = c.lastSession!.pairs.single;
      expect(p.structuralAvailable, isFalse);
      expect(p.structuralMissingReason, 'viewer_canonical_profile_missing');
      expect(p.structuralRank, isNull);
    });

    test('does not reorder ranked candidates (collector is side-channel)', () {
      final c = DiscoverStageB2DualPathCollector(
        enabled: true,
        sessionSaltFactory: () => 'salt-order',
      );
      c.beginSession(viewerUid: 'v');
      final ranked = [
        _candidate(uid: 'b', score: 0.9),
        _candidate(uid: 'a', score: 0.2),
      ];
      c.recordLegacyPair(
        candidateUid: 'b',
        legacyAvailable: true,
        legacyScore: 0.9,
        legacyMissingReason: null,
      );
      c.recordLegacyPair(
        candidateUid: 'a',
        legacyAvailable: true,
        legacyScore: 0.2,
        legacyMissingReason: null,
      );
      final before = ranked.map((e) => e.uid).toList();
      c.finalizeBatch(
        rankedCandidates: ranked,
        meCanonicalProfile: _canonicalProfile({for (final id in ids) id: 0.5}),
        candidateCanonicalProfiles: {
          'a': _canonicalProfile({for (final id in ids) id: 0.5}),
          'b': _canonicalProfile({for (final id in ids) id: 0.9}),
        },
      );
      expect(ranked.map((e) => e.uid).toList(), before);
      expect(c.lastSession!.pairs.map((p) => p.legacyRank).toList(), [1, 2]);

      final comparison = DiscoverStageB2ComparisonLog.lines(c.lastSession!);
      expect(comparison, hasLength(7));
      expect(
        comparison.every(
          (line) => line.startsWith(DiscoverStageB2ComparisonLog.prefix),
        ),
        isTrue,
      );
      expect(comparison[0], contains('20D coverage:'));
      expect(comparison[1], contains('legacy candidate order:'));
      expect(comparison[2], contains('L2 group-normalized 20D order:'));
      expect(comparison[3], contains('rank delta per candidate'));
      expect(comparison[4], contains('top-3 overlap:'));
      expect(comparison[5], contains('top-5 overlap:'));
      expect(comparison[6], contains('pairwise disagreement:'));
    });

    test('finalizeTrustedBatch keeps L1 order and does not invent 0.5', () {
      final c = DiscoverStageB2DualPathCollector(
        enabled: true,
        sessionSaltFactory: () => 'salt-trusted',
      );
      c.beginSession(viewerUid: 'v');
      final ranked = [
        _candidate(uid: 'b', score: 0.9),
        _candidate(uid: 'a', score: 0.2),
      ];
      c.recordLegacyPair(
        candidateUid: 'b',
        legacyAvailable: true,
        legacyScore: 0.9,
        legacyMissingReason: null,
      );
      c.recordLegacyPair(
        candidateUid: 'a',
        legacyAvailable: true,
        legacyScore: 0.2,
        legacyMissingReason: null,
      );
      final before = ranked.map((e) => e.uid).toList();
      c.finalizeTrustedBatch(
        rankedCandidates: ranked,
        trustedPairs: const [
          DiscoverStageB2TrustedPairResult(
            available: true,
            structuralDistance: 0.4,
            totalCoverage: 1.0,
            comparableDimensions: 20,
          ),
          DiscoverStageB2TrustedPairResult(
            available: false,
            totalCoverage: 0.0,
            comparableDimensions: 0,
            unavailableReason: 'candidate_canonical_profile_missing',
          ),
        ],
      );
      expect(ranked.map((e) => e.uid).toList(), before);
      expect(c.lastSession!.pairs[0].legacyRank, 1);
      expect(c.lastSession!.pairs[0].structuralDistance, 0.4);
      expect(c.lastSession!.pairs[1].structuralAvailable, isFalse);
      expect(c.lastSession!.pairs[1].structuralDistance, isNull);
    });

    test('legacyRank is independent of L2-sorted Discover batch after cutover',
        () {
      final c = DiscoverStageB2DualPathCollector(
        enabled: true,
        sessionSaltFactory: () => 'salt-legacy-independent',
      );
      c.beginSession(viewerUid: 'v');
      c.recordLegacyPair(
        candidateUid: 'stale_clone',
        legacyAvailable: true,
        legacyScore: 0.40,
        legacyMissingReason: null,
      );
      c.recordLegacyPair(
        candidateUid: 'fresh_far',
        legacyAvailable: true,
        legacyScore: 0.80,
        legacyMissingReason: null,
      );
      // Live Discover order after structural_l2_v1: closer first.
      final l2Sorted = [
        _candidate(uid: 'stale_clone', score: null),
        _candidate(uid: 'fresh_far', score: null),
      ];
      final before = l2Sorted.map((e) => e.uid).toList();
      c.finalizeTrustedBatch(
        rankedCandidates: l2Sorted,
        trustedPairs: const [
          DiscoverStageB2TrustedPairResult(
            available: true,
            structuralDistance: 0.0,
            totalCoverage: 1.0,
            comparableDimensions: 20,
          ),
          DiscoverStageB2TrustedPairResult(
            available: true,
            structuralDistance: 0.40,
            totalCoverage: 1.0,
            comparableDimensions: 20,
          ),
        ],
      );
      expect(l2Sorted.map((e) => e.uid).toList(), before);
      expect(c.lastSession!.pairs[0].legacyScore, 0.40);
      expect(c.lastSession!.pairs[1].legacyScore, 0.80);
      expect(c.lastSession!.pairs[0].legacyRank, 2);
      expect(c.lastSession!.pairs[1].legacyRank, 1);
      expect(c.lastSession!.pairs[0].structuralRank, 1);
      expect(c.lastSession!.pairs[1].structuralRank, 2);
      final pairs = c.lastSession!.pairs;
      final byLegacy = List.of(pairs)
        ..sort((a, b) => a.legacyRank.compareTo(b.legacyRank));
      final byL2 = List.of(pairs)
        ..sort((a, b) => a.structuralRank!.compareTo(b.structuralRank!));
      expect(
        byLegacy.map((p) => p.candidateAnonId).toList(),
        isNot(equals(byL2.map((p) => p.candidateAnonId).toList())),
      );
      expect(byLegacy.map((p) => p.legacyScore).toList(), [0.80, 0.40]);
      expect(byL2.map((p) => p.structuralDistance).toList(), [0.0, 0.40]);
    });
  });

  group('Discover Stage B2 wiring isolation', () {
    test('DiscoverService gates Stage B2 off by default; export API present',
        () {
      final service = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(
          service.contains('enableStageB2DualPathCollector = false'), isTrue);
      expect(service.contains('exportLastStageB2SessionJson'), isTrue);
      expect(service.contains('DiscoverStageB2DualPathCollector'), isTrue);
      final rankIdx = service.indexOf('rankL1Batch');
      final sortIdx = service.indexOf('ranked.sort(');
      final stageB2Finalize = service.indexOf('finalizeTrustedBatch');
      expect(rankIdx, greaterThanOrEqualTo(0));
      expect(sortIdx, greaterThanOrEqualTo(0));
      expect(stageB2Finalize, greaterThan(rankIdx));
      expect(stageB2Finalize, greaterThan(sortIdx));
      expect(service.contains('compareForL1Batch'), isTrue);
      expect(service.contains('group_normalized'), isFalse);
      expect(service.indexOf('ranked.sort(', sortIdx + 1), -1);
      expect(service.contains('persona_scoring'), isFalse);
      expect(service.contains('quantum_mixed_state'), isFalse);
      expect(service.contains('phase_alignment'), isFalse);
    });

    test('collector export map omits PII keys', () {
      final c = DiscoverStageB2DualPathCollector(
        enabled: true,
        sessionSaltFactory: () => 'salt-keys',
      );
      c.beginSession(viewerUid: 'v');
      c.recordLegacyPair(
        candidateUid: 'c',
        legacyAvailable: true,
        legacyScore: 0.6,
        legacyMissingReason: null,
      );
      c.finalizeBatch(
        rankedCandidates: [_candidate(uid: 'c', score: 0.6)],
        meCanonicalProfile: _canonicalProfile({for (final id in ids) id: 0.5}),
        candidateCanonicalProfiles: {
          'c': _canonicalProfile({for (final id in ids) id: 0.5}),
        },
      );
      final map = c.exportLastSessionMap()!;
      final pair = (map['pairs'] as List).first as Map<String, dynamic>;
      for (final forbidden in [
        'uid',
        'bio',
        'name',
        'photos',
        'profilePhotoUrl',
        'interests',
        'message',
        'answers',
      ]) {
        expect(map.containsKey(forbidden), isFalse, reason: forbidden);
        expect(pair.containsKey(forbidden), isFalse, reason: forbidden);
      }
      expect(pair.containsKey('candidate_anon_id'), isTrue);
      expect(pair.containsKey('legacy_score'), isTrue);
      expect(pair.containsKey('D_structural'), isTrue);
      expect(map['privacy']['stores_raw_uid'], isFalse);
    });

    test('UI screens do not read Stage B2 export', () {
      final screen = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('exportLastStageB2'), isFalse);
      expect(screen.contains('lastStageB2Session'), isFalse);
      expect(screen.contains('DiscoverStageB2ComparisonLog'), isFalse);
    });
  });
}
