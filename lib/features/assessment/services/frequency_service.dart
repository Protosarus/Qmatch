import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../models/frequency_model.dart';
import '../utils/assessment_language.dart';
import '../utils/assessment_localization_debug.dart';
import 'assessment_set_service.dart';

class FrequencyService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AssessmentSetService _assessmentSetService;

  FrequencyService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    AssessmentSetService? assessmentSetService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _assessmentSetService =
            assessmentSetService ?? AssessmentSetService(auth: auth, firestore: firestore);

  static String _defaultLanguageCode() {
    try {
      return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    } catch (_) {
      return 'en';
    }
  }

  Future<List<FrequencyQuestion>> loadAssignedFrequencyQuestions({
    String? languageCode,
  }) async {
    final lang = languageCode ?? _defaultLanguageCode();
    final set = await _assessmentSetService.getOrAssignSet(
      type: 'frequency',
      languageCode: lang,
      localeUsed: AssessmentLanguage.localeUsed(locale: Locale(lang)),
    );
    final mapped = set.questions
        .map(
          (m) => FrequencyQuestion.fromJson(
            m,
            languageCode: lang,
          ),
        )
        .toList();

    if (mapped.isNotEmpty) {
      AssessmentLocalizationDebug.logMappedQuestions(
        type: set.type,
        setId: set.id,
        languageCode: lang,
        rawQuestions: set.questions,
        resolvedFirstQuestion: mapped.first.question,
      );
    }

    return mapped;
  }

  List<FrequencyQuestion> getFrequencyQuestions() {
    // 12 questions: 6 dimensions x 2 each.
    return const [
      FrequencyQuestion(
        id: 'q1',
        question: 'I prefer deep conversations over small talk.',
        dimension: 'depth',
      ),
      FrequencyQuestion(
        id: 'q2',
        question: 'I connect faster when conversations are meaningful.',
        dimension: 'depth',
      ),
      FrequencyQuestion(
        id: 'q3',
        question: 'I enjoy playful and energetic conversations.',
        dimension: 'socialEnergy',
      ),
      FrequencyQuestion(
        id: 'q4',
        question: 'I feel drained by too much social intensity.',
        dimension: 'socialEnergy',
        reverseScored: true,
      ),
      FrequencyQuestion(
        id: 'q5',
        question: 'I enjoy spontaneous plans.',
        dimension: 'spontaneity',
      ),
      FrequencyQuestion(
        id: 'q6',
        question: 'I prefer slow-building attraction over instant intensity.',
        dimension: 'spontaneity',
        reverseScored: true,
      ),
      FrequencyQuestion(
        id: 'q7',
        question: 'I prefer stable and intentional relationships.',
        dimension: 'stability',
      ),
      FrequencyQuestion(
        id: 'q8',
        question: 'I need consistency to feel safe.',
        dimension: 'stability',
      ),
      FrequencyQuestion(
        id: 'q9',
        question: 'I can express what I feel clearly.',
        dimension: 'emotionalOpenness',
      ),
      FrequencyQuestion(
        id: 'q10',
        question: 'Emotional honesty matters more to me than constant excitement.',
        dimension: 'emotionalOpenness',
      ),
      FrequencyQuestion(
        id: 'q11',
        question: 'I like frequent communication when I feel connected.',
        dimension: 'conversationPace',
      ),
      FrequencyQuestion(
        id: 'q12',
        question: 'I need time before I fully trust someone.',
        dimension: 'conversationPace',
        reverseScored: true,
      ),
    ];
  }

  FrequencyResult calculateResult(
    Map<String, int> answers,
    List<FrequencyQuestion> questions,
  ) {
    // Normalize: Likert 1..5 -> 0..1 using (score - 1) / 4.

    final byDim = <String, List<double>>{};

    for (final q in questions) {
      final raw = answers[q.id];
      if (raw == null) continue;
      final clamped = raw.clamp(1, 5);
      final scored = q.reverseScored ? (6 - clamped) : clamped;
      final normalized = (scored - 1) / 4.0;
      (byDim[q.dimension] ??= []).add(normalized);
    }

    double dimAvg(String d) {
      final list = byDim[d] ?? const <double>[];
      if (list.isEmpty) return 0.5;
      return list.reduce((a, b) => a + b) / list.length;
    }

    final vector = <String, double>{
      'depth': dimAvg('depth'),
      'socialEnergy': dimAvg('socialEnergy'),
      'spontaneity': dimAvg('spontaneity'),
      'stability': dimAvg('stability'),
      'emotionalOpenness': dimAvg('emotionalOpenness'),
      'conversationPace': dimAvg('conversationPace'),
    };

    final scoreTotal = (vector.values.reduce((a, b) => a + b) / vector.length) * 100.0;

    final depth = vector['depth']!;
    final socialEnergy = vector['socialEnergy']!;
    final spontaneity = vector['spontaneity']!;
    final stability = vector['stability']!;
    final emotionalOpenness = vector['emotionalOpenness']!;
    final conversationPace = vector['conversationPace']!;

    String type;
    if (depth >= 0.75 && stability >= 0.65) {
      type = 'Deep Connector';
    } else if (socialEnergy >= 0.70 && spontaneity >= 0.60) {
      type = 'Social Spark';
    } else if (stability >= 0.75 && conversationPace <= 0.55) {
      type = 'Slow Burner';
    } else if (emotionalOpenness >= 0.75 && depth >= 0.60) {
      type = 'Emotional Explorer';
    } else if (spontaneity >= 0.70 && emotionalOpenness >= 0.60) {
      type = 'Open Current';
    } else {
      type = 'Balanced Frequency';
    }

    final tags = <String>[];
    if (depth >= 0.70) tags.add('deep_talker');
    if (socialEnergy >= 0.70) tags.add('social_energy');
    if (spontaneity >= 0.70) tags.add('spontaneous');
    if (stability >= 0.70) tags.add('stability_first');
    if (emotionalOpenness >= 0.70) tags.add('emotionally_open');
    if (conversationPace <= 0.45) tags.add('slow_bond');
    if (conversationPace >= 0.70) tags.add('fast_connection');

    return FrequencyResult(
      completed: true,
      scoreTotal: scoreTotal,
      vector: vector,
      type: type,
      tags: tags,
      completedAt: Timestamp.now(),
      answers: answers,
    );
  }

  Future<void> saveFrequencyResult(
    FrequencyResult result, {
    String? languageCode,
    String? localeUsed,
  }) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final language = AssessmentLanguage.languageUsed(languageCode: languageCode);
    final locale = localeUsed ??
        AssessmentLanguage.localeUsed(locale: Locale(language));

    final doc = _firestore
        .collection('users')
        .doc(me.uid)
        .collection('assessments')
        .doc('frequency');

    await doc.set(
      {
        ...result.toFirestore(),
        'completed_at': FieldValue.serverTimestamp(),
        'language_used': language,
        'locale_used': locale,
      },
      SetOptions(merge: true),
    );

    await _firestore.collection('users').doc(me.uid).set(
      {
        'frequency_completed': true,
        'frequency_type': result.type,
        'frequency_score': result.scoreTotal,
        'frequency_tags': result.tags,
        // Cold-start Discover needs 6D vector without N+1 assessment reads.
        // Additive mirror only — does not change Frequency scoring.
        'frequency_vector': result.vector,
        'frequency_language_used': language,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<FrequencyResult?> getMyFrequencyResult() async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final doc = await _firestore
        .collection('users')
        .doc(me.uid)
        .collection('assessments')
        .doc('frequency')
        .get();

    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return FrequencyResult.fromFirestore(data);
  }
}
