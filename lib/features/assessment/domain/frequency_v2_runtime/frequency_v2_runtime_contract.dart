/// Pins for the dormant Frequency V2 Flutter runtime bridge (Phase 8A).
///
/// Does not activate V2. Live routing must still resolve to Frequency V1
/// while [FrequencyBehaviorV2BankRegistry.isRuntimeSelectable] is false.
class FrequencyV2RuntimeContract {
  FrequencyV2RuntimeContract._();

  static const String persistedSchemaVersion =
      'qmatch_frequency_v2_persisted_session_v1';
  static const String finalizeSchemaVersion =
      'frequency_behavior_v2_finalize_session_v1';
  static const String catalogVersion = 'frequency_behavior_v2_catalog_v1';
  static const String assessmentType = 'frequency_v2';
  static const String storagePrefix = 'qmatch.frequency_v2_session.v1';
  static const int selectableItemCount = 405;
  static const int dropItemCount = 21;
  static const int sessionItemCount = 50;
  static const int optionsPerItem = 4;
  static const int maxIdLength = 128;
}
