import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Failure class for `finalizeEq`. Never shown raw to the user.
enum EqFinalizeFailureKind {
  retryable,
  nonRetryableSession,
  accountInconsistency,
}

class EqFinalizeException implements Exception {
  const EqFinalizeException({
    required this.kind,
    required this.code,
  });

  final EqFinalizeFailureKind kind;
  final String code;

  bool get isRetryable => kind == EqFinalizeFailureKind.retryable;

  @override
  String toString() => 'EqFinalizeException($kind, $code)';
}

class EqFinalizeResult {
  const EqFinalizeResult({
    required this.status,
    required this.flow,
    required this.idempotent,
  });

  final String status;
  final String flow;
  final bool idempotent;
}

/// Client for the live `finalizeEq` callable (europe-west1).
///
/// Structural verification only. Does not send or interpret EQ scores.
///
/// Release order: deploy backend `finalizeEq` and verify it in production
/// before shipping a Flutter build that requires this callable.
class EqFinalizeCallableClient {
  EqFinalizeCallableClient({
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
  static const String callableName = 'finalizeEq';

  Future<EqFinalizeResult> finalize(Map<String, dynamic> payload) async {
    try {
      final raw = await _invoke(payload);
      return _parseSuccess(raw);
    } on EqFinalizeException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      throw classifyFunctionsError(code: e.code, details: e.details);
    } on TimeoutException {
      throw const EqFinalizeException(
        kind: EqFinalizeFailureKind.retryable,
        code: 'deadline-exceeded',
      );
    } on SocketException {
      throw const EqFinalizeException(
        kind: EqFinalizeFailureKind.retryable,
        code: 'unavailable',
      );
    } catch (e) {
      debugPrint('finalizeEq unexpected failure: ${e.runtimeType}');
      throw const EqFinalizeException(
        kind: EqFinalizeFailureKind.retryable,
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
    throw const EqFinalizeException(
      kind: EqFinalizeFailureKind.retryable,
      code: 'internal',
    );
  }

  EqFinalizeResult _parseSuccess(Map<String, dynamic> raw) {
    final status = raw['status'] as String? ?? '';
    if (raw['ok'] != true || status != 'verified') {
      throw const EqFinalizeException(
        kind: EqFinalizeFailureKind.retryable,
        code: 'internal',
      );
    }
    return EqFinalizeResult(
      status: status,
      flow: raw['flow'] is String ? raw['flow'] as String : '',
      idempotent: raw['idempotent'] == true,
    );
  }

  /// Maps callable / HttpsError codes. Does not use backend messages.
  @visibleForTesting
  static EqFinalizeException classifyFunctionsError({
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
        return EqFinalizeException(
          kind: EqFinalizeFailureKind.retryable,
          code: code,
        );
      case 'invalid-argument':
        return const EqFinalizeException(
          kind: EqFinalizeFailureKind.nonRetryableSession,
          code: 'invalid-argument',
        );
      case 'permission-denied':
      case 'not-found':
        return EqFinalizeException(
          kind: EqFinalizeFailureKind.accountInconsistency,
          code: code,
        );
      case 'failed-precondition':
        if (detailsCode == 'EQ_ALREADY_VERIFIED') {
          return const EqFinalizeException(
            kind: EqFinalizeFailureKind.accountInconsistency,
            code: 'EQ_ALREADY_VERIFIED',
          );
        }
        return const EqFinalizeException(
          kind: EqFinalizeFailureKind.accountInconsistency,
          code: 'failed-precondition',
        );
      default:
        return EqFinalizeException(
          kind: EqFinalizeFailureKind.retryable,
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
