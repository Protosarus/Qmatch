import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'package:qmatch/features/assessment/services/frequency_v2_finalize_callable_client.dart';
import 'package:qmatch/features/assessment/services/frequency_v2_pending_finalization_pipeline.dart';

import 'support/frequency_v2_runtime_test_helpers.dart';

FrequencyV2PendingFinalizationPipeline _pipeline({
  required FrequencyV2SessionManager manager,
  required FrequencyV2FinalizeCallableClient client,
}) {
  return FrequencyV2PendingFinalizationPipeline(
    finalizeClient: client,
    markRemoteFinalized: ({required ownerUid, required sessionId}) =>
        manager.markRemoteFinalized(ownerUid: ownerUid, sessionId: sessionId),
    currentUid: () => 'owner-p',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FrequencyV2PendingFinalizationPipeline', () {
    test('success: finalize then local remote-finalized mark', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'owner-p',
        seed: 'pipe-ok',
      );
      final pipeline = _pipeline(
        manager: pending.manager,
        client: FrequencyV2FinalizeCallableClient(
          call: (name, data) async {
            expect(name, 'finalizeFrequencyV2');
            expect(data.containsKey('canonical_v1'), isFalse);
            expect(data.containsKey('frequency_completed'), isFalse);
            return {
              'ok': true,
              'assessment_type': 'frequency_v2',
              'status': 'completed',
              'idempotent': false,
            };
          },
        ),
      );
      final result = await pipeline.run(session: pending.session);
      expect(
        result.destination,
        FrequencyV2PendingPipelineDestination.dormantCompletion,
      );
      expect(result.completedSteps, [
        FrequencyV2PendingPipelineStep.finalizeFrequencyV2,
        FrequencyV2PendingPipelineStep.markRemoteFinalized,
      ]);
      expect(result.session!.remoteFinalized, isTrue);
    });

    test('auth failure retains local pending', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'owner-p',
        seed: 'pipe-auth',
      );
      final pipeline = _pipeline(
        manager: pending.manager,
        client: FrequencyV2FinalizeCallableClient(
          call: (_, __) async {
            throw FirebaseFunctionsException(
              code: 'unauthenticated',
              message: 'auth',
            );
          },
        ),
      );
      final result = await pipeline.run(session: pending.session);
      expect(result.destination,
          FrequencyV2PendingPipelineDestination.stayOnSession);
      expect(result.failureKind, FrequencyV2FinalizeFailureKind.retryable);
      final still =
          await pending.repo.loadSession('owner-p', pending.session.sessionId);
      expect(
        still.state!.status,
        FrequencyV2PersistedSessionStatus.completedPendingPersistence,
      );
      expect(still.state!.remoteFinalized, isFalse);
    });

    test('validation failure retains local pending', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'owner-p',
        seed: 'pipe-val',
      );
      final pipeline = _pipeline(
        manager: pending.manager,
        client: FrequencyV2FinalizeCallableClient(
          call: (_, __) async {
            throw FirebaseFunctionsException(
              code: 'invalid-argument',
              message: 'bad',
            );
          },
        ),
      );
      final result = await pipeline.run(session: pending.session);
      expect(result.failureKind,
          FrequencyV2FinalizeFailureKind.nonRetryableSession);
      expect(
        (await pending.repo.loadSession('owner-p', pending.session.sessionId))
            .state!
            .remoteFinalized,
        isFalse,
      );
    });

    test('network retry retains local pending', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'owner-p',
        seed: 'pipe-net',
      );
      final pipeline = _pipeline(
        manager: pending.manager,
        client: FrequencyV2FinalizeCallableClient(
          call: (_, __) async => throw const SocketException('down'),
        ),
      );
      final result = await pipeline.run(session: pending.session);
      expect(result.failureKind, FrequencyV2FinalizeFailureKind.retryable);
      expect(result.completedSteps, isEmpty);
    });

    test('idempotent success still marks local remote-finalized', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'owner-p',
        seed: 'pipe-idem',
      );
      final pipeline = _pipeline(
        manager: pending.manager,
        client: FrequencyV2FinalizeCallableClient(
          call: (_, __) async => {
            'ok': true,
            'assessment_type': 'frequency_v2',
            'status': 'completed',
            'idempotent': true,
          },
        ),
      );
      final result = await pipeline.run(session: pending.session);
      expect(result.finalize!.idempotent, isTrue);
      expect(result.session!.remoteFinalized, isTrue);
    });

    test('session conflict retains local pending', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
        bank: bank,
        uid: 'owner-p',
        seed: 'pipe-conflict',
      );
      final pipeline = _pipeline(
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
      final result = await pipeline.run(session: pending.session);
      expect(
          result.failureKind, FrequencyV2FinalizeFailureKind.sessionConflict);
      expect(
        (await pending.repo.loadSession('owner-p', pending.session.sessionId))
            .state!
            .status,
        FrequencyV2PersistedSessionStatus.completedPendingPersistence,
      );
    });

    test('pipeline source does not write V1 or Discover fields', () {
      final src = File(
        'lib/features/assessment/services/frequency_v2_pending_finalization_pipeline.dart',
      ).readAsStringSync();
      expect(src.contains('upsertCanonical'), isFalse);
      expect(src.contains("assessmentType: 'frequency'"), isFalse);
      expect(src.contains("'frequency_completed'"), isFalse);
      expect(src.contains("'test_completed'"), isFalse);
      expect(src.contains("'discover_eligible'"), isFalse);
      expect(src.contains("'assessment_verification_v1'"), isFalse);
      expect(src.contains('persistCanonical'), isFalse);
      expect(
          src.contains('FrequencyV2PendingFinalizationPipeline.live'), isTrue);
      expect(src.contains('FrequencyV2FinalizeCallableClient()'), isTrue);
    });
  });
}
