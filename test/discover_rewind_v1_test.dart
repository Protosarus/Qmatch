import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String screen;
  late String actionBar;
  late String swipeService;
  late String functionsIndex;

  setUpAll(() {
    screen = File(
      'lib/features/discover/screens/discover_screen.dart',
    ).readAsStringSync();

    actionBar = File(
      'lib/features/discover/widgets/qmatch_discover_action_bar.dart',
    ).readAsStringSync();

    swipeService = File(
      'lib/features/matching/services/swipe_service.dart',
    ).readAsStringSync();

    functionsIndex = File(
      'functions/index.js',
    ).readAsStringSync();
  });

  group('Discover Rewind v2 — Pass + one-sided Like', () {
    test('Rewind tracks Pass and Like as distinct actions', () {
      expect(
        screen.contains('enum _DiscoverRewindKind'),
        isTrue,
      );
      expect(
        screen.contains('pass,'),
        isTrue,
      );
      expect(
        screen.contains('like,'),
        isTrue,
      );
      expect(
        screen.contains('String? _rewindTargetUid;'),
        isTrue,
      );
      expect(
        screen.contains('_DiscoverRewindKind? _rewindKind;'),
        isTrue,
      );
    });

    test('Pass arms Rewind optimistically before backend completion', () {
      final start = screen.indexOf('Future<void> _onPass()');
      final end = screen.indexOf('Future<void> _onRewind()', start);

      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));

      final body = screen.substring(start, end);

      final passCall = body.indexOf('_passUser(c.uid)');
      final arm = body.indexOf('_armRewind(');
      final advance = body.indexOf('_advanceDeck();');

      expect(passCall, greaterThanOrEqualTo(0));
      expect(arm, greaterThan(passCall));
      expect(
        body.contains('kind: _DiscoverRewindKind.pass'),
        isTrue,
      );
      expect(
        body.contains('_DiscoverCommitState.rewindable'),
        isTrue,
      );
      expect(advance, greaterThan(arm));
    });

    test('Like arms Rewind optimistically and resolves commit state later', () {
      final start = screen.indexOf('Future<void> _onLike()');
      expect(start, greaterThanOrEqualTo(0));

      final body = screen.substring(start);

      expect(
        body.contains('_armRewind('),
        isTrue,
      );
      expect(
        body.contains('kind: _DiscoverRewindKind.like'),
        isTrue,
      );
      expect(
        body.contains('_DiscoverCommitState.rewindable'),
        isTrue,
      );
      expect(
        body.contains('_DiscoverCommitState.irreversible'),
        isTrue,
      );
      expect(
        body.contains('_advanceDeck();'),
        isTrue,
      );
    });

    test('Match outcomes do not become Like-Rewind state', () {
      final start = screen.indexOf('Future<void> _onLike()');
      final body = screen.substring(start);

      expect(body.contains('shouldArmLikeRewind'), isTrue);
      expect(
        body.contains('_DiscoverCommitState.rewindable'),
        isTrue,
      );
      expect(
        body.contains('_DiscoverCommitState.irreversible'),
        isTrue,
      );
      expect(
        body.contains('_DiscoverCommitState.notCommitted'),
        isTrue,
      );
      expect(
        body.contains('LikeMatchOutcome.createdNewMatch'),
        isTrue,
      );
      expect(
        body.contains('LikeMatchOutcome.existingActiveMatch'),
        isTrue,
      );

      // Like Rewind is armed optimistically before the backend result.
      expect(
        body.contains(
          'kind: _DiscoverRewindKind.like',
        ),
        isTrue,
      );
    });

    test('Rewind dispatches Pass and Like to separate trusted callables', () {
      final start = screen.indexOf('Future<void> _onRewind()');
      final end = screen.indexOf('Future<void> _onLike()', start);

      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));

      final body = screen.substring(start, end);

      expect(
        body.contains('kind == _DiscoverRewindKind.pass'),
        isTrue,
      );
      expect(
        body.contains('await _rewindPass(targetUid);'),
        isTrue,
      );
      expect(
        body.contains('await _rewindLike(targetUid);'),
        isTrue,
      );
    });

    test('Rewind moves deck optimistically before backend confirmation', () {
      final start = screen.indexOf('Future<void> _onRewind()');
      final end = screen.indexOf('Future<void> _onLike()', start);
      final body = screen.substring(start, end);

      final moveBack = body.indexOf(
        '_currentIndex = previousIndex;',
      );
      final passCall = body.indexOf(
        'await _rewindPass(targetUid);',
      );
      final likeCall = body.indexOf(
        'await _rewindLike(targetUid);',
      );
      final rollback = body.indexOf(
        '_currentIndex = forwardIndex;',
      );

      expect(moveBack, greaterThanOrEqualTo(0));
      expect(passCall, greaterThan(moveBack));
      expect(likeCall, greaterThan(moveBack));
      expect(rollback, greaterThan(passCall));
      expect(rollback, greaterThan(likeCall));
    });

    test('Rewind remains strictly one-step', () {
      final start = screen.indexOf('Future<void> _onRewind()');
      final end = screen.indexOf('Future<void> _onLike()', start);
      final body = screen.substring(start, end);

      expect(
        body.contains('final forwardIndex = _currentIndex;'),
        isTrue,
      );
      expect(
        body.contains('final previousIndex = forwardIndex - 1;'),
        isTrue,
      );
      expect(
        body.contains('_candidates[previousIndex].uid != targetUid'),
        isTrue,
      );
    });

    test('rewound Like becomes actionable again', () {
      final start = screen.indexOf('Future<void> _onRewind()');
      final end = screen.indexOf('Future<void> _onLike()', start);
      final body = screen.substring(start, end);

      expect(
        body.contains('kind == _DiscoverRewindKind.like'),
        isTrue,
      );
      expect(
        body.contains('_likeDispatchedUids.remove(targetUid)'),
        isTrue,
      );
    });

    test('successful Super Resonance invalidates prior Rewind', () {
      final start = screen.indexOf(
        'void _applySendResult(SuperResonanceSendResult result)',
      );
      final end = screen.indexOf(
        'void _showSuperResonanceError',
        start,
      );

      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));

      final body = screen.substring(start, end);

      expect(
        body.contains('_rewindTargetUid = null'),
        isTrue,
      );
      expect(
        body.contains('_rewindKind = null'),
        isTrue,
      );
    });

    test('gesture and action-bar buttons share the same action handlers', () {
      expect(
        screen.contains('onLike: _onLikeAction'),
        isTrue,
      );
      expect(
        screen.contains('onPass: _onPassAction'),
        isTrue,
      );
      expect(
        screen.contains(': _onLikeAction,'),
        isTrue,
      );
      expect(
        screen.contains(': _onPassAction,'),
        isTrue,
      );
    });

    test('normal action bar always exposes Rewind and uses visual loading', () {
      expect(
        screen.contains('showRewind: true'),
        isTrue,
      );
      expect(
        screen.contains('isRewindLoading: _rewindVisualBusy'),
        isTrue,
      );
    });

    test('empty deck keeps Rewind visible and disables it when unavailable',
        () {
      expect(
        screen.contains('QMatchDiscoverRewindButton('),
        isTrue,
      );
      expect(
        screen.contains('_rewindTargetUid == null'),
        isTrue,
      );
    });

    test('Rewind uses dedicated lilac control', () {
      expect(
        actionBar.contains("Key('qmatch-discover-rewind')"),
        isTrue,
      );
      expect(
        actionBar.contains('Icons.undo_rounded'),
        isTrue,
      );
      expect(
        actionBar.contains('class QMatchDiscoverRewindButton'),
        isTrue,
      );
    });

    test('SwipeService exposes both trusted Rewind callables', () {
      expect(
        swipeService.contains(
          "static const String rewindCallableName = 'rewindPass';",
        ),
        isTrue,
      );
      expect(
        swipeService.contains(
          "static const String rewindLikeCallableName = 'rewindLike';",
        ),
        isTrue,
      );
      expect(
        swipeService.contains('Future<bool> rewindPass('),
        isTrue,
      );
      expect(
        swipeService.contains('Future<bool> rewindLike('),
        isTrue,
      );
    });

    test('Cloud Functions export both Rewind handlers', () {
      expect(
        functionsIndex.contains('exports.rewindPass = onCall('),
        isTrue,
      );
      expect(
        functionsIndex.contains('exports.rewindLike = onCall('),
        isTrue,
      );
      expect(
        functionsIndex.contains(
          'rewindPass.handleRewindPass(request)',
        ),
        isTrue,
      );
      expect(
        functionsIndex.contains(
          'rewindLike.handleRewindLike(request)',
        ),
        isTrue,
      );
    });
  });
}
