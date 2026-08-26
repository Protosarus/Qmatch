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

    test('successful Pass becomes rewindable only after Pass write', () {
      final start = screen.indexOf('Future<void> _onPass()');
      final end = screen.indexOf('Future<void> _onRewind()', start);

      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));

      final body = screen.substring(start, end);

      final passCall = body.indexOf('_passUser(c.uid)');
      final targetSet = body.indexOf('_rewindTargetUid = c.uid');
      final kindSet = body.indexOf(
        '_rewindKind = _DiscoverRewindKind.pass',
      );
      final advance = body.indexOf('_advance();');

      expect(passCall, greaterThanOrEqualTo(0));
      expect(targetSet, greaterThan(passCall));
      expect(kindSet, greaterThan(passCall));
      expect(advance, greaterThan(kindSet));
    });

    test('one-sided Like becomes rewindable only for noMatch', () {
      final start = screen.indexOf('Future<void> _onLike()');
      expect(start, greaterThanOrEqualTo(0));

      final body = screen.substring(start);

      expect(
        body.contains('outcome == LikeMatchOutcome.noMatch'),
        isTrue,
      );
      expect(
        body.contains('await advanceFuture;'),
        isTrue,
      );
      expect(
        body.contains('_rewindTargetUid = c.uid'),
        isTrue,
      );
      expect(
        body.contains('_rewindKind = _DiscoverRewindKind.like'),
        isTrue,
      );
    });

    test('Match outcomes do not become Like-Rewind state', () {
      final start = screen.indexOf('Future<void> _onLike()');
      final body = screen.substring(start);

      final noMatch = body.indexOf(
        'outcome == LikeMatchOutcome.noMatch',
      );
      final createdMatch = body.indexOf(
        'outcome == LikeMatchOutcome.createdNewMatch',
      );

      expect(noMatch, greaterThanOrEqualTo(0));
      expect(createdMatch, greaterThan(noMatch));

      final noMatchBlock = body.substring(noMatch, createdMatch);
      expect(
        noMatchBlock.contains(
          '_rewindKind = _DiscoverRewindKind.like',
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

    test('normal action bar exposes Rewind when an action is rewindable', () {
      expect(
        screen.contains('showRewind: _rewindTargetUid != null'),
        isTrue,
      );
      expect(
        screen.contains('isRewindLoading: _rewindBusy'),
        isTrue,
      );
    });

    test('empty deck preserves final-card Rewind', () {
      expect(
        screen.contains('if (_rewindTargetUid != null)'),
        isTrue,
      );
      expect(
        screen.contains('QMatchDiscoverRewindButton('),
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
