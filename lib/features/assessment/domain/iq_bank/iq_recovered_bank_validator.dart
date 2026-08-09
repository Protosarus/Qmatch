import 'iq_bank_contract.dart';
import 'iq_canonical_dimensions.dart';
import 'iq_recovered_bank_document.dart';

/// Strict offline checks for the recovered 340-item bank (not production loader).
class IqRecoveredBankValidationReport {
  IqRecoveredBankValidationReport({
    required this.errors,
    required this.dimensionCounts,
    required this.familyCount,
    required this.rewrittenCounts,
    required this.answerPositionCounts,
    required this.itemCount,
  });

  final List<String> errors;
  final Map<String, int> dimensionCounts;
  final int familyCount;
  final Map<String, int> rewrittenCounts;
  final Map<String, int> answerPositionCounts;
  final int itemCount;

  bool get ok => errors.isEmpty;
}

class IqRecoveredBankValidator {
  IqRecoveredBankValidator._();

  static IqRecoveredBankValidationReport validate(
      IqRecoveredBankDocument bank) {
    final errors = <String>[];
    final items = bank.items;

    if (items.length != IqRecoveredBankDocument.expectedItemCount) {
      errors.add('Expected 340 items, found ${items.length}');
    }
    if (bank.bankVersion != IqRecoveredBankDocument.expectedBankVersion) {
      errors.add('Unexpected bank_version=${bank.bankVersion}');
    }

    final ids = items.map((i) => i.id).toList();
    if (ids.toSet().length != ids.length) {
      errors.add('Duplicate item IDs');
    }

    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final prompts = items.map((i) => norm(i.prompt)).toList();
    if (prompts.toSet().length != prompts.length) {
      errors.add('Duplicate normalized prompts');
    }

    final dimCounts = <String, int>{
      for (final d in IqCanonicalDimensions.all) d: 0,
    };
    final families = <String, List<String>>{};
    final rewritten = <String, int>{
      for (final d in IqCanonicalDimensions.all) d: 0,
    };
    final answers = <String, int>{'a': 0, 'b': 0, 'c': 0, 'd': 0};

    for (final item in items) {
      dimCounts[item.dimension] = (dimCounts[item.dimension] ?? 0) + 1;
      families.putIfAbsent(item.templateFamilyId, () => []).add(item.id);
      if (item.revisionStatus == 'rewritten_v2') {
        rewritten[item.dimension] = (rewritten[item.dimension] ?? 0) + 1;
      }
      answers[item.correctOptionId] = (answers[item.correctOptionId] ?? 0) + 1;
    }

    IqBankContract.recoveredDimensionDistribution.forEach((dim, n) {
      if (dimCounts[dim] != n) {
        errors.add('$dim: expected $n, found ${dimCounts[dim]}');
      }
    });

    if (families.length != IqBankContract.recoveredTemplateFamilyCount) {
      errors.add(
        'Expected ${IqBankContract.recoveredTemplateFamilyCount} families, '
        'found ${families.length}',
      );
    }
    final badFamilies =
        families.entries.where((e) => e.value.length != 2).toList();
    if (badFamilies.isNotEmpty) {
      errors
          .add('${badFamilies.length} families do not have exactly 2 variants');
    }

    final rewrittenTotal = rewritten.values.fold<int>(0, (a, b) => a + b);
    if (rewrittenTotal != IqBankContract.recoveredRewrittenCount) {
      errors.add(
        'Expected ${IqBankContract.recoveredRewrittenCount} rewritten, '
        'found $rewrittenTotal',
      );
    }
    IqBankContract.recoveredRewrittenDistribution.forEach((dim, n) {
      if (rewritten[dim] != n) {
        errors.add('rewritten $dim: expected $n, found ${rewritten[dim]}');
      }
    });

    IqBankContract.recoveredAnswerPositionDistribution.forEach((letter, n) {
      if (answers[letter] != n) {
        errors.add('answer $letter: expected $n, found ${answers[letter]}');
      }
    });

    return IqRecoveredBankValidationReport(
      errors: errors,
      dimensionCounts: dimCounts,
      familyCount: families.length,
      rewrittenCounts: rewritten,
      answerPositionCounts: answers,
      itemCount: items.length,
    );
  }
}
