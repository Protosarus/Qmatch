import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';

class _ThrowIfReadV2Repo implements FrequencyV2SessionPersistenceRepository {
  @override
  Future<void> saveSession(FrequencyV2PersistedSessionState state) async {}

  @override
  Future<FrequencyV2SessionLoadResult> loadActiveSession(String ownerUid) {
    throw StateError('V2 session store must not be read while track is V1');
  }

  @override
  Future<FrequencyV2SessionLoadResult> loadSession(
    String ownerUid,
    String sessionId,
  ) {
    throw StateError('V2 session store must not be read while track is V1');
  }

  @override
  Future<void> deleteSession(String ownerUid, String sessionId) async {}
}

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
  test('runtime selection is V1 while V2 banks are not selectable', () {
    expect(
      FrequencyBehaviorV2BankRegistry.isRuntimeSelectable(
        FrequencyBehaviorV2Contract.poolVersionTrDraft1,
      ),
      isFalse,
    );
    expect(
      FrequencyBehaviorV2BankRegistry.isRuntimeSelectable(
        FrequencyBehaviorV2Contract.poolVersionEnDraft1,
      ),
      isFalse,
    );
    expect(FrequencyRuntimeSelectionPolicy.resolve(), FrequencyRuntimeTrack.v1);
    expect(
      FrequencyRuntimeSelectionPolicy.resolve(
        isRuntimeSelectable: (_) => true,
      ),
      FrequencyRuntimeTrack.v2,
    );
    expect(
      FrequencyRuntimeSelectionPolicy.resolve(
        debugInternalV2Override: false,
      ),
      FrequencyRuntimeTrack.v1,
    );
    expect(
      FrequencyRuntimeSelectionPolicy.resolve(
        debugInternalV2Override: true,
      ),
      FrequencyRuntimeTrack.v2,
    );
    expect(
      FrequencyRuntimeSelectionPolicy.resolve(
        isRuntimeSelectable: (_) => false,
        debugInternalV2Override: true,
      ),
      FrequencyRuntimeTrack.v2,
    );
  });

  test('V2 cold-start branch is unreachable while track is V1', () {
    final ignored = AssessmentColdStartPendingReconciler.decide(
      iqPendingFinalization: false,
      eqPendingFinalization: false,
      frequencyPendingFinalization: false,
      frequencyV2PendingFinalization: true,
      runtimeTrack: FrequencyRuntimeTrack.v1,
      progressDestination: AssessmentFlowDestination.main,
    );
    expect(ignored.reason, 'progress_routing');
    expect(ignored.destination, AssessmentFlowDestination.main);

    final liveV1 = AssessmentColdStartPendingReconciler.decide(
      iqPendingFinalization: false,
      eqPendingFinalization: false,
      frequencyPendingFinalization: true,
      frequencyV2PendingFinalization: true,
      runtimeTrack: FrequencyRuntimeTrack.v1,
      progressDestination: AssessmentFlowDestination.main,
    );
    expect(liveV1.reason, 'frequency_pending_finalization');

    final v2 = AssessmentColdStartPendingReconciler.decide(
      iqPendingFinalization: false,
      eqPendingFinalization: false,
      frequencyPendingFinalization: false,
      frequencyV2PendingFinalization: true,
      runtimeTrack: FrequencyRuntimeTrack.v2,
      progressDestination: AssessmentFlowDestination.main,
    );
    expect(v2.reason, 'frequency_v2_pending_finalization');
  });

  test('V1 reconcile does not consult the V2 session repository', () async {
    final decision = await AssessmentColdStartPendingReconciler(
      iqRepository: IqSessionMemoryRepository(),
      eqRepository: EqSessionMemoryRepository(),
      frequencyRepository: FrequencySessionMemoryRepository(),
      frequencyV2Repository: _ThrowIfReadV2Repo(),
    ).reconcile(
      uid: 'uid_v1_live',
      progress: _progress(AssessmentFlowDestination.frequency),
    );
    expect(decision.reason, 'progress_routing');
    expect(decision.destination, AssessmentFlowDestination.frequency);
    expect(decision.openAssessmentTestScreen, isFalse);
  });

  test('V2 pools are bundled as dormant assets; release track stays V1', () {
    final pubspec =
        File('${Directory.current.path}/pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('tool/frequency_behavior_v2/out/'), isFalse);
    expect(
      pubspec.contains(
        'assets/assessment/frequency_v2/frequency_behavior_pool_tr_v2_draft1.json',
      ),
      isTrue,
    );
    expect(
      pubspec.contains(
        'assets/assessment/frequency_v2/frequency_behavior_pool_en_v2_draft1.json',
      ),
      isTrue,
    );
    expect(
      pubspec.contains(
        'assets/assessment/frequency_v2/frequency_behavior_pool_tr_v2_draft1_review_metadata.json',
      ),
      isTrue,
    );
    expect(
      pubspec.contains(
        'assets/assessment/frequency_v2/frequency_behavior_pool_en_v2_draft1_review_metadata.json',
      ),
      isTrue,
    );
    expect(
      FrequencyBehaviorV2BankRegistry.isRuntimeSelectable(
        FrequencyBehaviorV2Contract.poolVersionTrDraft1,
      ),
      isFalse,
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
    expect(policy.contains('QMATCH_FREQUENCY_V2_INTERNAL'), isTrue);
    expect(policy.contains('kDebugMode && _internalV2FromDefine'), isTrue);

    final ranking = File(
      'lib/features/discover/services/discover_structural_l2_ranking.dart',
    ).readAsStringSync();
    expect(ranking.contains("modeWireValue = 'structural_l2_v1'"), isTrue);
  });
}
