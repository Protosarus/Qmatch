import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/models/match_model.dart';
import 'package:qmatch/features/matching/services/like_match_atomicity_gate.dart';
import 'package:qmatch/features/matching/services/match_create_lifecycle_gate.dart';

void main() {
  group('LikeMatchAtomicityGate', () {
    test('first Like (no reverse) persists Like, no match', () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: false,
      );
      expect(plan.persistOwnLike, isTrue);
      expect(plan.writeMatchArtifacts, isFalse);
      expect(plan.matched, isFalse);
      expect(
        plan.matchDecision,
        MatchCreateLifecycleDecision.refuseNonMutualLike,
      );
    });

    test('mutual Like creates match artifacts', () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
      );
      expect(plan.persistOwnLike, isTrue);
      expect(plan.writeMatchArtifacts, isTrue);
      expect(plan.matched, isTrue);
      expect(plan.matchDecision, MatchCreateLifecycleDecision.createNew);
    });

    test('simultaneous/retry Like with active match is idempotent success', () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: true,
        matchState: MatchState.active.name,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
      );
      expect(plan.persistOwnLike, isTrue);
      expect(plan.writeMatchArtifacts, isFalse);
      expect(plan.matched, isTrue);
      expect(
        plan.matchDecision,
        MatchCreateLifecycleDecision.idempotentActiveSuccess,
      );
    });

    test('block race — persist Like, refuse match', () {
      final viewerBlock = LikeMatchAtomicityGate.planLike(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: true,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
      );
      expect(viewerBlock.persistOwnLike, isTrue);
      expect(viewerBlock.writeMatchArtifacts, isFalse);
      expect(
        viewerBlock.matchDecision,
        MatchCreateLifecycleDecision.refuseBlockEitherDirection,
      );

      final reverseBlock = LikeMatchAtomicityGate.planLike(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: true,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
      );
      expect(reverseBlock.persistOwnLike, isTrue);
      expect(reverseBlock.writeMatchArtifacts, isFalse);
    });

    test('existing unmatched match — Like persists, no reactivate', () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: true,
        matchState: MatchState.unmatched.name,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
      );
      expect(plan.persistOwnLike, isTrue);
      expect(plan.writeMatchArtifacts, isFalse);
      expect(plan.matched, isFalse);
      expect(
        plan.matchDecision,
        MatchCreateLifecycleDecision.refuseUnmatchedExists,
      );
    });

    test('existing blocked match — Like persists, no reactivate', () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: true,
        matchState: MatchState.blocked.name,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
      );
      expect(plan.persistOwnLike, isTrue);
      expect(plan.writeMatchArtifacts, isFalse);
      expect(
        plan.matchDecision,
        MatchCreateLifecycleDecision.refuseBlockedExists,
      );
    });

    test('Pass must never mutate match/thread', () {
      expect(LikeMatchAtomicityGate.passMayMutateMatchOrThread(), isFalse);
    });
  });

  group('Like/Pass wiring isolation', () {
    test('likeUser delegates to atomic likeAndMaybeCreateMatch', () {
      final swipe = File(
        'lib/features/matching/services/swipe_service.dart',
      ).readAsStringSync();
      expect(swipe.contains('likeAndMaybeCreateMatch'), isTrue);
      // No separate pre-transaction Like write in likeUser.
      expect(swipe.contains('direction\': SwipeDirection.like.name'), isFalse);
      expect(swipe.contains('SwipeDirection.like'), isFalse);
    });

    test('passUser is swipe-only — no match close / create', () {
      final swipe = File(
        'lib/features/matching/services/swipe_service.dart',
      ).readAsStringSync();
      final passIdx = swipe.indexOf('Future<void> passUser');
      final likeIdx = swipe.indexOf('Future<bool> likeUser');
      expect(passIdx, greaterThanOrEqualTo(0));
      expect(likeIdx, greaterThan(passIdx));
      final passBody = swipe.substring(passIdx, likeIdx);
      expect(passBody.contains('SwipeDirection.pass'), isTrue);
      expect(passBody.contains('likeAndMaybeCreateMatch'), isFalse);
      expect(passBody.contains('createMatchIfMutualLike'), isFalse);
      expect(passBody.contains('unmatch'), isFalse);
      expect(passBody.contains('closeRelationship'), isFalse);
      expect(passBody.contains('MatchCloseTarget'), isFalse);
      expect(passBody.contains('matches/'), isFalse);
      expect(passBody.contains('threadDoc'), isFalse);
    });

    test('MatchService writes own Like inside the match transaction', () {
      final src = File(
        'lib/features/matching/services/match_service.dart',
      ).readAsStringSync();
      expect(src.contains('LikeMatchAtomicityGate.planLike'), isTrue);
      expect(src.contains("direction': 'like'"), isTrue);
      expect(src.contains('viewerLikesCandidatePending: true'), isTrue);
      expect(src.contains('runTransaction'), isTrue);
      expect(src.contains('CompatibilityScoring'), isFalse);
      expect(src.contains('DiscoverService'), isFalse);
    });

    test('Like then Pass / Pass on matched — Pass never closes match (source)',
        () {
      final swipe = File(
        'lib/features/matching/services/swipe_service.dart',
      ).readAsStringSync();
      // Pass only sets swipe direction; match lifecycle gates stay untouched.
      expect(swipe.contains('MatchCloseLifecycleGate'), isFalse);
      expect(
        swipe.contains('MatchState.unmatched') ||
            swipe.contains("state': 'unmatched'"),
        isFalse,
      );
    });
  });
}
