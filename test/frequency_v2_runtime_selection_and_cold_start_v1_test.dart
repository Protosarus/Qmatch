import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';

AssessmentProgressSnapshot _progress(AssessmentFlowDestination destination) {
  return AssessmentProgressSnapshot(
    assessmentFlowVersion: AssessmentProgressSnapshot.flowVersionV2,
    iqStatus: AssessmentModuleStatus.completed,
    eqStatus: AssessmentModuleStatus.completed,
    frequencyStatus: AssessmentModuleStatus.notStarted,
    frequencyCompleted: false,
    frequencyIncomplete: false,
    iqCompleted: true,
    eqCompleted: true,
    allAssessmentsCompleted: false,
    assessmentFlowCompleted: false,
    canonicalPersonaAvailable: false,
    profileCompleted: false,
    destination: destination,
    resolutionSource: 'test',
    reason: null,
  );
}

void main() {
  test('runtime selection is always Frequency V2', () {
    expect(FrequencyRuntimeSelectionPolicy.resolve(), FrequencyRuntimeTrack.v2);
    expect(
      FrequencyRuntimeSelectionPolicy.resolve(
        isRuntimeSelectable: (_) => false,
      ),
      FrequencyRuntimeTrack.v2,
    );
    expect(
      FrequencyRuntimeSelectionPolicy.resolve(
        debugInternalV2Override: false,
      ),
      FrequencyRuntimeTrack.v2,
    );
    expect(FrequencyRuntimeSelectionPolicy.isV2RuntimeSelectable, isTrue);
  });

  test('cold start pending V2 resumes V2; leftover V1 pending is ignored', () {
    final v2 = AssessmentColdStartPendingReconciler.decide(
      iqPendingFinalization: false,
      eqPendingFinalization: false,
      frequencyPendingFinalization: false,
      frequencyV2PendingFinalization: true,
      runtimeTrack: FrequencyRuntimeTrack.v2,
      progressDestination: AssessmentFlowDestination.main,
    );
    expect(v2.reason, 'frequency_v2_pending_finalization');
    expect(v2.openAssessmentTestScreen, isTrue);
    expect(v2.destination, AssessmentFlowDestination.frequency);

    final leftoverV1 = AssessmentColdStartPendingReconciler.decide(
      iqPendingFinalization: false,
      eqPendingFinalization: false,
      frequencyPendingFinalization: true,
      frequencyV2PendingFinalization: false,
      runtimeTrack: FrequencyRuntimeTrack.v2,
      progressDestination: AssessmentFlowDestination.frequency,
    );
    expect(leftoverV1.reason, 'progress_routing');
    expect(leftoverV1.openAssessmentTestScreen, isFalse);
  });

  test('V2 reconcile consults the V2 session repository', () async {
    final decision = await AssessmentColdStartPendingReconciler(
      iqRepository: IqSessionMemoryRepository(),
      eqRepository: EqSessionMemoryRepository(),
      frequencyRepository: FrequencySessionMemoryRepository(),
      frequencyV2Repository: FrequencyV2SessionMemoryRepository(),
    ).reconcile(
      uid: 'uid_v2_live',
      progress: _progress(AssessmentFlowDestination.frequency),
    );
    expect(decision.reason, 'progress_routing');
    expect(decision.destination, AssessmentFlowDestination.frequency);
    expect(decision.openAssessmentTestScreen, isFalse);
  });

  test('V2 pools stay bundled; live ranking is fusion', () {
    final pubspec =
        File('${Directory.current.path}/pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('tool/frequency_behavior_v2/out/'), isFalse);
    expect(
      pubspec.contains(
        'assets/assessment/frequency_v2/frequency_behavior_pool_tr_v2_draft1.json',
      ),
      isTrue,
    );

    final intro = File(
      'lib/features/assessment/screens/frequency_intro_screen.dart',
    ).readAsStringSync();
    expect(intro.contains('QMATCH_FREQUENCY_V2_INTERNAL'), isFalse);
    expect(
      intro.contains('FrequencyRuntimeTestScreenFactory.build()'),
      isTrue,
    );

    final policy = File(
      'lib/features/assessment/domain/frequency_v2_runtime/frequency_runtime_selection_policy.dart',
    ).readAsStringSync();
    expect(policy.contains('QMATCH_FREQUENCY_V2_INTERNAL'), isFalse);

    final ranking = File(
      'lib/features/discover/services/discover_structural_l2_ranking.dart',
    ).readAsStringSync();
    expect(
      ranking.contains("modeWireValue = 'compatibility_fusion_v2'"),
      isTrue,
    );
  });
}
