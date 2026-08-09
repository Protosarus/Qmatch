import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

/// Reference-counted capture protection for active assessment question screens.
///
/// Android: applies [FlutterWindowManager.FLAG_SECURE] while any scope is open.
/// iOS: does **not** claim screenshot blocking; coordinates capture-state /
/// app-switcher privacy overlays via [obscureStream] (no score/RVI coupling).
///
/// Does not log UID, answers, or screen pixels.
class AssessmentCaptureProtection {
  AssessmentCaptureProtection._();

  static final AssessmentCaptureProtection instance =
      AssessmentCaptureProtection._();

  /// Test seam — inject a fake instead of touching the platform channel.
  static AssessmentCaptureProtection? debugOverride;

  static AssessmentCaptureProtection get active => debugOverride ?? instance;

  int _refs = 0;
  bool _androidSecureApplied = false;
  bool _iosListening = false;
  bool _screenCaptured = false;
  bool _appInactive = false;

  final StreamController<bool> _obscureController =
      StreamController<bool>.broadcast();

  int get debugRefCount => _refs;
  bool get debugAndroidSecureApplied => _androidSecureApplied;
  bool get isScreenCaptured => _screenCaptured;
  bool get shouldObscure => _screenCaptured || _appInactive;

  Stream<bool> get obscureStream => _obscureController.stream;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> enable() async {
    _refs++;
    if (_refs == 1) {
      await _applyPlatformProtection();
    }
    _emitObscure();
  }

  Future<void> disable() async {
    if (_refs <= 0) return;
    _refs--;
    if (_refs == 0) {
      await _clearPlatformProtection();
      _screenCaptured = false;
      _appInactive = false;
    }
    _emitObscure();
  }

  /// Called by UI [WidgetsBindingObserver] — app-switcher privacy only.
  void setAppInactive(bool inactive) {
    if (_refs == 0) {
      _appInactive = false;
      _emitObscure();
      return;
    }
    _appInactive = inactive;
    _emitObscure();
  }

  /// Called from platform events / tests — screen recording / capture flag.
  void setScreenCaptured(bool captured) {
    if (_refs == 0) {
      _screenCaptured = false;
      _emitObscure();
      return;
    }
    _screenCaptured = captured;
    _emitObscure();
  }

  /// Optional post-screenshot privacy flash (detection only — not blocking).
  void notifyScreenshotDetected() {
    if (_refs == 0) return;
    _screenCaptured = true;
    _emitObscure();
    scheduleMicrotask(() {
      unawaited(_refreshCapturedFromPlatform());
    });
  }

  @visibleForTesting
  void debugReset() {
    _refs = 0;
    _androidSecureApplied = false;
    _iosListening = false;
    _screenCaptured = false;
    _appInactive = false;
  }

  void _emitObscure() {
    if (!_obscureController.isClosed) {
      _obscureController.add(shouldObscure);
    }
  }

  Future<void> _applyPlatformProtection() async {
    try {
      if (_isAndroid) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        _androidSecureApplied = true;
      } else if (_isIos) {
        await _ensureIosListeners();
        _screenCaptured = await FlutterWindowManager.isCaptured();
      }
    } catch (_) {
      // Platform channel may be absent in unit tests — ignore.
    }
  }

  Future<void> _clearPlatformProtection() async {
    try {
      if (_isAndroid && _androidSecureApplied) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        _androidSecureApplied = false;
      } else if (_isIos) {
        await _stopIosListeners();
      }
    } catch (_) {}
  }

  Future<void> _ensureIosListeners() async {
    if (_iosListening) return;
    _iosListening = true;
    FlutterWindowManager.setCaptureEventHandler((event) {
      if (event == 'capturedChanged') {
        unawaited(_refreshCapturedFromPlatform());
      } else if (event == 'screenshotTaken') {
        notifyScreenshotDetected();
      }
    });
    await FlutterWindowManager.startCaptureMonitoring();
  }

  Future<void> _stopIosListeners() async {
    if (!_iosListening) return;
    _iosListening = false;
    try {
      await FlutterWindowManager.stopCaptureMonitoring();
    } catch (_) {}
    FlutterWindowManager.setCaptureEventHandler(null);
  }

  Future<void> _refreshCapturedFromPlatform() async {
    try {
      final captured = await FlutterWindowManager.isCaptured();
      setScreenCaptured(captured);
    } catch (_) {
      setScreenCaptured(false);
    }
  }
}
