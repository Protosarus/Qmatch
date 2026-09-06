import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
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
    bool signedOut = false,
    Future<Map<String, dynamic>> Function(Map<String, dynamic> data)?
        callDelete,
    Future<void> Function(String authorizationCode)? revokeApple,
    Future<AppleAuthorizationResult?> Function(String hashedNonce)?
        requestApple,
    Future<String> Function(AuthCredential credential)? resolveReauthUid,
    String Function()? generateAppleNonce,
    Future<void> Function()? signOut,
  }) {
    return AccountDeletionCoordinator(
      debugIdentity: identity ??
          (signedOut ? null : const AccountDeletionIdentity(uid: 'self')),
      debugSignedOut: signedOut,
      callDelete: callDelete ?? (_) async => const {},
      revokeApple: revokeApple,
      requestAppleAuthorization: requestApple,
      resolveReauthUid: resolveReauthUid ?? (_) async => 'self',
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
      expect(
        l10nEn.accountDeletionMayRetainBody.contains('Shared messages'),
        isTrue,
      );
      expect(
        l10nTr.accountDeletionMayRetainBody.contains('paylaşılan mesajlar'),
        isTrue,
      );
      expect(
        l10nEn.accountDeletionErrorGeneric.contains('connection'),
        isFalse,
      );
      expect(
        l10nTr.accountDeletionErrorGeneric.contains('Bağlantını'),
        isFalse,
      );
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

  group('signed-in delete without extra auth', () {
    test('1 password session deletes without a password prompt', () async {
      var deleted = false;
      var reauthCalls = 0;
      final result = await coordinator(
        identity: const AccountDeletionIdentity(uid: 'self'),
        resolveReauthUid: (_) async {
          reauthCalls += 1;
          return 'self';
        },
        callDelete: (_) async {
          deleted = true;
          return const {};
        },
      ).deleteAccount();
      expect(result.isSuccess, isTrue);
      expect(deleted, isTrue);
      expect(reauthCalls, 0);
    });

    test('2 Google session deletes without a Google chooser', () async {
      var deleted = false;
      var reauthCalls = 0;
      final src = File(
        'lib/features/settings/services/account_deletion_coordinator.dart',
      ).readAsStringSync();
      expect(src.contains('_reauthGoogle'), isFalse);
      expect(src.contains('pickGoogleAuthTokens'), isFalse);
      expect(src.contains('GoogleSignInFlow'), isFalse);

      final result = await coordinator(
        identity: const AccountDeletionIdentity(uid: 'self'),
        resolveReauthUid: (_) async {
          reauthCalls += 1;
          return 'self';
        },
        callDelete: (_) async {
          deleted = true;
          return const {};
        },
      ).deleteAccount();
      expect(result.isSuccess, isTrue);
      expect(deleted, isTrue);
      expect(reauthCalls, 0);
    });

    test('3 phone session deletes without OTP', () async {
      var deleted = false;
      final result = await coordinator(
        identity: const AccountDeletionIdentity(uid: 'self'),
        callDelete: (_) async {
          deleted = true;
          return const {};
        },
      ).deleteAccount();
      expect(result.isSuccess, isTrue);
      expect(deleted, isTrue);
      final src = File(
        'lib/features/settings/services/account_deletion_coordinator.dart',
      ).readAsStringSync();
      expect(src.contains('PhoneAuthProvider'), isFalse);
      expect(src.contains('phoneSmsCode'), isFalse);
    });

    test('4 Apple-linked still requires fresh Apple authorization', () async {
      var deleted = false;
      var appleCalls = 0;
      final result = await coordinator(
        identity: const AccountDeletionIdentity(uid: 'self', appleLinked: true),
        requestApple: (_) async {
          appleCalls += 1;
          return const AppleAuthorizationResult(
            identityToken: 'id',
            authorizationCode: 'code',
          );
        },
        revokeApple: (_) async {},
        callDelete: (_) async {
          deleted = true;
          return const {};
        },
      ).deleteAccount();
      expect(result.isSuccess, isTrue);
      expect(appleCalls, 1);
      expect(deleted, isTrue);
    });

    test('5 Google-current + Apple-linked still revokes Apple first', () async {
      final events = <String>[];
      final result = await coordinator(
        identity: const AccountDeletionIdentity(uid: 'self', appleLinked: true),
        requestApple: (_) async {
          events.add('apple-auth');
          return const AppleAuthorizationResult(
            identityToken: 'id',
            authorizationCode: 'code',
          );
        },
        resolveReauthUid: (_) async {
          events.add('apple-uid');
          return 'self';
        },
        revokeApple: (_) async => events.add('revoke'),
        callDelete: (_) async {
          events.add('delete');
          return const {};
        },
      ).deleteAccount();
      expect(result.isSuccess, isTrue);
      expect(events, ['apple-auth', 'apple-uid', 'revoke', 'delete']);
      expect(
        File('lib/core/services/auth_provider_resolver.dart')
            .readAsStringSync()
            .contains('hasAppleLinked'),
        isTrue,
      );
    });

    testWidgets('password/Google/phone UI never asks for extra credentials',
        (tester) async {
      configureView(tester);
      var deleted = false;
      await tester.pumpWidget(
        app(
          home: AccountDeletionRequestScreen(
            coordinator: coordinator(
              identity: const AccountDeletionIdentity(uid: 'self'),
              callDelete: (_) async {
                deleted = true;
                return const {};
              },
            ),
          ),
        ),
      );
      expect(
          find.byKey(const Key('qmatch-delete-password-field')), findsNothing);
      expect(find.byKey(const Key('qmatch-delete-apple-hint')), findsNothing);
      await completeConfirmation(tester);
      await tester.tap(find.byKey(const Key('qmatch-delete-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(deleted, isTrue);
      expect(
          find.byKey(const Key('qmatch-delete-password-field')), findsNothing);
    });
  });

  group('failure + auth authority', () {
    test('8 unauthenticated deletion is rejected', () async {
      var deleted = false;
      final result = await coordinator(
        signedOut: true,
        callDelete: (_) async {
          deleted = true;
          return const {};
        },
      ).deleteAccount();
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'not_signed_in');
      expect(deleted, isFalse);
    });

    test('9 backend deletes only request.auth.uid', () {
      final policy =
          File('functions/src/delete_qmatch_account.js').readAsStringSync();
      expect(
          policy.contains('Client-supplied targetUid is never used'), isTrue);
      expect(policy.contains('Only request.auth.uid is deleted'), isTrue);
      expect(policy.contains('request.auth && request.auth.uid'), isTrue);
      expect(policy.contains('resolveDeletionUid'), isTrue);
      final callable = File('functions/src/delete_qmatch_account_callable.js')
          .readAsStringSync();
      expect(callable.contains('resolveDeletionUid(request)'), isTrue);
      expect(callable.contains('Never uses client targetUid'), isTrue);
    });

    test('L Apple requires-recent-login maps to needsApple, never raw',
        () async {
      var deleted = false;
      final result = await coordinator(
        identity: const AccountDeletionIdentity(uid: 'self', appleLinked: true),
        requestApple: (_) async => const AppleAuthorizationResult(
          identityToken: 'id',
          authorizationCode: 'code',
        ),
        resolveReauthUid: (_) async {
          throw FirebaseAuthException(code: 'requires-recent-login');
        },
        callDelete: (_) async {
          deleted = true;
          return const {};
        },
      ).deleteAccount();
      expect(result.stage, AccountDeletionStage.needsApple);
      expect(result.errorCode, 'requires-recent-login');
      expect(deleted, isFalse);
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
      final result = await coordinator().deleteAccount();
      expect(result.isSuccess, isTrue);
      expect(PendingProviderLinkStore.hasPending, isFalse);
    });

    test('11 deletion does not change provider linking or merge', () {
      final coord = File(
        'lib/features/settings/services/account_deletion_coordinator.dart',
      ).readAsStringSync();
      expect(coord.contains('linkPendingCredential'), isFalse);
      expect(coord.contains('fetchSignInMethodsForEmail'), isFalse);
      expect(coord.contains('linkWithCredential'), isFalse);
      final screen = File(
        'lib/features/settings/screens/account_deletion_request_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('linkPendingCredential'), isFalse);
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

    test('Settings and Discover no longer render pending-deletion UX', () {
      final settings = File(
        'lib/features/settings/screens/settings_screen.dart',
      ).readAsStringSync();
      expect(settings.contains('isAccountDeletionPending'), isFalse);
      expect(settings.contains('_deletionPending'), isFalse);
      expect(settings.contains('_loadDeletionPending'), isFalse);
      expect(settings.contains('qmatch-settings-deletion-banner'), isFalse);
      expect(settings.contains('settingsDeleteAccountPending'), isFalse);

      final discover = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(discover.contains('isAccountDeletionPending'), isFalse);
      expect(discover.contains('_deletionPending'), isFalse);
      expect(discover.contains('_loadDeletionPending'), isFalse);
      expect(discover.contains('_buildDeletionPendingBanner'), isFalse);
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

  group('deletion error mapping', () {
    test('classifies session, network, Apple, server, and unknown separately',
        () {
      expect(
        classifyAccountDeletionError(
          const AccountDeletionResult(
            stage: AccountDeletionStage.failed,
            errorCode: 'unauthenticated',
          ),
        ),
        AccountDeletionUserError.sessionExpired,
      );
      expect(
        classifyAccountDeletionError(
          const AccountDeletionResult(
            stage: AccountDeletionStage.failed,
            errorCode: 'not_signed_in',
          ),
        ),
        AccountDeletionUserError.sessionExpired,
      );
      expect(
        classifyAccountDeletionError(
          const AccountDeletionResult(
            stage: AccountDeletionStage.failed,
            errorCode: 'unavailable',
          ),
        ),
        AccountDeletionUserError.network,
      );
      expect(
        classifyAccountDeletionError(
          const AccountDeletionResult(
            stage: AccountDeletionStage.failed,
            errorCode: 'deadline-exceeded',
          ),
        ),
        AccountDeletionUserError.network,
      );
      expect(
        classifyAccountDeletionError(
          const AccountDeletionResult(
            stage: AccountDeletionStage.failed,
            errorCode: 'network-request-failed',
          ),
        ),
        AccountDeletionUserError.network,
      );
      expect(
        classifyAccountDeletionError(
          const AccountDeletionResult(
            stage: AccountDeletionStage.needsApple,
            errorCode: 'failed-precondition',
          ),
        ),
        AccountDeletionUserError.appleRequired,
      );
      expect(
        classifyAccountDeletionError(
          const AccountDeletionResult(
            stage: AccountDeletionStage.appleRevokeFailed,
          ),
        ),
        AccountDeletionUserError.appleRevoke,
      );
      expect(
        classifyAccountDeletionError(
          const AccountDeletionResult(
            stage: AccountDeletionStage.failed,
            errorCode: 'internal',
          ),
        ),
        AccountDeletionUserError.server,
      );
      expect(
        classifyAccountDeletionError(
          const AccountDeletionResult(
            stage: AccountDeletionStage.failed,
            errorCode: 'unknown',
          ),
        ),
        AccountDeletionUserError.retry,
      );
    });

    testWidgets('unauthenticated shows session copy, not a network problem',
        (tester) async {
      configureView(tester);
      await tester.pumpWidget(
        app(
          home: AccountDeletionRequestScreen(
            coordinator: coordinator(
              callDelete: (_) async {
                throw FirebaseFunctionsException(
                  message: 'auth',
                  code: 'unauthenticated',
                );
              },
            ),
          ),
        ),
      );
      await completeConfirmation(tester);
      await tester.tap(find.byKey(const Key('qmatch-delete-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(l10nEn.accountDeletionErrorSessionExpired), findsOneWidget);
      expect(find.text(l10nEn.accountDeletionErrorNetwork), findsNothing);
      expect(find.textContaining('unauthenticated'), findsNothing);
    });

    testWidgets('unavailable shows connectivity copy', (tester) async {
      configureView(tester);
      await tester.pumpWidget(
        app(
          home: AccountDeletionRequestScreen(
            coordinator: coordinator(
              callDelete: (_) async {
                throw FirebaseFunctionsException(
                  message: 'down',
                  code: 'unavailable',
                );
              },
            ),
          ),
        ),
      );
      await completeConfirmation(tester);
      await tester.tap(find.byKey(const Key('qmatch-delete-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(l10nEn.accountDeletionErrorNetwork), findsOneWidget);
      expect(find.textContaining('unavailable'), findsNothing);
    });

    testWidgets('internal shows server copy, unknown shows generic retry',
        (tester) async {
      configureView(tester);
      await tester.pumpWidget(
        app(
          home: AccountDeletionRequestScreen(
            coordinator: coordinator(
              callDelete: (_) async {
                throw FirebaseFunctionsException(
                  message: 'boom',
                  code: 'internal',
                );
              },
            ),
          ),
        ),
      );
      await completeConfirmation(tester);
      await tester.tap(find.byKey(const Key('qmatch-delete-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(l10nEn.accountDeletionErrorServer), findsOneWidget);
      expect(find.text(l10nEn.accountDeletionErrorGeneric), findsNothing);
      expect(find.textContaining('internal'), findsNothing);
    });
  });
}
