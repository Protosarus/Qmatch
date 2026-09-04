import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_session_controller.dart';

import 'support/frequency_v2_runtime_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'V2 controller exposes question, 4 options, TR/EN bank, and 1..50 progress',
      () async {
    final bank = await FrequencyV2RuntimeTestHarness.loadTr();
    final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
      bank: bank,
      uid: 'ui-owner',
      seed: 'ui-seed',
    );
    final inProgress = pending.session.copyWith(
      status: FrequencyV2PersistedSessionStatus.inProgress,
      answers: const [],
      currentQuestionIndex: 0,
      remoteFinalized: false,
    );
    await pending.repo.saveSession(inProgress);
    final controller = FrequencyV2SessionController(
      bank: bank,
      manager: pending.manager,
    );
    await controller.start(ownerUid: 'ui-owner', sessionSeed: 'ui-seed');
    final plan = controller.currentPlan!;
    final labels = [
      for (final id in plan.presentedOptionOrder) controller.optionText(id)!,
    ];
    expect(labels, hasLength(4));
    expect(labels.every((t) => t.trim().isNotEmpty), isTrue);
    expect(controller.currentItem!.prompt.trim(), isNotEmpty);
    expect(controller.progressIndex, 1);
    expect(controller.progressTotal, 50);
    expect(controller.bank.locale, 'tr-TR');
  });

  test('V2 UI reuses Frequency presentation widgets', () {
    final src = File(
      'lib/features/assessment/screens/frequency_v2_test_screen.dart',
    ).readAsStringSync();
    expect(src.contains('FrequencyQuestionPanel'), isTrue);
    expect(src.contains('QMATCH_FREQUENCY_V2_INTERNAL'), isFalse);
    expect(src.contains('Directory.current'), isFalse);
    expect(src.contains('FrequencyProgressHeader'), isTrue);
    expect(src.contains('QAssessmentProgress'), isTrue);
    expect(src.toLowerCase().contains('true personality'), isFalse);
    expect(src.toLowerCase().contains('lie detection'), isFalse);
    expect(src.toLowerCase().contains('clinical diagnosis'), isFalse);
  });
}
