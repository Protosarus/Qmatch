import 'package:flutter/widgets.dart';

import '../../screens/frequency_test_screen.dart';
import '../../screens/frequency_v2_test_screen.dart';
import 'frequency_runtime_selection_policy.dart';

/// Shared Frequency *test* screen constructor.
///
/// Screens and route gates must not inspect `QMATCH_FREQUENCY_V2_INTERNAL`
/// themselves. Release/default stays [FrequencyTestScreen] while
/// [FrequencyRuntimeSelectionPolicy] resolves V1.
class FrequencyRuntimeTestScreenFactory {
  FrequencyRuntimeTestScreenFactory._();

  /// Builds the live Frequency question screen for [track], or for
  /// [FrequencyRuntimeSelectionPolicy.resolve] when [track] is omitted.
  static Widget build({
    Key? key,
    FrequencyRuntimeTrack? track,
    bool Function(String poolVersion)? isRuntimeSelectable,
    bool? debugInternalV2Override,
  }) {
    final resolved = track ??
        FrequencyRuntimeSelectionPolicy.resolve(
          isRuntimeSelectable: isRuntimeSelectable,
          debugInternalV2Override: debugInternalV2Override,
        );
    switch (resolved) {
      case FrequencyRuntimeTrack.v2:
        return FrequencyV2TestScreen(key: key);
      case FrequencyRuntimeTrack.v1:
        return FrequencyTestScreen(key: key);
    }
  }
}
