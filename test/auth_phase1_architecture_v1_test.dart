import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/navigation/auth_navigation.dart';
import 'package:qmatch/core/navigation/auth_wrapper.dart';
import 'package:qmatch/core/services/auth_provider_resolver.dart';
import 'package:qmatch/core/services/auth_service.dart';
import 'package:qmatch/core/services/user_document_ensure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('post-auth navigation', () {
    testWidgets(
      'email login success uses shared helper and cannot nest AuthWrapper',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  key: const Key('auth-wrapper-root'),
                  body: TextButton(
                    key: const Key('open-login'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (loginContext) => Scaffold(
                            key: const Key('login-route'),
                            body: TextButton(
                              key: const Key('finish-email-auth'),
                              onPressed: () =>
                                  AuthNavigation.completeAuthentication(
                                loginContext,
                              ),
                              child: const Text('finish email'),
                            ),
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
        expect(find.byKey(const Key('login-route')), findsOneWidget);
        expect(find.byType(AuthWrapper), findsNothing);

        await tester.tap(find.byKey(const Key('finish-email-auth')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byKey(const Key('login-route')), findsNothing);
        expect(find.byKey(const Key('auth-wrapper-root')), findsOneWidget);
        expect(find.byType(AuthWrapper), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'phone auth success uses the same shared post-auth routing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  key: const Key('auth-wrapper-root'),
                  body: TextButton(
                    key: const Key('open-phone'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (otpContext) => Scaffold(
                            key: const Key('otp-route'),
                            body: TextButton(
                              key: const Key('finish-phone-auth'),
                              onPressed: () =>
                                  AuthNavigation.completeAuthentication(
                                otpContext,
                              ),
                              child: const Text('finish phone'),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('open phone'),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('open-phone')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byKey(const Key('otp-route')), findsOneWidget);

        await tester.tap(find.byKey(const Key('finish-phone-auth')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byKey(const Key('otp-route')), findsNothing);
        expect(find.byKey(const Key('auth-wrapper-root')), findsOneWidget);
        expect(find.byType(AuthWrapper), findsNothing);
      },
    );

    test(
        'login and phone screens share AuthNavigation and do not remount wrapper',
        () {
      final login = File(
        'lib/features/auth/screens/login_screen.dart',
      ).readAsStringSync();
      final phone = File(
        'lib/features/auth/screens/phone_signup_screen.dart',
      ).readAsStringSync();
      for (final src in [login, phone]) {
        expect(src.contains('AuthNavigation.completeAuthentication'), isTrue);
        expect(src.contains('AuthWrapper('), isFalse);
        expect(src.contains('pushReplacement'), isFalse);
        expect(src.contains('pushAndRemoveUntil'), isFalse);
      }
    });
  });

  group('provider resolution', () {
    test('phone → phone', () {
      expect(
        AuthProviderResolver.resolve(
          providerIds: const ['phone'],
        ),
        AuthProviderResolver.phone,
      );
    });

    test('password → email', () {
      expect(
        AuthProviderResolver.resolve(
          providerIds: const ['password'],
        ),
        AuthProviderResolver.email,
      );
    });

    test('google.com → google', () {
      expect(
        AuthProviderResolver.resolve(
          providerIds: const ['google.com'],
          phoneNumber: '+15555550100',
        ),
        AuthProviderResolver.google,
      );
    });

    test('apple.com → apple', () {
      expect(
        AuthProviderResolver.resolve(
          providerIds: const ['apple.com'],
        ),
        AuthProviderResolver.apple,
      );
    });

    test('firebase provider id is ignored', () {
      expect(
        AuthProviderResolver.resolve(
          providerIds: const ['firebase', 'password'],
        ),
        AuthProviderResolver.email,
      );
    });
  });

  group('user-document ensure', () {
    UserDocumentEnsureInput inputFor({
      String uid = 'uid-1',
      String provider = AuthProviderResolver.phone,
      String? phone = '+905551112233',
      String? email,
      String? name,
    }) {
      return UserDocumentEnsureInput(
        uid: uid,
        authProvider: provider,
        phoneNumber: phone,
        email: email,
        displayName: name,
      );
    }

    test('existing auth_provider is not overwritten on session ensure', () {
      final docs = <String, Map<String, dynamic>>{
        'uid-1': {
          'uid': 'uid-1',
          'auth_provider': 'email',
          'name': 'Ada',
          'test_completed': true,
        },
      };
      final next = UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: inputFor(provider: AuthProviderResolver.phone),
      );
      expect(next['auth_provider'], 'email');
      expect(next['name'], 'Ada');
      expect(next['test_completed'], isTrue);
      expect(
        UserDocumentEnsure.decide(
          existing: docs['uid-1'],
          input: inputFor(provider: AuthProviderResolver.phone),
          timestamp: () => 'ts',
        ).fields.containsKey('auth_provider'),
        isFalse,
      );
    });

    test('missing auth_provider on a legacy user may be filled', () {
      final docs = <String, Map<String, dynamic>>{
        'uid-1': {
          'uid': 'uid-1',
          'name': 'Legacy',
          'profile_completed': true,
        },
      };
      final next = UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: inputFor(provider: AuthProviderResolver.email),
      );
      expect(next['auth_provider'], AuthProviderResolver.email);
      expect(next['name'], 'Legacy');
      expect(next['profile_completed'], isTrue);
    });

    test('repeated ensure does not reset completion or profile fields', () {
      final docs = <String, Map<String, dynamic>>{};
      UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: inputFor(name: 'First'),
      );
      docs['uid-1']!.addAll({
        'test_completed': true,
        'frequency_completed': true,
        'profile_completed': true,
        'discover_eligible': true,
        'active': true,
        'name': 'Kept',
        'iq_score': 12,
      });

      UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: inputFor(
          provider: AuthProviderResolver.email,
          name: 'ShouldNotWrite',
        ),
      );
      UserDocumentEnsure.applyInMemory(
        docs: docs,
        input: inputFor(provider: AuthProviderResolver.phone),
      );

      final next = docs['uid-1']!;
      expect(next['test_completed'], isTrue);
      expect(next['frequency_completed'], isTrue);
      expect(next['profile_completed'], isTrue);
      expect(next['discover_eligible'], isTrue);
      expect(next['active'], isTrue);
      expect(next['name'], 'Kept');
      expect(next['iq_score'], 12);
      expect(next['auth_provider'], AuthProviderResolver.phone);
      final merge = UserDocumentEnsure.decide(
        existing: next,
        input: inputFor(provider: AuthProviderResolver.email),
        timestamp: () => 'ts',
      );
      expect(merge.isCreate, isFalse);
      for (final key in UserDocumentEnsure.protectedExistingFields) {
        expect(merge.fields.containsKey(key), isFalse, reason: key);
      }
    });
  });

  group('typed email signup errors', () {
    test('signUpWithEmail rethrows FirebaseAuthException', () async {
      final service = AuthService(
        createUserWithEmailAndPassword: ({
          required String email,
          required String password,
        }) async {
          throw FirebaseAuthException(code: 'email-already-in-use');
        },
      );

      await expectLater(
        service.signUpWithEmail(
          email: 'ada@example.com',
          password: 'secret1',
          name: 'Ada',
        ),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'email-already-in-use',
          ),
        ),
      );
    });

    test('signup service no longer stringifies auth errors', () {
      final src =
          File('lib/core/services/auth_service.dart').readAsStringSync();
      final start = src.indexOf('Future<UserCredential> signUpWithEmail');
      final end = src.indexOf('Future<void> createUserInFirestore');
      expect(start, greaterThan(0));
      expect(end, greaterThan(start));
      final block = src.substring(start, end);
      expect(block.contains('throw e.toString()'), isFalse);
      expect(block.contains('createUserWithEmailAndPassword'), isTrue);
    });
  });
}
