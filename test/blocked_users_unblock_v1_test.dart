import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/features/settings/screens/blocked_users_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Unblock button is enabled and uses helper; row disappears',
      (tester) async {
    final controller = StreamController<List<String>>(sync: true);
    addTearDown(controller.close);
    final blocked = <String>['peer_a'];
    var helperCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: BlockedUsersScreen(
          blocksStream: controller.stream,
          unblockUser: ({required String blockedUid}) async {
            helperCalls++;
            expect(blockedUid, 'peer_a');
            blocked.remove(blockedUid);
            controller.add(List<String>.from(blocked));
          },
        ),
      ),
    );
    controller.add(List<String>.from(blocked));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final button = tester.widget<TextButton>(
      find.byKey(const Key('qmatch-blocked-unblock-peer_a')),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('Unblock'), findsOneWidget);
    expect(find.text('peer_a'), findsOneWidget);

    await tester.tap(find.byKey(const Key('qmatch-blocked-unblock-peer_a')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(helperCalls, 1);
    expect(find.text('peer_a'), findsNothing);
    expect(find.text('No blocked users'), findsOneWidget);
  });

  test('BlockedUsersScreen uses SafetyService.unblockUser', () {
    final src = File(
      'lib/features/settings/screens/blocked_users_screen.dart',
    ).readAsStringSync();
    expect(src.contains('SafetyService().unblockUser'), isTrue);
    expect(src.contains('onPressed: null'), isFalse);
    expect(src.contains('closeRelationship'), isFalse);
    expect(src.contains("state': 'active'"), isFalse);
  });
}
