import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/localized_text_resolver.dart';

class FrequencyQuestion {
  final String id;
  final String question;
  final String dimension;
  final bool reverseScored;
  /// Display labels (localized when content provides maps; else legacy/default).
  final List<String> options;

  const FrequencyQuestion({
    required this.id,
    required this.question,
    required this.dimension,
    this.reverseScored = false,
    this.options = const [
      'Strongly disagree',
      'Disagree',
      'Neutral',
      'Agree',
      'Strongly agree',
    ],
  });

  static const List<String> _defaultLikert = [
    'Strongly disagree',
    'Disagree',
    'Neutral',
    'Agree',
    'Strongly agree',
  ];

  factory FrequencyQuestion.fromJson(
    Map<String, dynamic> json, {
    String languageCode = 'en',
  }) {
    final questionRaw = json.containsKey('text')
        ? json['text']
        : json['question'];

    final optsRaw = json['options'];
    List<String> options;
    if (optsRaw is List && optsRaw.isNotEmpty) {
      options = LocalizedTextResolver.resolveOptionLabels(
        optsRaw,
        languageCode: languageCode,
      );
      // Ensure we always have 5 Likert slots for scoring UI (values 1..5).
      if (options.length < 5) {
        options = [
          ...options,
          ..._defaultLikert.skip(options.length),
        ];
      }
    } else {
      options = List<String>.from(_defaultLikert);
    }

    return FrequencyQuestion(
      id: json['id'] as String? ?? '',
      question: LocalizedTextResolver.resolve(
        questionRaw,
        languageCode: languageCode,
      ),
      dimension: json['dimension'] as String? ?? '',
      reverseScored: json['reverseScored'] as bool? ?? false,
      options: options,
    );
  }
}

class FrequencyAnswer {
  final String questionId;
  final int value; // 1..5

  const FrequencyAnswer({
    required this.questionId,
    required this.value,
  });
}

class FrequencyResult {
  final bool completed;
  final double scoreTotal; // 0..100
  final Map<String, double> vector; // 0..1 per dimension
  final String type;
  final List<String> tags;
  final Timestamp? completedAt;
  final Map<String, int>? answers; // optional raw answers (1..5)

  const FrequencyResult({
    this.completed = false,
    this.scoreTotal = 0,
    this.vector = const {},
    this.type = 'Balanced Frequency',
    this.tags = const [],
    this.completedAt,
    this.answers,
  });

  factory FrequencyResult.fromFirestore(Map<String, dynamic> data) {
    final vectorRaw =
        (data['vector'] as Map?)?.cast<String, dynamic>() ?? const {};
    final vector = <String, double>{};
    for (final e in vectorRaw.entries) {
      final v = e.value;
      if (v is num) vector[e.key] = v.toDouble();
    }

    final answersRaw = (data['answers'] as Map?)?.cast<String, dynamic>();
    Map<String, int>? answers;
    if (answersRaw != null) {
      answers = <String, int>{};
      for (final e in answersRaw.entries) {
        final v = e.value;
        if (v is num) answers[e.key] = v.toInt();
      }
    }

    return FrequencyResult(
      completed: data['completed'] as bool? ?? false,
      scoreTotal: (data['scoreTotal'] as num?)?.toDouble() ??
          (data['score_total'] as num?)?.toDouble() ??
          0,
      vector: vector,
      type: (data['type'] as String?) ??
          (data['frequency_type'] as String?) ??
          'Balanced Frequency',
      tags: List<String>.from(
        data['tags'] ?? data['frequency_tags'] ?? const [],
      ),
      completedAt:
          (data['completedAt'] is Timestamp
              ? data['completedAt'] as Timestamp
              : null) ??
          (data['completed_at'] is Timestamp
              ? data['completed_at'] as Timestamp
              : null),
      answers: answers,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'completed': completed,
      'score_total': scoreTotal,
      'vector': vector,
      'type': type,
      'tags': tags,
      'completed_at': completedAt,
      if (answers != null) 'answers': answers,
    };
  }
}
