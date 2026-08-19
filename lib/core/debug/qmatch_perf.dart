import 'package:flutter/foundation.dart';

/// Debug/profile latency traces. No-ops in release.
class QmatchPerf {
  QmatchPerf._();

  static bool get enabled => !kReleaseMode;

  static void log(String name, Duration elapsed) {
    if (!enabled) return;
    debugPrint('qmatch.perf $name ${elapsed.inMilliseconds}ms');
  }

  /// Instant marker. Optional [since] is elapsed from a caller stopwatch.
  static void mark(String name, [Duration? since]) {
    if (!enabled) return;
    if (since == null) {
      debugPrint('qmatch.perf $name');
    } else {
      log(name, since);
    }
  }

  static Future<T> trace<T>(String name, Future<T> Function() action) async {
    if (!enabled) return action();
    final sw = Stopwatch()..start();
    try {
      return await action();
    } finally {
      sw.stop();
      log(name, sw.elapsed);
    }
  }

  /// Sync counterpart so CPU stages stay synchronous.
  static T traceSync<T>(String name, T Function() action) {
    if (!enabled) return action();
    final sw = Stopwatch()..start();
    try {
      return action();
    } finally {
      sw.stop();
      log(name, sw.elapsed);
    }
  }
}
