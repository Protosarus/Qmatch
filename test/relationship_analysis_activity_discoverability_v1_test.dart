import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/navigation/main_navigation_screen.dart';
import 'package:qmatch/features/activity/models/activity_event_model.dart';
import 'package:qmatch/features/activity/screens/activity_screen.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_analysis_state.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_bank_loader.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_dimensions.dart';
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

  late DateTime fakeNow;

  RelationshipAnalysisPersistence memoryPersistence(
    Map<String, Map<String, dynamic>> memory,
  ) {
    return RelationshipAnalysisPersistence(
      loadOverride: (uid) async => memory[uid],
      writeOverride: (uid, fields) async {
        final target = memory.putIfAbsent(uid, () => <String, dynamic>{});
        RelationshipAnalysisPersistence.mergeFields(target, fields);
      },
    );
  }

  RelationshipAnalysisService serviceFor(
    Map<String, Map<String, dynamic>> memory,
  ) {
    return RelationshipAnalysisService(
      persistence: memoryPersistence(memory),
      clock: () => fakeNow,
    );
  }

  setUp(() {
    fakeNow = DateTime.utc(2026, 8, 24, 12);
  });

  group('Activity proactive eligibility', () {
    test('1. first RA prompt eligible when incomplete', () {
      final prompt = RelationshipAnalysisDiscovery.evaluateActivityPrompt(
        state: RelationshipAnalysisState.empty(),
        now: fakeNow,
      );
      expect(prompt.kind, RelationshipActivityPromptKind.start);
      expect(prompt.showCard, isTrue);
      expect(prompt.showBadge, isTrue);
    });

    test('3. unfinished micro-scan remains resumable (ignores cooldown)', () {
      final state = RelationshipAnalysisState.empty().copyWith(
        activeMicroScanId: 'ra_1',
        activeMicroScanQuestionIds: const [
          'ra_v1_01_busy_workday',
          'ra_v1_02_weekend_morning',
          'ra_v1_03_hobby_evening',
          'ra_v1_04_short_notice_trip',
        ],
        activeMicroScanIndex: 1,
        answersByQuestionId: const {
          'ra_v1_01_busy_workday': 'opt_a',
        },
        proactiveNudgeSuppressUntil: fakeNow.add(const Duration(hours: 20)),
      );
      final prompt = RelationshipAnalysisDiscovery.evaluateActivityPrompt(
        state: state,
        now: fakeNow,
      );
      expect(prompt.kind, RelationshipActivityPromptKind.resume);
      expect(prompt.showBadge, isTrue);
    });

    test('4/5/6. completed batch starts 24h cooldown; card+badge hidden',
        () async {
      final memory = <String, Map<String, dynamic>>{};
      final service = serviceFor(memory);

      var state = await service.beginMicroScan(
        uid: 'u1',
        state: RelationshipAnalysisState.empty(),
      );
      for (final qid in state.activeMicroScanQuestionIds) {
        state = await service.submitAnswer(
          uid: 'u1',
          state: state,
          questionId: qid,
          optionId: bank.byId[qid]!.options.first.id,
        );
      }

      expect(state.hasActiveMicroScan, isFalse);
      expect(state.answeredCount, 4);
      expect(state.proactiveNudgeSuppressUntil, isNotNull);
      expect(
        state.proactiveNudgeSuppressUntil,
        fakeNow.add(RelationshipAnalysisContract.proactiveNudgeCooldown),
      );

      final during = RelationshipAnalysisDiscovery.evaluateActivityPrompt(
        state: state,
        now: fakeNow.add(const Duration(hours: 1)),
      );
      expect(during.kind, RelationshipActivityPromptKind.none);
      expect(during.showCard, isFalse);
      expect(during.showBadge, isFalse);
    });

    test('7. next Activity prompt eligible after cooldown', () async {
      final memory = <String, Map<String, dynamic>>{};
      final service = serviceFor(memory);
      var state = await service.beginMicroScan(
        uid: 'u1',
        state: RelationshipAnalysisState.empty(),
      );
      for (final qid in state.activeMicroScanQuestionIds) {
        state = await service.submitAnswer(
          uid: 'u1',
          state: state,
          questionId: qid,
          optionId: bank.byId[qid]!.options.first.id,
        );
      }

      final after = RelationshipAnalysisDiscovery.evaluateActivityPrompt(
        state: state,
        now: fakeNow.add(const Duration(hours: 24, minutes: 1)),
      );
      expect(after.kind, RelationshipActivityPromptKind.start);
      expect(after.showBadge, isTrue);
    });

    test('8. Profile CTA remains available during Activity cooldown', () {
      final state = RelationshipAnalysisState.empty().copyWith(
        answersByQuestionId: {
          for (final q in bank.items.take(4)) q.id: q.options.first.id,
        },
        analysisDepth: 0.4,
        proactiveNudgeSuppressUntil: fakeNow.add(const Duration(hours: 24)),
      );
      expect(
          RelationshipAnalysisDiscovery.isProfileCtaAvailable(state), isTrue);

      final activity = RelationshipAnalysisDiscovery.evaluateActivityPrompt(
        state: state,
        now: fakeNow,
      );
      expect(activity.showCard, isFalse);
    });

    test('9. completing another batch from Profile resets nudge cooldown',
        () async {
      final memory = <String, Map<String, dynamic>>{};
      final service = serviceFor(memory);

      var state = await service.beginMicroScan(
        uid: 'u1',
        state: RelationshipAnalysisState.empty(),
      );
      for (final qid in List<String>.from(state.activeMicroScanQuestionIds)) {
        state = await service.submitAnswer(
          uid: 'u1',
          state: state,
          questionId: qid,
          optionId: bank.byId[qid]!.options.first.id,
        );
      }
      final firstSuppress = state.proactiveNudgeSuppressUntil!;

      fakeNow = fakeNow.add(const Duration(hours: 3));
      state = await service.beginMicroScan(uid: 'u1', state: state);
      for (final qid in List<String>.from(state.activeMicroScanQuestionIds)) {
        state = await service.submitAnswer(
          uid: 'u1',
          state: state,
          questionId: qid,
          optionId: bank.byId[qid]!.options.first.id,
        );
      }

      expect(state.proactiveNudgeSuppressUntil!.isAfter(firstSuppress), isTrue);
      expect(
        state.proactiveNudgeSuppressUntil,
        fakeNow.add(RelationshipAnalysisContract.proactiveNudgeCooldown),
      );
      final stillCool = RelationshipAnalysisDiscovery.evaluateActivityPrompt(
        state: state,
        now: fakeNow.add(const Duration(hours: 1)),
      );
      expect(stillCool.showCard, isFalse);
    });

    test('10/11. 24/24 removes Activity card and badge', () {
      const scorer = RelationshipAnalysisScorer();
      final answers = {
        for (final q in bank.items) q.id: q.options.first.id,
      };
      final snap = scorer.score(bank: bank, answersByQuestionId: answers);
      final state = RelationshipAnalysisState.empty().copyWith(
        answersByQuestionId: answers,
        analysisDepth: snap.analysisDepth,
        dimensionScores: snap.dimensionScores,
        dimensionEvidenceCounts: snap.dimensionEvidenceCounts,
        dimensionRawSignedEvidence: snap.dimensionRawSignedEvidence,
      );
      final prompt = RelationshipAnalysisDiscovery.evaluateActivityPrompt(
        state: state,
        now: fakeNow,
      );
      expect(prompt.kind, RelationshipActivityPromptKind.none);
      expect(prompt.showCard, isFalse);
      expect(prompt.showBadge, isFalse);
    });

    test('13. Activity derived card does not write fake feed events', () async {
      final memory = <String, Map<String, dynamic>>{};
      final activityWrites = <Map<String, dynamic>>[];
      final persistence = RelationshipAnalysisPersistence(
        loadOverride: (uid) async => memory[uid],
        writeOverride: (uid, fields) async {
          // Capture assessment writes only — Activity feed is never touched here.
          expect(fields.containsKey('type'), isFalse);
          expect(fields.containsKey('actor_uid'), isFalse);
          final target = memory.putIfAbsent(uid, () => <String, dynamic>{});
          RelationshipAnalysisPersistence.mergeFields(target, fields);
        },
      );
      final service = RelationshipAnalysisService(
        persistence: persistence,
        clock: () => fakeNow,
      );
      var state = await service.beginMicroScan(
        uid: 'u1',
        state: RelationshipAnalysisState.empty(),
      );
      for (final qid in state.activeMicroScanQuestionIds) {
        state = await service.submitAnswer(
          uid: 'u1',
          state: state,
          questionId: qid,
          optionId: bank.byId[qid]!.options.first.id,
        );
      }
      expect(activityWrites, isEmpty);
      expect(memory['u1']?['proactive_nudge_suppress_until'], isNotNull);
      expect(memory['u1']?.containsKey('activity_feed'), isFalse);
    });

    test('14. no Relationship field enters Discover/matching/Persona/20D', () {
      final fields = RelationshipAnalysisState.empty().toPersistenceFields();
      expect(fields['matching_input'], isFalse);
      expect(fields['persona_input'], isFalse);
      expect(fields['canonical_20d_merged'], isFalse);
      expect(fields.containsKey('primary_persona_id'), isFalse);
      expect(fields.containsKey('raw_delta_d'), isFalse);
      expect(fields.containsKey('compatibility_score'), isFalse);
    });
  });

  group('Activity / Profile UI', () {
    testWidgets('2. tapping Activity CTA opens/resumes micro-scan',
        (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ActivityScreen(
            activityStream: Stream.value(const <ActivityEventModel>[]),
            relationshipPromptStream: Stream.value(
              const RelationshipActivityPrompt(
                RelationshipActivityPromptKind.start,
              ),
            ),
            onOpenRelationshipAnalysis: () => opened++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('qmatch-relationship-analysis-activity-card')),
        findsOneWidget,
      );
      expect(find.text('Deepen your relationship analysis'), findsOneWidget);
      expect(
          find.text('4 new questions are ready · about 1 min'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('qmatch-relationship-analysis-activity-cta')),
      );
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('resume copy on Activity card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ActivityScreen(
            activityStream: Stream.value(const <ActivityEventModel>[]),
            relationshipPromptStream: Stream.value(
              const RelationshipActivityPrompt(
                RelationshipActivityPromptKind.resume,
              ),
            ),
            onOpenRelationshipAnalysis: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue your relationship analysis'), findsOneWidget);
      expect(find.text('Pick up where you left off.'), findsOneWidget);
    });

    testWidgets('5. Activity card hidden during cooldown prompt=none',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ActivityScreen(
            activityStream: Stream.value(const <ActivityEventModel>[]),
            relationshipPromptStream: Stream.value(
              const RelationshipActivityPrompt(
                RelationshipActivityPromptKind.none,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('qmatch-relationship-analysis-activity-card')),
        findsNothing,
      );
      expect(find.byKey(const Key('activity-empty-state')), findsOneWidget);
    });

    testWidgets('6. Activity badge hidden during cooldown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainNavigationScreen(
            screens: const [
              SizedBox(),
              SizedBox(),
              SizedBox(),
              SizedBox(),
            ],
            threadsStream: Stream.value(const []),
            currentUid: 'u1',
            relationshipActivityBadgeStream: Stream.value(false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('qmatch-nav-dot-badge-1')), findsNothing);
      expect(find.byKey(const Key('qmatch-nav-dot-badge-3')), findsNothing);
    });

    testWidgets('Activity badge on Activity tab when eligible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainNavigationScreen(
            screens: const [
              SizedBox(),
              SizedBox(),
              SizedBox(),
              SizedBox(),
            ],
            threadsStream: Stream.value(const []),
            currentUid: 'u1',
            relationshipActivityBadgeStream: Stream.value(true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('qmatch-nav-dot-badge-1')), findsOneWidget);
      expect(find.byKey(const Key('qmatch-nav-dot-badge-3')), findsNothing);
    });

    testWidgets('8/12. Profile CTA during cooldown; gone at 24/24',
        (tester) async {
      const scorer = RelationshipAnalysisScorer();
      final partialAnswers = {
        for (final q in bank.items.take(4)) q.id: q.options.first.id,
      };
      final partialSnap =
          scorer.score(bank: bank, answersByQuestionId: partialAnswers);
      final partial = RelationshipAnalysisState.empty().copyWith(
        answersByQuestionId: partialAnswers,
        analysisDepth: partialSnap.analysisDepth,
        dimensionScores: partialSnap.dimensionScores,
        dimensionEvidenceCounts: partialSnap.dimensionEvidenceCounts,
        dimensionRawSignedEvidence: partialSnap.dimensionRawSignedEvidence,
        proactiveNudgeSuppressUntil: fakeNow.add(const Duration(hours: 24)),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RelationshipAnalysisProfileCard(
              state: partial,
              onDeepen: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('qmatch-relationship-analysis-deepen')),
        findsOneWidget,
      );

      final fullAnswers = {
        for (final q in bank.items) q.id: q.options.first.id,
      };
      final fullSnap =
          scorer.score(bank: bank, answersByQuestionId: fullAnswers);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RelationshipAnalysisProfileCard(
              state: RelationshipAnalysisState.empty().copyWith(
                answersByQuestionId: fullAnswers,
                analysisDepth: fullSnap.analysisDepth,
                dimensionScores: fullSnap.dimensionScores,
                dimensionEvidenceCounts: fullSnap.dimensionEvidenceCounts,
                dimensionRawSignedEvidence: fullSnap.dimensionRawSignedEvidence,
              ),
              onDeepen: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('qmatch-relationship-analysis-deepen')),
        findsNothing,
      );
    });
  });
}
