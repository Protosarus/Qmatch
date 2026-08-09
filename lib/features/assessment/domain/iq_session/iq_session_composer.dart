import '../iq_bank/iq_bank_contract.dart';
import '../iq_bank/iq_canonical_dimensions.dart';
import '../iq_bank/iq_recovered_bank_document.dart';
import 'iq_deterministic_rng.dart';
import 'iq_session_contract.dart';
import 'iq_session_eligibility.dart';
import 'iq_session_models.dart';
import 'iq_session_plan_validator.dart';

/// Offline deterministic 25-question IQ session composer (P2C-2A-2).
///
/// Does not touch live IQ screens, Firebase, progress, or scoring.
class IqSessionComposer {
  const IqSessionComposer();

  /// Compose a session plan from an immutable recovered bank snapshot.
  IqSessionCompositionResult compose({
    required IqRecoveredBankDocument bank,
    required IqSessionConfig config,
  }) {
    if (config.selectionPolicyVersion !=
        IqSessionContract.selectionPolicyVersion) {
      return IqSessionCompositionFailure(
        code: 'unsupported_selection_policy',
        message:
            'Unsupported selection_policy_version=${config.selectionPolicyVersion}',
      );
    }
    if (config.freshnessMode ==
        IqSessionFreshnessMode.allowSeenFamilyRelaxation) {
      return IqSessionCompositionFailure(
        code: 'relaxation_not_activated',
        message: 'allowSeenFamilyRelaxation is a documented future hook and is '
            'not activated in ${IqSessionContract.selectionPolicyVersion}',
      );
    }

    for (final item in bank.items) {
      if (IqCanonicalDimensions.isRetired(item.dimension)) {
        return IqSessionCompositionFailure(
          code: 'retired_dimension_in_bank',
          message: 'Bank contains retired dimension=${item.dimension}',
        );
      }
      if (!IqCanonicalDimensions.isCanonical(item.dimension)) {
        return IqSessionCompositionFailure(
          code: 'unsupported_dimension',
          message: 'Unsupported dimension=${item.dimension}',
        );
      }
    }

    final eligible = IqSessionEligibility.filterEligible(
      items: bank.items,
      mode: config.eligibilityMode,
    );

    final byDimension = <String, List<IqRecoveredBankItem>>{
      for (final d in IqCanonicalDimensions.all) d: <IqRecoveredBankItem>[],
    };
    for (final item in eligible) {
      if (config.previouslySeenItemIds.contains(item.id)) continue;
      byDimension[item.dimension]!.add(item);
    }

    final insufficiencies = <IqSessionInsufficiency>[];
    final selectedByDim = <String, List<IqRecoveredBankItem>>{};

    for (final dim in IqCanonicalDimensions.all) {
      final required = IqSessionContract.dimensionQuotas[dim]!;
      final dimItems = byDimension[dim]!;

      // Group by family; exclude previously seen families.
      final families = <String, List<IqRecoveredBankItem>>{};
      var excludedSeenFamilies = 0;
      for (final item in dimItems) {
        if (config.previouslySeenTemplateFamilyIds
            .contains(item.templateFamilyId)) {
          excludedSeenFamilies++;
          continue;
        }
        families.putIfAbsent(item.templateFamilyId, () => []).add(item);
      }

      if (families.length < required) {
        insufficiencies.add(
          IqSessionInsufficiency(
            dimension: dim,
            requiredCount: required,
            availableUnseenFamilies: families.length,
            excludedSeenFamilies: excludedSeenFamilies,
            eligibleItemCount: dimItems.length,
            message:
                'Strict unseen-family policy cannot satisfy quota for $dim',
          ),
        );
        continue;
      }

      final familyKeys = families.keys.toList()
        ..sort(); // stable before shuffle — no source-file order dependence
      final rng = IqDeterministicRng.forSession(
        selectionPolicyVersion: config.selectionPolicyVersion,
        bankVersion: bank.bankVersion,
        sessionSeed: config.sessionSeed,
        stream: 'dim_select:$dim',
      );
      final shuffledFamilies = rng.shuffledCopy(familyKeys);
      final picked = <IqRecoveredBankItem>[];
      for (final fam in shuffledFamilies) {
        if (picked.length >= required) break;
        final variants = List<IqRecoveredBankItem>.from(families[fam]!)
          ..sort((a, b) => a.id.compareTo(b.id));
        final variantRng = IqDeterministicRng.forSession(
          selectionPolicyVersion: config.selectionPolicyVersion,
          bankVersion: bank.bankVersion,
          sessionSeed: config.sessionSeed,
          stream: 'variant:$dim:$fam',
        );
        final chosen = variantRng.shuffledCopy(variants).first;
        picked.add(chosen);
      }
      selectedByDim[dim] = picked;
    }

    if (insufficiencies.isNotEmpty) {
      return IqSessionCompositionFailure(
        code: 'insufficient_candidates',
        message: 'Cannot compose session under strict freshness policy',
        insufficiencies: insufficiencies,
      );
    }

    // Flatten selected items (sorted ids per dim already deterministic pick).
    final selected = <IqRecoveredBankItem>[
      for (final dim in IqCanonicalDimensions.all) ...selectedByDim[dim]!,
    ];

    // Family uniqueness hard check before ordering.
    final fams = selected.map((e) => e.templateFamilyId).toSet();
    if (fams.length != selected.length) {
      return IqSessionCompositionFailure(
        code: 'family_uniqueness_broken',
        message: 'Internal error: duplicate template_family_id in selection',
      );
    }
    final ids = selected.map((e) => e.id).toSet();
    if (ids.length != selected.length) {
      return IqSessionCompositionFailure(
        code: 'item_uniqueness_broken',
        message: 'Internal error: duplicate item id in selection',
      );
    }

    final interleaved = _interleave(
      selectedByDim: selectedByDim,
      config: config,
      bankVersion: bank.bankVersion,
    );

    final positionTargets = config.balanceDisplayedCorrectPositions
        ? _balancedCorrectPositions(
            count: interleaved.length,
            config: config,
            bankVersion: bank.bankVersion,
          )
        : List<int>.generate(
            interleaved.length,
            (i) {
              final rng = IqDeterministicRng.forSession(
                selectionPolicyVersion: config.selectionPolicyVersion,
                bankVersion: bank.bankVersion,
                sessionSeed: config.sessionSeed,
                stream: 'correct_pos_free:$i:${interleaved[i].id}',
              );
              return rng.nextInt(IqSessionContract.optionCount);
            },
          );

    final itemPlans = <IqSessionItemPlan>[];
    for (var i = 0; i < interleaved.length; i++) {
      final item = interleaved[i];
      final sourceIds = item.options.map((o) => o.id).toList(growable: false);
      final displayed = _displayOrderWithCorrectAt(
        sourceOptionIds: sourceIds,
        correctOptionId: item.correctOptionId,
        targetPosition: positionTargets[i],
        config: config,
        bankVersion: bank.bankVersion,
        itemId: item.id,
      );
      itemPlans.add(
        IqSessionItemPlan(
          itemId: item.id,
          dimension: item.dimension,
          templateFamilyId: item.templateFamilyId,
          displayedOptionIds: displayed,
          displayedCorrectPosition: positionTargets[i],
        ),
      );
    }

    final dimCounts = <String, int>{
      for (final d in IqCanonicalDimensions.all) d: 0,
    };
    for (final p in itemPlans) {
      dimCounts[p.dimension] = (dimCounts[p.dimension] ?? 0) + 1;
    }

    final plan = IqSessionPlan(
      schemaVersion: IqSessionContract.schemaVersion,
      bankVersion: bank.bankVersion,
      bankLocale: bank.locale,
      sessionSeed: config.sessionSeed,
      itemPlans: itemPlans,
      dimensionCounts: dimCounts,
      createdFromBankItemCount: bank.items.length,
      selectionPolicyVersion: config.selectionPolicyVersion,
      balanceDisplayedCorrectPositions: config.balanceDisplayedCorrectPositions,
      eligibilityMode: config.eligibilityMode,
      freshnessMode: config.freshnessMode,
    );

    final validation = IqSessionPlanValidator.validate(
      plan: plan,
      bank: bank,
    );
    if (!validation.ok) {
      return IqSessionCompositionFailure(
        code: 'post_compose_validation_failed',
        message: validation.issues.map((e) => e.message).join('; '),
      );
    }

    // Contract quotas must match bank contract live session targets.
    assert(
      IqSessionContract.dimensionQuotas.toString() ==
          IqBankContract.liveSessionDistribution.toString(),
    );

    return IqSessionCompositionSuccess(plan);
  }

  /// Deterministic interleave: avoid >3 same-dimension streak when possible.
  static List<IqRecoveredBankItem> _interleave({
    required Map<String, List<IqRecoveredBankItem>> selectedByDim,
    required IqSessionConfig config,
    required String bankVersion,
  }) {
    final pools = <String, List<IqRecoveredBankItem>>{};
    for (final dim in IqCanonicalDimensions.all) {
      final rng = IqDeterministicRng.forSession(
        selectionPolicyVersion: config.selectionPolicyVersion,
        bankVersion: bankVersion,
        sessionSeed: config.sessionSeed,
        stream: 'interleave_pool:$dim',
      );
      final sorted = List<IqRecoveredBankItem>.from(selectedByDim[dim]!)
        ..sort((a, b) => a.id.compareTo(b.id));
      pools[dim] = rng.shuffledCopy(sorted);
    }

    final remaining = <String, int>{
      for (final e in IqSessionContract.dimensionQuotas.entries) e.key: e.value,
    };
    final schedule = <String>[];
    while (schedule.length < IqSessionContract.sessionItemCount) {
      var candidates = remaining.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toList()
        ..sort();
      if (candidates.isEmpty) break;

      String? avoid;
      if (schedule.length >= IqSessionContract.maxSameDimensionStreak) {
        final window = schedule.sublist(
          schedule.length - IqSessionContract.maxSameDimensionStreak,
        );
        if (window.every((d) => d == window.first)) {
          avoid = window.first;
        }
      }
      if (avoid != null) {
        final filtered = candidates.where((d) => d != avoid).toList();
        if (filtered.isNotEmpty) candidates = filtered;
      }

      // Prefer dimensions with more remaining to reduce end-game forcing.
      final maxRem =
          candidates.map((d) => remaining[d]!).reduce((a, b) => a > b ? a : b);
      final top = candidates.where((d) => remaining[d] == maxRem).toList();
      final pickRng = IqDeterministicRng.forSession(
        selectionPolicyVersion: config.selectionPolicyVersion,
        bankVersion: bankVersion,
        sessionSeed: config.sessionSeed,
        stream: 'interleave_sched:${schedule.length}',
      );
      final dim = pickRng.shuffledCopy(top).first;
      schedule.add(dim);
      remaining[dim] = remaining[dim]! - 1;
    }

    final result = <IqRecoveredBankItem>[];
    for (final dim in schedule) {
      result.add(pools[dim]!.removeAt(0));
    }
    return result;
  }

  /// One position appears 7 times; the other three appear 6 (for n=25).
  static List<int> _balancedCorrectPositions({
    required int count,
    required IqSessionConfig config,
    required String bankVersion,
  }) {
    assert(count == IqSessionContract.sessionItemCount);
    final rng = IqDeterministicRng.forSession(
      selectionPolicyVersion: config.selectionPolicyVersion,
      bankVersion: bankVersion,
      sessionSeed: config.sessionSeed,
      stream: 'answer_pos_balance',
    );
    final positions = <int>[];
    // Which slot gets the extra (7th) assignment.
    final boosted = rng.nextInt(IqSessionContract.optionCount);
    for (var p = 0; p < IqSessionContract.optionCount; p++) {
      final n = p == boosted ? 7 : 6;
      for (var i = 0; i < n; i++) {
        positions.add(p);
      }
    }
    return rng.shuffledCopy(positions);
  }

  static List<String> _displayOrderWithCorrectAt({
    required List<String> sourceOptionIds,
    required String correctOptionId,
    required int targetPosition,
    required IqSessionConfig config,
    required String bankVersion,
    required String itemId,
  }) {
    if (!sourceOptionIds.contains(correctOptionId)) {
      throw StateError('correct_option_id missing from options for $itemId');
    }
    final distractors =
        sourceOptionIds.where((id) => id != correctOptionId).toList();
    final rng = IqDeterministicRng.forSession(
      selectionPolicyVersion: config.selectionPolicyVersion,
      bankVersion: bankVersion,
      sessionSeed: config.sessionSeed,
      stream: 'option_shuffle:$itemId',
    );
    final shuffledDistractors = rng.shuffledCopy(distractors);
    final displayed = List<String>.filled(
      IqSessionContract.optionCount,
      '',
    );
    displayed[targetPosition] = correctOptionId;
    var di = 0;
    for (var i = 0; i < displayed.length; i++) {
      if (i == targetPosition) continue;
      displayed[i] = shuffledDistractors[di++];
    }
    return displayed;
  }
}
