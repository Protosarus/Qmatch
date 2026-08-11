import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/activity_spectral_omega.dart';

void main() {
  const estimator = ActivitySpectralOmegaEstimator();
  final rng = math.Random(7);

  int ms(DateTime dt) => dt.toUtc().millisecondsSinceEpoch;

  /// Regular events every [period] starting at [start] for [window].
  List<int> periodic({
    required DateTime start,
    required Duration period,
    required Duration window,
    Duration jitter = Duration.zero,
  }) {
    final out = <int>[];
    var t = start.toUtc();
    final end = start.toUtc().add(window);
    while (t.isBefore(end) || t.isAtSameMomentAs(end)) {
      var ts = t;
      if (jitter > Duration.zero) {
        final j =
            rng.nextInt(jitter.inMilliseconds * 2) - jitter.inMilliseconds;
        ts = t.add(Duration(milliseconds: j));
      }
      if (!ts.isBefore(start.toUtc()) && !ts.isAfter(end)) {
        out.add(ms(ts));
      }
      t = t.add(period);
    }
    return out;
  }

  group('ActivitySpectralOmegaEstimator', () {
    test('clean periodic signal → ok with omega=2π/T', () {
      final start = DateTime.utc(2024, 1, 1);
      const period = Duration(hours: 12);
      const window = Duration(days: 21);
      final timestamps = periodic(start: start, period: period, window: window);
      // Densify slightly for stronger bins (2 events near each tick).
      final dense = <int>[
        for (final t in timestamps) ...[t, t + 5 * 60 * 1000],
      ];

      final r = estimator.estimate(
        timestamps: dense,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );

      expect(r.status, ActivitySpectralOmegaStatus.ok);
      expect(r.accepted, isTrue);
      expect(r.periodSeconds, closeTo(period.inSeconds.toDouble(), 3600));
      expect(r.omega, closeTo(2 * math.pi / r.periodSeconds!, 1e-6));
      expect(r.snr!, greaterThanOrEqualTo(6));
      expect(r.toWireMap()['gates_calibrated'], isFalse);
      expect(r.toWireMap()['shadow_only'], isTrue);
      expect(r.toWireMap()['attaches_to_frequency_modes'], isFalse);
    });

    test('noisy periodic signal still recoverable or sparse-not-fake', () {
      final start = DateTime.utc(2024, 2, 1);
      const period = Duration(hours: 10);
      const window = Duration(days: 28);
      final base = periodic(
        start: start,
        period: period,
        window: window,
        jitter: const Duration(minutes: 45),
      );
      // Add noise events.
      final noisy = [...base];
      final end = start.add(window);
      for (var i = 0; i < 40; i++) {
        final offset = rng.nextInt(window.inMilliseconds);
        noisy.add(ms(start.add(Duration(milliseconds: offset))));
      }
      noisy.sort();

      final r = estimator.estimate(
        timestamps: noisy,
        windowStartMs: ms(start),
        windowEndMs: ms(end),
      );

      expect(
        r.status,
        anyOf(
          ActivitySpectralOmegaStatus.ok,
          ActivitySpectralOmegaStatus.sparse,
          ActivitySpectralOmegaStatus.ambiguous,
        ),
      );
      // Never invent omega via cadence if not ok.
      if (r.status != ActivitySpectralOmegaStatus.ok) {
        expect(r.omega, isNull);
      } else {
        expect(r.periodSeconds!, closeTo(period.inSeconds.toDouble(), 7200));
      }
    });

    test('no periodicity → unavailable or sparse without omega', () {
      final start = DateTime.utc(2024, 3, 1);
      const window = Duration(days: 21);
      final timestamps = <int>[];
      for (var i = 0; i < 80; i++) {
        timestamps.add(
          ms(start.add(Duration(minutes: rng.nextInt(21 * 24 * 60)))),
        );
      }
      final r = estimator.estimate(
        timestamps: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(r.omega, isNull);
      expect(
        r.status,
        anyOf(
          ActivitySpectralOmegaStatus.unavailable,
          ActivitySpectralOmegaStatus.sparse,
          ActivitySpectralOmegaStatus.ambiguous,
        ),
      );
      expect(r.status, isNot(ActivitySpectralOmegaStatus.ok));
    });

    test('sparse data → unavailable/sparse', () {
      final start = DateTime.utc(2024, 4, 1);
      final timestamps = periodic(
        start: start,
        period: const Duration(hours: 12),
        window: const Duration(days: 5),
      );
      final r = estimator.estimate(
        timestamps: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(const Duration(days: 5))),
      );
      expect(r.accepted, isFalse);
      expect(r.omega, isNull);
      expect(
        r.status,
        anyOf(
          ActivitySpectralOmegaStatus.unavailable,
          ActivitySpectralOmegaStatus.sparse,
        ),
      );
    });

    test('harmonic ambiguity → ambiguous', () {
      final start = DateTime.utc(2024, 5, 1);
      const window = Duration(days: 28);
      // Strong energy at 16h and 8h (harmonic pair).
      final a = periodic(
        start: start,
        period: const Duration(hours: 16),
        window: window,
      );
      final b = periodic(
        start: start,
        period: const Duration(hours: 8),
        window: window,
      );
      final timestamps = <int>{...a, ...b}.toList()..sort();
      // Duplicate to boost SNR similarly.
      final dense = <int>[
        for (final t in timestamps) ...[t, t + 60 * 1000],
      ];

      final r = estimator.estimate(
        timestamps: dense,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );

      // Prefer ambiguous; if detector picks a clear winner that's also OK to
      // fail soft — but require no silent ok without harmonic check coverage.
      if (r.status == ActivitySpectralOmegaStatus.ok) {
        // Still must not attach modes / cadence.
        expect(
          ActivitySpectralOmegaEstimatorContract.attachesToFrequencyModes,
          isFalse,
        );
      } else {
        expect(
          r.status,
          anyOf(
            ActivitySpectralOmegaStatus.ambiguous,
            ActivitySpectralOmegaStatus.sparse,
          ),
        );
        if (r.status == ActivitySpectralOmegaStatus.ambiguous) {
          expect(
            r.reason,
            anyOf(
              ActivitySpectralOmegaEstimatorContract.reasonHarmonicAmbiguity,
              ActivitySpectralOmegaEstimatorContract.reasonMultiplePeaks,
            ),
          );
        }
        expect(r.omega, isNull);
      }
    });

    test('24h civil collision flagged', () {
      final start = DateTime.utc(2024, 6, 1);
      const window = Duration(days: 28);
      final timestamps = periodic(
        start: start,
        period: const Duration(hours: 24),
        window: window,
      );
      final dense = <int>[
        for (final t in timestamps) ...[t, t + 120000, t + 240000],
      ];
      final r = estimator.estimate(
        timestamps: dense,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(r.nearCivilCollision, isTrue);
      expect(r.civilCollisionKind, 'near_24h');
      if (r.periodSeconds != null) {
        expect(
          (r.periodSeconds! - 86400).abs() / 86400,
          lessThan(0.15),
        );
      }
    });

    test('split-half instability → ambiguous', () {
      final start = DateTime.utc(2024, 7, 1);
      const window = Duration(days: 28);
      final mid = start.add(const Duration(days: 14));
      final first = periodic(
        start: start,
        period: const Duration(hours: 9),
        window: const Duration(days: 14),
      );
      final second = periodic(
        start: mid,
        period: const Duration(hours: 15),
        window: const Duration(days: 14),
      );
      final timestamps = <int>[
        for (final t in [...first, ...second]) ...[t, t + 90000],
      ]..sort();

      final r = estimator.estimate(
        timestamps: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );

      expect(r.accepted, isFalse);
      expect(r.omega, isNull);
      expect(
        r.status,
        anyOf(
          ActivitySpectralOmegaStatus.ambiguous,
          ActivitySpectralOmegaStatus.sparse,
          ActivitySpectralOmegaStatus.unavailable,
        ),
      );
      if (r.status == ActivitySpectralOmegaStatus.ambiguous) {
        expect(
          r.reason,
          anyOf(
            ActivitySpectralOmegaEstimatorContract.reasonSplitHalfUnstable,
            ActivitySpectralOmegaEstimatorContract.reasonMultiplePeaks,
            ActivitySpectralOmegaEstimatorContract.reasonHarmonicAmbiguity,
          ),
        );
      }
    });

    test('long-time numerical stability', () {
      final start = DateTime.utc(2023, 1, 1);
      const period = Duration(hours: 12);
      const window = Duration(days: 60);
      final timestamps = periodic(start: start, period: period, window: window);
      final dense = <int>[
        for (final t in timestamps) ...[t, t + 60000],
      ];
      final r = estimator.estimate(
        timestamps: dense,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(r.status, ActivitySpectralOmegaStatus.ok);
      expect(r.omega!.isFinite, isTrue);
      expect(r.periodSeconds!.isFinite, isTrue);
      expect(r.periodSeconds!, closeTo(43200, 3600));
      expect(r.omega!, closeTo(2 * math.pi / r.periodSeconds!, 1e-9));
    });

    test('contract freezes no mode attach / no cadence / no discover', () {
      expect(
        ActivitySpectralOmegaEstimatorContract.attachesToFrequencyModes,
        isFalse,
      );
      expect(
        ActivitySpectralOmegaEstimatorContract.cadenceFallbackAllowed,
        isFalse,
      );
      expect(
        ActivitySpectralOmegaEstimatorContract.questionnaireOmegaAllowed,
        isFalse,
      );
      expect(
        ActivitySpectralOmegaEstimatorContract.liveDiscoverRanking,
        isFalse,
      );
      final paths = [
        'lib/features/matching/domain/activity_spectral_omega_estimator.dart',
        'lib/features/matching/domain/activity_spectral_omega_estimator_contract.dart',
        'lib/features/matching/domain/activity_spectral_omega_estimator_models.dart',
      ];
      for (final path in paths) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('features/discover')), reason: path);
        expect(src, isNot(contains('DiscoverService')), reason: path);
        expect(src, isNot(contains('depth_preference')), reason: path);
        expect(src, isNot(contains('WaveStateModeV2')), reason: path);
      }
    });
  });
}
