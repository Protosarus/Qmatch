import '../iq_bank/iq_canonical_dimensions.dart';
import 'iq_scoring_contract.dart';

/// Per-dimension uncalibrated reasoning performance (not an IQ score).
class IqDimensionScore {
  const IqDimensionScore({
    required this.dimension,
    required this.correctCount,
    required this.incorrectCount,
    required this.answeredCount,
    required this.itemCount,
    required this.rawAccuracy,
    required this.provisionalScore,
    required this.calibrationStatus,
  });

  final String dimension;
  final int correctCount;
  final int incorrectCount;
  final int answeredCount;
  final int itemCount;

  /// correctCount / itemCount in [0, 1].
  final double rawAccuracy;

  /// For v1 policy equals [rawAccuracy]. Not norm-referenced.
  final double provisionalScore;

  final IqCalibrationStatus calibrationStatus;

  Map<String, dynamic> toJson() => {
        'dimension': dimension,
        'correct_count': correctCount,
        'incorrect_count': incorrectCount,
        'answered_count': answeredCount,
        'item_count': itemCount,
        'raw_accuracy': rawAccuracy,
        'provisional_score': provisionalScore,
        'calibration_status': calibrationStatus.wireValue,
      };

  factory IqDimensionScore.fromJson(Map<String, dynamic> json) {
    return IqDimensionScore(
      dimension: json['dimension'] as String,
      correctCount: json['correct_count'] as int,
      incorrectCount: json['incorrect_count'] as int,
      answeredCount: json['answered_count'] as int,
      itemCount: json['item_count'] as int,
      rawAccuracy: (json['raw_accuracy'] as num).toDouble(),
      provisionalScore: (json['provisional_score'] as num).toDouble(),
      calibrationStatus:
          IqCalibrationStatus.fromWire(json['calibration_status'] as String?),
    );
  }
}

/// Structural (non-psychometric) completeness flags.
class IqScoringStructuralFlags {
  const IqScoringStructuralFlags({
    required this.completeSession,
    required this.quotaValid,
    required this.canonicalBankValid,
  });

  final bool completeSession;
  final bool quotaValid;
  final bool canonicalBankValid;

  Map<String, dynamic> toJson() => {
        'complete_session': completeSession,
        'quota_valid': quotaValid,
        'canonical_bank_valid': canonicalBankValid,
      };

  factory IqScoringStructuralFlags.fromJson(Map<String, dynamic> json) {
    return IqScoringStructuralFlags(
      completeSession: json['complete_session'] as bool? ?? false,
      quotaValid: json['quota_valid'] as bool? ?? false,
      canonicalBankValid: json['canonical_bank_valid'] as bool? ?? false,
    );
  }
}

/// Canonical 4D scoring result — uncalibrated reasoning profile.
///
/// Explicitly omits: overallIq, iqScore, percentile, reliabilityEstimate,
/// empiricalUncertainty, strongest/weakest dimension labels.
class IqCanonicalScoringResult {
  const IqCanonicalScoringResult({
    required this.schemaVersion,
    required this.bankVersion,
    required this.bankLocale,
    required this.selectionPolicyVersion,
    required this.scoringPolicyVersion,
    required this.sessionId,
    required this.dimensionScores,
    required this.totalAnswered,
    required this.createdAt,
    required this.calibrationStatus,
    required this.structuralFlags,
  });

  final String schemaVersion;
  final String bankVersion;
  final String bankLocale;
  final String selectionPolicyVersion;
  final String scoringPolicyVersion;
  final String sessionId;

  /// Exactly four scores in canonical dimension order.
  final List<IqDimensionScore> dimensionScores;

  final int totalAnswered;
  final String createdAt;
  final IqCalibrationStatus calibrationStatus;
  final IqScoringStructuralFlags structuralFlags;

  IqDimensionScore scoreFor(String dimension) =>
      dimensionScores.firstWhere((d) => d.dimension == dimension);

  Map<String, dynamic> toJson() {
    final byDim = {for (final d in dimensionScores) d.dimension: d};
    final ordered = <Map<String, dynamic>>[
      for (final id in IqCanonicalDimensions.all)
        if (byDim.containsKey(id)) byDim[id]!.toJson(),
    ];
    return {
      'schema_version': schemaVersion,
      'bank_version': bankVersion,
      'bank_locale': bankLocale,
      'selection_policy_version': selectionPolicyVersion,
      'scoring_policy_version': scoringPolicyVersion,
      'session_id': sessionId,
      'dimension_scores': ordered,
      'total_answered': totalAnswered,
      'created_at': createdAt,
      'calibration_status': calibrationStatus.wireValue,
      'structural_flags': structuralFlags.toJson(),
      // Explicit absences for contract clarity (never fabricate):
      'reliability_estimate': null,
      'empirical_uncertainty': null,
    };
  }

  factory IqCanonicalScoringResult.fromJson(Map<String, dynamic> json) {
    return IqCanonicalScoringResult(
      schemaVersion: json['schema_version'] as String,
      bankVersion: json['bank_version'] as String,
      bankLocale: json['bank_locale'] as String,
      selectionPolicyVersion: json['selection_policy_version'] as String,
      scoringPolicyVersion: json['scoring_policy_version'] as String,
      sessionId: json['session_id'] as String,
      dimensionScores: (json['dimension_scores'] as List)
          .map((e) =>
              IqDimensionScore.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalAnswered: json['total_answered'] as int,
      createdAt: json['created_at'] as String,
      calibrationStatus:
          IqCalibrationStatus.fromWire(json['calibration_status'] as String?),
      structuralFlags: IqScoringStructuralFlags.fromJson(
        Map<String, dynamic>.from(
          (json['structural_flags'] as Map?) ?? const {},
        ),
      ),
    );
  }
}

enum IqScoringFailureCode {
  sessionIncomplete,
  sessionNotCompleted,
  validationFailed,
  incompatibleBank,
  incompatiblePolicy,
  incompatibleSchema,
  corrupt,
  ownerMismatch,
  ownerUnavailable,
  resultInvalid,
}

class IqScoringOutcome {
  const IqScoringOutcome.ok(this.result)
      : ok = true,
        code = null,
        message = null;

  const IqScoringOutcome.fail({
    required this.code,
    this.message,
  })  : ok = false,
        result = null;

  final bool ok;
  final IqCanonicalScoringResult? result;
  final IqScoringFailureCode? code;
  final String? message;
}
