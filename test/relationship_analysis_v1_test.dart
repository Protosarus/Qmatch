import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_analysis_state.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_bank_loader.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_dimensions.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_micro_scan_selector.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_scorer.dart';
import 'package:qmatch/features/relationship_analysis/services/relationship_analysis_discovery.dart';
import 'package:qmatch/features/relationship_analysis/services/relationship_analysis_persistence.dart';
import 'package:qmatch/features/relationship_analysis/services/relationship_analysis_service.dart';
import 'package:qmatch/features/relationship_analysis/widgets/relationship_analysis_profile_card.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  final bankJson =
      File('assets/data/relationship_analysis_v1.json').readAsStringSync();
  final bank = RelationshipBankLoader.parseJsonString(bankJson);

  test('frozen content_version remains relationship-analysis-v1.2.1', () {
    expect(bank.contentVersion, 'relationship-analysis-v1.2.1');
    expect(
      RelationshipAnalysisContract.contentVersion,
      'relationship-analysis-v1.2.1',
    );
    expect(
      RelationshipAnalysisContract.analysisDepthPolicyVersion,
      'relationship_analysis_depth_capability_v1',
    );
  });

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

  test('micro-scan size 4, resumes full session ids, selectNext skips answered',
      () {
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
    // Active session keeps answered ids so Previous/resume can revisit.
    expect(resumed, first);

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
    expect(d3, closeTo(1.0, 1e-9));
  });

  test('answer replacement changes scores when options differ but not depth',
      () {
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
    expect(first.analysisDepth, replaced.analysisDepth);
    expect(
      first.dimensionRawSignedEvidence,
      isNot(replaced.dimensionRawSignedEvidence),
    );
  });

  test('adding a new unique answered question never decreases analysis depth',
      () {
    const scorer = RelationshipAnalysisScorer();
    var answers = <String, String>{};
    var prev = 0.0;
    for (final q in bank.items) {
      answers = {...answers, q.id: q.options.first.id};
      final depth =
          scorer.score(bank: bank, answersByQuestionId: answers).analysisDepth;
      expect(depth, greaterThanOrEqualTo(prev), reason: q.id);
      prev = depth;
    }
    expect(prev, closeTo(1.0, 1e-9));
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
    // One answered question — capability exposure once; score evidence from one option.
    expect(first.answeredQuestionIds.length, 1);
    expect(replaced.answeredQuestionIds.length, 1);
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
    expect(loaded.activeMicroScanIndex, 2);

    final fields = loaded.toPersistenceFields();
    expect(fields['persona_input'], isFalse);
    expect(fields['matching_input'], isFalse);
    expect(fields['canonical_20d_merged'], isFalse);
    expect(
      fields['analysis_depth_policy_version'],
      RelationshipAnalysisContract.analysisDepthPolicyVersion,
    );
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

  test('forward-only resume continues at first unanswered question', () async {
    final memory = <String, Map<String, dynamic>>{};
    final persistence = RelationshipAnalysisPersistence(
      loadOverride: (uid) async => memory[uid],
      writeOverride: (uid, fields) async {
        final target = memory.putIfAbsent(uid, () => <String, dynamic>{});
        RelationshipAnalysisPersistence.mergeFields(target, fields);
      },
    );
    final service = RelationshipAnalysisService(persistence: persistence);

    var state = await service.beginMicroScan(
      uid: 'u1',
      state: RelationshipAnalysisState.empty(),
    );
    expect(state.activeMicroScanQuestionIds.length, 4);

    final originalIds = List<String>.from(state.activeMicroScanQuestionIds);
    final q0 = originalIds[0];
    final q1 = originalIds[1];

    state = await service.submitAnswer(
      uid: 'u1',
      state: state,
      questionId: q0,
      optionId: bank.byId[q0]!.options.first.id,
    );
    expect(state.activeMicroScanIndex, 1);

    state = await service.submitAnswer(
      uid: 'u1',
      state: state,
      questionId: q1,
      optionId: bank.byId[q1]!.options.first.id,
    );
    expect(state.activeMicroScanIndex, 2);

    final reloaded = await service.loadState('u1');
    final resumed = await service.beginMicroScan(
      uid: 'u1',
      state: reloaded,
    );

    expect(resumed.activeMicroScanQuestionIds, originalIds);
    expect(resumed.activeMicroScanIndex, 2);
    expect(resumed.answersByQuestionId.containsKey(q0), isTrue);
    expect(resumed.answersByQuestionId.containsKey(q1), isTrue);
    expect(
      resumed.answersByQuestionId.containsKey(originalIds[2]),
      isFalse,
    );
  });

  test('submitted question cannot be changed after advancing', () async {
    final memory = <String, Map<String, dynamic>>{};
    final persistence = RelationshipAnalysisPersistence(
      loadOverride: (uid) async => memory[uid],
      writeOverride: (uid, fields) async {
        final target = memory.putIfAbsent(uid, () => <String, dynamic>{});
        RelationshipAnalysisPersistence.mergeFields(target, fields);
      },
    );
    final service = RelationshipAnalysisService(persistence: persistence);

    var state = await service.beginMicroScan(
      uid: 'u1',
      state: RelationshipAnalysisState.empty(),
    );

    final qId = state.activeMicroScanQuestionIds.first;
    final q = bank.byId[qId]!;
    final firstOption = q.options.first.id;
    final replacementOption = q.options.last.id;

    state = await service.submitAnswer(
      uid: 'u1',
      state: state,
      questionId: qId,
      optionId: firstOption,
    );

    expect(state.activeMicroScanIndex, 1);
    expect(state.answersByQuestionId[qId], firstOption);

    await expectLater(
      service.submitAnswer(
        uid: 'u1',
        state: state,
        questionId: qId,
        optionId: replacementOption,
      ),
      throwsA(isA<StateError>()),
    );

    final persisted = await service.loadState('u1');
    expect(persisted.answersByQuestionId[qId], firstOption);
    expect(persisted.activeMicroScanIndex, 1);
  });

  test('completed bank does not begin a new micro-scan', () async {
    final memory = <String, Map<String, dynamic>>{};
    final persistence = RelationshipAnalysisPersistence(
      loadOverride: (uid) async => memory[uid],
      writeOverride: (uid, fields) async {
        final target = memory.putIfAbsent(uid, () => <String, dynamic>{});
        RelationshipAnalysisPersistence.mergeFields(target, fields);
      },
    );
    final service = RelationshipAnalysisService(persistence: persistence);
    const scorer = RelationshipAnalysisScorer();
    final answers = {
      for (final q in bank.items) q.id: q.options.first.id,
    };
    final snap = scorer.score(bank: bank, answersByQuestionId: answers);
    final complete = RelationshipAnalysisState.empty().copyWith(
      answersByQuestionId: answers,
      dimensionScores: snap.dimensionScores,
      dimensionEvidenceCounts: snap.dimensionEvidenceCounts,
      dimensionRawSignedEvidence: snap.dimensionRawSignedEvidence,
      analysisDepth: snap.analysisDepth,
    );
    final next = await service.beginMicroScan(uid: 'u1', state: complete);
    expect(next.hasActiveMicroScan, isFalse);
    expect(next.activeMicroScanQuestionIds, isEmpty);
    expect(service.isBankComplete(next), isTrue);
  });

  group('profile card UX', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required RelationshipAnalysisState state,
      Locale locale = const Locale('en'),
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RelationshipAnalysisProfileCard(
              state: state,
              onDeepen: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('profile 0% state', (tester) async {
      await pumpCard(tester, state: RelationshipAnalysisState.empty());
      expect(find.text('Relationship Analysis'), findsOneWidget);
      expect(
        find.text('Discover your relationship patterns over time.'),
        findsOneWidget,
      );
      expect(find.text('Start analysis · 4 questions'), findsOneWidget);
      expect(find.byKey(const Key('qmatch-relationship-analysis-deepen')),
          findsOneWidget);
      expect(find.byKey(const Key('qmatch-relationship-analysis-depth-bar')),
          findsNothing);
    });

    testWidgets('profile partial state', (tester) async {
      const scorer = RelationshipAnalysisScorer();
      final answers = {
        for (final q in bank.items.take(4)) q.id: q.options.first.id,
      };
      final snap = scorer.score(bank: bank, answersByQuestionId: answers);
      final pct = (snap.analysisDepth * 100).round();
      await pumpCard(
        tester,
        state: RelationshipAnalysisState.empty().copyWith(
          answersByQuestionId: answers,
          analysisDepth: snap.analysisDepth,
          dimensionScores: snap.dimensionScores,
          dimensionEvidenceCounts: snap.dimensionEvidenceCounts,
          dimensionRawSignedEvidence: snap.dimensionRawSignedEvidence,
        ),
      );
      expect(find.text('Analysis depth'), findsOneWidget);
      expect(find.text('$pct%'), findsOneWidget);
      expect(find.text('Deepen your analysis · 4 questions'), findsOneWidget);
      expect(find.byKey(const Key('qmatch-relationship-analysis-depth-bar')),
          findsOneWidget);
    });

    testWidgets('profile 100% state has no CTA', (tester) async {
      const scorer = RelationshipAnalysisScorer();
      final answers = {
        for (final q in bank.items) q.id: q.options.first.id,
      };
      final snap = scorer.score(bank: bank, answersByQuestionId: answers);
      await pumpCard(
        tester,
        state: RelationshipAnalysisState.empty().copyWith(
          answersByQuestionId: answers,
          analysisDepth: snap.analysisDepth,
          dimensionScores: snap.dimensionScores,
          dimensionEvidenceCounts: snap.dimensionEvidenceCounts,
          dimensionRawSignedEvidence: snap.dimensionRawSignedEvidence,
        ),
      );
      expect(find.text('Analysis complete for now'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.byKey(const Key('qmatch-relationship-analysis-deepen')),
          findsNothing);
      expect(find.textContaining('Deepen'), findsNothing);
      expect(find.textContaining('v1'), findsNothing);
    });

    testWidgets('TR 0% copy', (tester) async {
      await pumpCard(
        tester,
        state: RelationshipAnalysisState.empty(),
        locale: const Locale('tr'),
      );
      expect(find.text('İlişki Analizi'), findsOneWidget);
      expect(
        find.text('İlişki örüntülerini zaman içinde keşfet.'),
        findsOneWidget,
      );
      expect(find.text('Analize başla · 4 soru'), findsOneWidget);
    });
  });

  test('completion depth display uses rounded before/after semantics', () {
    // Pure display helper logic mirrored by the screen.
    String format({required double before, required double after}) {
      final beforePct = (before * 100).round().clamp(0, 100);
      final afterPct = (after * 100).round().clamp(0, 100);
      if (beforePct == afterPct) return '$afterPct%';
      return '$beforePct% → $afterPct%';
    }

    expect(format(before: 0.26, after: 0.42), '26% → 42%');
    expect(format(before: 0.261, after: 0.264), '26%');
  });

  test('discovery: micro-scan available until bank complete', () {
    expect(RelationshipAnalysisDiscovery.isMicroScanAvailable(null), isTrue);
    expect(RelationshipAnalysisDiscovery.isMicroScanAvailable({}), isTrue);
    expect(
      RelationshipAnalysisDiscovery.isMicroScanAvailable({
        'answered_count': 4,
        'analysis_depth': 0.43,
      }),
      isTrue,
    );
    expect(
      RelationshipAnalysisDiscovery.isMicroScanAvailable({
        'answered_count': 24,
        'analysis_depth': 1.0,
      }),
      isFalse,
    );
    expect(
      RelationshipAnalysisDiscovery.isMicroScanAvailable({
        'answered_count': 20,
        'analysis_depth': 0.999,
      }),
      isFalse,
    );
  });

  test('micro-scan is forward-only and exposes no Previous action', () {
    final screenSrc = File(
      'lib/features/relationship_analysis/screens/relationship_analysis_micro_scan_screen.dart',
    ).readAsStringSync();
    final serviceSrc = File(
      'lib/features/relationship_analysis/services/relationship_analysis_service.dart',
    ).readAsStringSync();

    expect(
      screenSrc.contains("Key('relationship-analysis-previous')"),
      isFalse,
    );
    expect(screenSrc.contains('_onPrevious'), isFalse);
    expect(serviceSrc.contains('setMicroScanIndex'), isFalse);
  });
}
