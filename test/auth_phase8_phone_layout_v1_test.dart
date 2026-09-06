import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:qmatch/core/services/email_verification_policy.dart';
import 'package:qmatch/features/auth/screens/phone_signup_screen.dart';
import 'package:qmatch/features/auth/widgets/auth_keyboard_dismiss.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final l10nEn = AppLocalizationsEn();

  Widget app({
    required Widget home,
    Size size = const Size(390, 844),
    double devicePixelRatio = 3,
    double paddingBottom = 34,
    double insetBottom = 0,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          padding: EdgeInsets.only(bottom: paddingBottom, top: 47),
          viewPadding: EdgeInsets.only(bottom: paddingBottom, top: 47),
          viewInsets: EdgeInsets.only(bottom: insetBottom),
        ),
        child: home,
      ),
    );
  }

  Future<void> pumpPhone(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double paddingBottom = 34,
    double insetBottom = 0,
    bool otp = false,
    Future<void> Function()? sendCode,
    Future<void> Function()? verifyCode,
  }) async {
    await tester.pumpWidget(
      app(
        size: size,
        paddingBottom: paddingBottom,
        insetBottom: insetBottom,
        home: PhoneSignupScreen(
          debugShowCodeStep: otp,
          sendCodeOverride: sendCode,
          verifyCodeOverride: verifyCode,
        ),
      ),
    );
    await tester.pump();
  }

  group('A/B overflow', () {
    testWidgets('A phone screen renders without bottom overflow on SE',
        (tester) async {
      await pumpPhone(
        tester,
        size: const Size(375, 667),
        paddingBottom: 0,
      );
      expect(find.byType(PhoneSignupScreen), findsOneWidget);
      expect(find.byType(IntlPhoneField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('A phone screen renders on a home-indicator iPhone',
        (tester) async {
      await pumpPhone(tester);
      expect(find.byKey(PhoneSignupScreen.sendCodeKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('B OTP screen renders without bottom overflow on SE',
        (tester) async {
      await pumpPhone(
        tester,
        size: const Size(375, 667),
        paddingBottom: 0,
        otp: true,
      );
      expect(find.byKey(PhoneSignupScreen.codeFieldKey), findsOneWidget);
      expect(find.byKey(PhoneSignupScreen.verifyKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('B OTP screen renders on a home-indicator iPhone',
        (tester) async {
      await pumpPhone(tester, otp: true);
      expect(find.byKey(PhoneSignupScreen.resendKey), findsOneWidget);
      expect(find.byKey(PhoneSignupScreen.changeNumberKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('C no app-owned gray footer', () {
    test('C phone screen no longer mounts the gray accessory bar', () {
      final src = File(
        'lib/features/auth/screens/phone_signup_screen.dart',
      ).readAsStringSync();
      expect(src.contains('AuthKeyboardActionBar'), isFalse);
      expect(src.contains('0xFF2C2C2E'), isFalse);
      expect(src.contains('Colors.grey'), isFalse);
      expect(src.contains('bottomNavigationBar'), isFalse);
      expect(src.contains('persistentFooterButtons'), isFalse);
    });

    testWidgets('C focused phone field does not paint a gray footer',
        (tester) async {
      await pumpPhone(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(find.byType(AuthKeyboardActionBar), findsNothing);
      expect(find.byKey(AuthKeyboardActionBar.doneKey), findsNothing);
      final materials = tester.widgetList<Material>(find.byType(Material));
      expect(
        materials.any((m) => m.color == const Color(0xFF2C2C2E)),
        isFalse,
      );
    });
  });

  group('D/E/F keyboard inset', () {
    testWidgets('D/E Continue stays reachable with the keyboard open',
        (tester) async {
      await pumpPhone(tester, insetBottom: 336);
      expect(find.byKey(PhoneSignupScreen.sendCodeKey), findsOneWidget);
      await tester.ensureVisible(find.byKey(PhoneSignupScreen.sendCodeKey));
      await tester.tap(find.byKey(PhoneSignupScreen.sendCodeKey));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('F OTP actions stay reachable with the keyboard open',
        (tester) async {
      await pumpPhone(tester, otp: true, insetBottom: 336);
      await tester.ensureVisible(find.byKey(PhoneSignupScreen.verifyKey));
      await tester.ensureVisible(find.byKey(PhoneSignupScreen.resendKey));
      await tester.ensureVisible(find.byKey(PhoneSignupScreen.changeNumberKey));
      expect(find.byKey(PhoneSignupScreen.verifyKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape phone layout does not overflow', (tester) async {
      await pumpPhone(
        tester,
        size: const Size(844, 390),
        paddingBottom: 21,
        insetBottom: 180,
      );
      expect(find.byType(PhoneSignupScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('G country selector', () {
    testWidgets('G IntlPhoneField still exposes the country selector',
        (tester) async {
      await pumpPhone(tester);
      expect(find.byType(IntlPhoneField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(l10nEn.searchCountry), findsOneWidget);
    });
  });

  group('H/I loading guards', () {
    testWidgets('H loading prevents duplicate phone submit', (tester) async {
      var calls = 0;
      await pumpPhone(
        tester,
        sendCode: () async {
          calls += 1;
          await Future<void>.delayed(const Duration(milliseconds: 80));
        },
      );
      await tester.enterText(find.byType(TextField), '5551112233');
      await tester.pump();
      await tester.ensureVisible(find.byKey(PhoneSignupScreen.sendCodeKey));
      await tester.tap(find.byKey(PhoneSignupScreen.sendCodeKey));
      await tester.pump();
      await tester.tap(find.byKey(PhoneSignupScreen.sendCodeKey));
      await tester.pump();
      expect(calls, 1);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('I OTP loading prevents duplicate verify', (tester) async {
      var calls = 0;
      await pumpPhone(
        tester,
        otp: true,
        verifyCode: () async {
          calls += 1;
          await Future<void>.delayed(const Duration(milliseconds: 80));
        },
      );
      await tester.enterText(
          find.byKey(PhoneSignupScreen.codeFieldKey), '123456');
      await tester.pump();
      await tester.ensureVisible(find.byKey(PhoneSignupScreen.verifyKey));
      await tester.tap(find.byKey(PhoneSignupScreen.verifyKey));
      await tester.pump();
      await tester.tap(find.byKey(PhoneSignupScreen.verifyKey));
      await tester.pump();
      expect(calls, 1);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('J/K/L functional contract', () {
    test('J phone success still uses completeAuthentication', () {
      final src = File(
        'lib/features/auth/screens/phone_signup_screen.dart',
      ).readAsStringSync();
      expect(src.contains('AuthNavigation.completeAuthentication'), isTrue);
      expect(src.contains('AuthWrapper('), isFalse);
      expect(src.contains('IQTest'), isFalse);
      expect(src.contains('ProfileSetup'), isFalse);
    });

    test('K phone users still bypass the email verification gate', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['phone'],
          emailVerified: false,
        ),
        isFalse,
      );
    });

    test('L Google/Apple/password screens were not redesigned here', () {
      for (final path in [
        'lib/features/auth/screens/welcome_screen.dart',
        'lib/features/auth/google_sign_in_flow.dart',
        'lib/features/auth/apple_sign_in_flow.dart',
        'lib/features/auth/provider_link_flow.dart',
        'lib/core/services/email_verification_policy.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains('AuthKeyboardActionBar'), isFalse, reason: path);
      }
    });

    test('system navigation bar is pinned to the cosmic canvas', () {
      final src = File(
        'lib/features/auth/screens/phone_signup_screen.dart',
      ).readAsStringSync();
      expect(src.contains('systemNavigationBarColor'), isTrue);
      expect(src.contains('AppColors.midnightNavy'), isTrue);
    });
  });

  test('AuthKeyboardActionBar leftover is no longer iOS system gray', () {
    final src = File(
      'lib/features/auth/widgets/auth_keyboard_dismiss.dart',
    ).readAsStringSync();
    expect(src.contains('0xFF2C2C2E'), isFalse);
    expect(src.contains('AppColors.midnightNavy'), isTrue);
  });
}
