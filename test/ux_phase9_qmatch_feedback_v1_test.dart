import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/widgets/qmatch_feedback.dart';
import 'package:qmatch/features/auth/google_sign_in_flow.dart';
import 'package:qmatch/features/auth/screens/email_verification_screen.dart';
import 'package:qmatch/features/auth/screens/phone_signup_screen.dart';
import 'package:qmatch/features/auth/screens/provider_collision_screen.dart';
import 'package:qmatch/features/auth/screens/welcome_screen.dart';
import 'package:qmatch/features/auth/widgets/auth_keyboard_dismiss.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';
import 'package:qmatch/l10n/app_localizations_tr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final l10nEn = AppLocalizationsEn();
  final l10nTr = AppLocalizationsTr();

  test('localization fallbacks exist in EN and TR', () {
    expect(l10nEn.qmatchFeedbackGenericError, isNotEmpty);
    expect(l10nTr.qmatchFeedbackGenericError,
        'Bir sorun oluştu. Lütfen tekrar dene.');
    expect(l10nTr.qmatchFeedbackGenericSuccess, 'İşlem tamamlandı.');
    expect(
      l10nTr.qmatchFeedbackNetworkError,
      'Bağlantını kontrol edip tekrar dene.',
    );
  });

  const longEn =
      'We could not finish this right now. Please check your connection and try again in a moment so we can save your changes.';
  const longTr =
      'İşlemi şu anda tamamlayamadık. Lütfen bağlantını kontrol edip birkaç saniye sonra tekrar dene ki değişikliklerin kaydedilebilsin.';

  void configureView(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double paddingBottom = 34,
    double insetBottom = 0,
  }) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.padding = FakeViewPadding(
      bottom: paddingBottom * 3,
      top: 47 * 3,
    );
    tester.view.viewPadding = FakeViewPadding(
      bottom: paddingBottom * 3,
      top: 47 * 3,
    );
    tester.view.viewInsets = FakeViewPadding(bottom: insetBottom * 3);
    addTearDown(tester.view.reset);
  }

  Widget harness({
    required Widget child,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  Future<void> showFeedback(
    WidgetTester tester, {
    required String message,
    QMatchFeedbackType type = QMatchFeedbackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    bool compact = false,
    Size size = const Size(390, 844),
    double paddingBottom = 34,
    double insetBottom = 0,
    Locale locale = const Locale('en'),
  }) async {
    configureView(
      tester,
      size: size,
      paddingBottom: paddingBottom,
      insetBottom: insetBottom,
    );
    await tester.pumpWidget(
      harness(
        locale: locale,
        child: Builder(
          builder: (context) {
            return TextButton(
              key: const Key('qmatch-feedback-trigger'),
              onPressed: () => QMatchFeedback.show(
                context,
                message: message,
                type: type,
                actionLabel: actionLabel,
                onAction: onAction,
                compact: compact,
              ),
              child: const Text('show'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('qmatch-feedback-trigger')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Material bannerMaterial(WidgetTester tester) {
    return tester.widget<Material>(find.byKey(QMatchFeedback.bannerKey));
  }

  SnackBar snackBar(WidgetTester tester) {
    return tester.widget<SnackBar>(find.byType(SnackBar));
  }

  group('A no default white Material surface', () {
    testWidgets('A snackbar chrome is transparent and banner is cosmic',
        (tester) async {
      await showFeedback(
        tester,
        message: l10nEn.qmatchFeedbackGenericError,
        type: QMatchFeedbackType.error,
        compact: true,
      );
      final snack = snackBar(tester);
      expect(snack.backgroundColor, Colors.transparent);
      expect(snack.elevation, 0);
      expect(snack.behavior, SnackBarBehavior.floating);
      final banner = bannerMaterial(tester);
      expect(banner.color, isNot(Colors.white));
      expect(banner.color, isNot(Colors.grey));
      expect(banner.color!.computeLuminance(), lessThan(0.2));
      expect(tester.takeException(), isNull);
    });
  });

  group('B/C/D/E typed QMatch surfaces', () {
    testWidgets('B error renders QMatch component', (tester) async {
      await showFeedback(
        tester,
        message: l10nEn.qmatchFeedbackGenericError,
        type: QMatchFeedbackType.error,
        compact: true,
      );
      expect(find.byKey(QMatchFeedback.bannerKey), findsOneWidget);
      expect(
          find.byKey(const Key('qmatch-feedback-icon-error')), findsOneWidget);
      expect(find.byKey(QMatchFeedback.messageKey), findsOneWidget);
      expect(find.text(l10nEn.qmatchFeedbackGenericError), findsOneWidget);
    });

    testWidgets('C success renders QMatch component', (tester) async {
      await showFeedback(
        tester,
        message: l10nEn.qmatchFeedbackGenericSuccess,
        type: QMatchFeedbackType.success,
        compact: true,
      );
      expect(
        find.byKey(const Key('qmatch-feedback-icon-success')),
        findsOneWidget,
      );
      expect(find.text(l10nEn.qmatchFeedbackGenericSuccess), findsOneWidget);
    });

    testWidgets('D warning renders QMatch component', (tester) async {
      await showFeedback(
        tester,
        message: l10nEn.qmatchFeedbackNetworkError,
        type: QMatchFeedbackType.warning,
        compact: true,
      );
      expect(
        find.byKey(const Key('qmatch-feedback-icon-warning')),
        findsOneWidget,
      );
      expect(find.text(l10nEn.qmatchFeedbackNetworkError), findsOneWidget);
    });

    testWidgets('E info renders QMatch component', (tester) async {
      await showFeedback(
        tester,
        message: l10nEn.qmatchFeedbackGenericSuccess,
        type: QMatchFeedbackType.info,
        compact: true,
      );
      expect(
          find.byKey(const Key('qmatch-feedback-icon-info')), findsOneWidget);
    });
  });

  group('F/G long localized copy wraps', () {
    testWidgets('F long TR message wraps without overflow', (tester) async {
      await showFeedback(
        tester,
        message: longTr,
        type: QMatchFeedbackType.error,
        compact: true,
        locale: const Locale('tr'),
        size: const Size(375, 667),
        paddingBottom: 0,
      );
      final text = tester.widget<Text>(find.byKey(QMatchFeedback.messageKey));
      expect(text.maxLines, 4);
      expect(find.text(longTr), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('G long EN message wraps without overflow', (tester) async {
      await showFeedback(
        tester,
        message: longEn,
        type: QMatchFeedbackType.warning,
        compact: true,
        size: const Size(375, 667),
        paddingBottom: 0,
      );
      final text = tester.widget<Text>(find.byKey(QMatchFeedback.messageKey));
      expect(text.maxLines, 4);
      expect(find.text(longEn), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('H/I/J device safety', () {
    testWidgets('H small iPhone viewport has no overflow', (tester) async {
      await showFeedback(
        tester,
        message: longEn,
        type: QMatchFeedbackType.error,
        size: const Size(375, 667),
        paddingBottom: 0,
      );
      expect(find.byKey(QMatchFeedback.bannerKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('I home-indicator viewport remains safe', (tester) async {
      const size = Size(390, 844);
      await showFeedback(
        tester,
        message: longEn,
        type: QMatchFeedbackType.info,
        size: size,
        paddingBottom: 34,
      );
      final rect = tester.getRect(find.byKey(QMatchFeedback.bannerKey));
      expect(rect.bottom, lessThan(size.height - 34));
      expect(rect.left, greaterThan(0));
      expect(rect.right, lessThan(size.width));
      expect(tester.takeException(), isNull);
    });

    testWidgets('J keyboard-open viewport remains usable', (tester) async {
      const size = Size(390, 844);
      const keyboard = 336.0;
      await showFeedback(
        tester,
        message: longEn,
        type: QMatchFeedbackType.error,
        compact: true,
        size: size,
        paddingBottom: 34,
        insetBottom: keyboard,
      );
      final rect = tester.getRect(find.byKey(QMatchFeedback.bannerKey));
      expect(rect.bottom, lessThan(size.height - keyboard + 8));
      expect(find.byKey(QMatchFeedback.actionKey), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('K/L stacking and action', () {
    testWidgets('K repeated feedback does not stack', (tester) async {
      await tester.pumpWidget(
        harness(
          child: Builder(
            builder: (context) {
              return TextButton(
                key: const Key('qmatch-feedback-trigger'),
                onPressed: () => QMatchFeedback.show(
                  context,
                  message: l10nEn.qmatchFeedbackGenericError,
                  type: QMatchFeedbackType.error,
                  compact: true,
                ),
                child: const Text('show'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('qmatch-feedback-trigger')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('qmatch-feedback-trigger')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('qmatch-feedback-trigger')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(QMatchFeedback.bannerKey), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('L optional action callback still fires', (tester) async {
      var taps = 0;
      await showFeedback(
        tester,
        message: l10nEn.qmatchFeedbackGenericError,
        type: QMatchFeedbackType.error,
        actionLabel: 'Retry',
        onAction: () => taps += 1,
        compact: true,
      );
      expect(find.byKey(QMatchFeedback.actionKey), findsOneWidget);
      await tester.tap(find.byKey(QMatchFeedback.actionKey));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('M raw technical text', () {
    test('M helper does not stringify exceptions or codes', () {
      final src =
          File('lib/core/widgets/qmatch_feedback.dart').readAsStringSync();
      expect(src.contains('toString()'), isFalse);
      expect(src.contains('FirebaseException'), isFalse);
      expect(src.contains('PlatformException'), isFalse);
      expect(src.contains('stackTrace'), isFalse);
      expect(src.contains('error.code'), isFalse);
    });

    test('name save no longer interpolates raw exception text', () {
      final src = File(
        'lib/features/profile/screens/name_selection_screen.dart',
      ).readAsStringSync();
      expect(src.contains('errorMessage(e.toString())'), isFalse);
      expect(src.contains('qmatchFeedbackGenericError'), isTrue);
    });

    test('location failure no longer interpolates e.toString()', () {
      final src = File(
        'lib/features/profile/screens/steps/basic_info_step.dart',
      ).readAsStringSync();
      expect(src.contains('e.toString()'), isFalse);
      expect(src.contains('profileLocationError'), isFalse);
      expect(src.contains('qmatchFeedbackGenericError'), isTrue);
    });
  });

  group('N/O Auth Phase 3–8 stay inline', () {
    testWidgets('N email verification banner stays inline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EmailVerificationScreen(
            email: 'ada@example.com',
            checkVerified: () async => false,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(EmailVerificationScreen.checkKey));
      await tester.pump();
      expect(find.byKey(EmailVerificationScreen.bannerKey), findsOneWidget);
      expect(find.text(l10nEn.emailVerificationStillPending), findsOneWidget);
      expect(find.byKey(QMatchFeedback.bannerKey), findsNothing);
    });

    testWidgets('N Google failure stays on welcome inline banner',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WelcomeScreen(
            signInWithGoogle: () async => GoogleSignInAttempt.failed(
              FirebaseAuthException(code: 'network-request-failed'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.pump();
      expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);
      expect(find.byKey(QMatchFeedback.bannerKey), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('N provider collision error stays inline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProviderCollisionScreen(
            attemptedProvider: 'google.com',
            emailHint: 'ada@example.com',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ProviderCollisionScreen), findsOneWidget);
      expect(find.byKey(QMatchFeedback.bannerKey), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('O phone screen does not restore AuthKeyboardActionBar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PhoneSignupScreen(),
        ),
      );
      await tester.pump();
      expect(find.byType(PhoneSignupScreen), findsOneWidget);
      expect(find.byType(AuthKeyboardActionBar), findsNothing);
      expect(find.byKey(AuthKeyboardActionBar.doneKey), findsNothing);
    });

    test('O phone source still excludes the gray accessory bar', () {
      final src = File(
        'lib/features/auth/screens/phone_signup_screen.dart',
      ).readAsStringSync();
      expect(src.contains('AuthKeyboardActionBar'), isFalse);
      expect(src.contains('0xFF2C2C2E'), isFalse);
    });

    test('N auth screens keep dedicated inline banner keys', () {
      final verification = File(
        'lib/features/auth/screens/email_verification_screen.dart',
      ).readAsStringSync();
      final welcome = File(
        'lib/features/auth/screens/welcome_screen.dart',
      ).readAsStringSync();
      final collision = File(
        'lib/features/auth/screens/provider_collision_screen.dart',
      ).readAsStringSync();
      expect(verification.contains('QMatchFeedback'), isFalse);
      expect(verification.contains('qmatch-email-verification-banner'), isTrue);
      expect(welcome.contains('qmatch-welcome-google-error'), isTrue);
      expect(welcome.contains('qmatch-welcome-apple-error'), isTrue);
      expect(welcome.contains('QMatchFeedback'), isFalse);
      expect(collision.contains('qmatch-collision-error'), isTrue);
      expect(collision.contains('QMatchFeedback'), isFalse);
    });
  });

  group('P Discover gesture/tutorial unchanged', () {
    test('P discover swipe and tutorial tokens remain', () {
      final src = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(src.contains('QMatchDiscoverGestureOnboarding'), isTrue);
      expect(src.contains('discoverGestureOnboardingSwipeRight'), isTrue);
      expect(src.contains('discoverGestureOnboardingSwipeLeft'), isTrue);
      expect(src.contains('discoverGestureOnboardingGotIt'), isTrue);
      expect(src.contains('_completeGestureOnboarding'), isTrue);
      expect(src.contains('recordCommittedSwipe()'), isTrue);
      expect(src.contains('showSwipeStamps:'), isTrue);
      expect(src.contains('likeUser'), isTrue);
      expect(src.contains('passUser'), isTrue);
    });
  });

  group('Q migrated screens keep original callbacks', () {
    test('Q discover / likes / chat still call original failure paths', () {
      final discover = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      final likes = File(
        'lib/features/who_liked_you/screens/who_liked_you_screen.dart',
      ).readAsStringSync();
      final chat = File(
        'lib/features/messages/screens/chat_detail_screen.dart',
      ).readAsStringSync();
      expect(discover.contains('QMatchFeedback.show'), isTrue);
      expect(discover.contains('discoverActionFailed'), isTrue);
      expect(likes.contains('await _passUser(card.uid)'), isTrue);
      expect(likes.contains('await _likeUser(card.uid)'), isTrue);
      expect(likes.contains('discoverActionFailed'), isTrue);
      expect(chat.contains('QMatchFeedback.show'), isTrue);
      expect(chat.contains('chatActionFailed'), isTrue);
      expect(chat.contains('unblockUser'), isTrue);
    });
  });

  group('R remaining SnackBar inventory', () {
    test('R only QMatchFeedback constructs a SnackBar in lib/', () {
      final hits = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final src = entity.readAsStringSync();
        if (src.contains('SnackBar(')) hits.add(entity.path);
      }
      expect(hits, ['lib/core/widgets/qmatch_feedback.dart']);
    });
  });
}
