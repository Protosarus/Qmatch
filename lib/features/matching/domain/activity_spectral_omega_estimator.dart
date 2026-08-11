import 'dart:math' as math;

import 'activity_spectral_omega_estimator_contract.dart';
import 'activity_spectral_omega_estimator_models.dart';

/// Shadow-only binned activity periodogram omega estimator v1.
///
/// Global activity timestamps only. Accepts \(T^\star\) iff provisional gates pass,
/// then \(\omega=2\pi/T^\star\). No cadence fallback, no Frequency-mode attach.
class ActivitySpectralOmegaEstimator {
  const ActivitySpectralOmegaEstimator();

  ActivitySpectralOmegaEstimate estimate({
    required List<int> timestamps,
    required int windowStartMs,
    required int windowEndMs,
  }) {
    final windowSeconds = (windowEndMs - windowStartMs) / 1000.0;
    final binWidthSeconds = ActivitySpectralOmegaEstimatorContract.binWidth.inMilliseconds / 1000.0;

    if (windowEndMs <= windowStartMs || windowSeconds <= 0) {
      return _empty(
        status: ActivitySpectralOmegaStatus.unavailable,
        reason: ActivitySpectralOmegaEstimatorContract.reasonInvalidWindow,
        eventCount: timestamps.length,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
      );
    }

    final inWindow = [
      for (final t in timestamps)
        if (t >= windowStartMs && t <= windowEndMs) t,
    ]..sort();

    final n = inWindow.length;
    if (n == 0) {
      return _empty(
        status: ActivitySpectralOmegaStatus.unavailable,
        reason: ActivitySpectralOmegaEstimatorContract.reasonEmptyTimestamps,
        eventCount: 0,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
      );
    }
    if (n < ActivitySpectralOmegaEstimatorContract.minEventsSparse) {
      return _empty(
        status: ActivitySpectralOmegaStatus.unavailable,
        reason: ActivitySpectralOmegaEstimatorContract.reasonInsufficientEvents,
        eventCount: n,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
      );
    }
    if (windowSeconds < ActivitySpectralOmegaEstimatorContract.minWindowSparse.inMilliseconds / 1000.0) {
      return _empty(
        status: ActivitySpectralOmegaStatus.unavailable,
        reason: ActivitySpectralOmegaEstimatorContract.reasonInsufficientWindow,
        eventCount: n,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
      );
    }

    final primary = _analyze(
      timestamps: inWindow,
      windowStartMs: windowStartMs,
      windowEndMs: windowEndMs,
      binWidth: ActivitySpectralOmegaEstimatorContract.binWidth,
    );
    if (primary == null || primary.peaks.isEmpty) {
      final sparseVolume = n < ActivitySpectralOmegaEstimatorContract.minEventsOk ||
          windowSeconds < ActivitySpectralOmegaEstimatorContract.minWindowOk.inMilliseconds / 1000.0;
      return _empty(
        status: sparseVolume
            ? ActivitySpectralOmegaStatus.sparse
            : ActivitySpectralOmegaStatus.unavailable,
        reason: ActivitySpectralOmegaEstimatorContract.reasonNoAdmissiblePeak,
        eventCount: n,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
      );
    }

    final top = primary.peaks.first;
    final tStar = top.periodSeconds;
    final snr = top.snr;

    // Civil collision flag (does not by itself reject).
    final collision = _civilCollision(tStar);

    // Volume / SNR / cycles gates.
    final cycles = windowSeconds / tStar;
    if (cycles < ActivitySpectralOmegaEstimatorContract.minCyclesOk) {
      return _result(
        status: ActivitySpectralOmegaStatus.unavailable,
        reason: ActivitySpectralOmegaEstimatorContract.reasonInsufficientCycles,
        eventCount: n,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
        periodSeconds: tStar,
        omega: null,
        snr: snr,
        peaks: primary.peaks,
        collision: collision,
      );
    }

    // Harmonic ambiguity among strong peaks.
    if (_harmonicAmbiguity(primary.peaks)) {
      return _result(
        status: ActivitySpectralOmegaStatus.ambiguous,
        reason: ActivitySpectralOmegaEstimatorContract.reasonHarmonicAmbiguity,
        eventCount: n,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
        periodSeconds: tStar,
        omega: null,
        snr: snr,
        peaks: primary.peaks,
        collision: collision,
      );
    }

    // Multiple non-harmonic competing peaks at ok SNR.
    if (_multipleCompetingPeaks(primary.peaks)) {
      return _result(
        status: ActivitySpectralOmegaStatus.ambiguous,
        reason: ActivitySpectralOmegaEstimatorContract.reasonMultiplePeaks,
        eventCount: n,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
        periodSeconds: tStar,
        omega: null,
        snr: snr,
        peaks: primary.peaks,
        collision: collision,
      );
    }

    // Split-half stability.
    final mid = windowStartMs + ((windowEndMs - windowStartMs) ~/ 2);
    final first = _analyze(
      timestamps: inWindow,
      windowStartMs: windowStartMs,
      windowEndMs: mid,
      binWidth: ActivitySpectralOmegaEstimatorContract.binWidth,
    );
    final second = _analyze(
      timestamps: inWindow,
      windowStartMs: mid,
      windowEndMs: windowEndMs,
      binWidth: ActivitySpectralOmegaEstimatorContract.binWidth,
    );
    double? splitDelta;
    if (first != null &&
        first.peaks.isNotEmpty &&
        second != null &&
        second.peaks.isNotEmpty) {
      splitDelta = _relativeDelta(
        first.peaks.first.periodSeconds,
        second.peaks.first.periodSeconds,
      );
      if (splitDelta > ActivitySpectralOmegaEstimatorContract.splitHalfRelativeTolerance) {
        return _result(
          status: ActivitySpectralOmegaStatus.ambiguous,
          reason: ActivitySpectralOmegaEstimatorContract.reasonSplitHalfUnstable,
          eventCount: n,
          windowSeconds: windowSeconds,
          binWidthSeconds: binWidthSeconds,
          periodSeconds: tStar,
          omega: null,
          snr: snr,
          splitDelta: splitDelta,
          peaks: primary.peaks,
          collision: collision,
        );
      }
    } else {
      // Cannot verify stability → not ok.
      return _result(
        status: ActivitySpectralOmegaStatus.ambiguous,
        reason: ActivitySpectralOmegaEstimatorContract.reasonSplitHalfUnstable,
        eventCount: n,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
        periodSeconds: tStar,
        omega: null,
        snr: snr,
        peaks: primary.peaks,
        collision: collision,
      );
    }

    // Bin-size sensitivity (1h vs 2h).
    final alt = _analyze(
      timestamps: inWindow,
      windowStartMs: windowStartMs,
      windowEndMs: windowEndMs,
      binWidth: ActivitySpectralOmegaEstimatorContract.sensitivityBinWidth,
    );
    double? binDelta;
    if (alt != null && alt.peaks.isNotEmpty) {
      binDelta = _relativeDelta(tStar, alt.peaks.first.periodSeconds);
      if (binDelta > ActivitySpectralOmegaEstimatorContract.binSensitivityRelativeTolerance) {
        return _result(
          status: ActivitySpectralOmegaStatus.ambiguous,
          reason: ActivitySpectralOmegaEstimatorContract.reasonBinSensitivity,
          eventCount: n,
          windowSeconds: windowSeconds,
          binWidthSeconds: binWidthSeconds,
          periodSeconds: tStar,
          omega: null,
          snr: snr,
          splitDelta: splitDelta,
          binDelta: binDelta,
          peaks: primary.peaks,
          collision: collision,
        );
      }
    }

    // SNR / volume classification.
    final volumeOk = n >= ActivitySpectralOmegaEstimatorContract.minEventsOk &&
        windowSeconds >= ActivitySpectralOmegaEstimatorContract.minWindowOk.inMilliseconds / 1000.0;

    if (snr >= ActivitySpectralOmegaEstimatorContract.snrOk && volumeOk) {
      final omega = 2 * math.pi / tStar;
      final oscId =
          '${ActivitySpectralOmegaEstimatorContract.oscillatorIdPrefix}_${ActivitySpectralOmegaEstimatorContract.streamId}_t${tStar.round()}s';
      return _result(
        status: ActivitySpectralOmegaStatus.ok,
        reason: null,
        eventCount: n,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
        periodSeconds: tStar,
        omega: omega,
        snr: snr,
        splitDelta: splitDelta,
        binDelta: binDelta,
        peaks: primary.peaks,
        collision: collision,
        oscillatorId: oscId,
      );
    }

    if (snr >= ActivitySpectralOmegaEstimatorContract.snrSparse || !volumeOk) {
      return _result(
        status: ActivitySpectralOmegaStatus.sparse,
        reason: snr < ActivitySpectralOmegaEstimatorContract.snrOk ? ActivitySpectralOmegaEstimatorContract.reasonLowSnr : ActivitySpectralOmegaEstimatorContract.reasonInsufficientEvents,
        eventCount: n,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
        periodSeconds: tStar,
        omega: null,
        snr: snr,
        splitDelta: splitDelta,
        binDelta: binDelta,
        peaks: primary.peaks,
        collision: collision,
      );
    }

    return _result(
      status: ActivitySpectralOmegaStatus.unavailable,
      reason: ActivitySpectralOmegaEstimatorContract.reasonLowSnr,
      eventCount: n,
      windowSeconds: windowSeconds,
      binWidthSeconds: binWidthSeconds,
      periodSeconds: tStar,
      omega: null,
      snr: snr,
      splitDelta: splitDelta,
      binDelta: binDelta,
      peaks: primary.peaks,
      collision: collision,
    );
  }

  _Spectrum? _analyze({
    required List<int> timestamps,
    required int windowStartMs,
    required int windowEndMs,
    required Duration binWidth,
  }) {
    final windowSeconds = (windowEndMs - windowStartMs) / 1000.0;
    if (windowSeconds <= 0) return null;

    final deltaSec = binWidth.inMilliseconds / 1000.0;
    final bins = _binCounts(
      timestamps: timestamps,
      windowStartMs: windowStartMs,
      windowEndMs: windowEndMs,
      binWidthMs: binWidth.inMilliseconds,
    );
    if (bins.length < 4) return null;

    final mean = bins.reduce((a, b) => a + b) / bins.length;
    final x = [for (final v in bins) v - mean];

    final tMin = math.max(2 * deltaSec, ActivitySpectralOmegaEstimatorContract.minPeriodFloor.inMilliseconds / 1000.0);
    final tMax = math.min(
      windowSeconds / ActivitySpectralOmegaEstimatorContract.minCyclesOk,
      ActivitySpectralOmegaEstimatorContract.maxPeriodCap.inMilliseconds / 1000.0,
    );
    if (tMax <= tMin) return null;

    // Period grid: denser at short periods.
    final periods = <double>[];
    var t = tMin;
    while (t <= tMax) {
      periods.add(t);
      final step = math.max(deltaSec / 4.0, t * 0.01);
      t += step;
    }

    final powers = <double>[];
    for (final period in periods) {
      powers.add(_periodogramPower(x, deltaSec, period));
    }
    if (powers.isEmpty) return null;

    final peaks = <ActivitySpectralPeakCandidate>[];
    for (var i = 1; i < powers.length - 1; i++) {
      if (powers[i] >= powers[i - 1] && powers[i] > powers[i + 1]) {
        final snr = _snr(powers, i, periods);
        peaks.add(
          ActivitySpectralPeakCandidate(
            periodSeconds: periods[i],
            power: powers[i],
            snr: snr,
          ),
        );
      }
    }
    peaks.sort((a, b) => b.power.compareTo(a.power));

    // Keep top few for diagnostics.
    final top = peaks.take(5).toList(growable: false);
    return _Spectrum(peaks: top);
  }

  static List<double> _binCounts({
    required List<int> timestamps,
    required int windowStartMs,
    required int windowEndMs,
    required int binWidthMs,
  }) {
    final span = windowEndMs - windowStartMs;
    final jCount = math.max(1, (span / binWidthMs).ceil());
    final counts = List<double>.filled(jCount, 0.0);
    for (final t in timestamps) {
      if (t < windowStartMs || t > windowEndMs) continue;
      var j = ((t - windowStartMs) / binWidthMs).floor();
      if (j >= jCount) j = jCount - 1;
      if (j < 0) j = 0;
      counts[j] += 1.0;
    }
    return counts;
  }

  static double _periodogramPower(
    List<double> x,
    double deltaSec,
    double periodSec,
  ) {
    var c = 0.0;
    var s = 0.0;
    final w = 2 * math.pi / periodSec;
    for (var j = 0; j < x.length; j++) {
      final t = (j + 0.5) * deltaSec;
      c += x[j] * math.cos(w * t);
      s += x[j] * math.sin(w * t);
    }
    return (c * c + s * s) / x.length;
  }

  static double _snr(List<double> powers, int peakIndex, List<double> periods) {
    final peakPeriod = periods[peakIndex];
    final notch = <int>{};
    for (var i = 0; i < periods.length; i++) {
      final r = periods[i] / peakPeriod;
      // Notch fundamental and low harmonics/subharmonics.
      if ((r - 1.0).abs() < 0.12 ||
          (r - 0.5).abs() < 0.12 ||
          (r - 2.0).abs() < 0.12 ||
          (r - 1.5).abs() < 0.12) {
        notch.add(i);
      }
    }
    final noise = <double>[
      for (var i = 0; i < powers.length; i++)
        if (!notch.contains(i)) powers[i],
    ]..sort();
    if (noise.isEmpty) return 0.0;
    final floor = noise[noise.length ~/ 2];
    if (floor <= 1e-12) {
      return powers[peakIndex] > 0 ? 1e6 : 0.0;
    }
    return powers[peakIndex] / floor;
  }

  static bool _harmonicAmbiguity(List<ActivitySpectralPeakCandidate> peaks) {
    if (peaks.length < 2) return false;
    final a = peaks[0];
    for (var i = 1; i < peaks.length && i < 4; i++) {
      final b = peaks[i];
      if (b.snr < ActivitySpectralOmegaEstimatorContract.snrSparse) continue;
      final ratio = a.periodSeconds / b.periodSeconds;
      final harmonic = (ratio - 2.0).abs() < 0.12 ||
          (ratio - 0.5).abs() < 0.12 ||
          (1 / ratio - 2.0).abs() < 0.12;
      if (!harmonic) continue;
      final snrRatio = a.snr / math.max(b.snr, 1e-12);
      if (snrRatio <= ActivitySpectralOmegaEstimatorContract.harmonicSnrRatio &&
          snrRatio >= 1 / ActivitySpectralOmegaEstimatorContract.harmonicSnrRatio) {
        return true;
      }
    }
    return false;
  }

  static bool _multipleCompetingPeaks(
    List<ActivitySpectralPeakCandidate> peaks,
  ) {
    if (peaks.length < 2) return false;
    final a = peaks[0];
    if (a.snr < ActivitySpectralOmegaEstimatorContract.snrOk) return false;
    for (var i = 1; i < peaks.length && i < 4; i++) {
      final b = peaks[i];
      if (b.snr < ActivitySpectralOmegaEstimatorContract.snrOk) continue;
      final ratio = a.periodSeconds / b.periodSeconds;
      final harmonic = (ratio - 2.0).abs() < 0.12 ||
          (ratio - 0.5).abs() < 0.12 ||
          (ratio - 1.0).abs() < 0.12;
      if (!harmonic) {
        final snrRatio = a.snr / math.max(b.snr, 1e-12);
        if (snrRatio < ActivitySpectralOmegaEstimatorContract.harmonicSnrRatio) {
          return true;
        }
      }
    }
    return false;
  }

  static ({bool near, String? kind}) _civilCollision(double periodSeconds) {
    final day = ActivitySpectralOmegaEstimatorContract.civilDay.inMilliseconds /
        1000.0;
    final week =
        ActivitySpectralOmegaEstimatorContract.civilWeek.inMilliseconds /
            1000.0;
    final tol =
        ActivitySpectralOmegaEstimatorContract.civilCollisionRelativeTolerance;
    if (_relativeDelta(periodSeconds, day) <= tol) {
      return (near: true, kind: 'near_24h');
    }
    if (_relativeDelta(periodSeconds, week) <= tol) {
      return (near: true, kind: 'near_7d');
    }
    return (near: false, kind: null);
  }

  static double _relativeDelta(double a, double b) {
    final scale = math.max(a.abs(), b.abs());
    if (scale <= 1e-12) return 0.0;
    return (a - b).abs() / scale;
  }

  ActivitySpectralOmegaEstimate _empty({
    required ActivitySpectralOmegaStatus status,
    required String reason,
    required int eventCount,
    required double windowSeconds,
    required double binWidthSeconds,
  }) {
    return ActivitySpectralOmegaEstimate(
      status: status,
      reason: reason,
      eventCount: eventCount,
      windowSeconds: windowSeconds,
      binWidthSeconds: binWidthSeconds,
      periodSeconds: null,
      omega: null,
      snr: null,
      splitHalfRelativeDelta: null,
      binSensitivityRelativeDelta: null,
      nearCivilCollision: false,
      civilCollisionKind: null,
      candidatePeaks: const [],
      oscillatorId: null,
    );
  }

  ActivitySpectralOmegaEstimate _result({
    required ActivitySpectralOmegaStatus status,
    required String? reason,
    required int eventCount,
    required double windowSeconds,
    required double binWidthSeconds,
    required double? periodSeconds,
    required double? omega,
    required double? snr,
    double? splitDelta,
    double? binDelta,
    required List<ActivitySpectralPeakCandidate> peaks,
    required ({bool near, String? kind}) collision,
    String? oscillatorId,
  }) {
    return ActivitySpectralOmegaEstimate(
      status: status,
      reason: reason,
      eventCount: eventCount,
      windowSeconds: windowSeconds,
      binWidthSeconds: binWidthSeconds,
      periodSeconds: periodSeconds,
      omega: omega,
      snr: snr,
      splitHalfRelativeDelta: splitDelta,
      binSensitivityRelativeDelta: binDelta,
      nearCivilCollision: collision.near,
      civilCollisionKind: collision.kind,
      candidatePeaks: peaks,
      oscillatorId: oscillatorId,
    );
  }
}

class _Spectrum {
  const _Spectrum({required this.peaks});
  final List<ActivitySpectralPeakCandidate> peaks;
}
