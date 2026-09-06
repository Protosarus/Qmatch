import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/identity/identity.dart';
import 'package:qmatch/core/navigation/auth_wrapper.dart';
import 'package:qmatch/core/services/auth_provider_resolver.dart';
import 'package:qmatch/core/services/user_document_ensure.dart';
import 'package:qmatch/features/auth/apple_sign_in_flow.dart';
import 'package:qmatch/features/auth/google_sign_in_flow.dart';
import 'package:qmatch/features/auth/screens/welcome_screen.dart';
import 'package:qmatch/features/profile/screens/display_name_completion_screen.dart';
import 'package:qmatch/features/profile/services/display_name_service.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget app({required Widget home}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }

  Map<String, dynamic> createOAuthUser({
    required String uid,
    required String provider,
    String? email,
    String? displayName,
  }) {
    return UserDocumentEnsure.applyInMemory(
      docs: <String, Map<String, dynamic>>{},
      input: UserDocumentEnsureInput(
        uid: uid,
        authProvider: provider,
        email: email,
        displayName: displayName,
      ),
    );
  }

  const existingProgress = <String, dynamic>{
    'uid': 'kept',
    'auth_provider': 'google',
    'name': 'Kept Canonical',
    'email': 'kept@example.com',
    'test_completed': true,
    'frequency_completed': true,
    'profile_completed': true,
    'discover_eligible': true,
    'active': true,
    'iq_score': 14,
    'eq_score': 88,
    'subscription_status': 'active',
  };

  test('1 new Google user with Firebase displayName still needs nickname', () {
    final created = createOAuthUser(
      uid: 'g-new',
      provider: AuthProviderResolver.google,
      email: 'umit@gmail.com',
      displayName: 'Ümit Şirin',
    );
    expect(created.containsKey('name'), isFalse);
    expect(AuthWrapper.needsDisplayNameCompletion(created), isTrue);
  });

  testWidgets('2 Google provider name appears as nickname prefill',
      (tester) async {
    final store = _MemoryDisplayNameStore(prefill: 'Ümit Şirin');
    await tester.pumpWidget(
      app(
        home: DisplayNameCompletionScreen(
          displayNameService: store,
          overrideUid: 'g-new',
          onCompleted: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(DisplayNameCompletionScreen), findsOneWidget);
    expect(find.text('Ümit Şirin'), findsOneWidget);
    expect(store.savedName, isNull);
  });

  testWidgets('3 confirming Google prefill persists canonical users.name',
      (tester) async {
    final store = _MemoryDisplayNameStore(prefill: 'Ümit Şirin');
    await tester.pumpWidget(
      app(
        home: DisplayNameCompletionScreen(
          displayNameService: store,
          overrideUid: 'g-new',
          onCompleted: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('qmatch-display-name-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(store.savedName, 'Ümit Şirin');
    expect(
      DisplayNameService.isValidCanonicalDisplayNameFromMap(
        {DisplayNameContract.firestoreField: store.savedName},
      ),
      isTrue,
    );
    expect(
      AuthWrapper.needsDisplayNameCompletion(
        {DisplayNameContract.firestoreField: store.savedName},
      ),
      isFalse,
    );
  });

  test('4 new Apple first-auth name still needs nickname screen', () {
    final appleName = AppleSignInFlow.displayName(
      givenName: 'Ada',
      familyName: 'Lovelace',
    );
    final created = createOAuthUser(
      uid: 'a-new',
      provider: AuthProviderResolver.apple,
      email: 'hidden@privaterelay.appleid.com',
      displayName: appleName,
    );
    expect(appleName, 'Ada Lovelace');
    expect(created.containsKey('name'), isFalse);
    expect(AuthWrapper.needsDisplayNameCompletion(created), isTrue);
  });

  testWidgets('5 Apple first-auth name appears as nickname prefill',
      (tester) async {
    final store = _MemoryDisplayNameStore(prefill: 'Ada Lovelace');
    await tester.pumpWidget(
      app(
        home: DisplayNameCompletionScreen(
          displayNameService: store,
          overrideUid: 'a-new',
          onCompleted: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(DisplayNameCompletionScreen), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(store.savedName, isNull);
  });

  testWidgets('6 Apple with no returned name still opens nickname blank',
      (tester) async {
    final created = createOAuthUser(
      uid: 'a-blank',
      provider: AuthProviderResolver.apple,
      email: 'abc@privaterelay.appleid.com',
    );
    expect(created.containsKey('name'), isFalse);
    expect(AuthWrapper.needsDisplayNameCompletion(created), isTrue);

    final store = _MemoryDisplayNameStore();
    await tester.pumpWidget(
      app(
        home: DisplayNameCompletionScreen(
          displayNameService: store,
          overrideUid: 'a-blank',
          onCompleted: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(DisplayNameCompletionScreen), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('qmatch-display-name-field')),
    );
    expect(field.controller?.text, isEmpty);
  });

  test('7 existing Google user with valid users.name skips nickname', () {
    final docs = <String, Map<String, dynamic>>{
      'g-old': Map<String, dynamic>.from(existingProgress)
        ..['auth_provider'] = AuthProviderResolver.google,
    };
    final next = UserDocumentEnsure.applyInMemory(
      docs: docs,
      input: const UserDocumentEnsureInput(
        uid: 'g-old',
        authProvider: AuthProviderResolver.google,
        email: 'new@gmail.com',
        displayName: 'Should Not Open Nickname',
      ),
    );
    expect(next['name'], 'Kept Canonical');
    expect(AuthWrapper.needsDisplayNameCompletion(next), isFalse);
  });

  test('8 existing Apple user with valid users.name skips nickname', () {
    final docs = <String, Map<String, dynamic>>{
      'a-old': {
        ...existingProgress,
        'uid': 'a-old',
        'auth_provider': AuthProviderResolver.apple,
        'name': 'Kept Apple',
      },
    };
    final next = UserDocumentEnsure.applyInMemory(
      docs: docs,
      input: const UserDocumentEnsureInput(
        uid: 'a-old',
        authProvider: AuthProviderResolver.apple,
        email: null,
        displayName: 'Apple Sheet Name',
      ),
    );
    expect(next['name'], 'Kept Apple');
    expect(AuthWrapper.needsDisplayNameCompletion(next), isFalse);
  });

  test('9 existing canonical name is never overwritten by OAuth profile', () {
    final docs = <String, Map<String, dynamic>>{
      'kept': Map<String, dynamic>.from(existingProgress),
    };
    final google = UserDocumentEnsure.applyInMemory(
      docs: docs,
      input: const UserDocumentEnsureInput(
        uid: 'kept',
        authProvider: AuthProviderResolver.google,
        displayName: 'Google Profile',
      ),
    );
    final apple = UserDocumentEnsure.applyInMemory(
      docs: docs,
      input: const UserDocumentEnsureInput(
        uid: 'kept',
        authProvider: AuthProviderResolver.apple,
        displayName: 'Apple Profile',
      ),
    );
    expect(google['name'], 'Kept Canonical');
    expect(apple['name'], 'Kept Canonical');
  });

  test('10 assessment and profile state stay intact on OAuth ensure', () {
    final docs = <String, Map<String, dynamic>>{
      'kept': Map<String, dynamic>.from(existingProgress),
    };
    final next = UserDocumentEnsure.applyInMemory(
      docs: docs,
      input: const UserDocumentEnsureInput(
        uid: 'kept',
        authProvider: AuthProviderResolver.google,
        displayName: 'Overwrite Attempt',
      ),
    );
    expect(next['test_completed'], isTrue);
    expect(next['frequency_completed'], isTrue);
    expect(next['profile_completed'], isTrue);
    expect(next['discover_eligible'], isTrue);
    expect(next['iq_score'], 14);
    expect(next['eq_score'], 88);
    expect(next['subscription_status'], 'active');
    expect(next['name'], 'Kept Canonical');
    final merge = UserDocumentEnsure.decide(
      existing: next,
      input: const UserDocumentEnsureInput(
        uid: 'kept',
        authProvider: AuthProviderResolver.google,
        displayName: 'Overwrite Attempt',
      ),
      timestamp: () => 'ts',
    );
    expect(merge.isCreate, isFalse);
    for (final key in UserDocumentEnsure.protectedExistingFields) {
      expect(merge.fields.containsKey(key), isFalse, reason: key);
    }
  });

  test('11 Google/Apple handlers do not nest AuthWrapper', () {
    for (final path in [
      'lib/features/auth/screens/welcome_screen.dart',
      'lib/features/auth/google_sign_in_flow.dart',
      'lib/features/auth/apple_sign_in_flow.dart',
      'lib/core/navigation/auth_navigation.dart',
      'lib/core/services/auth_service.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src.contains('AuthWrapper('), isFalse, reason: path);
      expect(src.contains('DisplayNameCompletionScreen('), isFalse,
          reason: path);
    }
    final wrapper =
        File('lib/core/navigation/auth_wrapper.dart').readAsStringSync();
    expect(wrapper.contains('DisplayNameCompletionScreen()'), isTrue);
    expect(wrapper.contains('AssessmentProgressRouteGate('), isTrue);
    expect(
      File('lib/main.dart').readAsStringSync().contains('AuthWrapper()'),
      isTrue,
    );
  });

  testWidgets('12 Google and Apple Welcome callbacks stay wired',
      (tester) async {
    var googleCalls = 0;
    var appleCalls = 0;
    await tester.pumpWidget(
      app(
        home: WelcomeScreen(
          showAppleButton: true,
          signInWithGoogle: () async {
            googleCalls += 1;
            return GoogleSignInAttempt.cancelled();
          },
          signInWithApple: () async {
            appleCalls += 1;
            return AppleSignInAttempt.cancelled();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.googleButtonKey));
    await tester.pump();
    await tester.ensureVisible(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.appleButtonKey));
    await tester.pump();
    expect(googleCalls, 1);
    expect(appleCalls, 1);
  });

  test('email still seeds a deliberate create-time name; phone unchanged', () {
    final email = UserDocumentEnsure.applyInMemory(
      docs: <String, Map<String, dynamic>>{},
      input: const UserDocumentEnsureInput(
        uid: 'email-new',
        authProvider: AuthProviderResolver.email,
        email: 'ada@example.com',
        displayName: 'Ada Email',
      ),
    );
    expect(email['name'], 'Ada Email');
    expect(AuthWrapper.needsDisplayNameCompletion(email), isFalse);

    final emailEmpty = UserDocumentEnsure.applyInMemory(
      docs: <String, Map<String, dynamic>>{},
      input: const UserDocumentEnsureInput(
        uid: 'email-blank',
        authProvider: AuthProviderResolver.email,
        email: 'ada@example.com',
        displayName: '',
      ),
    );
    expect(emailEmpty.containsKey('name'), isFalse);
    expect(AuthWrapper.needsDisplayNameCompletion(emailEmpty), isTrue);

    final phone = UserDocumentEnsure.applyInMemory(
      docs: <String, Map<String, dynamic>>{},
      input: const UserDocumentEnsureInput(
        uid: 'phone-new',
        authProvider: AuthProviderResolver.phone,
        phoneNumber: '+905551112233',
      ),
    );
    expect(phone.containsKey('name'), isFalse);
    expect(AuthWrapper.needsDisplayNameCompletion(phone), isTrue);
  });

  test('Auth displayName remains a prefill candidate, not canonical', () {
    expect(
      DisplayNameService.isValidCanonicalDisplayNameFromMap(const {}),
      isFalse,
    );
    expect(
      DisplayNameService.isValidCanonicalDisplayNameFromMap(
        const {'displayName': 'Ümit Şirin'},
      ),
      isFalse,
    );
    expect(
      DisplayNameService.isValidCanonicalDisplayNameFromMap(
        const {'name': 'Ümit Şirin'},
      ),
      isTrue,
    );
  });
}

class _MemoryDisplayNameStore implements DisplayNameStore {
  _MemoryDisplayNameStore({this.prefill = ''});

  final String prefill;
  String? savedName;

  @override
  Future<bool> hasValidCanonicalDisplayName(String uid) async =>
      savedName != null;

  @override
  Future<String> prefillCandidate(String uid) async => prefill;

  @override
  Future<String?> readCanonicalDisplayName(String uid) async => savedName;

  @override
  Future<void> saveCanonicalDisplayName({
    required String uid,
    required String rawInput,
  }) async {
    final v = DisplayNameValidator.validate(rawInput);
    if (!v.isValid) throw ArgumentError(v.error);
    savedName = v.normalized;
  }
}
