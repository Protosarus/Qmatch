import 'frequency_behavior_v2_contract.dart';

/// Version-keyed bank registry for a future V2 activation.
///
/// Live Frequency routing must NOT call this. V1 sessions stay bound to
/// `frequency_bank_*_v1` via persisted `bank_version` + `bank_locale`.
/// Future runtime loaders must key by version, not locale alone.
class FrequencyBehaviorV2BankRegistry {
  FrequencyBehaviorV2BankRegistry._();

  static const Map<String, String> draftPathsByVersionLocale = {
    '${FrequencyBehaviorV2Contract.poolVersionTrDraft1}|${FrequencyBehaviorV2Contract.localeTr}':
        FrequencyBehaviorV2Contract.draftPoolRelativePath,
    '${FrequencyBehaviorV2Contract.poolVersionEnDraft1}|${FrequencyBehaviorV2Contract.localeEn}':
        FrequencyBehaviorV2Contract.draftPoolEnRelativePath,
  };

  static String? draftPath({
    required String poolVersion,
    required String locale,
  }) =>
      draftPathsByVersionLocale['$poolVersion|$locale'];

  static bool isRuntimeSelectable(String poolVersion) {
    // Draft versions are never live-selectable.
    return false;
  }
}
