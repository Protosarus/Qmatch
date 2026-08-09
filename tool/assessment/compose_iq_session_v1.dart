// ignore_for_file: avoid_print
/// Offline CLI: compose one deterministic IQ session from the recovered bank.
///
/// Development-only. Do not expose correct-answer audit fields in production UI.
///
/// Usage:
///   dart run tool/assessment/compose_iq_session_v1.dart --seed demo-seed-1
///   dart run tool/assessment/compose_iq_session_v1.dart --seed 42 --json
library;

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';

void main(List<String> args) {
  var bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';
  var seed = 'demo-seed-1';
  var asJson = false;
  final seenItems = <String>{};
  final seenFamilies = <String>{};

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--bank' && i + 1 < args.length) {
      bankPath = args[++i];
    } else if (a == '--seed' && i + 1 < args.length) {
      seed = args[++i];
    } else if (a == '--json') {
      asJson = true;
    } else if (a == '--seen-item' && i + 1 < args.length) {
      seenItems.add(args[++i]);
    } else if (a == '--seen-family' && i + 1 < args.length) {
      seenFamilies.add(args[++i]);
    } else if (a == '--help' || a == '-h') {
      stdout.writeln(
        'Usage: dart run tool/assessment/compose_iq_session_v1.dart '
        '[--bank PATH] [--seed SEED] [--json] '
        '[--seen-item ID] [--seen-family ID]',
      );
      exit(0);
    }
  }

  final raw =
      jsonDecode(File(bankPath).readAsStringSync()) as Map<String, dynamic>;
  final bank = IqRecoveredBankDocument.fromJson(raw);
  final bankValidation = IqRecoveredBankValidator.validate(bank);
  if (!bankValidation.ok) {
    stderr.writeln('BANK_VALIDATOR_FAIL: ${bankValidation.errors}');
    exit(2);
  }

  final result = const IqSessionComposer().compose(
    bank: bank,
    config: IqSessionConfig(
      sessionSeed: seed,
      previouslySeenItemIds: seenItems,
      previouslySeenTemplateFamilyIds: seenFamilies,
    ),
  );

  if (result is IqSessionCompositionFailure) {
    stderr.writeln('COMPOSE_FAIL ${result.code}: ${result.message}');
    for (final i in result.insufficiencies) {
      stderr.writeln('  $i');
    }
    exit(1);
  }

  final plan = (result as IqSessionCompositionSuccess).plan;
  final byId = {for (final i in bank.items) i.id: i};

  if (asJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(plan.toJson()));
    exit(0);
  }

  stdout.writeln('IQ Session Composer v1');
  stdout
      .writeln('seed=$seed bank=${plan.bankVersion} locale=${plan.bankLocale}');
  stdout.writeln('policy=${plan.selectionPolicyVersion}');
  stdout.writeln('items=${plan.itemPlans.length} dims=${plan.dimensionCounts}');
  stdout.writeln('---');
  for (var i = 0; i < plan.itemPlans.length; i++) {
    final p = plan.itemPlans[i];
    final item = byId[p.itemId]!;
    stdout.writeln(
      '${(i + 1).toString().padLeft(2)}. ${p.itemId}  '
      'dim=${p.dimension}  family=${p.templateFamilyId}  '
      'opts=${p.displayedOptionIds.join(",")}  '
      'correct_id=${item.correctOptionId}  '
      'audit_pos=${p.displayedCorrectPosition}',
    );
  }
  stdout.writeln('---');
  stdout.writeln(
      'family_unique=${plan.itemPlans.map((e) => e.templateFamilyId).toSet().length == 25}');
  stdout.writeln('OK');
}
