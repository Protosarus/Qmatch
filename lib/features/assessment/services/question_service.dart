import 'package:flutter/foundation.dart';

import '../models/assessment_set_model.dart';
import '../models/question_model.dart';
import 'assessment_set_service.dart';

class QuestionService {
  final AssessmentSetService _assessmentSetService;

  QuestionService({AssessmentSetService? assessmentSetService})
      : _assessmentSetService =
            assessmentSetService ?? AssessmentSetService();

  Future<List<QuestionModel>> loadIQQuestions() async {
    try {
      final set = await _assessmentSetService.getOrAssignSet(type: 'iq');
      return _mapQuestions(set);
    } catch (e, st) {
      debugPrint('❌ Error loading IQ assessment set: $e\n$st');
      return [];
    }
  }

  Future<List<QuestionModel>> getRandomIQQuestions({int count = 10}) async {
    final allQuestions = await loadIQQuestions();
    if (allQuestions.isEmpty) return [];
    if (allQuestions.length <= count) {
      return allQuestions;
    }
    return allQuestions.sublist(0, count);
  }

  Future<List<QuestionModel>> loadEQQuestions() async {
    try {
      final set = await _assessmentSetService.getOrAssignSet(type: 'eq');
      return _mapQuestions(set);
    } catch (e, st) {
      debugPrint('❌ Error loading EQ assessment set: $e\n$st');
      return [];
    }
  }

  Future<List<QuestionModel>> getRandomEQQuestions({int count = 10}) async {
    final allQuestions = await loadEQQuestions();
    if (allQuestions.isEmpty) return [];
    if (allQuestions.length <= count) {
      return allQuestions;
    }
    // Preserve assignment question_order (Step 14); do not reshuffle here.
    return allQuestions.sublist(0, count);
  }

  List<QuestionModel> _mapQuestions(AssessmentSetModel set) {
    return set.questions
        .map((m) => QuestionModel.fromJson(m))
        .toList();
  }
}
