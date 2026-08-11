import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/circadian_activity_phase.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_v2_models.dart';

void main() {
  const estimator = CircadianActivityPhaseEstimator();
  const tz = Duration(hours: 3);
  const tzLabel = 'UTC+03:00';

  /// Build UTC instants that land at local hour:minute on successive days.
  List<CircadianActivityTimestamp> clusterAtLocalHour({
    required int hour,
    required int minute,
    required int days,
    required int perDay,
    Duration offset = tz,
  }) {
    final out = <CircadianActivityTimestamp>[];
    for (var d = 0; d < days; d++) {
      for (var i = 0; i < perDay; i++) {
        // Interpret (year,month,day,hour,minute) as local civil, convert to UTC.
        final civil = DateTime.utc(2024, 1, 1 + d, hour, minute + i);
        final utcMs = civil.subtract(offset).millisecondsSinceEpoch;
        out.add(CircadianActivityTimestamp(timestampMs: utcMs));
      }
    }
    return out;
  }

  double expectedTheta(int hour, int minute) {
    final tau = hour * 3600 + minute * 60;
    var th = 2 * math.pi * tau / 86400.0;
    // Match atan2 principal value in (-π, π].
    while (th > math.pi) {
      th -= 2 * math.pi;
    }
    while (th <= -math.pi) {
      th += 2 * math.pi;
    }
    return th;
  }

  group('CircadianActivityPhaseEstimator', () {
    test('morning cluster → available PhaseReferenceV2 near morning phase', () {
      final events = clusterAtLocalHour(hour: 8, minute: 0, days: 5, perDay: 3);
      final r = estimator.estimate(
        timestamps: events,
        localTimeZoneOffset: tz,
        timezoneLabel: tzLabel,
      );
      expect(r.available, isTrue);
      expect(r.eventCount, greaterThanOrEqualTo(10));
      expect(r.distinctLocalDays, greaterThanOrEqualTo(4));
      expect(r.rBar!, greaterThanOrEqualTo(0.35));
      expect(r.phaseReference, isNotNull);
      final pref = r.phaseReference!;
      expect(pref.oscillatorId, 'circadian_activity_24h');
      expect(pref.phaseClass, WavePhaseClassV2.externalAnchored);
      expect(pref.timeBasis, WavePhaseTimeBasisV2.localCivil);
      expect(pref.periodSeconds, 86400);
      expect(pref.timezone, tzLabel);
      expect(pref.periodicityStatus, WavePeriodicityStatusV2.ok);
      expect(pref.source, contains('circadian_activity'));
      expect(r.thetaBar, closeTo(expectedTheta(8, 0), 0.15));
      expect(r.toWireMap()['attaches_to_frequency_modes'], isFalse);
      expect(r.toWireMap()['feeds_six_mode_r_wave'], isFalse);
      expect(r.toWireMap()['gates_calibrated'], isFalse);
    });

    test('evening cluster → phase near evening', () {
      final events =
          clusterAtLocalHour(hour: 21, minute: 0, days: 5, perDay: 3);
      final r = estimator.estimate(
        timestamps: events,
        localTimeZoneOffset: tz,
        timezoneLabel: tzLabel,
      );
      expect(r.available, isTrue);
      expect(r.thetaBar, closeTo(expectedTheta(21, 0), 0.15));
      // Morning vs evening should differ substantially.
      final morning = estimator.estimate(
        timestamps:
            clusterAtLocalHour(hour: 8, minute: 0, days: 5, perDay: 3),
        localTimeZoneOffset: tz,
        timezoneLabel: tzLabel,
      );
      final delta = (r.thetaBar! - morning.thetaBar!).abs();
      final wrapped = math.min(delta, 2 * math.pi - delta);
      expect(wrapped, greaterThan(1.0));
    });

    test('midnight wraparound → circular mean near 0', () {
      final late = clusterAtLocalHour(hour: 23, minute: 0, days: 5, perDay: 2);
      final early = clusterAtLocalHour(hour: 1, minute: 0, days: 5, perDay: 2);
      final r = estimator.estimate(
        timestamps: [...late, ...early],
        localTimeZoneOffset: tz,
        timezoneLabel: tzLabel,
      );
      expect(r.available, isTrue);
      // Near midnight ⇒ |theta| small or near ±π wrap; use cos proximity to 1.
      expect(math.cos(r.thetaBar!), closeTo(1.0, 0.25));
      expect(r.rBar!, greaterThan(0.35));
    });

    test('uniform activity → low R_bar, no PhaseReferenceV2', () {
      final events = <CircadianActivityTimestamp>[];
      for (var d = 0; d < 6; d++) {
        for (var h = 0; h < 24; h += 2) {
          final civil = DateTime.utc(2024, 1, 1 + d, h);
          events.add(
            CircadianActivityTimestamp(
              timestampMs: civil.subtract(tz).millisecondsSinceEpoch,
            ),
          );
        }
      }
      final r = estimator.estimate(
        timestamps: events,
        localTimeZoneOffset: tz,
        timezoneLabel: tzLabel,
      );
      expect(r.available, isFalse);
      expect(r.phaseReference, isNull);
      expect(r.rBar!, lessThan(0.35));
      expect(
        r.unavailableReason,
        CircadianActivityPhaseEstimatorContract.reasonLowConcentration,
      );
    });

    test('sparse events → unavailable', () {
      final events = clusterAtLocalHour(hour: 10, minute: 0, days: 3, perDay: 2);
      // 6 events < 10
      final r = estimator.estimate(
        timestamps: events,
        localTimeZoneOffset: tz,
        timezoneLabel: tzLabel,
      );
      expect(r.available, isFalse);
      expect(r.phaseReference, isNull);
      expect(
        r.unavailableReason,
        CircadianActivityPhaseEstimatorContract.reasonInsufficientEvents,
      );
      // Diagnostics may still report theta/R.
      expect(r.thetaBar, isNotNull);
      expect(r.rBar, isNotNull);
    });

    test('missing timezone → unavailable', () {
      final events = clusterAtLocalHour(hour: 9, minute: 0, days: 5, perDay: 3);
      final noOffset = estimator.estimate(
        timestamps: events,
        localTimeZoneOffset: null,
        timezoneLabel: tzLabel,
      );
      expect(noOffset.available, isFalse);
      expect(
        noOffset.unavailableReason,
        CircadianActivityPhaseEstimatorContract.reasonMissingTimezone,
      );
      expect(noOffset.phaseReference, isNull);

      final noLabel = estimator.estimate(
        timestamps: events,
        localTimeZoneOffset: tz,
        timezoneLabel: null,
      );
      expect(noLabel.available, isFalse);
      expect(
        noLabel.unavailableReason,
        CircadianActivityPhaseEstimatorContract.reasonMissingTimezone,
      );
    });

    test('timezone shift changes estimated phase', () {
      final events = clusterAtLocalHour(hour: 12, minute: 0, days: 5, perDay: 3);
      final a = estimator.estimate(
        timestamps: events,
        localTimeZoneOffset: const Duration(hours: 0),
        timezoneLabel: 'UTC',
      );
      final b = estimator.estimate(
        timestamps: events,
        localTimeZoneOffset: const Duration(hours: 6),
        timezoneLabel: 'UTC+06:00',
      );
      expect(a.available, isTrue);
      expect(b.available, isTrue);
      final delta = (a.thetaBar! - b.thetaBar!).abs();
      final wrapped = math.min(delta, 2 * math.pi - delta);
      expect(wrapped, closeTo(math.pi / 2, 0.2)); // 6h = π/2
    });

    test('circular symmetry: uniform time shift rotates theta_bar', () {
      final base = clusterAtLocalHour(hour: 10, minute: 0, days: 5, perDay: 3);
      final shiftHours = 4;
      final shifted = [
        for (final e in base)
          CircadianActivityTimestamp(
            timestampMs: e.timestampMs + shiftHours * 3600 * 1000,
          ),
      ];
      final a = estimator.estimate(
        timestamps: base,
        localTimeZoneOffset: tz,
        timezoneLabel: tzLabel,
      );
      final b = estimator.estimate(
        timestamps: shifted,
        localTimeZoneOffset: tz,
        timezoneLabel: tzLabel,
      );
      expect(a.available, isTrue);
      expect(b.available, isTrue);
      final expected = 2 * math.pi * shiftHours / 24;
      var delta = b.thetaBar! - a.thetaBar!;
      while (delta <= -math.pi) {
        delta += 2 * math.pi;
      }
      while (delta > math.pi) {
        delta -= 2 * math.pi;
      }
      expect(delta, closeTo(expected, 0.15));
      expect(a.rBar, closeTo(b.rBar!, 1e-9));
    });

    test('insufficient distinct days even with N>=10', () {
      // 12 events on only 2 local days.
      final events = clusterAtLocalHour(hour: 15, minute: 0, days: 2, perDay: 6);
      final r = estimator.estimate(
        timestamps: events,
        localTimeZoneOffset: tz,
        timezoneLabel: tzLabel,
      );
      expect(r.eventCount, 12);
      expect(r.distinctLocalDays, 2);
      expect(r.available, isFalse);
      expect(r.phaseReference, isNull);
      expect(
        r.unavailableReason,
        CircadianActivityPhaseEstimatorContract.reasonInsufficientDays,
      );
    });

    test('sources do not couple Discover / Frequency mode attachment', () {
      final paths = [
        'lib/features/matching/domain/circadian_activity_phase_estimator.dart',
        'lib/features/matching/domain/circadian_activity_phase_estimator_contract.dart',
        'lib/features/matching/domain/circadian_activity_phase_estimator_models.dart',
      ];
      for (final path in paths) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('features/discover')), reason: path);
        expect(src, isNot(contains('DiscoverService')), reason: path);
        expect(src, isNot(contains('depth_preference')), reason: path);
        expect(src, isNot(contains('WaveStateModeV2')), reason: path);
        expect(
          CircadianActivityPhaseEstimatorContract.questionnairePhaseAllowed,
          isFalse,
        );
      }
    });
  });
}
