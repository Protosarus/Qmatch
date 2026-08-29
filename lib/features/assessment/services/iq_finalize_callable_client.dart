import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Failure class for `finalizeIq`. Never shown raw to the user.
enum IqFinalizeFailureKind {
  retryable,
  nonRetryableSession,
  accountInconsistency,
}

class IqFinalizeException implements Exception {
  const IqFinalizeException({
    required this.kind,
    required this.code,
  });

  final IqFinalizeFailureKind kind;
  final String code;

  bool get isRetryable => kind == IqFinalizeFailureKind.retryable;

  @override
  String toString() => 'IqFinalizeException($kind, $code)';
}

class IqFinalizeResult {
  const IqFinalizeResult({
    required this.status,
    required this.flow,
    required this.idempotent,
  });

  final String status;
  final String flow;
  final bool idempotent;
}

/// Client for the live `finalizeIq` callable (europe-west1).
///
/// Structural verification only. Does not send or interpret IQ scores.
class IqFinalizeCallableClient {
  IqFinalizeCallableClient({
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
  static const String callableName = 'finalizeIq';

  Future<IqFinalizeResult> finalize(Map<String, dynamic> payload) async {
    try {
      final raw = await _invoke(payload);
      return _parseSuccess(raw);
    } on IqFinalizeException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      throw classifyFunctionsError(code: e.code, details: e.details);
    } on TimeoutException {
      throw const IqFinalizeException(
        kind: IqFinalizeFailureKind.retryable,
        code: 'deadline-exceeded',
      );
    } on SocketException {
      throw const IqFinalizeException(
        kind: IqFinalizeFailureKind.retryable,
        code: 'unavailable',
      );
    } catch (e) {
      debugPrint('finalizeIq unexpected failure: ${e.runtimeType}');
      throw const IqFinalizeException(
        kind: IqFinalizeFailureKind.retryable,
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
    throw const IqFinalizeException(
      kind: IqFinalizeFailureKind.retryable,
      code: 'internal',
    );
  }

  IqFinalizeResult _parseSuccess(Map<String, dynamic> raw) {
    final status = raw['status'] as String? ?? '';
    if (raw['ok'] != true || status != 'verified') {
      throw const IqFinalizeException(
        kind: IqFinalizeFailureKind.retryable,
        code: 'internal',
      );
    }
    return IqFinalizeResult(
      status: status,
      flow: raw['flow'] is String ? raw['flow'] as String : '',
      idempotent: raw['idempotent'] == true,
    );
  }

  /// Maps callable / HttpsError codes. Does not use backend messages.
  @visibleForTesting
  static IqFinalizeException classifyFunctionsError({
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
        return IqFinalizeException(
          kind: IqFinalizeFailureKind.retryable,
          code: code,
        );
      case 'invalid-argument':
        return const IqFinalizeException(
          kind: IqFinalizeFailureKind.nonRetryableSession,
          code: 'invalid-argument',
        );
      case 'permission-denied':
      case 'not-found':
        return IqFinalizeException(
          kind: IqFinalizeFailureKind.accountInconsistency,
          code: code,
        );
      case 'failed-precondition':
        if (detailsCode == 'IQ_ALREADY_VERIFIED') {
          return const IqFinalizeException(
            kind: IqFinalizeFailureKind.accountInconsistency,
            code: 'IQ_ALREADY_VERIFIED',
          );
        }
        return const IqFinalizeException(
          kind: IqFinalizeFailureKind.accountInconsistency,
          code: 'failed-precondition',
        );
      default:
        return IqFinalizeException(
          kind: IqFinalizeFailureKind.retryable,
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
