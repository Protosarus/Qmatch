import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/navigation/assessment_progress_route_gate.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_runtime_test_screen_factory.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/screens/frequency_test_screen.dart';
import 'package:qmatch/features/assessment/screens/frequency_v2_test_screen.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';
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

Future<FrequencyV2SessionController> _startController({
  required FrequencyV2LoadedBank bank,
  String uid = 'ux-owner',
  String seed = 'ux-seed',
}) async {
  final repo = FrequencyV2SessionMemoryRepository();
  final manager = FrequencyV2SessionManager(
    bank: bank,
    repository: repo,
    idFactory: FrequencyV2SessionIdFactory(random: Random(11)),
  );
  final controller = FrequencyV2SessionController(
    bank: bank,
    manager: manager,
  );
  await controller.start(ownerUid: uid, sessionSeed: seed);
  return controller;
}

Widget _app(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
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

  test('shared factory maps tracks and keeps release default on V1', () {
    expect(
      FrequencyRuntimeTestScreenFactory.build(track: FrequencyRuntimeTrack.v1),
      isA<FrequencyTestScreen>(),
    );
    expect(
      FrequencyRuntimeTestScreenFactory.build(track: FrequencyRuntimeTrack.v2),
      isA<FrequencyV2TestScreen>(),
    );
    expect(
      FrequencyRuntimeTestScreenFactory.build(debugInternalV2Override: false),
      isA<FrequencyTestScreen>(),
    );
    expect(
      FrequencyRuntimeTestScreenFactory.build(debugInternalV2Override: true),
      isA<FrequencyV2TestScreen>(),
    );
    expect(
      FrequencyRuntimeSelectionPolicy.resolve(debugInternalV2Override: false),
      FrequencyRuntimeTrack.v1,
    );
    expect(
      FrequencyRuntimeTestScreenFactory.build(),
      isA<FrequencyTestScreen>(),
    );
  });

  test('intro, route gate, and debug home use the shared factory', () {
    final intro = File(
      'lib/features/assessment/screens/frequency_intro_screen.dart',
    ).readAsStringSync();
    final gate = File(
      'lib/core/navigation/assessment_progress_route_gate.dart',
    ).readAsStringSync();
    final debug = File(
      'lib/features/debug/debug_home_screen.dart',
    ).readAsStringSync();
    for (final src in [intro, gate, debug]) {
      expect(src.contains('FrequencyRuntimeTestScreenFactory.build()'), isTrue);
      expect(src.contains('QMATCH_FREQUENCY_V2_INTERNAL'), isFalse);
    }
    expect(intro.contains('const FrequencyTestScreen()'), isFalse);
    expect(intro.contains('const FrequencyV2TestScreen()'), isFalse);
    expect(gate.contains('const FrequencyTestScreen()'), isFalse);
    expect(debug.contains('const FrequencyTestScreen()'), isFalse);

    final gateTest = buildAssessmentDestination(
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.frequency,
        openAssessmentTestScreen: true,
        reason: 'frequency_v2_pending_finalization',
      ),
    );
    expect(
      gateTest.runtimeType,
      FrequencyRuntimeTestScreenFactory.build().runtimeType,
    );
  });

  test('run_qmatch.sh prints V1/V2 runtime banners without enabling V2', () {
    final src = File('tool/run_qmatch.sh').readAsStringSync();
    expect(src.contains('QMatch runtime: INTERNAL FREQUENCY V2'), isTrue);
    expect(src.contains('QMatch runtime: DEFAULT FREQUENCY V1'), isTrue);
    expect(src.contains('QMATCH_FREQUENCY_V2_INTERNAL=true'), isTrue);
    expect(src.contains('secrets.local.json'), isTrue);
    expect(
      src.contains('QMATCH_FREQUENCY_V2_INTERNAL=true') &&
          src.contains('v2_internal=true'),
      isTrue,
    );
  });

  testWidgets('FrequencyQuestionPanel fourth option is tappable',
      (tester) async {
    int? selected;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SizedBox(
            height: 420,
            child: FrequencyQuestionPanel(
              eyebrow: 'Frequency',
              question: 'Long prompt that wraps on a small device height?',
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
    await tester.tap(find.byKey(const Key('frequency-answer-option-3')));
    await tester.pump();
    expect(selected, 4);
  });

  testWidgets('V2 option tap shows selected state, holds, then advances once',
      (tester) async {
    // Asset-bundle load deadlocks in testWidgets fake-async before the first pump.
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

    expect(find.textContaining('tr-TR'), findsNothing);
    expect(find.text('1 / 50'), findsOneWidget);

    final fourth = find.byKey(const Key('frequency-answer-option-3'));
    await tester.ensureVisible(fourth);
    await tester.tap(fourth);
    await tester.pump();
    expect(find.text('1 / 50'), findsOneWidget);
    final held = tester.widget<FrequencyAnswerOptionRow>(
      find.byKey(const Key('frequency-answer-option-3')),
    );
    expect(held.selected, isTrue);
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
    expect(controller.progressIndex, 2);
    expect(find.text('2 / 50'), findsOneWidget);
    expect(find.textContaining('tr-TR'), findsNothing);
  });

  testWidgets('successful dormant V2 completion has a working exit action',
      (tester) async {
    final bank = (await tester.runAsync(FrequencyV2RuntimeTestHarness.loadTr))!;
    final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
      bank: bank,
      uid: 'ux-owner',
      seed: 'ux-complete',
    );
    final controller = FrequencyV2SessionController(
      bank: bank,
      manager: pending.manager,
    );
    controller.session = pending.session;
    var continued = 0;
    final pipeline = FrequencyV2PendingFinalizationPipeline.live(
      manager: pending.manager,
      currentUid: () => 'ux-owner',
      finalizeClient: FrequencyV2FinalizeCallableClient(
        call: (_, __) async => _ok(),
      ),
    );

    await tester.pumpWidget(
      _app(
        FrequencyV2TestScreen(
          controller: controller,
          pendingPipeline: pipeline,
          onInternalContinue: () => continued += 1,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(FrequencyV2TestScreen.internalCompletionTitle),
        findsOneWidget);
    expect(
        find.byKey(FrequencyV2TestScreen.internalContinueKey), findsOneWidget);
    await tester.tap(find.byKey(FrequencyV2TestScreen.internalContinueKey));
    await tester.pump();
    expect(continued, 1);
    expect(
      File('lib/features/assessment/screens/frequency_v2_test_screen.dart')
          .readAsStringSync()
          .contains('NotificationRegistrationHost'),
      isTrue,
    );
  });
}
