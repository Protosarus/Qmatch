import 'dart:math' as math;

import 'temporal_shadow_extractor_contract.dart';
import 'temporal_shadow_extractor_models.dart';

/// L4 v1 post-match temporal feature extractor.
///
/// Consumes existing message metadata timestamps + sender ids only.
/// Production diagnostics: cadence / burstiness / regularity / reply-turn /
/// participation. Circadian is conditional on timezone.
/// No Discover ranking, Persona, quantum/L5, RVI, Class B omega, questionnaire
/// temporal maps, or pre-match inference.
class TemporalShadowExtractor {
  const TemporalShadowExtractor();

  /// Extract per-thread dyadic + user-level shadow features.
  ///
  /// [localTimeZoneOffset] — offset from UTC for civil local time. If null,
  /// hour histogram and circadian features are unavailable (do not assume UTC
  /// is local).
  TemporalShadowThreadResult extractThread({
    required String participantP,
    required String participantQ,
    required List<TemporalShadowEvent> events,
    required DateTime windowStart,
    required DateTime windowEnd,
    Duration? localTimeZoneOffset,
    Duration replyTimeout = TemporalShadowExtractorContract.replyTimeout,
  }) {
    if (participantP == participantQ) {
      throw ArgumentError('participantP and participantQ must differ');
    }

    final startMs = windowStart.toUtc().millisecondsSinceEpoch;
    final endMs = windowEnd.toUtc().millisecondsSinceEpoch;
    final windowSeconds = (endMs - startMs) / 1000.0;
    final windowValid = windowSeconds > 0;

    final filtered = <TemporalShadowEvent>[];
    if (windowValid) {
      for (final e in events) {
        if (e.senderId == TemporalShadowExtractorContract.systemSenderId) {
          continue;
        }
        if (e.senderId != participantP && e.senderId != participantQ) {
          continue;
        }
        if (e.timestampMs < startMs || e.timestampMs > endMs) continue;
        filtered.add(e);
      }
      filtered.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    }

    final userP = _userFeatures(
      userId: participantP,
      events: filtered.where((e) => e.senderId == participantP).toList(),
      windowSeconds: windowSeconds,
      windowValid: windowValid,
      localTimeZoneOffset: localTimeZoneOffset,
    );
    final userQ = _userFeatures(
      userId: participantQ,
      events: filtered.where((e) => e.senderId == participantQ).toList(),
      windowSeconds: windowSeconds,
      windowValid: windowValid,
      localTimeZoneOffset: localTimeZoneOffset,
    );

    final dyadic = _dyadicFeatures(
      participantP: participantP,
      participantQ: participantQ,
      ordered: filtered,
      userP: userP,
      userQ: userQ,
      windowSeconds: windowSeconds,
      windowValid: windowValid,
      replyTimeout: replyTimeout,
    );

    return TemporalShadowThreadResult(
      participantP: participantP,
      participantQ: participantQ,
      windowStartMs: startMs,
      windowEndMs: endMs,
      windowSeconds: windowValid ? windowSeconds : 0.0,
      userP: userP,
      userQ: userQ,
      dyadic: dyadic,
      localTimeZoneAvailable: localTimeZoneOffset != null,
    );
  }

  TemporalShadowUserFeatures _userFeatures({
    required String userId,
    required List<TemporalShadowEvent> events,
    required double windowSeconds,
    required bool windowValid,
    required Duration? localTimeZoneOffset,
  }) {
    final n = events.length;
    final intervals = <double>[];
    for (var i = 1; i < events.length; i++) {
      final d = (events[i].timestampMs - events[i - 1].timestampMs) / 1000.0;
      if (d > 0) intervals.add(d);
    }

    return TemporalShadowUserFeatures(
      userId: userId,
      eventCount: windowValid ? n : 0,
      interEventIntervalsSeconds: List.unmodifiable(intervals),
      cadenceMeanPerSecond: _cadenceMean(n, windowSeconds, windowValid),
      cadenceMedianPerSecond: _cadenceMedian(n, intervals, windowSeconds, windowValid),
      burstiness: _burstiness(intervals, windowSeconds, windowValid),
      regularity: _regularity(intervals, windowSeconds, windowValid),
      hourHistogramStatus: _hourStatus(n, events, localTimeZoneOffset, windowValid),
      hourOfDayHistogram: _hourHistogram(n, events, localTimeZoneOffset, windowValid),
      circadianThetaBar: _circadianTheta(n, events, localTimeZoneOffset, windowValid),
      circadianRBar: _circadianR(n, events, localTimeZoneOffset, windowValid),
    );
  }

  TemporalShadowDyadicFeatures _dyadicFeatures({
    required String participantP,
    required String participantQ,
    required List<TemporalShadowEvent> ordered,
    required TemporalShadowUserFeatures userP,
    required TemporalShadowUserFeatures userQ,
    required double windowSeconds,
    required bool windowValid,
    required Duration replyTimeout,
  }) {
    final nP = userP.eventCount;
    final nQ = userQ.eventCount;
    final nTot = nP + nQ;

    final gapsPFromQ = <double>[];
    final gapsQFromP = <double>[];
    final turnGaps = <double>[];
    final timeoutSec = replyTimeout.inMilliseconds / 1000.0;

    for (var i = 1; i < ordered.length; i++) {
      final prev = ordered[i - 1];
      final cur = ordered[i];
      if (prev.senderId == cur.senderId) continue;
      final g = (cur.timestampMs - prev.timestampMs) / 1000.0;
      if (g <= 0 || g > timeoutSec) continue;
      turnGaps.add(g);
      if (cur.senderId == participantP && prev.senderId == participantQ) {
        gapsPFromQ.add(g);
      } else if (cur.senderId == participantQ &&
          prev.senderId == participantP) {
        gapsQFromP.add(g);
      }
    }

    return TemporalShadowDyadicFeatures(
      eventCountP: nP,
      eventCountQ: nQ,
      eventCountTotal: nTot,
      participationShareP: _participationShare(nP, nTot, windowValid),
      dyadicParticipationBalance: _participationBalance(nP, nTot, windowValid),
      medianReplyGapPFromQSeconds:
          _gapMedian(gapsPFromQ, windowSeconds, windowValid),
      medianReplyGapQFromPSeconds:
          _gapMedian(gapsQFromP, windowSeconds, windowValid),
      medianTurnGapSeconds: _gapMedian(turnGaps, windowSeconds, windowValid),
      replyGapCountPFromQ: gapsPFromQ.length,
      replyGapCountQFromP: gapsQFromP.length,
      turnGapCount: turnGaps.length,
      circadianDeltaTheta: _deltaTheta(userP, userQ),
    );
  }

  static GatedDouble _cadenceMean(
    int n,
    double windowSeconds,
    bool windowValid,
  ) {
    if (!windowValid || n == 0 || windowSeconds < _days(1)) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final value = n / windowSeconds;
    if (n >= 5 && windowSeconds >= _days(3)) {
      return GatedDouble(status: TemporalFeatureStatus.ok, value: value);
    }
    return GatedDouble(status: TemporalFeatureStatus.sparse, value: value);
  }

  static GatedDouble _cadenceMedian(
    int n,
    List<double> intervals,
    double windowSeconds,
    bool windowValid,
  ) {
    if (!windowValid || intervals.isEmpty) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final med = _median(intervals);
    if (med <= 0) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final value = 1.0 / med;
    if (n >= 5 && intervals.length >= 4 && windowSeconds >= _days(3)) {
      return GatedDouble(status: TemporalFeatureStatus.ok, value: value);
    }
    return GatedDouble(status: TemporalFeatureStatus.sparse, value: value);
  }

  static GatedDouble _burstiness(
    List<double> intervals,
    double windowSeconds,
    bool windowValid,
  ) {
    if (!windowValid || intervals.length < 3) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final m = _mean(intervals);
    final s = _sampleStdev(intervals);
    if (m + s == 0) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final value = (s - m) / (s + m);
    if (intervals.length >= 5 && windowSeconds >= _days(7)) {
      return GatedDouble(status: TemporalFeatureStatus.ok, value: value);
    }
    if (intervals.length >= 3) {
      return GatedDouble(status: TemporalFeatureStatus.sparse, value: value);
    }
    return const GatedDouble(status: TemporalFeatureStatus.unavailable);
  }

  static GatedDouble _regularity(
    List<double> intervals,
    double windowSeconds,
    bool windowValid,
  ) {
    if (!windowValid || intervals.length < 3) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final m = _mean(intervals);
    if (m <= 0) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final s = _sampleStdev(intervals);
    final cv = s / m;
    final value = 1.0 / (1.0 + cv);
    if (intervals.length >= 5 && windowSeconds >= _days(7)) {
      return GatedDouble(status: TemporalFeatureStatus.ok, value: value);
    }
    return GatedDouble(status: TemporalFeatureStatus.sparse, value: value);
  }

  static GatedDouble _participationShare(int nP, int nTot, bool windowValid) {
    if (!windowValid || nTot < 2) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final value = nP / nTot;
    if (nTot >= 10) {
      return GatedDouble(status: TemporalFeatureStatus.ok, value: value);
    }
    return GatedDouble(status: TemporalFeatureStatus.sparse, value: value);
  }

  static GatedDouble _participationBalance(int nP, int nTot, bool windowValid) {
    final share = _participationShare(nP, nTot, windowValid);
    if (share.status == TemporalFeatureStatus.unavailable ||
        share.value == null) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final value = 1.0 - 2.0 * (share.value! - 0.5).abs();
    return GatedDouble(status: share.status, value: value);
  }

  static GatedDouble _gapMedian(
    List<double> gaps,
    double windowSeconds,
    bool windowValid,
  ) {
    if (!windowValid || gaps.length < 3) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final value = _median(gaps);
    if (gaps.length >= 8 && windowSeconds >= _days(7)) {
      return GatedDouble(status: TemporalFeatureStatus.ok, value: value);
    }
    return GatedDouble(status: TemporalFeatureStatus.sparse, value: value);
  }

  static GatedDouble _hourStatus(
    int n,
    List<TemporalShadowEvent> events,
    Duration? tz,
    bool windowValid,
  ) {
    if (!windowValid || tz == null || n < 5) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final days = _distinctLocalDays(events, tz);
    if (n >= 10 && days >= 3) {
      return const GatedDouble(status: TemporalFeatureStatus.ok);
    }
    return const GatedDouble(status: TemporalFeatureStatus.sparse);
  }

  static List<double>? _hourHistogram(
    int n,
    List<TemporalShadowEvent> events,
    Duration? tz,
    bool windowValid,
  ) {
    final status = _hourStatus(n, events, tz, windowValid);
    if (status.status == TemporalFeatureStatus.unavailable || n == 0) {
      return null;
    }
    final counts = List<int>.filled(24, 0);
    for (final e in events) {
      counts[_localHour(e.timestampMs, tz!)]++;
    }
    return [for (final c in counts) c / n];
  }

  static ({double? theta, double? r, TemporalFeatureStatus status})
      _circadianStats(
    int n,
    List<TemporalShadowEvent> events,
    Duration? tz,
    bool windowValid,
  ) {
    if (!windowValid || tz == null || n < 5) {
      return (
        theta: null,
        r: null,
        status: TemporalFeatureStatus.unavailable,
      );
    }
    final days = _distinctLocalDays(events, tz);
    var c = 0.0;
    var s = 0.0;
    for (final e in events) {
      final theta = _localTheta(e.timestampMs, tz);
      c += math.cos(theta);
      s += math.sin(theta);
    }
    c /= n;
    s /= n;
    final r = math.sqrt(c * c + s * s);
    final theta = math.atan2(s, c);

    final hist = _hourStatus(n, events, tz, windowValid);
    if (hist.status == TemporalFeatureStatus.unavailable || r < 0.20) {
      return (
        theta: null,
        r: null,
        status: TemporalFeatureStatus.unavailable,
      );
    }
    if (hist.status == TemporalFeatureStatus.ok &&
        r >= TemporalShadowExtractorContract.circadianOkR &&
        days >= 4) {
      return (theta: theta, r: r, status: TemporalFeatureStatus.ok);
    }
    if (r >= TemporalShadowExtractorContract.circadianSparseR) {
      return (theta: theta, r: r, status: TemporalFeatureStatus.sparse);
    }
    return (
      theta: null,
      r: null,
      status: TemporalFeatureStatus.unavailable,
    );
  }

  static GatedDouble _circadianTheta(
    int n,
    List<TemporalShadowEvent> events,
    Duration? tz,
    bool windowValid,
  ) {
    final st = _circadianStats(n, events, tz, windowValid);
    return GatedDouble(status: st.status, value: st.theta);
  }

  static GatedDouble _circadianR(
    int n,
    List<TemporalShadowEvent> events,
    Duration? tz,
    bool windowValid,
  ) {
    final st = _circadianStats(n, events, tz, windowValid);
    return GatedDouble(status: st.status, value: st.r);
  }

  static GatedDouble _deltaTheta(
    TemporalShadowUserFeatures p,
    TemporalShadowUserFeatures q,
  ) {
    if (p.circadianThetaBar.status == TemporalFeatureStatus.unavailable ||
        q.circadianThetaBar.status == TemporalFeatureStatus.unavailable ||
        p.circadianThetaBar.value == null ||
        q.circadianThetaBar.value == null) {
      return const GatedDouble(status: TemporalFeatureStatus.unavailable);
    }
    final raw = p.circadianThetaBar.value! - q.circadianThetaBar.value!;
    final wrapped = _wrapPi(raw);
    final status =
        (p.circadianThetaBar.status == TemporalFeatureStatus.ok &&
                q.circadianThetaBar.status == TemporalFeatureStatus.ok)
            ? TemporalFeatureStatus.ok
            : TemporalFeatureStatus.sparse;
    return GatedDouble(status: status, value: wrapped);
  }

  static double _days(int d) =>
      Duration(days: d).inMilliseconds / 1000.0;

  static double _mean(List<double> xs) =>
      xs.reduce((a, b) => a + b) / xs.length;

  static double _sampleStdev(List<double> xs) {
    if (xs.length < 2) return 0.0;
    final m = _mean(xs);
    var acc = 0.0;
    for (final x in xs) {
      final d = x - m;
      acc += d * d;
    }
    return math.sqrt(acc / (xs.length - 1));
  }

  static double _median(List<double> xs) {
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    if (s.length.isOdd) return s[mid];
    return 0.5 * (s[mid - 1] + s[mid]);
  }

  static int _localHour(int timestampMs, Duration tz) {
    final local = DateTime.fromMillisecondsSinceEpoch(
      timestampMs,
      isUtc: true,
    ).add(tz);
    return local.hour;
  }

  static double _localTheta(int timestampMs, Duration tz) {
    final local = DateTime.fromMillisecondsSinceEpoch(
      timestampMs,
      isUtc: true,
    ).add(tz);
    final tau = Duration(
      hours: local.hour,
      minutes: local.minute,
      seconds: local.second,
      milliseconds: local.millisecond,
    ).inMilliseconds /
        1000.0;
    return 2 * math.pi * (tau / 86400.0);
  }

  static int _distinctLocalDays(
    List<TemporalShadowEvent> events,
    Duration tz,
  ) {
    final days = <String>{};
    for (final e in events) {
      final local = DateTime.fromMillisecondsSinceEpoch(
        e.timestampMs,
        isUtc: true,
      ).add(tz);
      days.add(
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}',
      );
    }
    return days.length;
  }

  static double _wrapPi(double x) {
    var v = x;
    while (v <= -math.pi) {
      v += 2 * math.pi;
    }
    while (v > math.pi) {
      v -= 2 * math.pi;
    }
    return v;
  }
}
