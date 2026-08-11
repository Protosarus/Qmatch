import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_scoring/frequency_scoring.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';
import 'package:qmatch/features/assessment/domain/profile/profile.dart';
import 'package:qmatch/features/assessment/services/frequency_canonical_runtime_service.dart';

FrequencyCanonicalBankDocument _load(String path) {
  return FrequencyCanonicalBankDocument.fromJson(
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
  );
}

List<QmatchProfileDimension> _fakeIq() => [
      for (final id in QmatchProfileTaxonomy.iq)
        QmatchProfileDimension(
          dimensionId: id,
          module: 'iq',
          measurementState: QmatchMeasurementState.measured,
          value: 0.71,
          source: QmatchProfileContract.measurementSourceCanonicalIq,
          sourceVersion: 'iq_4d_uncalibrated_accuracy_v1',
          calibrationStatus: 'uncalibrated',
          reliabilityStatus:
              QmatchProfileContract.reliabilityStatusNotCalibrated,
        ),
    ];

List<QmatchProfileDimension> _fakeEq() => [
      for (final id in QmatchProfileTaxonomy.eq)
        QmatchProfileDimension(
          dimensionId: id,
          module: 'eq',
          measurementState: QmatchMeasurementState.measured,
          value: 0.62,
          source: QmatchProfileContract.measurementSourceCanonicalEq,
          sourceVersion: 'eq_10d_uncalibrated_signed_evidence_v1',
          calibrationStatus: 'uncalibrated',
          reliabilityStatus:
              QmatchProfileContract.reliabilityStatusNotCalibrated,
        ),
    ];

void main() {
  late FrequencyCanonicalBankDocument tr;
  late FrequencyCanonicalBankDocument en;

  setUpAll(() {
    tr = _load(FrequencyBankContract.trAssetPath);
    en = _load(FrequencyBankContract.enAssetPath);
  });

  group('Frequency runtime session', () {
    test('TR session: 50 items, roles, resume, locale stable', () async {
      final repo = FrequencySessionMemoryRepository();
      final manager = FrequencySessionManager(
        bank: tr,
        repository: repo,
        idFactory: FrequencySessionIdFactory(random: Random(3)),
        shuffleRandom: Random(9),
        clock: () => DateTime.utc(2026, 8, 9, 18),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'seed_a',
      );
      expect(created.ok, isTrue);
      expect(created.state!.itemPlans.length, 50);
      expect(created.state!.bankLocale, 'tr-TR');
      expect(
        FrequencySessionContract.selectionPolicyVersion,
        'frequency_50_full_bank_deterministic_v1',
      );
      expect(
        FrequencySessionContract.scoringPolicyVersion,
        'frequency_6d_uncalibrated_signed_evidence_v1',
      );
      expect(
        created.state!.selectionPolicyVersion,
        FrequencySessionContract.selectionPolicyVersion,
      );

      final roles = <String, int>{};
      for (final p in created.state!.itemPlans) {
        final item = tr.itemsById[p.itemId]!;
        roles[item.itemRole] = (roles[item.itemRole] ?? 0) + 1;
      }
      expect(roles['core'], 30);
      expect(roles['behavioral_equivalence'], 12);
      expect(roles['separator'], 6);
      expect(roles['response_quality'], 2);

      final first = created.state!.itemPlans.first;
      final ans = await manager.answer(
        ownerUid: 'uid_a',
        sessionId: created.state!.sessionId,
        itemId: first.itemId,
        selectedOptionId: first.displayedOptionIds.first,
      );
      expect(ans.ok, isTrue);
      await manager.moveToIndex(
        ownerUid: 'uid_a',
        sessionId: created.state!.sessionId,
        index: 1,
      );

      final resumed = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'ignored',
      );
      expect(resumed.ok, isTrue);
      expect(manager.lastOperationComposed, isFalse);
      expect(resumed.state!.sessionId, created.state!.sessionId);
      expect(resumed.state!.currentQuestionIndex, 1);
      expect(resumed.state!.bankLocale, 'tr-TR');
      expect(
        resumed.state!.itemPlans.first.displayedOptionIds,
        first.displayedOptionIds,
      );
    });

    test('EN session loads EN bank; UID isolation', () async {
      final repo = FrequencySessionMemoryRepository();
      final manager = FrequencySessionManager(
        bank: en,
        repository: repo,
        idFactory: FrequencySessionIdFactory(random: Random(1)),
        shuffleRandom: Random(2),
      );
      final a = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 's',
      );
      expect(a.state!.bankLocale, 'en-US');
      expect(a.state!.itemPlans.length, 50);
      final bLoad = await repo.loadSession('uid_b', a.state!.sessionId);
      expect(bLoad.code, FrequencySessionLoadCode.notFound);
    });

    test('incomplete cannot score; complete scores 6 dims', () async {
      final repo = FrequencySessionMemoryRepository();
      final manager = FrequencySessionManager(
        bank: tr,
        repository: repo,
        idFactory: FrequencySessionIdFactory(random: Random(4)),
        shuffleRandom: Random(5),
        clock: () => DateTime.utc(2026, 8, 9),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_score',
        sessionSeed: 'seed_score',
      );
      final incomplete = const CanonicalFrequencyScorer().score(
        bank: tr,
        responses: [
          FrequencyCanonicalResponse(
            itemId: created.state!.itemPlans.first.itemId,
            optionId: created.state!.itemPlans.first.displayedOptionIds.first,
          ),
        ],
      );
      expect(incomplete.ok, isFalse);

      var state = created.state!;
      for (var i = 0; i < state.itemPlans.length; i++) {
        final plan = state.itemPlans[i];
        final item = tr.itemsById[plan.itemId]!;
        var optionId = plan.displayedOptionIds.first;
        if (item.itemRole == FrequencyBankContract.itemRoleQuality) {
          optionId = item.expectedProtocolOptionId!;
        }
        final answered = await manager.answer(
          ownerUid: 'uid_score',
          sessionId: state.sessionId,
          itemId: plan.itemId,
          selectedOptionId: optionId,
        );
        state = answered.state!;
        if (i < state.itemPlans.length - 1) {
          state = (await manager.moveToIndex(
            ownerUid: 'uid_score',
            sessionId: state.sessionId,
            index: i + 1,
          ))
              .state!;
        }
      }
      final completed = await manager.complete(
        ownerUid: 'uid_score',
        sessionId: state.sessionId,
      );
      expect(completed.ok, isTrue);
      final responses = [
        for (final p in completed.state!.itemPlans)
          FrequencyCanonicalResponse(
            itemId: p.itemId,
            optionId:
                completed.state!.answersByItemId[p.itemId]!.selectedOptionId,
          ),
      ];
      final scored = const CanonicalFrequencyScorer().score(
        bank: tr,
        responses: responses,
      );
      expect(scored.ok, isTrue, reason: scored.message);
      expect(scored.result!.dimensionScores.length, 6);
      expect(scored.result!.toJson()['overall_frequency_score'], isNull);

      final signals = FrequencyCanonicalRuntimeService.deriveQualitySignals(
        bank: tr,
        session: completed.state!,
      );
      expect(signals['attention_check_1_passed'], isTrue);
      expect(signals['attention_check_2_passed'], isTrue);
      expect(
          signals['rvi_runtime_gate'], FrequencyScoringContract.rviRuntimeGate);
    });

    test('quality pass/fail does not change trait scores', () async {
      Future<FrequencyCanonicalScoringResult> run(bool pass) async {
        final repo = FrequencySessionMemoryRepository();
        final manager = FrequencySessionManager(
          bank: tr,
          repository: repo,
          idFactory: FrequencySessionIdFactory(random: Random(7)),
          shuffleRandom: Random(8),
          clock: () => DateTime.utc(2026, 8, 9),
        );
        final created = await manager.getOrCreateActiveSession(
          ownerUid: 'uid_q',
          sessionSeed: 'same_seed',
        );
        var state = created.state!;
        for (var i = 0; i < state.itemPlans.length; i++) {
          final plan = state.itemPlans[i];
          final item = tr.itemsById[plan.itemId]!;
          var optionId = plan.displayedOptionIds.first;
          if (item.itemRole == FrequencyBankContract.itemRoleQuality) {
            if (pass) {
              optionId = item.expectedProtocolOptionId!;
            } else {
              optionId = item.options
                  .firstWhere(
                      (o) => o.optionId != item.expectedProtocolOptionId)
                  .optionId;
            }
          }
          state = (await manager.answer(
            ownerUid: 'uid_q',
            sessionId: state.sessionId,
            itemId: plan.itemId,
            selectedOptionId: optionId,
          ))
              .state!;
          if (i < state.itemPlans.length - 1) {
            state = (await manager.moveToIndex(
              ownerUid: 'uid_q',
              sessionId: state.sessionId,
              index: i + 1,
            ))
                .state!;
          }
        }
        final completed = await manager.complete(
          ownerUid: 'uid_q',
          sessionId: state.sessionId,
        );
        final responses = [
          for (final p in completed.state!.itemPlans)
            FrequencyCanonicalResponse(
              itemId: p.itemId,
              optionId:
                  completed.state!.answersByItemId[p.itemId]!.selectedOptionId,
            ),
        ];
        final scored = const CanonicalFrequencyScorer().score(
          bank: tr,
          responses: responses,
        );
        expect(scored.ok, isTrue);
        return scored.result!;
      }

      final a = await run(true);
      final b = await run(false);
      for (final id in FrequencyCanonicalDimensions.all) {
        expect(a.scoreFor(id).normalizedScore, b.scoreFor(id).normalizedScore);
        expect(a.scoreFor(id).evidenceCount, b.scoreFor(id).evidenceCount);
        expect(
            a.scoreFor(id).rawSignedEvidence, b.scoreFor(id).rawSignedEvidence);
      }
    });
  });

  group('Frequency→20D adapter', () {
    test('maps 6 dims; preserves IQ+EQ; 20/20 ready via registry', () {
      final responses = [
        for (final i in tr.items)
          FrequencyCanonicalResponse(
            itemId: i.itemId,
            optionId: i.itemRole == FrequencyBankContract.itemRoleQuality
                ? i.expectedProtocolOptionId!
                : i.options.first.optionId,
          ),
      ];
      final scored = const CanonicalFrequencyScorer().score(
        bank: tr,
        responses: responses,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      expect(scored.ok, isTrue, reason: scored.message);

      final iq = _fakeIq();
      final eq = _fakeEq();
      final adapted = const FrequencyTo20dRuntimeAdapter().adapt(
        result: scored.result!,
        ownerUid: 'uid_20',
        sessionId: 'sess_20',
        existingIqDimensions: iq,
        existingEqDimensions: eq,
        clock: DateTime.utc(2026, 8, 9),
      );
      expect(adapted.ok, isTrue, reason: adapted.message);
      final f = adapted.fragment!;
      expect(f.measuredDimensionCount, 20);
      expect(f.requiredDimensionCount, 20);
      expect(f.missingDimensionIds, isEmpty);
      expect(f.profileStatus, QmatchProfileStatus.complete);
      expect(f.canonicalProfileReady, isTrue);
      expect(f.iqGroupStatus, QmatchGroupCompletionStatus.complete);
      expect(f.eqGroupStatus, QmatchGroupCompletionStatus.complete);
      expect(f.frequencyGroupStatus, QmatchGroupCompletionStatus.complete);

      for (final d in iq) {
        expect(
          f.measuredDimensions
              .firstWhere((x) => x.dimensionId == d.dimensionId)
              .value,
          d.value,
        );
      }
      for (final d in eq) {
        expect(
          f.measuredDimensions
              .firstWhere((x) => x.dimensionId == d.dimensionId)
              .value,
          d.value,
        );
      }

      final again = const FrequencyTo20dRuntimeAdapter().adapt(
        result: scored.result!,
        ownerUid: 'uid_20',
        sessionId: 'sess_20',
        existingIqDimensions: iq,
        existingEqDimensions: eq,
        clock: DateTime.utc(2026, 8, 9),
      );
      expect(jsonEncode(again.fragment!.toJson()), jsonEncode(f.toJson()));

      expect(
        FrequencyTo20dRuntimeAdapter.registryComplete([
          for (var i = 0; i < 20; i++)
            QmatchProfileDimension(
              dimensionId: 'fake_$i',
              module: 'iq',
              measurementState: QmatchMeasurementState.measured,
              value: 0.5,
              source: 'x',
              sourceVersion: 'x',
              calibrationStatus: 'uncalibrated',
              reliabilityStatus: 'not_calibrated',
            ),
        ]),
        isFalse,
      );
    });

    test('fails without preserved EQ', () {
      final responses = [
        for (final i in tr.items)
          FrequencyCanonicalResponse(
            itemId: i.itemId,
            optionId: i.options.first.optionId,
          ),
      ];
      final scored = const CanonicalFrequencyScorer().score(
        bank: tr,
        responses: responses,
      );
      final adapted = const FrequencyTo20dRuntimeAdapter().adapt(
        result: scored.result!,
        ownerUid: 'uid',
        sessionId: 's',
        existingIqDimensions: _fakeIq(),
        existingEqDimensions: const [],
      );
      expect(adapted.ok, isFalse);
      expect(adapted.code, FrequencyTo20dFailureCode.eqPreservationFailed);
    });
  });

  group('downstream isolation', () {
    test('runtime/screen do not invoke Persona/matching/quantum', () {
      final src = File(
        'lib/features/assessment/services/frequency_canonical_runtime_service.dart',
      ).readAsStringSync();
      expect(src.toLowerCase().contains('persona'), isFalse);
      expect(src.contains('qrcf'), isFalse);
      expect(src.contains('density_matrix'), isFalse);
      final screen = File(
        'lib/features/assessment/screens/frequency_test_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('PersonaScoring'), isFalse);
      expect(screen.contains('FrequencyResultScreen'), isFalse);
      expect(screen.contains('PersonaAssignmentGateScreen'), isTrue);
      expect(screen.contains('AssessmentFlowCompleteScreen'), isFalse);
    });
  });

  group('EN semantic review artifact', () {
    test('review doc exists and EN bank has no pending stubs', () {
      expect(
        File('docs/assessment/qmatch_frequency_en_semantic_review_v1.md')
            .existsSync(),
        isTrue,
      );
      final enRaw = File(FrequencyBankContract.enAssetPath).readAsStringSync();
      expect(enRaw.contains('EN equivalent pending'), isFalse);
      final loc = jsonDecode(enRaw)['localization'] as Map;
      expect(loc['internal_semantic_equivalence_review'], 'passed');
      expect(loc['psychometric_cross_language_validation'], 'not_calibrated');
      expect(en.locale, 'en-US');
    });
  });
}
