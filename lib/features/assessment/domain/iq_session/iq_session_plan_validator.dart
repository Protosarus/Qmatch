import '../iq_bank/iq_canonical_dimensions.dart';
import '../iq_bank/iq_recovered_bank_document.dart';
import 'iq_session_contract.dart';
import 'iq_session_models.dart';

/// Hard invariant checks for an [IqSessionPlan] against its bank.
class IqSessionPlanValidator {
  IqSessionPlanValidator._();

  static IqSessionValidationResult validate({
    required IqSessionPlan plan,
    required IqRecoveredBankDocument bank,
  }) {
    final issues = <IqSessionValidationIssue>[];

    void fail(String code, String message) {
      issues.add(IqSessionValidationIssue(code: code, message: message));
    }

    if (plan.schemaVersion != IqSessionContract.schemaVersion) {
      fail('schema_version', 'Unexpected schema_version=${plan.schemaVersion}');
    }
    if (plan.selectionPolicyVersion !=
        IqSessionContract.selectionPolicyVersion) {
      fail(
        'selection_policy_version',
        'Unexpected selection_policy_version=${plan.selectionPolicyVersion}',
      );
    }
    if (plan.sessionSeed.trim().isEmpty) {
      fail('session_seed', 'session_seed must be present');
    }
    if (plan.bankVersion != bank.bankVersion) {
      fail(
        'bank_version',
        'Plan bank_version=${plan.bankVersion} != bank ${bank.bankVersion}',
      );
    }
    if (plan.bankLocale != bank.locale) {
      fail(
        'bank_locale',
        'Plan locale=${plan.bankLocale} != bank ${bank.locale}',
      );
    }
    if (plan.itemPlans.length != IqSessionContract.sessionItemCount) {
      fail(
        'item_count',
        'Expected ${IqSessionContract.sessionItemCount}, got ${plan.itemPlans.length}',
      );
    }

    final byId = {for (final i in bank.items) i.id: i};
    final seenIds = <String>{};
    final seenFamilies = <String>{};
    final dimCounts = <String, int>{
      for (final d in IqCanonicalDimensions.all) d: 0,
    };
    final positionCounts = <int, int>{0: 0, 1: 0, 2: 0, 3: 0};

    for (var i = 0; i < plan.itemPlans.length; i++) {
      final p = plan.itemPlans[i];
      if (!seenIds.add(p.itemId)) {
        fail('duplicate_item', 'Duplicate item_id=${p.itemId} at index $i');
      }
      if (!seenFamilies.add(p.templateFamilyId)) {
        fail(
          'duplicate_family',
          'Duplicate template_family_id=${p.templateFamilyId} at index $i',
        );
      }
      final bankItem = byId[p.itemId];
      if (bankItem == null) {
        fail('unknown_item', 'item_id=${p.itemId} not in bank');
        continue;
      }
      if (IqCanonicalDimensions.isRetired(p.dimension) ||
          IqCanonicalDimensions.isRetired(bankItem.dimension)) {
        fail('retired_dimension', 'Retired dimension on ${p.itemId}');
      }
      if (p.dimension != bankItem.dimension) {
        fail(
          'dimension_mismatch',
          '${p.itemId}: plan=${p.dimension} bank=${bankItem.dimension}',
        );
      }
      if (p.templateFamilyId != bankItem.templateFamilyId) {
        fail(
          'family_mismatch',
          '${p.itemId}: plan=${p.templateFamilyId} bank=${bankItem.templateFamilyId}',
        );
      }
      dimCounts[p.dimension] = (dimCounts[p.dimension] ?? 0) + 1;

      if (p.displayedOptionIds.length != IqSessionContract.optionCount) {
        fail(
          'option_count',
          '${p.itemId}: expected 4 displayed options',
        );
      }
      final sourceIds = bankItem.options.map((o) => o.id).toSet();
      final disp = p.displayedOptionIds.toSet();
      if (disp.length != p.displayedOptionIds.length) {
        fail('option_dup', '${p.itemId}: duplicate displayed option ids');
      }
      if (disp.length != sourceIds.length || !disp.containsAll(sourceIds)) {
        fail(
          'option_permutation',
          '${p.itemId}: displayed options are not a permutation of source',
        );
      }
      if (!p.displayedOptionIds.contains(bankItem.correctOptionId)) {
        fail(
          'correct_missing',
          '${p.itemId}: correct_option_id absent from displayed order',
        );
      }
      final pos = p.displayedCorrectPosition;
      if (pos < 0 || pos >= p.displayedOptionIds.length) {
        fail('correct_pos_range',
            '${p.itemId}: invalid displayedCorrectPosition');
      } else if (p.displayedOptionIds[pos] != bankItem.correctOptionId) {
        fail(
          'correct_pos_mismatch',
          '${p.itemId}: displayedCorrectPosition does not point at correct_option_id',
        );
      }
      positionCounts[pos] = (positionCounts[pos] ?? 0) + 1;
    }

    for (final e in IqSessionContract.dimensionQuotas.entries) {
      final got = dimCounts[e.key] ?? 0;
      if (got != e.value) {
        fail(
          'quota',
          '${e.key}: expected ${e.value}, got $got',
        );
      }
    }

    // Streak check (advisory hard when avoidable — composer should satisfy).
    var streak = 1;
    for (var i = 1; i < plan.itemPlans.length; i++) {
      if (plan.itemPlans[i].dimension == plan.itemPlans[i - 1].dimension) {
        streak++;
        if (streak > IqSessionContract.maxSameDimensionStreak) {
          fail(
            'dimension_streak',
            'More than ${IqSessionContract.maxSameDimensionStreak} '
                'consecutive ${plan.itemPlans[i].dimension} at index $i',
          );
        }
      } else {
        streak = 1;
      }
    }

    if (plan.balanceDisplayedCorrectPositions) {
      final counts = positionCounts.values.toList()..sort();
      if (counts.isNotEmpty) {
        final spread = counts.last - counts.first;
        if (spread > IqSessionContract.maxAnswerPositionBalanceSpread) {
          fail(
            'answer_position_balance',
            'Displayed correct position spread=$spread counts=$positionCounts',
          );
        }
      }
    }

    // Reject obvious fixed repeating pattern A B C D A B C D ...
    if (plan.itemPlans.length >= 8) {
      final pattern =
          plan.itemPlans.map((e) => e.displayedCorrectPosition).toList();
      var cyclic = true;
      for (var i = 0; i < pattern.length; i++) {
        if (pattern[i] != i % 4) {
          cyclic = false;
          break;
        }
      }
      if (cyclic) {
        fail(
          'obvious_position_pattern',
          'Displayed correct positions form an obvious 0,1,2,3 cycle',
        );
      }
    }

    return IqSessionValidationResult(ok: issues.isEmpty, issues: issues);
  }
}
