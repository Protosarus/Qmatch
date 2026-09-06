import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/navigation/assessment_progress_route_gate.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_runtime_test_screen_factory.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_runtime_result_policy.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/screens/frequency_intro_screen.dart';
import 'package:qmatch/features/assessment/screens/frequency_v2_test_screen.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import 'package:qmatch/features/assessment/services/assessment_progress_service.dart';
import 'package:qmatch/features/assessment/services/frequency_v2_finalize_callable_client.dart';
import 'package:qmatch/features/assessment/services/frequency_v2_pending_finalization_pipeline.dart';
import 'package:qmatch/features/assessment/widgets/frequency_question_chrome.dart';
import 'package:qmatch/l10n/app_localizations.dart';

import 'support/frequency_v2_runtime_test_helpers.dart';

Map<String, dynamic> _ok() => {
      'ok': true,
      'assessment_type': 'frequency_v2',
      'status': 'completed',
      'idempotent': false,
    };

Map<String, dynamic> _validFrequencyV2() {
  return {
    'schema_version': FrequencyV2ResultAuthority.resultSchemaVersion,
    'assessment_type': FrequencyV2ResultAuthority.assessmentType,
    'status': FrequencyV2ResultAuthority.resultStatus,
    'source': FrequencyV2ResultAuthority.resultSource,
    'dimensions': [
      for (final id in FrequencyBehaviorV2Contract.canonicalDimensions)
        {
          'dimension_id': id,
          'normalized_behavior': 0.1,
          'provisional_confidence': 1,
          'confidence_completeness': 1,
        },
    ],
  };
}

Map<String, dynamic> _validPersona() {
  return {
    'primary_persona_id': 'kararli',
    'secondary_persona_id': 'empat',
    'raw_delta_d': 0.18,
    'scoring_version': PersonaRuntimeResultPolicy.scoringVersion,
    'config_version': PersonaRuntimeResultPolicy.configVersion,
    'policy_version': PersonaRuntimeResultPolicy.policyVersion,
    'prototype_version': PersonaRuntimeResultPolicy.prototypeVersion,
  };
}

Future<FrequencyV2SessionController> _startController({
  required FrequencyV2LoadedBank bank,
  String uid = 'ux11-owner',
  String seed = 'ux11-seed',
}) async {
  final repo = FrequencyV2SessionMemoryRepository();
  final manager = FrequencyV2SessionManager(
    bank: bank,
    repository: repo,
    idFactory: FrequencyV2SessionIdFactory(random: Random(17)),
  );
  final controller = FrequencyV2SessionController(
    bank: bank,
    manager: manager,
  );
  await controller.start(ownerUid: uid, sessionSeed: seed);
  return controller;
}

FrequencyV2PendingFinalizationPipeline _pipe({
  required FrequencyV2SessionManager manager,
  required FrequencyV2FinalizeCallableClient client,
  String uid = 'ux11-owner',
}) {
  return FrequencyV2PendingFinalizationPipeline.live(
    manager: manager,
    finalizeClient: client,
    currentUid: () => uid,
  );
}

Widget _app(Widget home, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('A/B live route uses FrequencyV2TestScreen, not V1', () {
    expect(
      FrequencyRuntimeTestScreenFactory.build(),
      isA<FrequencyV2TestScreen>(),
    );
    final pending = buildAssessmentDestination(
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.frequency,
        openAssessmentTestScreen: true,
        reason: 'frequency_v2_pending_finalization',
      ),
    );
    expect(pending, isA<FrequencyV2TestScreen>());
    final intro = buildAssessmentDestination(
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.frequency,
        openAssessmentTestScreen: false,
        reason: 'progress_routing',
      ),
    );
    expect(intro, isA<FrequencyIntroScreen>());
    expect(FrequencyRuntimeTrack.values, [FrequencyRuntimeTrack.v2]);

    final liveRoots = [
      'lib/core/navigation/assessment_progress_route_gate.dart',
      'lib/features/assessment/screens/frequency_intro_screen.dart',
      'lib/features/assessment/screens/eq_test_screen.dart',
      'lib/features/assessment/domain/frequency_v2_runtime/frequency_runtime_test_screen_factory.dart',
    ];
    for (final path in liveRoots) {
      final src = File(path).readAsStringSync();
      expect(src.contains('FrequencyTestScreen('), isFalse, reason: path);
      expect(src.contains('const FrequencyTestScreen'), isFalse, reason: path);
    }
  });

  testWidgets('C loading does not show blank question 1 / 50', (tester) async {
    final bank = (await tester.runAsync(FrequencyV2RuntimeTestHarness.loadTr))!;
    final repo = FrequencyV2SessionMemoryRepository();
    final manager = FrequencyV2SessionManager(
      bank: bank,
      repository: repo,
      idFactory: FrequencyV2SessionIdFactory(random: Random(2)),
    );
    final controller = FrequencyV2SessionController(
      bank: bank,
      manager: manager,
    );

    await tester
        .pumpWidget(_app(FrequencyV2TestScreen(controller: controller)));
    await tester.pump();

    expect(find.byKey(const Key('frequency-v2-loading')), findsOneWidget);
    expect(find.text('1 / 50'), findsNothing);
    expect(find.byKey(const Key('frequency-v2-question-panel')), findsNothing);
    expect(find.textContaining('owner_unavailable'), findsNothing);
  });

  testWidgets('D TR instruction/start copy is V2-safe', (tester) async {
    await tester.pumpWidget(
      _app(const FrequencyIntroScreen(), locale: const Locale('tr')),
    );
    await tester.pump();

    expect(find.byKey(const Key('frequency-v2-intro')), findsOneWidget);
    expect(
      find.text(
          'Bu sorular gündelik davranış eğilimlerini anlamaya yöneliktir. Doğru veya yanlış cevap yoktur.'),
      findsOneWidget,
    );
    expect(find.text('Kendine en yakın seçeneği seç'), findsOneWidget);
    expect(find.text('Yaklaşık 50 soru'), findsOneWidget);
    expect(find.text('İlk doğal cevabını tercih et'), findsOneWidget);
    expect(find.text('Frekans Testine Başla'), findsOneWidget);
    expect(find.textContaining('Yönergeyi okudum'), findsNothing);
    expect(find.textContaining('bilinçaltı'), findsNothing);
    expect(find.textContaining('klinik'), findsNothing);
  });

  testWidgets('E EN instruction/start copy matches TR semantics',
      (tester) async {
    await tester.pumpWidget(_app(const FrequencyIntroScreen()));
    await tester.pump();

    expect(
      find.text(
          'These questions look at everyday behavior tendencies. There are no right or wrong answers.'),
      findsOneWidget,
    );
    expect(find.text('Choose the option closest to you'), findsOneWidget);
    expect(find.text('About 50 questions'), findsOneWidget);
    expect(find.text('Go with your first natural answer'), findsOneWidget);
    expect(find.text('Start Frequency Test'), findsOneWidget);
    expect(find.textContaining('subconscious'), findsNothing);
    expect(find.textContaining('lie detection'), findsNothing);
    expect(find.textContaining('true personality'), findsNothing);
    expect(find.textContaining('clinical'), findsNothing);
  });

  for (final locale in const [Locale('tr'), Locale('en')]) {
    testWidgets(
        'F/G long ${locale.languageCode} question wraps without overflow',
        (tester) async {
      final errors = <FlutterErrorDetails>[];
      final old = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = old);

      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final question = locale.languageCode == 'tr'
          ? 'Kalabalık bir akşam yemeğinde kendini nasıl konumlandırırsın ve odadaki ritme nasıl katılırsın, özellikle herkes aynı anda konuşurken ve senden hızlı bir tepki beklendiğinde?'
          : 'In a crowded dinner where everyone talks at once and a quick reaction is expected of you, how do you usually place yourself and join the rhythm of the room?';
      final labels = locale.languageCode == 'tr'
          ? const [
              'Önce dinler, sonra kısa ve net konuşurum',
              'Hemen araya girer, konuşmayı yönlendiririm',
              'Sessiz kalır, gözlemlerim',
              'Şakayla ortamı yumuşatmaya çalışırım',
            ]
          : const [
              'I listen first, then speak briefly and clearly',
              'I jump in and steer the conversation',
              'I stay quiet and observe',
              'I try to soften the room with humor',
            ];

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SizedBox(
              height: 520,
              child: FrequencyQuestionPanel(
                eyebrow: locale.languageCode == 'tr' ? 'Frekans' : 'Frequency',
                question: question,
                labels: labels,
                selectedValue: null,
                compact: true,
                onSelected: (_) {},
              ),
            ),
          ),
          locale: locale,
        ),
      );
      await tester.pump();

      expect(
        errors.any((error) => error.toString().contains('overflowed')),
        isFalse,
      );
      expect(find.text(question), findsOneWidget);
      expect(
          find.byKey(const Key('frequency-answer-option-3')), findsOneWidget);
    });
  }

  testWidgets('H all options stay reachable on a small iPhone viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    int? selected;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SizedBox(
            height: 420,
            child: FrequencyQuestionPanel(
              compact: true,
              eyebrow: 'Frequency',
              question: 'Which everyday reaction is closest to you?',
              labels: const [
                'First option text',
                'Second option text',
                'Third option text',
                'Fourth option must receive this tap',
              ],
              selectedValue: null,
              onSelected: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    final fourth = find.byKey(const Key('frequency-answer-option-3'));
    await tester.ensureVisible(fourth);
    await tester.tap(fourth);
    await tester.pump();
    expect(selected, 4);
  });

  testWidgets('I/J/K selected hold, no double-answer, progress advances',
      (tester) async {
    final bank = (await tester.runAsync(FrequencyV2RuntimeTestHarness.loadTr))!;
    final controller = await _startController(bank: bank);
    final firstPlan = controller.currentPlan!;
    final fourthId = firstPlan.presentedOptionOrder[3];

    await tester.pumpWidget(
      _app(
        FrequencyV2TestScreen(
          controller: controller,
          selectionHold: FrequencyV2TestScreen.selectionHoldDuration,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('1 / 50'), findsOneWidget);

    await tester.tap(find.byKey(const Key('frequency-answer-option-3')));
    await tester.pump();
    expect(
      tester
          .widget<FrequencyAnswerOptionRow>(
            find.byKey(const Key('frequency-answer-option-3')),
          )
          .selected,
      isTrue,
    );
    expect(controller.session!.answersByItemId, isEmpty);

    await tester.tap(find.byKey(const Key('frequency-answer-option-0')));
    await tester.pump();
    expect(controller.session!.answersByItemId, isEmpty);

    await tester.pump(FrequencyV2TestScreen.selectionHoldDuration);
    await tester.pump();
    expect(controller.session!.answersByItemId, hasLength(1));
    expect(
      controller.session!.answersByItemId[firstPlan.itemId]!.selectedOptionId,
      fourthId,
    );
    expect(find.text('2 / 50'), findsOneWidget);
  });

  testWidgets('L/M last answer shows finishing and locks controls',
      (tester) async {
    final bank = (await tester.runAsync(FrequencyV2RuntimeTestHarness.loadTr))!;
    final controller = await _startController(bank: bank, seed: 'ux11-last');
    await tester.runAsync(() async {
      while (controller.session!.answersByItemId.length < 49) {
        await controller.selectOption(
          controller.currentPlan!.presentedOptionOrder.first,
        );
      }
    });
    final hold = Completer<void>();
    final pipeline = _pipe(
      manager: controller.manager,
      client: FrequencyV2FinalizeCallableClient(
        call: (_, __) async {
          await hold.future;
          return _ok();
        },
      ),
    );

    await tester.pumpWidget(
      _app(
        FrequencyV2TestScreen(
          controller: controller,
          pendingPipeline: pipeline,
          selectionHold: Duration.zero,
          onProductContinue: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('50 / 50'), findsOneWidget);

    await tester.tap(find.byKey(const Key('frequency-answer-option-0')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('frequency-v2-finishing')), findsOneWidget);
    expect(find.text('Preparing your results…'), findsOneWidget);
    expect(find.byKey(const Key('frequency-v2-question-panel')), findsNothing);
    expect(find.text('Retry finalize'), findsNothing);
    hold.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
  });

  test('N/O/V/W V2 UI source has no raw errors, V1 writes, or SnackBars', () {
    final screen = File(
      'lib/features/assessment/screens/frequency_v2_test_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('error.toString()'), isFalse);
    expect(screen.contains('Retry finalize'), isFalse);
    expect(screen.contains("eyebrow: 'Frequency'"), isFalse);
    expect(screen.contains('SnackBar('), isFalse);
    expect(screen.contains('ScaffoldMessenger'), isFalse);
    expect(screen.contains('canonical_v1'), isFalse);
    expect(screen.contains('FrequencyRuntimeTrack.v1'), isFalse);
    expect(screen.contains('FrequencyTestScreen'), isFalse);
    expect(screen.contains('QMATCH_FREQUENCY_V2_INTERNAL'), isFalse);

    final intro = File(
      'lib/features/assessment/screens/frequency_intro_screen.dart',
    ).readAsStringSync();
    expect(intro.contains('FrequencyTestScreen'), isFalse);
    expect(intro.contains('Yönergeyi okudum'), isFalse);
    expect(intro.contains('FrequencyRuntimeTestScreenFactory.build()'), isTrue);
  });

  testWidgets(
      'P/Q retryable finalize failure stays pending and retries same session',
      (tester) async {
    final bank = (await tester.runAsync(FrequencyV2RuntimeTestHarness.loadTr))!;
    final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
      bank: bank,
      uid: 'ux11-owner',
      seed: 'ux11-retry',
    );
    final sessionId = pending.session.sessionId;
    var calls = 0;
    String? seenSession;
    final pipeline = _pipe(
      manager: pending.manager,
      client: FrequencyV2FinalizeCallableClient(
        call: (_, data) async {
          calls += 1;
          seenSession = data['session_id'] as String?;
          if (calls == 1) throw const SocketException('down');
          return _ok();
        },
      ),
    );
    final controller = FrequencyV2SessionController(
      bank: bank,
      manager: pending.manager,
    );
    controller.session = pending.session;
    var continued = 0;

    await tester.pumpWidget(
      _app(
        FrequencyV2TestScreen(
          controller: controller,
          pendingPipeline: pipeline,
          onProductContinue: () => continued += 1,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.byKey(const Key('frequency-v2-save-error')), findsOneWidget);
    expect(
      find.textContaining("Couldn't save your results. Check your connection"),
      findsOneWidget,
    );
    expect(find.textContaining('unavailable'), findsNothing);
    expect(find.textContaining('finalize_failed'), findsNothing);
    expect(find.text('Retry finalize'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      controller.session!.status,
      FrequencyV2PersistedSessionStatus.completedPendingPersistence,
    );
    expect(controller.session!.answersByItemId, hasLength(50));
    expect(controller.session!.sessionId, sessionId);
    expect(seenSession, sessionId);
    expect(continued, 0);

    await tester.tap(find.byKey(const Key('frequency-v2-retry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(calls, 2);
    expect(seenSession, sessionId);
    expect(continued, 1);
  });

  testWidgets('R already-finalized proceeds as completion, not an error',
      (tester) async {
    final bank = (await tester.runAsync(FrequencyV2RuntimeTestHarness.loadTr))!;
    final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
      bank: bank,
      uid: 'ux11-owner',
      seed: 'ux11-done',
    );
    final controller = FrequencyV2SessionController(
      bank: bank,
      manager: pending.manager,
    );
    controller.session = pending.session;
    var continued = 0;
    final pipeline = _pipe(
      manager: pending.manager,
      client: FrequencyV2FinalizeCallableClient(
        call: (_, __) async {
          throw FirebaseFunctionsException(
            code: 'failed-precondition',
            message: 'conflict',
            details: {'code': 'FREQUENCY_V2_ALREADY_FINALIZED'},
          );
        },
      ),
    );

    await tester.pumpWidget(
      _app(
        FrequencyV2TestScreen(
          controller: controller,
          pendingPipeline: pipeline,
          onProductContinue: () => continued += 1,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(continued, 1);
    expect(find.text('FREQUENCY_V2_ALREADY_FINALIZED'), findsNothing);
    expect(find.byKey(const Key('frequency-v2-save-error')), findsNothing);
  });

  testWidgets('S resume of pending finalization shows finishing, not Q50',
      (tester) async {
    final bank = (await tester.runAsync(FrequencyV2RuntimeTestHarness.loadTr))!;
    final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
      bank: bank,
      uid: 'ux11-owner',
      seed: 'ux11-resume',
    );
    final controller = FrequencyV2SessionController(
      bank: bank,
      manager: pending.manager,
    );
    controller.session = pending.session;
    final hold = Completer<void>();
    final pipeline = _pipe(
      manager: pending.manager,
      client: FrequencyV2FinalizeCallableClient(
        call: (_, __) async {
          await hold.future;
          return _ok();
        },
      ),
    );

    await tester.pumpWidget(
      _app(
        FrequencyV2TestScreen(
          controller: controller,
          pendingPipeline: pipeline,
          onProductContinue: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('frequency-v2-finishing')), findsOneWidget);
    expect(find.byKey(const Key('frequency-v2-question-panel')), findsNothing);
    expect(find.text('Retry finalize'), findsNothing);
    hold.complete();
    await tester.pump();
  });

  test('T/U authoritative V2 does not reopen; missing Persona routes Persona',
      () {
    final v2 = _validFrequencyV2();
    final afterV2 = AssessmentProgressService.resolveFromMaps(
      userDoc: {
        'assessment_flow_version': 2,
        'iq_completed': true,
        'eq_completed': true,
      },
      iqAssessment: {'status': 'completed'},
      eqAssessment: {'status': 'completed'},
      frequencyV2Assessment: v2,
    );
    expect(afterV2.frequencyCompleted, isTrue);
    expect(afterV2.destination, AssessmentFlowDestination.persona);
    expect(afterV2.destination, isNot(AssessmentFlowDestination.frequency));

    final withPersona = AssessmentProgressService.resolveFromMaps(
      userDoc: {
        'assessment_flow_version': 2,
        'iq_completed': true,
        'eq_completed': true,
        'profile_completed': true,
      },
      iqAssessment: {'status': 'completed'},
      eqAssessment: {'status': 'completed'},
      frequencyV2Assessment: v2,
      personaAssessment: _validPersona(),
    );
    expect(withPersona.destination, AssessmentFlowDestination.main);
  });

  testWidgets('unsigned load shows account recovery, not a raw code',
      (tester) async {
    await tester.pumpWidget(_app(const FrequencyV2TestScreen()));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('frequency-v2-load-error')), findsOneWidget);
    expect(find.textContaining('owner_unavailable'), findsNothing);
    expect(find.textContaining('FirebaseException'), findsNothing);
    expect(find.text('1 / 50'), findsNothing);
    expect(
      find.text("The test couldn't be loaded right now. Please try again."),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
