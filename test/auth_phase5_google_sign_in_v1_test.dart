import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/navigation/auth_wrapper.dart';
import 'package:qmatch/core/services/auth_provider_resolver.dart';
import 'package:qmatch/core/services/auth_service.dart';
import 'package:qmatch/core/services/email_verification_policy.dart';
import 'package:qmatch/core/services/user_document_ensure.dart';
import 'package:qmatch/features/auth/google_sign_in_flow.dart';
import 'package:qmatch/features/auth/screens/email_verification_screen.dart';
import 'package:qmatch/features/auth/screens/provider_collision_screen.dart';
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

  group('policy D / F / G', () {
    test('D Google never hits the password email-verification gate', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['google.com'],
          emailVerified: false,
        ),
        isFalse,
      );
    });

    test('F phone behavior is unchanged', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['phone'],
          emailVerified: false,
        ),
        isFalse,
      );
    });

    test('G unverified password still requires the gate', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['password'],
          emailVerified: false,
        ),
        isTrue,
      );
    });
  });

  group('Welcome Google button A/B/C/J/K', () {
    testWidgets('A Google button invokes the Google auth flow', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        app(
          home: WelcomeScreen(
            signInWithGoogle: () async {
              calls += 1;
              return GoogleSignInAttempt.cancelled();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('B cancellation is clean and shows no error', (tester) async {
      await tester.pumpWidget(
        app(
          home: WelcomeScreen(
            signInWithGoogle: () async => GoogleSignInAttempt.cancelled(),
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.pump();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byKey(WelcomeScreen.googleErrorKey), findsNothing);
      expect(find.byType(AuthWrapper), findsNothing);
    });

    testWidgets(
      'C success uses completeAuthentication and does not push a wrapper',
      (tester) async {
        await tester.pumpWidget(
          app(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  key: const Key('auth-wrapper-root'),
                  body: Column(
                    children: [
                      TextButton(
                        key: const Key('open-welcome'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => WelcomeScreen(
                                signInWithGoogle: () async =>
                                    GoogleSignInAttempt.success(),
                              ),
                            ),
                          );
                        },
                        child: const Text('open welcome'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('open-welcome')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
        await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(WelcomeScreen), findsNothing);
        expect(find.byType(AuthWrapper), findsNothing);
        expect(find.byKey(const Key('auth-wrapper-root')), findsOneWidget);
      },
    );

    testWidgets('J double-tap cannot start a second Google request',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        app(
          home: WelcomeScreen(
            signInWithGoogle: () async {
              calls += 1;
              await Future<void>.delayed(const Duration(milliseconds: 80));
              return GoogleSignInAttempt.cancelled();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(calls, 1);
    });

    testWidgets(
      'K account-exists-with-different-credential opens collision recovery',
      (tester) async {
        await tester.pumpWidget(
          app(
            home: WelcomeScreen(
              signInWithGoogle: () async => GoogleSignInAttempt.collision(
                FirebaseAuthException(
                  code: 'account-exists-with-different-credential',
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
        await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(ProviderCollisionScreen), findsOneWidget);
        expect(find.text(l10nEn.providerCollisionBody), findsOneWidget);
        expect(
          find.textContaining('account-exists-with-different-credential'),
          findsNothing,
        );
        final welcome = File(
          'lib/features/auth/screens/welcome_screen.dart',
        ).readAsStringSync();
        final service = File(
          'lib/core/services/auth_service.dart',
        ).readAsStringSync();
        expect(welcome.contains('linkWithCredential'), isFalse);
        expect(service.contains('fetchSignInMethodsForEmail'), isFalse);
      },
    );
  });

  group('AuthService Google seams B/C/K/M', () {
    test('B picker cancellation writes nothing and does not sign in', () async {
      var credentialCalls = 0;
      final service = AuthService(
        pickGoogleAuthTokens: () async => null,
        signInWithCredential: (credential) async {
          credentialCalls += 1;
          throw StateError('should not sign in');
        },
      );
      final attempt = await service.signInWithGoogle();
      expect(attempt.isCancelled, isTrue);
      expect(credentialCalls, 0);
    });

    test('K collision stays typed and signs Google out without linking',
        () async {
      var googleSignOuts = 0;
      final service = AuthService(
        pickGoogleAuthTokens: () async => (
          idToken: 'id-token',
          accessToken: 'access-token',
        ),
        signInWithCredential: (credential) async {
          expect(credential is GoogleAuthProvider, isFalse);
          throw FirebaseAuthException(
            code: 'account-exists-with-different-credential',
          );
        },
        signOutGoogle: () async {
          googleSignOuts += 1;
        },
      );
      final attempt = await service.signInWithGoogle();
      expect(attempt.isCollision, isTrue);
      expect(
        attempt.error?.code,
        'account-exists-with-different-credential',
      );
      expect(googleSignOuts, 1);
    });

    test('M sign-out also clears the Google session without disconnect', () {
      final src =
          File('lib/core/services/auth_service.dart').readAsStringSync();
      expect(src.contains('_signOutGoogleSession()'), isTrue);
      expect(src.contains('GoogleSignInFlow.createClient().signOut()'), isTrue);
      expect(src.contains('.disconnect()'), isFalse);
    });
  });

  group('bootstrap H/I', () {
    test('I new Google user gets safe identity bootstrap', () {
      final docs = <String, Map<String, dynamic>>{};
      final next = UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: const UserDocumentEnsureInput(
          uid: 'g-new',
          authProvider: AuthProviderResolver.google,
          email: 'ada@gmail.com',
          displayName: 'Ada',
        ),
      );
      expect(next['auth_provider'], AuthProviderResolver.google);
      expect(next['email'], 'ada@gmail.com');
      expect(next.containsKey('name'), isFalse);
      expect(next['test_completed'], isFalse);
      expect(next['discover_eligible'], isFalse);
      expect(next['profile_completed'], isFalse);
      expect(next.containsKey('email_verified'), isFalse);
    });

    test('H existing Google user bootstrap preserves progress/profile', () {
      final docs = <String, Map<String, dynamic>>{
        'g-old': {
          'uid': 'g-old',
          'auth_provider': AuthProviderResolver.google,
          'name': 'Kept',
          'email': 'kept@gmail.com',
          'test_completed': true,
          'frequency_completed': true,
          'profile_completed': true,
          'discover_eligible': true,
          'iq_score': 14,
          'archetype': 'Sezgisel',
        },
      };
      final next = UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: const UserDocumentEnsureInput(
          uid: 'g-old',
          authProvider: AuthProviderResolver.google,
          email: 'ada@gmail.com',
          displayName: 'ShouldNotOverwrite',
        ),
      );
      expect(next['name'], 'Kept');
      expect(next['email'], 'kept@gmail.com');
      expect(next['test_completed'], isTrue);
      expect(next['frequency_completed'], isTrue);
      expect(next['profile_completed'], isTrue);
      expect(next['discover_eligible'], isTrue);
      expect(next['iq_score'], 14);
      expect(next['archetype'], 'Sezgisel');
      expect(next['auth_provider'], AuthProviderResolver.google);
    });
  });

  group('architecture D/E/L/N', () {
    testWidgets('E Google branch does not show EmailVerificationScreen',
        (tester) async {
      await tester.pumpWidget(
        app(
          home: const AuthSignedInVerificationBranch(
            requiresEmailVerification: false,
            email: 'ada@gmail.com',
            child: Text('google-main'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(EmailVerificationScreen), findsNothing);
      expect(find.text('google-main'), findsOneWidget);
    });

    test('D only one root AuthWrapper remains', () {
      for (final path in [
        'lib/features/auth/screens/welcome_screen.dart',
        'lib/features/auth/google_sign_in_flow.dart',
        'lib/core/navigation/auth_navigation.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains('AuthWrapper('), isFalse, reason: path);
      }
      expect(
        File('lib/main.dart').readAsStringSync().contains('AuthWrapper()'),
        isTrue,
      );
    });

    test('L no client email_verified authority', () {
      for (final path in [
        'lib/features/auth/google_sign_in_flow.dart',
        'lib/features/auth/screens/welcome_screen.dart',
        'lib/core/services/auth_service.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains("'email_verified'"), isFalse, reason: path);
        expect(src.contains('"email_verified"'), isFalse, reason: path);
      }
    });

    test('Turkish and English Google copy exist', () {
      expect(l10nEn.welcomeContinueWithGoogle, 'Continue with Google');
      expect(AppLocalizationsTr().welcomeContinueWithGoogle,
          'Google ile devam et');
    });

    test('Phase 4 backend still allows google.com without password gate', () {
      final src = File(
        'functions/src/verified_product_auth.js',
      ).readAsStringSync();
      expect(src.contains("GOOGLE_PROVIDER = 'google.com'"), isTrue);
      expect(src.contains('isPasswordProvider(auth) && !isEmailVerifiedClaim'),
          isTrue);
    });

    test('web client ID is the existing google-services.json client', () {
      final android =
          File('android/app/google-services.json').readAsStringSync();
      expect(android.contains(GoogleSignInFlow.webClientId), isTrue);
    });
  });
}
