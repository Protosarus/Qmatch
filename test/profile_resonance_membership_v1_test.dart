import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/profile/screens/profile_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';
import 'package:qmatch/l10n/app_localizations_tr.dart';

import 'support/profile_golden_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const badge = Key('qmatch-profile-resonance-badge');
  const membership = Key('qmatch-profile-membership');

  Future<void> pumpProfile(
    WidgetTester tester, {
    bool? resonanceAccess,
    Future<bool> Function()? readResonanceAccess,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(
          debugProfile: ProfileGoldenFixtures.full(),
          debugResonanceAccess: resonanceAccess,
          readResonanceAccess: readResonanceAccess,
          animateBackground: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  test('EN/TR membership copy', () {
    expect(AppLocalizationsEn().profileMembershipResonanceActive,
        'Resonance active');
    expect(AppLocalizationsEn().profileMembershipFree, 'QMatch Free');
    expect(AppLocalizationsTr().profileMembershipResonanceActive,
        'Resonance aktif');
    expect(AppLocalizationsTr().profileMembershipFree, 'QMatch Free');
  });

  testWidgets('trusted Resonance access shows photo badge and status row',
      (tester) async {
    await pumpProfile(tester, resonanceAccess: true);

    expect(find.byKey(badge), findsOneWidget);
    expect(find.byKey(membership), findsOneWidget);
    expect(find.text('Resonance active'), findsOneWidget);

    final badgeBox = tester.getSize(find.byKey(badge));
    expect(badgeBox.width, lessThanOrEqualTo(24));
    expect(badgeBox.height, lessThanOrEqualTo(24));

    final photo = tester.getRect(find.byType(ClipOval).first);
    final badgeRect = tester.getRect(find.byKey(badge));
    expect(badgeRect.center.dx, greaterThan(photo.center.dx));
    expect(badgeRect.center.dy, greaterThan(photo.center.dy));
  });

  testWidgets('TR Resonance access uses aktif copy', (tester) async {
    await pumpProfile(
      tester,
      resonanceAccess: true,
      locale: const Locale('tr'),
    );
    expect(find.text('Resonance aktif'), findsOneWidget);
    expect(find.text('Resonance active'), findsNothing);
  });

  testWidgets('free entitlement shows Free row and no Resonance badge',
      (tester) async {
    await pumpProfile(tester, resonanceAccess: false);
    expect(find.byKey(badge), findsNothing);
    expect(find.byKey(membership), findsOneWidget);
    expect(find.text('QMatch Free'), findsOneWidget);
    expect(find.text('Resonance active'), findsNothing);
  });

  testWidgets('synthetic profile fail-closes without an entitlement override',
      (tester) async {
    await pumpProfile(tester);
    expect(find.byKey(badge), findsNothing);
    expect(find.byKey(membership), findsNothing);
    expect(find.text('Resonance active'), findsNothing);
  });

  testWidgets('entitlement read false does not show Resonance UI',
      (tester) async {
    await pumpProfile(
      tester,
      readResonanceAccess: () async => false,
    );
    await tester.pump();
    expect(find.byKey(badge), findsNothing);
    expect(find.text('QMatch Free'), findsOneWidget);
  });

  testWidgets('entitlement read error fail-closes', (tester) async {
    await pumpProfile(
      tester,
      readResonanceAccess: () async => throw StateError('denied'),
    );
    await tester.pump();
    expect(find.byKey(badge), findsNothing);
    expect(find.text('QMatch Free'), findsOneWidget);
  });

  testWidgets('membership row opens Membership screen', (tester) async {
    await pumpProfile(tester, resonanceAccess: true);

    await tester.tap(find.byKey(membership));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('qmatch-membership-resonance')), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  test('Profile reads trusted entitlements resonance_access, not StoreKit', () {
    final src = File(
      'lib/features/profile/screens/profile_screen.dart',
    ).readAsStringSync();
    expect(src.contains('EntitlementRepository'), isTrue);
    expect(src.contains('resonanceAccess == true'), isTrue);
    expect(src.contains('InAppPurchase'), isFalse);
    expect(src.contains('purchase'), isFalse);
    expect(src.toLowerCase().contains('storekit'), isFalse);

    final badgeSrc = File(
      'lib/features/profile/widgets/qmatch_profile_resonance.dart',
    ).readAsStringSync();
    expect(badgeSrc.contains('0xFFDAC8ED'), isTrue);
    expect(badgeSrc.contains('AppColors.resonanceViolet'), isTrue);
    expect(badgeSrc.contains('AppColors.softGold'), isFalse);
  });
}
