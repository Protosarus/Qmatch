import 'dart:math' as math;

import 'activity_spectral_omega_estimator_contract.dart';
import 'activity_spectral_omega_estimator_models.dart';

/// Shadow-only binned activity periodogram omega estimator v1.
///
/// Global activity timestamps only. Accepts \(T^\star\) iff provisional gates pass,
/// then \(\omega=2\pi/T^\star\). No cadence fallback, no Frequency-mode attach.
/// Near-24h / near-7d → [ActivitySpectralOmegaStatus.civilCollision] (no Class B ω).
class ActivitySpectralOmegaEstimator {
  const ActivitySpectralOmegaEstimator();

  ActivitySpectralOmegaEstimate estimate({
    required List<int> timestamps,
    required int windowStartMs,
    required int windowEndMs,
  }) {
    final windowSeconds = (windowEndMs - windowStartMs) / 1000.0;
    final binWidthSeconds =
        ActivitySpectralOmegaEstimatorContract.binWidth.inMilliseconds / 1000.0;

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
    if (windowSeconds <
        ActivitySpectralOmegaEstimatorContract.minWindowSparse.inMilliseconds /
            1000.0) {
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
          windowSeconds <
              ActivitySpectralOmegaEstimatorContract.minWindowOk.inMilliseconds /
                  1000.0;
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

    final resolved = _resolvePeriod(primary);
    final selected = resolved.peak ?? primary.peaks.first;
    final tStar = selected.periodSeconds;
    final snr = selected.snr;

    // Civil collisions are never Class B omega (priority over harmonic/compete).
    // Prefer an explicit near-civil peak in the same harmonic family when present.
    final civilHit = _familyCivilCollision(selected, primary.peaks);
    if (civilHit != null) {
      return _result(
        status: ActivitySpectralOmegaStatus.civilCollision,
        reason: ActivitySpectralOmegaEstimatorContract.reasonCivilCollision,
        eventCount: n,
        windowSeconds: windowSeconds,
        binWidthSeconds: binWidthSeconds,
        periodSeconds: civilHit.peak.periodSeconds,
        omega: null,
        snr: civilHit.peak.snr,
        peaks: primary.peaks,
        collision: (near: true, kind: civilHit.kind),
      );
    }
    final collision = const (near: false, kind: null);

    if (resolved.kind == _ResolveKind.competing) {
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
    if (resolved.kind == _ResolveKind.harmonicAmbiguous) {
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

    // Split-half stability on resolved periods.
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
    final firstResolved =
        first != null && first.peaks.isNotEmpty ? _resolvePeriod(first) : null;
    final secondResolved =
        second != null && second.peaks.isNotEmpty ? _resolvePeriod(second) : null;
    if (firstResolved != null &&
        firstResolved.peak != null &&
        secondResolved != null &&
        secondResolved.peak != null) {
      final t1 = firstResolved.peak!.periodSeconds;
      final t2 = secondResolved.peak!.periodSeconds;
      splitDelta = _isHarmonicRelated(t1, t2) ? 0.0 : _relativeDelta(t1, t2);
      if (splitDelta >
          ActivitySpectralOmegaEstimatorContract.splitHalfRelativeTolerance) {
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

    // Bin-size sensitivity: recover the same \(T^\star\) (or harmonic family) under 2h bins.
    final alt = _analyze(
      timestamps: inWindow,
      windowStartMs: windowStartMs,
      windowEndMs: windowEndMs,
      binWidth: ActivitySpectralOmegaEstimatorContract.sensitivityBinWidth,
    );
    double? binDelta;
    if (alt != null && alt.peaks.isNotEmpty) {
      final altNear = _nearestFamilyPeak(alt.peaks, tStar);
      if (altNear == null) {
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
          binDelta: 1.0,
          peaks: primary.peaks,
          collision: collision,
        );
      }
      binDelta = _isHarmonicRelated(tStar, altNear.periodSeconds)
          ? 0.0
          : _relativeDelta(tStar, altNear.periodSeconds);
      if (binDelta >
          ActivitySpectralOmegaEstimatorContract
              .binSensitivityRelativeTolerance) {
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

    final volumeOk = n >= ActivitySpectralOmegaEstimatorContract.minEventsOk &&
        windowSeconds >=
            ActivitySpectralOmegaEstimatorContract.minWindowOk.inMilliseconds /
                1000.0;

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
        reason: snr < ActivitySpectralOmegaEstimatorContract.snrOk
            ? ActivitySpectralOmegaEstimatorContract.reasonLowSnr
            : ActivitySpectralOmegaEstimatorContract.reasonInsufficientEvents,
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

  /// Resolve \(T^\star\) from ranked peaks: harmonic families + competing gate.
  ///
  /// Does **not** auto-prefer the strongest harmonic. Prefers the fundamental
  /// (longest period in a T/T/2/T/3 family) only when SNR support is consistent.
  /// Probes 2T/3T on the periodogram so a missing local peak at the fundamental
  /// still participates. If a longer parent exists without support → ambiguous.
  static _ResolvedPeriod _resolvePeriod(_Spectrum spectrum) {
    final peaks = spectrum.peaks;
    if (peaks.isEmpty) {
      return const _ResolvedPeriod(kind: _ResolveKind.harmonicAmbiguous);
    }

    final strong = [
      for (final p in peaks)
        if (p.snr >= ActivitySpectralOmegaEstimatorContract.competingPeakSnrMin)
          p,
    ];
    final competePool = strong.isNotEmpty ? strong : [peaks.first];
    final families = _clusterHarmonicFamilies(competePool);
    if (families.length >= 2 && _hasCompetingFamilies(families)) {
      ActivitySpectralPeakCandidate? lead;
      for (final p in competePool) {
        if (lead == null || p.snr > lead.snr) lead = p;
      }
      return _ResolvedPeriod(kind: _ResolveKind.competing, peak: lead);
    }

    ActivitySpectralPeakCandidate? strongest;
    for (final p in peaks) {
      if (strongest == null || p.snr > strongest.snr) strongest = p;
    }

    final augmented = [
      ...peaks,
      ..._harmonicParentProbes(spectrum, strongest!),
    ];
    final allFamilies = _clusterHarmonicFamilies(augmented);
    final family = allFamilies.firstWhere(
      (f) => f.contains(strongest),
      orElse: () => [strongest!],
    );

    ActivitySpectralPeakCandidate fund = family.first;
    for (final p in family) {
      if (p.periodSeconds > fund.periodSeconds) fund = p;
    }
    ActivitySpectralPeakCandidate familyStrongest = family.first;
    for (final p in family) {
      if (p.snr > familyStrongest.snr) familyStrongest = p;
    }

    final hasLongerParent = fund.periodSeconds >
        familyStrongest.periodSeconds *
            (1.0 +
                ActivitySpectralOmegaEstimatorContract.harmonicRatioTolerance *
                    0.5);

    // Consistent support: absolute ok-SNR on fundamental OR relative to child.
    final supportOk = fund.snr >= ActivitySpectralOmegaEstimatorContract.snrOk ||
        fund.snr >=
            familyStrongest.snr /
                ActivitySpectralOmegaEstimatorContract
                    .fundamentalSupportSnrRatio;

    if (hasLongerParent && !supportOk) {
      return _ResolvedPeriod(
        kind: _ResolveKind.harmonicAmbiguous,
        peak: fund,
      );
    }
    if (!supportOk) {
      return _ResolvedPeriod(
        kind: _ResolveKind.harmonicAmbiguous,
        peak: fund,
      );
    }
    return _ResolvedPeriod(kind: _ResolveKind.ok, peak: fund);
  }

  /// Look up periodogram SNR at 2T and 3T of [child] (fundamental probes).
  static List<ActivitySpectralPeakCandidate> _harmonicParentProbes(
    _Spectrum spectrum,
    ActivitySpectralPeakCandidate child,
  ) {
    final out = <ActivitySpectralPeakCandidate>[];
    for (final mult in [2, 3]) {
      final target = child.periodSeconds * mult;
      if (target >
          ActivitySpectralOmegaEstimatorContract.maxPeriodCap.inMilliseconds /
              1000.0) {
        continue;
      }
      var bestIdx = -1;
      var bestDist = double.infinity;
      for (var i = 0; i < spectrum.periods.length; i++) {
        final d = (spectrum.periods[i] - target).abs() / target;
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      if (bestIdx < 0 ||
          bestDist >
              ActivitySpectralOmegaEstimatorContract.harmonicRatioTolerance) {
        continue;
      }
      final snr = _snr(spectrum.powers, bestIdx, spectrum.periods);
      if (snr < ActivitySpectralOmegaEstimatorContract.snrSparse) continue;
      out.add(
        ActivitySpectralPeakCandidate(
          periodSeconds: spectrum.periods[bestIdx],
          power: spectrum.powers[bestIdx],
          snr: snr,
        ),
      );
    }
    return out;
  }

  static List<List<ActivitySpectralPeakCandidate>> _clusterHarmonicFamilies(
    List<ActivitySpectralPeakCandidate> peaks,
  ) {
    final families = <List<ActivitySpectralPeakCandidate>>[];
    for (final p in peaks) {
      var placed = false;
      for (final f in families) {
        if (f.any((q) => _isHarmonicRelated(p.periodSeconds, q.periodSeconds))) {
          f.add(p);
          placed = true;
          break;
        }
      }
      if (!placed) families.add([p]);
    }
    // Merge families that became transitively related (e.g. T/2 and T/3).
    var changed = true;
    while (changed) {
      changed = false;
      for (var i = 0; i < families.length; i++) {
        for (var j = i + 1; j < families.length; j++) {
          final related = families[i].any(
            (a) => families[j].any(
              (b) => _isHarmonicRelated(a.periodSeconds, b.periodSeconds),
            ),
          );
          if (related) {
            families[i].addAll(families[j]);
            families.removeAt(j);
            changed = true;
            break;
          }
        }
        if (changed) break;
      }
    }
    return families;
  }

  /// True when ≥2 families each have a peak that is prominence-competitive.
  static bool _hasCompetingFamilies(
    List<List<ActivitySpectralPeakCandidate>> families,
  ) {
    if (families.length < 2) return false;
    final leaders = <ActivitySpectralPeakCandidate>[];
    for (final f in families) {
      var best = f.first;
      for (final p in f) {
        if (p.snr > best.snr) best = p;
      }
      leaders.add(best);
    }
    leaders.sort((a, b) => b.snr.compareTo(a.snr));
    final primary = leaders.first;
    for (var i = 1; i < leaders.length; i++) {
      final secondary = leaders[i];
      if (secondary.snr <
          ActivitySpectralOmegaEstimatorContract.competingPeakSnrMin) {
        continue;
      }
      final snrRatio = primary.snr / math.max(secondary.snr, 1e-12);
      if (snrRatio <=
          ActivitySpectralOmegaEstimatorContract.competingProminenceSnrRatio) {
        return true;
      }
    }
    return false;
  }

  /// Nearest peak to [target] within relative tolerance or T/T/2/T/3 family.
  static ActivitySpectralPeakCandidate? _nearestFamilyPeak(
    List<ActivitySpectralPeakCandidate> peaks,
    double target,
  ) {
    ActivitySpectralPeakCandidate? best;
    var bestScore = double.infinity;
    for (final p in peaks) {
      final rel = _relativeDelta(p.periodSeconds, target);
      final related = _isHarmonicRelated(p.periodSeconds, target);
      if (!related &&
          rel >
              ActivitySpectralOmegaEstimatorContract
                  .binSensitivityRelativeTolerance) {
        continue;
      }
      final score = related ? 0.0 : rel;
      if (score < bestScore) {
        bestScore = score;
        best = p;
      }
    }
    return best;
  }

  /// If [selected] or a same-family peak is near 24h/7d, return that peak.
  static ({ActivitySpectralPeakCandidate peak, String kind})?
      _familyCivilCollision(
    ActivitySpectralPeakCandidate selected,
    List<ActivitySpectralPeakCandidate> peaks,
  ) {
    ActivitySpectralPeakCandidate? best;
    String? kind;
    void consider(ActivitySpectralPeakCandidate p) {
      final c = _civilCollision(p.periodSeconds);
      if (!c.near) return;
      if (best == null || p.snr > best!.snr) {
        best = p;
        kind = c.kind;
      }
    }

    consider(selected);
    for (final p in peaks) {
      if (_isHarmonicRelated(p.periodSeconds, selected.periodSeconds) ||
          _relativeDelta(p.periodSeconds, selected.periodSeconds) <=
              ActivitySpectralOmegaEstimatorContract
                  .civilCollisionRelativeTolerance) {
        consider(p);
      }
    }
    if (best == null || kind == null) return null;
    return (peak: best!, kind: kind!);
  }

  /// Related if period ratio ≈ 2 or 3 (T ↔ T/2 ↔ T/3).
  static bool _isHarmonicRelated(double a, double b) {
    final hi = math.max(a, b);
    final lo = math.min(a, b);
    if (lo <= 1e-12) return false;
    final ratio = hi / lo;
    final tol = ActivitySpectralOmegaEstimatorContract.harmonicRatioTolerance;
    return (ratio - 2.0).abs() <= tol || (ratio - 3.0).abs() <= tol;
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

    final tMin = math.max(
      2 * deltaSec,
      ActivitySpectralOmegaEstimatorContract.minPeriodFloor.inMilliseconds /
          1000.0,
    );
    final tMax = math.min(
      windowSeconds / ActivitySpectralOmegaEstimatorContract.minCyclesOk,
      ActivitySpectralOmegaEstimatorContract.maxPeriodCap.inMilliseconds /
          1000.0,
    );
    if (tMax <= tMin) return null;

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

    final top = peaks.take(5).toList(growable: false);
    return _Spectrum(
      peaks: top,
      periods: List<double>.unmodifiable(periods),
      powers: List<double>.unmodifiable(powers),
    );
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
      if ((r - 1.0).abs() < 0.12 ||
          (r - 0.5).abs() < 0.12 ||
          (r - 2.0).abs() < 0.12 ||
          (r - 1.0 / 3.0).abs() < 0.12 ||
          (r - 3.0).abs() < 0.12 ||
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

  static ({bool near, String? kind}) _civilCollision(double periodSeconds) {
    final day =
        ActivitySpectralOmegaEstimatorContract.civilDay.inMilliseconds / 1000.0;
    final week =
        ActivitySpectralOmegaEstimatorContract.civilWeek.inMilliseconds / 1000.0;
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

enum _ResolveKind { ok, competing, harmonicAmbiguous }

class _ResolvedPeriod {
  const _ResolvedPeriod({required this.kind, this.peak});
  final _ResolveKind kind;
  final ActivitySpectralPeakCandidate? peak;
}

class _Spectrum {
  const _Spectrum({
    required this.peaks,
    required this.periods,
    required this.powers,
  });
  final List<ActivitySpectralPeakCandidate> peaks;
  final List<double> periods;
  final List<double> powers;
}
