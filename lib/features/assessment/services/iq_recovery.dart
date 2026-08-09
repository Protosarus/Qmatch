/// Explicit IQ recovery outcome (P1B-1.1).
///
/// [questionCount] is null when unknown — never use `0` as a stand-in for
/// "unavailable" (that would normalize a real raw score into a false Low band).
class IqRecoveryResult {
  static const statusOk = 'ok';
  static const statusInsufficientMetadata = 'insufficient_metadata';
  static const reasonMissingIqQuestionCount = 'missing_iq_question_count';

  /// Legacy correct-count when known (canonical / assignment / user mirror).
  final int? rawScore;

  /// Positive IQ question / order count when known; null = unavailable.
  final int? questionCount;

  /// [statusOk] or [statusInsufficientMetadata].
  final String status;

  /// e.g. [reasonMissingIqQuestionCount].
  final String? reasonCode;

  const IqRecoveryResult({
    required this.rawScore,
    required this.questionCount,
    required this.status,
    this.reasonCode,
  });

  bool get hasQuestionCount => questionCount != null && questionCount! > 0;

  bool get isInsufficientMetadata => status == statusInsufficientMetadata;

  /// Pure recovery merger for unit tests and runtime.
  ///
  /// Order:
  /// 1. Canonical IQ `question_count`
  /// 2. Assignment `question_order` length, else assignment `question_count`
  /// 3. [setMetadataQuestionCount] from persisted `set_id`
  /// 4. User mirror supplies **raw score only**, never a denominator
  static IqRecoveryResult fromSources({
    Map<String, dynamic>? canonical,
    Map<String, dynamic>? assignment,
    int? setMetadataQuestionCount,
    int? userMirrorRawScore,
  }) {
    int? raw;
    int? questionCount;

    if (canonical != null) {
      raw = _readRawScore(canonical);
      questionCount = _positiveInt(canonical['question_count']);
    }

    if (assignment != null) {
      if (raw == null && assignment['completed'] == true) {
        raw = _numToInt(assignment['score']);
      }
      if (questionCount == null) {
        final order = assignment['question_order'];
        if (order is List && order.isNotEmpty) {
          questionCount = order.length;
        }
      }
      questionCount ??= _positiveInt(assignment['question_count']);
    }

    questionCount ??= _positiveInt(setMetadataQuestionCount);

    // Historical user mirror: raw only.
    raw ??= userMirrorRawScore;

    if (questionCount == null) {
      return IqRecoveryResult(
        rawScore: raw,
        questionCount: null,
        status: statusInsufficientMetadata,
        reasonCode: reasonMissingIqQuestionCount,
      );
    }

    return IqRecoveryResult(
      rawScore: raw,
      questionCount: questionCount,
      status: statusOk,
      reasonCode: null,
    );
  }

  static int? _readRawScore(Map<String, dynamic> data) {
    final raw = data['raw_score'];
    if (raw is num) return raw.toInt();
    final summary = data['performance_summary'];
    if (summary is Map && summary['correct_count'] is num) {
      return (summary['correct_count'] as num).toInt();
    }
    return null;
  }

  static int? _numToInt(dynamic v) => v is num ? v.toInt() : null;

  /// Rejects null and non-positive values (0 is not a valid denominator).
  static int? _positiveInt(dynamic v) {
    if (v is! num) return null;
    final n = v.toInt();
    if (n <= 0) return null;
    return n;
  }
}
