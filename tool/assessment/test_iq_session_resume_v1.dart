// Development-only proof: durable IQ session resume (P2C-2A-3).
// Run: dart run tool/assessment/test_iq_session_resume_v1.dart
// Not a production debug route.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';

Future<void> main() async {
  final bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';
  final bank = IqRecoveredBankDocument.fromJson(
    jsonDecode(File(bankPath).readAsStringSync()) as Map<String, dynamic>,
  );

  final repo = IqSessionMemoryRepository();
  final manager = IqSessionManager(
    bank: bank,
    repository: repo,
    idFactory: IqSessionIdFactory(random: Random(42)),
    clock: () => DateTime.utc(2026, 8, 9, 12),
  );

  const uid = 'proof_uid';
  final created = await manager.getOrCreateActiveSession(
    ownerUid: uid,
    sessionSeed: 'proof-seed-v1',
  );
  if (!created.ok || created.state == null) {
    stderr.writeln('CREATE_FAIL ${created.code}');
    exit(1);
  }
  final sid = created.state!.sessionId;
  for (var i = 0; i < 7; i++) {
    final p = created.state!.itemPlans[i];
    await manager.answer(
      ownerUid: uid,
      sessionId: sid,
      itemId: p.itemId,
      selectedOptionId: p.displayedOptionIds.first,
    );
  }
  await manager.moveToIndex(ownerUid: uid, sessionId: sid, index: 7);

  final snapshot = Map<String, String>.from(repo.debugSnapshot);
  final freshRepo = IqSessionMemoryRepository();
  for (final e in snapshot.entries) {
    freshRepo.putRaw(e.key, e.value);
  }
  final fresh = IqSessionManager(bank: bank, repository: freshRepo);
  final resumed = await fresh.getOrCreateActiveSession(
    ownerUid: uid,
    sessionSeed: 'must-not-apply',
  );

  final s = resumed.state!;
  final size = utf8.encode(jsonEncode(s.toJson())).length;
  stdout.writeln('IQ_SESSION_RESUME_PROOF_V1');
  stdout.writeln('ok=${resumed.ok}');
  stdout.writeln('composed_on_resume=${fresh.lastOperationComposed}');
  stdout.writeln('session_id_prefix=${s.sessionId.substring(0, 12)}…');
  stdout.writeln('seed_match=${s.sessionSeed == 'proof-seed-v1'}');
  stdout.writeln('item_count=${s.itemPlans.length}');
  stdout.writeln('answers=${s.answers.length}');
  stdout.writeln('index=${s.currentQuestionIndex}');
  stdout.writeln('status=${s.status.wireValue}');
  stdout.writeln('serialized_bytes=$size');
  stdout.writeln(
    'has_correct_option_id_field=${jsonEncode(s.toJson()).contains('correct_option_id')}',
  );
  stdout.writeln(
    'has_displayed_correct_position_key=${jsonEncode(s.toJson()).contains('"displayed_correct_position"')}',
  );
  if (!resumed.ok ||
      fresh.lastOperationComposed ||
      s.answers.length != 7 ||
      s.currentQuestionIndex != 7) {
    exit(2);
  }
}
