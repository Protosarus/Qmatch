import '../utils/localized_text_resolver.dart';

class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  /// Index into [options] after any assignment option remapping.
  final int correctAnswer;
  final int difficulty;

  /// Optional stable option value IDs from future format `{ value, label }`.
  /// Parallel to [options] when present; used only for future scoring identity.
  /// Null/empty entries mean "score by index" (legacy).
  final List<String?>? optionValues;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    this.optionValues,
  });

  /// Parses both legacy and future localized JSON.
  ///
  /// Legacy:
  /// ```json
  /// { "question": "...", "options": ["A","B"], "correctAnswer": 0 }
  /// ```
  ///
  /// Future:
  /// ```json
  /// {
  ///   "text": { "en": "...", "tr": "..." },
  ///   "options": [{ "value": "a", "label": { "en": "...", "tr": "..." } }],
  ///   "correctAnswer": 0
  /// }
  /// ```
  factory QuestionModel.fromJson(
    Map<String, dynamic> json, {
    String languageCode = 'en',
  }) {
    final id = json['id']?.toString().trim() ?? '';
    if (id.isEmpty) {
      throw FormatException('QuestionModel.fromJson requires non-empty id');
    }

    final questionRaw = json.containsKey('text')
        ? json['text']
        : json['question'];
    final question = LocalizedTextResolver.resolve(
      questionRaw,
      languageCode: languageCode,
    );

    final optionsRaw = json['options'];
    final options = LocalizedTextResolver.resolveOptionLabels(
      optionsRaw,
      languageCode: languageCode,
    );

    List<String?>? optionValues;
    if (optionsRaw is List && optionsRaw.isNotEmpty) {
      final values = optionsRaw
          .map(LocalizedTextResolver.optionValueId)
          .toList();
      if (values.any((v) => v != null)) {
        optionValues = values;
      }
    }

    return QuestionModel(
      id: id,
      question: question,
      options: options,
      correctAnswer: (json['correctAnswer'] as num?)?.toInt() ?? 0,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 0,
      optionValues: optionValues,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty,
      if (optionValues != null) 'optionValues': optionValues,
    };
  }
}
