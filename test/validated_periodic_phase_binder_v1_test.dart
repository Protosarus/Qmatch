import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/activity_spectral_omega.dart';
import 'package:qmatch/features/matching/domain/validated_periodic_phase.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_v2_models.dart';

void main() {
  const omegaEstimator = ActivitySpectralOmegaEstimator();
  const binder = ValidatedPeriodicPhaseBinder();

  int ms(DateTime dt) => dt.toUtc().millisecondsSinceEpoch;

  List<int> periodic({
    required DateTime start,
    required Duration period,
    required Duration window,
    Duration phaseOffset = Duration.zero,
    int duplicates = 3,
  }) {
    final out = <int>[];
    var t = start.toUtc().add(phaseOffset);
    final end = start.toUtc().add(window);
    // Align first tick into window.
    while (t.isBefore(start.toUtc())) {
      t = t.add(period);
    }
    while (!t.isAfter(end)) {
      for (var d = 0; d < duplicates; d++) {
        final ts = t.add(Duration(minutes: d));
        if (!ts.isBefore(start.toUtc()) && !ts.isAfter(end)) {
          out.add(ms(ts));
        }
      }
      t = t.add(period);
    }
    return out..sort();
  }

  double wrapPi(double x) {
    var y = x;
    while (y > math.pi) {
      y -= 2 * math.pi;
    }
    while (y < -math.pi) {
      y += 2 * math.pi;
    }
    return y;
  }

  group('ValidatedPeriodicPhaseBinder', () {
    test('clean periodic phase recovery', () {
      final start = DateTime.utc(2024, 1, 1);
      const period = Duration(hours: 12);
      const window = Duration(days: 21);
      final timestamps = periodic(
        start: start,
        period: period,
        window: window,
      );
      final omega = omegaEstimator.estimate(
        timestamps: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(omega.status, ActivitySpectralOmegaStatus.ok);

      final phase = binder.bind(
        omegaEstimate: omega,
        timestampsMs: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );

      expect(phase.available, isTrue);
      expect(phase.phaseReference, isNotNull);
      expect(phase.thetaBar, isNotNull);
      expect(phase.rBar!, greaterThan(0.9));
      expect(phase.periodSeconds, omega.periodSeconds);
      expect(phase.omega, omega.omega);
      expect(phase.oscillatorId, omega.oscillatorId);

      final pref = phase.phaseReference!;
      expect(pref.phaseClass, WavePhaseClassV2.validatedPeriodic);
      expect(pref.timeBasis, WavePhaseTimeBasisV2.utc);
      expect(pref.periodicityStatus, WavePeriodicityStatusV2.ok);
      expect(pref.periodSeconds, omega.periodSeconds);
      expect(pref.omega, omega.omega);
      expect(pref.oscillatorId, omega.oscillatorId);
      expect(pref.referenceEpoch, isNotNull);
      expect(pref.source, ValidatedPeriodicPhaseBinderContract.sourceId);
      expect(pref.provenanceGapReason(), isNull);
      expect(phase.toWireMap()['gates_calibrated'], isFalse);
      expect(phase.toWireMap()['shadow_only'], isTrue);
      expect(phase.toWireMap()['attaches_to_frequency_modes'], isFalse);

      // Events at window start (+0..2 min) → phase near 0.
      expect(phase.thetaBar!.abs(), lessThan(0.15));
    });

    test('phase-shifted streams recover shifted circular mean', () {
      final start = DateTime.utc(2024, 2, 1);
      const period = Duration(hours: 12);
      const window = Duration(days: 21);
      const shift = Duration(hours: 3);

      final base = periodic(start: start, period: period, window: window);
      final shifted = periodic(
        start: start,
        period: period,
        window: window,
        phaseOffset: shift,
      );

      final omegaBase = omegaEstimator.estimate(
        timestamps: base,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      final omegaShift = omegaEstimator.estimate(
        timestamps: shifted,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(omegaBase.status, ActivitySpectralOmegaStatus.ok);
      expect(omegaShift.status, ActivitySpectralOmegaStatus.ok);

      final p0 = binder.bind(
        omegaEstimate: omegaBase,
        timestampsMs: base,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      final p1 = binder.bind(
        omegaEstimate: omegaShift,
        timestampsMs: shifted,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(p0.available && p1.available, isTrue);

      final expectedDelta = 2 * math.pi * (shift.inSeconds / period.inSeconds);
      final got = wrapPi(p1.thetaBar! - p0.thetaBar!);
      expect(got, closeTo(wrapPi(expectedDelta), 0.2));
    });

    test('wraparound: foldPhaseRadians positive-mod across epoch', () {
      const T = 43200.0;
      const epoch = 1700000000000;
      // Just before epoch → near 2π.
      final before = ValidatedPeriodicPhaseBinder.foldPhaseRadians(
        timestampMs: epoch - 1000,
        referenceEpochMs: epoch,
        periodSeconds: T,
      );
      expect(before, closeTo(2 * math.pi * ((T - 1) / T), 1e-9));
      // Exactly at epoch → 0.
      final at = ValidatedPeriodicPhaseBinder.foldPhaseRadians(
        timestampMs: epoch,
        referenceEpochMs: epoch,
        periodSeconds: T,
      );
      expect(at, closeTo(0.0, 1e-12));
      // Half period later → π.
      final half = ValidatedPeriodicPhaseBinder.foldPhaseRadians(
        timestampMs: epoch + (T / 2 * 1000).round(),
        referenceEpochMs: epoch,
        periodSeconds: T,
      );
      expect(half, closeTo(math.pi, 1e-9));
    });

    test('same T* different phase → distinct theta_bar, shared oscillator family', () {
      final start = DateTime.utc(2024, 3, 1);
      const period = Duration(hours: 12);
      const window = Duration(days: 21);
      final a = periodic(start: start, period: period, window: window);
      final b = periodic(
        start: start,
        period: period,
        window: window,
        phaseOffset: const Duration(hours: 3),
      );

      final oa = omegaEstimator.estimate(
        timestamps: a,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      final ob = omegaEstimator.estimate(
        timestamps: b,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(oa.status, ActivitySpectralOmegaStatus.ok);
      expect(ob.status, ActivitySpectralOmegaStatus.ok);
      expect(oa.periodSeconds!, closeTo(ob.periodSeconds!, 3600));

      final pa = binder.bind(
        omegaEstimate: oa,
        timestampsMs: a,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      final pb = binder.bind(
        omegaEstimate: ob,
        timestampsMs: b,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(pa.available && pb.available, isTrue);
      expect(
        wrapPi(pa.thetaBar! - pb.thetaBar!).abs(),
        greaterThan(0.5),
      );
      // Same T tag family prefix.
      expect(pa.oscillatorId!.startsWith('activity_spectral_'), isTrue);
      expect(pb.oscillatorId!.startsWith('activity_spectral_'), isTrue);
    });

    test('rejected omega → no Class-B phase', () {
      final start = DateTime.utc(2024, 4, 1);
      final rng = math.Random(3);
      final timestamps = <int>[
        for (var i = 0; i < 80; i++)
          ms(start.add(Duration(minutes: rng.nextInt(21 * 24 * 60)))),
      ];
      final omega = omegaEstimator.estimate(
        timestamps: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(const Duration(days: 21))),
      );
      expect(omega.status, isNot(ActivitySpectralOmegaStatus.ok));

      final phase = binder.bind(
        omegaEstimate: omega,
        timestampsMs: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(const Duration(days: 21))),
      );
      expect(phase.available, isFalse);
      expect(phase.phaseReference, isNull);
      expect(phase.omega, isNull);
      expect(
        phase.unavailableReason,
        anyOf(
          ValidatedPeriodicPhaseBinderContract.reasonOmegaAmbiguous,
          ValidatedPeriodicPhaseBinderContract.reasonOmegaSparse,
          ValidatedPeriodicPhaseBinderContract.reasonOmegaUnavailable,
          ValidatedPeriodicPhaseBinderContract.reasonCivilCollision,
          ValidatedPeriodicPhaseBinderContract.reasonOmegaNotOk,
        ),
      );
    });

    test('civil collision → no Class-B phase', () {
      final start = DateTime.utc(2024, 6, 1);
      const window = Duration(days: 28);
      final timestamps = periodic(
        start: start,
        period: const Duration(hours: 24),
        window: window,
      );
      final omega = omegaEstimator.estimate(
        timestamps: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(omega.status, ActivitySpectralOmegaStatus.civilCollision);

      final phase = binder.bind(
        omegaEstimate: omega,
        timestampsMs: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(phase.available, isFalse);
      expect(phase.phaseReference, isNull);
      expect(
        phase.unavailableReason,
        ValidatedPeriodicPhaseBinderContract.reasonCivilCollision,
      );
      expect(phase.toWireMap()['omega_status'], 'civilCollision');
    });

    test('symmetry / deterministic epoch handling', () {
      final start = DateTime.utc(2024, 7, 1);
      const period = Duration(hours: 12);
      const window = Duration(days: 21);
      final timestamps = periodic(
        start: start,
        period: period,
        window: window,
      );
      final omega = omegaEstimator.estimate(
        timestamps: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(omega.status, ActivitySpectralOmegaStatus.ok);

      final a = binder.bind(
        omegaEstimate: omega,
        timestampsMs: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      final b = binder.bind(
        omegaEstimate: omega,
        timestampsMs: List<int>.from(timestamps.reversed),
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      expect(a.available && b.available, isTrue);
      expect(a.referenceEpoch, b.referenceEpoch);
      expect(a.referenceEpochMs, ms(start));
      expect(a.thetaBar, closeTo(b.thetaBar!, 1e-12));
      expect(a.rBar, closeTo(b.rBar!, 1e-12));
      expect(
        a.referenceEpoch,
        DateTime.fromMillisecondsSinceEpoch(ms(start), isUtc: true)
            .toIso8601String(),
      );

      // Explicit shared epoch override is deterministic.
      final epoch = ms(start) + 3600 * 1000;
      final c = binder.bind(
        omegaEstimate: omega,
        timestampsMs: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
        referenceEpochMs: epoch,
      );
      final d = binder.bind(
        omegaEstimate: omega,
        timestampsMs: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
        referenceEpochMs: epoch,
      );
      expect(c.referenceEpochMs, epoch);
      expect(c.thetaBar, closeTo(d.thetaBar!, 1e-12));
      expect(
        wrapPi(c.thetaBar! - a.thetaBar!).abs(),
        greaterThan(0.1),
      );
    });

    test('contract freezes no mode attach / no discover / no questionnaire', () {
      expect(
        ValidatedPeriodicPhaseBinderContract.attachesToFrequencyModes,
        isFalse,
      );
      expect(
        ValidatedPeriodicPhaseBinderContract.feedsSixModeRWave,
        isFalse,
      );
      expect(
        ValidatedPeriodicPhaseBinderContract.liveDiscoverRanking,
        isFalse,
      );
      expect(
        ValidatedPeriodicPhaseBinderContract.questionnairePhaseAllowed,
        isFalse,
      );
      expect(ValidatedPeriodicPhaseBinderContract.gatesCalibrated, isFalse);
      final paths = [
        'lib/features/matching/domain/validated_periodic_phase_binder.dart',
        'lib/features/matching/domain/validated_periodic_phase_binder_contract.dart',
        'lib/features/matching/domain/validated_periodic_phase_binder_models.dart',
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
