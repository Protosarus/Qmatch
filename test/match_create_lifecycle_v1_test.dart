import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/utils/firestore_paths.dart';
import 'package:qmatch/features/matching/models/match_model.dart';
import 'package:qmatch/features/matching/services/match_create_lifecycle_gate.dart';

void main() {
  group('MatchCreateLifecycleGate — create / refuse matrix', () {
    test('new mutual match → createNew (success)', () {
      final d = MatchCreateLifecycleGate.decide(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidate: true,
        candidateLikesViewer: true,
      );
      expect(d, MatchCreateLifecycleDecision.createNew);
      expect(MatchCreateLifecycleGate.isSuccess(d), isTrue);
    });

    test('duplicate active match → idempotent success', () {
      final d = MatchCreateLifecycleGate.decide(
        matchExists: true,
        matchState: MatchState.active.name,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidate: true,
        candidateLikesViewer: true,
      );
      expect(d, MatchCreateLifecycleDecision.idempotentActiveSuccess);
      expect(MatchCreateLifecycleGate.isSuccess(d), isTrue);
    });

    test('existing unmatched match → refuse (no auto-reactivate)', () {
      final d = MatchCreateLifecycleGate.decide(
        matchExists: true,
        matchState: MatchState.unmatched.name,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidate: true,
        candidateLikesViewer: true,
      );
      expect(d, MatchCreateLifecycleDecision.refuseUnmatchedExists);
      expect(MatchCreateLifecycleGate.isSuccess(d), isFalse);
    });

    test('existing blocked match → refuse', () {
      final d = MatchCreateLifecycleGate.decide(
        matchExists: true,
        matchState: MatchState.blocked.name,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidate: true,
        candidateLikesViewer: true,
      );
      expect(d, MatchCreateLifecycleDecision.refuseBlockedExists);
      expect(MatchCreateLifecycleGate.isSuccess(d), isFalse);
    });

    test('existence alone (missing state) never means active', () {
      final d = MatchCreateLifecycleGate.decide(
        matchExists: true,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidate: true,
        candidateLikesViewer: true,
      );
      expect(d, MatchCreateLifecycleDecision.refuseExistingNonActive);
      expect(MatchCreateLifecycleGate.isSuccess(d), isFalse);
    });

    test('viewer blocks candidate → refuse', () {
      final d = MatchCreateLifecycleGate.decide(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: true,
        candidateBlockedViewer: false,
        viewerLikesCandidate: true,
        candidateLikesViewer: true,
      );
      expect(d, MatchCreateLifecycleDecision.refuseBlockEitherDirection);
      expect(MatchCreateLifecycleGate.isSuccess(d), isFalse);
    });

    test('candidate blocks viewer → refuse', () {
      final d = MatchCreateLifecycleGate.decide(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: true,
        viewerLikesCandidate: true,
        candidateLikesViewer: true,
      );
      expect(d, MatchCreateLifecycleDecision.refuseBlockEitherDirection);
      expect(MatchCreateLifecycleGate.isSuccess(d), isFalse);
    });

    test('non-mutual like (missing reverse) → refuse', () {
      final d = MatchCreateLifecycleGate.decide(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidate: true,
        candidateLikesViewer: false,
      );
      expect(d, MatchCreateLifecycleDecision.refuseNonMutualLike);
      expect(MatchCreateLifecycleGate.isSuccess(d), isFalse);
    });

    test('non-mutual like (viewer pass / missing own like) → refuse', () {
      final d = MatchCreateLifecycleGate.decide(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidate: false,
        candidateLikesViewer: true,
      );
      expect(d, MatchCreateLifecycleDecision.refuseNonMutualLike);
      expect(MatchCreateLifecycleGate.isSuccess(d), isFalse);
    });

    test('retry/idempotency: active wins over blocks and likes noise', () {
      // Retry after successful create: active match → success even if a later
      // block doc appeared client-side (match already active; do not recreate).
      final d = MatchCreateLifecycleGate.decide(
        matchExists: true,
        matchState: MatchState.active.name,
        viewerBlockedCandidate: true,
        candidateBlockedViewer: false,
        viewerLikesCandidate: false,
        candidateLikesViewer: false,
      );
      expect(d, MatchCreateLifecycleDecision.idempotentActiveSuccess);
      expect(MatchCreateLifecycleGate.isSuccess(d), isTrue);
    });

    test('unmatched takes precedence over mutual likes (no reactivate)', () {
      final d = MatchCreateLifecycleGate.decide(
        matchExists: true,
        matchState: MatchState.unmatched.name,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidate: true,
        candidateLikesViewer: true,
      );
      expect(d, MatchCreateLifecycleDecision.refuseUnmatchedExists);
    });
  });

  group('MatchService wiring + ID consistency', () {
    test('deterministic match/thread ids stay mirrored', () {
      const a = 'uid_aaa';
      const b = 'uid_bbb';
      expect(
        FirestorePaths.deterministicMatchId(a, b),
        FirestorePaths.deterministicThreadId(a, b),
      );
      expect(
        FirestorePaths.deterministicMatchId(a, b),
        FirestorePaths.deterministicMatchId(b, a),
      );
    });

    test('createMatchIfMutualLike uses lifecycle gate + both swipes + blocks', () {
      final src = File(
        'lib/features/matching/services/match_service.dart',
      ).readAsStringSync();
      expect(src.contains('MatchCreateLifecycleGate.decide'), isTrue);
      expect(src.contains('userBlockDoc'), isTrue);
      expect(src.contains('ownSwipeRef'), isTrue);
      expect(src.contains('reverseSwipeRef'), isTrue);
      expect(src.contains('match_create_lifecycle_v1'), isTrue);
      // Create path must not treat bare existence as success.
      expect(src.contains('if (matchSnap.exists) {\n        return true;'), isFalse);
      // Must not auto-reactivate: no write of active over unmatched in create path.
      expect(src.contains("state': 'active'"), isFalse);
      expect(
        src.contains("'state': MatchState.active.name"),
        isTrue,
      ); // only on fresh create
    });

    test('no Discover ranking / CompatibilityScoring in match create path', () {
      final gate = File(
        'lib/features/matching/services/match_create_lifecycle_gate.dart',
      ).readAsStringSync();
      final service = File(
        'lib/features/matching/services/match_service.dart',
      ).readAsStringSync();
      for (final src in [gate, service]) {
        expect(src.contains('CompatibilityScoring'), isFalse);
        expect(src.contains('DiscoverService'), isFalse);
        expect(src.contains('compareDiscoverCandidates'), isFalse);
        expect(src.contains('persona'), isFalse);
        expect(src.contains('quantum'), isFalse);
      }
    });
  });
}
