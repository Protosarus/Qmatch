import 'package:flutter/widgets.dart';

import '../models/assessment_set_model.dart';
import '../models/question_model.dart';
import '../utils/assessment_localization_debug.dart';
import 'assessment_set_service.dart';

/// Assigned MCQ set + localized questions (IQ/EQ).
class LoadedMcqAssessment {
  final AssessmentSetModel set;
  final List<QuestionModel> questions;

  const LoadedMcqAssessment({
    required this.set,
    required this.questions,
  });
}

class QuestionService {
  final AssessmentSetService _assessmentSetService;

  QuestionService({AssessmentSetService? assessmentSetService})
      : _assessmentSetService = assessmentSetService ?? AssessmentSetService();

  static String _defaultLanguageCode() {
    try {
      return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    } catch (_) {
      return 'en';
    }
  }

  Future<LoadedMcqAssessment> loadIQAssessment({
    String? languageCode,
  }) async {
    final lang = languageCode ?? _defaultLanguageCode();
    try {
      final set = await _assessmentSetService.getOrAssignSet(
        type: 'iq',
        languageCode: lang,
      );
      return LoadedMcqAssessment(
        set: set,
        questions: _mapQuestions(set, languageCode: lang),
      );
    } catch (e, st) {
      debugPrint('❌ Error loading IQ assessment set: $e\n$st');
      return const LoadedMcqAssessment(
        set: AssessmentSetModel(id: '', type: 'iq'),
        questions: [],
      );
    }
  }

  Future<List<QuestionModel>> loadIQQuestions({
    String? languageCode,
  }) async {
    return (await loadIQAssessment(languageCode: languageCode)).questions;
  }

  Future<List<QuestionModel>> getRandomIQQuestions({
    int count = 10,
    String? languageCode,
  }) async {
    final loaded = await loadIQAssessment(languageCode: languageCode);
    final allQuestions = loaded.questions;
    if (allQuestions.isEmpty) return [];
    if (allQuestions.length <= count) {
      return allQuestions;
    }
    return allQuestions.sublist(0, count);
  }

  Future<LoadedMcqAssessment> loadEQAssessment({
    String? languageCode,
  }) async {
    final lang = languageCode ?? _defaultLanguageCode();
    try {
      final set = await _assessmentSetService.getOrAssignSet(
        type: 'eq',
        languageCode: lang,
      );
      return LoadedMcqAssessment(
        set: set,
        questions: _mapQuestions(set, languageCode: lang),
      );
    } catch (e, st) {
      debugPrint('❌ Error loading EQ assessment set: $e\n$st');
      return const LoadedMcqAssessment(
        set: AssessmentSetModel(id: '', type: 'eq'),
        questions: [],
      );
    }
  }

  Future<List<QuestionModel>> loadEQQuestions({
    String? languageCode,
  }) async {
    return (await loadEQAssessment(languageCode: languageCode)).questions;
  }

  Future<List<QuestionModel>> getRandomEQQuestions({
    int count = 10,
    String? languageCode,
  }) async {
    final loaded = await loadEQAssessment(languageCode: languageCode);
    final allQuestions = loaded.questions;
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
