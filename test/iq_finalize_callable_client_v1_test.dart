import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/services/iq_finalize_callable_client.dart';

void main() {
  group('IqFinalizeCallableClient', () {
    test('invokes finalizeIq and returns typed verified result', () async {
      String? calledName;
      Map<String, dynamic>? calledData;
      final client = IqFinalizeCallableClient(
        call: (name, data) async {
          calledName = name;
          calledData = data;
          return {
            'ok': true,
            'assessment_type': 'iq',
            'status': 'verified',
            'flow': 'iq',
            'idempotent': false,
          };
        },
      );

      final result = await client.finalize({
        'schema_version': 'assessment_finalize_session_v1',
        'session_id': 'iq_sess_abc',
      });

      expect(calledName, 'finalizeIq');
      expect(calledName, IqFinalizeCallableClient.callableName);
      expect(IqFinalizeCallableClient.callableName, 'finalizeIq');
      expect(IqFinalizeCallableClient.region, 'europe-west1');
      expect(calledData!['session_id'], 'iq_sess_abc');
      expect(result.status, 'verified');
      expect(result.flow, 'iq');
      expect(result.idempotent, isFalse);
    });

    test('idempotent true is preserved', () async {
      final client = IqFinalizeCallableClient(
        call: (_, __) async => {
          'ok': true,
          'status': 'verified',
          'flow': 'iq',
          'idempotent': true,
        },
      );
      final result = await client.finalize(const {});
      expect(result.idempotent, isTrue);
    });

    test('binds europe-west1 via instanceFor and never uses default instance',
        () {
      final src = File(
        'lib/features/assessment/services/iq_finalize_callable_client.dart',
      ).readAsStringSync();
      expect(
        src.contains("FirebaseFunctions.instanceFor(region: region)"),
        isTrue,
      );
      expect(src.contains('FirebaseFunctions.instance;'), isFalse);
      expect(src.contains("callableName = 'finalizeIq'"), isTrue);
      expect(src.contains("region = 'europe-west1'"), isTrue);
    });

    test('unavailable callable error is retryable and hides backend text',
        () async {
      final client = IqFinalizeCallableClient(
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
        fail('expected IqFinalizeException');
      } on IqFinalizeException catch (e) {
        expect(e.kind, IqFinalizeFailureKind.retryable);
        expect(e.code, 'unavailable');
        expect(e.toString().contains('secret'), isFalse);
      }
    });
  });

  group('IqFinalizeCallableClient.classifyFunctionsError', () {
    test('retryable codes', () {
      for (final code in [
        'unavailable',
        'deadline-exceeded',
        'internal',
        'unauthenticated',
      ]) {
        final e = IqFinalizeCallableClient.classifyFunctionsError(code: code);
        expect(e.kind, IqFinalizeFailureKind.retryable, reason: code);
        expect(e.code, code);
      }
    });

    test('invalid-argument is non-retryable session', () {
      final e = IqFinalizeCallableClient.classifyFunctionsError(
        code: 'invalid-argument',
      );
      expect(e.kind, IqFinalizeFailureKind.nonRetryableSession);
    });

    test('permission-denied and not-found are account inconsistency', () {
      expect(
        IqFinalizeCallableClient.classifyFunctionsError(
          code: 'permission-denied',
        ).kind,
        IqFinalizeFailureKind.accountInconsistency,
      );
      expect(
        IqFinalizeCallableClient.classifyFunctionsError(code: 'not-found').kind,
        IqFinalizeFailureKind.accountInconsistency,
      );
    });

    test('IQ_ALREADY_VERIFIED details map to inconsistency', () {
      final e = IqFinalizeCallableClient.classifyFunctionsError(
        code: 'failed-precondition',
        details: {'code': 'IQ_ALREADY_VERIFIED'},
      );
      expect(e.kind, IqFinalizeFailureKind.accountInconsistency);
      expect(e.code, 'IQ_ALREADY_VERIFIED');
    });
  });
}
