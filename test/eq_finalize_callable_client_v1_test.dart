import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/services/eq_finalize_callable_client.dart';

void main() {
  group('EqFinalizeCallableClient', () {
    test('invokes finalizeEq in europe-west1 and returns verified result',
        () async {
      String? calledName;
      Map<String, dynamic>? calledData;
      final client = EqFinalizeCallableClient(
        call: (name, data) async {
          calledName = name;
          calledData = data;
          return {
            'ok': true,
            'assessment_type': 'eq',
            'status': 'verified',
            'flow': 'eq',
            'idempotent': false,
          };
        },
      );

      final result = await client.finalize({
        'schema_version': 'assessment_finalize_session_v1',
        'session_id': 'eq_sess_abc',
      });

      expect(calledName, 'finalizeEq');
      expect(calledName, EqFinalizeCallableClient.callableName);
      expect(EqFinalizeCallableClient.callableName, 'finalizeEq');
      expect(EqFinalizeCallableClient.region, 'europe-west1');
      expect(calledData!['session_id'], 'eq_sess_abc');
      expect(result.status, 'verified');
      expect(result.flow, 'eq');
      expect(result.idempotent, isFalse);
    });

    test('idempotent true is preserved', () async {
      final client = EqFinalizeCallableClient(
        call: (_, __) async => {
          'ok': true,
          'status': 'verified',
          'flow': 'eq',
          'idempotent': true,
        },
      );
      final result = await client.finalize(const {});
      expect(result.idempotent, isTrue);
    });

    test('non-verified payload is not local success', () async {
      final client = EqFinalizeCallableClient(
        call: (_, __) async => {
          'ok': false,
          'status': 'rejected',
          'flow': 'eq',
        },
      );
      try {
        await client.finalize(const {});
        fail('expected EqFinalizeException');
      } on EqFinalizeException catch (e) {
        expect(e.kind, EqFinalizeFailureKind.retryable);
        expect(e.code, 'internal');
      }
    });

    test('binds europe-west1 via instanceFor and never uses default instance',
        () {
      final src = File(
        'lib/features/assessment/services/eq_finalize_callable_client.dart',
      ).readAsStringSync();
      expect(
        src.contains('FirebaseFunctions.instanceFor(region: region)'),
        isTrue,
      );
      expect(src.contains('FirebaseFunctions.instance;'), isFalse);
      expect(src.contains("callableName = 'finalizeEq'"), isTrue);
      expect(src.contains("region = 'europe-west1'"), isTrue);
    });

    test('unavailable callable error is retryable and hides backend text',
        () async {
      final client = EqFinalizeCallableClient(
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
        fail('expected EqFinalizeException');
      } on EqFinalizeException catch (e) {
        expect(e.kind, EqFinalizeFailureKind.retryable);
        expect(e.code, 'unavailable');
        expect(e.toString().contains('secret'), isFalse);
      }
    });

    test('SocketException remains retryable', () async {
      final client = EqFinalizeCallableClient(
        call: (_, __) async {
          throw const SocketException('network down');
        },
      );
      try {
        await client.finalize(const {});
        fail('expected EqFinalizeException');
      } on EqFinalizeException catch (e) {
        expect(e.kind, EqFinalizeFailureKind.retryable);
        expect(e.code, 'unavailable');
      }
    });
  });

  group('EqFinalizeCallableClient.classifyFunctionsError', () {
    test('retryable codes', () {
      for (final code in [
        'unavailable',
        'deadline-exceeded',
        'internal',
        'unauthenticated',
      ]) {
        final e = EqFinalizeCallableClient.classifyFunctionsError(code: code);
        expect(e.kind, EqFinalizeFailureKind.retryable, reason: code);
        expect(e.code, code);
      }
    });

    test('invalid-argument is non-retryable session', () {
      final e = EqFinalizeCallableClient.classifyFunctionsError(
        code: 'invalid-argument',
      );
      expect(e.kind, EqFinalizeFailureKind.nonRetryableSession);
    });

    test('permission-denied and not-found are account inconsistency', () {
      expect(
        EqFinalizeCallableClient.classifyFunctionsError(
          code: 'permission-denied',
        ).kind,
        EqFinalizeFailureKind.accountInconsistency,
      );
      expect(
        EqFinalizeCallableClient.classifyFunctionsError(code: 'not-found').kind,
        EqFinalizeFailureKind.accountInconsistency,
      );
    });

    test('EQ_ALREADY_VERIFIED details map to inconsistency', () {
      final e = EqFinalizeCallableClient.classifyFunctionsError(
        code: 'failed-precondition',
        details: {'code': 'EQ_ALREADY_VERIFIED'},
      );
      expect(e.kind, EqFinalizeFailureKind.accountInconsistency);
      expect(e.code, 'EQ_ALREADY_VERIFIED');
    });
  });
}
