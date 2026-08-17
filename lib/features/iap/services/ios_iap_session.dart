import 'package:flutter/foundation.dart';

import '../domain/iap_exceptions.dart';
import 'ios_iap_client.dart';

/// One [IosIapClient] for the authenticated iOS app session.
///
/// The StoreKit purchase listener starts after Firebase Auth is available
/// and stays alive until the session detaches (sign-out). Paywall UI must
/// reuse [client] instead of constructing a second listener.
class IosIapSession {
  IosIapSession({IosIapClient Function()? createClient})
      : _createClient = createClient;

  static IosIapSession instance = IosIapSession();

  final IosIapClient Function()? _createClient;
  IosIapClient? _client;
  bool _attached = false;

  IosIapClient get client => _client ??= _create();

  bool get isAttached => _attached;

  bool get isListening => _client?.isListening == true;

  IosIapClient _create() {
    final custom = _createClient;
    if (custom != null) return custom();
    return IosIapClient();
  }

  /// Start (or keep) the session listener. Idempotent.
  void attach() {
    _attached = true;
    try {
      client.startListening();
    } on IapPlatformDisabledException {
      // Android / non-iOS: no StoreKit listener.
    }
  }

  /// Stop the listener for this authenticated session.
  Future<void> detach() async {
    _attached = false;
    final client = _client;
    _client = null;
    await client?.dispose();
  }

  @visibleForTesting
  static void debugResetInstance([IosIapSession? next]) {
    instance = next ?? IosIapSession();
  }
}
