import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/navigation/auth_wrapper.dart';
import 'package:qmatch/core/services/auth_provider_resolver.dart';
import 'package:qmatch/core/services/auth_service.dart';
import 'package:qmatch/core/services/email_verification_policy.dart';
import 'package:qmatch/core/services/pending_provider_link.dart';
import 'package:qmatch/core/services/user_document_ensure.dart';
import 'package:qmatch/features/auth/apple_sign_in_flow.dart';
import 'package:qmatch/features/auth/email_signup_flow.dart';
import 'package:qmatch/features/auth/google_sign_in_flow.dart';
import 'package:qmatch/features/auth/provider_link_flow.dart';
import 'package:qmatch/features/auth/screens/email_verification_screen.dart';
import 'package:qmatch/features/auth/screens/login_screen.dart';
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

  setUp(() {
    PendingProviderLinkStore.debugReset();
    SignInProviderMemory.clear();
  });

  final l10nEn = AppLocalizationsEn();
  final l10nTr = AppLocalizationsTr();

  AuthCredential googleCredential() {
    return GoogleAuthProvider.credential(
      idToken: 'id-token',
      accessToken: 'access-token',
    );
  }

  AuthCredential appleCredential() {
    return OAuthProvider('apple.com').credential(
      idToken: 'apple-id-token',
      rawNonce: 'raw-nonce',
    );
  }

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

  group('A/B collision pending state', () {
    test('A Google collision creates pending link state', () async {
      final service = AuthService(
        pickGoogleAuthTokens: () async => (
          idToken: 'id-token',
          accessToken: 'access-token',
        ),
        signInWithCredential: (credential) async {
          throw FirebaseAuthException(
            code: 'account-exists-with-different-credential',
            email: 'ada@example.com',
            credential: googleCredential(),
          );
        },
        signOutGoogle: () async {},
      );
      final attempt = await service.signInWithGoogle();
      expect(attempt.isCollision, isTrue);
      expect(PendingProviderLinkStore.hasPending, isTrue);
      expect(
        PendingProviderLinkStore.current?.attemptedProvider,
        AuthProviderResolver.googleProviderId,
      );
      expect(PendingProviderLinkStore.current?.emailHint, 'ada@example.com');
    });

    test('B Apple collision creates pending link state', () async {
      final service = AuthService(
        requestAppleAuthorization: (hashedNonce) async {
          return const AppleAuthorizationResult(identityToken: 'tok');
        },
        signInWithCredential: (credential) async {
          throw FirebaseAuthException(
            code: 'account-exists-with-different-credential',
            email: 'ada@privaterelay.appleid.com',
            credential: appleCredential(),
          );
        },
      );
      final attempt = await service.signInWithApple();
      expect(attempt.isCollision, isTrue);
      expect(PendingProviderLinkStore.hasPending, isTrue);
      expect(
        PendingProviderLinkStore.current?.attemptedProvider,
        AuthProviderResolver.appleProviderId,
      );
    });
  });

  group('C/D memory-only pending credential', () {
    test('C/D pending store is process memory only', () {
      final store = File(
        'lib/core/services/pending_provider_link.dart',
      ).readAsStringSync();
      expect(store.contains("import 'package:shared_preferences"), isFalse);
      expect(store.contains("import 'package:flutter_secure_storage"), isFalse);
      expect(store.contains("import 'package:cloud_firestore"), isFalse);
      expect(store.contains('FirebaseFirestore'), isFalse);
      expect(store.contains('debugPrint'), isFalse);
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
        emailHint: 'ada@example.com',
      );
      expect(PendingProviderLinkStore.hasPending, isTrue);
      PendingProviderLinkStore.clear();
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });
  });

  group('E/F password + pending OAuth preserves UID', () {
    test('E existing password + pending Google links to same UID', () async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
      );
      var linkCalls = 0;
      final docs = <String, Map<String, dynamic>>{
        'ABC': {
          'uid': 'ABC',
          'auth_provider': 'email',
          'test_completed': true,
          'iq_score': 132,
        },
      };
      final result = await AuthService().linkPendingCredential(
        existingUid: 'ABC',
        emailVerified: true,
        currentSignInProvider: AuthProviderResolver.passwordProviderId,
        linkAndReturnUid: (credential) async {
          linkCalls += 1;
          expect(credential.providerId, 'google.com');
          return 'ABC';
        },
        ensureExistingUser: (uid) async {
          UserDocumentEnsure.applyInMemory(
            docs: docs,
            input: UserDocumentEnsureInput(
              uid: uid,
              authProvider: AuthProviderResolver.google,
              email: 'ada@example.com',
            ),
          );
        },
      );
      expect(result.isLinked, isTrue);
      expect(result.uid, 'ABC');
      expect(linkCalls, 1);
      expect(PendingProviderLinkStore.hasPending, isFalse);
      expect(docs.keys, ['ABC']);
      expect(docs['ABC']?['auth_provider'], 'email');
      expect(docs['ABC']?['test_completed'], isTrue);
      expect(docs['ABC']?['iq_score'], 132);
    });

    test('F existing password + pending Apple links to same UID', () async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.appleProviderId,
        credential: appleCredential(),
      );
      final result = await AuthService().linkPendingCredential(
        existingUid: 'ABC',
        emailVerified: true,
        currentSignInProvider: AuthProviderResolver.passwordProviderId,
        linkAndReturnUid: (credential) async {
          expect(credential.providerId, 'apple.com');
          return 'ABC';
        },
        ensureExistingUser: (_) async {},
      );
      expect(result.isLinked, isTrue);
      expect(result.uid, 'ABC');
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });
  });

  group('G/H Google ↔ Apple preserves UID', () {
    test('G existing Google + pending Apple preserves UID', () async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.appleProviderId,
        credential: appleCredential(),
      );
      final result = await AuthService().linkPendingCredential(
        existingUid: 'GOOGLE-UID',
        emailVerified: true,
        currentSignInProvider: AuthProviderResolver.googleProviderId,
        linkAndReturnUid: (_) async => 'GOOGLE-UID',
        ensureExistingUser: (_) async {},
      );
      expect(result.uid, 'GOOGLE-UID');
      expect(result.isSuccess, isTrue);
    });

    test('H existing Apple + pending Google preserves UID', () async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
      );
      final result = await AuthService().linkPendingCredential(
        existingUid: 'APPLE-UID',
        emailVerified: true,
        currentSignInProvider: AuthProviderResolver.appleProviderId,
        linkAndReturnUid: (_) async => 'APPLE-UID',
        ensureExistingUser: (_) async {},
      );
      expect(result.uid, 'APPLE-UID');
      expect(result.isSuccess, isTrue);
    });
  });

  group('I/J/K clear pending state', () {
    test('I successful link clears pending state', () async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
      );
      await AuthService().linkPendingCredential(
        existingUid: 'ABC',
        emailVerified: true,
        currentSignInProvider: AuthProviderResolver.passwordProviderId,
        linkAndReturnUid: (_) async => 'ABC',
        ensureExistingUser: (_) async {},
      );
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });

    testWidgets('J cancel clears pending state', (tester) async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
        emailHint: 'ada@example.com',
      );
      await tester.pumpWidget(
        app(
          home: ProviderCollisionScreen(
            attemptedProvider: AuthProviderResolver.googleProviderId,
            emailHint: 'ada@example.com',
            showAppleButton: true,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(ProviderCollisionScreen.cancelButtonKey));
      await tester.pump();
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });

    test('K logout clears pending state and does not unlink', () {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
      );
      SignInProviderMemory.remember(AuthProviderResolver.passwordProviderId);
      final src =
          File('lib/core/services/auth_service.dart').readAsStringSync();
      final signOutAt = src.indexOf('Future<void> signOut()');
      expect(signOutAt, greaterThan(0));
      final signOutBody = src.substring(signOutAt, signOutAt + 500);
      expect(signOutBody.contains('PendingProviderLinkStore.clear()'), isTrue);
      expect(signOutBody.contains('SignInProviderMemory.clear()'), isTrue);
      expect(src.contains('.unlink('), isFalse);
      expect(src.contains('revokeToken'), isFalse);
      PendingProviderLinkStore.clear();
      SignInProviderMemory.clear();
      expect(PendingProviderLinkStore.hasPending, isFalse);
      expect(SignInProviderMemory.current, isNull);
    });
  });

  group('L/M Firestore preservation', () {
    test('L/M existing progress is not reset and no second users doc', () {
      final docs = <String, Map<String, dynamic>>{
        'ABC': {
          'uid': 'ABC',
          'auth_provider': 'email',
          'test_completed': true,
          'frequency_completed': true,
          'profile_completed': true,
          'discover_eligible': true,
          'iq_score': 140,
          'eq_score': 88,
          'name': 'Ada',
        },
      };
      UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: const UserDocumentEnsureInput(
          uid: 'ABC',
          authProvider: AuthProviderResolver.google,
          email: 'ada@gmail.com',
          displayName: 'Ada Lovelace',
        ),
      );
      expect(docs.keys, ['ABC']);
      expect(docs['ABC']?['auth_provider'], 'email');
      expect(docs['ABC']?['test_completed'], isTrue);
      expect(docs['ABC']?['frequency_completed'], isTrue);
      expect(docs['ABC']?['profile_completed'], isTrue);
      expect(docs['ABC']?['discover_eligible'], isTrue);
      expect(docs['ABC']?['iq_score'], 140);
      expect(docs['ABC']?['name'], 'Ada');
    });
  });

  group('N/O link errors fail closed', () {
    test('N credential-already-in-use does not merge two UIDs', () async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
      );
      final docs = <String, Map<String, dynamic>>{
        'ABC': {'uid': 'ABC', 'iq_score': 120},
        'XYZ': {'uid': 'XYZ', 'iq_score': 90},
      };
      var ensureCalls = 0;
      final result = await AuthService().linkPendingCredential(
        existingUid: 'ABC',
        emailVerified: true,
        currentSignInProvider: AuthProviderResolver.passwordProviderId,
        linkAndReturnUid: (_) async {
          throw FirebaseAuthException(code: 'credential-already-in-use');
        },
        ensureExistingUser: (_) async {
          ensureCalls += 1;
        },
      );
      expect(result.isFailed, isTrue);
      expect(result.error?.code, 'credential-already-in-use');
      expect(ensureCalls, 0);
      expect(docs['ABC']?['iq_score'], 120);
      expect(docs['XYZ']?['iq_score'], 90);
      expect(docs.keys.toSet(), {'ABC', 'XYZ'});
      expect(PendingProviderLinkStore.hasPending, isFalse);
      expect(
        ProviderLinkFlow.mapAuthError(
          l10nEn,
          FirebaseAuthException(code: 'credential-already-in-use'),
        ).contains('credential-already-in-use'),
        isFalse,
      );
    });

    test('N UID change after link is treated as two-UID failure', () async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
      );
      final result = await AuthService().linkPendingCredential(
        existingUid: 'ABC',
        emailVerified: true,
        currentSignInProvider: AuthProviderResolver.passwordProviderId,
        linkAndReturnUid: (_) async => 'OTHER-UID',
        ensureExistingUser: (_) async {},
      );
      expect(result.isFailed, isTrue);
      expect(result.error?.code, 'credential-already-in-use');
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });

    test('O provider-already-linked is handled as success on this UID',
        () async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
      );
      final result = await AuthService().linkPendingCredential(
        existingUid: 'ABC',
        emailVerified: true,
        currentSignInProvider: AuthProviderResolver.passwordProviderId,
        linkAndReturnUid: (_) async {
          throw FirebaseAuthException(code: 'provider-already-linked');
        },
        ensureExistingUser: (_) async {},
      );
      expect(result.isAlreadyLinked, isTrue);
      expect(result.uid, 'ABC');
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });
  });

  group('P password signup collision', () {
    test('P email signup collision does not store a raw password', () async {
      var seenPassword = '';
      final service = AuthService(
        createUserWithEmailAndPassword: ({
          required email,
          required password,
        }) async {
          seenPassword = password;
          throw FirebaseAuthException(code: 'email-already-in-use');
        },
      );
      try {
        await EmailSignupFlow.register(
          authService: service,
          email: 'ada@example.com',
          password: 'raw-secret-password',
        );
      } on FirebaseAuthException catch (error) {
        expect(error.code, 'email-already-in-use');
      }
      expect(seenPassword, 'raw-secret-password');
      expect(PendingProviderLinkStore.hasPending, isFalse);
      final store = File(
        'lib/core/services/pending_provider_link.dart',
      ).readAsStringSync();
      expect(store.contains('password'), isFalse);
      expect(
        EmailSignupFlow.mapAuthError(
          l10nEn,
          FirebaseAuthException(code: 'email-already-in-use'),
        ),
        l10nEn.emailSignupErrorEmailInUse,
      );
    });
  });

  group('Q/R/S linked-account verification policy', () {
    test('Q unverified password cannot bypass verification through linking',
        () async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
      );
      var linkCalls = 0;
      final deferred = await AuthService().linkPendingCredential(
        existingUid: 'ABC',
        emailVerified: false,
        currentSignInProvider: AuthProviderResolver.passwordProviderId,
        linkAndReturnUid: (_) async {
          linkCalls += 1;
          return 'ABC';
        },
        ensureExistingUser: (_) async {},
      );
      expect(deferred.isDeferred, isTrue);
      expect(linkCalls, 0);
      expect(PendingProviderLinkStore.hasPending, isTrue);

      final afterVerify = await AuthService().linkPendingCredential(
        existingUid: 'ABC',
        emailVerified: true,
        currentSignInProvider: AuthProviderResolver.passwordProviderId,
        linkAndReturnUid: (_) async {
          linkCalls += 1;
          return 'ABC';
        },
        ensureExistingUser: (_) async {},
      );
      expect(afterVerify.isLinked, isTrue);
      expect(linkCalls, 1);
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });

    test('R linked user signed in through Google is not password-gated', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['password', 'google.com'],
          emailVerified: false,
          currentSignInProvider: AuthProviderResolver.googleProviderId,
        ),
        isFalse,
      );
    });

    test('S linked user signed in through Apple is not password-gated', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['password', 'apple.com'],
          emailVerified: false,
          currentSignInProvider: AuthProviderResolver.appleProviderId,
        ),
        isFalse,
      );
    });

    test('unverified password current session stays gated even if linked', () {
      expect(
        EmailVerificationPolicy.requiresEmailVerification(
          providerIds: const ['password', 'google.com'],
          emailVerified: false,
          currentSignInProvider: AuthProviderResolver.passwordProviderId,
        ),
        isTrue,
      );
    });
  });

  group('T Phase 4 current-provider security', () {
    test('T backend still gates only current password + unverified claim', () {
      final src =
          File('functions/src/verified_product_auth.js').readAsStringSync();
      expect(src.contains('sign_in_provider'), isTrue);
      expect(src.contains('PASSWORD_PROVIDER'), isTrue);
      expect(src.contains('email_verified'), isTrue);
      expect(src.contains('providerData'), isFalse);
    });
  });

  group('U/V architecture', () {
    test('U no nested AuthWrapper is introduced', () {
      for (final path in [
        'lib/features/auth/screens/provider_collision_screen.dart',
        'lib/features/auth/provider_link_flow.dart',
        'lib/features/auth/screens/login_screen.dart',
        'lib/core/navigation/auth_navigation.dart',
        'lib/core/services/pending_provider_link.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains('AuthWrapper('), isFalse, reason: path);
      }
      expect(
        File('lib/main.dart').readAsStringSync().contains('AuthWrapper()'),
        isTrue,
      );
    });

    test('V no automatic account-merge code', () {
      for (final path in [
        'lib/core/services/pending_provider_link.dart',
        'lib/features/auth/provider_link_flow.dart',
        'lib/core/services/auth_service.dart',
        'lib/features/auth/screens/provider_collision_screen.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains('fetchSignInMethodsForEmail'), isFalse);
        expect(src.contains('mergeUsers'), isFalse);
        expect(src.contains('copyUserDocument'), isFalse);
        expect(src.contains('.unlink('), isFalse);
      }
    });
  });

  group('collision UX', () {
    testWidgets('collision screen copy is localized and has cancel',
        (tester) async {
      await tester.pumpWidget(
        app(
          locale: const Locale('tr'),
          home: const ProviderCollisionScreen(
            attemptedProvider: AuthProviderResolver.googleProviderId,
            showAppleButton: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.text(l10nTr.providerCollisionBody), findsOneWidget);
      expect(find.text(l10nTr.providerCollisionCancel), findsOneWidget);
      expect(
          find.byKey(ProviderCollisionScreen.emailButtonKey), findsOneWidget);
      expect(find.byKey(ProviderCollisionScreen.googleButtonKey), findsNothing);
      expect(
          find.byKey(ProviderCollisionScreen.appleButtonKey), findsOneWidget);
    });

    testWidgets('email choice opens the existing LoginScreen', (tester) async {
      await tester.pumpWidget(
        app(
          home: const ProviderCollisionScreen(
            attemptedProvider: AuthProviderResolver.googleProviderId,
            emailHint: 'ada@example.com',
            showAppleButton: false,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(ProviderCollisionScreen.emailButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Welcome Google collision opens the recovery screen',
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
    });
  });

  group('login + verification seams', () {
    testWidgets('password login invokes pending link on the existing UID',
        (tester) async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
      );
      var signInCalls = 0;
      var linkCalls = 0;
      await tester.pumpWidget(
        app(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  key: const Key('open-login'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LoginScreen(
                          signIn: ({required email, required password}) async {
                            signInCalls += 1;
                            expect(password, isNotEmpty);
                          },
                          completePendingLink: () async {
                            linkCalls += 1;
                            return AuthService().linkPendingCredential(
                              existingUid: 'ABC',
                              emailVerified: true,
                              currentSignInProvider:
                                  AuthProviderResolver.passwordProviderId,
                              linkAndReturnUid: (_) async => 'ABC',
                              ensureExistingUser: (_) async {},
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('open login'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-login')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(
        find.byKey(LoginScreen.emailFieldKey),
        'ada@example.com',
      );
      await tester.enterText(
        find.byKey(LoginScreen.passwordFieldKey),
        'secret1',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(LoginScreen.submitKey));
      await tester.tap(find.byKey(LoginScreen.submitKey));
      await tester.pump();
      expect(signInCalls, 1);
      expect(linkCalls, 1);
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });

    testWidgets('verification success can complete a deferred link',
        (tester) async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: googleCredential(),
      );
      var linkCalls = 0;
      await tester.pumpWidget(
        app(
          home: EmailVerificationScreen(
            email: 'ada@example.com',
            checkVerified: () async => true,
            refreshIdToken: () async {},
            completePendingLink: () async {
              linkCalls += 1;
              return AuthService().linkPendingCredential(
                existingUid: 'ABC',
                emailVerified: true,
                currentSignInProvider: AuthProviderResolver.passwordProviderId,
                linkAndReturnUid: (_) async => 'ABC',
                ensureExistingUser: (_) async {},
              );
            },
            onVerified: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(EmailVerificationScreen.checkKey));
      await tester.pump();
      expect(linkCalls, 1);
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });
  });

  group('error mapping', () {
    test('link errors stay localized without raw Firebase codes', () {
      const codes = [
        'provider-already-linked',
        'credential-already-in-use',
        'email-already-in-use',
        'invalid-credential',
        'requires-recent-login',
        'network-request-failed',
        'too-many-requests',
        'user-disabled',
        'operation-not-allowed',
      ];
      for (final code in codes) {
        final message = ProviderLinkFlow.mapAuthError(
          l10nEn,
          FirebaseAuthException(code: code),
        );
        expect(message.contains(code), isFalse, reason: code);
        expect(message, isNotEmpty);
      }
    });
  });

  test('auth_provider remains a bootstrap label after linking docs', () {
    final resolver = File(
      'lib/core/services/auth_provider_resolver.dart',
    ).readAsStringSync();
    expect(resolver.contains('bootstrap'), isTrue);
    expect(
      AuthProviderResolver.resolve(
        providerIds: const ['password', 'google.com'],
      ),
      AuthProviderResolver.email,
    );
  });

  testWidgets('U collision recovery does not push a second AuthWrapper',
      (tester) async {
    await tester.pumpWidget(
      app(
        home: Builder(
          builder: (context) {
            return Scaffold(
              key: const Key('auth-wrapper-root'),
              body: TextButton(
                key: const Key('open-collision'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProviderCollisionScreen(
                        attemptedProvider:
                            AuthProviderResolver.googleProviderId,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-collision')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(ProviderCollisionScreen), findsOneWidget);
    expect(find.byType(AuthWrapper), findsNothing);
    expect(find.byKey(const Key('auth-wrapper-root')), findsOneWidget);
  });
}
