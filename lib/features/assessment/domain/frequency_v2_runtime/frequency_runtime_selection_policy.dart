/// Live Frequency runtime. V1 is not selectable for new assessments.
enum FrequencyRuntimeTrack { v2 }

/// Production Frequency always resolves to V2.
///
/// There is no dart-define, debug override, or V1 fallback.
class FrequencyRuntimeSelectionPolicy {
  FrequencyRuntimeSelectionPolicy._();

  static FrequencyRuntimeTrack resolve({
    bool Function(String poolVersion)? isRuntimeSelectable,
    bool? debugInternalV2Override,
  }) {
    return FrequencyRuntimeTrack.v2;
  }

  static bool get isV2RuntimeSelectable => true;
}
