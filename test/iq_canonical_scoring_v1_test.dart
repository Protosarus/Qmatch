import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_scoring/iq_scoring.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/screens/iq_test_screen.dart';
import 'package:qmatch/features/assessment/services/question_service.dart';

const _bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';

IqRecoveredBankDocument _loadBank() {
  return IqRecoveredBankDocument.fromJson(
    jsonDecode(File(_bankPath).readAsStringSync()) as Map<String, dynamic>,
  );
}

String _bankFingerprint(IqRecoveredBankDocument bank) {
  return jsonEncode({
    'bank_version': bank.bankVersion,
    'items': [
      for (final i in bank.items)
        {
          'id': i.id,
          'dimension': i.dimension,
          'family': i.templateFamilyId,
          'correct': i.correctOptionId,
          'prompt': i.prompt,
          'options': [for (final o in i.options) o.id],
          'review': i.reviewStatus,
        },
    ],
  });
}

Future<IqPersistedSessionState> _completeSession({
  required IqRecoveredBankDocument bank,
  required String seed,
  required String Function(int index, IqSessionItemPlan plan, String correctId)
      pick,
  String uid = 'uid_score',
}) async {
  final repo = IqSessionMemoryRepository();
  final manager = IqSessionManager(
    bank: bank,
    repository: repo,
    idFactory: IqSessionIdFactory(random: Random(21)),
    clock: () => DateTime.utc(2026, 8, 9, 15),
  );
  final created = await manager.getOrCreateActiveSession(
    ownerUid: uid,
    sessionSeed: seed,
  );
  expect(created.ok, isTrue);
  final byId = {for (final i in bank.items) i.id: i};
  final sid = created.state!.sessionId;
  for (var i = 0; i < created.state!.itemPlans.length; i++) {
    final p = created.state!.itemPlans[i];
    await manager.answer(
      ownerUid: uid,
      sessionId: sid,
      itemId: p.itemId,
      selectedOptionId: pick(i, p, byId[p.itemId]!.correctOptionId),
    );
  }
  final done = await manager.complete(ownerUid: uid, sessionId: sid);
  expect(done.ok, isTrue);
  return done.state!;
}

void main() {
  late IqRecoveredBankDocument bank;

  setUpAll(() {
    bank = _loadBank();
  });

  group('P2C-2A-4 canonical 4D scoring', () {
    test('1-12 all-correct / all-incorrect fixtures', () async {
      final allCorrect = await _completeSession(
        bank: bank,
        seed: 'score-all-correct',
        pick: (_, __, correct) => correct,
      );
      final ok = const IqCanonicalScorer().scoreCompletedSession(
        session: allCorrect,
        bank: bank,
        ownerUid: 'uid_score',
      );
      expect(ok.ok, isTrue);
      final r = ok.result!;
      expect(r.dimensionScores.length, 4);
      expect(r.scoreFor('logical_reasoning').itemCount, 7);
      expect(r.scoreFor('pattern_reasoning').itemCount, 6);
      expect(r.scoreFor('verbal_reasoning').itemCount, 6);
      expect(r.scoreFor('spatial_reasoning').itemCount, 6);
      for (final d in r.dimensionScores) {
        expect(d.rawAccuracy, 1.0);
        expect(d.provisionalScore, 1.0);
        expect(d.correctCount, d.itemCount);
        expect(d.incorrectCount, 0);
        expect(d.answeredCount, d.itemCount);
        expect(d.calibrationStatus, IqCalibrationStatus.uncalibrated);
      }
      expect(r.calibrationStatus, IqCalibrationStatus.uncalibrated);
      expect(r.scoringPolicyVersion, IqScoringContract.scoringPolicyVersion);

      final allWrong = await _completeSession(
        bank: bank,
        seed: 'score-all-wrong',
        pick: (_, plan, correct) =>
            plan.displayedOptionIds.firstWhere((id) => id != correct),
      );
      final bad = const IqCanonicalScorer().scoreCompletedSession(
        session: allWrong,
        bank: bank,
        ownerUid: 'uid_score',
      );
      expect(bad.ok, isTrue);
      for (final d in bad.result!.dimensionScores) {
        expect(d.rawAccuracy, 0.0);
        expect(d.provisionalScore, 0.0);
        expect(d.correctCount, 0);
        expect(d.incorrectCount, d.itemCount);
      }
    });

    test('13 mixed known-answer fixture exact', () async {
      final session = await _completeSession(
        bank: bank,
        seed: 'score-mixed',
        pick: (i, plan, correct) {
          if (i.isEven) return correct;
          return plan.displayedOptionIds.firstWhere((id) => id != correct);
        },
      );
      final byId = {for (final i in bank.items) i.id: i};
      final expectedCorrect = <String, int>{
        for (final d in IqCanonicalDimensions.all) d: 0,
      };
      for (var i = 0; i < session.itemPlans.length; i++) {
        final p = session.itemPlans[i];
        final a = session.answersByItemId[p.itemId]!;
        final item = byId[p.itemId]!;
        if (a.selectedOptionId == item.correctOptionId) {
          expectedCorrect[item.dimension] =
              expectedCorrect[item.dimension]! + 1;
        }
      }
      final scored = const IqCanonicalScorer().scoreCompletedSession(
        session: session,
        bank: bank,
        ownerUid: 'uid_score',
      );
      expect(scored.ok, isTrue);
      for (final d in scored.result!.dimensionScores) {
        expect(d.correctCount, expectedCorrect[d.dimension]);
        expect(
          d.rawAccuracy,
          closeTo(d.correctCount / d.itemCount, 1e-12),
        );
        expect(d.provisionalScore, d.rawAccuracy);
        expect(d.rawAccuracy >= 0 && d.rawAccuracy <= 1, isTrue);
      }
    });

    test('14-17 option-id scoring; shuffle/order invariance', () async {
      final session = await _completeSession(
        bank: bank,
        seed: 'score-invariance',
        pick: (_, __, correct) => correct,
      );
      final base = const IqCanonicalScorer().scoreCompletedSession(
        session: session,
        bank: bank,
        ownerUid: 'uid_score',
      );
      expect(base.ok, isTrue);

      // Shuffle displayed option order only — answers still correct by option id.
      final shuffledPlans = session.itemPlans.map((p) {
        final ids = List<String>.from(p.displayedOptionIds.reversed);
        return IqSessionItemPlan(
          itemId: p.itemId,
          dimension: p.dimension,
          templateFamilyId: p.templateFamilyId,
          displayedOptionIds: ids,
          displayedCorrectPosition: ids.indexOf(
            // placeholder; validator rehydrates
            ids.first,
          ),
        );
      }).toList();
      final shuffled = IqPersistedSessionState(
        schemaVersion: session.schemaVersion,
        sessionId: session.sessionId,
        ownerUid: session.ownerUid,
        bankVersion: session.bankVersion,
        bankLocale: session.bankLocale,
        selectionPolicyVersion: session.selectionPolicyVersion,
        sessionSeed: session.sessionSeed,
        itemPlans: shuffledPlans,
        currentQuestionIndex: session.currentQuestionIndex,
        answers: session.answers,
        startedAt: session.startedAt,
        updatedAt: session.updatedAt,
        completedAt: session.completedAt,
        status: session.status,
      );
      final shuffledScore = const IqCanonicalScorer().scoreCompletedSession(
        session: shuffled,
        bank: bank,
        ownerUid: 'uid_score',
      );
      expect(shuffledScore.ok, isTrue);
      expect(
        shuffledScore.result!.dimensionScores
            .map((e) => e.rawAccuracy)
            .toList(),
        base.result!.dimensionScores.map((e) => e.rawAccuracy).toList(),
      );

      // Presentation-order invariance: swap two items of different dimensions
      // when the swap preserves streak/quota invariants.
      List<IqSessionItemPlan>? swappedPlans;
      final plans = List<IqSessionItemPlan>.from(session.itemPlans);
      outer:
      for (var i = 0; i < plans.length; i++) {
        for (var j = i + 1; j < plans.length; j++) {
          if (plans[i].dimension == plans[j].dimension) continue;
          final trial = List<IqSessionItemPlan>.from(plans);
          final tmp = trial[i];
          trial[i] = trial[j];
          trial[j] = tmp;
          final trialState = IqPersistedSessionState(
            schemaVersion: session.schemaVersion,
            sessionId: session.sessionId,
            ownerUid: session.ownerUid,
            bankVersion: session.bankVersion,
            bankLocale: session.bankLocale,
            selectionPolicyVersion: session.selectionPolicyVersion,
            sessionSeed: session.sessionSeed,
            itemPlans: trial,
            currentQuestionIndex: session.currentQuestionIndex,
            answers: session.answers,
            startedAt: session.startedAt,
            updatedAt: session.updatedAt,
            completedAt: session.completedAt,
            status: session.status,
          );
          final check = IqPersistedSessionValidator.validate(
            state: trialState,
            bank: bank,
            ownerUid: 'uid_score',
          );
          if (check.isLoaded) {
            swappedPlans = trial;
            break outer;
          }
        }
      }
      expect(swappedPlans, isNotNull);
      final swapped = IqPersistedSessionState(
        schemaVersion: session.schemaVersion,
        sessionId: session.sessionId,
        ownerUid: session.ownerUid,
        bankVersion: session.bankVersion,
        bankLocale: session.bankLocale,
        selectionPolicyVersion: session.selectionPolicyVersion,
        sessionSeed: session.sessionSeed,
        itemPlans: swappedPlans!,
        currentQuestionIndex: session.currentQuestionIndex,
        answers: session.answers,
        startedAt: session.startedAt,
        updatedAt: session.updatedAt,
        completedAt: session.completedAt,
        status: session.status,
      );
      final orderScore = const IqCanonicalScorer().scoreCompletedSession(
        session: swapped,
        bank: bank,
        ownerUid: 'uid_score',
      );
      expect(orderScore.ok, isTrue);
      expect(
        orderScore.result!.dimensionScores
            .map((e) => '${e.dimension}:${e.correctCount}')
            .toList(),
        base.result!.dimensionScores
            .map((e) => '${e.dimension}:${e.correctCount}')
            .toList(),
      );
    });

    test('2 incomplete / not completed rejected', () async {
      final repo = IqSessionMemoryRepository();
      final manager = IqSessionManager(
        bank: bank,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(3)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_score',
        sessionSeed: 'incomplete',
      );
      final fail = const IqCanonicalScorer().scoreCompletedSession(
        session: created.state!,
        bank: bank,
        ownerUid: 'uid_score',
      );
      expect(fail.ok, isFalse);
      expect(fail.code, IqScoringFailureCode.sessionIncomplete);
    });

    test('18-27 tamper resistance', () async {
      final session = await _completeSession(
        bank: bank,
        seed: 'score-tamper',
        pick: (_, __, c) => c,
      );

      // Invalid selected option
      final badOptAnswers = [
        for (final a in session.answers)
          a.itemId == session.itemPlans.first.itemId
              ? IqSessionAnswer(
                  itemId: a.itemId,
                  selectedOptionId: 'not_real_option',
                  answeredAt: a.answeredAt,
                )
              : a,
      ];
      final badOpt = session.copyWith(answers: badOptAnswers);
      expect(
        const IqCanonicalScorer()
            .scoreCompletedSession(
              session: badOpt,
              bank: bank,
              ownerUid: 'uid_score',
            )
            .ok,
        isFalse,
      );

      // Unknown item in answers
      final badItem = session.copyWith(
        answers: [
          ...session.answers.skip(1),
          IqSessionAnswer(
            itemId: 'unknown_item_zzz',
            selectedOptionId: 'a',
            answeredAt: session.answers.first.answeredAt,
          ),
        ],
      );
      expect(
        const IqCanonicalScorer()
            .scoreCompletedSession(
              session: badItem,
              bank: bank,
              ownerUid: 'uid_score',
            )
            .ok,
        isFalse,
      );

      // Duplicate answer
      final dupJson = session.toJson();
      final answers = List<Map<String, dynamic>>.from(
        (dupJson['answers'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      answers.add(Map<String, dynamic>.from(answers.first));
      dupJson['answers'] = answers;
      final dupState = IqPersistedSessionState.fromJson(dupJson);
      expect(
        const IqCanonicalScorer()
            .scoreCompletedSession(
              session: dupState,
              bank: bank,
              ownerUid: 'uid_score',
            )
            .ok,
        isFalse,
      );

      // Missing answer (completed with 24)
      final missingJson = session.toJson();
      missingJson['answers'] =
          (missingJson['answers'] as List).take(24).toList();
      final missing = IqPersistedSessionState.fromJson(missingJson);
      expect(
        const IqCanonicalScorer()
            .scoreCompletedSession(
              session: missing,
              bank: bank,
              ownerUid: 'uid_score',
            )
            .ok,
        isFalse,
      );

      // Bank mismatch
      final bankMismatch = IqPersistedSessionState.fromJson({
        ...session.toJson(),
        'bank_version': 'other_bank',
      });
      expect(
        const IqCanonicalScorer()
            .scoreCompletedSession(
              session: bankMismatch,
              bank: bank,
              ownerUid: 'uid_score',
            )
            .code,
        IqScoringFailureCode.incompatibleBank,
      );

      // Policy mismatch
      final policyMismatch = IqPersistedSessionState.fromJson({
        ...session.toJson(),
        'selection_policy_version': 'other_policy',
      });
      expect(
        const IqCanonicalScorer()
            .scoreCompletedSession(
              session: policyMismatch,
              bank: bank,
              ownerUid: 'uid_score',
            )
            .code,
        IqScoringFailureCode.incompatiblePolicy,
      );

      // Dimension tampering
      final dimJson = session.toJson();
      final plans = (dimJson['item_plans'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final bankItem =
          bank.items.firstWhere((i) => i.id == plans[0]['item_id']);
      plans[0]['dimension'] = bankItem.dimension == 'logical_reasoning'
          ? 'verbal_reasoning'
          : 'logical_reasoning';
      dimJson['item_plans'] = plans;
      expect(
        const IqCanonicalScorer()
            .scoreCompletedSession(
              session: IqPersistedSessionState.fromJson(dimJson),
              bank: bank,
              ownerUid: 'uid_score',
            )
            .ok,
        isFalse,
      );

      // Family tampering
      final famJson = session.toJson();
      final plans2 = (famJson['item_plans'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      plans2[0]['template_family_id'] = 'tampered_family';
      famJson['item_plans'] = plans2;
      expect(
        const IqCanonicalScorer()
            .scoreCompletedSession(
              session: IqPersistedSessionState.fromJson(famJson),
              bank: bank,
              ownerUid: 'uid_score',
            )
            .ok,
        isFalse,
      );

      // Invalid displayed options
      final optJson = session.toJson();
      final plans3 = (optJson['item_plans'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      plans3[0]['displayed_option_ids'] = ['x', 'y', 'z', 'w'];
      optJson['item_plans'] = plans3;
      expect(
        const IqCanonicalScorer()
            .scoreCompletedSession(
              session: IqPersistedSessionState.fromJson(optJson),
              bank: bank,
              ownerUid: 'uid_score',
            )
            .ok,
        isFalse,
      );

      // Completed without 25 answers already covered; also status completed
      // with empty answers:
      final emptyCompleted = IqPersistedSessionState.fromJson({
        ...session.toJson(),
        'answers': <dynamic>[],
      });
      expect(
        const IqCanonicalScorer()
            .scoreCompletedSession(
              session: emptyCompleted,
              bank: bank,
              ownerUid: 'uid_score',
            )
            .ok,
        isFalse,
      );
    });

    test('28-40 serialization, privacy, no IQ fields', () async {
      final session = await _completeSession(
        bank: bank,
        seed: 'score-ser',
        pick: (i, plan, c) => i % 3 == 0
            ? c
            : plan.displayedOptionIds.firstWhere((id) => id != c),
      );
      final scored = const IqCanonicalScorer().scoreCompletedSession(
        session: session,
        bank: bank,
        ownerUid: 'uid_score',
        clock: () => DateTime.utc(2026, 8, 9, 16),
      );
      expect(scored.ok, isTrue);
      final s1 = jsonEncode(scored.result!.toJson());
      final s2 = jsonEncode(
        IqCanonicalScoringResult.fromJson(
          jsonDecode(s1) as Map<String, dynamic>,
        ).toJson(),
      );
      expect(s2, s1);

      final order = scored.result!.dimensionScores.map((e) => e.dimension);
      expect(order, IqCanonicalDimensions.all);

      expect(s1.contains('correct_option_id'), isFalse);
      expect(s1.contains('"prompt"'), isFalse);
      expect(s1.contains('"email"'), isFalse);
      expect(s1.contains('overallIq'), isFalse);
      expect(s1.contains('iqScore'), isFalse);
      expect(s1.contains('percentile'), isFalse);
      expect(s1.contains('estimatedIq'), isFalse);
      expect(s1.contains('numerical'), isFalse);
      expect(s1.contains('quantum'), isFalse);
      expect(jsonDecode(s1)['reliability_estimate'], isNull);
      expect(jsonDecode(s1)['empirical_uncertainty'], isNull);
      expect(
        IqScoringResultValidator.validate(scored.result!).ok,
        isTrue,
      );
    });

    test('41-42 bank immutability', () async {
      final before = _bankFingerprint(bank);
      for (var n = 0; n < 5; n++) {
        final session = await _completeSession(
          bank: bank,
          seed: 'immut-$n',
          pick: (_, __, c) => c,
          uid: 'uid_immut_$n',
        );
        final r = const IqCanonicalScorer().scoreCompletedSession(
          session: session,
          bank: bank,
          ownerUid: 'uid_immut_$n',
        );
        expect(r.ok, isTrue);
      }
      expect(_bankFingerprint(bank), before);
    });
  });

  group('45-50 runtime isolation', () {
    test('live IQ / TraitScoring / Core Method untouched', () {
      expect(QuestionService, isNotNull);
      expect(IQTestScreen, isNotNull);
      final iq = File(
        'lib/features/assessment/screens/iq_test_screen.dart',
      ).readAsStringSync();
      expect(iq.contains('IqCanonicalScorer'), isFalse);
      // Runtime integration (P2C-2A-5) may import scoring models for result handoff.
      expect(iq.contains('IqCanonicalRuntimeService'), isTrue);

      final qs = File(
        'lib/features/assessment/services/question_service.dart',
      ).readAsStringSync();
      expect(qs.contains('IqCanonicalScorer'), isFalse);

      for (final path in [
        'lib/features/assessment/domain/iq_scoring/iq_canonical_scorer.dart',
        'lib/features/assessment/domain/iq_scoring/iq_scoring_models.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains("import 'package:cloud_firestore"), isFalse);
        expect(src.contains('TraitScoringService'), isFalse);
        expect(src.contains('core_method_v2'), isFalse);
        expect(src.contains('quantum_inspired'), isFalse);
        expect(src.contains('quantumScore'), isFalse);
      }

      // Persistence domain files unchanged by this phase for resume semantics.
      final manager = File(
        'lib/features/assessment/domain/iq_session/iq_session_manager.dart',
      ).readAsStringSync();
      expect(manager.contains('IqCanonicalScorer'), isFalse);
    });
  });
}
