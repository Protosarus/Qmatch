import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'firebase_push_messaging_adapter.dart';
import 'push_messaging_port.dart';
import 'push_permission_state.dart';

/// Requests iOS notification permission and registers the FCM token.
///
/// Does not send pushes, show a marketing prompt, or write Firestore directly.
class NotificationRegistrationService {
  NotificationRegistrationService({
    PushMessagingPort? messaging,
    Future<void> Function(String name, Map<String, dynamic> data)? call,
    FirebaseFunctions? functions,
    String Function()? currentUid,
    String Function()? appId,
    bool? isIOS,
    String? apnsEnv,
    void Function(String message)? log,
    Future<void> Function(Duration delay)? delay,
  })  : _injectedMessaging = messaging,
        _call = call,
        _functions = functions,
        _currentUid = currentUid,
        _appId = appId,
        _isIOS = isIOS,
        _apnsEnv = apnsEnv,
        _log = log,
        _delay = delay;

  static const String region = 'europe-west1';
  static const String registerCallableName = 'registerFcmToken';
  static const String unregisterCallableName = 'unregisterFcmToken';

  static NotificationRegistrationService instance =
      NotificationRegistrationService();

  final PushMessagingPort? _injectedMessaging;
  final Future<void> Function(String name, Map<String, dynamic> data)? _call;
  final FirebaseFunctions? _functions;
  final String Function()? _currentUid;
  final String Function()? _appId;
  final bool? _isIOS;
  final String? _apnsEnv;
  final void Function(String message)? _log;
  final Future<void> Function(Duration delay)? _delay;

  PushMessagingPort? _lazyMessaging;
  StreamSubscription<String>? _refreshSub;
  Future<void>? _startFuture;
  String? _startedUid;
  String? _currentToken;
  bool _stopped = false;

  @visibleForTesting
  String? get debugCurrentToken => _currentToken;

  PushMessagingPort get _messaging =>
      _injectedMessaging ?? (_lazyMessaging ??= FirebasePushMessagingAdapter());

  bool get _runningOnIos =>
      _isIOS ?? defaultTargetPlatform == TargetPlatform.iOS;

  String? _resolveUid() =>
      _currentUid?.call() ?? FirebaseAuth.instance.currentUser?.uid;

  String _resolveAppId() =>
      _appId?.call() ?? DefaultFirebaseOptions.currentPlatform.appId;

  String? _resolveApnsEnv() {
    if (!_runningOnIos) return null;
    if (_apnsEnv != null) return _apnsEnv;
    return kDebugMode ? 'sandbox' : 'production';
  }

  void _debugLog(String message) {
    if (_log != null) {
      _log!(message);
      return;
    }
    if (kReleaseMode) return;
    debugPrint(message);
  }

  /// System permission + token register. Safe to call on rebuilds.
  Future<void> startAfterAuthenticatedAppReady() {
    final uid = _resolveUid();
    if (uid == null || uid.isEmpty) return Future.value();
    if (_startedUid == uid && _startFuture != null) {
      return _startFuture!;
    }
    _startedUid = uid;
    _startFuture = _start(uid);
    return _startFuture!;
  }

  Future<void> _start(String uid) async {
    _stopped = false;
    try {
      var status = await _messaging.currentPermission();
      if (status == PushPermissionState.notDetermined) {
        status = await _messaging.requestPermission();
      }
      _debugLog('qmatch.push permission=${status.name}');
      if (!status.allowsTokenRegistration) return;
      if (_stopped || _resolveUid() != uid) return;
      await _registerCurrentFcmToken(fromRefresh: false);
      if (_stopped) return;
      _listenForRefresh();
    } catch (_) {
      // Permission / token failures must not break the authenticated shell.
    }
  }

  void _listenForRefresh() {
    if (_refreshSub != null) return;
    _refreshSub = _messaging.onTokenRefresh.listen((token) async {
      if (_stopped) return;
      final trimmed = token.trim();
      if (trimmed.isEmpty) return;
      try {
        await _registerToken(trimmed, fromRefresh: true);
      } catch (_) {}
    });
  }

  Future<void> _registerCurrentFcmToken({required bool fromRefresh}) async {
    if (_runningOnIos) {
      final apns = await _messaging.getAPNSToken();
      if (apns == null || apns.trim().isEmpty) {
        final wait = _delay ?? Future<void>.delayed;
        await wait(const Duration(milliseconds: 500));
        await _messaging.getAPNSToken();
      }
    }
    final token = (await _messaging.getToken())?.trim();
    if (token == null || token.isEmpty) return;
    await _registerToken(token, fromRefresh: fromRefresh);
  }

  Future<void> _registerToken(String token, {required bool fromRefresh}) async {
    final uid = _resolveUid();
    if (uid == null || uid.isEmpty) return;
    final payload = <String, dynamic>{
      'token': token,
      'platform': _runningOnIos ? 'ios' : 'android',
      'app_id': _resolveAppId(),
    };
    final apnsEnv = _resolveApnsEnv();
    if (apnsEnv != null) payload['apns_env'] = apnsEnv;
    await _invoke(registerCallableName, payload);
    if (_stopped) {
      try {
        await _invoke(unregisterCallableName, {'token': token});
      } catch (_) {}
      return;
    }
    _currentToken = token;
    _debugLog(
      fromRefresh
          ? 'qmatch.push token_refreshed'
          : 'qmatch.push token_registered',
    );
  }

  /// Unregister this device token. Never throws. Does not touch other devices.
  Future<void> unregisterForLogout() async {
    _stopped = true;
    final token = _currentToken;
    _currentToken = null;
    _startedUid = null;
    _startFuture = null;
    final sub = _refreshSub;
    _refreshSub = null;
    await sub?.cancel();
    if (token == null || token.isEmpty) return;
    try {
      await _invoke(unregisterCallableName, {'token': token});
      _debugLog('qmatch.push token_unregistered');
    } catch (_) {
      // Logout must continue even if the callable fails.
    }
  }

  Future<void> _invoke(String name, Map<String, dynamic> data) async {
    final custom = _call;
    if (custom != null) {
      await custom(name, data);
      return;
    }
    final functions =
        _functions ?? FirebaseFunctions.instanceFor(region: region);
    await functions.httpsCallable(name).call(data);
  }
}
