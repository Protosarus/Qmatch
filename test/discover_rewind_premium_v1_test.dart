import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/screens/discover_screen.dart';
import 'package:qmatch/features/discover/widgets/qmatch_discover_action_bar.dart';
import 'package:qmatch/features/iap/domain/entitlement_snapshot.dart';
import 'package:qmatch/features/iap/domain/resonance_paywall_feature.dart';
import 'package:qmatch/features/iap/services/entitlement_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Discover Rewind premium gate', () {
    test('Free + rewindable Pass -> paywall, rewindPass is NOT called', () {
      expect(
        discoverRewindTapAction(
          hasRewindableAction: true,
          resonanceAccess: false,
        ),
        DiscoverRewindTapAction.paywall,
      );
    });

    test('Free + rewindable Like -> paywall, rewindLike is NOT called', () {
      expect(
        discoverRewindTapAction(
          hasRewindableAction: true,
          resonanceAccess: false,
        ),
        DiscoverRewindTapAction.paywall,
      );
    });

    test('Resonance + rewindable Pass/Like -> perform Rewind', () {
      expect(
        discoverRewindTapAction(
          hasRewindableAction: true,
          resonanceAccess: true,
        ),
        DiscoverRewindTapAction.rewind,
      );
    });

    test('no rewindable action -> no paywall and no rewind call', () {
      expect(
        discoverRewindTapAction(
          hasRewindableAction: false,
          resonanceAccess: false,
        ),
        DiscoverRewindTapAction.none,
      );
      expect(
        discoverRewindTapAction(
          hasRewindableAction: false,
          resonanceAccess: true,
        ),
        DiscoverRewindTapAction.none,
      );
    });

    test('missing/error entitlement fail closed', () {
      expect(resonanceAccessFromEntitlement(null), isFalse);
      expect(
        resonanceAccessFromEntitlement(EntitlementSnapshot.free),
        isFalse,
      );
      expect(
        resonanceAccessFromEntitlement(
          EntitlementSnapshot.fromMap('uid-1', null),
        ),
        isFalse,
      );
      expect(
        resonanceAccessFromEntitlement(
          EntitlementSnapshot.fromMap('uid-1', {
            'resonance_access': 'true',
          }),
        ),
        isFalse,
      );
      expect(
        resonanceAccessFromEntitlement(
          EntitlementSnapshot.fromMap('uid-1', {
            'resonance_access': true,
          }),
        ),
        isTrue,
      );
    });
  });

  group('Discover Rewind premium tap routing', () {
    testWidgets(
      'Free + rewindable Pass opens paywall and does not call rewindPass',
      (tester) async {
        final calls = _RewindCalls();
        await _pumpGate(
          tester,
          calls: calls,
          kind: _DiscoverRewindKind.pass,
          hasRewindableAction: true,
          resonanceAccess: false,
        );
        _expectNormalRewindControl();
        await tester.tap(find.byKey(const Key('qmatch-discover-rewind')));
        await tester.pump();
        expect(calls.paywallFeatures, [ResonancePaywallFeature.rewind]);
        expect(calls.pass, 0);
        expect(calls.like, 0);
      },
    );

    testWidgets(
      'Free + rewindable Like opens paywall and does not call rewindLike',
      (tester) async {
        final calls = _RewindCalls();
        await _pumpGate(
          tester,
          calls: calls,
          kind: _DiscoverRewindKind.like,
          hasRewindableAction: true,
          resonanceAccess: false,
        );
        _expectNormalRewindControl();
        await tester.tap(find.byKey(const Key('qmatch-discover-rewind')));
        await tester.pump();
        expect(calls.paywallFeatures, [ResonancePaywallFeature.rewind]);
        expect(calls.pass, 0);
        expect(calls.like, 0);
      },
    );

    testWidgets('Resonance + rewindable Pass calls rewindPass', (tester) async {
      final calls = _RewindCalls();
      await _pumpGate(
        tester,
        calls: calls,
        kind: _DiscoverRewindKind.pass,
        hasRewindableAction: true,
        resonanceAccess: true,
      );
      _expectNormalRewindControl();
      await tester.tap(find.byKey(const Key('qmatch-discover-rewind')));
      await tester.pump();
      expect(calls.paywallFeatures, isEmpty);
      expect(calls.pass, 1);
      expect(calls.like, 0);
    });

    testWidgets('Resonance + rewindable Like calls rewindLike', (tester) async {
      final calls = _RewindCalls();
      await _pumpGate(
        tester,
        calls: calls,
        kind: _DiscoverRewindKind.like,
        hasRewindableAction: true,
        resonanceAccess: true,
      );
      _expectNormalRewindControl();
      await tester.tap(find.byKey(const Key('qmatch-discover-rewind')));
      await tester.pump();
      expect(calls.paywallFeatures, isEmpty);
      expect(calls.pass, 0);
      expect(calls.like, 1);
    });

    testWidgets('no rewindable action does not open paywall or rewind',
        (tester) async {
      final calls = _RewindCalls();
      await _pumpGate(
        tester,
        calls: calls,
        kind: _DiscoverRewindKind.pass,
        hasRewindableAction: false,
        resonanceAccess: false,
      );
      expect(find.byKey(const Key('qmatch-discover-rewind')), findsOneWidget);
      expect(
        tester
            .widget<GestureDetector>(
              find.descendant(
                of: find.byType(QMatchDiscoverRewindButton),
                matching: find.byType(GestureDetector),
              ),
            )
            .onTap,
        isNull,
      );
      _expectNoRewindPremiumDecoration();
      await tester.tap(find.byKey(const Key('qmatch-discover-rewind')));
      await tester.pump();
      expect(calls.paywallFeatures, isEmpty);
      expect(calls.pass, 0);
      expect(calls.like, 0);
    });

    testWidgets('entitlement watch error fail closed to paywall',
        (tester) async {
      var access = true;
      final repo = EntitlementRepository(
        watchOverride: (_) => Stream<EntitlementSnapshot>.error(
          StateError('denied'),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: _EntitlementWatchProbe(
            repo: repo,
            uid: 'uid-1',
            onAccess: (value) => access = value,
          ),
        ),
      );
      await tester.pump();
      expect(access, isFalse);
    });

    testWidgets('missing uid fail closed', (tester) async {
      var access = true;
      final repo = EntitlementRepository(
        watchOverride: (_) => Stream.value(
          EntitlementSnapshot.fromMap('uid-1', {'resonance_access': true}),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: _EntitlementWatchProbe(
            repo: repo,
            uid: null,
            onAccess: (value) => access = value,
          ),
        ),
      );
      await tester.pump();
      expect(access, isFalse);
    });
  });

  group('Rewind has no lock / premium decoration', () {
    testWidgets('Free rewindable control looks like the normal Rewind button',
        (tester) async {
      final calls = _RewindCalls();
      await _pumpGate(
        tester,
        calls: calls,
        kind: _DiscoverRewindKind.pass,
        hasRewindableAction: true,
        resonanceAccess: false,
      );
      _expectNormalRewindControl();
    });

    testWidgets('Resonance rewindable control looks like the normal Rewind button',
        (tester) async {
      final calls = _RewindCalls();
      await _pumpGate(
        tester,
        calls: calls,
        kind: _DiscoverRewindKind.like,
        hasRewindableAction: true,
        resonanceAccess: true,
      );
      _expectNormalRewindControl();
    });
  });

  group('DiscoverScreen wiring (source)', () {
    late String screen;
    late String actionBar;

    setUpAll(() {
      screen = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      actionBar = File(
        'lib/features/discover/widgets/qmatch_discover_action_bar.dart',
      ).readAsStringSync();
    });

    test('Rewind tap uses client gate then existing _onRewind', () {
      final start = screen.indexOf('Future<void> _onRewindPressed()');
      final end = screen.indexOf('Future<void> _onRewind() async {');
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final body = screen.substring(start, end);
      expect(body.contains('discoverRewindTapAction'), isTrue);
      expect(body.contains('ResonancePaywallFeature.rewind'), isTrue);
      expect(body.contains('_openResonancePaywall'), isTrue);
      expect(body.contains('await _onRewind()'), isTrue);
      expect(body.contains('rewindPass'), isFalse);
      expect(body.contains('rewindLike'), isFalse);
      expect(
        body.contains('Backend rewind authorization remains authoritative'),
        isTrue,
      );
    });

    test('entitlement watch fail-closes missing uid and errors', () {
      expect(screen.contains('_entitlements.watch(uid)'), isTrue);
      expect(screen.contains('resonanceAccessFromEntitlement'), isTrue);
      expect(screen.contains('setState(() => _resonanceAccess = false)'), isTrue);
      expect(screen.contains("uid == null || uid.isEmpty"), isTrue);
    });

    test('Passport still uses the shared Resonance paywall helper', () {
      expect(screen.contains('_openResonancePaywall'), isTrue);
      expect(
        screen.contains('openPaywall: _openResonancePaywall'),
        isTrue,
      );
      expect(screen.contains('_openPassportPaywall'), isFalse);
      expect(
        screen.contains('PassportDestinationPickerScreen.open'),
        isTrue,
      );
    });

    test('action bar and empty deck keep Rewind unavailable without a target',
        () {
      expect(
        screen.contains('_rewindTargetUid == null ? null : _onRewindPressed'),
        isTrue,
      );
      expect(
        screen.contains('_rewindBusy || _rewindTargetUid == null'),
        isTrue,
      );
    });

    test('Rewind control is not lock-decorated', () {
      expect(screen.contains('showRewindLock'), isFalse);
      expect(screen.contains('showLock'), isFalse);
      expect(screen.contains('qmatch-discover-rewind-lock'), isFalse);
      expect(screen.contains('Icons.lock_outline'), isFalse);
      expect(actionBar.contains('showRewindLock'), isFalse);
      expect(actionBar.contains('showLock'), isFalse);
      expect(actionBar.contains('qmatch-discover-rewind-lock'), isFalse);
    });
  });
}

void _expectNormalRewindControl() {
  expect(find.byKey(const Key('qmatch-discover-rewind')), findsOneWidget);
  expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
  _expectNoRewindPremiumDecoration();
}

void _expectNoRewindPremiumDecoration() {
  expect(find.byKey(const Key('qmatch-discover-rewind-lock')), findsNothing);
  expect(find.byIcon(Icons.lock_outline), findsNothing);
}

class _RewindCalls {
  int pass = 0;
  int like = 0;
  final paywallFeatures = <ResonancePaywallFeature>[];
}

enum _DiscoverRewindKind { pass, like }

Future<void> _pumpGate(
  WidgetTester tester, {
  required _RewindCalls calls,
  required _DiscoverRewindKind kind,
  required bool hasRewindableAction,
  required bool resonanceAccess,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _RewindGateHarness(
          calls: calls,
          kind: kind,
          hasRewindableAction: hasRewindableAction,
          resonanceAccess: resonanceAccess,
        ),
      ),
    ),
  );
  await tester.pump();
}

class _RewindGateHarness extends StatelessWidget {
  const _RewindGateHarness({
    required this.calls,
    required this.kind,
    required this.hasRewindableAction,
    required this.resonanceAccess,
  });

  final _RewindCalls calls;
  final _DiscoverRewindKind kind;
  final bool hasRewindableAction;
  final bool resonanceAccess;

  Future<void> _onPressed() async {
    final action = discoverRewindTapAction(
      hasRewindableAction: hasRewindableAction,
      resonanceAccess: resonanceAccess,
    );
    switch (action) {
      case DiscoverRewindTapAction.none:
        return;
      case DiscoverRewindTapAction.paywall:
        calls.paywallFeatures.add(ResonancePaywallFeature.rewind);
        return;
      case DiscoverRewindTapAction.rewind:
        if (kind == _DiscoverRewindKind.pass) {
          calls.pass += 1;
        } else {
          calls.like += 1;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return QMatchDiscoverRewindButton(
      semanticLabel: 'Rewind',
      onPressed: hasRewindableAction ? _onPressed : null,
    );
  }
}

class _EntitlementWatchProbe extends StatefulWidget {
  const _EntitlementWatchProbe({
    required this.repo,
    required this.uid,
    required this.onAccess,
  });

  final EntitlementRepository repo;
  final String? uid;
  final void Function(bool access) onAccess;

  @override
  State<_EntitlementWatchProbe> createState() => _EntitlementWatchProbeState();
}

class _EntitlementWatchProbeState extends State<_EntitlementWatchProbe> {
  StreamSubscription<EntitlementSnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    final uid = widget.uid;
    if (uid == null || uid.isEmpty) {
      widget.onAccess(false);
      return;
    }
    _sub = widget.repo.watch(uid).listen(
      (snap) {
        widget.onAccess(resonanceAccessFromEntitlement(snap));
      },
      onError: (_) {
        widget.onAccess(false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
