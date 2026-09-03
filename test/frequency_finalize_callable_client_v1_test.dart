import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/services/frequency_finalize_callable_client.dart';

void main() {
  group('FrequencyFinalizeCallableClient', () {
    test('invokes finalizeFrequency in europe-west1 and returns verified result',
        () async {
      String? calledName;
      Map<String, dynamic>? calledData;
      final client = FrequencyFinalizeCallableClient(
        call: (name, data) async {
          calledName = name;
          calledData = data;
          return {
            'ok': true,
            'assessment_type': 'frequency',
            'status': 'verified',
            'flow': 'frequency',
            'idempotent': false,
          };
        },
      );

      final result = await client.finalize({
        'schema_version': 'assessment_finalize_session_v1',
        'session_id': 'freq_sess_abc',
      });

      expect(calledName, 'finalizeFrequency');
      expect(calledName, FrequencyFinalizeCallableClient.callableName);
      expect(FrequencyFinalizeCallableClient.callableName, 'finalizeFrequency');
      expect(FrequencyFinalizeCallableClient.region, 'europe-west1');
      expect(calledData!['session_id'], 'freq_sess_abc');
      expect(result.status, 'verified');
      expect(result.flow, 'frequency');
      expect(result.idempotent, isFalse);
    });

    test('idempotent true is preserved', () async {
      final client = FrequencyFinalizeCallableClient(
        call: (_, __) async => {
          'ok': true,
          'status': 'verified',
          'flow': 'frequency',
          'idempotent': true,
        },
      );
      final result = await client.finalize(const {});
      expect(result.idempotent, isTrue);
    });

    test('non-verified payload is not local success', () async {
      final client = FrequencyFinalizeCallableClient(
        call: (_, __) async => {
          'ok': false,
          'status': 'rejected',
          'flow': 'frequency',
        },
      );
      try {
        await client.finalize(const {});
        fail('expected FrequencyFinalizeException');
      } on FrequencyFinalizeException catch (e) {
        expect(e.kind, FrequencyFinalizeFailureKind.retryable);
        expect(e.code, 'internal');
      }
    });

    test('binds europe-west1 via instanceFor and never uses default instance',
        () {
      final src = File(
        'lib/features/assessment/services/frequency_finalize_callable_client.dart',
      ).readAsStringSync();
      expect(
        src.contains('FirebaseFunctions.instanceFor(region: region)'),
        isTrue,
      );
      expect(src.contains('FirebaseFunctions.instance;'), isFalse);
      expect(src.contains("callableName = 'finalizeFrequency'"), isTrue);
      expect(src.contains("region = 'europe-west1'"), isTrue);
    });

    test('unavailable callable error is retryable and hides backend text',
        () async {
      final client = FrequencyFinalizeCallableClient(
        call: (_, __) async {
          // ignore: invalid_use_of_protected_member
          throw FirebaseFunctionsException(
            message: 'secret backend timeout text',
            code: 'unavailable',
          );
        },
      );
      try {
        await client.finalize(const {});
        fail('expected FrequencyFinalizeException');
      } on FrequencyFinalizeException catch (e) {
        expect(e.kind, FrequencyFinalizeFailureKind.retryable);
        expect(e.code, 'unavailable');
        expect(e.toString().contains('secret'), isFalse);
      }
    });

    test('SocketException remains retryable', () async {
      final client = FrequencyFinalizeCallableClient(
        call: (_, __) async {
          throw const SocketException('network down');
        },
      );
      try {
        await client.finalize(const {});
        fail('expected FrequencyFinalizeException');
      } on FrequencyFinalizeException catch (e) {
        expect(e.kind, FrequencyFinalizeFailureKind.retryable);
        expect(e.code, 'unavailable');
      }
    });
  });

  group('FrequencyFinalizeCallableClient.classifyFunctionsError', () {
    test('retryable codes', () {
      for (final code in [
        'unavailable',
        'deadline-exceeded',
        'internal',
        'unauthenticated',
      ]) {
        final e = FrequencyFinalizeCallableClient.classifyFunctionsError(
          code: code,
        );
        expect(e.kind, FrequencyFinalizeFailureKind.retryable, reason: code);
        expect(e.code, code);
      }
    });

    test('invalid-argument is non-retryable session', () {
      final e = FrequencyFinalizeCallableClient.classifyFunctionsError(
        code: 'invalid-argument',
      );
      expect(e.kind, FrequencyFinalizeFailureKind.nonRetryableSession);
    });

    test('permission-denied and not-found are account inconsistency', () {
      expect(
        FrequencyFinalizeCallableClient.classifyFunctionsError(
          code: 'permission-denied',
        ).kind,
        FrequencyFinalizeFailureKind.accountInconsistency,
      );
      expect(
        FrequencyFinalizeCallableClient.classifyFunctionsError(
          code: 'not-found',
        ).kind,
        FrequencyFinalizeFailureKind.accountInconsistency,
      );
    });

    test('FREQUENCY_ALREADY_VERIFIED details map to inconsistency', () {
      final e = FrequencyFinalizeCallableClient.classifyFunctionsError(
        code: 'failed-precondition',
        details: {'code': 'FREQUENCY_ALREADY_VERIFIED'},
      );
      expect(e.kind, FrequencyFinalizeFailureKind.accountInconsistency);
      expect(e.code, 'FREQUENCY_ALREADY_VERIFIED');
    });
  });
}
