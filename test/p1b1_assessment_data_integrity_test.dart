import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/models/archetype_model.dart';
import 'package:qmatch/features/assessment/models/frequency_model.dart';
import 'package:qmatch/features/assessment/services/canonical_assessment_persistence.dart';
import 'package:qmatch/features/assessment/services/frequency_service.dart';
import 'package:qmatch/features/profile/models/user_profile_model.dart';

void main() {
  group('UserProfileModel null omission (P1B-1)', () {
    test('omits null archetype/category and optional fields', () {
      const profile = UserProfileModel(
        userId: 'u1',
        name: 'Ada',
        age: 28,
        gender: 'female',
        education: 'uni',
        bio: 'hi',
        interests: ['art'],
        lookingFor: 'serious',
        ageRange: [24, 35],
        distancePreference: 40,
        profileCompleted: false,
        verified: false,
      );

      final map = profile.toFirestore();
      expect(map.containsKey('archetype'), isFalse);
      expect(map.containsKey('category'), isFalse);
      expect(map.containsKey('location'), isFalse);
      // Empty photos + no primary → explicit clear string for merge revoke.
      expect(map['profile_photo_url'], '');
      expect(map['photos'], isEmpty);
      expect(map['name'], 'Ada');
      expect(map['profile_completed'], isFalse);
      expect(map['verified'], isFalse);
      expect(map['age'], 28);
      expect(map['distance_preference'], 40);
    });

    test('writes non-null archetype/category when present', () {
      const profile = UserProfileModel(
        userId: 'u1',
        name: 'Ada',
        age: 28,
        gender: 'female',
        education: 'uni',
        bio: 'hi',
        interests: ['art'],
        lookingFor: 'serious',
        ageRange: [24, 35],
        distancePreference: 40,
        archetype: 'The Realist',
        category: 'MM',
        profileCompleted: true,
        verified: true,
      );

      final map = profile.toFirestore();
      expect(map['archetype'], 'The Realist');
      expect(map['category'], 'MM');
      expect(map['profile_completed'], isTrue);
      expect(map['verified'], isTrue);
    });

    test(
        'merge simulation: null profile payload does not clear assessment keys',
        () {
      final existing = <String, dynamic>{
        'name': 'Old',
        'archetype': 'The Mastermind',
        'category': 'HH',
        'iq_score': 8,
        'eq_score': 7,
        'iq_normalized': 80,
        'eq_normalized': 70,
        'primary_persona_id': 'lider',
        'frequency_completed': true,
        'test_completed': true,
      };

      const incoming = UserProfileModel(
        userId: 'u1',
        name: 'New',
        age: 30,
        gender: 'female',
        education: 'uni',
        bio: 'updated',
        interests: ['music'],
        lookingFor: 'casual',
        ageRange: [25, 40],
        distancePreference: 25,
      );

      final merged = <String, dynamic>{
        ...existing,
        ...incoming.toFirestore(),
        'profile_completed': true,
      };

      expect(merged['name'], 'New');
      expect(merged['archetype'], 'The Mastermind');
      expect(merged['category'], 'HH');
      expect(merged['iq_score'], 8);
      expect(merged['primary_persona_id'], 'lider');
      expect(merged['test_completed'], isTrue);
      expect(merged['profile_completed'], isTrue);
    });
  });

  group('ArchetypeCalculator module-specific denominators', () {
    test('EQ question count change does not alter IQ normalization', () {
      final a = ArchetypeCalculator.calculateArchetype(
        iqCorrect: 8,
        iqQuestionCount: 10,
        eqCorrect: 5,
        eqQuestionCount: 10,
      );
      final b = ArchetypeCalculator.calculateArchetype(
        iqCorrect: 8,
        iqQuestionCount: 10,
        eqCorrect: 5,
        eqQuestionCount: 20,
      );

      expect(a.iqNormalized, 80);
      expect(b.iqNormalized, 80);
      expect(a.iqNormalized, b.iqNormalized);
      expect(a.eqNormalized, 50);
      expect(b.eqNormalized, 25);
    });

    test('zero denominator yields zero normalized score', () {
      final m = ArchetypeCalculator.calculateArchetype(
        iqCorrect: 0,
        iqQuestionCount: 0,
        eqCorrect: 3,
        eqQuestionCount: 10,
      );
      expect(m.iqNormalized, 0);
      expect(m.eqNormalized, 30);
    });
  });

  group('CanonicalAssessmentPersistence payload', () {
    test('IQ payload omits invented dimensions and lists all IQ missing', () {
      final persistence = CanonicalAssessmentPersistence();
      final payload = persistence.buildLegacyIqEqPayload(
        assessmentType: 'iq',
        setId: 'iq_set_001',
        contentVersion: '2026_01',
        locale: 'tr_TR',
        languageUsed: 'tr',
        questionCount: 10,
        answeredCount: 10,
        rawScore: 7,
        missingDimensions: CanonicalDimensions.iq,
        assignmentType: 'iq',
        startedAt: DateTime.utc(2026, 7, 23),
      );

      expect(payload['assessment_type'], isNull); // added by upsert
      expect(payload['raw_score'], 7);
      expect(payload['dimension_scores'], isEmpty);
      expect(payload['canonical_profile_ready'], isFalse);
      expect(payload['missing_dimensions'], CanonicalDimensions.iq);
      expect(payload.containsKey('started_at'), isTrue);
      expect(payload['trait_scoring_version'],
          CanonicalAssessmentVersions.traitScoringVersionLegacyTotal);
      // No fabricated neutrals
      expect(payload['dimension_scores'], isNot(contains(0.5)));
    });

    test('EQ payload marks correct_answer_total legacy mode', () {
      final persistence = CanonicalAssessmentPersistence();
      final payload = persistence.buildLegacyIqEqPayload(
        assessmentType: 'eq',
        setId: 'eq_set_001',
        contentVersion: '2026_01',
        locale: 'en_US',
        languageUsed: 'en',
        questionCount: 10,
        answeredCount: 10,
        rawScore: 6,
        missingDimensions: CanonicalDimensions.eq,
        assignmentType: 'eq',
        legacyScoringMode: 'correct_answer_total',
      );

      expect(payload['legacy_scoring_mode'], 'correct_answer_total');
      expect(payload['missing_dimensions'], CanonicalDimensions.eq);
      expect(payload['dimension_scores'], isEmpty);
      expect(payload['canonical_profile_ready'], isFalse);
    });

    test('omitNulls drops null keys but keeps false and zero', () {
      final out = CanonicalAssessmentPersistence.omitNulls({
        'a': null,
        'b': false,
        'c': 0,
        'd': '',
        'e': <String, dynamic>{},
      });
      expect(out.containsKey('a'), isFalse);
      expect(out['b'], isFalse);
      expect(out['c'], 0);
      expect(out['d'], '');
      expect(out['e'], isEmpty);
    });
  });

  group('Frequency missing dimensions (P1B-1)', () {
    List<FrequencyQuestion> questionsFor({
      required List<String> dims,
      int perDim = 2,
    }) {
      final out = <FrequencyQuestion>[];
      for (final d in dims) {
        for (var i = 0; i < perDim; i++) {
          out.add(
            FrequencyQuestion(
              id: '${d}_$i',
              question: 'Q $d $i',
              dimension: d,
            ),
          );
        }
      }
      return out;
    }

    final allDims = [
      'depth',
      'socialEnergy',
      'spontaneity',
      'stability',
      'emotionalOpenness',
      'conversationPace',
    ];

    test('complete six-dimension result classifies and is ready', () {
      final qs = questionsFor(dims: allDims);
      final answers = {
        for (final q in qs) q.id: 5,
      };
      final result = FrequencyService.scoreAnswers(answers, qs);

      expect(result.canonicalProfileReady, isTrue);
      expect(result.status, FrequencyResult.statusCompleted);
      expect(result.missingDimensions, isEmpty);
      expect(result.vector.length, 6);
      expect(result.vector.values.every((v) => v == 1.0), isTrue);
      expect(result.scoreTotal, closeTo(100.0, 0.001));
      expect(result.type, isNotNull);
      expect(result.type, isNot('Incomplete Frequency'));
      expect(result.scoreTotal.isNaN, isFalse);
    });

    test('one missing dimension stays missing (no 0.5) and incomplete status',
        () {
      final qs = questionsFor(dims: allDims);
      final answers = <String, int>{};
      for (final q in qs) {
        if (q.dimension == 'depth') continue;
        answers[q.id] = 4;
      }

      final result = FrequencyService.scoreAnswers(answers, qs);
      expect(result.vector.containsKey('depth'), isFalse);
      expect(result.missingDimensions, contains('depth_preference'));
      expect(result.canonicalProfileReady, isFalse);
      expect(result.status, FrequencyResult.statusIncomplete);
      expect(result.type, isNull);
      expect(result.tags, isEmpty);
      expect(result.vector.values.contains(0.5), isFalse);
      expect(result.scoreTotal.isNaN, isFalse);
    });

    test('all dimensions missing => score 0, no division by zero', () {
      final qs = questionsFor(dims: allDims);
      final result = FrequencyService.scoreAnswers({}, qs);

      expect(result.vector, isEmpty);
      expect(result.missingDimensions.length, 6);
      expect(result.scoreTotal, 0.0);
      expect(result.scoreTotal.isNaN, isFalse);
      expect(result.canonicalProfileReady, isFalse);
      expect(result.status, FrequencyResult.statusIncomplete);
      expect(result.type, isNull);
    });

    test('FrequencyResult.toFirestore omits null type; incomplete uses status',
        () {
      const result = FrequencyResult(
        completed: true,
        scoreTotal: 40,
        vector: {'stability': 0.8},
        type: null,
        status: FrequencyResult.statusIncomplete,
        missingDimensions: ['depth_preference'],
        dimensionEvidenceCounts: {'stability': 2, 'depth': 0},
        canonicalProfileReady: false,
        completedAt: null,
      );
      final map = result.toFirestore();
      expect(map.containsKey('type'), isFalse);
      expect(map.containsKey('tags'), isFalse);
      expect(map['status'], FrequencyResult.statusIncomplete);
      expect(map['missing_dimensions'], ['depth_preference']);
      expect(map['canonical_profile_ready'], isFalse);
      expect(map['vector'], {'stability': 0.8});
      expect((map['vector'] as Map).containsKey('depth'), isFalse);
      expect(map.containsKey('score_total'), isFalse);
      expect(map['partial_score_total'], 40);
    });
  });

  group('Canonical dimension constants', () {
    test('exactly 4 + 10 + 6', () {
      expect(CanonicalDimensions.iq.length, 4);
      expect(CanonicalDimensions.eq.length, 10);
      expect(CanonicalDimensions.frequency.length, 6);
      expect(
        CanonicalDimensions.iq.length +
            CanonicalDimensions.eq.length +
            CanonicalDimensions.frequency.length,
        20,
      );
      expect(CanonicalDimensions.iq, isNot(contains('numerical')));
    });
  });
}
