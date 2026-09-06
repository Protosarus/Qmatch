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
import 'package:qmatch/features/auth/apple_sign_in_flow.dart';
import 'package:qmatch/features/auth/google_sign_in_flow.dart';
import 'package:qmatch/features/auth/screens/email_verification_screen.dart';
import 'package:qmatch/features/auth/screens/provider_collision_screen.dart';
import 'package:qmatch/features/auth/screens/welcome_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';
import 'package:qmatch/l10n/app_localizations_tr.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  group('policy G/H/I/J', () {
    test('G Apple bypasses the password email-verification gate', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['apple.com'],
          emailVerified: false,
        ),
        isFalse,
      );
    });

    test('H unverified password is still gated', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['password'],
          emailVerified: false,
        ),
        isTrue,
      );
    });

    test('I phone is unchanged', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['phone'],
          emailVerified: false,
        ),
        isFalse,
      );
    });

    test('J Google is unchanged', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['google.com'],
          emailVerified: false,
        ),
        isFalse,
      );
    });
  });

  group('nonce B/C', () {
    test('B raw nonce is cryptographically generated and hashed', () {
      final a = AppleSignInFlow.generateRawNonce();
      final b = AppleSignInFlow.generateRawNonce();
      expect(a.length, AppleSignInFlow.nonceLength);
      expect(b.length, AppleSignInFlow.nonceLength);
      expect(a, isNot(b));
      expect(AppleSignInFlow.sha256Of('abc').length, 64);
      expect(
        AppleSignInFlow.sha256Of('abc'),
        AppleSignInFlow.sha256Of('abc'),
      );
      final src = File(
        'lib/features/auth/apple_sign_in_flow.dart',
      ).readAsStringSync();
      expect(src.contains('Random.secure()'), isTrue);
      expect(src.contains('sha256.convert'), isTrue);
    });

    test('C hashed nonce goes to Apple and raw nonce to Firebase', () async {
      String? hashedSeen;
      String? rawSeen;
      String? idSeen;
      final raw = 'fixed-raw-nonce-value-32chars!!';
      final service = AuthService(
        generateAppleNonce: () => raw,
        requestAppleAuthorization: (hashedNonce) async {
          hashedSeen = hashedNonce;
          return const AppleAuthorizationResult(
              identityToken: 'apple-id-token');
        },
        buildAppleCredential: ({required idToken, required rawNonce}) {
          idSeen = idToken;
          rawSeen = rawNonce;
          return OAuthProvider('apple.com').credential(
            idToken: idToken,
            rawNonce: rawNonce,
          );
        },
        signInWithCredential: (credential) async {
          throw FirebaseAuthException(code: 'network-request-failed');
        },
      );
      final attempt = await service.signInWithApple();
      expect(attempt.isFailed, isTrue);
      expect(hashedSeen, AppleSignInFlow.sha256Of(raw));
      expect(rawSeen, raw);
      expect(idSeen, 'apple-id-token');
    });
  });

  group('Welcome Apple button A/D/E/N/O', () {
    testWidgets('A Apple CTA invokes the Apple auth flow', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        app(
          home: WelcomeScreen(
            showAppleButton: true,
            signInWithApple: () async {
              calls += 1;
              return AppleSignInAttempt.cancelled();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('D cancellation is a clean no-op', (tester) async {
      await tester.pumpWidget(
        app(
          home: WelcomeScreen(
            showAppleButton: true,
            signInWithApple: () async => AppleSignInAttempt.cancelled(),
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
      await tester.pump();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byKey(WelcomeScreen.appleErrorKey), findsNothing);
      expect(find.byType(AuthWrapper), findsNothing);
    });

    testWidgets(
      'E success uses completeAuthentication and does not push a wrapper',
      (tester) async {
        await tester.pumpWidget(
          app(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  key: const Key('auth-wrapper-root'),
                  body: TextButton(
                    key: const Key('open-welcome'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WelcomeScreen(
                            showAppleButton: true,
                            signInWithApple: () async =>
                                AppleSignInAttempt.success(),
                          ),
                        ),
                      );
                    },
                    child: const Text('open welcome'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('open-welcome')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
        await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(WelcomeScreen), findsNothing);
        expect(find.byType(AuthWrapper), findsNothing);
        expect(find.byKey(const Key('auth-wrapper-root')), findsOneWidget);
      },
    );

    testWidgets('N double-tap cannot start a second Apple request',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        app(
          home: WelcomeScreen(
            showAppleButton: true,
            signInWithApple: () async {
              calls += 1;
              await Future<void>.delayed(const Duration(milliseconds: 80));
              return AppleSignInAttempt.cancelled();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(calls, 1);
    });

    testWidgets('O collision opens collision recovery', (tester) async {
      await tester.pumpWidget(
        app(
          home: WelcomeScreen(
            showAppleButton: true,
            signInWithApple: () async => AppleSignInAttempt.collision(
              FirebaseAuthException(
                code: 'account-exists-with-different-credential',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
      await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(ProviderCollisionScreen), findsOneWidget);
      expect(find.text(l10nEn.providerCollisionBody), findsOneWidget);
      expect(
        find.textContaining('account-exists-with-different-credential'),
        findsNothing,
      );
    });

    testWidgets('Google CTA remains available beside Apple', (tester) async {
      await tester.pumpWidget(
        app(
          home: WelcomeScreen(
            showAppleButton: true,
            signInWithGoogle: () async => GoogleSignInAttempt.cancelled(),
            signInWithApple: () async => AppleSignInAttempt.cancelled(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(WelcomeScreen.googleButtonKey), findsOneWidget);
      expect(find.byKey(WelcomeScreen.appleButtonKey), findsOneWidget);
    });
  });

  group('AuthService Apple seams D/O/P', () {
    test('D Apple authorization cancel writes nothing', () async {
      var credentialCalls = 0;
      final service = AuthService(
        requestAppleAuthorization: (hashedNonce) async => null,
        signInWithCredential: (credential) async {
          credentialCalls += 1;
          throw StateError('should not sign in');
        },
      );
      final attempt = await service.signInWithApple();
      expect(attempt.isCancelled, isTrue);
      expect(credentialCalls, 0);
    });

    test('D SignInWithAppleAuthorizationException canceled is a no-op',
        () async {
      var credentialCalls = 0;
      final service = AuthService(
        requestAppleAuthorization: (hashedNonce) async {
          throw const SignInWithAppleAuthorizationException(
            code: AuthorizationErrorCode.canceled,
            message: 'user canceled',
          );
        },
        signInWithCredential: (credential) async {
          credentialCalls += 1;
          throw StateError('should not sign in');
        },
      );
      final attempt = await service.signInWithApple();
      expect(attempt.isCancelled, isTrue);
      expect(credentialCalls, 0);
    });

    test('O collision stays typed and does not link during the attempt',
        () async {
      var linkCalls = 0;
      final service = AuthService(
        requestAppleAuthorization: (hashedNonce) async {
          return const AppleAuthorizationResult(identityToken: 'tok');
        },
        signInWithCredential: (credential) async {
          throw FirebaseAuthException(
            code: 'account-exists-with-different-credential',
          );
        },
      );
      final attempt = await service.signInWithApple();
      expect(attempt.isCollision, isTrue);
      expect(
        attempt.error?.code,
        'account-exists-with-different-credential',
      );
      expect(linkCalls, 0);
      final src =
          File('lib/core/services/auth_service.dart').readAsStringSync();
      expect(src.contains('fetchSignInMethodsForEmail'), isFalse);
    });

    test('P sign-out does not revoke Apple authorization', () {
      final src =
          File('lib/core/services/auth_service.dart').readAsStringSync();
      expect(src.contains('revokeToken'), isFalse);
      expect(src.contains('revokeApple'), isFalse);
      expect(src.contains('getCredentialState'), isFalse);
    });
  });

  group('bootstrap K/L/M', () {
    test('K new Apple user gets safe identity bootstrap', () {
      final docs = <String, Map<String, dynamic>>{};
      final next = UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: const UserDocumentEnsureInput(
          uid: 'a-new',
          authProvider: AuthProviderResolver.apple,
          email: 'hidden@privaterelay.appleid.com',
          displayName: 'Ada Lovelace',
        ),
      );
      expect(next['auth_provider'], AuthProviderResolver.apple);
      expect(next['email'], 'hidden@privaterelay.appleid.com');
      expect(next.containsKey('name'), isFalse);
      expect(next['test_completed'], isFalse);
      expect(next['discover_eligible'], isFalse);
      expect(next.containsKey('email_verified'), isFalse);
    });

    test('L returning Apple user keeps stored name/email when Apple omits them',
        () {
      final docs = <String, Map<String, dynamic>>{
        'a-old': {
          'uid': 'a-old',
          'auth_provider': AuthProviderResolver.apple,
          'name': 'Kept Name',
          'email': 'kept@privaterelay.appleid.com',
          'test_completed': true,
          'profile_completed': true,
          'discover_eligible': true,
        },
      };
      final next = UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: const UserDocumentEnsureInput(
          uid: 'a-old',
          authProvider: AuthProviderResolver.apple,
          email: null,
          displayName: null,
        ),
      );
      expect(next['name'], 'Kept Name');
      expect(next['email'], 'kept@privaterelay.appleid.com');
      expect(next['test_completed'], isTrue);
      expect(next['profile_completed'], isTrue);
      expect(next['discover_eligible'], isTrue);
    });

    test('M private relay email is accepted', () {
      expect(
        AppleSignInFlow.isPrivateRelayEmail(
          'abc@privaterelay.appleid.com',
        ),
        isTrue,
      );
      final docs = <String, Map<String, dynamic>>{};
      final next = UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: const UserDocumentEnsureInput(
          uid: 'relay',
          authProvider: AuthProviderResolver.apple,
          email: 'abc@privaterelay.appleid.com',
        ),
      );
      expect(next['email'], 'abc@privaterelay.appleid.com');
    });
  });

  group('architecture F/G/Q/R', () {
    testWidgets('G Apple branch does not show EmailVerificationScreen',
        (tester) async {
      await tester.pumpWidget(
        app(
          home: const AuthSignedInVerificationBranch(
            requiresEmailVerification: false,
            email: 'ada@privaterelay.appleid.com',
            child: Text('apple-main'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(EmailVerificationScreen), findsNothing);
      expect(find.text('apple-main'), findsOneWidget);
    });

    test('F only one root AuthWrapper remains', () {
      for (final path in [
        'lib/features/auth/screens/welcome_screen.dart',
        'lib/features/auth/apple_sign_in_flow.dart',
        'lib/core/navigation/auth_navigation.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains('AuthWrapper('), isFalse, reason: path);
      }
    });

    test('Q entitlement exists and preserves aps-environment', () {
      final debug = File('ios/Runner/Runner.entitlements').readAsStringSync();
      final release =
          File('ios/Runner/RunnerRelease.entitlements').readAsStringSync();
      for (final src in [debug, release]) {
        expect(src.contains('com.apple.developer.applesignin'), isTrue);
        expect(src.contains('<string>Default</string>'), isTrue);
        expect(src.contains('aps-environment'), isTrue);
      }
      expect(debug.contains('<string>development</string>'), isTrue);
      expect(release.contains('<string>production</string>'), isTrue);
      final pbx =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      expect(
          pbx.contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'),
          isTrue);
      expect(
        pbx.contains(
            'CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements;'),
        isTrue,
      );
    });

    test('R no client email_verified authority', () {
      for (final path in [
        'lib/features/auth/apple_sign_in_flow.dart',
        'lib/features/auth/screens/welcome_screen.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains("'email_verified'"), isFalse, reason: path);
      }
    });

    test('Turkish and English Apple copy exist', () {
      expect(l10nEn.welcomeContinueWithApple, 'Continue with Apple');
      expect(
          AppLocalizationsTr().welcomeContinueWithApple, 'Apple ile devam et');
    });

    test('Android is not treated as a native Apple target', () {
      final src = File(
        'lib/features/auth/apple_sign_in_flow.dart',
      ).readAsStringSync();
      expect(src.contains('TargetPlatform.android'), isFalse);
      expect(src.contains('webAuthenticationOptions'), isFalse);
    });
  });
}
