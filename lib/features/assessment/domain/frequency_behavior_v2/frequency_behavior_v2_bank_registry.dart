import 'frequency_behavior_v2_contract.dart';

/// Version-keyed bank paths for Frequency V2 assets.
///
/// Live routing always uses V2 via FrequencyRuntimeSelectionPolicy.
/// [isRuntimeSelectable] is unused by production selection and stays false
/// so draft pool metadata is not treated as a second switch.
class FrequencyBehaviorV2BankRegistry {
  FrequencyBehaviorV2BankRegistry._();

  static const Map<String, String> draftPathsByVersionLocale = {
    '${FrequencyBehaviorV2Contract.poolVersionTrDraft1}|${FrequencyBehaviorV2Contract.localeTr}':
        FrequencyBehaviorV2Contract.draftPoolRelativePath,
    '${FrequencyBehaviorV2Contract.poolVersionEnDraft1}|${FrequencyBehaviorV2Contract.localeEn}':
        FrequencyBehaviorV2Contract.draftPoolEnRelativePath,
  };

  static const Map<String, String> draftReviewPathsByVersionLocale = {
    '${FrequencyBehaviorV2Contract.poolVersionTrDraft1}|${FrequencyBehaviorV2Contract.localeTr}':
        FrequencyBehaviorV2Contract.draftReviewRelativePath,
    '${FrequencyBehaviorV2Contract.poolVersionEnDraft1}|${FrequencyBehaviorV2Contract.localeEn}':
        FrequencyBehaviorV2Contract.draftReviewEnRelativePath,
  };

  static const Map<String, String> runtimeAssetPathsByVersionLocale = {
    '${FrequencyBehaviorV2Contract.poolVersionTrDraft1}|${FrequencyBehaviorV2Contract.localeTr}':
        FrequencyBehaviorV2Contract.runtimePoolAssetPathTr,
    '${FrequencyBehaviorV2Contract.poolVersionEnDraft1}|${FrequencyBehaviorV2Contract.localeEn}':
        FrequencyBehaviorV2Contract.runtimePoolAssetPathEn,
  };

  static const Map<String, String> runtimeReviewAssetPathsByVersionLocale = {
    '${FrequencyBehaviorV2Contract.poolVersionTrDraft1}|${FrequencyBehaviorV2Contract.localeTr}':
        FrequencyBehaviorV2Contract.runtimeReviewAssetPathTr,
    '${FrequencyBehaviorV2Contract.poolVersionEnDraft1}|${FrequencyBehaviorV2Contract.localeEn}':
        FrequencyBehaviorV2Contract.runtimeReviewAssetPathEn,
  };

  static String? draftPath({
    required String poolVersion,
    required String locale,
  }) =>
      draftPathsByVersionLocale['$poolVersion|$locale'];

  static String? draftReviewPath({
    required String poolVersion,
    required String locale,
  }) =>
      draftReviewPathsByVersionLocale['$poolVersion|$locale'];

  static String? runtimeAssetPath({
    required String poolVersion,
    required String locale,
  }) =>
      runtimeAssetPathsByVersionLocale['$poolVersion|$locale'];

  static String? runtimeReviewAssetPath({
    required String poolVersion,
    required String locale,
  }) =>
      runtimeReviewAssetPathsByVersionLocale['$poolVersion|$locale'];

  static bool isRuntimeSelectable(String poolVersion) {
    // Draft versions are never live-selectable.
    return false;
  }
}
