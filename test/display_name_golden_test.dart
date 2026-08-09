import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/identity/identity.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/profile/screens/display_name_completion_screen.dart';
import 'package:qmatch/features/profile/services/display_name_service.dart';
import 'package:qmatch/l10n/app_localizations.dart';

/// Deterministic display-name / identity goldens (P2C-1C-4A).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    required Widget home,
    Size size = const Size(390, 844),
    Locale locale = const Locale('en'),
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(bottom: 34),
            viewPadding: const EdgeInsets.only(bottom: 34),
            viewInsets: viewInsets,
            textScaler: TextScaler.noScaling,
            devicePixelRatio: 1,
          ),
          child: SizedBox(width: size.width, height: size.height, child: home),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  testWidgets('empty input golden', (tester) async {
    await pumpApp(
      tester,
      home: DisplayNameCompletionScreen(
        displayNameService: _MemStore(),
        overrideUid: 'u1',
        onCompleted: () {},
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/display_name/empty_input_compact_1_0.png'),
    );
  });

  testWidgets('valid Turkish name golden', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('tr'),
      home: DisplayNameCompletionScreen(
        displayNameService: _MemStore(prefill: 'Şule'),
        overrideUid: 'u1',
        onCompleted: () {},
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/display_name/turkish_name_compact_1_0.png'),
    );
  });

  testWidgets('valid Cyrillic name golden', (tester) async {
    await pumpApp(
      tester,
      home: DisplayNameCompletionScreen(
        displayNameService: _MemStore(prefill: 'Анна'),
        overrideUid: 'u1',
        onCompleted: () {},
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/display_name/cyrillic_name_compact_1_0.png'),
    );
  });

  testWidgets('validation error golden', (tester) async {
    await pumpApp(
      tester,
      home: DisplayNameCompletionScreen(
        displayNameService: _MemStore(),
        overrideUid: 'u1',
        onCompleted: () {},
      ),
    );
    await tester.tap(find.byKey(const Key('qmatch-display-name-continue')));
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
          'goldens/display_name/validation_error_compact_1_0.png'),
    );
  });

  testWidgets('keyboard insets golden', (tester) async {
    await pumpApp(
      tester,
      viewInsets: const EdgeInsets.only(bottom: 280),
      home: DisplayNameCompletionScreen(
        displayNameService: _MemStore(prefill: 'Ada'),
        overrideUid: 'u1',
        onCompleted: () {},
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/display_name/keyboard_compact_1_0.png'),
    );
  });

  testWidgets('profile identity name+age golden', (tester) async {
    final label = UserIdentityResolver.formatNameAndAge(
      displayName: 'Ada',
      age: 26,
    )!;
    await pumpApp(
      tester,
      home: Scaffold(
        backgroundColor: AppColors.cosmicBlack,
        body: Center(
          child: Text(
            key: const Key('qmatch-profile-identity'),
            label,
            style: const TextStyle(color: Colors.white, fontSize: 32),
          ),
        ),
      ),
    );
    expect(find.text(', 26'), findsNothing);
    expect(find.text('Ada, 26'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
          'goldens/display_name/profile_identity_name_age_1_0.png'),
    );
  });

  testWidgets('profile identity name only golden', (tester) async {
    final label = UserIdentityResolver.formatNameAndAge(
      displayName: 'Ada',
      age: null,
    )!;
    await pumpApp(
      tester,
      home: Scaffold(
        backgroundColor: AppColors.cosmicBlack,
        body: Center(
          child: Text(
            key: const Key('qmatch-profile-identity'),
            label,
            style: const TextStyle(color: Colors.white, fontSize: 32),
          ),
        ),
      ),
    );
    expect(find.text('Ada'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        'goldens/display_name/profile_identity_name_only_1_0.png',
      ),
    );
  });
}

class _MemStore implements DisplayNameStore {
  _MemStore({this.prefill = ''});
  final String prefill;
  @override
  Future<bool> hasValidCanonicalDisplayName(String uid) async => false;
  @override
  Future<String> prefillCandidate(String uid) async => prefill;
  @override
  Future<String?> readCanonicalDisplayName(String uid) async => null;
  @override
  Future<void> saveCanonicalDisplayName({
    required String uid,
    required String rawInput,
  }) async {}
}
