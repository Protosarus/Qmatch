import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/core/widgets/qmatch_pushed_screen_header.dart';
import 'package:qmatch/features/settings/screens/about_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';
import 'package:qmatch/l10n/app_localizations_tr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const lilac = Color(0xFFDAC8ED);
  const enBody =
      'QMatch helps people discover compatible connections based on how they think, feel, and connect — not looks alone. Compatibility insights are meant to support discovery; they do not guarantee the success of any relationship.';
  const trBody =
      'QMatch; düşünme, hissetme ve bağ kurma biçimine göre anlamlı bağlantılar keşfetmene yardımcı olur — yalnızca görünüşe göre değil. Uyumluluk içgörüleri keşfi desteklemek içindir; herhangi bir ilişkinin başarısını garanti etmez.';

  Future<void> pumpAbout(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AboutScreen(),
      ),
    );
    await tester.pump();
  }

  test('EN/TR About copy uses QMatch and refined TR body', () {
    expect(AppLocalizationsEn().aboutTagline, 'Minds First');
    expect(AppLocalizationsEn().aboutDescription, enBody);
    expect(AppLocalizationsEn().aboutDescription.contains('Qmatch'), isFalse);
    expect(AppLocalizationsEn().aboutDescription.contains('QMatch'), isTrue);

    expect(AppLocalizationsTr().aboutTagline, 'Minds First');
    expect(AppLocalizationsTr().aboutDescription, trBody);
    expect(AppLocalizationsTr().aboutDescription.contains('Qmatch'), isFalse);
  });

  testWidgets('EN About screen shows QMatch brand, tagline, version, and legal',
      (tester) async {
    await pumpAbout(tester);

    expect(find.text('QMatch'), findsOneWidget);
    expect(find.text('Qmatch'), findsNothing);
    expect(find.text('Minds First'), findsOneWidget);
    expect(find.text(enBody), findsOneWidget);
    expect(find.byKey(const Key('qmatch-about-header')), findsOneWidget);
    expect(find.byType(QMatchPushedScreenHeader), findsOneWidget);
    expect(find.text(AppLocalizationsEn().aboutVersion), findsOneWidget);
    expect(find.text(AppLocalizationsEn().aboutLegal), findsOneWidget);
    expect(find.text(AppLocalizationsEn().openPrivacyPolicy), findsOneWidget);
    expect(find.text(AppLocalizationsEn().openTermsOfUse), findsOneWidget);
  });

  testWidgets('TR About screen shows refined body copy', (tester) async {
    await pumpAbout(tester, locale: const Locale('tr'));
    expect(find.text('QMatch'), findsOneWidget);
    expect(find.text(trBody), findsOneWidget);
    expect(find.textContaining('görünüme göre'), findsNothing);
  });

  testWidgets('Minds First uses lilac, not gold', (tester) async {
    await pumpAbout(tester);
    final tagline = tester.widget<Text>(
      find.byKey(const Key('qmatch-about-tagline')),
    );
    expect(tagline.style?.color, lilac);
    expect(tagline.style?.color, isNot(AppColors.softGold));
  });

  test('About screen source drops gold accent and keeps QMatch brand', () {
    final src = File(
      'lib/features/settings/screens/about_screen.dart',
    ).readAsStringSync();
    expect(src.contains('AppColors.softGold'), isFalse);
    expect(src.contains('0xFFDAC8ED'), isTrue);
    expect(src.contains("'QMatch'"), isTrue);
    expect(src.contains("'Qmatch'"), isFalse);
    expect(src.contains('LegalDocumentScreen'), isTrue);
    expect(src.contains('aboutVersion'), isTrue);
  });
}
