import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_scoring/iq_scoring.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/screens/iq_test_screen.dart';
import 'package:qmatch/features/assessment/services/canonical_assessment_persistence.dart';
import 'package:qmatch/features/assessment/services/iq_canonical_runtime_service.dart';
import 'package:qmatch/features/assessment/services/question_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';

IqRecoveredBankDocument _loadBank() {
  return IqRecoveredBankDocument.fromJson(
    jsonDecode(File(_bankPath).readAsStringSync()) as Map<String, dynamic>,
  );
}

void main() {
  late IqRecoveredBankDocument bank;

  setUpAll(() {
    bank = _loadBank();
  });

  group('P2C-2A-5 canonical live runtime (service-level)', () {
    late IqSessionMemoryRepository repo;
    late IqSessionManager manager;

    setUp(() {
      repo = IqSessionMemoryRepository();
      manager = IqSessionManager(
        bank: bank,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(42)),
        clock: () => DateTime.utc(2026, 8, 9, 18),
      );
    });

    test('1-4 create/resume 25 items 7/6/6/6; no regen', () async {
      final a = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_live',
        sessionSeed: 'live-seed-1',
      );
      expect(a.ok, isTrue);
      expect(a.state!.itemPlans.length, 25);
      expect(
        a.state!.itemPlans
            .where((p) => p.dimension == 'logical_reasoning')
            .length,
        7,
      );
      expect(
        a.state!.itemPlans
            .where((p) => p.dimension == 'pattern_reasoning')
            .length,
        6,
      );
      expect(
        a.state!.itemPlans
            .where((p) => p.dimension == 'verbal_reasoning')
            .length,
        6,
      );
      expect(
        a.state!.itemPlans
            .where((p) => p.dimension == 'spatial_reasoning')
            .length,
        6,
      );
      expect(manager.lastOperationComposed, isTrue);

      final b = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_live',
        sessionSeed: 'ignored',
      );
      expect(manager.lastOperationComposed, isFalse);
      expect(b.state!.sessionId, a.state!.sessionId);
      expect(
        b.state!.itemPlans.map((e) => e.displayedOptionIds.join()).toList(),
        a.state!.itemPlans.map((e) => e.displayedOptionIds.join()).toList(),
      );
    });

    test('5-12 selectedOptionId persist; index persist; relaunch', () async {
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_live',
        sessionSeed: 'persist-seed',
      );
      final sid = created.state!.sessionId;
      final plan0 = created.state!.itemPlans.first;
      await manager.answer(
        ownerUid: 'uid_live',
        sessionId: sid,
        itemId: plan0.itemId,
        selectedOptionId: plan0.displayedOptionIds.first,
      );
      await manager.moveToIndex(ownerUid: 'uid_live', sessionId: sid, index: 1);

      final snap = Map<String, String>.from(repo.debugSnapshot);
      final fresh = IqSessionMemoryRepository();
      for (final e in snap.entries) {
        fresh.putRaw(e.key, e.value);
      }
      final resumed = IqSessionManager(bank: bank, repository: fresh);
      final r = await resumed.getOrCreateActiveSession(
        ownerUid: 'uid_live',
        sessionSeed: 'x',
      );
      expect(resumed.lastOperationComposed, isFalse);
      expect(r.state!.currentQuestionIndex, 1);
      expect(r.state!.answers.length, 1);
      expect(r.state!.answers.single.selectedOptionId,
          plan0.displayedOptionIds.first);
      expect(r.state!.answers.single.selectedOptionId, isNot(equals('0')));
    });

    test('13 UID isolation', () async {
      final a = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'a',
      );
      final b = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_b',
        sessionSeed: 'b',
      );
      expect(a.state!.sessionId, isNot(b.state!.sessionId));
    });

    test('14-20 complete + score; no IQ/percentile/reliability', () async {
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_live',
        sessionSeed: 'score-seed',
      );
      final sid = created.state!.sessionId;
      final byId = {for (final i in bank.items) i.id: i};
      for (final p in created.state!.itemPlans) {
        await manager.answer(
          ownerUid: 'uid_live',
          sessionId: sid,
          itemId: p.itemId,
          selectedOptionId: byId[p.itemId]!.correctOptionId,
        );
      }
      expect(
        (await manager.complete(ownerUid: 'uid_live', sessionId: sid)).ok,
        isTrue,
      );
      final incomplete = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_live2',
        sessionSeed: 'inc',
      );
      final failScore = const IqCanonicalScorer().scoreCompletedSession(
        session: incomplete.state!,
        bank: bank,
        ownerUid: 'uid_live2',
      );
      expect(failScore.ok, isFalse);

      final done = await repo.loadSession('uid_live', sid);
      final scored = const IqCanonicalScorer().scoreCompletedSession(
        session: done.state!,
        bank: bank,
        ownerUid: 'uid_live',
      );
      expect(scored.ok, isTrue);
      expect(scored.result!.dimensionScores.length, 4);
      final json = jsonEncode(scored.result!.toJson());
      expect(json.contains('percentile'), isFalse);
      expect(json.contains('overallIq'), isFalse);
      expect(json.contains('iqScore'), isFalse);
      expect(jsonDecode(json)['reliability_estimate'], isNull);
    });

    test('26-29 typed failures', () async {
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_live',
        sessionSeed: 'fail-seed',
      );
      expect(
        (await manager.answer(
          ownerUid: 'uid_live',
          sessionId: created.state!.sessionId,
          itemId: created.state!.itemPlans.first.itemId,
          selectedOptionId: 'zzz',
        ))
            .ok,
        isFalse,
      );

      final bankBad = IqPersistedSessionState.fromJson({
        ...created.state!.toJson(),
        'bank_version': 'other',
      });
      await repo.saveSession(bankBad);
      final r = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_live',
        sessionSeed: 'n',
      );
      expect(r.ok, isFalse);
      expect(r.code, 'incompatibleBank');
    });

    test('30-31 live result payload has no keys/PII', () {
      final plan = (const IqSessionComposer().compose(
        bank: bank,
        config: const IqSessionConfig(sessionSeed: 'payload'),
      ) as IqSessionCompositionSuccess)
          .plan;
      final session = IqPersistedSessionState(
        schemaVersion: IqPersistedSessionState.schemaVersionValue,
        sessionId: 'iq_sess_payload',
        ownerUid: 'uid_x',
        bankVersion: plan.bankVersion,
        bankLocale: plan.bankLocale,
        selectionPolicyVersion: plan.selectionPolicyVersion,
        sessionSeed: plan.sessionSeed,
        itemPlans: plan.itemPlans,
        currentQuestionIndex: 24,
        answers: [
          for (final p in plan.itemPlans)
            IqSessionAnswer(
              itemId: p.itemId,
              selectedOptionId: p.displayedOptionIds.first,
              answeredAt: '2026-08-09T00:00:00.000Z',
            ),
        ],
        startedAt: '2026-08-09T00:00:00.000Z',
        updatedAt: '2026-08-09T00:00:00.000Z',
        completedAt: '2026-08-09T00:00:00.000Z',
        status: IqPersistedSessionStatus.completed,
      );
      final scored = const IqCanonicalScorer().scoreCompletedSession(
        session: session,
        bank: bank,
        ownerUid: 'uid_x',
      );
      expect(scored.ok, isTrue);
      final payload =
          CanonicalAssessmentPersistence().buildCanonicalIq4dPayload(
        result: scored.result!,
        locale: 'tr-TR',
        languageUsed: 'tr',
      );
      final checkable = Map<String, dynamic>.from(payload)
        ..remove('completed_at')
        ..remove('started_at');
      final s = jsonEncode(checkable);
      expect(s.contains('correct_option_id'), isFalse);
      expect(s.contains('"prompt"'), isFalse);
      expect(s.contains('"email"'), isFalse);
      expect(s.contains('"phone"'), isFalse);
      expect(payload['iq_result_kind'], 'uncalibrated_reasoning_profile_v1');
      expect(payload['calibration_status'], 'uncalibrated');
      expect(payload.containsKey('raw_score'), isFalse);
      expect(
        (payload['canonical_dimensions'] as List).length,
        4,
      );
    });

    test('40 live screen no longer calls legacy loadIQAssessment', () {
      final screen = File(
        'lib/features/assessment/screens/iq_test_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('loadIQAssessment'), isFalse);
      expect(screen.contains('IqCanonicalRuntimeService'), isTrue);
      expect(screen.contains('_correctAnswers'), isFalse);
      expect(QuestionService, isNotNull);
      expect(IQTestScreen, isNotNull);
      expect(
        File('lib/features/assessment/screens/eq_test_screen.dart')
            .readAsStringSync()
            .contains('IqCanonicalScorer'),
        isFalse,
      );
      expect(
        File('lib/features/assessment/screens/frequency_test_screen.dart')
            .readAsStringSync()
            .contains('IqCanonicalScorer'),
        isFalse,
      );
      expect(
        File('lib/features/assessment/services/iq_canonical_runtime_service.dart')
            .readAsStringSync()
            .contains('core_method_v2'),
        isFalse,
      );
      expect(
        File('lib/features/assessment/services/iq_canonical_runtime_service.dart')
            .readAsStringSync()
            .toLowerCase()
            .contains('quantum'),
        isFalse,
      );
    });

    test('SharedPreferences adapter used by runtime default', () {
      expect(
        File('lib/features/assessment/services/iq_canonical_runtime_service.dart')
            .readAsStringSync()
            .contains('IqSessionPrefsRepository'),
        isTrue,
      );
    });

    test('bank asset registered for runtime', () {
      final pub = File('pubspec.yaml').readAsStringSync();
      expect(pub.contains('iq_bank_tr_v1.json'), isTrue);
      expect(pub.contains('iq_pilot_tr_v1'), isFalse);
    });

    test('25 bank locale stable on session', () async {
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_loc',
        sessionSeed: 'loc',
      );
      expect(created.state!.bankLocale, bank.locale);
    });
  });

  group('displayedOptionIds rendering contract', () {
    test('runtime service maps option ids to text in display order', () {
      SharedPreferences.setMockInitialValues({});
      final service = IqCanonicalRuntimeService(
        repository: IqSessionMemoryRepository(),
        idFactory: IqSessionIdFactory(random: Random(1)),
      );
      final plan = (const IqSessionComposer().compose(
        bank: bank,
        config: const IqSessionConfig(sessionSeed: 'render'),
      ) as IqSessionCompositionSuccess)
          .plan
          .itemPlans
          .first;
      final opts = service.displayedOptions(bank: bank, plan: plan);
      expect(opts.map((e) => e.optionId).toList(), plan.displayedOptionIds);
      expect(opts.every((e) => e.text.isNotEmpty), isTrue);
    });
  });
}
