import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/utils/compatibility_scoring.dart';
import 'package:qmatch/features/assessment/models/archetype_model.dart';
import 'package:qmatch/features/assessment/models/frequency_model.dart';
import 'package:qmatch/features/assessment/services/frequency_service.dart';
import 'package:qmatch/features/assessment/services/iq_recovery.dart';

/// P1B-1.1 — unknown IQ denominator, incomplete Frequency status, sparse match.
void main() {
  group('IqRecoveryResult denominator order', () {
    test('canonical IQ record with valid question_count', () {
      final r = IqRecoveryResult.fromSources(
        canonical: {
          'raw_score': 8,
          'question_count': 10,
          'set_id': 'iq_set_001',
        },
        assignment: {
          'completed': true,
          'score': 3,
          'question_order': List.generate(20, (i) => 'q$i'),
        },
        setMetadataQuestionCount: 15,
        userMirrorRawScore: 1,
      );
      expect(r.status, IqRecoveryResult.statusOk);
      expect(r.questionCount, 10);
      expect(r.rawScore, 8);
      expect(r.reasonCode, isNull);
    });

    test('assignment fallback with valid assigned question order count', () {
      final r = IqRecoveryResult.fromSources(
        canonical: {'raw_score': 7},
        assignment: {
          'completed': true,
          'score': 7,
          'question_order': ['a', 'b', 'c', 'd', 'e'],
        },
      );
      expect(r.status, IqRecoveryResult.statusOk);
      expect(r.questionCount, 5);
      expect(r.rawScore, 7);
    });

    test('set_id metadata fallback', () {
      final r = IqRecoveryResult.fromSources(
        canonical: {'raw_score': 6, 'set_id': 'iq_set_x'},
        assignment: {'completed': true, 'score': 6, 'set_id': 'iq_set_x'},
        setMetadataQuestionCount: 12,
      );
      expect(r.status, IqRecoveryResult.statusOk);
      expect(r.questionCount, 12);
      expect(r.rawScore, 6);
    });

    test('raw score exists but all denominator sources unavailable', () {
      final r = IqRecoveryResult.fromSources(
        canonical: {'raw_score': 9},
        assignment: {'completed': true, 'score': 9},
        setMetadataQuestionCount: null,
        userMirrorRawScore: 9,
      );
      expect(r.status, IqRecoveryResult.statusInsufficientMetadata);
      expect(r.reasonCode, IqRecoveryResult.reasonMissingIqQuestionCount);
      expect(r.rawScore, 9);
      expect(r.questionCount, isNull);
      expect(r.hasQuestionCount, isFalse);
    });

    test('question_count 0 is treated as unavailable (not a real denom)', () {
      final r = IqRecoveryResult.fromSources(
        canonical: {'raw_score': 4, 'question_count': 0},
      );
      expect(r.hasQuestionCount, isFalse);
      expect(r.status, IqRecoveryResult.statusInsufficientMetadata);
    });

    test('unknown denominator must not produce normalized IQ = 0 via calc', () {
      final r = IqRecoveryResult.fromSources(
        canonical: {'raw_score': 8},
      );
      expect(r.questionCount, isNull);
      // Callers must not pass 0: that would invent Low-band IQ.
      final fabricated = ArchetypeCalculator.normalizeScore(8, 0);
      expect(fabricated, 0); // documents the pitfall
      // Correct policy: skip normalize when count unknown.
      int? iqNormalized;
      if (r.hasQuestionCount) {
        iqNormalized =
            ArchetypeCalculator.normalizeScore(r.rawScore!, r.questionCount!);
      }
      expect(iqNormalized, isNull);
    });

    test('unknown denominator does not overwrite legacy persona payload', () {
      final existing = <String, dynamic>{
        'archetype': 'The Mastermind',
        'category': 'HH',
        'iq_normalized': 90,
      };
      final recovery = IqRecoveryResult.fromSources(
        canonical: {'raw_score': 2},
      );
      final writePersona = recovery.hasQuestionCount;
      final patch = <String, dynamic>{
        'eq_score': 5,
        'eq_normalized': 50,
        'iq_score': recovery.rawScore,
      };
      if (writePersona) {
        patch['archetype'] = 'The Executor';
        patch['category'] = 'LL';
        patch['iq_normalized'] = ArchetypeCalculator.normalizeScore(
          recovery.rawScore!,
          recovery.questionCount!,
        );
      }
      final merged = {...existing, ...patch};
      expect(merged['archetype'], 'The Mastermind');
      expect(merged['category'], 'HH');
      expect(merged['iq_normalized'], 90);
      expect(merged['iq_score'], 2);
    });

    test('user mirror supplies raw only, never denominator', () {
      final r = IqRecoveryResult.fromSources(
        userMirrorRawScore: 8,
        // No set metadata / assignment / canonical count.
      );
      expect(r.rawScore, 8);
      expect(r.questionCount, isNull);
      expect(r.status, IqRecoveryResult.statusInsufficientMetadata);
    });
  });

  group('Frequency incomplete is status not type', () {
    List<FrequencyQuestion> questionsFor(List<String> dims) {
      final out = <FrequencyQuestion>[];
      for (final d in dims) {
        out.add(FrequencyQuestion(id: '${d}_0', question: 'q', dimension: d));
        out.add(FrequencyQuestion(id: '${d}_1', question: 'q', dimension: d));
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

    test('complete result has a valid legacy type', () {
      final qs = questionsFor(allDims);
      final answers = {for (final q in qs) q.id: 5};
      final result = FrequencyService.scoreAnswers(answers, qs);
      expect(result.isComplete, isTrue);
      expect(result.type, isNotNull);
      expect(result.status, FrequencyResult.statusCompleted);
    });

    test('incomplete result has no type and is not classified', () {
      final qs = questionsFor(allDims);
      final answers = <String, int>{};
      for (final q in qs) {
        if (q.dimension == 'depth') continue;
        answers[q.id] = 5;
      }
      final result = FrequencyService.scoreAnswers(answers, qs);
      expect(result.type, isNull);
      expect(result.status, FrequencyResult.statusIncomplete);
      expect(result.tags, isEmpty);
      // Threshold classification must not run on incomplete evidence.
      expect(
        [
          'Deep Connector',
          'Social Spark',
          'Slow Burner',
          'Emotional Explorer',
          'Open Current',
          'Balanced Frequency',
          'Incomplete Frequency',
        ].contains(result.type),
        isFalse,
      );
    });

    test('incomplete attempt does not erase an existing valid user mirror', () {
      final existing = <String, dynamic>{
        'frequency_type': 'Deep Connector',
        'frequency_score': 88,
        'frequency_tags': ['deep_talker'],
        'frequency_completed': true,
      };
      final incomplete =
          FrequencyService.scoreAnswers({}, questionsFor(allDims));
      final patch = FrequencyService.buildUserMirrorFields(
        incomplete,
        language: 'en',
      );
      // Strip FieldValue for merge simulation.
      patch.remove('updated_at');
      final merged = {...existing, ...patch};
      expect(merged['frequency_type'], 'Deep Connector');
      expect(merged['frequency_score'], 88);
      expect(merged['frequency_tags'], ['deep_talker']);
      expect(patch.containsKey('frequency_type'), isFalse);
      expect(merged['frequency_status'], FrequencyResult.statusIncomplete);
      expect(merged['frequency_canonical_profile_ready'], isFalse);
    });

    test('serialization omits null type and empty tags', () {
      final map = const FrequencyResult(
        status: FrequencyResult.statusIncomplete,
        canonicalProfileReady: false,
        type: null,
        tags: [],
        scoreTotal: 12,
        vector: {'stability': 0.2},
      ).toFirestore();
      expect(map.containsKey('type'), isFalse);
      expect(map.containsKey('tags'), isFalse);
      expect(map['status'], 'incomplete');
    });
  });

  group('Sparse Frequency vector compatibility', () {
    Map<String, double> full({
      double depth = 0.5,
      double socialEnergy = 0.5,
      double spontaneity = 0.5,
      double stability = 0.5,
      double emotionalOpenness = 0.5,
      double conversationPace = 0.5,
    }) =>
        {
          'depth': depth,
          'socialEnergy': socialEnergy,
          'spontaneity': spontaneity,
          'stability': stability,
          'emotionalOpenness': emotionalOpenness,
          'conversationPace': conversationPace,
        };

    Map<String, dynamic> profile(Map<String, double>? vector) => {
          'category': 'MM',
          'iq_normalized': 50,
          'eq_normalized': 50,
          if (vector != null) 'frequency_vector': vector,
          'interests': <String>[],
          'last_active_at': DateTime.now(),
        };

    test('both users have all six Frequency dimensions', () {
      final r = CompatibilityScoring.frequencyVectorSimilarityDetailed(
        full(depth: 0.8),
        full(depth: 0.7),
      );
      expect(r.available, isTrue);
      expect(r.comparableDimensionCount, 6);
      expect(r.score, isNotNull);
      expect(r.score!.isNaN, isFalse);
    });

    test('users share five comparable dimensions', () {
      final a = full();
      final b = full();
      a.remove('conversationPace');
      b.remove('conversationPace');
      final r = CompatibilityScoring.frequencyVectorSimilarityDetailed(a, b);
      expect(r.comparableDimensionCount, 5);
      expect(r.available, isTrue);
      expect(r.score, isNotNull);
    });

    test('users share one comparable dimension => unavailable', () {
      final r = CompatibilityScoring.frequencyVectorSimilarityDetailed(
        {'depth': 0.8},
        {'depth': 0.2, 'stability': 0.5},
      );
      expect(r.comparableDimensionCount, 1);
      expect(r.available, isFalse);
      expect(r.score, isNull);
      expect(
          r.reason, CompatibilityScoring.reasonInsufficientFrequencyEvidence);
    });

    test('users share zero comparable dimensions', () {
      final r = CompatibilityScoring.frequencyVectorSimilarityDetailed(
        {'depth': 0.8},
        {'stability': 0.2},
      );
      expect(r.comparableDimensionCount, 0);
      expect(r.available, isFalse);
      expect(r.score, isNull);
    });

    test('no missing value becomes 0.5 or 0.42 as dimension filler', () {
      final r = CompatibilityScoring.calculateCompatibility(
        me: profile({'depth': 0.9, 'stability': 0.8}),
        candidate: profile({'depth': 0.1}),
      );
      expect(r.available, isFalse);
      expect(r.scoreTotal, isNull);
      expect(r.breakdown['frequency_vector'], isNull);
      // Shared dims only — never invent the four missing ones.
      final sim = CompatibilityScoring.frequencyVectorSimilarityDetailed(
        {'depth': 0.9, 'stability': 0.8},
        {'depth': 0.1},
      );
      expect(sim.comparableDimensionCount, 1);
      expect(sim.score, isNull);
    });

    test('no NaN or division by zero', () {
      final zero = CompatibilityScoring.frequencyVectorSimilarityDetailed(
        {},
        {},
      );
      expect(zero.score, isNull);
      expect(zero.available, isFalse);

      final fullSim = CompatibilityScoring.frequencyVectorSimilarityDetailed(
        full(),
        full(),
      );
      expect(fullSim.score!.isNaN, isFalse);
      expect(fullSim.score, 1.0);
    });

    test(
        'Discover ordering handles unavailable compatibility deterministically',
        () {
      final ordered = <({String id, double? score, int ts})>[
        (id: 'a', score: null, ts: 100),
        (id: 'b', score: 0.9, ts: 50),
        (id: 'c', score: 0.4, ts: 80),
        (id: 'd', score: null, ts: 200),
      ];
      ordered.sort((x, y) {
        return CompatibilityScoring.compareDiscoverCandidates(
          aScore: x.score,
          bScore: y.score,
          aLastActiveMs: x.ts,
          bLastActiveMs: y.ts,
        );
      });
      expect(ordered.map((e) => e.id).toList(), ['b', 'c', 'd', 'a']);
      // Never treat null as 0.5 (which would insert between 0.9 and 0.4).
      expect(ordered.first.score, 0.9);
      expect(ordered[1].score, 0.4);
      expect(ordered[2].score, isNull);
      expect(ordered[3].score, isNull);
    });
  });
}
