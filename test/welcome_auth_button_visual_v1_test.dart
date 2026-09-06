import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_radii.dart';
import 'package:qmatch/features/auth/apple_sign_in_flow.dart';
import 'package:qmatch/features/auth/google_sign_in_flow.dart';
import 'package:qmatch/features/auth/screens/welcome_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';
import 'package:qmatch/l10n/app_localizations_tr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget app({
    required Widget home,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }

  Future<void> pumpWelcome(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(320, 568),
    FakeViewPadding? padding,
    WelcomeGoogleSignIn? signInWithGoogle,
    WelcomeAppleSignIn? signInWithApple,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (padding != null) {
      tester.view.padding = padding;
      tester.view.viewPadding = padding;
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
    }
    await tester.pumpWidget(
      app(
        locale: locale,
        home: WelcomeScreen(
          showAppleButton: true,
          signInWithGoogle: signInWithGoogle ??
              () async => GoogleSignInAttempt.cancelled(),
          signInWithApple: signInWithApple ??
              () async => AppleSignInAttempt.cancelled(),
        ),
      ),
    );
    await tester.pump();
  }


  BoxDecoration ctaDecoration(WidgetTester tester, Finder label) {
    final ink = find.ancestor(of: label, matching: find.byType(InkWell));
    final decorated =
        find.ancestor(of: ink, matching: find.byType(DecoratedBox)).first;
    return tester.widget<DecoratedBox>(decorated).decoration as BoxDecoration;
  }

  Size ctaSize(WidgetTester tester, Finder label) {
    final ink = find.ancestor(of: label, matching: find.byType(InkWell));
    return tester.getSize(ink);
  }

  testWidgets('EN and TR labels fit on a small iPhone without overflow',
      (tester) async {
    FlutterError? overflow;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflow = FlutterError(details.exceptionAsString());
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await pumpWelcome(tester);
    expect(find.text(AppLocalizationsEn().welcomeContinueWithPhone),
        findsOneWidget);
    expect(find.text(AppLocalizationsEn().welcomeContinueWithGoogle),
        findsOneWidget);
    expect(find.text(AppLocalizationsEn().welcomeContinueWithApple),
        findsOneWidget);

    await pumpWelcome(tester, locale: const Locale('tr'));
    expect(find.text(AppLocalizationsTr().welcomeContinueWithPhone),
        findsOneWidget);
    expect(find.text(AppLocalizationsTr().welcomeContinueWithGoogle),
        findsOneWidget);
    expect(find.text(AppLocalizationsTr().welcomeContinueWithApple),
        findsOneWidget);
    expect(overflow, isNull);
  });

  testWidgets('premium layout keeps cues and CTAs, drops lower cards',
      (tester) async {
    FlutterError? overflow;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflow = FlutterError(details.exceptionAsString());
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    Future<void> assertContract(Locale locale) async {
      await pumpWelcome(
        tester,
        locale: locale,
        size: const Size(402, 874),
      );
      final l10n = locale.languageCode == 'tr'
          ? AppLocalizationsTr()
          : AppLocalizationsEn();
      expect(find.text('QMatch'), findsOneWidget);
      expect(find.text('Qmatch'), findsNothing);
      expect(find.text(l10n.welcomeCueIntelligent), findsOneWidget);
      expect(find.text(l10n.welcomeCueEmotional), findsOneWidget);
      expect(find.text(l10n.welcomeCueVibrational), findsOneWidget);
      expect(find.text(l10n.welcomeContinueWithPhone), findsOneWidget);
      expect(find.text(l10n.welcomeContinueWithGoogle), findsOneWidget);
      expect(find.text(l10n.welcomeContinueWithApple), findsOneWidget);
      expect(find.text(l10n.welcomeSignUpWithEmail), findsOneWidget);
      expect(find.text(l10n.welcomeLogInWithEmail), findsOneWidget);
      expect(find.textContaining(l10n.welcomeTermsOfService), findsOneWidget);
      expect(find.textContaining(l10n.welcomePrivacyPolicy), findsOneWidget);
      expect(find.text(l10n.welcomeTrustPrivateTitle), findsNothing);
      expect(find.text(l10n.welcomeTrustScienceTitle), findsNothing);
      expect(find.text(l10n.welcomeTrustMatchesTitle), findsNothing);
    }

    await assertContract(const Locale('en'));
    await assertContract(const Locale('tr'));

    await pumpWelcome(tester, size: const Size(375, 667));
    expect(find.text('QMatch'), findsOneWidget);
    expect(find.text(AppLocalizationsEn().welcomeTrustPrivateTitle),
        findsNothing);
    expect(overflow, isNull);
  });

  testWidgets('viewports do not overflow and hero is smaller than last pass',
      (tester) async {
    FlutterError? overflow;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflow = FlutterError(details.exceptionAsString());
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    const viewports = <Size>[
      Size(402, 874),
      Size(390, 844),
      Size(375, 667),
      Size(320, 568),
    ];
    const homeInset = FakeViewPadding(top: 59, bottom: 34);

    for (final size in viewports) {
      for (final locale in const [Locale('en'), Locale('tr')]) {
        overflow = null;
        await pumpWelcome(
          tester,
          locale: locale,
          size: size,
          padding: homeInset,
        );
        expect(overflow, isNull, reason: '$locale $size');
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byKey(WelcomeScreen.heroKey), findsOneWidget);
        final hero = tester.getSize(find.byKey(WelcomeScreen.heroKey));
        expect(hero.width, hero.height);
        final safeH = size.height - 59 - 34;
        final contentW = size.width < 430 ? size.width : 430.0;
        final expected = WelcomeScreen.resolveHeroSize(
          safeHeight: safeH,
          contentWidth: contentW,
        );
        expect(hero.width, moreOrLessEquals(expected, epsilon: 0.6));
        final previousPass = safeH *
            (safeH < 640
                ? 0.36
                : safeH < 720
                    ? 0.40
                    : 0.45) *
            0.82;
        expect(hero.width, lessThan(previousPass));
        final l10n = locale.languageCode == 'tr'
            ? AppLocalizationsTr()
            : AppLocalizationsEn();
        await tester.ensureVisible(
          find.textContaining(l10n.welcomeTermsOfService),
        );
        expect(find.text(l10n.welcomeSignUpWithEmail), findsOneWidget);
        expect(find.text(l10n.welcomeContinueWithPhone), findsOneWidget);
        expect(find.text(l10n.welcomeTrustPrivateTitle), findsNothing);
      }
    }
  });

  testWidgets('error banner does not overflow compact or modern viewports',
      (tester) async {
    FlutterError? overflow;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflow = FlutterError(details.exceptionAsString());
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    for (final size in const [Size(402, 874), Size(320, 568)]) {
      overflow = null;
      await pumpWelcome(
        tester,
        size: size,
        padding: const FakeViewPadding(top: 59, bottom: 34),
        signInWithGoogle: () async => GoogleSignInAttempt.failed(
          FirebaseAuthException(code: 'credential-already-in-use'),
        ),
      );
      await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);
      expect(overflow, isNull, reason: '$size with banner');
      await tester.ensureVisible(
        find.textContaining(AppLocalizationsEn().welcomeTermsOfService),
      );
    }
  });

  testWidgets('auth CTAs share height, width, and cosmic/brand styles',
      (tester) async {
    await pumpWelcome(tester, size: const Size(375, 667));
    final phone = find.text(AppLocalizationsEn().welcomeContinueWithPhone);
    final google = find.text(AppLocalizationsEn().welcomeContinueWithGoogle);
    final apple = find.text(AppLocalizationsEn().welcomeContinueWithApple);

    final phoneSize = ctaSize(tester, phone);
    expect(ctaSize(tester, google), phoneSize);
    expect(ctaSize(tester, apple), phoneSize);

    final phoneDeco = ctaDecoration(tester, phone);
    expect(
      (phoneDeco.gradient as LinearGradient).colors,
      const [
        Color(0xFF5A2BEA),
        Color(0xFF8B4CF6),
        Color(0xFFE9B83F),
      ],
    );

    final googleDeco = ctaDecoration(tester, google);
    expect(googleDeco.color, const Color.fromRGBO(17, 12, 35, 0.88));
    expect(
      googleDeco.border?.top.color,
      const Color.fromRGBO(190, 151, 255, 0.55),
    );
    expect(
      find.descendant(
        of: find.byKey(WelcomeScreen.googleButtonKey),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );

    final appleDeco = ctaDecoration(tester, apple);
    expect(appleDeco.color, Colors.black);
    expect(appleDeco.gradient, isNull);
    final appleLabel = tester.widget<Text>(apple);
    expect(appleLabel.style?.color, Colors.white);
  });

  testWidgets('Google and Apple tap callbacks stay wired', (tester) async {
    var googleCalls = 0;
    var appleCalls = 0;
    await pumpWelcome(
      tester,
      signInWithGoogle: () async {
        googleCalls += 1;
        return GoogleSignInAttempt.cancelled();
      },
      signInWithApple: () async {
        appleCalls += 1;
        return AppleSignInAttempt.cancelled();
      },
    );

    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    expect(googleCalls, 1);
    expect(appleCalls, 0);

    await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.pump();
    expect(googleCalls, 1);
    expect(appleCalls, 1);
  });

  Future<void> failGoogle(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(320, 568),
    String code = 'credential-already-in-use',
  }) async {
    await pumpWelcome(
      tester,
      locale: locale,
      size: size,
      signInWithGoogle: () async => GoogleSignInAttempt.failed(
        FirebaseAuthException(code: code),
      ),
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> failApple(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(320, 568),
    String code = 'credential-already-in-use',
  }) async {
    await pumpWelcome(
      tester,
      locale: locale,
      size: size,
      signInWithApple: () async => AppleSignInAttempt.failed(
        FirebaseAuthException(code: code),
      ),
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  BoxDecoration bannerDecoration(WidgetTester tester, Key key) {
    return tester
        .widget<DecoratedBox>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration as BoxDecoration;
  }

  testWidgets('error banner is inline cosmic alert with icon, not SnackBar',
      (tester) async {
    FlutterError? overflow;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflow = FlutterError(details.exceptionAsString());
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await failGoogle(tester);
    final banner = find.byKey(WelcomeScreen.googleErrorKey);
    expect(banner, findsOneWidget);
    expect(
      find.descendant(
        of: banner,
        matching: find.byIcon(Icons.error_outline_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.text(AppLocalizationsEn().googleSignInErrorCredentialInUse),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);

    final deco = bannerDecoration(tester, WelcomeScreen.googleErrorKey);
    expect(deco.color, const Color.fromRGBO(74, 15, 35, 0.78));
    expect(deco.border?.top.color, const Color.fromRGBO(255, 92, 115, 0.75));
    expect(deco.borderRadius, AppRadii.buttonBorder);

    final label = tester.widget<Text>(
      find.text(AppLocalizationsEn().googleSignInErrorCredentialInUse),
    );
    expect(label.style?.color, const Color(0xFFFF7488));
    expect(label.style?.fontWeight, FontWeight.w600);
    expect(label.maxLines, isNull);

    final bannerWidth = tester.getSize(banner).width;
    final googleWidth = tester.getSize(
      find.byKey(WelcomeScreen.googleButtonKey),
    ).width;
    expect(bannerWidth, googleWidth);

    final semantics = tester.getSemantics(banner);
    expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
    expect(overflow, isNull);
  });

  testWidgets('TR error copy wraps on a small iPhone without overflow',
      (tester) async {
    FlutterError? overflow;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflow = FlutterError(details.exceptionAsString());
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await failApple(
      tester,
      locale: const Locale('tr'),
    );
    expect(find.byKey(WelcomeScreen.appleErrorKey), findsOneWidget);
    expect(
      find.text(AppLocalizationsTr().appleSignInErrorCredentialInUse),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(overflow, isNull);
  });

  testWidgets('failed Apple/Google attempts still call the injected flows once',
      (tester) async {
    var googleCalls = 0;
    var appleCalls = 0;
    await pumpWelcome(
      tester,
      signInWithGoogle: () async {
        googleCalls += 1;
        return GoogleSignInAttempt.failed(
          FirebaseAuthException(code: 'network-request-failed'),
        );
      },
      signInWithApple: () async {
        appleCalls += 1;
        return AppleSignInAttempt.failed(
          FirebaseAuthException(code: 'network-request-failed'),
        );
      },
    );

    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    expect(googleCalls, 1);
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);

    await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.pump();
    expect(appleCalls, 1);
    expect(find.byKey(WelcomeScreen.appleErrorKey), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('inline Welcome error appears immediately and auto-dismisses',
      (tester) async {
    await pumpWelcome(
      tester,
      signInWithGoogle: () async => GoogleSignInAttempt.failed(
        FirebaseAuthException(code: 'network-request-failed'),
      ),
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(const Duration(milliseconds: 1499));
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a new Welcome error cancels the previous dismiss timer',
      (tester) async {
    var calls = 0;
    await pumpWelcome(
      tester,
      signInWithGoogle: () async {
        calls += 1;
        return GoogleSignInAttempt.failed(
          FirebaseAuthException(
            code: calls == 1
                ? 'network-request-failed'
                : 'credential-already-in-use',
          ),
        );
      },
    );

    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);

    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    expect(calls, 2);
    expect(
      find.text(AppLocalizationsEn().googleSignInErrorCredentialInUse),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsNothing);
  });

  testWidgets('disposing Welcome cancels the error timer without setState',
      (tester) async {
    FlutterError? leak;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('setState() called after dispose') ||
          text.contains('deactivated widget')) {
        leak = FlutterError(text);
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await pumpWelcome(
      tester,
      signInWithGoogle: () async => GoogleSignInAttempt.failed(
        FirebaseAuthException(code: 'network-request-failed'),
      ),
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 2000));
    expect(leak, isNull);
  });

  Finder spinnerOn(Key key) {
    return find.descendant(
      of: find.byKey(key),
      matching: find.byType(CircularProgressIndicator),
    );
  }

  Finder googleLogo() {
    return find.descendant(
      of: find.byKey(WelcomeScreen.googleButtonKey),
      matching: find.byType(CustomPaint),
    );
  }

  Finder appleLogo() {
    return find.descendant(
      of: find.byKey(WelcomeScreen.appleButtonKey),
      matching: find.byIcon(Icons.apple),
    );
  }

  testWidgets('tap Google shows only the Google spinner', (tester) async {
    final gate = Completer<GoogleSignInAttempt>();
    await pumpWelcome(
      tester,
      signInWithGoogle: () => gate.future,
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();

    expect(spinnerOn(WelcomeScreen.googleButtonKey), findsOneWidget);
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsNothing);
    expect(appleLogo(), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete(GoogleSignInAttempt.cancelled());
    await tester.pump();
  });

  testWidgets('tap Apple shows only the Apple spinner', (tester) async {
    final gate = Completer<AppleSignInAttempt>();
    await pumpWelcome(
      tester,
      signInWithApple: () => gate.future,
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.pump();

    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsOneWidget);
    expect(spinnerOn(WelcomeScreen.googleButtonKey), findsNothing);
    expect(appleLogo(), findsNothing);
    expect(googleLogo(), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete(AppleSignInAttempt.cancelled());
    await tester.pump();
  });

  testWidgets('in-flight provider blocks a second auth attempt', (tester) async {
    final googleGate = Completer<GoogleSignInAttempt>();
    var googleCalls = 0;
    var appleCalls = 0;
    await pumpWelcome(
      tester,
      signInWithGoogle: () {
        googleCalls += 1;
        return googleGate.future;
      },
      signInWithApple: () async {
        appleCalls += 1;
        return AppleSignInAttempt.cancelled();
      },
    );

    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    expect(spinnerOn(WelcomeScreen.googleButtonKey), findsOneWidget);
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsNothing);

    await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.pump();
    expect(googleCalls, 1);
    expect(appleCalls, 0);
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsNothing);
    expect(appleLogo(), findsOneWidget);

    googleGate.complete(GoogleSignInAttempt.cancelled());
    await tester.pump();
  });

  testWidgets('Google cancel clears the Google spinner', (tester) async {
    final gate = Completer<GoogleSignInAttempt>();
    await pumpWelcome(
      tester,
      signInWithGoogle: () => gate.future,
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    expect(spinnerOn(WelcomeScreen.googleButtonKey), findsOneWidget);

    gate.complete(GoogleSignInAttempt.cancelled());
    await tester.pump();
    expect(spinnerOn(WelcomeScreen.googleButtonKey), findsNothing);
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsNothing);
    expect(googleLogo(), findsWidgets);
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsNothing);
  });

  testWidgets('Apple cancel clears the Apple spinner', (tester) async {
    final gate = Completer<AppleSignInAttempt>();
    await pumpWelcome(
      tester,
      signInWithApple: () => gate.future,
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.pump();
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsOneWidget);

    gate.complete(AppleSignInAttempt.cancelled());
    await tester.pump();
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsNothing);
    expect(spinnerOn(WelcomeScreen.googleButtonKey), findsNothing);
    expect(appleLogo(), findsOneWidget);
    expect(find.byKey(WelcomeScreen.appleErrorKey), findsNothing);
  });

  testWidgets('Google error clears the Google spinner', (tester) async {
    final gate = Completer<GoogleSignInAttempt>();
    await pumpWelcome(
      tester,
      signInWithGoogle: () => gate.future,
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    expect(spinnerOn(WelcomeScreen.googleButtonKey), findsOneWidget);

    gate.complete(
      GoogleSignInAttempt.failed(
        FirebaseAuthException(code: 'network-request-failed'),
      ),
    );
    await tester.pump();
    expect(spinnerOn(WelcomeScreen.googleButtonKey), findsNothing);
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsNothing);
    expect(googleLogo(), findsWidgets);
    expect(find.byKey(WelcomeScreen.googleErrorKey), findsOneWidget);
  });

  testWidgets('Apple error clears the Apple spinner', (tester) async {
    final gate = Completer<AppleSignInAttempt>();
    await pumpWelcome(
      tester,
      signInWithApple: () => gate.future,
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.pump();
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsOneWidget);

    gate.complete(
      AppleSignInAttempt.failed(
        FirebaseAuthException(code: 'network-request-failed'),
      ),
    );
    await tester.pump();
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsNothing);
    expect(spinnerOn(WelcomeScreen.googleButtonKey), findsNothing);
    expect(appleLogo(), findsOneWidget);
    expect(find.byKey(WelcomeScreen.appleErrorKey), findsOneWidget);
  });

  testWidgets('in-flight auth completing after dispose does not setState',
      (tester) async {
    FlutterError? leak;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('setState() called after dispose') ||
          text.contains('deactivated widget')) {
        leak = FlutterError(text);
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    final googleGate = Completer<GoogleSignInAttempt>();
    final appleGate = Completer<AppleSignInAttempt>();
    await pumpWelcome(
      tester,
      signInWithGoogle: () => googleGate.future,
      signInWithApple: () => appleGate.future,
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    expect(spinnerOn(WelcomeScreen.googleButtonKey), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    googleGate.complete(GoogleSignInAttempt.cancelled());
    appleGate.complete(AppleSignInAttempt.failed(
      FirebaseAuthException(code: 'network-request-failed'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(leak, isNull);
  });

  testWidgets('phone stays spinner-free while Google is in flight',
      (tester) async {
    final gate = Completer<GoogleSignInAttempt>();
    await pumpWelcome(
      tester,
      signInWithGoogle: () => gate.future,
    );
    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();

    final phone = find.text(AppLocalizationsEn().welcomeContinueWithPhone);
    expect(phone, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: phone, matching: find.byType(InkWell)),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsNothing);
    expect(appleLogo(), findsOneWidget);

    await tester.tap(phone);
    await tester.pump();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(spinnerOn(WelcomeScreen.appleButtonKey), findsNothing);

    gate.complete(GoogleSignInAttempt.cancelled());
    await tester.pump();
  });
}
