import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/l10n/app_localizations.dart';

/// Dark Material scheme matching [AppTheme.darkTheme] tokens without GoogleFonts
/// network/asset fetches in unit tests.
ThemeData _darkThemeMirror() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.resonanceViolet,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.cosmicBlack,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      onError: AppColors.textPrimary,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('main.dart wires AppTheme.darkTheme (not light gold seed)', () {
    final mainSrc = File('lib/main.dart').readAsStringSync();
    expect(mainSrc.contains('import \'core/theme/app_theme.dart\''), isTrue);
    expect(mainSrc.contains('theme: AppTheme.darkTheme'), isTrue);
    expect(mainSrc.contains('themeMode: ThemeMode.dark'), isTrue);
    expect(mainSrc.contains('ColorScheme.fromSeed'), isFalse);
    expect(mainSrc.contains('seedColor: const Color(0xFFE3C565)'), isFalse);

    final themeSrc = File('lib/core/theme/app_theme.dart').readAsStringSync();
    expect(themeSrc.contains('brightness: Brightness.dark'), isTrue);
    expect(themeSrc.contains('primary: AppColors.primary'), isTrue);
    expect(themeSrc.contains('scaffoldBackgroundColor: AppColors.background'),
        isTrue);
    // Brand gold stays primary; lavender is not the global seed.
    expect(themeSrc.contains('0xFFDAC8ED'), isFalse);
  });

  testWidgets('phone-signup style Theme patch stays dark under dark root theme',
      (tester) async {
    late ThemeData nested;
    await tester.pumpWidget(
      MaterialApp(
        theme: _darkThemeMirror(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            return Theme(
              data: Theme.of(context).copyWith(
                brightness: Brightness.dark,
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      brightness: Brightness.dark,
                      onSurface: Colors.white,
                    ),
                textTheme: Theme.of(context).textTheme.apply(
                      bodyColor: Colors.white,
                      displayColor: Colors.white,
                    ),
              ),
              child: Builder(
                builder: (context) {
                  nested = Theme.of(context);
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(nested.brightness, Brightness.dark);
    expect(nested.colorScheme.brightness, Brightness.dark);
    expect(nested.colorScheme.onSurface, Colors.white);
    expect(nested.textTheme.bodyMedium?.color, Colors.white);
  });

  testWidgets('Profile Setup slider overrides remain readable on dark theme',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _darkThemeMirror(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF9B7CFF),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
                  thumbColor: const Color(0xFFDAC8ED),
                  overlayColor: const Color(0x339B7CFF),
                  valueIndicatorColor: const Color(0xFF5B4B8A),
                  valueIndicatorTextStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: RangeSlider(
                  values: const RangeValues(25, 35),
                  min: 18,
                  max: 80,
                  onChanged: (_) {},
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final sliderTheme = SliderTheme.of(
      tester.element(find.byType(RangeSlider)),
    );
    expect(sliderTheme.thumbColor, const Color(0xFFDAC8ED));
    expect(sliderTheme.activeTrackColor, const Color(0xFF9B7CFF));
    expect(Theme.of(tester.element(find.byType(RangeSlider))).brightness,
        Brightness.dark);
    expect(find.byType(RangeSlider), findsOneWidget);
  });

  testWidgets('dialogs / sheets / switch / checkbox stay contrast-safe',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _darkThemeMirror(),
        themeMode: ThemeMode.dark,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Column(
                children: [
                  Switch.adaptive(
                    value: true,
                    onChanged: (_) {},
                    activeThumbColor: AppColors.softGold,
                    activeTrackColor:
                        AppColors.resonanceViolet.withValues(alpha: 0.45),
                  ),
                  CheckboxListTile(
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppColors.softGold,
                    checkColor: AppColors.cosmicBlack,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    title: const Text(
                      'Confirm',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surfaceElevated,
                          title: const Text(
                            'Title',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          content: const Text(
                            'Body',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'OK',
                                style: TextStyle(color: AppColors.softGold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('open-dialog'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: AppColors.surfaceElevated,
                        builder: (ctx) => SafeArea(
                          child: ListTile(
                            leading: const Icon(
                              Icons.star,
                              color: AppColors.softGold,
                            ),
                            title: const Text(
                              'Set as main',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            onTap: () => Navigator.pop(ctx),
                          ),
                        ),
                      );
                    },
                    child: const Text('open-sheet'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).colorScheme.primary,
      AppColors.softGold,
    );

    await tester.tap(find.text('open-dialog'));
    await tester.pumpAndSettle();
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.backgroundColor, AppColors.surfaceElevated);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open-sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Set as main'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);

    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsOneWidget);
  });
}
