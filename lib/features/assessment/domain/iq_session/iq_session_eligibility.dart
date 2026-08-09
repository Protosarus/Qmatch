import '../iq_bank/iq_recovered_bank_document.dart';
import 'iq_session_models.dart';

/// Review-status eligibility without mutating bank review fields.
class IqSessionEligibility {
  IqSessionEligibility._();

  static const _desk = 'desk_reviewed_candidate';
  static const _pilot = 'pilot_eligible';
  static const _runtime = 'runtime_eligible';

  static bool allowsReviewStatus(
    IqSessionEligibilityMode mode,
    String reviewStatus,
  ) {
    switch (mode) {
      case IqSessionEligibilityMode.offlineDeskReviewedCandidate:
        return reviewStatus == _desk ||
            reviewStatus == _pilot ||
            reviewStatus == _runtime;
      case IqSessionEligibilityMode.pilotEligible:
        return reviewStatus == _pilot || reviewStatus == _runtime;
      case IqSessionEligibilityMode.runtimeEligible:
        return reviewStatus == _runtime;
    }
  }

  static List<IqRecoveredBankItem> filterEligible({
    required List<IqRecoveredBankItem> items,
    required IqSessionEligibilityMode mode,
  }) {
    return items
        .where((i) => allowsReviewStatus(mode, i.reviewStatus))
        .toList(growable: false);
  }
}
