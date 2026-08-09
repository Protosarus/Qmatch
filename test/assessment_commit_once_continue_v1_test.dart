import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_bank/eq_bank.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';

const _iqBankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';

void main() {
  group('commit-once Continue semantics', () {
    late IqRecoveredBankDocument iqBank;
    late EqCanonicalBankDocument eqBank;
    late FrequencyCanonicalBankDocument freqBank;

    setUpAll(() {
      iqBank = IqRecoveredBankDocument.fromJson(
        jsonDecode(File(_iqBankPath).readAsStringSync())
            as Map<String, dynamic>,
      );
      eqBank = EqCanonicalBankDocument.fromJson(
        jsonDecode(File(EqBankContract.trAssetPath).readAsStringSync())
            as Map<String, dynamic>,
      );
      freqBank = FrequencyCanonicalBankDocument.fromJson(
        jsonDecode(File(FrequencyBankContract.trAssetPath).readAsStringSync())
            as Map<String, dynamic>,
      );
    });

    test('Frequency: no persist before Continue; A→B then commit B once',
        () async {
      final repo = FrequencySessionMemoryRepository();
      final manager = FrequencySessionManager(
        bank: freqBank,
        repository: repo,
        idFactory: FrequencySessionIdFactory(random: Random(7)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_f',
        sessionSeed: 'commit-once-f',
      );
      expect(created.ok, isTrue);
      final sid = created.state!.sessionId;
      final q0 = created.state!.itemPlans[0];
      final a = q0.displayedOptionIds[0];
      final b = q0.displayedOptionIds[1];

      // Local UI selection A then B does not call answer — simulate by not answering.
      expect(created.state!.answers, isEmpty);

      // Continue commits B once.
      final committed = await manager.answer(
        ownerUid: 'uid_f',
        sessionId: sid,
        itemId: q0.itemId,
        selectedOptionId: b,
      );
      expect(committed.ok, isTrue);
      expect(committed.state!.answers.single.selectedOptionId, b);

      // Changing mind after commit rejected.
      final overwrite = await manager.answer(
        ownerUid: 'uid_f',
        sessionId: sid,
        itemId: q0.itemId,
        selectedOptionId: a,
      );
      expect(overwrite.code, 'answer_already_committed');

      // Advance to next.
      final moved = await manager.moveToIndex(
        ownerUid: 'uid_f',
        sessionId: sid,
        index: 1,
      );
      expect(moved.ok, isTrue);
      expect(moved.state!.currentQuestionIndex, 1);
      expect(moved.state!.answers.length, 1);
    });

    test('Frequency: resume reconciles cursor past committed item', () async {
      final repo = FrequencySessionMemoryRepository();
      final manager = FrequencySessionManager(
        bank: freqBank,
        repository: repo,
        idFactory: FrequencySessionIdFactory(random: Random(8)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_f2',
        sessionSeed: 'resume-f',
      );
      final sid = created.state!.sessionId;
      final q0 = created.state!.itemPlans[0];
      final q1 = created.state!.itemPlans[1];
      await manager.answer(
        ownerUid: 'uid_f2',
        sessionId: sid,
        itemId: q0.itemId,
        selectedOptionId: q0.displayedOptionIds.first,
      );
      // Stuck cursor: answered Q1 but index still 0.
      expect(created.state!.currentQuestionIndex, 0);

      final resumed = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_f2',
        sessionSeed: 'ignored',
      );
      expect(resumed.ok, isTrue);
      expect(resumed.state!.currentQuestionIndex, 1);
      expect(
        resumed.state!.answersByItemId.containsKey(q1.itemId),
        isFalse,
      );

      // Continue on Q2 must succeed (not answer_already_committed on Q1).
      final q2ans = await manager.answer(
        ownerUid: 'uid_f2',
        sessionId: sid,
        itemId: resumed.state!.itemPlans[1].itemId,
        selectedOptionId: resumed.state!.itemPlans[1].displayedOptionIds.first,
      );
      expect(q2ans.ok, isTrue);
    });

    test('Frequency quality item accepts any valid option', () async {
      final manager = FrequencySessionManager(
        bank: freqBank,
        repository: FrequencySessionMemoryRepository(),
        idFactory: FrequencySessionIdFactory(random: Random(9)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_fq',
        sessionSeed: 'quality',
      );
      // Find a quality/control item if present; otherwise first item.
      FrequencySessionItemPlan plan = created.state!.itemPlans.first;
      for (final p in created.state!.itemPlans) {
        final item = freqBank.items.firstWhere((e) => e.itemId == p.itemId);
        if (item.itemRole == FrequencyBankContract.itemRoleQuality) {
          plan = p;
          break;
        }
      }
      // Commit first option (may not be expected attention answer).
      final ans = await manager.answer(
        ownerUid: 'uid_fq',
        sessionId: created.state!.sessionId,
        itemId: plan.itemId,
        selectedOptionId: plan.displayedOptionIds.first,
      );
      expect(ans.ok, isTrue);
    });

    test('IQ: commit-once + resume reconcile', () async {
      final repo = IqSessionMemoryRepository();
      final manager = IqSessionManager(
        bank: iqBank,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(10)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_iq',
        sessionSeed: 'iq-commit',
      );
      final sid = created.state!.sessionId;
      final q0 = created.state!.itemPlans.first;
      final a = q0.displayedOptionIds[0];
      final b = q0.displayedOptionIds[1];
      expect(created.state!.answers, isEmpty);
      await manager.answer(
        ownerUid: 'uid_iq',
        sessionId: sid,
        itemId: q0.itemId,
        selectedOptionId: b,
      );
      expect(
        (await manager.answer(
          ownerUid: 'uid_iq',
          sessionId: sid,
          itemId: q0.itemId,
          selectedOptionId: a,
        ))
            .code,
        'answer_already_committed',
      );
      final resumed = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_iq',
        sessionSeed: 'x',
      );
      expect(resumed.state!.currentQuestionIndex, 1);
    });

    test('EQ: commit-once + resume reconcile', () async {
      final repo = EqSessionMemoryRepository();
      final manager = EqSessionManager(
        bank: eqBank,
        repository: repo,
        idFactory: EqSessionIdFactory(random: Random(11)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_eq',
        sessionSeed: 'eq-commit',
      );
      final sid = created.state!.sessionId;
      final q0 = created.state!.itemPlans.first;
      await manager.answer(
        ownerUid: 'uid_eq',
        sessionId: sid,
        itemId: q0.itemId,
        selectedOptionId: q0.displayedOptionIds.last,
      );
      expect(
        (await manager.answer(
          ownerUid: 'uid_eq',
          sessionId: sid,
          itemId: q0.itemId,
          selectedOptionId: q0.displayedOptionIds.first,
        ))
            .code,
        'answer_already_committed',
      );
      final resumed = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_eq',
        sessionSeed: 'x',
      );
      expect(resumed.state!.currentQuestionIndex, 1);
    });
  });
}
