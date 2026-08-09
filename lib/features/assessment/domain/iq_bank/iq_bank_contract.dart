/// Canonical IQ bank-level targets (P2C-2A-0 / P2C-2A-1).
///
/// Recovered bank JSON exists offline (`IMPLEMENTED_OFFLINE`) but is **not**
/// production-wired. Asset paths are for tools/tests only.
class IqBankContract {
  IqBankContract._();

  static const String schemaVersion = 'iq_item_schema_v1';
  static const String recoveredBankSchemaVersion = 'qmatch_iq_bank_v1';
  static const String targetBankFileName = 'iq_bank_tr_v1.json';
  static const String schemaFileName = 'iq_item_schema_v1.json';
  static const String pilotFileName = 'iq_pilot_tr_v1.json';

  static const int targetUniqueItems = 340;

  /// Verified source distribution for the recovered 340-item bank (not equal 85s).
  static const Map<String, int> recoveredDimensionDistribution = {
    'logical_reasoning': 100,
    'pattern_reasoning': 80,
    'verbal_reasoning': 80,
    'spatial_reasoning': 80,
  };

  static const int recoveredTemplateFamilyCount = 170;
  static const int recoveredRewrittenCount = 40;
  static const Map<String, int> recoveredRewrittenDistribution = {
    'logical_reasoning': 1,
    'pattern_reasoning': 14,
    'verbal_reasoning': 9,
    'spatial_reasoning': 16,
  };
  static const Map<String, int> recoveredAnswerPositionDistribution = {
    'a': 97,
    'b': 86,
    'c': 81,
    'd': 76,
  };

  /// @Deprecated Prefer [recoveredDimensionDistribution]. Equal 85 split was a
  /// pre-source placeholder from P2C-2A-0 and is not the verified bank layout.
  static const int targetPerDimension = 85;

  static const int liveSessionItems = 25;
  static const Map<String, int> liveSessionDistribution = {
    'logical_reasoning': 7,
    'pattern_reasoning': 6,
    'verbal_reasoning': 6,
    'spatial_reasoning': 6,
  };

  static const int pilotItems = 25;

  static const Set<String> difficultyBands = {'easy', 'medium', 'hard'};
  static const Set<String> locales = {'tr-TR'};

  static const int minEstimatedTimeSeconds = 20;
  static const int maxEstimatedTimeSeconds = 180;

  /// Promotion flow — expert review must not be claimed prematurely.
  static const List<String> promotionFlow = [
    'draft',
    'technically_valid',
    'content_reviewed',
    'expert_reviewed',
    'pilot_eligible',
    'runtime_eligible',
  ];

  static const Set<String> runtimeEligibleStatuses = {'runtime_eligible'};

  static bool isRuntimeEligibleStatus(String status) =>
      runtimeEligibleStatuses.contains(status);

  /// Editorial difficulty is not calibrated measurement.
  static bool treatsDifficultyAsCalibrated = false;
}
