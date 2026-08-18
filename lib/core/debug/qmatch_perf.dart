import 'package:flutter/foundation.dart';

/// Debug/profile latency traces. No-ops in release.
class QmatchPerf {
  QmatchPerf._();

  static bool get enabled => !kReleaseMode;

  static void log(String name, Duration elapsed) {
    if (!enabled) return;
    debugPrint('qmatch.perf $name ${elapsed.inMilliseconds}ms');
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
}
