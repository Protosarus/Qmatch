import 'dart:math' as math;

import 'circadian_activity_phase_estimator_contract.dart';
import 'circadian_activity_phase_estimator_models.dart';
import 'wave_state_modal_shadow_v2_models.dart';

/// Shadow-only global circadian activity phase estimator v1.
///
/// \[
/// \theta_i = 2\pi\,\mathrm{local\_seconds}_i / 86400
/// \]
/// \[
/// \bar\theta = \mathrm{atan2}(\overline{\sin\theta},\,\overline{\cos\theta})
/// \]
/// \[
/// \bar R = \sqrt{\overline{\cos\theta}^{2}+\overline{\sin\theta}^{2}}
/// \]
///
/// Emits [PhaseReferenceV2] for `circadian_activity_24h` only when provisional
/// gates pass. Does **not** attach to Frequency modes or six-mode `r_wave`.
/// Fixed 24h ω only — no free omega estimation, no questionnaire phase.
class CircadianActivityPhaseEstimator {
  const CircadianActivityPhaseEstimator();

  /// Estimate global activity-clock phase from metadata timestamps.
  ///
  /// [localTimeZoneOffset] and non-empty [timezoneLabel] are both required
  /// (local civil basis). Missing either → unavailable (no UTC-as-local).
  CircadianActivityPhaseEstimate estimate({
    required List<CircadianActivityTimestamp> timestamps,
    required Duration? localTimeZoneOffset,
    required String? timezoneLabel,
  }) {
    final tz = localTimeZoneOffset;
    final label = timezoneLabel?.trim();
    if (tz == null || label == null || label.isEmpty) {
      return CircadianActivityPhaseEstimate(
        available: false,
        unavailableReason:
            CircadianActivityPhaseEstimatorContract.reasonMissingTimezone,
        eventCount: timestamps.length,
        distinctLocalDays: 0,
        thetaBar: null,
        rBar: null,
        phaseReference: null,
        timezoneLabel: label,
        localTimeZoneOffset: tz,
      );
    }

    if (timestamps.isEmpty) {
      return CircadianActivityPhaseEstimate(
        available: false,
        unavailableReason:
            CircadianActivityPhaseEstimatorContract.reasonNoEvents,
        eventCount: 0,
        distinctLocalDays: 0,
        thetaBar: null,
        rBar: null,
        phaseReference: null,
        timezoneLabel: label,
        localTimeZoneOffset: tz,
      );
    }

    var c = 0.0;
    var s = 0.0;
    final dayKeys = <String>{};
    for (final e in timestamps) {
      final theta = _localTheta(e.timestampMs, tz);
      c += math.cos(theta);
      s += math.sin(theta);
      dayKeys.add(_localDayKey(e.timestampMs, tz));
    }
    final n = timestamps.length;
    c /= n;
    s /= n;
    final rBar = math.sqrt(c * c + s * s);
    final thetaBar = math.atan2(s, c);
    final days = dayKeys.length;

    String? reason;
    if (n < CircadianActivityPhaseEstimatorContract.minEventsOk) {
      reason = CircadianActivityPhaseEstimatorContract.reasonInsufficientEvents;
    } else if (days <
        CircadianActivityPhaseEstimatorContract.minDistinctLocalDaysOk) {
      reason = CircadianActivityPhaseEstimatorContract.reasonInsufficientDays;
    } else if (rBar < CircadianActivityPhaseEstimatorContract.minRBarOk) {
      reason = CircadianActivityPhaseEstimatorContract.reasonLowConcentration;
    }

    if (reason != null) {
      return CircadianActivityPhaseEstimate(
        available: false,
        unavailableReason: reason,
        eventCount: n,
        distinctLocalDays: days,
        thetaBar: thetaBar,
        rBar: rBar,
        phaseReference: null,
        timezoneLabel: label,
        localTimeZoneOffset: tz,
      );
    }

    final phase = PhaseReferenceV2(
      oscillatorId: CircadianActivityPhaseEstimatorContract.oscillatorId,
      phaseRadians: thetaBar,
      phaseClass: WavePhaseClassV2.externalAnchored,
      timeBasis: WavePhaseTimeBasisV2.localCivil,
      periodicityStatus: WavePeriodicityStatusV2.ok,
      periodSeconds: CircadianActivityPhaseEstimatorContract.periodSeconds,
      omega: CircadianActivityPhaseEstimatorContract.fixedOmega,
      referenceEpoch: null,
      timezone: label,
      source: CircadianActivityPhaseEstimatorContract.sourceId,
    );

    return CircadianActivityPhaseEstimate(
      available: true,
      unavailableReason: null,
      eventCount: n,
      distinctLocalDays: days,
      thetaBar: thetaBar,
      rBar: rBar,
      phaseReference: phase,
      timezoneLabel: label,
      localTimeZoneOffset: tz,
    );
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
    return 2 * math.pi * (tau / CircadianActivityPhaseEstimatorContract.periodSeconds);
  }

  static String _localDayKey(int timestampMs, Duration tz) {
    final local = DateTime.fromMillisecondsSinceEpoch(
      timestampMs,
      isUtc: true,
    ).add(tz);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
