import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_bank/eq_bank.dart';
import 'package:qmatch/features/assessment/domain/eq_scoring/eq_scoring.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/profile/profile.dart';
import 'package:qmatch/features/assessment/services/eq_canonical_runtime_service.dart';

EqCanonicalBankDocument _load(String path) {
  return EqCanonicalBankDocument.fromJson(
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
  );
}

List<QmatchProfileDimension> _fakeIqDims() => [
      for (final id in QmatchProfileTaxonomy.iq)
        QmatchProfileDimension(
          dimensionId: id,
          module: 'iq',
          measurementState: QmatchMeasurementState.measured,
          value: 0.7,
          source: QmatchProfileContract.measurementSourceCanonicalIq,
          sourceVersion: 'iq_4d_uncalibrated_accuracy_v1',
          calibrationStatus: 'uncalibrated',
          reliabilityStatus:
              QmatchProfileContract.reliabilityStatusNotCalibrated,
        ),
    ];

void main() {
  late EqCanonicalBankDocument tr;
  late EqCanonicalBankDocument en;

  setUpAll(() {
    tr = _load(EqBankContract.trAssetPath);
    en = _load(EqBankContract.enAssetPath);
  });

  group('EQ session + runtime', () {
    test('full session resume preserves order/answers/index/locale', () async {
      final repo = EqSessionMemoryRepository();
      final manager = EqSessionManager(
        bank: tr,
        repository: repo,
        idFactory: EqSessionIdFactory(random: Random(3)),
        shuffleRandom: Random(9),
        clock: () => DateTime.utc(2026, 8, 9, 17),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'seed_a',
      );
      expect(created.ok, isTrue);
      expect(created.state!.itemPlans.length, 30);
      expect(created.state!.bankLocale, 'tr-TR');

      final first = created.state!.itemPlans.first;
      final ans = await manager.answer(
        ownerUid: 'uid_a',
        sessionId: created.state!.sessionId,
        itemId: first.itemId,
        selectedOptionId: first.displayedOptionIds.first,
      );
      expect(ans.ok, isTrue);
      final moved = await manager.moveToIndex(
        ownerUid: 'uid_a',
        sessionId: created.state!.sessionId,
        index: 1,
      );
      expect(moved.ok, isTrue);

      final resumed = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'ignored',
      );
      expect(resumed.ok, isTrue);
      expect(manager.lastOperationComposed, isFalse);
      expect(resumed.state!.sessionId, created.state!.sessionId);
      expect(resumed.state!.currentQuestionIndex, 1);
      expect(
        resumed.state!.answersByItemId[first.itemId]!.selectedOptionId,
        first.displayedOptionIds.first,
      );
      expect(
        resumed.state!.itemPlans.first.displayedOptionIds,
        first.displayedOptionIds,
      );
      expect(resumed.state!.bankLocale, 'tr-TR');
    });

    test('UID isolation — A cannot load B', () async {
      final repo = EqSessionMemoryRepository();
      final manager = EqSessionManager(
        bank: tr,
        repository: repo,
        idFactory: EqSessionIdFactory(random: Random(1)),
        shuffleRandom: Random(2),
      );
      final a = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 's',
      );
      final bLoad = await repo.loadSession('uid_b', a.state!.sessionId);
      expect(bLoad.code, EqSessionLoadCode.notFound);
    });

    test('incomplete cannot score; complete scores 10 dims', () async {
      final repo = EqSessionMemoryRepository();
      final manager = EqSessionManager(
        bank: tr,
        repository: repo,
        idFactory: EqSessionIdFactory(random: Random(4)),
        shuffleRandom: Random(5),
        clock: () => DateTime.utc(2026, 8, 9),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_score',
        sessionSeed: 'seed_score',
      );
      final incomplete = await manager.complete(
        ownerUid: 'uid_score',
        sessionId: created.state!.sessionId,
      );
      expect(incomplete.ok, isFalse);

      var state = created.state!;
      for (final p in state.itemPlans) {
        final r = await manager.answer(
          ownerUid: 'uid_score',
          sessionId: state.sessionId,
          itemId: p.itemId,
          selectedOptionId: p.displayedOptionIds.first,
        );
        expect(r.ok, isTrue);
        state = r.state!;
      }
      final done = await manager.complete(
        ownerUid: 'uid_score',
        sessionId: state.sessionId,
      );
      expect(done.ok, isTrue);
      final responses = [
        for (final p in done.state!.itemPlans)
          EqCanonicalResponse(
            itemId: p.itemId,
            optionId: done.state!.answersByItemId[p.itemId]!.selectedOptionId,
          ),
      ];
      final scored = const CanonicalEqScorer().score(
        bank: tr,
        responses: responses,
      );
      expect(scored.ok, isTrue);
      expect(scored.result!.dimensionScores.length, 10);
      expect(scored.result!.toJson()['overall_eq_score'], isNull);
      expect(scored.result!.scoringPolicyVersion,
          EqScoringContract.scoringPolicyVersion);
    });

    test('locale resolve + EN bank', () {
      expect(EqCanonicalRuntimeService.resolveBankLocale('tr'), 'tr-TR');
      expect(EqCanonicalRuntimeService.resolveBankLocale('en'), 'en-US');
      expect(en.locale, 'en-US');
      expect(en.items.length, 30);
    });

    test('no correctness fields in session JSON', () {
      final plan = EqSessionItemPlan(
        itemId: 'eq_v1_empathy_001',
        primaryDimension: 'empathy',
        displayedOptionIds: const ['A', 'B', 'C', 'D'],
      );
      final json = jsonEncode(plan.toJson());
      expect(json.contains('correct'), isFalse);
      expect(json.contains('index'), isFalse);
    });
  });

  group('EqTo20d adapter', () {
    Future<EqCanonicalScoringResult> scoreAllA(
        EqCanonicalBankDocument bank) async {
      final responses = [
        for (final i in bank.items)
          EqCanonicalResponse(
            itemId: i.itemId,
            optionId: i.options.first.optionId,
          ),
      ];
      final out =
          const CanonicalEqScorer().score(bank: bank, responses: responses);
      expect(out.ok, isTrue);
      return out.result!;
    }

    test('maps 10 EQ dims; preserves IQ; 14/20 partial', () async {
      final result = await scoreAllA(tr);
      final adapted = const EqTo20dRuntimeAdapter().adapt(
        result: result,
        ownerUid: 'uid_p',
        sessionId: 'eq_sess_1',
        existingIqDimensions: _fakeIqDims(),
        clock: DateTime.utc(2026, 8, 9),
      );
      expect(adapted.ok, isTrue, reason: adapted.message);
      final f = adapted.fragment!;
      expect(f.measuredDimensionCount, 14);
      expect(f.requiredDimensionCount, 20);
      expect(f.missingDimensionIds, QmatchProfileTaxonomy.frequency);
      expect(f.canonicalProfileReady, isFalse);
      expect(f.profileStatus, QmatchProfileStatus.partial);
      expect(f.iqGroupStatus, QmatchGroupCompletionStatus.complete);
      expect(f.eqGroupStatus, QmatchGroupCompletionStatus.complete);
      expect(f.frequencyGroupStatus, QmatchGroupCompletionStatus.incomplete);
      for (final id in QmatchProfileTaxonomy.iq) {
        final d = f.measuredDimensions.firstWhere((e) => e.dimensionId == id);
        expect(d.value, 0.7);
        expect(d.source, QmatchProfileContract.measurementSourceCanonicalIq);
      }
      for (final id in EqCanonicalDimensions.all) {
        final d = f.measuredDimensions.firstWhere((e) => e.dimensionId == id);
        expect(d.value, inInclusiveRange(0.0, 1.0));
        expect(d.source, QmatchProfileContract.measurementSourceCanonicalEq);
      }
      for (final miss in f.missingDimensionIds) {
        expect(miss, isNot(anyOf('0', '0.0', '0.5', '50')));
        expect(QmatchProfileTaxonomy.frequency.contains(miss), isTrue);
      }
      final json = f.toJson();
      expect(json['canonical_profile_ready'], isFalse);
      expect(json.containsKey('persona'), isFalse);
    });

    test('idempotent adapt yields same EQ contribution', () async {
      final result = await scoreAllA(tr);
      final a = const EqTo20dRuntimeAdapter().adapt(
        result: result,
        ownerUid: 'uid_p',
        sessionId: 'eq_sess_1',
        existingIqDimensions: _fakeIqDims(),
        clock: DateTime.utc(2026, 8, 9),
      );
      final b = const EqTo20dRuntimeAdapter().adapt(
        result: result,
        ownerUid: 'uid_p',
        sessionId: 'eq_sess_1',
        existingIqDimensions: _fakeIqDims(),
        clock: DateTime.utc(2026, 8, 9),
      );
      expect(
        jsonEncode(a.fragment!.toJson()),
        jsonEncode(b.fragment!.toJson()),
      );
    });

    test('fails without IQ preservation', () async {
      final result = await scoreAllA(tr);
      final adapted = const EqTo20dRuntimeAdapter().adapt(
        result: result,
        ownerUid: 'uid_p',
        sessionId: 'eq_sess_1',
        existingIqDimensions: const [],
      );
      expect(adapted.ok, isFalse);
      expect(adapted.code, EqTo20dFailureCode.iqPreservationFailed);
    });
  });

  group('non-integration guards', () {
    test('EQ runtime source does not import persona/matching/quantum', () {
      final files = [
        'lib/features/assessment/services/eq_canonical_runtime_service.dart',
        'lib/features/assessment/domain/profile/eq_to_20d_runtime_adapter.dart',
        'lib/features/assessment/screens/eq_test_screen.dart',
      ];
      for (final path in files) {
        final text = File(path).readAsStringSync();
        expect(text.contains('PersonaScoring'), isFalse, reason: path);
        expect(text.contains('compatibility_scoring'), isFalse, reason: path);
        expect(text.contains('|ψ>'), isFalse, reason: path);
        expect(text.contains('density matrix'), isFalse, reason: path);
        expect(text.contains('correctAnswer'), isFalse, reason: path);
        expect(text.contains('_correctAnswers'), isFalse, reason: path);
      }
    });
  });
}
