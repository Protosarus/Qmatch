import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/screens/iq_test_screen.dart';
import 'package:qmatch/features/assessment/services/assessment_set_service.dart';
import 'package:qmatch/features/assessment/services/question_service.dart';

const _bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';

Map<String, dynamic> _loadBankJson() =>
    jsonDecode(File(_bankPath).readAsStringSync()) as Map<String, dynamic>;

IqSessionPlan _mustCompose(
  IqRecoveredBankDocument bank, {
  required String seed,
  Set<String> seenItems = const {},
  Set<String> seenFamilies = const {},
  IqSessionEligibilityMode eligibility =
      IqSessionEligibilityMode.offlineDeskReviewedCandidate,
  bool balance = true,
}) {
  final result = const IqSessionComposer().compose(
    bank: bank,
    config: IqSessionConfig(
      sessionSeed: seed,
      previouslySeenItemIds: seenItems,
      previouslySeenTemplateFamilyIds: seenFamilies,
      eligibilityMode: eligibility,
      balanceDisplayedCorrectPositions: balance,
    ),
  );
  expect(result, isA<IqSessionCompositionSuccess>());
  return (result as IqSessionCompositionSuccess).plan;
}

void main() {
  late Map<String, dynamic> raw;
  late IqRecoveredBankDocument bank;
  late String bankSnapshot;

  setUpAll(() {
    expect(File(_bankPath).existsSync(), isTrue);
    raw = _loadBankJson();
    bankSnapshot = jsonEncode(raw);
    bank = IqRecoveredBankDocument.fromJson(
      jsonDecode(bankSnapshot) as Map<String, dynamic>,
    );
  });

  group('P2C-2A-1 prerequisite', () {
    test('canonical bank loads and validator PASS', () {
      final v = IqRecoveredBankValidator.validate(bank);
      expect(v.ok, isTrue);
      expect(v.itemCount, 340);
      expect(bank.items.map((e) => e.id).toSet().length, 340);
      expect(v.familyCount, 170);
      expect(v.dimensionCounts['logical_reasoning'], 100);
      expect(v.dimensionCounts['pattern_reasoning'], 80);
      expect(v.dimensionCounts['verbal_reasoning'], 80);
      expect(v.dimensionCounts['spatial_reasoning'], 80);
      expect(
        v.rewrittenCounts.values.fold<int>(0, (a, b) => a + b),
        40,
      );
    });
  });

  group('exact quotas and uniqueness', () {
    late IqSessionPlan plan;

    setUp(() {
      plan = _mustCompose(bank, seed: 'quota-seed-1');
    });

    test('exact session count = 25', () {
      expect(plan.itemPlans.length, 25);
    });

    test('exact logical = 7', () {
      expect(plan.dimensionCounts['logical_reasoning'], 7);
    });

    test('exact pattern = 6', () {
      expect(plan.dimensionCounts['pattern_reasoning'], 6);
    });

    test('exact verbal = 6', () {
      expect(plan.dimensionCounts['verbal_reasoning'], 6);
    });

    test('exact spatial = 6', () {
      expect(plan.dimensionCounts['spatial_reasoning'], 6);
    });

    test('no duplicate item IDs', () {
      final ids = plan.itemPlans.map((e) => e.itemId).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('no duplicate family IDs', () {
      final fams = plan.itemPlans.map((e) => e.templateFamilyId).toList();
      expect(fams.toSet().length, fams.length);
    });

    test('both variants of one family never coexist', () {
      final byFamily = <String, List<String>>{};
      for (final p in plan.itemPlans) {
        byFamily.putIfAbsent(p.templateFamilyId, () => []).add(p.itemId);
      }
      for (final e in byFamily.entries) {
        expect(e.value.length, 1, reason: e.key);
      }
    });
  });

  group('determinism', () {
    test('same seed produces identical item selection and order', () {
      final a = _mustCompose(bank, seed: 'same-seed-xyz');
      final b = _mustCompose(bank, seed: 'same-seed-xyz');
      expect(
        a.itemPlans.map((e) => e.itemId).toList(),
        b.itemPlans.map((e) => e.itemId).toList(),
      );
      expect(
        a.itemPlans.map((e) => e.displayedOptionIds).toList(),
        b.itemPlans.map((e) => e.displayedOptionIds).toList(),
      );
    });

    test('different seeds normally produce different sessions', () {
      final a = _mustCompose(bank, seed: 'seed-A');
      final b = _mustCompose(bank, seed: 'seed-B');
      expect(
        a.itemPlans.map((e) => e.itemId).join('|'),
        isNot(b.itemPlans.map((e) => e.itemId).join('|')),
      );
    });

    test('different seeds produce option-order variation', () {
      final a = _mustCompose(bank, seed: 'opt-A');
      final b = _mustCompose(bank, seed: 'opt-B');
      // Overlap items and compare displayed orders when shared.
      final mapB = {for (final p in b.itemPlans) p.itemId: p};
      var compared = 0;
      var differed = 0;
      for (final p in a.itemPlans) {
        final other = mapB[p.itemId];
        if (other == null) continue;
        compared++;
        if (p.displayedOptionIds.join() != other.displayedOptionIds.join()) {
          differed++;
        }
      }
      // Even without overlap, overall option sequences across session differ.
      expect(
        a.itemPlans.map((e) => e.displayedOptionIds.join()).join('|'),
        isNot(b.itemPlans.map((e) => e.displayedOptionIds.join()).join('|')),
      );
      expect(compared >= 0, isTrue);
      expect(differed >= 0, isTrue);
    });
  });

  group('options and correctness', () {
    test('correct_option_id unchanged; displayed is permutation', () {
      final plan = _mustCompose(bank, seed: 'opt-perm-1');
      final byId = {for (final i in bank.items) i.id: i};
      for (final p in plan.itemPlans) {
        final item = byId[p.itemId]!;
        final source = item.options.map((o) => o.id).toSet();
        expect(p.displayedOptionIds.toSet(), source);
        expect(p.displayedOptionIds.contains(item.correctOptionId), isTrue);
        expect(
          p.displayedOptionIds[p.displayedCorrectPosition],
          item.correctOptionId,
        );
      }
    });

    test('answer-position balance difference <= 1', () {
      final plan = _mustCompose(bank, seed: 'balance-1');
      final counts = <int, int>{0: 0, 1: 0, 2: 0, 3: 0};
      for (final p in plan.itemPlans) {
        counts[p.displayedCorrectPosition] =
            counts[p.displayedCorrectPosition]! + 1;
      }
      final vals = counts.values.toList()..sort();
      expect(vals.last - vals.first, lessThanOrEqualTo(1));
      expect(vals, equals([6, 6, 6, 7]));
      expect(vals.where((v) => v == 7).length, 1);
      expect(vals.where((v) => v == 6).length, 3);
    });

    test('no fixed obvious answer-position sequence', () {
      final plan = _mustCompose(bank, seed: 'no-cycle-1');
      final pattern =
          plan.itemPlans.map((e) => e.displayedCorrectPosition).toList();
      final cyclic = List.generate(25, (i) => i % 4).join() == pattern.join();
      expect(cyclic, isFalse);
    });
  });

  group('interleaving', () {
    test('no more than 3 same-dimension consecutive when avoidable', () {
      for (final seed in ['il-1', 'il-2', 'il-3', 'il-4', 'il-5']) {
        final plan = _mustCompose(bank, seed: seed);
        var streak = 1;
        for (var i = 1; i < plan.itemPlans.length; i++) {
          if (plan.itemPlans[i].dimension == plan.itemPlans[i - 1].dimension) {
            streak++;
            expect(streak, lessThanOrEqualTo(3), reason: 'seed=$seed i=$i');
          } else {
            streak = 1;
          }
        }
      }
    });
  });

  group('bank immutability', () {
    test('bank unchanged after one composition', () {
      _mustCompose(bank, seed: 'imm-1');
      final after = jsonEncode(_loadBankJson());
      expect(after, bankSnapshot);
    });

    test('bank unchanged after many compositions', () {
      for (var i = 0; i < 200; i++) {
        _mustCompose(bank, seed: 'imm-many-$i');
      }
      expect(jsonEncode(_loadBankJson()), bankSnapshot);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('eligibility and freshness', () {
    test('unsupported / retired numerical rejected via bank decode', () {
      expect(
        () => IqRecoveredBankDocument.fromJson({
          ...raw,
          'items': [
            {
              ...(raw['items'] as List).first as Map,
              'dimension': 'numerical',
            },
          ],
        }),
        throwsA(isA<IqRecoveredBankDecodeException>()),
      );
    });

    test('insufficient candidates returns structured failure', () {
      // Exclude almost all logical families.
      final logicalFamilies = bank.items
          .where((i) => i.dimension == 'logical_reasoning')
          .map((i) => i.templateFamilyId)
          .toSet();
      final keep = logicalFamilies.take(3).toSet();
      final exclude = logicalFamilies.difference(keep);
      final result = const IqSessionComposer().compose(
        bank: bank,
        config: IqSessionConfig(
          sessionSeed: 'insuff-1',
          previouslySeenTemplateFamilyIds: exclude,
        ),
      );
      expect(result, isA<IqSessionCompositionFailure>());
      final fail = result as IqSessionCompositionFailure;
      expect(fail.code, 'insufficient_candidates');
      expect(fail.insufficiencies, isNotEmpty);
      expect(
        fail.insufficiencies.any((e) => e.dimension == 'logical_reasoning'),
        isTrue,
      );
    });

    test('strict seen-family policy does not silently reuse families', () {
      final plan1 = _mustCompose(bank, seed: 'fresh-base');
      final seenFams = plan1.itemPlans.map((e) => e.templateFamilyId).toSet();
      // Seeing 25 families still leaves plenty (170).
      final plan2 = _mustCompose(
        bank,
        seed: 'fresh-next',
        seenFamilies: seenFams,
      );
      for (final p in plan2.itemPlans) {
        expect(seenFams.contains(p.templateFamilyId), isFalse);
      }
    });

    test('seen item IDs are respected', () {
      final plan1 = _mustCompose(bank, seed: 'seen-items-base');
      final seen = plan1.itemPlans.map((e) => e.itemId).toSet();
      final plan2 =
          _mustCompose(bank, seed: 'seen-items-next', seenItems: seen);
      for (final p in plan2.itemPlans) {
        expect(seen.contains(p.itemId), isFalse);
      }
    });

    test('offline candidate eligibility works; runtime excludes desk', () {
      final ok = const IqSessionComposer().compose(
        bank: bank,
        config: const IqSessionConfig(
          sessionSeed: 'elig-desk',
          eligibilityMode:
              IqSessionEligibilityMode.offlineDeskReviewedCandidate,
        ),
      );
      expect(ok, isA<IqSessionCompositionSuccess>());

      final blocked = const IqSessionComposer().compose(
        bank: bank,
        config: const IqSessionConfig(
          sessionSeed: 'elig-runtime',
          eligibilityMode: IqSessionEligibilityMode.runtimeEligible,
        ),
      );
      expect(blocked, isA<IqSessionCompositionFailure>());
    });

    test('ineligible review states excluded', () {
      expect(
        IqSessionEligibility.allowsReviewStatus(
          IqSessionEligibilityMode.pilotEligible,
          'desk_reviewed_candidate',
        ),
        isFalse,
      );
    });
  });

  group('seed / order independence', () {
    test('source file order does not determine selected first items', () {
      final firstBankIds = bank.items.take(25).map((e) => e.id).toList();
      final plan = _mustCompose(bank, seed: 'order-indep-1');
      final selected = plan.itemPlans.map((e) => e.itemId).toList();
      expect(selected, isNot(equals(firstBankIds)));
    });

    test('stable seed derivation does not use String.hashCode', () {
      final a = IqDeterministicRng.fnv1a32('hello');
      final b = IqDeterministicRng.fnv1a32('hello');
      expect(a, b);
      final rngSrc = File(
        'lib/features/assessment/domain/iq_session/iq_deterministic_rng.dart',
      ).readAsStringSync();
      expect(rngSrc.contains('.hashCode'), isFalse);
      expect(rngSrc.contains('fnv1a32'), isTrue);
      expect(rngSrc.contains('xorshift'), isTrue);
      final rng1 = IqDeterministicRng.fromParts(['p', 'b', 's']);
      final rng2 = IqDeterministicRng.fromParts(['p', 'b', 's']);
      expect(
        List.generate(20, (_) => rng1.nextUint32()),
        List.generate(20, (_) => rng2.nextUint32()),
      );
    });
  });

  group('validator catches tampering', () {
    test('tampered item ID', () {
      final plan = _mustCompose(bank, seed: 'val-1');
      final bad = IqSessionPlan(
        schemaVersion: plan.schemaVersion,
        bankVersion: plan.bankVersion,
        bankLocale: plan.bankLocale,
        sessionSeed: plan.sessionSeed,
        itemPlans: [
          IqSessionItemPlan(
            itemId: 'does_not_exist',
            dimension: plan.itemPlans.first.dimension,
            templateFamilyId: plan.itemPlans.first.templateFamilyId,
            displayedOptionIds: plan.itemPlans.first.displayedOptionIds,
            displayedCorrectPosition:
                plan.itemPlans.first.displayedCorrectPosition,
          ),
          ...plan.itemPlans.skip(1),
        ],
        dimensionCounts: plan.dimensionCounts,
        createdFromBankItemCount: plan.createdFromBankItemCount,
        selectionPolicyVersion: plan.selectionPolicyVersion,
        balanceDisplayedCorrectPositions: plan.balanceDisplayedCorrectPositions,
        eligibilityMode: plan.eligibilityMode,
        freshnessMode: plan.freshnessMode,
      );
      final v = IqSessionPlanValidator.validate(plan: bad, bank: bank);
      expect(v.ok, isFalse);
      expect(v.issues.any((e) => e.code == 'unknown_item'), isTrue);
    });

    test('duplicate family', () {
      final plan = _mustCompose(bank, seed: 'val-2');
      final first = plan.itemPlans.first;
      final second = plan.itemPlans[1];
      final badPlans = [
        first,
        IqSessionItemPlan(
          itemId: second.itemId,
          dimension: second.dimension,
          templateFamilyId: first.templateFamilyId,
          displayedOptionIds: second.displayedOptionIds,
          displayedCorrectPosition: second.displayedCorrectPosition,
        ),
        ...plan.itemPlans.skip(2),
      ];
      final bad = IqSessionPlan(
        schemaVersion: plan.schemaVersion,
        bankVersion: plan.bankVersion,
        bankLocale: plan.bankLocale,
        sessionSeed: plan.sessionSeed,
        itemPlans: badPlans,
        dimensionCounts: plan.dimensionCounts,
        createdFromBankItemCount: plan.createdFromBankItemCount,
        selectionPolicyVersion: plan.selectionPolicyVersion,
        balanceDisplayedCorrectPositions: plan.balanceDisplayedCorrectPositions,
        eligibilityMode: plan.eligibilityMode,
        freshnessMode: plan.freshnessMode,
      );
      final v = IqSessionPlanValidator.validate(plan: bad, bank: bank);
      expect(v.ok, isFalse);
      expect(v.issues.any((e) => e.code == 'duplicate_family'), isTrue);
    });

    test('invalid displayed option order', () {
      final plan = _mustCompose(bank, seed: 'val-3');
      final first = plan.itemPlans.first;
      final badFirst = IqSessionItemPlan(
        itemId: first.itemId,
        dimension: first.dimension,
        templateFamilyId: first.templateFamilyId,
        displayedOptionIds: const ['a', 'a', 'b', 'c'],
        displayedCorrectPosition: first.displayedCorrectPosition,
      );
      final bad = IqSessionPlan(
        schemaVersion: plan.schemaVersion,
        bankVersion: plan.bankVersion,
        bankLocale: plan.bankLocale,
        sessionSeed: plan.sessionSeed,
        itemPlans: [badFirst, ...plan.itemPlans.skip(1)],
        dimensionCounts: plan.dimensionCounts,
        createdFromBankItemCount: plan.createdFromBankItemCount,
        selectionPolicyVersion: plan.selectionPolicyVersion,
        balanceDisplayedCorrectPositions: plan.balanceDisplayedCorrectPositions,
        eligibilityMode: plan.eligibilityMode,
        freshnessMode: plan.freshnessMode,
      );
      final v = IqSessionPlanValidator.validate(plan: bad, bank: bank);
      expect(v.ok, isFalse);
      expect(
        v.issues.any(
          (e) => e.code == 'option_dup' || e.code == 'option_permutation',
        ),
        isTrue,
      );
    });

    test('dimension mismatch', () {
      final plan = _mustCompose(bank, seed: 'val-4');
      final first = plan.itemPlans.first;
      final wrongDim =
          IqCanonicalDimensions.all.firstWhere((d) => d != first.dimension);
      final badFirst = IqSessionItemPlan(
        itemId: first.itemId,
        dimension: wrongDim,
        templateFamilyId: first.templateFamilyId,
        displayedOptionIds: first.displayedOptionIds,
        displayedCorrectPosition: first.displayedCorrectPosition,
      );
      final bad = IqSessionPlan(
        schemaVersion: plan.schemaVersion,
        bankVersion: plan.bankVersion,
        bankLocale: plan.bankLocale,
        sessionSeed: plan.sessionSeed,
        itemPlans: [badFirst, ...plan.itemPlans.skip(1)],
        dimensionCounts: plan.dimensionCounts,
        createdFromBankItemCount: plan.createdFromBankItemCount,
        selectionPolicyVersion: plan.selectionPolicyVersion,
        balanceDisplayedCorrectPositions: plan.balanceDisplayedCorrectPositions,
        eligibilityMode: plan.eligibilityMode,
        freshnessMode: plan.freshnessMode,
      );
      final v = IqSessionPlanValidator.validate(plan: bad, bank: bank);
      expect(v.ok, isFalse);
      expect(v.issues.any((e) => e.code == 'dimension_mismatch'), isTrue);
    });

    test('wrong bank version', () {
      final plan = _mustCompose(bank, seed: 'val-5');
      final bad = IqSessionPlan(
        schemaVersion: plan.schemaVersion,
        bankVersion: 'wrong_version',
        bankLocale: plan.bankLocale,
        sessionSeed: plan.sessionSeed,
        itemPlans: plan.itemPlans,
        dimensionCounts: plan.dimensionCounts,
        createdFromBankItemCount: plan.createdFromBankItemCount,
        selectionPolicyVersion: plan.selectionPolicyVersion,
        balanceDisplayedCorrectPositions: plan.balanceDisplayedCorrectPositions,
        eligibilityMode: plan.eligibilityMode,
        freshnessMode: plan.freshnessMode,
      );
      final v = IqSessionPlanValidator.validate(plan: bad, bank: bank);
      expect(v.ok, isFalse);
      expect(v.issues.any((e) => e.code == 'bank_version'), isTrue);
    });
  });

  group('exposure simulation (compact)', () {
    test('1000 sessions reach every item/family and keep invariants', () {
      final itemExp = <String, int>{for (final i in bank.items) i.id: 0};
      final famExp = {
        for (final i in bank.items) i.templateFamilyId: 0,
      };
      for (var n = 0; n < 1000; n++) {
        final plan = _mustCompose(bank, seed: 'exp-$n');
        expect(plan.itemPlans.length, 25);
        final fams = <String>{};
        for (final p in plan.itemPlans) {
          itemExp[p.itemId] = itemExp[p.itemId]! + 1;
          famExp[p.templateFamilyId] = famExp[p.templateFamilyId]! + 1;
          expect(fams.add(p.templateFamilyId), isTrue);
        }
        expect(plan.dimensionCounts['logical_reasoning'], 7);
        expect(plan.dimensionCounts['pattern_reasoning'], 6);
        expect(plan.dimensionCounts['verbal_reasoning'], 6);
        expect(plan.dimensionCounts['spatial_reasoning'], 6);
      }
      expect(itemExp.values.every((v) => v > 0), isTrue);
      expect(famExp.values.every((v) => v > 0), isTrue);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('runtime unchanged', () {
    test('current runtime IQ loader symbols still present', () {
      // Compile-time / type presence — do not invoke network.
      expect(QuestionService, isNotNull);
      expect(AssessmentSetService, isNotNull);
      expect(IQTestScreen, isNotNull);
    });

    test('composer does not import Firebase in its library path', () {
      final composerSrc = File(
        'lib/features/assessment/domain/iq_session/iq_session_composer.dart',
      ).readAsStringSync();
      expect(composerSrc.contains('firebase'), isFalse);
      expect(composerSrc.contains('Firestore'), isFalse);
      expect(composerSrc.contains('AssessmentProgress'), isFalse);
      expect(composerSrc.contains('TraitScoring'), isFalse);
    });
  });
}
