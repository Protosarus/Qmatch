class TraitScoringValidationException implements Exception {
  final String message;
  final List<TraitValidationError> errors;

  TraitScoringValidationException(this.message, [this.errors = const []]);

  @override
  String toString() => 'TraitScoringValidationException: $message'
      '${errors.isEmpty ? '' : ' | ${errors.map((e) => e.reasonCode).join(', ')}'}';
}

class TraitValidationError {
  final String? source;
  final String? questionId;
  final String fieldPath;
  final String reasonCode;
  final String explanation;

  const TraitValidationError({
    this.source,
    this.questionId,
    required this.fieldPath,
    required this.reasonCode,
    required this.explanation,
  });

  Map<String, Object?> toJson() => {
        'source': source,
        'question_id': questionId,
        'field_path': fieldPath,
        'reason_code': reasonCode,
        'explanation': explanation,
      };
}
