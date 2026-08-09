import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/core/widgets/qmatch_glass_icon_button.dart';
import 'package:qmatch/core/widgets/qmatch_primary_action.dart';
import 'package:qmatch/core/widgets/qmatch_pushed_screen_header.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpHeader(
    WidgetTester tester, {
    required Widget child,
    Size size = const Size(375, 667),
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.cosmicBlack,
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shared back button keeps 44x44 tap target', (tester) async {
    await pumpHeader(
      tester,
      child: const SafeArea(
        child: QMatchPushedScreenHeader(
          title: 'Header',
          backButtonKey: Key('header-back'),
        ),
      ),
    );
    final size = tester.getSize(find.byKey(const Key('header-back')));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('back button uses visible glass container', (tester) async {
    await pumpHeader(
      tester,
      child: const SafeArea(
        child: QMatchPushedScreenHeader(
          title: 'Header',
          backButtonKey: Key('header-back'),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const Key('header-back')),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, QMatchGlassIconButton.glassFill);
    expect(material.shape, isA<OutlinedBorder>());
  });

  testWidgets('back icon is not gold in default state', (tester) async {
    await pumpHeader(
      tester,
      child: const SafeArea(
        child: QMatchPushedScreenHeader(
          title: 'Header',
          backButtonKey: Key('header-back'),
        ),
      ),
    );

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('header-back')),
        matching: find.byIcon(Icons.arrow_back_ios_new),
      ),
    );
    expect(icon.color, QMatchGlassIconButton.iconDefault);
    expect(icon.color, isNot(AppColors.softGold));
    expect(icon.color, isNot(AppColors.warmGold));
  });

  testWidgets('back button invokes Navigator.pop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: SafeArea(
                          child: QMatchPushedScreenHeader(
                            title: 'Destination',
                            backButtonKey: Key('header-back'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Destination'), findsOneWidget);

    await tester.tap(find.byKey(const Key('header-back')));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('long title and text scale do not overflow', (tester) async {
    await pumpHeader(
      tester,
      size: const Size(320, 568),
      textScale: 1.3,
      child: const SafeArea(
        child: QMatchPushedScreenHeader(
          title:
              'Very long Turkish and English destination title for layout verification',
          backButtonKey: Key('header-back'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary action enabled surface is not solid yellow',
      (tester) async {
    await pumpHeader(
      tester,
      child: QMatchPrimaryAction(
        label: 'Continue',
        onPressed: () {},
      ),
    );

    final ink = tester.widget<Ink>(find.byType(Ink));
    final decoration = ink.decoration! as BoxDecoration;
    expect(decoration.color, isNot(AppColors.softGold));
    expect(decoration.color, isNot(AppColors.warmGold));
    final gradient = decoration.gradient as LinearGradient?;
    expect(gradient, isNotNull);
    for (final color in gradient!.colors) {
      expect(color, isNot(AppColors.softGold));
      expect(color, isNot(AppColors.warmGold));
      // Solid yellow CTAs are high luminance yellow/gold — reject that family.
      final isYellowish = color.r > 0.70 && color.g > 0.55 && color.b < 0.47;
      expect(isYellowish, isFalse);
    }
  });
}
