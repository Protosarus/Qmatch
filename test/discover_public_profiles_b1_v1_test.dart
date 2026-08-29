import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/services/discover_l1_eligibility_gate.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_dual_path_collector.dart';
import 'package:qmatch/features/discover/services/discover_structural_l2_ranking.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  group('Discover B1 public_profiles query', () {
    test('A/B candidate query targets public_profiles with discover_eligible',
        () {
      final service = read(
        'lib/features/discover/services/discover_service.dart',
      );
      final paths = read('lib/core/utils/firestore_paths.dart');

      expect(paths.contains("collection('public_profiles')"), isTrue);
      expect(paths.contains('static CollectionReference<Map<String, dynamic>> '
          'publicProfiles()'), isTrue);
      expect(paths.contains('static CollectionReference<Map<String, dynamic>> '
          'users()'), isTrue);

      final start = service.indexOf(
        'Future<List<DiscoverUserModel>> getCandidates({int limit = 30}) async {',
      );
      final end = service.indexOf(
        'Future<void> _hydrateViewerLegacyFrequencyMirrors({',
      );
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final body = service.substring(start, end);

      expect(body.contains('FirestorePaths.publicProfiles()'), isTrue);
      expect(
        body.contains("where('discover_eligible', isEqualTo: true)"),
        isTrue,
      );
      expect(body.contains('FirestorePaths.users()'), isFalse);
      expect(body.contains('userDoc(doc.id)'), isFalse);
      expect(body.contains('users().doc('), isFalse);
    });

    test('C Passport destination still filters home_country and home_city', () {
      final service = read(
        'lib/features/discover/services/discover_service.dart',
      );
      expect(service.contains('usesDestinationFilter'), isTrue);
      expect(service.contains('skipEligibleQuery'), isTrue);
      expect(
        service.contains("where('home_country', isEqualTo: plan.country)"),
        isTrue,
      );
      expect(
        service.contains("where('home_city', isEqualTo: plan.city)"),
        isTrue,
      );
    });

    test('H owner users/{currentUid} read remains; peer user GET is absent', () {
      final service = read(
        'lib/features/discover/services/discover_service.dart',
      );
      expect(
        service.contains('FirestorePaths.userDoc(currentUid).get()'),
        isTrue,
      );
      expect(service.contains(".collection('assessments')"), isTrue);
      expect(service.contains("doc('frequency')"), isTrue);
      expect(service.contains('userDoc(doc.id)'), isFalse);
    });
  });

  group('Discover B1 public snapshot L1 / model', () {
    Map<String, dynamic> publicSnapshot({
      bool eligible = true,
      String? photo = 'https://example.com/a.jpg',
      List<String> photos = const [],
    }) {
      return {
        'discover_eligible': eligible,
        'name': 'Ada',
        'age': 29,
        'bio': 'Hello',
        'photos': photos,
        if (photo != null) 'profile_photo_url': photo,
        'home_country': 'TR',
        'home_city': 'istanbul',
        'occupation': 'Engineer',
        'interests': ['music'],
      };
    }

    test('D missing private L1 mirrors does not reject a valid public profile',
        () {
      final candidate = DiscoverUserModel.fromFirestore(
        'peerA',
        publicSnapshot(),
      );
      expect(candidate.profileCompleted, isFalse);
      expect(candidate.testCompleted, isFalse);
      expect(candidate.assessmentFlowCompleted, isFalse);
      expect(candidate.discoverEligible, isTrue);
      expect(candidate.hasPhoto, isTrue);
      expect(
        DiscoverL1EligibilityGate.passesLocalAccountGates(
          active: candidate.active,
          profileCompleted: candidate.profileCompleted,
          testCompleted: candidate.testCompleted,
          assessmentFlowCompleted: candidate.assessmentFlowCompleted,
          hasPhoto: candidate.hasPhoto,
        ),
        isFalse,
      );
      expect(
        DiscoverL1EligibilityGate.passesPublicProfileLocalGates(
          discoverEligible: candidate.discoverEligible,
          hasPhoto: candidate.hasPhoto,
        ),
        isTrue,
      );
    });

    test('E candidate with no usable photo is still rejected', () {
      final candidate = DiscoverUserModel.fromFirestore(
        'peerB',
        publicSnapshot(photo: null, photos: const []),
      );
      expect(candidate.hasPhoto, isFalse);
      expect(
        DiscoverL1EligibilityGate.passesPublicProfileLocalGates(
          discoverEligible: candidate.discoverEligible,
          hasPhoto: candidate.hasPhoto,
        ),
        isFalse,
      );
    });

    test('F private/legacy fields are not required or fabricated', () {
      final candidate = DiscoverUserModel.fromFirestore(
        'peerC',
        publicSnapshot(),
      );
      expect(candidate.iqNormalized, isNull);
      expect(candidate.eqNormalized, isNull);
      expect(candidate.frequencyType, isNull);
      expect(candidate.frequencyScore, isNull);
      expect(candidate.frequencyTags, isNull);
      expect(candidate.lastActiveAt, isNull);
      expect(candidate.archetype, isNull);
      expect(candidate.category, isNull);
      expect(candidate.gender, isEmpty);
      expect(candidate.lookingFor, isEmpty);
    });

    test('G equal L2 distance without last_active_at uses uid tiebreak', () {
      DiscoverUserModel card(String uid) => DiscoverUserModel.fromFirestore(
            uid,
            publicSnapshot(),
          );
      final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
        l1Eligible: [card('zeta'), card('alpha')],
        pairsByUid: {
          'zeta': const DiscoverStageB2TrustedPairResult(
            available: true,
            structuralDistance: 0.2,
            totalCoverage: 1.0,
            comparableDimensions: 20,
          ),
          'alpha': const DiscoverStageB2TrustedPairResult(
            available: true,
            structuralDistance: 0.2,
            totalCoverage: 1.0,
            comparableDimensions: 20,
          ),
        },
      );
      expect(ranked.map((c) => c.uid).toList(), ['alpha', 'zeta']);
    });
  });

  group('Discover B1 does not reintroduce private peer fields', () {
    test('DiscoverService does not GET peer users or private field names', () {
      final service = read(
        'lib/features/discover/services/discover_service.dart',
      );
      final start = service.indexOf(
        'Future<List<DiscoverUserModel>> getCandidates({int limit = 30}) async {',
      );
      final end = service.indexOf(
        'Future<void> _hydrateViewerLegacyFrequencyMirrors({',
      );
      final body = service.substring(start, end);
      expect(body.contains('frequency_vector'), isFalse);
      expect(body.contains('iq_normalized'), isFalse);
      expect(body.contains('email'), isFalse);
      expect(body.contains('phone_number'), isFalse);
      expect(body.contains('profile_completed'), isFalse);
      expect(body.contains('test_completed'), isFalse);
      expect(body.contains('assessment_flow_completed'), isFalse);
    });
  });
}
