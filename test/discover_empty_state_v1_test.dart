import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/widgets/discover_widgets.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const actionBar = Key('qmatch-discover-action-bar');
  const empty = Key('qmatch-discover-empty');
  const emptyRetry = Key('qmatch-discover-empty-retry');
  const likeButton = Key('qmatch-discover-like');
  const passButton = Key('qmatch-discover-pass');

  Future<void> pumpEmpty(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    VoidCallback? onRetry,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                children: [
                  Expanded(
                    child: QMatchDiscoverEmptyState(
                      title: l10n.discoverEmptyTitle,
                      body: l10n.discoverEmptySubtitle,
                      retryLabel: l10n.discoverEmptyRetry,
                      onRetry: onRetry ?? () {},
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('EN empty state is centered cosmic copy without action buttons',
      (tester) async {
    await pumpEmpty(tester);

    expect(find.byKey(empty), findsOneWidget);
    expect(find.text('No new profiles for now'), findsOneWidget);
    expect(
      find.text('New match candidates will appear here as they arrive.'),
      findsOneWidget,
    );
    expect(find.text('Check again'), findsOneWidget);
    expect(find.byKey(emptyRetry), findsOneWidget);
    expect(find.byKey(actionBar), findsNothing);
    expect(find.byKey(likeButton), findsNothing);
    expect(find.byKey(passButton), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('TR empty state uses specified copy', (tester) async {
    await pumpEmpty(tester, locale: const Locale('tr'));

    expect(find.text('Şimdilik yeni profil yok'), findsOneWidget);
    expect(
      find.text('Yeni eşleşme adayları geldikçe burada görünecek.'),
      findsOneWidget,
    );
    expect(find.text('Tekrar kontrol et'), findsOneWidget);
    expect(find.byKey(actionBar), findsNothing);
  });

  testWidgets('Check again triggers the provided reload callback once',
      (tester) async {
    var taps = 0;
    await pumpEmpty(tester, onRetry: () => taps++);
    await tester.tap(find.byKey(emptyRetry));
    await tester.pump();
    expect(taps, 1);
  });

  test('empty deck wiring never shows action bar and never auto-refreshes', () {
    final src = File(
      'lib/features/discover/screens/discover_screen.dart',
    ).readAsStringSync();
    final bodyIdx = src.indexOf('Widget _buildBody() {');
    final emptyIdx = src.indexOf('if (c == null)', bodyIdx);
    final cardIdx = src.indexOf('QMatchDiscoverSwipeableCard', bodyIdx);
    expect(emptyIdx, greaterThan(bodyIdx));
    expect(cardIdx, greaterThan(emptyIdx));
    final emptyBranch = src.substring(emptyIdx, cardIdx);
    expect(emptyBranch.contains('QMatchDiscoverEmptyState'), isTrue);
    expect(emptyBranch.contains('discoverEmptyRetry'), isTrue);
    expect(
      emptyBranch.contains(
        'onRetry: passportEmpty ? _openPassportPicker : _loadCandidates',
      ),
      isTrue,
    );
    expect(emptyBranch.contains('QMatchDiscoverActionBar'), isFalse);
    expect(src.contains('Timer('), isFalse);
    expect(src.contains('periodic'), isFalse);
  });
}
