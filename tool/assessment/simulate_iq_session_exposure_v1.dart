// ignore_for_file: avoid_print
/// Offline exposure fairness simulation for the IQ session composer.
///
/// Composes N deterministic sessions with empty seen-history and reports
/// per-item / per-family exposure. Development-only — not statistical
/// calibration.
///
/// Usage:
///   dart run tool/assessment/simulate_iq_session_exposure_v1.dart
///   dart run tool/assessment/simulate_iq_session_exposure_v1.dart --sessions 10000
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';

void main(List<String> args) {
  var bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';
  var sessions = 10000;
  var outPath =
      'assets/data/assessment_v3/iq/reports/iq_session_composer_exposure_v1.json';

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--bank' && i + 1 < args.length) {
      bankPath = args[++i];
    } else if (a == '--sessions' && i + 1 < args.length) {
      sessions = int.parse(args[++i]);
    } else if (a == '--out' && i + 1 < args.length) {
      outPath = args[++i];
    }
  }

  final raw =
      jsonDecode(File(bankPath).readAsStringSync()) as Map<String, dynamic>;
  final bankBefore = jsonEncode(raw);
  final bank = IqRecoveredBankDocument.fromJson(
    jsonDecode(bankBefore) as Map<String, dynamic>,
  );
  final bankSha = IqDeterministicRng.fnv1a32(bankBefore).toRadixString(16);

  final itemExposure = <String, int>{for (final i in bank.items) i.id: 0};
  final familyExposure = {
    for (final i in bank.items) i.templateFamilyId: 0,
  };
  final dimItemExposure = <String, Map<String, int>>{
    for (final d in IqCanonicalDimensions.all)
      d: {
        for (final i in bank.items.where((e) => e.dimension == d)) i.id: 0,
      },
  };
  final dimFamilyExposure = <String, Map<String, int>>{
    for (final d in IqCanonicalDimensions.all) d: <String, int>{},
  };
  for (final i in bank.items) {
    dimFamilyExposure[i.dimension]!.putIfAbsent(i.templateFamilyId, () => 0);
  }

  final positionCounts = <int, int>{0: 0, 1: 0, 2: 0, 3: 0};
  final dimSlotCounts = <int, Map<String, int>>{
    for (var s = 0; s < 25; s++)
      s: {for (final d in IqCanonicalDimensions.all) d: 0},
  };

  final composer = const IqSessionComposer();
  var failures = 0;

  for (var n = 0; n < sessions; n++) {
    final seed = 'exposure-sim-$n';
    final result = composer.compose(
      bank: bank,
      config: IqSessionConfig(sessionSeed: seed),
    );
    if (result is! IqSessionCompositionSuccess) {
      failures++;
      stderr.writeln('FAIL seed=$seed $result');
      continue;
    }
    final plan = result.plan;
    final fams = <String>{};
    for (var idx = 0; idx < plan.itemPlans.length; idx++) {
      final p = plan.itemPlans[idx];
      itemExposure[p.itemId] = (itemExposure[p.itemId] ?? 0) + 1;
      familyExposure[p.templateFamilyId] =
          (familyExposure[p.templateFamilyId] ?? 0) + 1;
      dimItemExposure[p.dimension]![p.itemId] =
          (dimItemExposure[p.dimension]![p.itemId] ?? 0) + 1;
      dimFamilyExposure[p.dimension]![p.templateFamilyId] =
          (dimFamilyExposure[p.dimension]![p.templateFamilyId] ?? 0) + 1;
      if (!fams.add(p.templateFamilyId)) {
        stderr.writeln('FAMILY_DUP seed=$seed family=${p.templateFamilyId}');
        failures++;
      }
      positionCounts[p.displayedCorrectPosition] =
          (positionCounts[p.displayedCorrectPosition] ?? 0) + 1;
      dimSlotCounts[idx]![p.dimension] =
          (dimSlotCounts[idx]![p.dimension] ?? 0) + 1;
    }
  }

  final bankAfter = jsonEncode(
    jsonDecode(File(bankPath).readAsStringSync()) as Map<String, dynamic>,
  );
  final immutable = bankBefore == bankAfter;

  Map<String, dynamic> summarize(Map<String, int> exposure) {
    final values = exposure.values.toList()..sort();
    if (values.isEmpty) {
      return {
        'min': 0,
        'median': 0,
        'max': 0,
        'mean': 0,
        'cv': 0,
        'never_selected': 0,
      };
    }
    final sum = values.fold<int>(0, (a, b) => a + b);
    final mean = sum / values.length;
    final variance = values.fold<double>(
          0,
          (a, b) => a + (b - mean) * (b - mean),
        ) /
        values.length;
    final sd = math.sqrt(variance);
    final cv = mean == 0 ? 0.0 : sd / mean;
    final mid = values.length ~/ 2;
    final median = values.length.isOdd
        ? values[mid].toDouble()
        : (values[mid - 1] + values[mid]) / 2.0;
    return {
      'min': values.first,
      'median': median,
      'max': values.last,
      'mean': double.parse(mean.toStringAsFixed(4)),
      'cv': double.parse(cv.toStringAsFixed(4)),
      'never_selected': values.where((v) => v == 0).length,
    };
  }

  final neverItems = itemExposure.entries
      .where((e) => e.value == 0)
      .map((e) => e.key)
      .toList()
    ..sort();
  final neverFamilies = familyExposure.entries
      .where((e) => e.value == 0)
      .map((e) => e.key)
      .toList()
    ..sort();

  final report = <String, dynamic>{
    'ok': failures == 0 &&
        neverItems.isEmpty &&
        neverFamilies.isEmpty &&
        immutable,
    'sessions': sessions,
    'failures': failures,
    'bank_path': bankPath,
    'bank_version': bank.bankVersion,
    'bank_fnv1a32_hex': bankSha,
    'selection_policy_version': IqSessionContract.selectionPolicyVersion,
    'bank_immutable': immutable,
    'item_exposure': summarize(itemExposure),
    'family_exposure': summarize(familyExposure),
    'per_dimension_item_exposure': {
      for (final d in IqCanonicalDimensions.all)
        d: summarize(dimItemExposure[d]!),
    },
    'per_dimension_family_exposure': {
      for (final d in IqCanonicalDimensions.all)
        d: summarize(dimFamilyExposure[d]!),
    },
    'items_never_selected': neverItems,
    'families_never_selected': neverFamilies,
    'correct_answer_displayed_position_counts': {
      for (final e in positionCounts.entries) e.key.toString(): e.value,
    },
    'dimension_by_session_slot': {
      for (final e in dimSlotCounts.entries) e.key.toString(): e.value,
    },
    'hard_failure_conditions': {
      'any_valid_item_never_selected': neverItems.isNotEmpty,
      'any_family_structurally_unreachable': neverFamilies.isNotEmpty,
      'quota_or_family_invariant_failures': failures > 0,
      'bank_mutated': !immutable,
    },
    'disclaimer':
        'Algorithmic fairness/exposure testing only — not psychometric calibration.',
  };

  File(outPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  stdout.writeln(jsonEncode({
    'ok': report['ok'],
    'sessions': sessions,
    'failures': failures,
    'never_items': neverItems.length,
    'never_families': neverFamilies.length,
    'out': outPath,
  }));

  exit(report['ok'] == true ? 0 : 1);
}
