import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/widgets/qmatch_candidate_card.dart';
import 'package:qmatch/features/profile/models/user_profile_model.dart';
import 'package:qmatch/features/profile/screens/profile_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';

UserProfileModel baseProfile({
  String education = 'Lisans',
  String? occupation = 'Engineer',
  String? company = 'QMatch',
  String? school = 'Boğaziçi',
  String? educationField = 'CS',
}) {
  return UserProfileModel(
    userId: 'u1',
    name: 'Ada',
    age: 26,
    gender: 'Kadın',
    education: education,
    bio: 'Hello',
    interests: const ['Müzik'],
    lookingFor: 'Ciddi İlişki',
    ageRange: const [25, 35],
    distancePreference: 50,
    occupation: occupation,
    company: company,
    school: school,
    educationField: educationField,
  );
}

Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('UserProfileModel work/education fields', () {
    test('serializes optional company/school/education_field', () {
      final map = baseProfile().toFirestore();
      expect(map['occupation'], 'Engineer');
      expect(map['company'], 'QMatch');
      expect(map['school'], 'Boğaziçi');
      expect(map['education_field'], 'CS');
      expect(map['education'], 'Lisans');
    });

    test('omits null optional work fields', () {
      final map = baseProfile(
        occupation: null,
        company: null,
        school: null,
        educationField: null,
      ).toFirestore();
      expect(map.containsKey('occupation'), isFalse);
      expect(map.containsKey('company'), isFalse);
      expect(map.containsKey('school'), isFalse);
      expect(map.containsKey('education_field'), isFalse);
    });

    test('round-trips fromFirestore', () {
      final original = baseProfile();
      final restored = UserProfileModel.fromFirestore(
        original.toFirestore(),
        'u1',
      );
      expect(restored.company, 'QMatch');
      expect(restored.school, 'Boğaziçi');
      expect(restored.educationField, 'CS');
      expect(restored.occupation, 'Engineer');
    });
  });

  group('DiscoverUserModel work/education', () {
    test('parses work and education fields', () {
      final user = DiscoverUserModel.fromFirestore('u2', {
        'name': 'Bora',
        'age': 30,
        'education': 'Yüksek Lisans',
        'occupation': 'Designer',
        'company': 'Studio',
        'school': 'ODTÜ',
        'education_field': 'Architecture',
      });
      expect(user.education, 'Yüksek Lisans');
      expect(user.occupation, 'Designer');
      expect(user.company, 'Studio');
      expect(user.school, 'ODTÜ');
      expect(user.educationField, 'Architecture');
    });
  });

  testWidgets('profile shows work/education rows without post-setup editor',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        ProfileScreen(
          debugProfile: baseProfile(),
          debugResonanceAccess: false,
          animateBackground: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Occupation'), findsOneWidget);
    expect(find.text('Engineer'), findsOneWidget);
    expect(find.text('Company'), findsOneWidget);
    expect(find.text('QMatch'), findsOneWidget);
    expect(find.text('School'), findsOneWidget);
    expect(find.text('Boğaziçi'), findsOneWidget);
    expect(find.text('Field of study'), findsOneWidget);
    expect(find.text('CS'), findsOneWidget);
    expect(find.byKey(const Key('qmatch-profile-edit-details')), findsNothing);
  });

  testWidgets('candidate card shows work/education line', (tester) async {
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: SizedBox(
            height: 640,
            child: QMatchCandidateCard(
              candidate: DiscoverUserModel(
                uid: 'u3',
                name: 'Ada',
                age: 27,
                education: 'Lisans',
                occupation: 'Engineer',
                company: 'QMatch',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('qmatch-candidate-work-education')),
      findsOneWidget,
    );
    expect(find.textContaining('Engineer'), findsOneWidget);
    expect(find.textContaining('QMatch'), findsOneWidget);
  });
}
