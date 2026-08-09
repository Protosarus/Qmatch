/// P2C-2A-2 IQ session composer contracts (offline / runtime-neutral).
///
/// Selection policy version is frozen for reproducibility.
class IqSessionContract {
  IqSessionContract._();

  static const String schemaVersion = 'qmatch_iq_session_plan_v1';
  static const String selectionPolicyVersion = 'iq_session_selection_v1';
  static const String rngAlgorithmVersion = 'xorshift32_fnv1a32_v1';

  static const int sessionItemCount = 25;

  /// Exact quotas for a live-style 25-item session.
  static const Map<String, int> dimensionQuotas = {
    'logical_reasoning': 7,
    'pattern_reasoning': 6,
    'verbal_reasoning': 6,
    'spatial_reasoning': 6,
  };

  static const int optionCount = 4;
  static const List<String> canonicalOptionIds = ['a', 'b', 'c', 'd'];

  /// Max consecutive same-dimension streak when an alternative exists.
  static const int maxSameDimensionStreak = 3;

  /// When balancing displayed correct positions: max(count)-min(count) <= 1.
  static const int maxAnswerPositionBalanceSpread = 1;
}
