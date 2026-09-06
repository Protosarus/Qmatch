import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/services/auth_provider_resolver.dart';
import 'package:qmatch/core/services/pending_provider_link.dart';
import 'package:qmatch/features/auth/apple_sign_in_flow.dart';
import 'package:qmatch/features/settings/screens/account_deletion_request_screen.dart';
import 'package:qmatch/features/settings/services/account_deletion_coordinator.dart';
import 'package:qmatch/features/settings/services/account_deletion_request_service.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';
import 'package:qmatch/l10n/app_localizations_tr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(PendingProviderLinkStore.clear);
  tearDown(PendingProviderLinkStore.clear);

  final l10nEn = AppLocalizationsEn();
  final l10nTr = AppLocalizationsTr();

  void configureView(WidgetTester tester) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 7200);
    addTearDown(tester.view.reset);
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

  Future<void> completeConfirmation(WidgetTester tester) async {
    await tester.ensureVisible(
      find.byKey(const Key('qmatch-delete-ack-irreversible')),
    );
    await tester.tap(find.byKey(const Key('qmatch-delete-ack-irreversible')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('qmatch-delete-ack-timeline')),
    );
    await tester.tap(find.byKey(const Key('qmatch-delete-ack-timeline')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('qmatch-delete-confirm-field')),
    );
    await tester.enterText(
      find.byKey(const Key('qmatch-delete-confirm-field')),
      AccountDeletionRequestService.confirmationToken,
    );
    await tester.pump();
  }

  AccountDeletionCoordinator coordinator({
    AccountDeletionIdentity? identity,
    Future<Map<String, dynamic>> Function(Map<String, dynamic> data)?
        callDelete,
    Future<void> Function(String authorizationCode)? revokeApple,
    Future<AppleAuthorizationResult?> Function(String hashedNonce)?
        requestApple,
    Future<String> Function(AuthCredential credential)? resolveReauthUid,
    Future<({String? idToken, String? accessToken})?> Function()? pickGoogle,
    String Function()? generateAppleNonce,
    Future<void> Function()? signOut,
  }) {
    return AccountDeletionCoordinator(
      debugIdentity: identity ??
          const AccountDeletionIdentity(
            uid: 'self',
            email: 'self@qmatch.test',
            passwordLinked: true,
          ),
      callDelete: callDelete ?? (_) async => const {},
      revokeApple: revokeApple,
      requestAppleAuthorization: requestApple,
      resolveReauthUid: resolveReauthUid ?? (_) async => 'self',
      pickGoogleAuthTokens: pickGoogle,
      generateAppleNonce: generateAppleNonce,
      signOut: signOut ?? () async {},
    );
  }

  group('copy A confirmation', () {
    test('TR/EN confirmation is irreversible and non-manipulative', () {
      expect(
        l10nEn.accountDeletionWarningTitle,
        'Are you sure you want to permanently delete your account?',
      );
      expect(
        l10nTr.accountDeletionWarningTitle,
        'Hesabını kalıcı olarak silmek istediğine emin misin?',
      );
      expect(l10nEn.accountDeletionIntro.contains('cannot be undone'), isTrue);
      expect(l10nTr.accountDeletionIntro.contains('geri alınamaz'), isTrue);
      expect(l10nEn.helpFaqDeleteAccountA.contains('30 days'), isFalse);
      expect(l10nTr.helpFaqDeleteAccountA.contains('30 gün'), isFalse);
    });
  });

  group('UI A/B/P/Q', () {
    testWidgets('A delete CTA opens confirmation', (tester) async {
      configureView(tester);
      await tester.pumpWidget(
        app(
          home: AccountDeletionRequestScreen(
            coordinator: coordinator(),
          ),
        ),
      );
      expect(find.text(l10nEn.accountDeletionWarningTitle), findsOneWidget);
      expect(find.byKey(const Key('qmatch-delete-submit')), findsOneWidget);
      expect(
          find.byKey(const Key('qmatch-delete-confirm-field')), findsOneWidget);
    });

    testWidgets('B cancel / back performs no deletion', (tester) async {
      configureView(tester);
      var deleted = false;
      await tester.pumpWidget(
        app(
          home: AccountDeletionRequestScreen(
            coordinator: coordinator(
              callDelete: (_) async {
                deleted = true;
                return const {};
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('qmatch-delete-back')));
      await tester.pump();
      expect(deleted, isFalse);
    });

    test('P success pops to the first route; signed-out session is Welcome',
        () {
      final screen = File(
        'lib/features/settings/screens/account_deletion_request_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('rootNavigator: true'), isTrue);
      expect(
        screen.contains('popUntil((route) => route.isFirst)'),
        isTrue,
      );
      final wrapper =
          File('lib/core/navigation/auth_wrapper.dart').readAsStringSync();
      expect(wrapper.contains('WelcomeScreen'), isTrue);
    });

    testWidgets('Q failures use inline copy, not SnackBar', (tester) async {
      configureView(tester);
      await tester.pumpWidget(
        app(
          home: AccountDeletionRequestScreen(
            debugAppleLinked: true,
            coordinator: coordinator(
              identity: const AccountDeletionIdentity(
                uid: 'self',
                appleLinked: true,
              ),
              requestApple: (_) async => const AppleAuthorizationResult(
                identityToken: 'id',
                authorizationCode: 'code',
              ),
              revokeApple: (_) async {
                throw Exception('revoke-failed');
              },
            ),
          ),
        ),
      );
      await completeConfirmation(tester);
      await tester.tap(find.byKey(const Key('qmatch-delete-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byKey(const Key('qmatch-delete-error')), findsOneWidget);
      expect(find.text(l10nEn.accountDeletionErrorAppleRevoke), findsOneWidget);
      expect(find.textContaining('requires-recent-login'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });
  });

  group('Apple C–J', () {
    test(
        'C/D/E/F Apple-linked uses fresh nonce, in-memory code, revoke before delete',
        () async {
      final events = <String>[];
      String? hashedSeen;
      String? codeSeen;
      Map<String, dynamic>? payload;
      final raw = AppleSignInFlow.generateRawNonce();

      final result = await coordinator(
        identity: const AccountDeletionIdentity(
          uid: 'self',
          appleLinked: true,
          googleLinked: true,
        ),
        generateAppleNonce: () => raw,
        requestApple: (hashedNonce) async {
          hashedSeen = hashedNonce;
          events.add('apple-auth');
          return const AppleAuthorizationResult(
            identityToken: 'fresh-id-token',
            authorizationCode: 'fresh-auth-code',
          );
        },
        resolveReauthUid: (_) async {
          events.add('reauth');
          return 'self';
        },
        revokeApple: (code) async {
          codeSeen = code;
          events.add('revoke');
        },
        callDelete: (data) async {
          payload = data;
          events.add('delete');
          return const {};
        },
      ).deleteAccount();

      expect(result.isSuccess, isTrue);
      expect(hashedSeen, AppleSignInFlow.sha256Of(raw));
      expect(codeSeen, 'fresh-auth-code');
      expect(payload, {'apple_revocation_completed': true});
      expect(events, ['apple-auth', 'reauth', 'revoke', 'delete']);
    });

    test('G Apple cancel leaves the account intact', () async {
      var deleted = false;
      final result = await coordinator(
        identity: const AccountDeletionIdentity(uid: 'self', appleLinked: true),
        requestApple: (_) async => null,
        callDelete: (_) async {
          deleted = true;
          return const {};
        },
      ).deleteAccount();
      expect(result.isCancelled, isTrue);
      expect(deleted, isFalse);
    });

    test('H Apple revoke failure is retryable and does not delete', () async {
      var deleted = false;
      final first = await coordinator(
        identity: const AccountDeletionIdentity(uid: 'self', appleLinked: true),
        requestApple: (_) async => const AppleAuthorizationResult(
          identityToken: 'id',
          authorizationCode: 'code',
        ),
        revokeApple: (_) async {
          throw Exception('network');
        },
        callDelete: (_) async {
          deleted = true;
          return const {};
        },
      ).deleteAccount();
      expect(first.stage, AccountDeletionStage.appleRevokeFailed);
      expect(deleted, isFalse);

      final second = await coordinator(
        identity: const AccountDeletionIdentity(uid: 'self', appleLinked: true),
        requestApple: (_) async => const AppleAuthorizationResult(
          identityToken: 'id',
          authorizationCode: 'code-2',
        ),
        revokeApple: (_) async {},
        callDelete: (_) async => const {},
      ).deleteAccount();
      expect(second.isSuccess, isTrue);
    });

    test('I linked Apple is detected even when current login is Google', () {
      final resolver = File('lib/core/services/auth_provider_resolver.dart')
          .readAsStringSync();
      expect(resolver.contains('apple.com'), isTrue);
      expect(resolver.contains('hasAppleLinked'), isTrue);
      expect(resolver.contains('providerData'), isTrue);
      expect(
        resolver.contains('Linked Apple is read from Firebase providerData'),
        isTrue,
      );

      final coord = coordinator(
        identity: const AccountDeletionIdentity(
          uid: 'self',
          appleLinked: true,
          googleLinked: true,
        ),
      );
      expect(coord.isAppleLinked(), isTrue);
    });

    test('J UID mismatch fails closed', () async {
      var deleted = false;
      var revoked = false;
      final result = await coordinator(
        identity: const AccountDeletionIdentity(uid: 'self', appleLinked: true),
        requestApple: (_) async => const AppleAuthorizationResult(
          identityToken: 'id',
          authorizationCode: 'code',
        ),
        resolveReauthUid: (_) async => 'other-uid',
        revokeApple: (_) async {
          revoked = true;
        },
        callDelete: (_) async {
          deleted = true;
          return const {};
        },
      ).deleteAccount();
      expect(result.stage, AccountDeletionStage.uidMismatch);
      expect(revoked, isFalse);
      expect(deleted, isFalse);
    });
  });

  group('reauth K/L', () {
    test('K password/Google/phone reauth preserve UID', () async {
      AuthCredential? passwordCred;
      final password = await coordinator(
        identity: const AccountDeletionIdentity(
          uid: 'self',
          email: 'self@qmatch.test',
          passwordLinked: true,
        ),
        resolveReauthUid: (credential) async {
          passwordCred = credential;
          return 'self';
        },
      ).deleteAccount(password: 'secret-pass');
      expect(password.isSuccess, isTrue);
      expect(passwordCred, isA<EmailAuthCredential>());

      AuthCredential? googleCred;
      final google = await coordinator(
        identity: const AccountDeletionIdentity(
          uid: 'self',
          googleLinked: true,
        ),
        pickGoogle: () async => (
          idToken: 'google-id',
          accessToken: 'google-access',
        ),
        resolveReauthUid: (credential) async {
          googleCred = credential;
          return 'self';
        },
      ).deleteAccount();
      expect(google.isSuccess, isTrue);
      expect(googleCred, isA<OAuthCredential>());

      AuthCredential? phoneCred;
      final phone = await coordinator(
        identity: const AccountDeletionIdentity(
          uid: 'self',
          phoneLinked: true,
          phoneNumber: '+15555550100',
        ),
        resolveReauthUid: (credential) async {
          phoneCred = credential;
          return 'self';
        },
      ).deleteAccount(
        phoneCredentialVerificationId: 'ver-id',
        phoneSmsCode: '123456',
      );
      expect(phone.isSuccess, isTrue);
      expect(phoneCred, isA<PhoneAuthCredential>());

      final phoneSession = await coordinator(
        identity: const AccountDeletionIdentity(
          uid: 'self',
          phoneLinked: true,
          phoneNumber: '+15555550100',
        ),
      ).deleteAccount();
      expect(phoneSession.isSuccess, isTrue);
    });

    test('L requires-recent-login is mapped, never raw', () async {
      final result = await coordinator(
        identity: const AccountDeletionIdentity(
          uid: 'self',
          email: 'self@qmatch.test',
          passwordLinked: true,
        ),
        resolveReauthUid: (_) async {
          throw FirebaseAuthException(code: 'requires-recent-login');
        },
      ).deleteAccount(password: 'secret');
      expect(result.stage, AccountDeletionStage.needsPassword);
      expect(result.errorCode, 'requires-recent-login');
    });
  });

  group('session M/N/O', () {
    test('M successful deletion clears pending provider-link memory', () async {
      PendingProviderLinkStore.capture(
        attemptedProvider: AuthProviderResolver.googleProviderId,
        credential: GoogleAuthProvider.credential(idToken: 'pending-id'),
        emailHint: 'link@qmatch.test',
      );
      expect(PendingProviderLinkStore.hasPending, isTrue);
      final result = await coordinator().deleteAccount(password: 'secret');
      expect(result.isSuccess, isTrue);
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });

    test('N logout remains non-destructive', () {
      final auth =
          File('lib/core/services/auth_service.dart').readAsStringSync();
      expect(auth.contains('revokeTokenWithAuthorizationCode'), isFalse);
      expect(auth.contains('deleteQMatchAccount'), isFalse);
      expect(auth.contains('Future<void> signOut()'), isTrue);
      expect(auth.contains('PendingProviderLinkStore.clear()'), isTrue);

      final settings =
          File('lib/features/settings/screens/settings_screen.dart')
              .readAsStringSync();
      expect(settings.contains('_confirmLogout'), isTrue);
      expect(settings.contains('_openDeleteAccount'), isTrue);
      expect(
        settings.contains('AccountDeletionRequestScreen'),
        isTrue,
      );
    });

    test('O no token/code/.p8 persistence', () {
      final files = [
        'lib/features/settings/services/account_deletion_coordinator.dart',
        'lib/features/auth/apple_sign_in_flow.dart',
        'lib/core/services/auth_service.dart',
        'lib/core/services/pending_provider_link.dart',
      ];
      for (final path in files) {
        final src = File(path).readAsStringSync();
        expect(src.contains('.p8'), isFalse, reason: path);
        expect(
          RegExp(r'SharedPreferences\.(get|set|instance)').hasMatch(src),
          isFalse,
          reason: path,
        );
        expect(
            src.contains('authorizationCode'),
            path.contains('apple') ||
                    path.contains('account_deletion_coordinator')
                ? isTrue
                : anything);
      }
      final coordinatorSrc = File(
        'lib/features/settings/services/account_deletion_coordinator.dart',
      ).readAsStringSync();
      expect(coordinatorSrc.contains('in memory only'), isTrue);
      expect(
        coordinatorSrc.contains('revokeTokenWithAuthorizationCode'),
        isTrue,
      );

      for (final root in ['lib', 'functions', 'ios', 'android', 'test']) {
        final dir = Directory(root);
        if (!dir.existsSync()) continue;
        final p8Files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.p8'))
            .toList();
        expect(p8Files, isEmpty, reason: root);
      }
    });
  });

  group('SDK + settings discoverability', () {
    test('installed firebase_auth documents revokeTokenWithAuthorizationCode',
        () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('firebase_auth: ^5.7.0'), isTrue);
      final coordinatorSrc = File(
        'lib/features/settings/services/account_deletion_coordinator.dart',
      ).readAsStringSync();
      expect(
        coordinatorSrc.contains('_auth.revokeTokenWithAuthorizationCode(code)'),
        isTrue,
      );
    });

    testWidgets('Apple-linked settings screen explains the extra Apple step',
        (tester) async {
      configureView(tester);
      await tester.pumpWidget(
        app(
          home: AccountDeletionRequestScreen(
            debugAppleLinked: true,
            coordinator: coordinator(
              identity: const AccountDeletionIdentity(
                uid: 'self',
                appleLinked: true,
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('qmatch-delete-apple-hint')), findsOneWidget);
      expect(find.text(l10nEn.accountDeletionAppleReauthHint), findsOneWidget);
    });
  });
}
