import '../iq_bank/iq_canonical_dimensions.dart';
import '../iq_session/iq_session_contract.dart';
import 'iq_scoring_contract.dart';
import 'iq_scoring_models.dart';

class IqScoringValidationResult {
  const IqScoringValidationResult({
    required this.ok,
    this.issues = const [],
  });

  final bool ok;
  final List<String> issues;
}

/// Hard validator for [IqCanonicalScoringResult].
class IqScoringResultValidator {
  IqScoringResultValidator._();

  static IqScoringValidationResult validate(IqCanonicalScoringResult result) {
    final issues = <String>[];

    void fail(String msg) => issues.add(msg);

    if (result.schemaVersion != IqScoringContract.schemaVersion) {
      fail('schema_version');
    }
    if (result.scoringPolicyVersion != IqScoringContract.scoringPolicyVersion) {
      fail('scoring_policy_version');
    }
    if (result.calibrationStatus != IqCalibrationStatus.uncalibrated) {
      fail('calibration_status');
    }
    if (result.bankVersion.trim().isEmpty) fail('bank_version');
    if (result.sessionId.trim().isEmpty) fail('session_id');
    if (result.selectionPolicyVersion.trim().isEmpty) {
      fail('selection_policy_version');
    }
    if (result.totalAnswered != IqSessionContract.sessionItemCount) {
      fail('total_answered');
    }

    if (result.dimensionScores.length != IqCanonicalDimensions.all.length) {
      fail('dimension_count');
    }

    final seen = <String>{};
    for (var i = 0; i < result.dimensionScores.length; i++) {
      final d = result.dimensionScores[i];
      if (i < IqCanonicalDimensions.all.length &&
          d.dimension != IqCanonicalDimensions.all[i]) {
        fail('dimension_order:${d.dimension}');
      }
      if (!seen.add(d.dimension)) fail('duplicate_dimension:${d.dimension}');
      if (!IqCanonicalDimensions.isCanonical(d.dimension)) {
        fail('non_canonical:${d.dimension}');
      }
      if (IqCanonicalDimensions.isRetired(d.dimension)) {
        fail('retired:${d.dimension}');
      }

      final expectedItems = IqSessionContract.dimensionQuotas[d.dimension];
      if (expectedItems == null || d.itemCount != expectedItems) {
        fail('item_count:${d.dimension}');
      }
      if (d.answeredCount != d.itemCount) {
        fail('answered_count:${d.dimension}');
      }
      if (d.correctCount + d.incorrectCount != d.itemCount) {
        fail('correct_incorrect_sum:${d.dimension}');
      }
      if (d.rawAccuracy < 0 || d.rawAccuracy > 1) {
        fail('raw_accuracy_range:${d.dimension}');
      }
      if (d.provisionalScore < 0 || d.provisionalScore > 1) {
        fail('provisional_range:${d.dimension}');
      }
      final expectedRaw = d.itemCount == 0 ? 0.0 : d.correctCount / d.itemCount;
      if ((d.rawAccuracy - expectedRaw).abs() > 1e-12) {
        fail('raw_accuracy_mismatch:${d.dimension}');
      }
      // v1 policy: provisionalScore == rawAccuracy
      if ((d.provisionalScore - d.rawAccuracy).abs() > 1e-12) {
        fail('provisional_policy:${d.dimension}');
      }
      if (d.calibrationStatus != IqCalibrationStatus.uncalibrated) {
        fail('dim_calibration:${d.dimension}');
      }
    }

    if (!result.structuralFlags.completeSession ||
        !result.structuralFlags.quotaValid ||
        !result.structuralFlags.canonicalBankValid) {
      fail('structural_flags');
    }

    return IqScoringValidationResult(ok: issues.isEmpty, issues: issues);
  }
}
