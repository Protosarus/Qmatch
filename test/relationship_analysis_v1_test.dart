import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_analysis_state.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_bank_loader.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_dimensions.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_micro_scan_selector.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_scorer.dart';
import 'package:qmatch/features/relationship_analysis/services/relationship_analysis_persistence.dart';

void main() {
  final bankJson =
      File('assets/data/relationship_analysis_v1.json').readAsStringSync();
  final bank = RelationshipBankLoader.parseJsonString(bankJson);

  test('exactly 24 canonical questions with unique ids', () {
    expect(bank.items.length, RelationshipAnalysisContract.questionCount);
    expect(bank.items.map((q) => q.id).toSet().length, 24);
  });

  test('canonical question ids remain stable and ordered', () {
    const expectedIds = [
      'ra_v1_01_busy_workday',
      'ra_v1_02_weekend_morning',
      'ra_v1_03_hobby_evening',
      'ra_v1_04_short_notice_trip',
      'ra_v1_05_partner_friends_party',
      'ra_v1_06_after_disagreement',
      'ra_v1_07_plans_change',
      'ra_v1_08_long_distance_week',
      'ra_v1_09_career_move',
      'ra_v1_10_define_us',
      'ra_v1_11_affection_style',
      'ra_v1_12_unexpected_free_evening',
      'ra_v1_13_meet_friends',
      'ra_v1_14_vacation_style',
      'ra_v1_15_after_intense_day',
      'ra_v1_16_weekend_uncertainty',
      'ra_v1_17_daytime_texting',
      'ra_v1_18_repair_timing',
      'ra_v1_19_partner_night_out',
      'ra_v1_20_exclusivity',
      'ra_v1_21_affection_mismatch',
      'ra_v1_22_date_energy',
      'ra_v1_23_calendar_visibility',
      'ra_v1_24_future_talk',
    ];
    expect(bank.items.map((q) => q.id).toList(), expectedIds);
  });

  test('all EN/TR question and option text populated', () {
    for (final q in bank.items) {
      expect(q.prompt.en, isNotEmpty, reason: q.id);
      expect(q.prompt.tr, isNotEmpty, reason: q.id);
      expect(q.options.length, inInclusiveRange(2, 4));
      for (final o in q.options) {
        expect(o.text.en, isNotEmpty);
        expect(o.text.tr, isNotEmpty);
        expect(o.dimensionDeltas, isNotEmpty);
        for (final key in o.dimensionDeltas.keys) {
          expect(RelationshipDimensionIds.allSet.contains(key), isTrue);
        }
      }
    }
  });

  test('scoring vectors use only declared dims with finite bounded weights',
      () {
    for (final q in bank.items) {
      for (final o in q.options) {
        for (final e in o.dimensionDeltas.entries) {
          expect(RelationshipDimensionIds.allSet.contains(e.key), isTrue);
          expect(e.value.isFinite, isTrue, reason: '${q.id}/${o.id}');
          expect(e.value, isNot(0), reason: '${q.id}/${o.id} zero weight');
          expect(e.value.abs(), lessThanOrEqualTo(0.55));
        }
      }
    }
  });

  test('relationship_pace is limited to genuine integration items', () {
    const allowed = {
      'ra_v1_07_plans_change',
      'ra_v1_10_define_us',
      'ra_v1_13_meet_friends',
      'ra_v1_16_weekend_uncertainty',
      'ra_v1_20_exclusivity',
      'ra_v1_24_future_talk',
    };
    final paced = <String>{};
    for (final q in bank.items) {
      for (final o in q.options) {
        if (o.dimensionDeltas.containsKey(
          RelationshipDimensionIds.relationshipPace,
        )) {
          paced.add(q.id);
        }
      }
    }
    expect(paced, allowed);
  });

  test('every dimension has sufficient bank evidence', () {
    final abs = {for (final d in RelationshipDimensionIds.all) d: 0.0};
    final touched = {
      for (final d in RelationshipDimensionIds.all) d: <String>{},
    };
    for (final q in bank.items) {
      for (final o in q.options) {
        for (final e in o.dimensionDeltas.entries) {
          abs[e.key] = abs[e.key]! + e.value.abs();
          touched[e.key]!.add(q.id);
        }
      }
    }
    for (final d in RelationshipDimensionIds.all) {
      expect(
        touched[d]!.length,
        greaterThanOrEqualTo(
          RelationshipAnalysisContract.minQuestionsPerDimension,
        ),
      );
      expect(
        abs[d],
        greaterThanOrEqualTo(
          RelationshipAnalysisContract.minAbsWeightPerDimension,
        ),
      );
    }
  });

  test('scoring deterministic and bounded; unanswered ignored', () {
    const scorer = RelationshipAnalysisScorer();
    final answers = {
      for (final q in bank.items.take(8)) q.id: q.options.first.id,
    };
    final a = scorer.score(bank: bank, answersByQuestionId: answers);
    final b = scorer.score(bank: bank, answersByQuestionId: answers);
    expect(a.dimensionScores, b.dimensionScores);
    expect(a.analysisDepth, b.analysisDepth);
    for (final v in a.dimensionScores.values) {
      expect(v, inInclusiveRange(0.0, 1.0));
    }
    expect(a.analysisDepth, inInclusiveRange(0.0, 1.0));

    final empty = scorer.score(bank: bank, answersByQuestionId: const {});
    for (final d in RelationshipDimensionIds.all) {
      expect(
          empty.dimensionScores[d], RelationshipAnalysisContract.scoreBaseline);
      expect(empty.dimensionEvidenceCounts[d], 0);
    }
    expect(empty.analysisDepth, 0.0);
  });

  test('duplicate answer map does not inflate evidence', () {
    const scorer = RelationshipAnalysisScorer();
    final q = bank.items.first;
    final once = scorer.score(
      bank: bank,
      answersByQuestionId: {q.id: q.options.first.id},
    );
    final again = scorer.score(
      bank: bank,
      answersByQuestionId: {q.id: q.options.first.id},
    );
    expect(once.dimensionEvidenceCounts, again.dimensionEvidenceCounts);
    expect(once.dimensionRawSignedEvidence, again.dimensionRawSignedEvidence);
  });

  test('micro-scan size 4, resumes without reshuffle, skips answered', () {
    const selector = RelationshipMicroScanSelector();
    final evidence = {for (final d in RelationshipDimensionIds.all) d: 0};
    final first = selector.selectOrResume(
      bank: bank,
      answeredQuestionIds: {},
      dimensionEvidenceCounts: evidence,
    );
    expect(first.length, 4);
    expect(
      selector.selectOrResume(
        bank: bank,
        answeredQuestionIds: {},
        dimensionEvidenceCounts: evidence,
        activeQuestionIds: first,
      ),
      first,
    );
    final resumed = selector.selectOrResume(
      bank: bank,
      answeredQuestionIds: {first.first},
      dimensionEvidenceCounts: evidence,
      activeQuestionIds: first,
    );
    expect(resumed.contains(first.first), isFalse);
    expect(resumed, first.skip(1).toList());

    final nextBatch = selector.selectNext(
      bank: bank,
      answeredQuestionIds: first.toSet(),
      dimensionEvidenceCounts: {
        for (final d in RelationshipDimensionIds.all) d: 2,
      },
    );
    expect(nextBatch.toSet().intersection(first.toSet()), isEmpty);
  });

  test('analysis depth grows with coverage and never exceeds 1.0', () {
    const scorer = RelationshipAnalysisScorer();
    final d1 = scorer.score(
      bank: bank,
      answersByQuestionId: {
        for (final q in bank.items.take(4)) q.id: q.options.first.id,
      },
    ).analysisDepth;
    final d2 = scorer.score(
      bank: bank,
      answersByQuestionId: {
        for (final q in bank.items.take(12)) q.id: q.options.first.id,
      },
    ).analysisDepth;
    final d3 = scorer.score(
      bank: bank,
      answersByQuestionId: {
        for (final q in bank.items) q.id: q.options.first.id,
      },
    ).analysisDepth;
    expect(d2, greaterThan(d1));
    expect(d3, greaterThanOrEqualTo(d2));
    expect(d3, lessThanOrEqualTo(1.0));
  });

  test('persistence round-trip and hard wall flags', () async {
    final memory = <String, Map<String, dynamic>>{};
    final persistence = RelationshipAnalysisPersistence(
      loadOverride: (uid) async => memory[uid],
      writeOverride: (uid, fields) async {
        final target = memory.putIfAbsent(uid, () => <String, dynamic>{});
        RelationshipAnalysisPersistence.mergeFields(target, fields);
      },
    );

    const scorer = RelationshipAnalysisScorer();
    final answers = {
      for (final q in bank.items.take(4)) q.id: q.options.first.id,
    };
    final snap = scorer.score(bank: bank, answersByQuestionId: answers);
    final state = RelationshipAnalysisState.empty().copyWith(
      answersByQuestionId: answers,
      dimensionScores: snap.dimensionScores,
      dimensionEvidenceCounts: snap.dimensionEvidenceCounts,
      dimensionRawSignedEvidence: snap.dimensionRawSignedEvidence,
      analysisDepth: snap.analysisDepth,
      activeMicroScanId: 'ra_test',
      activeMicroScanQuestionIds: answers.keys.toList(),
      activeMicroScanIndex: 2,
    );

    await persistence.saveForUid(uid: 'u1', state: state);
    final loaded = await persistence.loadForUid('u1');
    expect(loaded.answersByQuestionId, answers);
    expect(loaded.analysisDepth, closeTo(snap.analysisDepth, 1e-9));
    expect(loaded.activeMicroScanQuestionIds, answers.keys.toList());

    final fields = loaded.toPersistenceFields();
    expect(fields['persona_input'], isFalse);
    expect(fields['matching_input'], isFalse);
    expect(fields['canonical_20d_merged'], isFalse);
    expect(fields.containsKey('primary_persona_id'), isFalse);
  });

  test('clearing active micro-scan removes stale active_micro_scan field',
      () async {
    final memory = <String, Map<String, dynamic>>{};
    final persistence = RelationshipAnalysisPersistence(
      loadOverride: (uid) async => memory[uid],
      writeOverride: (uid, fields) async {
        final target = memory.putIfAbsent(uid, () => <String, dynamic>{});
        RelationshipAnalysisPersistence.mergeFields(target, fields);
      },
    );

    const scorer = RelationshipAnalysisScorer();
    final answers = {
      for (final q in bank.items.take(4)) q.id: q.options.first.id,
    };
    final snap = scorer.score(bank: bank, answersByQuestionId: answers);

    await persistence.saveForUid(
      uid: 'u1',
      state: RelationshipAnalysisState.empty().copyWith(
        answersByQuestionId: answers,
        dimensionScores: snap.dimensionScores,
        dimensionEvidenceCounts: snap.dimensionEvidenceCounts,
        dimensionRawSignedEvidence: snap.dimensionRawSignedEvidence,
        analysisDepth: snap.analysisDepth,
        activeMicroScanId: 'ra_open',
        activeMicroScanQuestionIds: answers.keys.toList(),
        activeMicroScanIndex: 3,
      ),
    );
    expect(memory['u1']!.containsKey('active_micro_scan'), isTrue);

    await persistence.saveForUid(
      uid: 'u1',
      state: RelationshipAnalysisState.empty().copyWith(
        answersByQuestionId: answers,
        dimensionScores: snap.dimensionScores,
        dimensionEvidenceCounts: snap.dimensionEvidenceCounts,
        dimensionRawSignedEvidence: snap.dimensionRawSignedEvidence,
        analysisDepth: snap.analysisDepth,
        clearActiveMicroScan: true,
      ),
    );

    expect(memory['u1']!.containsKey('active_micro_scan'), isFalse);
    final loaded = await persistence.loadForUid('u1');
    expect(loaded.activeMicroScanQuestionIds, isEmpty);
    expect(loaded.hasActiveMicroScan, isFalse);
  });

  test('replacing an answer keeps single evidence count per question', () {
    const scorer = RelationshipAnalysisScorer();
    final q = bank.items.first;
    final first = scorer.score(
      bank: bank,
      answersByQuestionId: {q.id: q.options.first.id},
    );
    final replaced = scorer.score(
      bank: bank,
      answersByQuestionId: {q.id: q.options.last.id},
    );
    final firstTotal =
        first.dimensionEvidenceCounts.values.fold<int>(0, (a, b) => a + b);
    final replacedTotal =
        replaced.dimensionEvidenceCounts.values.fold<int>(0, (a, b) => a + b);
    expect(firstTotal, replacedTotal);
  });
}
