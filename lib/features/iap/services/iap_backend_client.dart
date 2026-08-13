import 'package:cloud_functions/cloud_functions.dart';

import '../domain/iap_exceptions.dart';

/// Callable client for trusted purchase verify / restore.
///
/// Never grants entitlement locally — only forwards StoreKit proof to backend.
class IapBackendClient {
  IapBackendClient({
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>> Function(String name, Map<String, dynamic> data)?
        call,
  })  : _functions = functions,
        _call = call;

  final FirebaseFunctions? _functions;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? _call;

  static const verifyAndApplyPurchaseName = 'verifyAndApplyPurchase';
  static const restorePurchasesName = 'restorePurchases';

  Future<Map<String, dynamic>> _invoke(
    String name,
    Map<String, dynamic> data,
  ) async {
    final custom = _call;
    if (custom != null) {
      return custom(name, data);
    }
    final functions = _functions ?? FirebaseFunctions.instance;
    final result = await functions.httpsCallable(name).call(data);
    final raw = result.data;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    throw IapVerificationFailedException(
      code: 'invalid_response',
      message: 'Callable $name returned a non-map payload.',
    );
  }

  /// After StoreKit purchase success — server verifies and applies.
  Future<Map<String, dynamic>> verifyAndApplyPurchase({
    required String signedTransaction,
    required String transactionId,
  }) {
    return _invoke(verifyAndApplyPurchaseName, {
      'platform': 'ios',
      'signedTransaction': signedTransaction,
      'transactionId': transactionId,
    });
  }

  /// Explicit Restore Purchases — Apple transactions only.
  Future<Map<String, dynamic>> restorePurchases({
    required List<Map<String, String>> transactions,
  }) {
    return _invoke(restorePurchasesName, {
      'platform': 'ios',
      'transactions': transactions,
    });
  }

  /// True only when backend reports trusted verification success.
  static bool isTrustedVerified(Map<String, dynamic>? response) {
    if (response == null) return false;
    return response['ok'] == true &&
        response['trusted'] == true &&
        response['verified'] == true;
  }

  /// Restore batch accepted when at least one trusted txn applied path is ok.
  static bool isTrustedRestore(Map<String, dynamic>? response) {
    if (response == null) return false;
    if (response['ok'] == true &&
        response['trusted'] == true &&
        response['verified'] == true) {
      return true;
    }
    // Partial restore still requires at least one trusted verified item.
    final count = response['restored_count'];
    if (count is int && count > 0 && response['verified'] == true) {
      return true;
    }
    return false;
  }
}
