import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/navigation/auth_wrapper.dart';
import 'package:qmatch/features/auth/email_signup_flow.dart';
import 'package:qmatch/features/auth/screens/email_signup_screen.dart';
import 'package:qmatch/features/auth/screens/login_screen.dart';
import 'package:qmatch/features/auth/screens/welcome_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';
import 'package:qmatch/l10n/app_localizations_tr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final l10nEn = AppLocalizationsEn();

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

  Future<void> enterSignupFields(
    WidgetTester tester, {
    required String email,
    required String password,
    required String confirm,
  }) async {
    await tester.enterText(
      find.byKey(EmailSignupScreen.emailFieldKey),
      email,
    );
    await tester.enterText(
      find.byKey(EmailSignupScreen.passwordFieldKey),
      password,
    );
    await tester.enterText(
      find.byKey(EmailSignupScreen.confirmFieldKey),
      confirm,
    );
    await tester.pump();
  }

  testWidgets('A. welcome signup entry opens email signup', (tester) async {
    await tester.pumpWidget(app(home: const WelcomeScreen()));
    await tester.pump();

    expect(find.byKey(const Key('qmatch-welcome-email-login')), findsOneWidget);
    final signupEntry = find.byKey(const Key('qmatch-welcome-email-signup'));
    expect(signupEntry, findsOneWidget);

    await tester.ensureVisible(signupEntry);
    await tester.tap(signupEntry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(EmailSignupScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('B. empty form cannot submit', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        home: EmailSignupScreen(
          register: ({required email, required password}) async {
            calls += 1;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(EmailSignupScreen.submitKey));
    await tester.tap(find.byKey(EmailSignupScreen.submitKey));
    await tester.pump();

    expect(calls, 0);
    expect(find.text(l10nEn.loginErrorEnterEmail), findsOneWidget);
    expect(find.text(l10nEn.loginErrorEnterPassword), findsOneWidget);
    expect(find.text(l10nEn.emailSignupErrorConfirmPassword), findsOneWidget);
  });

  testWidgets('C. invalid email shows validation', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        home: EmailSignupScreen(
          register: ({required email, required password}) async {
            calls += 1;
          },
        ),
      ),
    );
    await tester.pump();

    await enterSignupFields(
      tester,
      email: 'not-an-email',
      password: 'secret1',
      confirm: 'secret1',
    );
    await tester.ensureVisible(find.byKey(EmailSignupScreen.submitKey));
    await tester.tap(find.byKey(EmailSignupScreen.submitKey));
    await tester.pump();

    expect(calls, 0);
    expect(find.text(l10nEn.loginErrorValidEmail), findsOneWidget);
  });

  testWidgets('D. password mismatch shows validation', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        home: EmailSignupScreen(
          register: ({required email, required password}) async {
            calls += 1;
          },
        ),
      ),
    );
    await tester.pump();

    await enterSignupFields(
      tester,
      email: 'user@example.com',
      password: 'secret1',
      confirm: 'secret2',
    );
    await tester.ensureVisible(find.byKey(EmailSignupScreen.submitKey));
    await tester.tap(find.byKey(EmailSignupScreen.submitKey));
    await tester.pump();

    expect(calls, 0);
    expect(find.text(l10nEn.emailSignupErrorPasswordMismatch), findsOneWidget);
  });

  testWidgets('E. valid form calls signup exactly once', (tester) async {
    var calls = 0;
    String? seenEmail;
    String? seenPassword;
    await tester.pumpWidget(
      app(
        home: EmailSignupScreen(
          register: ({required email, required password}) async {
            calls += 1;
            seenEmail = email;
            seenPassword = password;
          },
        ),
      ),
    );
    await tester.pump();

    await enterSignupFields(
      tester,
      email: '  user@example.com  ',
      password: 'secret1',
      confirm: 'secret1',
    );
    await tester.ensureVisible(find.byKey(EmailSignupScreen.submitKey));
    await tester.tap(find.byKey(EmailSignupScreen.submitKey));
    await tester.pump();

    expect(calls, 1);
    expect(seenEmail, 'user@example.com');
    expect(seenPassword, 'secret1');
  });

  testWidgets('F. loading prevents duplicate submit', (tester) async {
    var calls = 0;
    final gate = Completer<void>();
    await tester.pumpWidget(
      app(
        home: EmailSignupScreen(
          register: ({required email, required password}) async {
            calls += 1;
            await gate.future;
          },
        ),
      ),
    );
    await tester.pump();

    await enterSignupFields(
      tester,
      email: 'user@example.com',
      password: 'secret1',
      confirm: 'secret1',
    );
    await tester.ensureVisible(find.byKey(EmailSignupScreen.submitKey));
    await tester.tap(find.byKey(EmailSignupScreen.submitKey));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.ensureVisible(find.byKey(EmailSignupScreen.submitKey));
    await tester.tap(find.byKey(EmailSignupScreen.submitKey));
    await tester.pump();
    expect(calls, 1);

    gate.complete();
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets(
    'G. email-already-in-use is a friendly user-facing error',
    (tester) async {
      await tester.pumpWidget(
        app(
          home: EmailSignupScreen(
            register: ({required email, required password}) async {
              throw FirebaseAuthException(code: 'email-already-in-use');
            },
          ),
        ),
      );
      await tester.pump();

      await enterSignupFields(
        tester,
        email: 'user@example.com',
        password: 'secret1',
        confirm: 'secret1',
      );
      await tester.ensureVisible(find.byKey(EmailSignupScreen.submitKey));
      await tester.tap(find.byKey(EmailSignupScreen.submitKey));
      await tester.pump();

      expect(find.byKey(EmailSignupScreen.errorBannerKey), findsOneWidget);
      expect(find.text(l10nEn.emailSignupErrorEmailInUse), findsWidgets);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(EmailSignupScreen.passwordFieldKey),
            )
            .controller
            ?.text,
        'secret1',
      );
      expect(find.textContaining('email-already-in-use'), findsNothing);
    },
  );

  testWidgets(
    'H. success uses shared auth completion and does not push AuthWrapper',
    (tester) async {
      await tester.pumpWidget(
        app(
          home: Builder(
            builder: (context) {
              return Scaffold(
                key: const Key('auth-wrapper-root'),
                body: TextButton(
                  key: const Key('open-signup'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EmailSignupScreen(
                          register: (
                              {required email, required password}) async {},
                        ),
                      ),
                    );
                  },
                  child: const Text('open signup'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open-signup')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(EmailSignupScreen), findsOneWidget);
      expect(find.byType(AuthWrapper), findsNothing);

      await enterSignupFields(
        tester,
        email: 'user@example.com',
        password: 'secret1',
        confirm: 'secret1',
      );
      await tester.ensureVisible(find.byKey(EmailSignupScreen.submitKey));
      await tester.tap(find.byKey(EmailSignupScreen.submitKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(EmailSignupScreen), findsNothing);
      expect(find.byKey(const Key('auth-wrapper-root')), findsOneWidget);
      expect(find.byType(AuthWrapper), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'I. existing-account login link opens the email login screen',
    (tester) async {
      await tester.pumpWidget(app(home: const EmailSignupScreen()));
      await tester.pump();

      await tester.ensureVisible(find.byKey(EmailSignupScreen.goLoginKey));
      await tester.tap(find.byKey(EmailSignupScreen.goLoginKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AuthWrapper), findsNothing);
    },
  );

  test('J. signup UI does not write onboarding completion flags', () {
    final screen = File(
      'lib/features/auth/screens/email_signup_screen.dart',
    ).readAsStringSync();
    final flow = File(
      'lib/features/auth/email_signup_flow.dart',
    ).readAsStringSync();
    for (final src in [screen, flow]) {
      expect(src.contains('test_completed'), isFalse);
      expect(src.contains('frequency_completed'), isFalse);
      expect(src.contains('profile_completed'), isFalse);
      expect(src.contains('discover_eligible'), isFalse);
      expect(src.contains('.emailVerified'), isFalse);
      expect(src.contains('isEmailVerified'), isFalse);
      expect(src.contains('AuthWrapper('), isFalse);
      expect(src.contains('pushAndRemoveUntil'), isFalse);
    }
    expect(screen.contains('AuthNavigation.completeAuthentication'), isTrue);
    expect(flow.contains('signUpWithEmail'), isTrue);
    expect(
      'await authService.createUserInFirestore'.allMatches(flow).length,
      1,
    );
  });

  test('Turkish signup copy is available', () {
    final tr = AppLocalizationsTr();
    expect(tr.welcomeSignUpWithEmail, 'E-posta ile kayıt ol');
    expect(tr.emailSignupConfirmPassword, 'Şifreyi tekrar gir');
    expect(tr.emailSignupAlreadyHaveAccount, 'Zaten hesabın var mı?');
    expect(tr.logIn, 'Giriş yap');
  });

  test('maps email-already-in-use without exposing the raw code', () {
    final message = EmailSignupFlow.mapAuthError(
      l10nEn,
      FirebaseAuthException(code: 'email-already-in-use'),
    );
    expect(message, l10nEn.emailSignupErrorEmailInUse);
    expect(message.contains('email-already-in-use'), isFalse);
  });
}
