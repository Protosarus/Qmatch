import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/navigation/auth_wrapper.dart';
import 'package:qmatch/core/services/auth_provider_resolver.dart';
import 'package:qmatch/core/services/email_verification_policy.dart';
import 'package:qmatch/features/auth/email_verification_flow.dart';
import 'package:qmatch/features/auth/screens/email_signup_screen.dart';
import 'package:qmatch/features/auth/screens/email_verification_screen.dart';
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

  group('policy A/B/C', () {
    test('A password + unverified requires the gate', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['password'],
          emailVerified: false,
        ),
        isTrue,
      );
    });

    test('B password + verified continues normally', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['password'],
          emailVerified: true,
        ),
        isFalse,
      );
    });

    test('C phone auth never requires email verification', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['phone'],
          emailVerified: false,
        ),
        isFalse,
      );
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['phone'],
          emailVerified: true,
        ),
        isFalse,
      );
    });

    test('Google and Apple are not gated by the password-email policy', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['google.com'],
          emailVerified: false,
        ),
        isFalse,
      );
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['apple.com'],
          emailVerified: false,
        ),
        isFalse,
      );
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['firebase', 'password'],
          emailVerified: false,
        ),
        isTrue,
      );
    });

    test('does not use email-presence as the gate', () {
      final src = File(
        'lib/core/services/email_verification_policy.dart',
      ).readAsStringSync();
      expect(src.contains('user.email != null'), isFalse);
      expect(src.contains('passwordProviderId'), isTrue);
    });
  });

  group('AuthWrapper signed-in branch D/E/L', () {
    testWidgets('D/E unverified password stays on verification gate',
        (tester) async {
      await tester.pumpWidget(
        app(
          home: const AuthSignedInVerificationBranch(
            requiresEmailVerification: true,
            email: 'user@example.com',
            child: Text('onboarding-or-main'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(find.text('onboarding-or-main'), findsNothing);
      expect(find.textContaining('user@example.com'), findsOneWidget);
    });

    testWidgets('B/C verified or phone continues past the gate',
        (tester) async {
      await tester.pumpWidget(
        app(
          home: const AuthSignedInVerificationBranch(
            requiresEmailVerification: false,
            email: 'user@example.com',
            child: Text('onboarding-or-main'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(EmailVerificationScreen), findsNothing);
      expect(find.text('onboarding-or-main'), findsOneWidget);
    });

    test('L AuthWrapper gates verification before onboarding destinations', () {
      final src =
          File('lib/core/navigation/auth_wrapper.dart').readAsStringSync();
      final verify = src.indexOf('AuthSignedInPolicyGate');
      final displayName = src.indexOf('DisplayNameCompletionScreen');
      final gate = src.indexOf('AssessmentProgressRouteGate');
      expect(verify, greaterThan(0));
      expect(displayName, greaterThan(verify));
      expect(gate, greaterThan(verify));
      expect(src.contains('EmailVerificationScreen'), isTrue);
    });
  });

  group('verification screen F/G/H/I/J', () {
    testWidgets('F reload after verified exits via onVerified', (tester) async {
      var verifiedCalls = 0;
      await tester.pumpWidget(
        app(
          home: EmailVerificationScreen(
            email: 'ada@example.com',
            checkVerified: () async => true,
            refreshIdToken: () async {},
            onVerified: () => verifiedCalls += 1,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(EmailVerificationScreen.checkKey));
      await tester.pump();
      expect(verifiedCalls, 1);
      expect(find.byKey(EmailVerificationScreen.bannerKey), findsNothing);
    });

    testWidgets('verification success force-refreshes the ID token',
        (tester) async {
      var refreshCalls = 0;
      var verifiedCalls = 0;
      await tester.pumpWidget(
        app(
          home: EmailVerificationScreen(
            email: 'ada@example.com',
            checkVerified: () async => true,
            refreshIdToken: () async {
              refreshCalls += 1;
            },
            onVerified: () => verifiedCalls += 1,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(EmailVerificationScreen.checkKey));
      await tester.pump();
      expect(refreshCalls, 1);
      expect(verifiedCalls, 1);
    });

    testWidgets('G reload while unverified stays on the gate', (tester) async {
      var verifiedCalls = 0;
      await tester.pumpWidget(
        app(
          home: EmailVerificationScreen(
            email: 'ada@example.com',
            checkVerified: () async => false,
            onVerified: () => verifiedCalls += 1,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(EmailVerificationScreen.checkKey));
      await tester.pump();
      expect(verifiedCalls, 0);
      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(find.byKey(EmailVerificationScreen.bannerKey), findsOneWidget);
      expect(find.text(l10nEn.emailVerificationStillPending), findsOneWidget);
    });

    testWidgets('H resend invokes sendEmailVerification seam', (tester) async {
      var resendCalls = 0;
      await tester.pumpWidget(
        app(
          home: EmailVerificationScreen(
            email: 'ada@example.com',
            resend: () async {
              resendCalls += 1;
            },
            resendCooldown: const Duration(seconds: 45),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(EmailVerificationScreen.resendKey));
      await tester.pump();
      expect(resendCalls, 1);
      expect(find.text(l10nEn.emailVerificationResendSent), findsOneWidget);
    });

    testWidgets('I resend cooldown prevents spam', (tester) async {
      var resendCalls = 0;
      await tester.pumpWidget(
        app(
          home: EmailVerificationScreen(
            email: 'ada@example.com',
            resend: () async {
              resendCalls += 1;
            },
            resendCooldown: const Duration(seconds: 45),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(EmailVerificationScreen.resendKey));
      await tester.pump();
      await tester.tap(find.byKey(EmailVerificationScreen.resendKey));
      await tester.pump();
      expect(resendCalls, 1);
      expect(find.textContaining('45'), findsOneWidget);
    });

    testWidgets('J sign-out invokes the sign-out seam', (tester) async {
      var signOutCalls = 0;
      await tester.pumpWidget(
        app(
          home: EmailVerificationScreen(
            email: 'ada@example.com',
            signOut: () async {
              signOutCalls += 1;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(EmailVerificationScreen.signOutKey));
      await tester.pump();
      expect(signOutCalls, 1);
    });

    testWidgets('maps too-many-requests without exposing the raw code',
        (tester) async {
      await tester.pumpWidget(
        app(
          home: EmailVerificationScreen(
            email: 'ada@example.com',
            resend: () async {
              throw FirebaseAuthException(code: 'too-many-requests');
            },
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(EmailVerificationScreen.resendKey));
      await tester.pump();
      expect(
          find.text(l10nEn.emailVerificationTooManyRequests), findsOneWidget);
      expect(find.textContaining('too-many-requests'), findsNothing);
    });
  });

  group('architecture K/M/N', () {
    test('K no nested AuthWrapper is introduced', () {
      for (final path in [
        'lib/features/auth/screens/email_verification_screen.dart',
        'lib/features/auth/screens/email_signup_screen.dart',
        'lib/features/auth/screens/login_screen.dart',
        'lib/core/navigation/auth_navigation.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains('AuthWrapper('), isFalse, reason: path);
        expect(src.contains('pushAndRemoveUntil'), isFalse, reason: path);
      }
      expect(
        File('lib/main.dart').readAsStringSync().contains('AuthWrapper()'),
        isTrue,
      );
    });

    test('M no client-authoritative email_verified Firestore flag', () {
      for (final path in [
        'lib/core/services/email_verification_policy.dart',
        'lib/features/auth/email_verification_flow.dart',
        'lib/features/auth/screens/email_verification_screen.dart',
        'lib/core/navigation/auth_wrapper.dart',
        'lib/features/auth/email_signup_flow.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains("'email_verified'"), isFalse, reason: path);
        expect(src.contains('"email_verified"'), isFalse, reason: path);
      }
    });

    test('verification success path force-refreshes the Firebase ID token', () {
      final flow = File(
        'lib/features/auth/email_verification_flow.dart',
      ).readAsStringSync();
      final screen = File(
        'lib/features/auth/screens/email_verification_screen.dart',
      ).readAsStringSync();
      expect(flow.contains('getIdToken(true)'), isTrue);
      expect(screen.contains('forceRefreshIdToken'), isTrue);
      expect(screen.contains('refreshIdToken'), isTrue);
    });

    test('signup still completes through AuthNavigation, not onboarding', () {
      final screen = File(
        'lib/features/auth/screens/email_signup_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('AuthNavigation.completeAuthentication'), isTrue);
      expect(screen.contains('IQTest'), isFalse);
      expect(screen.contains('ProfileSetup'), isFalse);
      expect(screen.contains('PersonaAssignment'), isFalse);
      expect(screen.contains('Discover'), isFalse);
    });

    test('Turkish and English verification copy exist', () {
      expect(l10nEn.emailVerificationCheck, 'I verified');
      expect(AppLocalizationsTr().emailVerificationCheck, 'Doğruladım');
      expect(
        EmailVerificationFlow.mapAuthError(
          l10nEn,
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        l10nEn.emailVerificationNetworkError,
      );
    });

    test('password resolver remains email for Firestore auth_provider', () {
      expect(
        AuthProviderResolver.resolve(providerIds: const ['password']),
        AuthProviderResolver.email,
      );
    });
  });

  testWidgets(
      'signup success still pops to the existing root, not a new wrapper',
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
    await tester.enterText(
      find.byKey(EmailSignupScreen.emailFieldKey),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(EmailSignupScreen.passwordFieldKey),
      'secret1',
    );
    await tester.enterText(
      find.byKey(EmailSignupScreen.confirmFieldKey),
      'secret1',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(EmailSignupScreen.submitKey));
    await tester.tap(find.byKey(EmailSignupScreen.submitKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(EmailSignupScreen), findsNothing);
    expect(find.byType(AuthWrapper), findsNothing);
    expect(find.byKey(const Key('auth-wrapper-root')), findsOneWidget);
  });

  test('login still uses shared completion and does not push onboarding', () {
    final login =
        File('lib/features/auth/screens/login_screen.dart').readAsStringSync();
    expect(login.contains('AuthNavigation.completeAuthentication'), isTrue);
    expect(login.contains('EmailVerificationScreen'), isFalse);
    expect(login.contains('ProfileSetup'), isFalse);
  });
}
