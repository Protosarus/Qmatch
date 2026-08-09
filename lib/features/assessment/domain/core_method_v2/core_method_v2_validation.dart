class CoreMethodValidationError {
  final String fieldPath;
  final String reasonCode;
  final String explanation;

  const CoreMethodValidationError({
    required this.fieldPath,
    required this.reasonCode,
    required this.explanation,
  });

  Map<String, Object?> toJson() => {
        'field_path': fieldPath,
        'reason_code': reasonCode,
        'explanation': explanation,
      };
}

class CoreMethodValidationException implements Exception {
  final String message;
  final List<CoreMethodValidationError> errors;

  CoreMethodValidationException(this.message, [this.errors = const []]);

  @override
  String toString() =>
      'CoreMethodValidationException: $message (${errors.length} errors)';
}

void cmRequire(bool ok, String field, String code, String explanation) {
  if (!ok) {
    throw CoreMethodValidationException(
      explanation,
      [
        CoreMethodValidationError(
            fieldPath: field, reasonCode: code, explanation: explanation)
      ],
    );
  }
}

bool cmIsFinite(num? v) => v != null && v.isFinite;

void cmRequireFinite01(num? v, String field, {required bool allowNull}) {
  if (v == null) {
    cmRequire(allowNull, field, 'null_not_allowed', '$field must not be null');
    return;
  }
  cmRequire(v.isFinite, field, 'non_finite', '$field must be finite');
  cmRequire(
      v >= 0.0 && v <= 1.0, field, 'out_of_range', '$field must be in [0,1]');
}

Map<String, dynamic> cmSortedMap(Map<String, dynamic> input) {
  final keys = input.keys.toList()..sort();
  final out = <String, dynamic>{};
  for (final k in keys) {
    final v = input[k];
    if (v is Map) {
      out[k] = cmSortedMap(Map<String, dynamic>.from(v));
    } else if (v is List) {
      out[k] = [
        for (final e in v)
          if (e is Map) cmSortedMap(Map<String, dynamic>.from(e)) else e,
      ];
    } else {
      out[k] = v;
    }
  }
  return out;
}
