import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session_prefs_repository.dart';
import 'package:qmatch/features/assessment/screens/iq_test_screen.dart';
import 'package:qmatch/features/assessment/services/assessment_set_service.dart';
import 'package:qmatch/features/assessment/services/question_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';

IqRecoveredBankDocument _loadBank() {
  final raw =
      jsonDecode(File(_bankPath).readAsStringSync()) as Map<String, dynamic>;
  return IqRecoveredBankDocument.fromJson(raw);
}

IqPersistedSessionState _mutate(
  IqPersistedSessionState s,
  Map<String, dynamic> overlay,
) {
  return IqPersistedSessionState.fromJson({...s.toJson(), ...overlay});
}

void main() {
  late IqRecoveredBankDocument bank;

  setUpAll(() {
    bank = _loadBank();
  });

  group('P2C-2A-3 durable persistence', () {
    late IqSessionMemoryRepository repo;
    late IqSessionManager manager;

    setUp(() {
      repo = IqSessionMemoryRepository();
      manager = IqSessionManager(
        bank: bank,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(7)),
        clock: () => DateTime.utc(2026, 8, 9, 12, 0, 0),
      );
    });

    test('1-4 new session persists; composer skipped on valid resume',
        () async {
      final first = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'seed-1',
      );
      expect(first.ok, isTrue);
      expect(manager.lastOperationComposed, isTrue);
      final loaded = await repo.loadActiveSession('uid_a');
      expect(loaded.isLoaded, isTrue);
      expect(loaded.state!.sessionId, first.state!.sessionId);

      final second = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'seed-SHOULD-NOT-APPLY',
      );
      expect(second.ok, isTrue);
      expect(manager.lastOperationComposed, isFalse);
      expect(second.state!.sessionId, first.state!.sessionId);
      expect(second.state!.sessionSeed, 'seed-1');
      expect(
        second.state!.itemPlans.map((e) => e.itemId).toList(),
        first.state!.itemPlans.map((e) => e.itemId).toList(),
      );
      expect(
        second.state!.itemPlans
            .map((e) => e.displayedOptionIds.join())
            .toList(),
        first.state!.itemPlans.map((e) => e.displayedOptionIds.join()).toList(),
      );
    });

    test('5-9,40 app-kill relaunch exact equality', () async {
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'relaunch-seed',
      );
      final sid = created.state!.sessionId;
      for (var i = 0; i < 5; i++) {
        final item = created.state!.itemPlans[i];
        await manager.answer(
          ownerUid: 'uid_a',
          sessionId: sid,
          itemId: item.itemId,
          selectedOptionId: item.displayedOptionIds.first,
        );
      }
      await manager.moveToIndex(ownerUid: 'uid_a', sessionId: sid, index: 5);

      final snapshot = Map<String, String>.from(repo.debugSnapshot);
      final freshRepo = IqSessionMemoryRepository();
      for (final e in snapshot.entries) {
        freshRepo.putRaw(e.key, e.value);
      }
      final freshManager = IqSessionManager(
        bank: bank,
        repository: freshRepo,
        idFactory: IqSessionIdFactory(random: Random(99)),
      );
      final resumed = await freshManager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'ignored',
      );
      expect(freshManager.lastOperationComposed, isFalse);
      expect(resumed.state!.sessionId, sid);
      expect(resumed.state!.sessionSeed, 'relaunch-seed');
      expect(resumed.state!.currentQuestionIndex, 5);
      expect(resumed.state!.answers.length, 5);
      expect(resumed.state!.status, IqPersistedSessionStatus.inProgress);
      expect(
        resumed.state!.itemPlans.map((e) => e.itemId).join('|'),
        created.state!.itemPlans.map((e) => e.itemId).join('|'),
      );
      expect(
        resumed.state!.itemPlans.map((e) => e.templateFamilyId).join('|'),
        created.state!.itemPlans.map((e) => e.templateFamilyId).join('|'),
      );
      expect(
        resumed.state!.itemPlans
            .map((e) => e.displayedOptionIds.join())
            .join('|'),
        created.state!.itemPlans
            .map((e) => e.displayedOptionIds.join())
            .join('|'),
      );
    });

    test('10-18 answers, replacement, index, one-per-item', () async {
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'ans-seed',
      );
      final sid = created.state!.sessionId;
      final item = created.state!.itemPlans.first;
      await manager.answer(
        ownerUid: 'uid_a',
        sessionId: sid,
        itemId: item.itemId,
        selectedOptionId: item.displayedOptionIds[0],
      );
      final replaced = await manager.answer(
        ownerUid: 'uid_a',
        sessionId: sid,
        itemId: item.itemId,
        selectedOptionId: item.displayedOptionIds[1],
      );
      expect(replaced.state!.answers.length, 1);
      expect(
        replaced.state!.answers.single.selectedOptionId,
        item.displayedOptionIds[1],
      );
      expect(replaced.state!.answers.length, lessThan(25));

      expect(
        (await manager.moveToIndex(
          ownerUid: 'uid_a',
          sessionId: sid,
          index: -1,
        ))
            .ok,
        isFalse,
      );
      expect(
        (await manager.moveToIndex(
          ownerUid: 'uid_a',
          sessionId: sid,
          index: 25,
        ))
            .ok,
        isFalse,
      );
      expect(
        (await manager.moveToIndex(
          ownerUid: 'uid_a',
          sessionId: sid,
          index: 3,
        ))
            .ok,
        isTrue,
      );
      expect(
        (await manager.answer(
          ownerUid: 'uid_a',
          sessionId: sid,
          itemId: 'nope',
          selectedOptionId: 'a',
        ))
            .ok,
        isFalse,
      );
      expect(
        (await manager.answer(
          ownerUid: 'uid_a',
          sessionId: sid,
          itemId: item.itemId,
          selectedOptionId: 'not_an_option',
        ))
            .ok,
        isFalse,
      );
    });

    test('19-22 completion semantics', () async {
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'complete-seed',
      );
      final sid = created.state!.sessionId;
      expect(
        (await manager.complete(ownerUid: 'uid_a', sessionId: sid)).ok,
        isFalse,
      );
      for (final p in created.state!.itemPlans) {
        await manager.answer(
          ownerUid: 'uid_a',
          sessionId: sid,
          itemId: p.itemId,
          selectedOptionId: p.displayedOptionIds.first,
        );
      }
      final done = await manager.complete(ownerUid: 'uid_a', sessionId: sid);
      expect(done.ok, isTrue);
      expect(done.state!.status, IqPersistedSessionStatus.completed);
      expect(done.state!.completedAt, isNotNull);

      final active = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'new-after-complete',
      );
      expect(manager.lastOperationComposed, isTrue);
      expect(active.state!.sessionId, isNot(sid));

      expect(
        (await manager.answer(
          ownerUid: 'uid_a',
          sessionId: sid,
          itemId: created.state!.itemPlans.first.itemId,
          selectedOptionId:
              created.state!.itemPlans.first.displayedOptionIds.last,
        ))
            .ok,
        isFalse,
      );
    });

    test('23-25 UID isolation / missing owner', () async {
      final a = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'a-seed',
      );
      await manager.answer(
        ownerUid: 'uid_a',
        sessionId: a.state!.sessionId,
        itemId: a.state!.itemPlans.first.itemId,
        selectedOptionId: a.state!.itemPlans.first.displayedOptionIds.first,
      );

      final b = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_b',
        sessionSeed: 'b-seed',
      );
      expect(b.state!.sessionId, isNot(a.state!.sessionId));
      expect(b.state!.answers, isEmpty);

      final aAgain = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'ignored',
      );
      expect(aAgain.state!.sessionId, a.state!.sessionId);
      expect(aAgain.state!.answers.length, 1);

      final r = await manager.getOrCreateActiveSession(
        ownerUid: '',
        sessionSeed: 'seed',
      );
      expect(r.ok, isFalse);
      expect(r.code, 'owner_unavailable');
    });

    test('26-27 corrupt typed failure; not auto-deleted', () async {
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'corrupt-seed',
      );
      final sessionKey =
          IqSessionStorageKeys.session('uid_a', created.state!.sessionId);
      repo.putRaw(sessionKey, '{not-json');
      final loaded = await repo.loadActiveSession('uid_a');
      expect(loaded.code, IqSessionLoadCode.corrupt);
      expect(repo.debugSnapshot.containsKey(sessionKey), isTrue);

      final mgr = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'new',
      );
      expect(mgr.ok, isFalse);
      expect(mgr.code, 'corrupt');
      expect(manager.lastOperationComposed, isFalse);
      expect(repo.debugSnapshot.containsKey(sessionKey), isTrue);
    });

    test('28-31 incompatible schema/bank/policy no silent regen', () async {
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'compat-seed',
      );

      await repo.saveSession(
        _mutate(created.state!, {'schema_version': 'other_schema'}),
      );
      final r0 = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'new',
      );
      expect(r0.ok, isFalse);
      expect(r0.code, 'incompatibleSchema');
      expect(manager.lastOperationComposed, isFalse);

      await repo.saveSession(
        _mutate(created.state!, {'bank_version': 'other_bank'}),
      );
      final r1 = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'new',
      );
      expect(r1.ok, isFalse);
      expect(r1.code, 'incompatibleBank');
      expect(manager.lastOperationComposed, isFalse);

      await repo.saveSession(
        _mutate(created.state!, {
          'selection_policy_version': 'other_policy',
        }),
      );
      final r2 = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'new',
      );
      expect(r2.ok, isFalse);
      expect(r2.code, 'incompatiblePolicy');
      expect(manager.lastOperationComposed, isFalse);
    });

    test('32-37 structural corruption detected', () async {
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'struct-seed',
      );
      final base = created.state!;

      // Missing item from bank
      final badItem = Map<String, dynamic>.from(base.toJson());
      final plans = (badItem['item_plans'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      plans[0]['item_id'] = 'iq_does_not_exist_zzz';
      badItem['item_plans'] = plans;
      var validated = IqPersistedSessionValidator.validate(
        state: IqPersistedSessionState.fromJson(badItem),
        bank: bank,
        ownerUid: 'uid_a',
      );
      expect(validated.code, IqSessionLoadCode.corrupt);

      // Family mismatch
      final badFam = Map<String, dynamic>.from(base.toJson());
      final plans2 = (badFam['item_plans'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      plans2[0]['template_family_id'] = 'wrong_family';
      badFam['item_plans'] = plans2;
      validated = IqPersistedSessionValidator.validate(
        state: IqPersistedSessionState.fromJson(badFam),
        bank: bank,
        ownerUid: 'uid_a',
      );
      expect(validated.code, IqSessionLoadCode.corrupt);

      // Dimension mismatch
      final badDim = Map<String, dynamic>.from(base.toJson());
      final plans3 = (badDim['item_plans'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final bankItem =
          bank.items.firstWhere((i) => i.id == plans3[0]['item_id']);
      plans3[0]['dimension'] = bankItem.dimension == 'logical_reasoning'
          ? 'verbal_reasoning'
          : 'logical_reasoning';
      badDim['item_plans'] = plans3;
      validated = IqPersistedSessionValidator.validate(
        state: IqPersistedSessionState.fromJson(badDim),
        bank: bank,
        ownerUid: 'uid_a',
      );
      expect(validated.code, IqSessionLoadCode.corrupt);

      // Invalid displayed options
      final badOpt = Map<String, dynamic>.from(base.toJson());
      final plans4 = (badOpt['item_plans'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      plans4[0]['displayed_option_ids'] = ['x', 'y', 'z', 'w'];
      badOpt['item_plans'] = plans4;
      validated = IqPersistedSessionValidator.validate(
        state: IqPersistedSessionState.fromJson(badOpt),
        bank: bank,
        ownerUid: 'uid_a',
      );
      expect(validated.code, IqSessionLoadCode.corrupt);

      // Duplicate family
      final badDup = Map<String, dynamic>.from(base.toJson());
      final plans5 = (badDup['item_plans'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      plans5[1]['template_family_id'] = plans5[0]['template_family_id'];
      // also need same item bank consistency — duplicate family alone fails
      badDup['item_plans'] = plans5;
      validated = IqPersistedSessionValidator.validate(
        state: IqPersistedSessionState.fromJson(badDup),
        bank: bank,
        ownerUid: 'uid_a',
      );
      expect(validated.code, IqSessionLoadCode.corrupt);

      // Wrong quota — change one dimension label to another while keeping family
      // already covered by dimension mismatch / item count; truncate plan:
      final badQuota = Map<String, dynamic>.from(base.toJson());
      badQuota['item_plans'] =
          (badQuota['item_plans'] as List).take(20).toList();
      validated = IqPersistedSessionValidator.validate(
        state: IqPersistedSessionState.fromJson(badQuota),
        bank: bank,
        ownerUid: 'uid_a',
      );
      expect(validated.code, IqSessionLoadCode.corrupt);
    });

    test('38-44 serialization, privacy, size', () {
      final plan = (const IqSessionComposer().compose(
        bank: bank,
        config: const IqSessionConfig(sessionSeed: 'ser-seed'),
      ) as IqSessionCompositionSuccess)
          .plan;
      final state = IqPersistedSessionState(
        schemaVersion: IqPersistedSessionState.schemaVersionValue,
        sessionId: 'iq_sess_test',
        ownerUid: 'uid_a',
        bankVersion: plan.bankVersion,
        bankLocale: plan.bankLocale,
        selectionPolicyVersion: plan.selectionPolicyVersion,
        sessionSeed: plan.sessionSeed,
        itemPlans: plan.itemPlans,
        currentQuestionIndex: 3,
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
        status: IqPersistedSessionStatus.inProgress,
      );
      final s1 = jsonEncode(state.toJson());
      final s2 = jsonEncode(
        IqPersistedSessionState.fromJson(
          jsonDecode(s1) as Map<String, dynamic>,
        ).toJson(),
      );
      expect(s2, s1);
      expect(s1.contains('correct_option_id'), isFalse);
      expect(s1.contains('"displayed_correct_position"'), isFalse);
      expect(s1.contains('"prompt"'), isFalse);
      expect(s1.contains('"email"'), isFalse);
      expect(s1.contains('@example'), isFalse);
      expect(s1.contains('display_name'), isFalse);
      expect(s1.contains('"phone"'), isFalse);
      final bytes = utf8.encode(s1).length;
      // Fresh+answered session should stay well under 32KB (IDs only).
      expect(bytes, lessThan(32 * 1024));
      expect(bytes, greaterThan(500));
    });

    test('SharedPreferences adapter relaunch', () async {
      SharedPreferences.setMockInitialValues({});
      final prefsRepo = IqSessionPrefsRepository(
        prefs: await SharedPreferences.getInstance(),
      );
      final prefsManager = IqSessionManager(
        bank: bank,
        repository: prefsRepo,
        idFactory: IqSessionIdFactory(random: Random(3)),
      );
      final created = await prefsManager.getOrCreateActiveSession(
        ownerUid: 'uid_prefs',
        sessionSeed: 'prefs-seed',
      );
      final relaunched = IqSessionManager(
        bank: bank,
        repository: IqSessionPrefsRepository(
          prefs: await SharedPreferences.getInstance(),
        ),
      );
      final resumed = await relaunched.getOrCreateActiveSession(
        ownerUid: 'uid_prefs',
        sessionSeed: 'ignored',
      );
      expect(relaunched.lastOperationComposed, isFalse);
      expect(resumed.state!.sessionId, created.state!.sessionId);
    });
  });

  group('45-49 runtime / firebase isolation', () {
    test('live IQ symbols present; no firebase in session domain', () {
      expect(QuestionService, isNotNull);
      expect(AssessmentSetService, isNotNull);
      expect(IQTestScreen, isNotNull);

      final domainFiles = [
        'lib/features/assessment/domain/iq_session/iq_session_manager.dart',
        'lib/features/assessment/domain/iq_session/iq_persisted_session_state.dart',
        'lib/features/assessment/domain/iq_session/iq_session_persistence_repository.dart',
        'lib/features/assessment/domain/iq_session/iq_session_prefs_repository.dart',
      ];
      for (final path in domainFiles) {
        final src = File(path).readAsStringSync();
        expect(src.contains("import 'package:cloud_firestore"), isFalse,
            reason: path);
        expect(src.contains("import 'package:firebase"), isFalse, reason: path);
        expect(src.contains('FirebaseFirestore'), isFalse, reason: path);
        expect(src.contains('users/{'), isFalse, reason: path);
      }

      final iqScreen = File(
        'lib/features/assessment/screens/iq_test_screen.dart',
      ).readAsStringSync();
      expect(iqScreen.contains('IqSessionManager'), isFalse);
      expect(iqScreen.contains('IqSessionPrefsRepository'), isFalse);
    });
  });
}
