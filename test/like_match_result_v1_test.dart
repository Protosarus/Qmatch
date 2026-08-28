import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/services/like_match_outcome.dart';

void main() {
  group('LikeMatchResult.fromWire', () {
    test('no_match + true => Rewind is armed', () {
      final result = LikeMatchResult.fromWire({
        'outcome': 'no_match',
        'like_rewindable': true,
      });
      expect(result.outcome, LikeMatchOutcome.noMatch);
      expect(result.likeRewindable, isTrue);
      expect(result.shouldArmLikeRewind, isTrue);
    });

    test('no_match + false => Rewind is NOT armed', () {
      final result = LikeMatchResult.fromWire({
        'outcome': 'no_match',
        'like_rewindable': false,
      });
      expect(result.outcome, LikeMatchOutcome.noMatch);
      expect(result.likeRewindable, isFalse);
      expect(result.shouldArmLikeRewind, isFalse);
    });

    test('created_new_match => no Rewind', () {
      final result = LikeMatchResult.fromWire({
        'outcome': 'created_new_match',
        'like_rewindable': false,
      });
      expect(result.outcome, LikeMatchOutcome.createdNewMatch);
      expect(result.likeRewindable, isFalse);
      expect(result.shouldArmLikeRewind, isFalse);
    });

    test('existing_active_match => no Rewind', () {
      final result = LikeMatchResult.fromWire({
        'outcome': 'existing_active_match',
        'like_rewindable': false,
      });
      expect(result.outcome, LikeMatchOutcome.existingActiveMatch);
      expect(result.likeRewindable, isFalse);
      expect(result.shouldArmLikeRewind, isFalse);
    });

    test('missing like_rewindable => false', () {
      final result = LikeMatchResult.fromWire({
        'outcome': 'no_match',
      });
      expect(result.outcome, LikeMatchOutcome.noMatch);
      expect(result.likeRewindable, isFalse);
      expect(result.shouldArmLikeRewind, isFalse);
    });

    test('non-true like_rewindable values fail closed', () {
      expect(
        LikeMatchResult.fromWire({
          'outcome': 'no_match',
          'like_rewindable': 'true',
        }).likeRewindable,
        isFalse,
      );
      expect(
        LikeMatchResult.fromWire({
          'outcome': 'no_match',
          'like_rewindable': 1,
        }).likeRewindable,
        isFalse,
      );
      expect(
        LikeMatchResult.fromWire({
          'outcome': 'no_match',
          'like_rewindable': null,
        }).likeRewindable,
        isFalse,
      );
    });

    test('match outcomes never arm Rewind even if like_rewindable is true', () {
      expect(
        LikeMatchResult.fromWire({
          'outcome': 'created_new_match',
          'like_rewindable': true,
        }).shouldArmLikeRewind,
        isFalse,
      );
      expect(
        LikeMatchResult.fromWire({
          'outcome': 'existing_active_match',
          'like_rewindable': true,
        }).shouldArmLikeRewind,
        isFalse,
      );
    });

    test('does not leak internal refusal or block fields', () {
      final result = LikeMatchResult.fromWire({
        'outcome': 'no_match',
        'like_rewindable': false,
        'reason': 'secret-block-reason',
        'blocked_uid': 'userB',
        'matchDecision': 'refuseBlockEitherDirection',
      });
      expect(result.outcome, LikeMatchOutcome.noMatch);
      expect(result.likeRewindable, isFalse);
      final encoded = '${result.outcome} ${result.likeRewindable}';
      expect(encoded.contains('secret-block-reason'), isFalse);
      expect(encoded.contains('blocked_uid'), isFalse);
      expect(encoded.contains('refuseBlockEitherDirection'), isFalse);
    });
  });

  group('Discover Like commit wiring (source)', () {
    late String screen;

    setUpAll(() {
      screen = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
    });

    test('Like no longer treats every no_match as rewindable', () {
      final start = screen.indexOf('Future<void> _onLike()');
      expect(start, greaterThanOrEqualTo(0));
      final body = screen.substring(start);

      expect(
        body.contains('outcome == LikeMatchOutcome.noMatch'),
        isFalse,
      );
      expect(body.contains('shouldArmLikeRewind'), isTrue);
      expect(body.contains('like_rewindable'), isFalse);
    });

    test('commit state maps match / rewindable / non-rewindable outcomes', () {
      final start = screen.indexOf('Future<void> _onLike()');
      final body = screen.substring(start);

      expect(
        body.contains('LikeMatchOutcome.createdNewMatch'),
        isTrue,
      );
      expect(
        body.contains('LikeMatchOutcome.existingActiveMatch'),
        isTrue,
      );
      expect(
        body.contains('_DiscoverCommitState.irreversible'),
        isTrue,
      );
      expect(
        body.contains('_DiscoverCommitState.rewindable'),
        isTrue,
      );
      expect(
        body.contains('_DiscoverCommitState.notCommitted'),
        isTrue,
      );
    });
  });

  group('MatchService / SwipeService result contract (source)', () {
    test('callable parse returns LikeMatchResult from public payload keys', () {
      final match = File(
        'lib/features/matching/services/match_service.dart',
      ).readAsStringSync();
      final swipe = File(
        'lib/features/matching/services/swipe_service.dart',
      ).readAsStringSync();
      final outcome = File(
        'lib/features/matching/services/like_match_outcome.dart',
      ).readAsStringSync();

      expect(
        match.contains('Future<LikeMatchResult> likeAndMaybeCreateMatch'),
        isTrue,
      );
      expect(match.contains('LikeMatchResult.fromWire(raw)'), isTrue);
      expect(match.contains("'like_rewindable'"), isFalse);
      expect(swipe.contains('Future<LikeMatchResult> likeUser'), isTrue);
      expect(outcome.contains("map['like_rewindable'] == true"), isTrue);
      expect(outcome.contains('blocked_uid'), isFalse);
      expect(outcome.contains('matchDecision'), isFalse);
    });
  });
}
