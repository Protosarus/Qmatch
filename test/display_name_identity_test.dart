import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/identity/identity.dart';
import 'package:qmatch/features/profile/models/user_profile_model.dart';
import 'package:qmatch/features/profile/screens/display_name_completion_screen.dart';
import 'package:qmatch/features/profile/services/display_name_service.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('DisplayNameValidator', () {
    test('trims and collapses whitespace', () {
      final r = DisplayNameValidator.validate('  Ada   Lovelace  ');
      expect(r.isValid, isTrue);
      expect(r.normalized, 'Ada Lovelace');
    });

    test('Turkish characters pass', () {
      expect(DisplayNameValidator.validate('Şule').isValid, isTrue);
      expect(DisplayNameValidator.validate('İrem').normalized, 'İrem');
    });

    test('Cyrillic characters pass', () {
      expect(DisplayNameValidator.validate('Анна').isValid, isTrue);
    });

    test('accented Latin passes', () {
      expect(DisplayNameValidator.validate('José').isValid, isTrue);
    });

    test('apostrophe and hyphen pass', () {
      expect(DisplayNameValidator.validate("O'Neill").isValid, isTrue);
      expect(DisplayNameValidator.validate('Anne-Marie').isValid, isTrue);
    });

    test('emoji does not break grapheme counting', () {
      final r = DisplayNameValidator.validate('A😀');
      expect(r.isValid, isTrue);
      expect(
        DisplayNameValidator.validate('😀').error,
        DisplayNameValidationError.tooShort,
      );
    });

    test('too short / too long', () {
      expect(
        DisplayNameValidator.validate('A').error,
        DisplayNameValidationError.tooShort,
      );
      expect(
        DisplayNameValidator.validate('A' * 25).error,
        DisplayNameValidationError.tooLong,
      );
    });

    test('newline/control fail', () {
      expect(
        DisplayNameValidator.validate('Ada\nX').error,
        DisplayNameValidationError.controlCharacters,
      );
    });

    test('email/phone/url-only fail', () {
      expect(
        DisplayNameValidator.validate('a@b.com').error,
        DisplayNameValidationError.emailLike,
      );
      expect(
        DisplayNameValidator.validate('+90 532 111 2233').error,
        DisplayNameValidationError.phoneLike,
      );
      expect(
        DisplayNameValidator.validate('https://qmatch.app').error,
        DisplayNameValidationError.urlLike,
      );
    });

    test('requires letter or number', () {
      expect(
        DisplayNameValidator.validate('--').error,
        DisplayNameValidationError.missingLetterOrNumber,
      );
    });

    test('canonical firestore key is name', () {
      expect(DisplayNameContract.firestoreField, 'name');
    });

    test('empty name omitted from profile toFirestore merge payload', () {
      const profile = UserProfileModel(
        userId: 'u1',
        name: '',
        age: 26,
        gender: 'female',
        education: 'bachelor',
        bio: 'Hello',
        interests: [],
        lookingFor: 'relationship',
        ageRange: [25, 35],
        distancePreference: 50,
      );
      expect(profile.toFirestore().containsKey('name'), isFalse);
    });
  });

  group('UserIdentityResolver', () {
    test('formats Ada, 26 and never emits , 26', () {
      expect(
        UserIdentityResolver.formatNameAndAge(displayName: 'Ada', age: 26),
        'Ada, 26',
      );
      expect(
        UserIdentityResolver.formatNameAndAge(displayName: '', age: 26),
        isNull,
      );
      expect(
        UserIdentityResolver.formatNameAndAge(displayName: 'Ada', age: null),
        'Ada',
      );
    });

    test('reads canonical name; no email/phone/uid fallback', () {
      final resolved = UserIdentityResolver.fromUserMap({
        'name': 'Ada',
        'age': 26,
        'email': 'x@y.com',
        'phone_number': '+15551212',
        'uid': 'uid_abc',
      });
      expect(resolved.displayName, 'Ada');
      expect(
        UserIdentityResolver.formatFromUserMap({
          'email': 'x@y.com',
          'uid': 'uid_abc',
          'age': 26,
        }),
        isNull,
      );
    });

    test('invalid contact-like name treated as missing', () {
      final resolved = UserIdentityResolver.fromUserMap({
        'name': 'a@b.com',
        'age': 26,
      });
      expect(resolved.hasDisplayName, isFalse);
    });

    test('oversized legacy name still displays (write path remains strict)',
        () {
      final long = 'Very Long Display Name That Should Ellipsize Gracefully';
      expect(DisplayNameValidator.validate(long).isValid, isFalse);
      expect(UserIdentityResolver.coerceForDisplay(long), long);
      expect(
        UserIdentityResolver.formatNameAndAge(displayName: long, age: 29),
        '$long, 29',
      );
    });
  });

  group('DisplayNameCompletionScreen', () {
    testWidgets('localized TR title; empty cannot continue', (tester) async {
      final store = _MemoryDisplayNameStore();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: DisplayNameCompletionScreen(
            displayNameService: store,
            overrideUid: 'user_test',
            onCompleted: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Sana nasıl hitap edelim?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-display-name-continue')));
      await tester.pump();
      expect(
          find.byKey(const Key('qmatch-display-name-error')), findsOneWidget);
      expect(store.savedName, isNull);
    });

    testWidgets('valid name persists through store boundary', (tester) async {
      final store = _MemoryDisplayNameStore();
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: DisplayNameCompletionScreen(
            displayNameService: store,
            overrideUid: 'user_test',
            onCompleted: () => completed = true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(
        find.byKey(const Key('qmatch-display-name-field')),
        'Ada',
      );
      await tester.tap(find.byKey(const Key('qmatch-display-name-continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(store.savedName, 'Ada');
      expect(completed, isTrue);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('legacy prefill is shown for confirmation', (tester) async {
      final store = _MemoryDisplayNameStore(prefill: 'Şule');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: DisplayNameCompletionScreen(
            displayNameService: store,
            overrideUid: 'user_test',
            onCompleted: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Şule'), findsOneWidget);
    });
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
