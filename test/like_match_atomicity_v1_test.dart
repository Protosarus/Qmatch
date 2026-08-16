import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/models/match_model.dart';
import 'package:qmatch/features/matching/services/like_match_atomicity_gate.dart';
import 'package:qmatch/features/matching/services/match_create_lifecycle_gate.dart';

LikeMatchAtomicPlan _plan({
  required bool matchExists,
  String? matchState,
  bool viewerBlockedCandidate = false,
  bool candidateBlockedViewer = false,
  bool viewerLikesCandidatePending = true,
  bool candidateLikesViewer = false,
  bool viewerLiveEligible = true,
  bool targetLiveEligible = true,
}) {
  return LikeMatchAtomicityGate.planLike(
    matchExists: matchExists,
    matchState: matchState,
    viewerBlockedCandidate: viewerBlockedCandidate,
    candidateBlockedViewer: candidateBlockedViewer,
    viewerLikesCandidatePending: viewerLikesCandidatePending,
    candidateLikesViewer: candidateLikesViewer,
    viewerLiveEligible: viewerLiveEligible,
    targetLiveEligible: targetLiveEligible,
  );
}

void main() {
  group('LikeMatchAtomicityGate', () {
    test('first Like (no reverse) persists Like, no match', () {
      final plan = _plan(
        matchExists: false,
        matchState: null,
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
      final plan = _plan(
        matchExists: false,
        matchState: null,
        candidateLikesViewer: true,
      );
      expect(plan.persistOwnLike, isTrue);
      expect(plan.writeMatchArtifacts, isTrue);
      expect(plan.matched, isTrue);
      expect(plan.matchDecision, MatchCreateLifecycleDecision.createNew);
    });

    test('simultaneous/retry Like with active match is idempotent success', () {
      final plan = _plan(
        matchExists: true,
        matchState: MatchState.active.name,
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
      final viewerBlock = _plan(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: true,
        candidateLikesViewer: true,
      );
      expect(viewerBlock.persistOwnLike, isTrue);
      expect(viewerBlock.writeMatchArtifacts, isFalse);
      expect(
        viewerBlock.matchDecision,
        MatchCreateLifecycleDecision.refuseBlockEitherDirection,
      );

      final reverseBlock = _plan(
        matchExists: false,
        matchState: null,
        candidateBlockedViewer: true,
        candidateLikesViewer: true,
      );
      expect(reverseBlock.persistOwnLike, isTrue);
      expect(reverseBlock.writeMatchArtifacts, isFalse);
    });

    test('existing unmatched match — Like persists, no reactivate', () {
      final plan = _plan(
        matchExists: true,
        matchState: MatchState.unmatched.name,
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
      final plan = _plan(
        matchExists: true,
        matchState: MatchState.blocked.name,
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
      final likeIdx = swipe.indexOf('Future<LikeMatchOutcome> likeUser');
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
      expect(src.contains('MatchLiveUserValidityGate'), isTrue);
      expect(src.contains('runTransaction'), isTrue);
      expect(src.contains('CompatibilityScoring'), isFalse);
      expect(src.contains('DiscoverService'), isFalse);
      // Reverse-block is rules-enforced; never GET peer block docs.
      expect(src.contains('userBlockDoc(targetUid, currentUid)'), isFalse);
      expect(src.contains('candidateBlockedViewer: false'), isTrue);
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
