import 'package:flutter/foundation.dart';

import '../domain/temporal_shadow.dart';
import 'temporal_shadow_debug_diagnostics_runner_contract.dart';
import 'temporal_shadow_firestore_diagnostics.dart';

/// Aggregate-only debug report (no message bodies, no per-message dumps).
class TemporalShadowDebugDiagnosticsReport {
  const TemporalShadowDebugDiagnosticsReport({
    required this.refused,
    required this.refusalReason,
    required this.hasData,
    required this.noDataReason,
    required this.timezoneProvided,
    required this.threadCountExamined,
    required this.threadCountWithResults,
    required this.totalEligibleEvents,
    required this.uniqueUserCount,
    required this.featureStatusRates,
    required this.cadenceMeanDistribution,
    required this.cadenceMedianDistribution,
    required this.burstinessDistribution,
    required this.participationBalanceDistribution,
    required this.turnGapDistribution,
    required this.circadian,
    required this.writesPerformed,
  });

  final bool refused;
  final String? refusalReason;
  final bool hasData;
  final String? noDataReason;
  final bool timezoneProvided;
  final int threadCountExamined;
  final int threadCountWithResults;
  final int totalEligibleEvents;
  final int uniqueUserCount;
  final Map<String, Map<String, num>> featureStatusRates;
  final Map<String, num?> cadenceMeanDistribution;
  final Map<String, num?> cadenceMedianDistribution;
  final Map<String, num?> burstinessDistribution;
  final Map<String, num?> participationBalanceDistribution;
  final Map<String, num?> turnGapDistribution;
  final Map<String, dynamic> circadian;
  final bool writesPerformed;

  static TemporalShadowDebugDiagnosticsReport asRefused(String reason) {
    return TemporalShadowDebugDiagnosticsReport(
      refused: true,
      refusalReason: reason,
      hasData: false,
      noDataReason: reason,
      timezoneProvided: false,
      threadCountExamined: 0,
      threadCountWithResults: 0,
      totalEligibleEvents: 0,
      uniqueUserCount: 0,
      featureStatusRates: const {},
      cadenceMeanDistribution: const {},
      cadenceMedianDistribution: const {},
      burstinessDistribution: const {},
      participationBalanceDistribution: const {},
      turnGapDistribution: const {},
      circadian: const {
        'included': false,
        'reason': 'runner_refused',
      },
      writesPerformed: false,
    );
  }

  Map<String, dynamic> toWireMap() => {
        'scoring_version':
            TemporalShadowDebugDiagnosticsRunnerContract.scoringVersion,
        'policy_status':
            TemporalShadowDebugDiagnosticsRunnerContract.policyStatus,
        'debug_only': TemporalShadowDebugDiagnosticsRunnerContract.debugOnly,
        'shadow_only': TemporalShadowDebugDiagnosticsRunnerContract.shadowOnly,
        'persists_derived_features': TemporalShadowDebugDiagnosticsRunnerContract
            .persistsDerivedFeatures,
        'affects_discover_ranking': TemporalShadowDebugDiagnosticsRunnerContract
            .affectsDiscoverRanking,
        'production_ui_exposed': TemporalShadowDebugDiagnosticsRunnerContract
            .productionUiExposed,
        'refused': refused,
        if (refusalReason != null) 'refusal_reason': refusalReason,
        'has_data': hasData,
        if (noDataReason != null) 'no_data_reason': noDataReason,
        'timezone_provided': timezoneProvided,
        'thread_count_examined': threadCountExamined,
        'thread_count_with_results': threadCountWithResults,
        'total_eligible_events': totalEligibleEvents,
        'unique_user_count': uniqueUserCount,
        'feature_status_rates': featureStatusRates,
        'cadence_mean_per_second_distribution': cadenceMeanDistribution,
        'cadence_median_per_second_distribution': cadenceMedianDistribution,
        'burstiness_distribution': burstinessDistribution,
        'dyadic_participation_balance_distribution':
            participationBalanceDistribution,
        'median_turn_gap_seconds_distribution': turnGapDistribution,
        'circadian': circadian,
        'omega': {'status': 'unavailable'},
        'writes_performed': writesPerformed,
      };
}

/// DEBUG-ONLY runner over [TemporalShadowFirestoreDiagnostics.collectForCurrentUser].
///
/// Refuses when not in debug mode. Emits aggregate diagnostics only — never
/// message bodies, never Firestore writes, never Discover ranking changes.
class TemporalShadowDebugDiagnosticsRunner {
  TemporalShadowDebugDiagnosticsRunner({
    TemporalShadowFirestoreDiagnostics? firestoreDiagnostics,
    bool? debugModeOverride,
    Future<TemporalShadowAggregateDiagnostics> Function({
      Duration? localTimeZoneOffset,
      int maxThreads,
      int maxMessagesPerThread,
    })? collectOverride,
  })  : _firestoreDiagnostics = firestoreDiagnostics,
        _debugModeOverride = debugModeOverride,
        _collectOverride = collectOverride;

  final TemporalShadowFirestoreDiagnostics? _firestoreDiagnostics;
  final bool? _debugModeOverride;
  final Future<TemporalShadowAggregateDiagnostics> Function({
    Duration? localTimeZoneOffset,
    int maxThreads,
    int maxMessagesPerThread,
  })? _collectOverride;

  bool get isEnabled => _debugModeOverride ?? kDebugMode;

  /// Run real-thread metadata diagnostics for the current user (debug only).
  Future<TemporalShadowDebugDiagnosticsReport> run({
    Duration? localTimeZoneOffset,
    int maxThreads = 40,
    int maxMessagesPerThread = 500,
  }) async {
    if (!isEnabled) {
      return TemporalShadowDebugDiagnosticsReport.asRefused(
        TemporalShadowDebugDiagnosticsRunnerContract.refusalRequiresDebugMode,
      );
    }

    final override = _collectOverride;
    final TemporalShadowAggregateDiagnostics aggregate;
    if (override != null) {
      aggregate = await override(
        localTimeZoneOffset: localTimeZoneOffset,
        maxThreads: maxThreads,
        maxMessagesPerThread: maxMessagesPerThread,
      );
    } else {
      final diagnostics =
          _firestoreDiagnostics ?? TemporalShadowFirestoreDiagnostics();
      aggregate = await diagnostics.collectForCurrentUser(
        localTimeZoneOffset: localTimeZoneOffset,
        maxThreads: maxThreads,
        maxMessagesPerThread: maxMessagesPerThread,
      );
    }

    return summarizeAggregate(
      aggregate,
      timezoneProvided: localTimeZoneOffset != null,
    );
  }

  /// Pure aggregate summarizer (no I/O). Safe for unit tests.
  static TemporalShadowDebugDiagnosticsReport summarizeAggregate(
    TemporalShadowAggregateDiagnostics aggregate, {
    required bool timezoneProvided,
  }) {
    if (!aggregate.hasData) {
      return TemporalShadowDebugDiagnosticsReport(
        refused: false,
        refusalReason: null,
        hasData: false,
        noDataReason: aggregate.noDataReason ?? 'no_data',
        timezoneProvided: timezoneProvided,
        threadCountExamined: aggregate.threadCountExamined,
        threadCountWithResults: aggregate.threadCountWithResults,
        totalEligibleEvents: aggregate.totalEligibleEvents,
        uniqueUserCount: aggregate.uniqueUserCount,
        featureStatusRates: const {},
        cadenceMeanDistribution: const {},
        cadenceMedianDistribution: const {},
        burstinessDistribution: const {},
        participationBalanceDistribution: const {},
        turnGapDistribution: const {},
        circadian: {
          'included': false,
          'reason': timezoneProvided
              ? 'no_eligible_threads'
              : 'timezone_not_provided',
        },
        writesPerformed: false,
      );
    }

    final cadenceMean = <GatedDouble>[];
    final cadenceMedian = <GatedDouble>[];
    final burstiness = <GatedDouble>[];
    final participation = <GatedDouble>[];
    final turnGaps = <GatedDouble>[];
    final circTheta = <GatedDouble>[];
    final circR = <GatedDouble>[];
    final circDelta = <GatedDouble>[];

    for (final t in aggregate.threads) {
      cadenceMean
        ..add(t.result.userP.cadenceMeanPerSecond)
        ..add(t.result.userQ.cadenceMeanPerSecond);
      cadenceMedian
        ..add(t.result.userP.cadenceMedianPerSecond)
        ..add(t.result.userQ.cadenceMedianPerSecond);
      burstiness
        ..add(t.result.userP.burstiness)
        ..add(t.result.userQ.burstiness);
      participation.add(t.result.dyadic.dyadicParticipationBalance);
      turnGaps.add(t.result.dyadic.medianTurnGapSeconds);
      circTheta
        ..add(t.result.userP.circadianThetaBar)
        ..add(t.result.userQ.circadianThetaBar);
      circR
        ..add(t.result.userP.circadianRBar)
        ..add(t.result.userQ.circadianRBar);
      circDelta.add(t.result.dyadic.circadianDeltaTheta);
    }

    final rates = <String, Map<String, num>>{
      'cadence_mean_per_second': _statusRates(cadenceMean),
      'cadence_median_per_second': _statusRates(cadenceMedian),
      'burstiness': _statusRates(burstiness),
      'dyadic_participation_balance': _statusRates(participation),
      'median_turn_gap_seconds': _statusRates(turnGaps),
    };

    final circadian = timezoneProvided
        ? <String, dynamic>{
            'included': true,
            'feature_status_rates': {
              'circadian_theta_bar': _statusRates(circTheta),
              'circadian_r_bar': _statusRates(circR),
              'circadian_delta_theta': _statusRates(circDelta),
            },
            'circadian_theta_bar_distribution': _distribution(circTheta),
            'circadian_r_bar_distribution': _distribution(circR),
            'circadian_delta_theta_distribution': _distribution(circDelta),
          }
        : <String, dynamic>{
            'included': false,
            'reason': 'timezone_not_provided',
          };

    return TemporalShadowDebugDiagnosticsReport(
      refused: false,
      refusalReason: null,
      hasData: true,
      noDataReason: null,
      timezoneProvided: timezoneProvided,
      threadCountExamined: aggregate.threadCountExamined,
      threadCountWithResults: aggregate.threadCountWithResults,
      totalEligibleEvents: aggregate.totalEligibleEvents,
      uniqueUserCount: aggregate.uniqueUserCount,
      featureStatusRates: rates,
      cadenceMeanDistribution: _distribution(cadenceMean),
      cadenceMedianDistribution: _distribution(cadenceMedian),
      burstinessDistribution: _distribution(burstiness),
      participationBalanceDistribution: _distribution(participation),
      turnGapDistribution: _distribution(turnGaps),
      circadian: circadian,
      writesPerformed: false,
    );
  }

  static Map<String, num> _statusRates(List<GatedDouble> gated) {
    var ok = 0;
    var sparse = 0;
    var unavailable = 0;
    for (final g in gated) {
      switch (g.status) {
        case TemporalFeatureStatus.ok:
          ok++;
        case TemporalFeatureStatus.sparse:
          sparse++;
        case TemporalFeatureStatus.unavailable:
          unavailable++;
      }
    }
    final total = ok + sparse + unavailable;
    final available = ok + sparse;
    return {
      'ok': ok,
      'sparse': sparse,
      'unavailable': unavailable,
      'total': total,
      'ok_rate': total == 0 ? 0.0 : ok / total,
      'sparse_rate': total == 0 ? 0.0 : sparse / total,
      'available_rate': total == 0 ? 0.0 : available / total,
      'unavailable_rate': total == 0 ? 0.0 : unavailable / total,
    };
  }

  static Map<String, num?> _distribution(List<GatedDouble> gated) {
    final values = <double>[
      for (final g in gated)
        if (g.value != null &&
            (g.status == TemporalFeatureStatus.ok ||
                g.status == TemporalFeatureStatus.sparse))
          g.value!,
    ]..sort();

    if (values.isEmpty) {
      return {
        'count': 0,
        'min': null,
        'max': null,
        'mean': null,
        'p50': null,
      };
    }

    final sum = values.fold<double>(0, (a, b) => a + b);
    return {
      'count': values.length,
      'min': values.first,
      'max': values.last,
      'mean': sum / values.length,
      'p50': _percentile(values, 0.5),
    };
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return double.nan;
    if (sorted.length == 1) return sorted.first;
    final idx = (sorted.length - 1) * p;
    final lo = idx.floor();
    final hi = idx.ceil();
    if (lo == hi) return sorted[lo];
    final w = idx - lo;
    return sorted[lo] * (1 - w) + sorted[hi] * w;
  }
}
