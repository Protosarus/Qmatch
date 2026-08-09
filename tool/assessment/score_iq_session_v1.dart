// Development-only: score a completed canonical IQ session (P2C-2A-4).
// Run:
//   dart run tool/assessment/score_iq_session_v1.dart all_correct
//   dart run tool/assessment/score_iq_session_v1.dart all_incorrect
//   dart run tool/assessment/score_iq_session_v1.dart deterministic_mixed
//
// UNCALIBRATED — NOT AN IQ SCORE
// Not a production debug route.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_scoring/iq_scoring.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'deterministic_mixed' : args.first;
  final bank = IqRecoveredBankDocument.fromJson(
    jsonDecode(
      File('assets/data/assessment_v3/iq/iq_bank_tr_v1.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>,
  );
  final byId = {for (final i in bank.items) i.id: i};

  final repo = IqSessionMemoryRepository();
  final manager = IqSessionManager(
    bank: bank,
    repository: repo,
    idFactory: IqSessionIdFactory(random: Random(11)),
    clock: () => DateTime.utc(2026, 8, 9, 14),
  );

  const uid = 'score_cli_uid';
  final created = await manager.getOrCreateActiveSession(
    ownerUid: uid,
    sessionSeed: 'score-cli-seed-v1',
  );
  if (!created.ok || created.state == null) {
    stderr.writeln('CREATE_FAIL ${created.code}');
    exit(1);
  }
  final state = created.state!;
  final sid = state.sessionId;

  for (var i = 0; i < state.itemPlans.length; i++) {
    final p = state.itemPlans[i];
    final item = byId[p.itemId]!;
    final selected = _selectOption(
      mode: mode,
      index: i,
      plan: p,
      correctId: item.correctOptionId,
    );
    final r = await manager.answer(
      ownerUid: uid,
      sessionId: sid,
      itemId: p.itemId,
      selectedOptionId: selected,
    );
    if (!r.ok) {
      stderr.writeln('ANSWER_FAIL ${r.code}');
      exit(2);
    }
  }

  final done = await manager.complete(ownerUid: uid, sessionId: sid);
  if (!done.ok || done.state == null) {
    stderr.writeln('COMPLETE_FAIL ${done.code}');
    exit(3);
  }

  final scored = const IqCanonicalScorer().scoreCompletedSession(
    session: done.state!,
    bank: bank,
    ownerUid: uid,
    clock: () => DateTime.utc(2026, 8, 9, 14, 5),
  );
  if (!scored.ok || scored.result == null) {
    stderr.writeln('SCORE_FAIL ${scored.code}');
    exit(4);
  }

  final result = scored.result!;
  stdout.writeln('==================================================');
  stdout.writeln('UNCALIBRATED — NOT AN IQ SCORE');
  stdout.writeln('==================================================');
  stdout.writeln('mode=$mode');
  stdout.writeln('scoring_policy=${result.scoringPolicyVersion}');
  stdout.writeln('calibration=${result.calibrationStatus.wireValue}');
  stdout.writeln('session_id_prefix=${result.sessionId.substring(0, 12)}…');
  for (final d in result.dimensionScores) {
    stdout.writeln('${d.dimension}:');
    stdout.writeln('  ${d.correctCount} / ${d.itemCount}');
    stdout.writeln('  raw_accuracy: ${d.rawAccuracy}');
    stdout.writeln('  provisional_score: ${d.provisionalScore}');
  }
  stdout.writeln('total_answered=${result.totalAnswered}');
}

String _selectOption({
  required String mode,
  required int index,
  required IqSessionItemPlan plan,
  required String correctId,
}) {
  switch (mode) {
    case 'all_correct':
      return correctId;
    case 'all_incorrect':
      return plan.displayedOptionIds.firstWhere((id) => id != correctId);
    case 'deterministic_mixed':
      // Correct on even presentation indices; incorrect on odd.
      if (index.isEven) return correctId;
      return plan.displayedOptionIds.firstWhere((id) => id != correctId);
    default:
      stderr.writeln('Unknown mode: $mode');
      exit(64);
  }
}
