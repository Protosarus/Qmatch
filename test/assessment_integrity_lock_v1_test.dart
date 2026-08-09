import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_bank/eq_bank.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/services/assessment_capture_protection.dart';
import 'package:qmatch/features/assessment/widgets/assessment_capture_guard.dart';
import 'package:qmatch/features/assessment/widgets/eq_question_chrome.dart';
import 'package:qmatch/features/assessment/widgets/frequency_question_chrome.dart';
import 'package:qmatch/features/assessment/widgets/iq_question_chrome.dart';

const _iqBankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';

void main() {
  group('ASSESSMENT integrity lock — domain', () {
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

    test('IQ committed answer immutable; cursor forward-only; resume',
        () async {
      final repo = IqSessionMemoryRepository();
      final manager = IqSessionManager(
        bank: iqBank,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(11)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_iq',
        sessionSeed: 'lock-iq',
      );
      final sid = created.state!.sessionId;
      for (var i = 0; i < 10; i++) {
        final plan = created.state!.itemPlans[i];
        await manager.answer(
          ownerUid: 'uid_iq',
          sessionId: sid,
          itemId: plan.itemId,
          selectedOptionId: plan.displayedOptionIds.first,
        );
        await manager.moveToIndex(
          ownerUid: 'uid_iq',
          sessionId: sid,
          index: i + 1,
        );
      }
      final first = created.state!.itemPlans.first;
      final overwrite = await manager.answer(
        ownerUid: 'uid_iq',
        sessionId: sid,
        itemId: first.itemId,
        selectedOptionId: first.displayedOptionIds.last,
      );
      expect(overwrite.code, 'answer_already_committed');
      final back = await manager.moveToIndex(
        ownerUid: 'uid_iq',
        sessionId: sid,
        index: 3,
      );
      expect(back.code, 'cursor_not_forward');

      final snapshot = Map<String, String>.from(repo.debugSnapshot);
      final fresh = IqSessionMemoryRepository();
      for (final e in snapshot.entries) {
        fresh.putRaw(e.key, e.value);
      }
      final resumed = await IqSessionManager(
        bank: iqBank,
        repository: fresh,
        idFactory: IqSessionIdFactory(random: Random(12)),
      ).getOrCreateActiveSession(ownerUid: 'uid_iq', sessionSeed: 'x');
      expect(resumed.state!.currentQuestionIndex, 10);
      expect(resumed.state!.answers.length, 10);
      expect(
        resumed.state!.answersByItemId[first.itemId]!.selectedOptionId,
        first.displayedOptionIds.first,
      );
    });

    test('EQ committed answer immutable; cursor forward-only', () async {
      final manager = EqSessionManager(
        bank: eqBank,
        repository: EqSessionMemoryRepository(),
        idFactory: EqSessionIdFactory(random: Random(21)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_eq',
        sessionSeed: 'lock-eq',
      );
      final sid = created.state!.sessionId;
      final a = created.state!.itemPlans[0];
      final b = created.state!.itemPlans[1];
      await manager.answer(
        ownerUid: 'uid_eq',
        sessionId: sid,
        itemId: a.itemId,
        selectedOptionId: a.displayedOptionIds.first,
      );
      await manager.moveToIndex(ownerUid: 'uid_eq', sessionId: sid, index: 1);
      expect(
        (await manager.answer(
          ownerUid: 'uid_eq',
          sessionId: sid,
          itemId: a.itemId,
          selectedOptionId: a.displayedOptionIds.last,
        ))
            .code,
        'answer_already_committed',
      );
      expect(
        (await manager.moveToIndex(
          ownerUid: 'uid_eq',
          sessionId: sid,
          index: 0,
        ))
            .code,
        'cursor_not_forward',
      );
      // Current question still answerable.
      expect(
        (await manager.answer(
          ownerUid: 'uid_eq',
          sessionId: sid,
          itemId: b.itemId,
          selectedOptionId: b.displayedOptionIds.first,
        ))
            .ok,
        isTrue,
      );
    });

    test('Frequency cannot move Q20→Q19; answer immutable', () async {
      final manager = FrequencySessionManager(
        bank: freqBank,
        repository: FrequencySessionMemoryRepository(),
        idFactory: FrequencySessionIdFactory(random: Random(31)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_f',
        sessionSeed: 'lock-f',
      );
      final sid = created.state!.sessionId;
      for (var i = 0; i < 20; i++) {
        final plan = created.state!.itemPlans[i];
        await manager.answer(
          ownerUid: 'uid_f',
          sessionId: sid,
          itemId: plan.itemId,
          selectedOptionId: plan.displayedOptionIds.first,
        );
        if (i < 19) {
          await manager.moveToIndex(
            ownerUid: 'uid_f',
            sessionId: sid,
            index: i + 1,
          );
        }
      }
      expect(created.state!.itemPlans.length, 50);
      final at19 = await manager.moveToIndex(
        ownerUid: 'uid_f',
        sessionId: sid,
        index: 19,
      );
      // already at 19 after loop when i=19 answered without move — move to 19 ok
      expect(at19.ok || at19.code == 'cursor_not_forward', isTrue);
      final to18 = await manager.moveToIndex(
        ownerUid: 'uid_f',
        sessionId: sid,
        index: 18,
      );
      expect(to18.code, 'cursor_not_forward');
      final q19 = created.state!.itemPlans[18];
      expect(
        (await manager.answer(
          ownerUid: 'uid_f',
          sessionId: sid,
          itemId: q19.itemId,
          selectedOptionId: q19.displayedOptionIds.last,
        ))
            .code,
        'answer_already_committed',
      );
    });

    test('pending finalization rejects answer edits', () async {
      final manager = EqSessionManager(
        bank: eqBank,
        repository: EqSessionMemoryRepository(),
        idFactory: EqSessionIdFactory(random: Random(41)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_p',
        sessionSeed: 'pend',
      );
      final sid = created.state!.sessionId;
      for (final p in created.state!.itemPlans) {
        await manager.answer(
          ownerUid: 'uid_p',
          sessionId: sid,
          itemId: p.itemId,
          selectedOptionId: p.displayedOptionIds.first,
        );
      }
      final done = await manager.complete(ownerUid: 'uid_p', sessionId: sid);
      expect(done.ok, isTrue);
      expect(
        done.state!.status,
        EqPersistedSessionStatus.completedPendingPersistence,
      );
      final first = created.state!.itemPlans.first;
      expect(
        (await manager.answer(
          ownerUid: 'uid_p',
          sessionId: sid,
          itemId: first.itemId,
          selectedOptionId: first.displayedOptionIds.last,
        ))
            .code,
        'session_not_editable',
      );
    });
  });

  group('ASSESSMENT integrity lock — UI chrome', () {
    testWidgets('question top bars omit back when onBack is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                IqQuestionTopBar(),
                EqQuestionTopBar(),
                FrequencyQuestionTopBar(),
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });

    testWidgets('AssessmentCaptureGuard blocks route pop', (tester) async {
      AssessmentCaptureProtection.instance.debugReset();
      await tester.pumpWidget(
        const MaterialApp(
          home: AssessmentCaptureGuard(
            child: Scaffold(body: Text('locked')),
          ),
        ),
      );
      await tester.pump();
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
      AssessmentCaptureProtection.instance.debugReset();
    });
  });

  group('ASSESSMENT capture protection', () {
    tearDown(() {
      AssessmentCaptureProtection.instance.debugReset();
    });

    test('ref-count enable/disable and obscure signals', () async {
      final p = AssessmentCaptureProtection.instance;
      p.debugReset();
      expect(p.debugRefCount, 0);
      await p.enable();
      expect(p.debugRefCount, 1);
      await p.enable();
      expect(p.debugRefCount, 2);
      p.setScreenCaptured(true);
      expect(p.shouldObscure, isTrue);
      p.setScreenCaptured(false);
      p.setAppInactive(true);
      expect(p.shouldObscure, isTrue);
      await p.disable();
      expect(p.debugRefCount, 1);
      expect(p.shouldObscure, isTrue); // still protected + inactive
      await p.disable();
      expect(p.debugRefCount, 0);
      expect(p.shouldObscure, isFalse);
    });

    testWidgets('capture guard shows overlay when obscure', (tester) async {
      final p = AssessmentCaptureProtection.instance;
      p.debugReset();
      await tester.pumpWidget(
        const MaterialApp(
          home: AssessmentCaptureGuard(
            child: Scaffold(body: Text('content')),
          ),
        ),
      );
      await tester.pump();
      p.setScreenCaptured(true);
      await tester.pump();
      expect(find.byType(ColoredBox), findsWidgets);
      p.setScreenCaptured(false);
      await tester.pump();
      AssessmentCaptureProtection.instance.debugReset();
    });
  });
}
