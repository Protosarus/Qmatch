/// Explicit option object for canonical IQ items.
class IqOption {
  const IqOption({
    required this.id,
    required this.text,
  });

  final String id;
  final String text;

  factory IqOption.fromJson(Map<String, dynamic> json) {
    return IqOption(
      id: json['id'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
      };
}

/// Runtime-neutral canonical IQ item model (does not replace live QuestionModel).
class IqCanonicalItem {
  const IqCanonicalItem({
    required this.id,
    required this.schemaVersion,
    required this.bankVersion,
    required this.locale,
    required this.dimension,
    required this.subskill,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    required this.rationale,
    required this.difficultyBand,
    required this.estimatedTimeSeconds,
    required this.languageDependency,
    required this.cognitiveLoad,
    required this.answerOrderPolicy,
    required this.status,
    required this.source,
    required this.reviewState,
    required this.tags,
  });

  final String id;
  final String schemaVersion;
  final String bankVersion;
  final String locale;
  final String dimension;
  final String subskill;
  final String prompt;
  final List<IqOption> options;
  final String correctOptionId;
  final String rationale;
  final String difficultyBand;
  final int estimatedTimeSeconds;
  final String languageDependency;
  final String cognitiveLoad;
  final String answerOrderPolicy;
  final String status;
  final String source;
  final String reviewState;
  final List<String> tags;

  factory IqCanonicalItem.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? const [])
        .map((e) => IqOption.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final rawTags = (json['tags'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    return IqCanonicalItem(
      id: json['id'] as String,
      schemaVersion: json['schema_version'] as String,
      bankVersion: json['bank_version'] as String,
      locale: json['locale'] as String,
      dimension: json['dimension'] as String,
      subskill: json['subskill'] as String,
      prompt: json['prompt'] as String,
      options: rawOptions,
      correctOptionId: json['correct_option_id'] as String,
      rationale: json['rationale'] as String,
      difficultyBand: json['difficulty_band'] as String,
      estimatedTimeSeconds: json['estimated_time_seconds'] as int,
      languageDependency: json['language_dependency'] as String,
      cognitiveLoad: json['cognitive_load'] as String,
      answerOrderPolicy: json['answer_order_policy'] as String,
      status: json['status'] as String,
      source: json['source'] as String,
      reviewState: json['review_state'] as String,
      tags: rawTags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'schema_version': schemaVersion,
        'bank_version': bankVersion,
        'locale': locale,
        'dimension': dimension,
        'subskill': subskill,
        'prompt': prompt,
        'options': options.map((o) => o.toJson()).toList(),
        'correct_option_id': correctOptionId,
        'rationale': rationale,
        'difficulty_band': difficultyBand,
        'estimated_time_seconds': estimatedTimeSeconds,
        'language_dependency': languageDependency,
        'cognitive_load': cognitiveLoad,
        'answer_order_policy': answerOrderPolicy,
        'status': status,
        'source': source,
        'review_state': reviewState,
        'tags': tags,
      };
}
