import 'iq_session_contract.dart';

/// Explicit eligibility gate — do not hard-code future production status
/// into selection internals.
enum IqSessionEligibilityMode {
  /// Offline / desk-review candidate items (current recovered bank).
  offlineDeskReviewedCandidate,

  /// Future pilot gate.
  pilotEligible,

  /// Future runtime gate.
  runtimeEligible,
}

/// How to treat previously seen families/items.
enum IqSessionFreshnessMode {
  /// Prefer / require unseen families; never silently reuse when insufficient.
  strictUnseenFamilies,

  /// Documented future hook — not auto-activated in P2C-2A-2.
  allowSeenFamilyRelaxation,
}

/// Config for composing one deterministic IQ session.
class IqSessionConfig {
  const IqSessionConfig({
    required this.sessionSeed,
    this.eligibilityMode =
        IqSessionEligibilityMode.offlineDeskReviewedCandidate,
    this.freshnessMode = IqSessionFreshnessMode.strictUnseenFamilies,
    this.balanceDisplayedCorrectPositions = true,
    this.previouslySeenItemIds = const {},
    this.previouslySeenTemplateFamilyIds = const {},
    this.selectionPolicyVersion = IqSessionContract.selectionPolicyVersion,
  });

  /// Opaque session seed (string or numeric string). Explicit only.
  final String sessionSeed;

  final IqSessionEligibilityMode eligibilityMode;
  final IqSessionFreshnessMode freshnessMode;
  final bool balanceDisplayedCorrectPositions;
  final Set<String> previouslySeenItemIds;
  final Set<String> previouslySeenTemplateFamilyIds;
  final String selectionPolicyVersion;
}

/// Per-dimension quota declaration.
class IqSessionDimensionQuota {
  const IqSessionDimensionQuota({
    required this.dimension,
    required this.requiredCount,
  });

  final String dimension;
  final int requiredCount;
}

/// One selected item in a session plan (no full prompt duplication).
class IqSessionItemPlan {
  const IqSessionItemPlan({
    required this.itemId,
    required this.dimension,
    required this.templateFamilyId,
    required this.displayedOptionIds,
    required this.displayedCorrectPosition,
  });

  final String itemId;
  final String dimension;
  final String templateFamilyId;

  /// Permutation of source option IDs for display.
  final List<String> displayedOptionIds;

  /// Audit-only 0-based index of correct option in [displayedOptionIds].
  /// Never treat this as scoring source of truth — use bank correct_option_id.
  final int displayedCorrectPosition;

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'dimension': dimension,
        'template_family_id': templateFamilyId,
        'displayed_option_ids': displayedOptionIds,
        'displayed_correct_position': displayedCorrectPosition,
      };

  factory IqSessionItemPlan.fromJson(Map<String, dynamic> json) {
    return IqSessionItemPlan(
      itemId: json['item_id'] as String,
      dimension: json['dimension'] as String,
      templateFamilyId: json['template_family_id'] as String,
      displayedOptionIds: (json['displayed_option_ids'] as List)
          .map((e) => e.toString())
          .toList(),
      displayedCorrectPosition: json['displayed_correct_position'] as int,
    );
  }
}

/// Reproducible session plan — enough to rebuild identical presentation later.
class IqSessionPlan {
  const IqSessionPlan({
    required this.schemaVersion,
    required this.bankVersion,
    required this.bankLocale,
    required this.sessionSeed,
    required this.itemPlans,
    required this.dimensionCounts,
    required this.createdFromBankItemCount,
    required this.selectionPolicyVersion,
    required this.balanceDisplayedCorrectPositions,
    required this.eligibilityMode,
    required this.freshnessMode,
  });

  final String schemaVersion;
  final String bankVersion;
  final String bankLocale;
  final String sessionSeed;
  final List<IqSessionItemPlan> itemPlans;
  final Map<String, int> dimensionCounts;
  final int createdFromBankItemCount;
  final String selectionPolicyVersion;
  final bool balanceDisplayedCorrectPositions;
  final IqSessionEligibilityMode eligibilityMode;
  final IqSessionFreshnessMode freshnessMode;

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'bank_version': bankVersion,
        'bank_locale': bankLocale,
        'session_seed': sessionSeed,
        'item_plans': itemPlans.map((e) => e.toJson()).toList(),
        'dimension_counts': dimensionCounts,
        'created_from_bank_item_count': createdFromBankItemCount,
        'selection_policy_version': selectionPolicyVersion,
        'balance_displayed_correct_positions': balanceDisplayedCorrectPositions,
        'eligibility_mode': eligibilityMode.name,
        'freshness_mode': freshnessMode.name,
      };
}

/// Structured insufficiency — never silently reuse families under strict mode.
class IqSessionInsufficiency {
  const IqSessionInsufficiency({
    required this.dimension,
    required this.requiredCount,
    required this.availableUnseenFamilies,
    required this.excludedSeenFamilies,
    required this.eligibleItemCount,
    this.message,
  });

  final String dimension;
  final int requiredCount;
  final int availableUnseenFamilies;
  final int excludedSeenFamilies;
  final int eligibleItemCount;
  final String? message;

  @override
  String toString() =>
      'IqSessionInsufficiency(dim=$dimension required=$requiredCount '
      'unseenFamilies=$availableUnseenFamilies '
      'excludedSeenFamilies=$excludedSeenFamilies '
      'eligibleItems=$eligibleItemCount'
      '${message == null ? '' : ' message=$message'})';
}

/// Success or structured failure for composition.
sealed class IqSessionCompositionResult {
  const IqSessionCompositionResult();
}

class IqSessionCompositionSuccess extends IqSessionCompositionResult {
  const IqSessionCompositionSuccess(this.plan);
  final IqSessionPlan plan;
}

class IqSessionCompositionFailure extends IqSessionCompositionResult {
  const IqSessionCompositionFailure({
    required this.code,
    required this.message,
    this.insufficiencies = const [],
  });

  final String code;
  final String message;
  final List<IqSessionInsufficiency> insufficiencies;
}

/// Validator issue.
class IqSessionValidationIssue {
  const IqSessionValidationIssue({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

class IqSessionValidationResult {
  const IqSessionValidationResult({
    required this.ok,
    required this.issues,
  });

  final bool ok;
  final List<IqSessionValidationIssue> issues;
}
