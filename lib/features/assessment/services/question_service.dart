import 'package:flutter/widgets.dart';

import '../models/assessment_set_model.dart';
import '../models/question_model.dart';
import '../utils/assessment_localization_debug.dart';
import 'assessment_set_service.dart';

class QuestionService {
  final AssessmentSetService _assessmentSetService;

  QuestionService({AssessmentSetService? assessmentSetService})
      : _assessmentSetService =
            assessmentSetService ?? AssessmentSetService();

  static String _defaultLanguageCode() {
    try {
      return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    } catch (_) {
      return 'en';
    }
  }

  Future<List<QuestionModel>> loadIQQuestions({
    String? languageCode,
  }) async {
    try {
      final set = await _assessmentSetService.getOrAssignSet(
        type: 'iq',
        languageCode: languageCode ?? _defaultLanguageCode(),
      );
      return _mapQuestions(
        set,
        languageCode: languageCode ?? _defaultLanguageCode(),
      );
    } catch (e, st) {
      debugPrint('❌ Error loading IQ assessment set: $e\n$st');
      return [];
    }
  }

  Future<List<QuestionModel>> getRandomIQQuestions({
    int count = 10,
    String? languageCode,
  }) async {
    final allQuestions = await loadIQQuestions(languageCode: languageCode);
    if (allQuestions.isEmpty) return [];
    if (allQuestions.length <= count) {
      return allQuestions;
    }
    return allQuestions.sublist(0, count);
  }

  Future<List<QuestionModel>> loadEQQuestions({
    String? languageCode,
  }) async {
    try {
      final set = await _assessmentSetService.getOrAssignSet(
        type: 'eq',
        languageCode: languageCode ?? _defaultLanguageCode(),
      );
      return _mapQuestions(
        set,
        languageCode: languageCode ?? _defaultLanguageCode(),
      );
    } catch (e, st) {
      debugPrint('❌ Error loading EQ assessment set: $e\n$st');
      return [];
    }
  }

  Future<List<QuestionModel>> getRandomEQQuestions({
    int count = 10,
    String? languageCode,
  }) async {
    final allQuestions = await loadEQQuestions(languageCode: languageCode);
    if (allQuestions.isEmpty) return [];
    if (allQuestions.length <= count) {
      return allQuestions;
    }
    // Preserve assignment question_order; do not reshuffle here.
    return allQuestions.sublist(0, count);
  }

  List<QuestionModel> _mapQuestions(
    AssessmentSetModel set, {
    required String languageCode,
  }) {
    final mapped = set.questions
        .map(
          (m) => QuestionModel.fromJson(
            m,
            languageCode: languageCode,
          ),
        )
        .toList();

    if (mapped.isNotEmpty) {
      AssessmentLocalizationDebug.logMappedQuestions(
        type: set.type,
        setId: set.id,
        languageCode: languageCode,
        rawQuestions: set.questions,
        resolvedFirstQuestion: mapped.first.question,
      );
    }

    return mapped;
  }
}
