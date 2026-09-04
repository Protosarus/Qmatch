import 'package:flutter/foundation.dart';

import '../frequency_behavior_v2/frequency_behavior_v2_bank_registry.dart';
import '../frequency_behavior_v2/frequency_behavior_v2_contract.dart';

/// Central Frequency runtime track. Live production must resolve [v1] while
/// V2 banks are not runtime-selectable.
enum FrequencyRuntimeTrack { v1, v2 }

/// Single gate for V1 vs V2 Frequency routing.
///
/// Screens must not inspect `runtime_selectable` or the internal dart-define
/// themselves. Release/profile always resolve [v1] while the registry is
/// false. Debug may opt into V2 with `--dart-define=QMATCH_FREQUENCY_V2_INTERNAL=true`.
class FrequencyRuntimeSelectionPolicy {
  FrequencyRuntimeSelectionPolicy._();

  static const String internalDebugDefineName = 'QMATCH_FREQUENCY_V2_INTERNAL';

  static const List<String> reviewedPoolVersions = [
    FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    FrequencyBehaviorV2Contract.poolVersionEnDraft1,
  ];

  static const bool _internalV2FromDefine = bool.fromEnvironment(
    internalDebugDefineName,
    defaultValue: false,
  );

  /// Debug-only test access. Ignored in release/profile.
  static bool get isInternalDebugV2Override =>
      kDebugMode && _internalV2FromDefine;

  /// Production/default: V1, because the registry always returns false today.
  ///
  /// [debugInternalV2Override] is injectable for tests. Production callers
  /// omit it and use [isInternalDebugV2Override].
  static FrequencyRuntimeTrack resolve({
    bool Function(String poolVersion)? isRuntimeSelectable,
    bool? debugInternalV2Override,
  }) {
    final internal = debugInternalV2Override ?? isInternalDebugV2Override;
    if (internal) return FrequencyRuntimeTrack.v2;
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
