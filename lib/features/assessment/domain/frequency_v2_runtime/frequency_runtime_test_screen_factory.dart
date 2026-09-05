import 'package:flutter/widgets.dart';

import '../../screens/frequency_v2_test_screen.dart';
import 'frequency_runtime_selection_policy.dart';

/// Shared Frequency test-screen constructor. Always builds V2.
class FrequencyRuntimeTestScreenFactory {
  FrequencyRuntimeTestScreenFactory._();

  static Widget build({
    Key? key,
    FrequencyRuntimeTrack? track,
    bool Function(String poolVersion)? isRuntimeSelectable,
    bool? debugInternalV2Override,
  }) {
    return FrequencyV2TestScreen(key: key);
  }
}
