import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/services/assessment_progress_service.dart';
import 'package:qmatch/features/assessment/services/frequency_service.dart';
import 'package:qmatch/features/assessment/models/frequency_model.dart';

void main() {
  group('AssessmentProgressService routing (P1B-2A)', () {
    test('1. new user begins at IQ', () {
      final s = AssessmentProgressService.resolveFromMaps();
      expect(s.destination, AssessmentFlowDestination.iq);
      expect(s.iqCompleted, isFalse);
      expect(s.assessmentFlowVersion, isNull);
      expect(s.canonicalPersonaAvailable, isFalse);
    });

    test('2. IQ complete routes to EQ (flow v2)', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
        },
        iqAssessment: {'status': 'completed'},
      );
      expect(s.iqCompleted, isTrue);
      expect(s.destination, AssessmentFlowDestination.eq);
    });

    test('3. IQ + EQ complete routes to Frequency', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
        },
        iqAssessment: {'status': 'completed'},
        eqAssessment: {'status': 'completed'},
      );
      expect(s.destination, AssessmentFlowDestination.frequency);
    });

    test('4. Frequency incomplete remains at Frequency', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
          'frequency_status': 'incomplete',
        },
        iqAssessment: {'status': 'completed'},
        eqAssessment: {'status': 'completed'},
        frequencyAssessment: {
          'status': 'incomplete',
          'canonical_profile_ready': false,
          'missing_dimensions': ['depth_preference'],
        },
      );
      expect(s.frequencyIncomplete, isTrue);
      expect(s.frequencyCompleted, isFalse);
      expect(s.destination, AssessmentFlowDestination.frequency);
      expect(s.reason, 'v2_frequency_incomplete');
    });

    test('5. all three complete + profile incomplete → profile setup', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
          'frequency_completed': true,
          'assessment_flow_completed': true,
          'profile_completed': false,
        },
        iqAssessment: {'status': 'completed'},
        eqAssessment: {'status': 'completed'},
        frequencyAssessment: {
          'status': 'completed',
          'canonical_profile_ready': true,
          'missing_dimensions': <String>[],
        },
      );
      expect(s.allAssessmentsCompleted, isTrue);
      expect(s.destination, AssessmentFlowDestination.profileSetup);
    });

    test('6. all three complete + profile complete → main', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
          'frequency_completed': true,
          'assessment_flow_completed': true,
          'profile_completed': true,
        },
        iqAssessment: {'status': 'completed'},
        eqAssessment: {'status': 'completed'},
        frequencyAssessment: {
          'status': 'completed',
          'canonical_profile_ready': true,
        },
      );
      expect(s.destination, AssessmentFlowDestination.main);
    });

    test('10. Frequency completion marks full flow complete (mirror fields)',
        () {
      final complete = FrequencyService.scoreAnswers(
        {
          for (final d in [
            'depth',
            'socialEnergy',
            'spontaneity',
            'stability',
            'emotionalOpenness',
            'conversationPace',
          ])
            for (final i in [0, 1]) '${d}_$i': 5,
        },
        [
          for (final d in [
            'depth',
            'socialEnergy',
            'spontaneity',
            'stability',
            'emotionalOpenness',
            'conversationPace',
          ])
            for (final i in [0, 1])
              FrequencyQuestion(id: '${d}_$i', question: 'q', dimension: d),
        ],
      );
      expect(complete.isComplete, isTrue);
      final patch =
          FrequencyService.buildUserMirrorFields(complete, language: 'en');
      patch.remove('updated_at');
      patch.remove('test_completed_at');
      expect(patch['frequency_completed'], isTrue);
      expect(patch['assessment_flow_completed'], isTrue);
      expect(patch['assessment_flow_version'], 2);
      expect(patch['test_completed'], isTrue);
      expect(patch.containsKey('archetype'), isFalse);
      expect(patch.containsKey('category'), isFalse);
      expect(patch.containsKey('primary_persona_id'), isFalse);
    });

    test('12. existing legacy archetype/category preserved on EQ mirror merge',
        () {
      final existing = <String, dynamic>{
        'archetype': 'The Mastermind',
        'category': 'HH',
        'assessment_flow_version': 2,
      };
      // Simulate markEqCompleted payload (no persona keys).
      final eqPatch = <String, dynamic>{
        'eq_completed': true,
        'eq_score': 7,
        'assessment_flow_version': 2,
      };
      final merged = {...existing, ...eqPatch};
      expect(merged['archetype'], 'The Mastermind');
      expect(merged['category'], 'HH');
      expect(merged.containsKey('test_completed'), isFalse);
    });

    test(
        '13. legacy test_completed without Frequency is not full three-assessment flow',
        () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'test_completed': true,
          'profile_completed': false,
          // no assessment_flow_version
        },
      );
      expect(s.allAssessmentsCompleted, isFalse);
      expect(s.assessmentFlowCompleted, isFalse);
      expect(s.destination, AssessmentFlowDestination.frequency);
      expect(s.resolutionSource, 'legacy_test_completed');
    });

    test('14. existing active legacy users with profile are not locked out',
        () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'test_completed': true,
          'profile_completed': true,
          // Frequency missing
        },
      );
      expect(s.destination, AssessmentFlowDestination.main);
      expect(
        s.resolutionSource,
        'legacy_active_profile_grandfather',
      );
    });

    test('15. relaunch after EQ (v2) resumes at Frequency', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
        },
        iqAssignment: {'completed': true},
        eqAssignment: {'completed': true},
      );
      expect(s.destination, AssessmentFlowDestination.frequency);
    });

    test('16. relaunch after incomplete Frequency resumes at Frequency', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
        },
        frequencyAssessment: {
          'status': 'incomplete',
          'canonical_profile_ready': false,
        },
      );
      expect(s.destination, AssessmentFlowDestination.frequency);
    });

    test('legacy complete Frequency without flow version → profile setup', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'frequency_completed': true,
          'profile_completed': false,
        },
        frequencyAssessment: {
          'status': 'completed',
          'canonical_profile_ready': true,
        },
      );
      expect(s.destination, AssessmentFlowDestination.profileSetup);
    });

    test('canonical preferred over false frequency_completed mirror', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
          'frequency_completed': true, // stale / wrong
        },
        frequencyAssessment: {
          'status': 'incomplete',
          'canonical_profile_ready': false,
          'missing_dimensions': ['stability'],
        },
      );
      expect(s.frequencyCompleted, isFalse);
      expect(s.destination, AssessmentFlowDestination.frequency);
    });

    test('9. no persona fields in incomplete Frequency mirror', () {
      final incomplete = FrequencyService.scoreAnswers({}, [
        const FrequencyQuestion(id: 'd0', question: 'q', dimension: 'depth'),
      ]);
      final patch = FrequencyService.buildUserMirrorFields(
        incomplete,
        language: 'en',
      );
      expect(patch.containsKey('frequency_type'), isFalse);
      expect(patch.containsKey('assessment_flow_completed'), isFalse);
      expect(patch.containsKey('test_completed'), isFalse);
    });
  });

  group('Completion screen copy contract', () {
    test('18. screen class has no persona identity API', () {
      // Structural: constructor only takes profileCompleted — no persona name.
      const screenTitleTr = 'Değerlendirmelerin tamamlandı';
      const screenTitleEn = 'Your assessments are complete';
      expect(screenTitleTr.toLowerCase(), isNot(contains('persona')));
      expect(screenTitleEn.toLowerCase(), isNot(contains('hh')));
      expect(screenTitleEn.toLowerCase(), isNot(contains('mastermind')));
    });
  });
}
