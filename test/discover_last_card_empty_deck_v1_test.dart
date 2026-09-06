import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/widgets/discover_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const actionBar = Key('qmatch-discover-action-bar');
  const empty = Key('qmatch-discover-empty');
  const emptyRetry = Key('qmatch-discover-empty-retry');
  const likeButton = Key('qmatch-discover-like');
  const passButton = Key('qmatch-discover-pass');

  late String src;
  late String likeBody;
  late String passBody;
  late String buildBody;

  setUpAll(() {
    src = File(
      'lib/features/discover/screens/discover_screen.dart',
    ).readAsStringSync();
    final likeIdx = src.indexOf('Future<void> _onLike() async {');
    final buildIdx = src.indexOf('Widget build(BuildContext context)');
    final passIdx = src.indexOf('Future<void> _onPass() {');
    final bodyIdx = src.indexOf('Widget _buildBody() {');
    expect(likeIdx, greaterThanOrEqualTo(0));
    expect(passIdx, greaterThanOrEqualTo(0));
    expect(buildIdx, greaterThan(likeIdx));
    expect(likeIdx, greaterThan(passIdx));
    expect(bodyIdx, greaterThan(buildIdx));
    likeBody = src.substring(likeIdx, buildIdx);
    passBody = src.substring(passIdx, likeIdx);
    buildBody = src.substring(bodyIdx);
  });

  test('last Like hides action bar immediately', () {
    expect(likeBody.contains('_isLastCandidate'), isTrue);
    expect(likeBody.contains('_lastCardCommitted = true'), isTrue);
    expect(
      likeBody.indexOf('_lastCardCommitted = true') <
          likeBody.indexOf('QMatchDiscoverSwipeableCard.flyOffDuration'),
      isTrue,
    );
    expect(likeBody.contains('_isActionLoading'), isTrue);
    expect(likeBody.contains('_loadCandidates'), isFalse);
    expect(buildBody.contains('if (!_lastCardCommitted)'), isTrue);
    expect(
      buildBody.indexOf('if (!_lastCardCommitted)') <
          buildBody.indexOf('QMatchDiscoverActionBar'),
      isTrue,
    );
  });

  test('last Pass hides action bar immediately', () {
    expect(passBody.contains('_isLastCandidate'), isTrue);
    expect(passBody.contains('_lastCardCommitted = true'), isTrue);
    expect(
      passBody.indexOf('_lastCardCommitted = true') <
          passBody.indexOf('passUser(c.uid)'),
      isTrue,
    );
    expect(passBody.contains('_isActionLoading = true'), isTrue);
    expect(passBody.contains('_loadCandidates'), isFalse);
    expect(buildBody.contains('if (!_lastCardCommitted)'), isTrue);
  });

  test('empty state appears after commit', () {
    expect(
      likeBody.indexOf('QMatchDiscoverSwipeableCard.flyOffDuration') <
          likeBody.indexOf('_advanceDeck()'),
      isTrue,
    );
    expect(passBody.contains('QMatchDiscoverSwipeableCard.flyOffDuration'),
        isTrue);
    expect(
      passBody.indexOf('QMatchDiscoverSwipeableCard.flyOffDuration') <
          passBody.indexOf('_advanceDeck()'),
      isTrue,
    );
    expect(buildBody.contains('QMatchDiscoverEmptyState'), isTrue);
    expect(
      buildBody.contains(
        'onRetry: passportEmpty ? _openPassportPicker : _loadCandidates',
      ),
      isTrue,
    );
    final emptyIdx = buildBody.indexOf('if (c == null)');
    final cardIdx = buildBody.indexOf('QMatchDiscoverSwipeableCard');
    expect(emptyIdx, greaterThanOrEqualTo(0));
    expect(cardIdx, greaterThan(emptyIdx));
    final emptyBranch = buildBody.substring(emptyIdx, cardIdx);
    expect(emptyBranch.contains('QMatchDiscoverEmptyState'), isTrue);
    expect(emptyBranch.contains('QMatchDiscoverActionBar'), isFalse);
    expect(src.contains('getCandidates'), isTrue);
    expect(likeBody.contains('getCandidates'), isFalse);
    expect(passBody.contains('getCandidates'), isFalse);
  });

  testWidgets('last Like hides action bar immediately', (tester) async {
    await tester.pumpWidget(
      _chrome(
        hasCandidate: true,
        lastCardCommitted: true,
      ),
    );
    expect(find.byKey(actionBar), findsNothing);
    expect(find.byKey(likeButton), findsNothing);
    expect(find.byKey(passButton), findsNothing);
    expect(find.byKey(empty), findsNothing);
    expect(find.text('candidate'), findsOneWidget);
  });

  testWidgets('last Pass hides action bar immediately', (tester) async {
    await tester.pumpWidget(
      _chrome(
        hasCandidate: true,
        lastCardCommitted: true,
      ),
    );
    expect(find.byKey(actionBar), findsNothing);
    expect(find.byKey(likeButton), findsNothing);
    expect(find.byKey(passButton), findsNothing);
  });

  testWidgets('empty state appears after commit', (tester) async {
    await tester.pumpWidget(
      _chrome(
        hasCandidate: true,
        lastCardCommitted: true,
      ),
    );
    expect(find.byKey(actionBar), findsNothing);
    expect(find.byKey(empty), findsNothing);

    await tester.pumpWidget(
      _chrome(
        hasCandidate: false,
        lastCardCommitted: true,
      ),
    );
    expect(find.byKey(empty), findsOneWidget);
    expect(find.byKey(emptyRetry), findsOneWidget);
    expect(find.byKey(actionBar), findsNothing);
    expect(find.byKey(likeButton), findsNothing);
    expect(find.byKey(passButton), findsNothing);
  });
}

Widget _chrome({
  required bool hasCandidate,
  required bool lastCardCommitted,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          if (hasCandidate) ...[
            const Expanded(child: Center(child: Text('candidate'))),
            if (!lastCardCommitted)
              QMatchDiscoverActionBar(
                passLabel: 'Pass',
                likeLabel: 'Like',
                onPass: () {},
                onLike: () {},
                isActionLoading: false,
              ),
          ] else
            const Expanded(
              child: QMatchDiscoverEmptyState(
                title: 'No profiles',
                body: 'Try later',
                retryLabel: 'Retry',
                onRetry: _noop,
              ),
            ),
        ],
      ),
    ),
  );
}

void _noop() {}
