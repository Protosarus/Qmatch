import '../frequency_behavior_v2/frequency_behavior_v2_bank_registry.dart';
import '../frequency_behavior_v2/frequency_behavior_v2_contract.dart';

/// Central Frequency runtime track. Live production must resolve [v1] while
/// V2 banks are not runtime-selectable.
enum FrequencyRuntimeTrack { v1, v2 }

/// Single gate for V1 vs V2 Frequency routing.
///
/// Screens must not inspect `runtime_selectable` themselves.
class FrequencyRuntimeSelectionPolicy {
  FrequencyRuntimeSelectionPolicy._();

  static const List<String> reviewedPoolVersions = [
    FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    FrequencyBehaviorV2Contract.poolVersionEnDraft1,
  ];

  /// Production/default: V1, because the registry always returns false today.
  static FrequencyRuntimeTrack resolve({
    bool Function(String poolVersion)? isRuntimeSelectable,
  }) {
    final check = isRuntimeSelectable ??
        FrequencyBehaviorV2BankRegistry.isRuntimeSelectable;
    for (final version in reviewedPoolVersions) {
      if (check(version)) return FrequencyRuntimeTrack.v2;
    }
    return FrequencyRuntimeTrack.v1;
  }

  static bool get isV2RuntimeSelectable =>
      resolve() == FrequencyRuntimeTrack.v2;
}
