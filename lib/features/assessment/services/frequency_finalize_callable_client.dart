import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Failure class for `finalizeFrequency`. Never shown raw to the user.
enum FrequencyFinalizeFailureKind {
  retryable,
  nonRetryableSession,
  accountInconsistency,
}

class FrequencyFinalizeException implements Exception {
  const FrequencyFinalizeException({
    required this.kind,
    required this.code,
  });

  final FrequencyFinalizeFailureKind kind;
  final String code;

  bool get isRetryable => kind == FrequencyFinalizeFailureKind.retryable;

  @override
  String toString() => 'FrequencyFinalizeException($kind, $code)';
}

class FrequencyFinalizeResult {
  const FrequencyFinalizeResult({
    required this.status,
    required this.flow,
    required this.idempotent,
  });

  final String status;
  final String flow;
  final bool idempotent;
}

/// Client for the live `finalizeFrequency` callable (europe-west1).
///
/// Structural verification only. Does not send or interpret Frequency scores.
///
/// Release order: deploy backend `finalizeEq` and verify it in production,
/// then deploy `finalizeFrequency` and verify it, before shipping a Flutter
/// build that requires this callable.
class FrequencyFinalizeCallableClient {
  FrequencyFinalizeCallableClient({
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
  static const String callableName = 'finalizeFrequency';

  Future<FrequencyFinalizeResult> finalize(Map<String, dynamic> payload) async {
    try {
      final raw = await _invoke(payload);
      return _parseSuccess(raw);
    } on FrequencyFinalizeException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      throw classifyFunctionsError(code: e.code, details: e.details);
    } on TimeoutException {
      throw const FrequencyFinalizeException(
        kind: FrequencyFinalizeFailureKind.retryable,
        code: 'deadline-exceeded',
      );
    } on SocketException {
      throw const FrequencyFinalizeException(
        kind: FrequencyFinalizeFailureKind.retryable,
        code: 'unavailable',
      );
    } catch (e) {
      debugPrint('finalizeFrequency unexpected failure: ${e.runtimeType}');
      throw const FrequencyFinalizeException(
        kind: FrequencyFinalizeFailureKind.retryable,
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
    throw const FrequencyFinalizeException(
      kind: FrequencyFinalizeFailureKind.retryable,
      code: 'internal',
    );
  }

  FrequencyFinalizeResult _parseSuccess(Map<String, dynamic> raw) {
    final status = raw['status'] as String? ?? '';
    if (raw['ok'] != true || status != 'verified') {
      throw const FrequencyFinalizeException(
        kind: FrequencyFinalizeFailureKind.retryable,
        code: 'internal',
      );
    }
    return FrequencyFinalizeResult(
      status: status,
      flow: raw['flow'] is String ? raw['flow'] as String : '',
      idempotent: raw['idempotent'] == true,
    );
  }

  /// Maps callable / HttpsError codes. Does not use backend messages.
  @visibleForTesting
  static FrequencyFinalizeException classifyFunctionsError({
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
      case 'unauthenticated':
        return FrequencyFinalizeException(
          kind: FrequencyFinalizeFailureKind.retryable,
          code: code,
        );
      case 'invalid-argument':
        return const FrequencyFinalizeException(
          kind: FrequencyFinalizeFailureKind.nonRetryableSession,
          code: 'invalid-argument',
        );
      case 'permission-denied':
      case 'not-found':
        return FrequencyFinalizeException(
          kind: FrequencyFinalizeFailureKind.accountInconsistency,
          code: code,
        );
      case 'failed-precondition':
        if (detailsCode == 'FREQUENCY_ALREADY_VERIFIED') {
          return const FrequencyFinalizeException(
            kind: FrequencyFinalizeFailureKind.accountInconsistency,
            code: 'FREQUENCY_ALREADY_VERIFIED',
          );
        }
        return const FrequencyFinalizeException(
          kind: FrequencyFinalizeFailureKind.accountInconsistency,
          code: 'failed-precondition',
        );
      default:
        return FrequencyFinalizeException(
          kind: FrequencyFinalizeFailureKind.retryable,
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
