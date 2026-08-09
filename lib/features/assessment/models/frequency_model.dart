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
    final questionRaw =
        json.containsKey('text') ? json['text'] : json['question'];

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
  static const statusCompleted = 'completed';
  static const statusIncomplete = 'incomplete';

  final bool completed;

  /// Partial mean over present dims only; not a complete Frequency score when
  /// [status] is [statusIncomplete].
  final double scoreTotal;
  final Map<String, double> vector; // legacy keys; only present dims
  /// Legacy Frequency type — null when incomplete (never "Incomplete Frequency").
  final String? type;
  final List<String> tags;
  final Timestamp? completedAt;
  final Map<String, int>? answers; // optional raw answers (1..5)
  /// Canonical Frequency dimension IDs lacking evidence.
  final List<String> missingDimensions;

  /// Legacy dimension key → evidence item count.
  final Map<String, int> dimensionEvidenceCounts;

  /// True only when all 6 Frequency dimensions have evidence.
  final bool canonicalProfileReady;

  /// [statusCompleted] or [statusIncomplete] — incomplete is a status, not a type.
  final String status;

  const FrequencyResult({
    this.completed = false,
    this.scoreTotal = 0,
    this.vector = const {},
    this.type,
    this.tags = const [],
    this.completedAt,
    this.answers,
    this.missingDimensions = const [],
    this.dimensionEvidenceCounts = const {},
    this.canonicalProfileReady = false,
    this.status = statusIncomplete,
  });

  bool get isComplete =>
      status == statusCompleted && canonicalProfileReady && type != null;

  factory FrequencyResult.fromFirestore(Map<String, dynamic> data) {
    final vectorRaw = (data['vector'] as Map?)?.cast<String, dynamic>() ??
        (data['frequency_vector'] as Map?)?.cast<String, dynamic>() ??
        const {};
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

    final missingRaw = data['missing_dimensions'];
    final missing = missingRaw is List
        ? missingRaw.map((e) => e.toString()).toList()
        : const <String>[];

    final evidenceRaw = data['dimension_evidence_counts'];
    final evidence = <String, int>{};
    if (evidenceRaw is Map) {
      for (final e in evidenceRaw.entries) {
        if (e.value is num) {
          evidence[e.key.toString()] = (e.value as num).toInt();
        }
      }
    }

    final rawType =
        (data['type'] as String?) ?? (data['frequency_type'] as String?);
    // Never treat the UI status phrase as a stored type.
    final type = (rawType == null ||
            rawType.isEmpty ||
            rawType == 'Incomplete Frequency')
        ? null
        : rawType;

    final statusRaw = data['status'] as String?;
    final status = statusRaw == statusCompleted || statusRaw == statusIncomplete
        ? statusRaw!
        : (missing.isNotEmpty || type == null
            ? statusIncomplete
            : statusCompleted);

    final ready = data['canonical_profile_ready'] as bool? ??
        (status == statusCompleted && missing.isEmpty && vector.length == 6);

    return FrequencyResult(
      completed: data['completed'] as bool? ?? false,
      scoreTotal: (data['scoreTotal'] as num?)?.toDouble() ??
          (data['score_total'] as num?)?.toDouble() ??
          (data['legacy_score_total'] as num?)?.toDouble() ??
          0,
      vector: vector,
      type: type,
      tags: List<String>.from(
        data['tags'] ?? data['frequency_tags'] ?? const [],
      ),
      completedAt: (data['completedAt'] is Timestamp
              ? data['completedAt'] as Timestamp
              : null) ??
          (data['completed_at'] is Timestamp
              ? data['completed_at'] as Timestamp
              : null),
      answers: answers,
      missingDimensions: missing,
      dimensionEvidenceCounts: evidence,
      canonicalProfileReady: ready,
      status: status,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'completed': completed,
      'status': status,
      // Present-dim mean only; incomplete must not be read as a finished score.
      if (status == statusCompleted) 'score_total': scoreTotal,
      if (status == statusCompleted) 'legacy_score_total': scoreTotal,
      if (status == statusIncomplete) 'partial_score_total': scoreTotal,
      'vector': vector,
      if (type != null) 'type': type,
      if (tags.isNotEmpty) 'tags': tags,
      'completed_at': completedAt,
      'missing_dimensions': missingDimensions,
      'dimension_evidence_counts': dimensionEvidenceCounts,
      'canonical_profile_ready': canonicalProfileReady,
      if (answers != null) 'answers': answers,
    };
  }
}
