import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_screen_finalize_coordinator.dart';
import 'package:qmatch/features/assessment/screens/frequency_v2_test_screen.dart';
import 'package:qmatch/features/assessment/services/frequency_v2_finalize_callable_client.dart';
import 'package:qmatch/features/assessment/services/frequency_v2_pending_finalization_pipeline.dart';

import 'support/frequency_v2_runtime_test_helpers.dart';

Map<String, dynamic> _ok({bool idempotent = false}) => {
      'ok': true,
      'assessment_type': 'frequency_v2',
      'status': 'completed',
      'idempotent': idempotent,
    };

FrequencyV2PendingFinalizationPipeline _pipe({
  required FrequencyV2SessionManager manager,
  required FrequencyV2FinalizeCallableClient client,
}) {
  return FrequencyV2PendingFinalizationPipeline.live(
    manager: manager,
    finalizeClient: client,
    currentUid: () => 'wire-owner',
  );
}

Future<FrequencyV2SessionController> _startController({
  required FrequencyV2LoadedBank bank,
  String uid = 'wire-owner',
  String seed = 'wire-seed',
}) async {
  final repo = FrequencyV2SessionMemoryRepository();
  final manager = FrequencyV2SessionManager(
    bank: bank,
    repository: repo,
    idFactory: FrequencyV2SessionIdFactory(random: Random(3)),
  );
  final controller = FrequencyV2SessionController(
    bank: bank,
    manager: manager,
  );
  await controller.start(ownerUid: uid, sessionSeed: seed);
  return controller;
}

Future<void> _answerRemaining(FrequencyV2SessionController controller) async {
  while (controller.session!.answersByItemId.length < 50) {
    final plan = controller.currentPlan!;
    await controller.selectOption(plan.presentedOptionOrder.first);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Frequency V2 screen finalize wiring', () {
    test('50th answer locks session and pipeline is invoked once', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final controller = await _startController(bank: bank);
      var calls = 0;
      final coordinator = FrequencyV2ScreenFinalizeCoordinator(
        pipeline: _pipe(
          manager: controller.manager,
          client: FrequencyV2FinalizeCallableClient(
            call: (name, data) async {
              calls += 1;
              expect(name, 'finalizeFrequencyV2');
              expect(data.containsKey('canonical_v1'), isFalse);
              expect(data.containsKey('frequency_completed'), isFalse);
              expect(data.containsKey('discover_eligible'), isFalse);
              return _ok();
            },
          ),
        ),
      );
      await _answerRemaining(controller);
      expect(controller.session!.answersByItemId, hasLength(50));
      await controller.lockIfComplete();
      expect(
        controller.session!.status,
        FrequencyV2PersistedSessionStatus.completedPendingPersistence,
      );
      final result = await coordinator.runIfPending(controller.session);
      expect(calls, 1);
      expect(
        result!.destination,
        FrequencyV2PendingPipelineDestination.dormantCompletion,
      );
      expect(result.session!.remoteFinalized, isTrue);
    });

    test('pipeline success marks local remote_finalized for dormant completion',
        () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'wire-owner',
        seed: 'wire-success',
      );
      final coordinator = FrequencyV2ScreenFinalizeCoordinator(
        pipeline: _pipe(
          manager: pending.manager,
          client: FrequencyV2FinalizeCallableClient(
            call: (_, __) async => _ok(),
          ),
        ),
      );
      final result = await coordinator.runIfPending(pending.session);
      expect(
        result!.destination,
        FrequencyV2PendingPipelineDestination.dormantCompletion,
      );
      expect(result.session!.remoteFinalized, isTrue);
      expect(
        result.session!.status,
        FrequencyV2PersistedSessionStatus.completed,
      );
      expect(
        FrequencyV2TestScreen.internalCompletionTitle,
        'Frequency V2 internal test completed',
      );
    });

    test('same-session idempotent success is dormant completion', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'wire-owner',
        seed: 'wire-idem',
      );
      final coordinator = FrequencyV2ScreenFinalizeCoordinator(
        pipeline: _pipe(
          manager: pending.manager,
          client: FrequencyV2FinalizeCallableClient(
            call: (_, __) async => _ok(idempotent: true),
          ),
        ),
      );
      final result = await coordinator.runIfPending(pending.session);
      expect(result!.finalize!.idempotent, isTrue);
      expect(
        result.destination,
        FrequencyV2PendingPipelineDestination.dormantCompletion,
      );
      expect(result.session!.remoteFinalized, isTrue);
    });

    test('network failure preserves pending and allows retry', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'wire-owner',
        seed: 'wire-net',
      );
      var calls = 0;
      final coordinator = FrequencyV2ScreenFinalizeCoordinator(
        pipeline: _pipe(
          manager: pending.manager,
          client: FrequencyV2FinalizeCallableClient(
            call: (_, __) async {
              calls += 1;
              if (calls == 1) throw const SocketException('down');
              return _ok();
            },
          ),
        ),
      );
      final failed = await coordinator.runIfPending(pending.session);
      expect(failed!.destination,
          FrequencyV2PendingPipelineDestination.stayOnSession);
      expect(failed.failureKind, FrequencyV2FinalizeFailureKind.retryable);
      final still = await pending.repo.loadSession(
        'wire-owner',
        pending.session.sessionId,
      );
      expect(
        still.state!.status,
        FrequencyV2PersistedSessionStatus.completedPendingPersistence,
      );
      expect(still.state!.remoteFinalized, isFalse);
      expect(still.state!.answers, hasLength(50));
      final retry = await coordinator.runIfPending(still.state);
      expect(
        retry!.destination,
        FrequencyV2PendingPipelineDestination.dormantCompletion,
      );
      expect(calls, 2);
    });

    test('bootstrap completedPendingPersistence schedules one automatic retry',
        () async {
      final coordinator = FrequencyV2ScreenFinalizeCoordinator(
        pipeline: FrequencyV2PendingFinalizationPipeline(
          finalizeClient: FrequencyV2FinalizeCallableClient(
            call: (_, __) async => _ok(),
          ),
          markRemoteFinalized: ({required ownerUid, required sessionId}) async {
            return const FrequencyV2SessionWriteResult(ok: true);
          },
        ),
      );
      expect(coordinator.tryClaimBootstrapRetry(), isTrue);
      expect(coordinator.tryClaimBootstrapRetry(), isFalse);
      expect(coordinator.didAutoRetryPending, isTrue);
    });

    test('rebuild does not duplicate bootstrap retry claim', () {
      final coordinator = FrequencyV2ScreenFinalizeCoordinator(
        pipeline: FrequencyV2PendingFinalizationPipeline(
          finalizeClient: FrequencyV2FinalizeCallableClient(
            call: (_, __) async => _ok(),
          ),
          markRemoteFinalized: ({required ownerUid, required sessionId}) async {
            return const FrequencyV2SessionWriteResult(ok: true);
          },
        ),
      );
      expect(coordinator.tryClaimBootstrapRetry(), isTrue);
      expect(coordinator.tryClaimBootstrapRetry(), isFalse);
      expect(coordinator.tryClaimBootstrapRetry(), isFalse);
    });

    test('rapid final tap does not create concurrent finalize calls', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'wire-owner',
        seed: 'wire-race',
      );
      var calls = 0;
      final started = Completer<void>();
      final hold = Completer<void>();
      final coordinator = FrequencyV2ScreenFinalizeCoordinator(
        pipeline: _pipe(
          manager: pending.manager,
          client: FrequencyV2FinalizeCallableClient(
            call: (_, __) async {
              calls += 1;
              if (!started.isCompleted) started.complete();
              await hold.future;
              return _ok();
            },
          ),
        ),
      );
      final first = coordinator.runIfPending(pending.session);
      await started.future;
      expect(coordinator.pipelineInFlight, isTrue);
      final second = await coordinator.runIfPending(pending.session);
      expect(second, isNull);
      hold.complete();
      final result = await first;
      expect(calls, 1);
      expect(
        result!.destination,
        FrequencyV2PendingPipelineDestination.dormantCompletion,
      );
    });

    test('different-session already-finalized is not treated as success',
        () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'wire-owner',
        seed: 'wire-conflict',
      );
      final coordinator = FrequencyV2ScreenFinalizeCoordinator(
        pipeline: _pipe(
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
        ),
      );
      final result = await coordinator.runIfPending(pending.session);
      expect(
          result!.failureKind, FrequencyV2FinalizeFailureKind.sessionConflict);
      expect(
        result.destination,
        FrequencyV2PendingPipelineDestination.stayOnSession,
      );
      expect(result.uiErrorCode, 'FREQUENCY_V2_ALREADY_FINALIZED');
      final still = await pending.repo.loadSession(
        'wire-owner',
        pending.session.sessionId,
      );
      expect(
        still.state!.status,
        FrequencyV2PersistedSessionStatus.completedPendingPersistence,
      );
      expect(still.state!.remoteFinalized, isFalse);
    });

    test('release/default routing remains V1 and intro uses centralized policy',
        () {
      expect(
        FrequencyRuntimeSelectionPolicy.resolve(
          debugInternalV2Override: false,
        ),
        FrequencyRuntimeTrack.v1,
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
      expect(
          intro.contains('FrequencyRuntimeSelectionPolicy.resolve()'), isTrue);
      expect(intro.contains('QMATCH_FREQUENCY_V2_INTERNAL'), isFalse);
      expect(intro.contains('FrequencyTestScreen'), isTrue);
      expect(intro.contains('FrequencyV2TestScreen'), isTrue);
    });

    test('debug internal routing reaches wired V2 screen', () {
      expect(
        FrequencyRuntimeSelectionPolicy.resolve(
          isRuntimeSelectable: (_) => false,
          debugInternalV2Override: true,
        ),
        FrequencyRuntimeTrack.v2,
      );
      final src = File(
        'lib/features/assessment/screens/frequency_v2_test_screen.dart',
      ).readAsStringSync();
      expect(src.contains('FrequencyV2PendingFinalizationPipeline'), isTrue);
      expect(src.contains('.live('), isTrue);
      expect(src.contains('_runPendingFinalizationPipeline'), isTrue);
      expect(src.contains('tryClaimBootstrapRetry'), isTrue);
      expect(
        src.contains(FrequencyV2TestScreen.internalCompletionTitle),
        isTrue,
      );
      expect(src.contains('PersonaAssignmentGateScreen'), isFalse);
    });

    test('wired client path does not write server authority fields', () {
      final screen = File(
        'lib/features/assessment/screens/frequency_v2_test_screen.dart',
      ).readAsStringSync();
      final pipeline = File(
        'lib/features/assessment/services/frequency_v2_pending_finalization_pipeline.dart',
      ).readAsStringSync();
      final coordinator = File(
        'lib/features/assessment/domain/frequency_v2_runtime/frequency_v2_screen_finalize_coordinator.dart',
      ).readAsStringSync();
      for (final src in [screen, pipeline, coordinator]) {
        expect(src.contains('FirebaseFirestore'), isFalse);
        expect(src.contains('upsertCanonical'), isFalse);
        expect(src.contains('upsertCompletedAssessment'), isFalse);
        expect(src.contains("'frequency_completed'"), isFalse);
        expect(src.contains("'test_completed'"), isFalse);
        expect(src.contains("'assessment_flow_completed'"), isFalse);
        expect(src.contains("'discover_eligible'"), isFalse);
        expect(src.contains("'assessment_verification_v1'"), isFalse);
      }
      expect(screen.contains('canonical_v1'), isFalse);
      expect(coordinator.contains('canonical_v1'), isFalse);
      expect(pipeline.contains('finalizeFrequencyV2'), isTrue);
      expect(pipeline.contains('markRemoteFinalized'), isTrue);
      expect(
        File(
          'lib/features/assessment/services/assessment_cold_start_pending_reconciler.dart',
        ).readAsStringSync().contains('FrequencyV2PendingFinalizationPipeline'),
        isFalse,
      );
    });
  });
}
