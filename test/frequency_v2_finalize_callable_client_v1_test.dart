import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/services/frequency_v2_finalize_callable_client.dart';

void main() {
  group('FrequencyV2FinalizeCallableClient', () {
    test('invokes finalizeFrequencyV2 in europe-west1', () async {
      String? calledName;
      final client = FrequencyV2FinalizeCallableClient(
        call: (name, data) async {
          calledName = name;
          return {
            'ok': true,
            'assessment_type': 'frequency_v2',
            'status': 'completed',
            'session_id': data['session_id'],
            'idempotent': false,
          };
        },
      );
      final result = await client.finalize({'session_id': 'frequency_v2_sess_1'});
      expect(calledName, 'finalizeFrequencyV2');
      expect(FrequencyV2FinalizeCallableClient.region, 'europe-west1');
      expect(FrequencyV2FinalizeCallableClient.callableName, 'finalizeFrequencyV2');
      expect(result.status, 'completed');
      expect(result.idempotent, isFalse);
    });

    test('classifies auth, validation, and session-conflict errors', () {
      expect(
        FrequencyV2FinalizeCallableClient.classifyFunctionsError(
          code: 'unauthenticated',
        ).kind,
        FrequencyV2FinalizeFailureKind.retryable,
      );
      expect(
        FrequencyV2FinalizeCallableClient.classifyFunctionsError(
          code: 'invalid-argument',
        ).kind,
        FrequencyV2FinalizeFailureKind.nonRetryableSession,
      );
      expect(
        FrequencyV2FinalizeCallableClient.classifyFunctionsError(
          code: 'failed-precondition',
          details: {'code': 'FREQUENCY_V2_ALREADY_FINALIZED'},
        ).kind,
        FrequencyV2FinalizeFailureKind.sessionConflict,
      );
    });

    test('binds europe-west1 via instanceFor', () {
      final src = File(
        'lib/features/assessment/services/frequency_v2_finalize_callable_client.dart',
      ).readAsStringSync();
      expect(src.contains('FirebaseFunctions.instanceFor(region: region)'), isTrue);
      expect(src.contains("callableName = 'finalizeFrequencyV2'"), isTrue);
      expect(src.contains("region = 'europe-west1'"), isTrue);
    });

    test('FirebaseFunctionsException invalid-argument is non-retryable', () async {
      final client = FrequencyV2FinalizeCallableClient(
        call: (_, __) async {
          throw FirebaseFunctionsException(
            code: 'invalid-argument',
            message: 'bad',
          );
        },
      );
      try {
        await client.finalize(const {});
        fail('expected exception');
      } on FrequencyV2FinalizeException catch (e) {
        expect(e.kind, FrequencyV2FinalizeFailureKind.nonRetryableSession);
      }
    });
  });
}
