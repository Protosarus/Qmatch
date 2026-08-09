import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../models/assessment_progress.dart';
import '../models/frequency_model.dart';
import '../utils/assessment_language.dart';
import '../utils/assessment_localization_debug.dart';
import 'assessment_set_service.dart';
import 'canonical_assessment_persistence.dart';

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
        _assessmentSetService = assessmentSetService ??
            AssessmentSetService(auth: auth, firestore: firestore);

  static String _defaultLanguageCode() {
    try {
      return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    } catch (_) {
      return 'en';
    }
  }

  Future<
      ({
        List<FrequencyQuestion> questions,
        String setId,
        String contentVersion
      })> loadAssignedFrequencyAssessment({
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

    return (
      questions: mapped,
      setId: set.id,
      contentVersion:
          set.version.isNotEmpty ? set.version : 'content_legacy_2026_01',
    );
  }

  Future<List<FrequencyQuestion>> loadAssignedFrequencyQuestions({
    String? languageCode,
  }) async {
    final loaded = await loadAssignedFrequencyAssessment(
      languageCode: languageCode,
    );
    return loaded.questions;
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
        question:
            'Emotional honesty matters more to me than constant excitement.',
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
    return FrequencyService.scoreAnswers(answers, questions);
  }

  /// Pure Frequency aggregation — safe to call without Firebase.
  static FrequencyResult scoreAnswers(
    Map<String, int> answers,
    List<FrequencyQuestion> questions,
  ) {
    // Normalize: Likert 1..5 -> 0..1 using (score - 1) / 4.
    // P1B-1: missing dimensions stay missing (never invent 0.5).

    const legacyDims = <String>[
      'depth',
      'socialEnergy',
      'spontaneity',
      'stability',
      'emotionalOpenness',
      'conversationPace',
    ];

    final byDim = <String, List<double>>{};

    for (final q in questions) {
      final raw = answers[q.id];
      if (raw == null) continue;
      final clamped = raw.clamp(1, 5);
      final scored = q.reverseScored ? (6 - clamped) : clamped;
      final normalized = (scored - 1) / 4.0;
      (byDim[q.dimension] ??= []).add(normalized);
    }

    final vector = <String, double>{};
    final evidenceCounts = <String, int>{};
    final missingCanonical = <String>[];

    for (final d in legacyDims) {
      final list = byDim[d] ?? const <double>[];
      evidenceCounts[d] = list.length;
      final canonicalId =
          CanonicalDimensions.frequencyLegacyToCanonical[d] ?? d;
      if (list.isEmpty) {
        missingCanonical.add(canonicalId);
        continue;
      }
      vector[d] = list.reduce((a, b) => a + b) / list.length;
    }

    final presentScores = vector.values.toList();
    final scoreTotal = presentScores.isEmpty
        ? 0.0
        : (presentScores.reduce((a, b) => a + b) / presentScores.length) *
            100.0;

    final complete =
        missingCanonical.isEmpty && vector.length == legacyDims.length;

    // Do not classify a Frequency type from incomplete evidence.
    if (!complete) {
      return FrequencyResult(
        completed: true,
        scoreTotal: scoreTotal,
        vector: vector,
        type: null,
        tags: const [],
        completedAt: Timestamp.now(),
        answers: answers,
        missingDimensions: missingCanonical,
        dimensionEvidenceCounts: evidenceCounts,
        canonicalProfileReady: false,
        status: FrequencyResult.statusIncomplete,
      );
    }

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
      missingDimensions: const [],
      dimensionEvidenceCounts: evidenceCounts,
      canonicalProfileReady: true,
      status: FrequencyResult.statusCompleted,
    );
  }

  /// User-doc mirror fields. Incomplete attempts omit `frequency_type` so a
  /// valid stored type is not erased on merge.
  static Map<String, dynamic> buildUserMirrorFields(
    FrequencyResult result, {
    required String language,
  }) {
    final fields = <String, dynamic>{
      'frequency_vector': result.vector,
      'frequency_language_used': language,
      'frequency_canonical_profile_ready': result.canonicalProfileReady,
      'frequency_status': result.status,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (result.isComplete) {
      fields['frequency_completed'] = true;
      fields['frequency_type'] = result.type;
      fields['frequency_tags'] = result.tags;
      fields['frequency_score'] = result.scoreTotal;
      // Full battery complete — Discover/legacy gate (see AssessmentProgress).
      fields['assessment_flow_completed'] = true;
      fields['assessment_flow_version'] =
          AssessmentProgressSnapshot.flowVersionV2;
      fields['test_completed'] = true;
      fields['test_completed_at'] = FieldValue.serverTimestamp();
    }
    // Incomplete: do not write frequency_type / tags / score / flow flags.
    return fields;
  }

  Future<void> saveFrequencyResult(
    FrequencyResult result, {
    String? languageCode,
    String? localeUsed,
    String? setId,
    String? contentVersion,
  }) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final language =
        AssessmentLanguage.languageUsed(languageCode: languageCode);
    final locale =
        localeUsed ?? AssessmentLanguage.localeUsed(locale: Locale(language));

    final canonicalScores = <String, double>{};
    for (final e in result.vector.entries) {
      final canonical =
          CanonicalDimensions.frequencyLegacyToCanonical[e.key] ?? e.key;
      canonicalScores[canonical] = e.value;
    }

    final canonicalEvidence = <String, int>{};
    for (final e in result.dimensionEvidenceCounts.entries) {
      final canonical =
          CanonicalDimensions.frequencyLegacyToCanonical[e.key] ?? e.key;
      canonicalEvidence[canonical] = e.value;
    }
    for (final id in result.missingDimensions) {
      canonicalEvidence.putIfAbsent(id, () => 0);
    }

    final persistence = CanonicalAssessmentPersistence(
      auth: _auth,
      firestore: _firestore,
    );
    final assessmentFields = <String, dynamic>{
      ...result.toFirestore(),
      'assessment_version': CanonicalAssessmentVersions.assessmentVersion,
      'question_schema_version':
          CanonicalAssessmentVersions.questionSchemaVersion,
      'content_version': contentVersion ?? 'content_legacy_2026_01',
      'trait_scoring_version':
          CanonicalAssessmentVersions.traitScoringVersionFrequencyPartial,
      'normalization_version': CanonicalAssessmentVersions.normalizationVersion,
      'locale': locale,
      'language_used': language,
      if (setId != null && setId.isNotEmpty) 'set_id': setId,
      'assignment_ref': 'assessment_assignments/frequency',
      'question_count': result.answers?.length ?? 0,
      'answered_count': result.answers?.length ?? 0,
      'status': result.status,
      'completed_at': FieldValue.serverTimestamp(),
      'source': 'client_v1',
      'dimension_scores': canonicalScores,
      'dimension_evidence_counts': canonicalEvidence,
      'dimension_reliability': <String, dynamic>{},
      'missing_dimensions': result.missingDimensions,
      'canonical_profile_ready': result.canonicalProfileReady,
      'response_validity': {
        'rvi_version': CanonicalAssessmentVersions.rviVersion,
        'completion_ratio': 1.0,
        'straightlining_flag': false,
        'too_fast_flag': false,
        'inconsistency_flag': false,
        'quality_band': 'unknown',
      },
    };
    // Ensure incomplete never persists a synthetic type key.
    if (!result.isComplete) {
      assessmentFields.remove('type');
      assessmentFields.remove('tags');
    }

    await persistence.upsertCompletedAssessment(
      assessmentType: 'frequency',
      fields: assessmentFields,
    );

    // Lightweight user mirrors only (not full evidence maps).
    await _firestore.collection('users').doc(me.uid).set(
          buildUserMirrorFields(result, language: language),
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
