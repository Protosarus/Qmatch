import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/navigation/qmatch_main_shell.dart';
import 'package:qmatch/core/theme/app_spacing.dart';

void main() {
  testWidgets('shell renders all tabs with discover selected by default', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrapWithMediaQuery(
        const _ShellHarness(
          pages: [
            _InitTrackedPage(label: 'Discover content', pageId: 'discover'),
            _InitTrackedPage(label: 'Messages content', pageId: 'messages'),
            _InitTrackedPage(label: 'Profile content', pageId: 'profile'),
          ],
        ),
      ),
    );

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Discover content'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Discover',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Messages',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Profile',
      ),
      findsOneWidget,
    );

    final safeArea = tester.widget<SafeArea>(
      find.byKey(const Key('qmatch-bottom-nav-safe-area')),
    );
    expect(safeArea.minimum.bottom, AppSpacing.xs);

    expect(
      tester.getSize(find.byKey(const Key('qmatch-nav-indicator-0'))).width,
      14,
    );
    expect(
      tester.getSize(find.byKey(const Key('qmatch-nav-indicator-1'))).width,
      0,
    );

    semanticsHandle.dispose();
  });

  testWidgets('tab order, switching, and page state are preserved', (
    tester,
  ) async {
    _InitTrackedPage.initCounts.clear();

    await tester.pumpWidget(
      _wrapWithMediaQuery(
        const _ShellHarness(
          pages: [
            _CounterPage(label: 'Discover content', pageId: 'discover'),
            _CounterPage(label: 'Messages content', pageId: 'messages'),
            _CounterPage(label: 'Profile content', pageId: 'profile'),
          ],
        ),
      ),
    );

    expect(_InitTrackedPage.initCounts['discover'], 1);
    expect(_InitTrackedPage.initCounts['messages'], 1);
    expect(_InitTrackedPage.initCounts['profile'], 1);

    await tester.tap(find.byKey(const Key('counter-button-discover')));
    await tester.pumpAndSettle();
    expect(find.text('Discover content: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('qmatch-nav-item-1')));
    await tester.pumpAndSettle();
    expect(find.text('Messages content: 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('qmatch-nav-item-2')));
    await tester.pumpAndSettle();
    expect(find.text('Profile content: 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('qmatch-nav-item-0')));
    await tester.pumpAndSettle();
    expect(find.text('Discover content: 1'), findsOneWidget);

    expect(
      tester.getSize(find.byKey(const Key('qmatch-nav-indicator-0'))).width,
      14,
    );
    expect(
      tester.getSize(find.byKey(const Key('qmatch-nav-indicator-1'))).width,
      0,
    );
    expect(_InitTrackedPage.initCounts['discover'], 1);
    expect(_InitTrackedPage.initCounts['messages'], 1);
    expect(_InitTrackedPage.initCounts['profile'], 1);
  });

  test('shell source stays presentation-only and uses current content screens',
      () {
    final shellSource = File(
      'lib/core/navigation/qmatch_main_shell.dart',
    ).readAsStringSync();
    final navSource = File(
      'lib/core/navigation/main_navigation_screen.dart',
    ).readAsStringSync();

    expect(shellSource.contains('firebase_'), isFalse);
    expect(shellSource.contains('Firebase'), isFalse);
    expect(shellSource.contains('assessment/services'), isFalse);
    expect(shellSource.contains('core_method'), isFalse);
    expect(shellSource.contains('ProfileService'), isFalse);

    expect(navSource.contains('DiscoverScreen()'), isTrue);
    expect(navSource.contains('MessagesScreen()'), isTrue);
    expect(navSource.contains('ProfileScreen()'), isTrue);
    expect(navSource.contains('SettingsScreen'), isFalse);
  });
}

Widget _wrapWithMediaQuery(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        padding: EdgeInsets.only(bottom: 34),
        viewPadding: EdgeInsets.only(bottom: 34),
      ),
      child: child,
    ),
  );
}

class _ShellHarness extends StatefulWidget {
  const _ShellHarness({required this.pages});

  final List<Widget> pages;

  @override
  State<_ShellHarness> createState() => _ShellHarnessState();
}

class _ShellHarnessState extends State<_ShellHarness> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return QMatchMainShell(
      currentIndex: _currentIndex,
      onTabSelected: (index) => setState(() => _currentIndex = index),
      pages: widget.pages,
      items: const [
        QMatchBottomNavigationItem(
          icon: Icons.explore_rounded,
          label: 'Discover',
        ),
        QMatchBottomNavigationItem(
          icon: Icons.chat_bubble_rounded,
          label: 'Messages',
        ),
        QMatchBottomNavigationItem(
          icon: Icons.person_rounded,
          label: 'Profile',
        ),
      ],
    );
  }
}

class _InitTrackedPage extends StatefulWidget {
  const _InitTrackedPage({required this.label, required this.pageId});

  final String label;
  final String pageId;

  static final Map<String, int> initCounts = <String, int>{};

  @override
  State<_InitTrackedPage> createState() => _InitTrackedPageState();
}

class _InitTrackedPageState extends State<_InitTrackedPage> {
  @override
  void initState() {
    super.initState();
    _InitTrackedPage.initCounts.update(
      widget.pageId,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: Text(widget.label)),
    );
  }
}

class _CounterPage extends StatefulWidget {
  const _CounterPage({required this.label, required this.pageId});

  final String label;
  final String pageId;

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _InitTrackedPage.initCounts.update(
      widget.pageId,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.label}: $_count'),
            ElevatedButton(
              key: Key('counter-button-${widget.pageId}'),
              onPressed: () => setState(() => _count++),
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
