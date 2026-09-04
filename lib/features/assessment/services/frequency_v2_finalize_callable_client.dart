import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

enum FrequencyV2FinalizeFailureKind {
  retryable,
  nonRetryableSession,
  accountInconsistency,
  sessionConflict,
}

class FrequencyV2FinalizeException implements Exception {
  const FrequencyV2FinalizeException({
    required this.kind,
    required this.code,
  });

  final FrequencyV2FinalizeFailureKind kind;
  final String code;

  bool get isRetryable => kind == FrequencyV2FinalizeFailureKind.retryable;

  @override
  String toString() => 'FrequencyV2FinalizeException($kind, $code)';
}

class FrequencyV2FinalizeResult {
  const FrequencyV2FinalizeResult({
    required this.status,
    required this.assessmentType,
    required this.idempotent,
    this.sessionId,
  });

  final String status;
  final String assessmentType;
  final bool idempotent;
  final String? sessionId;
}

/// Client for undeployed `finalizeFrequencyV2` (`europe-west1`).
///
/// Dormant: must not be invoked from live Frequency V1 routing.
class FrequencyV2FinalizeCallableClient {
  FrequencyV2FinalizeCallableClient({
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    )? call,
  })  : _functions = functions,
        _call = call;

  final FirebaseFunctions? _functions;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? _call;

  static const String region = 'europe-west1';
  static const String callableName = 'finalizeFrequencyV2';

  Future<FrequencyV2FinalizeResult> finalize(
    Map<String, dynamic> payload,
  ) async {
    try {
      final raw = await _invoke(payload);
      return _parseSuccess(raw);
    } on FrequencyV2FinalizeException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      throw classifyFunctionsError(code: e.code, details: e.details);
    } on TimeoutException {
      throw const FrequencyV2FinalizeException(
        kind: FrequencyV2FinalizeFailureKind.retryable,
        code: 'deadline-exceeded',
      );
    } on SocketException {
      throw const FrequencyV2FinalizeException(
        kind: FrequencyV2FinalizeFailureKind.retryable,
        code: 'unavailable',
      );
    } catch (e) {
      debugPrint('finalizeFrequencyV2 unexpected failure: ${e.runtimeType}');
      throw const FrequencyV2FinalizeException(
        kind: FrequencyV2FinalizeFailureKind.retryable,
        code: 'internal',
      );
    }
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> data) async {
    final custom = _call;
    if (custom != null) return custom(callableName, data);
    final functions =
        _functions ?? FirebaseFunctions.instanceFor(region: region);
    final result = await functions.httpsCallable(callableName).call(data);
    final payload = result.data;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw const FrequencyV2FinalizeException(
      kind: FrequencyV2FinalizeFailureKind.retryable,
      code: 'internal',
    );
  }

  FrequencyV2FinalizeResult _parseSuccess(Map<String, dynamic> raw) {
    final status = raw['status'] as String? ?? '';
    if (raw['ok'] != true || status != 'completed') {
      throw const FrequencyV2FinalizeException(
        kind: FrequencyV2FinalizeFailureKind.retryable,
        code: 'internal',
      );
    }
    return FrequencyV2FinalizeResult(
      status: status,
      assessmentType: raw['assessment_type'] is String
          ? raw['assessment_type'] as String
          : '',
      idempotent: raw['idempotent'] == true,
      sessionId: raw['session_id'] as String?,
    );
  }

  @visibleForTesting
  static FrequencyV2FinalizeException classifyFunctionsError({
    required String code,
    Object? details,
  }) {
    final detailsCode = _detailsCode(details);
    switch (code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'internal':
      case 'aborted':
      case 'resource-exhausted':
      case 'cancelled':
        return FrequencyV2FinalizeException(
          kind: FrequencyV2FinalizeFailureKind.retryable,
          code: code,
        );
      case 'unauthenticated':
        return const FrequencyV2FinalizeException(
          kind: FrequencyV2FinalizeFailureKind.retryable,
          code: 'unauthenticated',
        );
      case 'invalid-argument':
        return const FrequencyV2FinalizeException(
          kind: FrequencyV2FinalizeFailureKind.nonRetryableSession,
          code: 'invalid-argument',
        );
      case 'permission-denied':
      case 'not-found':
        return FrequencyV2FinalizeException(
          kind: FrequencyV2FinalizeFailureKind.accountInconsistency,
          code: code,
        );
      case 'failed-precondition':
        if (detailsCode == 'FREQUENCY_V2_ALREADY_FINALIZED') {
          return const FrequencyV2FinalizeException(
            kind: FrequencyV2FinalizeFailureKind.sessionConflict,
            code: 'FREQUENCY_V2_ALREADY_FINALIZED',
          );
        }
        return const FrequencyV2FinalizeException(
          kind: FrequencyV2FinalizeFailureKind.accountInconsistency,
          code: 'failed-precondition',
        );
      default:
        return FrequencyV2FinalizeException(
          kind: FrequencyV2FinalizeFailureKind.retryable,
          code: code,
        );
    }
  }

  static String? _detailsCode(Object? details) {
    if (details is Map) {
      final code = details['code'];
      if (code is String && code.trim().isNotEmpty) return code.trim();
    }
    return null;
  }
}
