import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/activity_spectral_omega.dart';

/// Offline synthetic stress harness for activity spectral omega v1.
/// Does not change production estimator behavior or Discover wiring.
void main() {
  test('activity_spectral_omega_v1 synthetic stress report', () {
    const estimator = ActivitySpectralOmegaEstimator();
    final rng = math.Random(11);

    int ms(DateTime dt) => dt.toUtc().millisecondsSinceEpoch;

    List<int> periodic({
      required DateTime start,
      required Duration period,
      required Duration window,
      Duration jitter = Duration.zero,
      int duplicates = 2,
    }) {
      final out = <int>[];
      var t = start.toUtc();
      final end = start.toUtc().add(window);
      while (!t.isAfter(end)) {
        var ts = t;
        if (jitter > Duration.zero) {
          final j =
              rng.nextInt(jitter.inMilliseconds * 2 + 1) - jitter.inMilliseconds;
          ts = t.add(Duration(milliseconds: j));
        }
        if (!ts.isBefore(start.toUtc()) && !ts.isAfter(end)) {
          for (var d = 0; d < duplicates; d++) {
            out.add(ms(ts.add(Duration(minutes: d))));
          }
        }
        t = t.add(period);
      }
      return out..sort();
    }

    List<int> randomTimes({
      required DateTime start,
      required Duration window,
      required int count,
    }) {
      final out = <int>[];
      for (var i = 0; i < count; i++) {
        out.add(
          ms(start.add(Duration(milliseconds: rng.nextInt(window.inMilliseconds)))),
        );
      }
      return out..sort();
    }

    List<int> burstyNonPeriodic({
      required DateTime start,
      required Duration window,
    }) {
      // Irregular clusters: random day offsets, burst of 5-8 messages, then long quiet.
      final out = <int>[];
      var cursor = start.toUtc();
      final end = start.toUtc().add(window);
      while (cursor.isBefore(end)) {
        final burst = 5 + rng.nextInt(4);
        for (var i = 0; i < burst; i++) {
          out.add(ms(cursor.add(Duration(minutes: i * (2 + rng.nextInt(8))))));
        }
        cursor = cursor.add(Duration(hours: 18 + rng.nextInt(60)));
      }
      return out.where((t) => t <= ms(end)).toList()..sort();
    }

    Map<String, dynamic> runCase({
      required String id,
      required String family,
      required List<int> timestamps,
      required DateTime start,
      required Duration window,
      double? truePeriodSeconds,
      String? expectHint,
    }) {
      final r = estimator.estimate(
        timestamps: timestamps,
        windowStartMs: ms(start),
        windowEndMs: ms(start.add(window)),
      );
      double? relErrT;
      double? relErrW;
      if (r.accepted && truePeriodSeconds != null && truePeriodSeconds > 0) {
        relErrT = (r.periodSeconds! - truePeriodSeconds).abs() / truePeriodSeconds;
        final trueOmega = 2 * math.pi / truePeriodSeconds;
        relErrW = (r.omega! - trueOmega).abs() / trueOmega;
      }
      return {
        'id': id,
        'family': family,
        'expect_hint': expectHint,
        'true_period_seconds': truePeriodSeconds,
        'n': timestamps.length,
        'window_days': window.inHours / 24.0,
        'status': r.status.name,
        'reason': r.reason,
        'accepted': r.accepted,
        'period_seconds': r.periodSeconds,
        'omega': r.omega,
        'snr': r.snr,
        'split_half_relative_delta': r.splitHalfRelativeDelta,
        'bin_sensitivity_relative_delta': r.binSensitivityRelativeDelta,
        'near_civil_collision': r.nearCivilCollision,
        'civil_collision_kind': r.civilCollisionKind,
        'rel_err_T': relErrT,
        'rel_err_omega': relErrW,
        'candidate_peak_count': r.candidatePeaks.length,
      };
    }

    final cases = <Map<String, dynamic>>[];
    final startBase = DateTime.utc(2024, 1, 1);

    // 1. clean single-period signals
    for (final hours in [8, 10, 12, 16]) {
      const window = Duration(days: 28);
      final period = Duration(hours: hours);
      cases.add(
        runCase(
          id: 'clean_T=${hours}h',
          family: 'clean_single_period',
          timestamps: periodic(
            start: startBase,
            period: period,
            window: window,
            duplicates: 3,
          ),
          start: startBase,
          window: window,
          truePeriodSeconds: period.inSeconds.toDouble(),
          expectHint: 'ok',
        ),
      );
    }

    // 2. noisy periodic
    for (var i = 0; i < 8; i++) {
      const window = Duration(days: 28);
      const period = Duration(hours: 12);
      final base = periodic(
        start: startBase.add(Duration(days: i)),
        period: period,
        window: window,
        jitter: Duration(minutes: 20 + 10 * i),
        duplicates: 2,
      );
      final noisy = [
        ...base,
        ...randomTimes(
          start: startBase.add(Duration(days: i)),
          window: window,
          count: 20 + 5 * i,
        ),
      ]..sort();
      cases.add(
        runCase(
          id: 'noisy_periodic_$i',
          family: 'noisy_periodic',
          timestamps: noisy,
          start: startBase.add(Duration(days: i)),
          window: window,
          truePeriodSeconds: period.inSeconds.toDouble(),
          expectHint: 'ok_or_sparse',
        ),
      );
    }

    // 3. multiple competing periods
    {
      const window = Duration(days: 28);
      final a = periodic(
        start: startBase,
        period: const Duration(hours: 9),
        window: window,
        duplicates: 3,
      );
      final b = periodic(
        start: startBase,
        period: const Duration(hours: 14),
        window: window,
        duplicates: 3,
      );
      cases.add(
        runCase(
          id: 'competing_9h_14h',
          family: 'competing_periods',
          timestamps: <int>{...a, ...b}.toList()..sort(),
          start: startBase,
          window: window,
          expectHint: 'ambiguous',
        ),
      );
    }

    // 4. harmonics/subharmonics (phase-offset so 8h is not a 16h subset)
    {
      const window = Duration(days: 28);
      final fund = periodic(
        start: startBase,
        period: const Duration(hours: 16),
        window: window,
        duplicates: 3,
      );
      final harm = periodic(
        start: startBase.add(const Duration(hours: 4)),
        period: const Duration(hours: 8),
        window: window,
        duplicates: 3,
      );
      cases.add(
        runCase(
          id: 'harmonic_16h_8h',
          family: 'harmonics',
          timestamps: <int>{...fund, ...harm}.toList()..sort(),
          start: startBase,
          window: window,
          truePeriodSeconds: 16 * 3600,
          expectHint: 'fundamental_or_ambiguous',
        ),
      );
    }

    // 5. near-24h and near-7d civil collisions
    {
      const window = Duration(days: 28);
      cases.add(
        runCase(
          id: 'civil_near_24h',
          family: 'civil_collision',
          timestamps: periodic(
            start: startBase,
            period: const Duration(hours: 24),
            window: window,
            duplicates: 3,
          ),
          start: startBase,
          window: window,
          truePeriodSeconds: 86400,
          expectHint: 'civilCollision',
        ),
      );
      cases.add(
        runCase(
          id: 'civil_near_7d',
          family: 'civil_collision',
          timestamps: periodic(
            start: startBase,
            period: const Duration(days: 7),
            window: const Duration(days: 56),
            duplicates: 4,
          ),
          start: startBase,
          window: const Duration(days: 56),
          truePeriodSeconds: 7 * 86400,
          expectHint: 'civilCollision',
        ),
      );
    }

    // 6. drifting period over time
    {
      const window = Duration(days: 28);
      final mid = startBase.add(const Duration(days: 14));
      final first = periodic(
        start: startBase,
        period: const Duration(hours: 9),
        window: const Duration(days: 14),
        duplicates: 3,
      );
      final second = periodic(
        start: mid,
        period: const Duration(hours: 15),
        window: const Duration(days: 14),
        duplicates: 3,
      );
      cases.add(
        runCase(
          id: 'drifting_9h_to_15h',
          family: 'drifting_period',
          timestamps: [...first, ...second]..sort(),
          start: startBase,
          window: window,
          expectHint: 'ambiguous',
        ),
      );
    }

    // 7. missing-event gaps (periodic with large holes)
    {
      const window = Duration(days: 28);
      final full = periodic(
        start: startBase,
        period: const Duration(hours: 12),
        window: window,
        duplicates: 3,
      );
      // Drop a 5-day hole in the middle.
      final holeStart = ms(startBase.add(const Duration(days: 10)));
      final holeEnd = ms(startBase.add(const Duration(days: 15)));
      final gapped = [
        for (final t in full)
          if (t < holeStart || t > holeEnd) t,
      ];
      cases.add(
        runCase(
          id: 'gapped_12h',
          family: 'missing_event_gaps',
          timestamps: gapped,
          start: startBase,
          window: window,
          truePeriodSeconds: 12 * 3600,
          expectHint: 'ok_or_sparse_or_ambiguous',
        ),
      );
    }

    // 8. bursty but non-periodic
    for (var i = 0; i < 6; i++) {
      cases.add(
        runCase(
          id: 'bursty_nonperiodic_$i',
          family: 'bursty_nonperiodic',
          timestamps: burstyNonPeriodic(
            start: startBase.add(Duration(days: i * 3)),
            window: const Duration(days: 28),
          ),
          start: startBase.add(Duration(days: i * 3)),
          window: const Duration(days: 28),
          expectHint: 'not_ok',
        ),
      );
    }

    // 9. random activity (false-positive probe) — expanded for FPR validation
    const randomTrials = 100;
    var randomOk = 0;
    for (var i = 0; i < randomTrials; i++) {
      final c = runCase(
        id: 'random_$i',
        family: 'random_activity',
        timestamps: randomTimes(
          start: startBase.add(Duration(days: i)),
          window: const Duration(days: 21),
          count: 60 + rng.nextInt(40),
        ),
        start: startBase.add(Duration(days: i)),
        window: const Duration(days: 21),
        expectHint: 'not_ok',
      );
      cases.add(c);
      if (c['accepted'] == true) randomOk++;
    }

    // 10. different bin sizes — estimator hardcodes 1h vs internal 2h sensitivity;
    // report bin_sensitivity deltas on clean signals.
    for (final hours in [10, 12]) {
      const window = Duration(days: 28);
      cases.add(
        runCase(
          id: 'bin_sensitivity_probe_${hours}h',
          family: 'bin_size_probe',
          timestamps: periodic(
            start: startBase,
            period: Duration(hours: hours),
            window: window,
            duplicates: 3,
          ),
          start: startBase,
          window: window,
          truePeriodSeconds: hours * 3600.0,
          expectHint: 'ok_with_bin_delta',
        ),
      );
    }

    // 11. short vs long observation windows
    {
      const period = Duration(hours: 12);
      for (final days in [7, 10, 14, 21, 45]) {
        final window = Duration(days: days);
        cases.add(
          runCase(
            id: 'window_${days}d',
            family: 'window_length',
            timestamps: periodic(
              start: startBase,
              period: period,
              window: window,
              duplicates: 3,
            ),
            start: startBase,
            window: window,
            truePeriodSeconds: period.inSeconds.toDouble(),
            expectHint: days < 14 ? 'not_ok' : 'ok',
          ),
        );
      }
    }

    // 12. long-time numerical stability
    {
      const window = Duration(days: 90);
      const period = Duration(hours: 12);
      cases.add(
        runCase(
          id: 'long_time_90d',
          family: 'long_time_stability',
          timestamps: periodic(
            start: DateTime.utc(2023, 1, 1),
            period: period,
            window: window,
            duplicates: 2,
          ),
          start: DateTime.utc(2023, 1, 1),
          window: window,
          truePeriodSeconds: period.inSeconds.toDouble(),
          expectHint: 'ok',
        ),
      );
    }

    // --- Aggregates ---
    Map<String, int> statusHist(String family) {
      final h = <String, int>{
        'ok': 0,
        'sparse': 0,
        'ambiguous': 0,
        'civilCollision': 0,
        'unavailable': 0,
      };
      for (final c in cases) {
        if (c['family'] != family) continue;
        h[c['status'] as String] = (h[c['status'] as String] ?? 0) + 1;
      }
      return h;
    }

    List<double> errs(String family, String key) => [
          for (final c in cases)
            if (c['family'] == family && c[key] is num)
              (c[key] as num).toDouble(),
        ];

    double? mean(List<double> xs) =>
        xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;

    final cleanErrs = errs('clean_single_period', 'rel_err_T');
    final cleanOmegaErrs = errs('clean_single_period', 'rel_err_omega');
    final cleanAccepted = cases
        .where((c) => c['family'] == 'clean_single_period' && c['accepted'] == true)
        .length;
    final cleanTotal =
        cases.where((c) => c['family'] == 'clean_single_period').length;

    final civil = cases.where((c) => c['family'] == 'civil_collision').toList();
    final civilStatusOk = civil
        .where((c) => c['status'] == 'civilCollision' && c['accepted'] != true)
        .length;
    final civilFlagged =
        civil.where((c) => c['near_civil_collision'] == true).length;

    final competing = cases.where((c) => c['family'] == 'competing_periods').toList();
    final competingAmbiguous =
        competing.where((c) => c['status'] == 'ambiguous').length;

    final harmonics = cases.where((c) => c['family'] == 'harmonics').toList();
    final harmonicSilentHarmonicOk = harmonics.where((c) {
      if (c['accepted'] != true) return false;
      final t = c['period_seconds'];
      if (t is! num) return false;
      // Silent harmonic lock ≈ 8h when true fundamental is 16h.
      return (t - 8 * 3600).abs() < 3600;
    }).length;

    final falsePositiveRate = randomOk / randomTrials;

    // Soft assertions: harness health + hardened policy targets.
    expect(cleanTotal, greaterThan(0));
    expect(cases.length, greaterThan(50));
    // Clean recall: all clean single-period streams should accept.
    expect(cleanAccepted / cleanTotal, equals(1.0));
    // Random FPR target after snrOk=20 validation.
    expect(falsePositiveRate, lessThan(0.01));
    // Civil collisions → dedicated status, never Class B ok.
    expect(civilStatusOk, equals(civil.length));
    expect(civilFlagged, equals(civil.length));
    // Competing unrelated peaks must not silently ok.
    expect(competingAmbiguous, equals(competing.length));
    expect(harmonicSilentHarmonicOk, equals(0));
    // Contract isolation.
    expect(
      ActivitySpectralOmegaEstimatorContract.attachesToFrequencyModes,
      isFalse,
    );
    expect(
      ActivitySpectralOmegaEstimatorContract.cadenceFallbackAllowed,
      isFalse,
    );
    expect(ActivitySpectralOmegaEstimatorContract.gatesCalibrated, isFalse);
    expect(ActivitySpectralOmegaEstimatorContract.snrOk, equals(20.0));

    final findings = <String>[
      'Clean single-period: accepted $cleanAccepted/$cleanTotal; mean |ΔT|/T=${mean(cleanErrs)}; mean |Δω|/ω=${mean(cleanOmegaErrs)}.',
      'Random activity false-positive ok-rate: ${(falsePositiveRate * 100).toStringAsFixed(1)}% ($randomOk/$randomTrials); snrOk=${ActivitySpectralOmegaEstimatorContract.snrOk}.',
      'Civil collision → civilCollision status: $civilStatusOk/${civil.length} (flagged $civilFlagged).',
      'Competing unrelated peaks ambiguous: $competingAmbiguous/${competing.length}.',
      'Harmonic silent-8h ok count: $harmonicSilentHarmonicOk/${harmonics.length}.',
      'Bin-size probe reports internal 1h↔2h sensitivity deltas when accepted.',
      'Short windows (<14d) should rarely reach ok under provisional gates.',
      'Long 90d clean run remains finite when accepted.',
      'No cadence fallback and no Frequency-mode attachment; gates_calibrated=false.',
    ];

    final readyToBindPhase = cleanAccepted == cleanTotal &&
        falsePositiveRate < 0.01 &&
        civilStatusOk == civil.length &&
        competingAmbiguous == competing.length &&
        harmonicSilentHarmonicOk == 0;

    final recommendation = readyToBindPhase
        ? 'Shadow omega hardened enough to prototype Class-B phase folding on the same oscillator_id in shadow only (still gates_calibrated=false).'
        : 'Not ready to bind phase on the same oscillator: keep omega diagnostics separate until remaining gate failures clear.';

    final report = {
      'title': 'Activity Spectral Omega Shadow v1 — synthetic stress (hardened)',
      'scoring_version':
          ActivitySpectralOmegaEstimatorContract.scoringVersion,
      'policy_status': ActivitySpectralOmegaEstimatorContract.policyStatus,
      'shadow_only': true,
      'gates_calibrated':
          ActivitySpectralOmegaEstimatorContract.gatesCalibrated,
      'snr_ok': ActivitySpectralOmegaEstimatorContract.snrOk,
      'affects_discover_ranking': false,
      'attaches_to_frequency_modes': false,
      'cadence_fallback_allowed': false,
      'rng_seed': 11,
      'case_count': cases.length,
      'status_histograms': {
        for (final f in {
          'clean_single_period',
          'noisy_periodic',
          'competing_periods',
          'harmonics',
          'civil_collision',
          'drifting_period',
          'missing_event_gaps',
          'bursty_nonperiodic',
          'random_activity',
          'bin_size_probe',
          'window_length',
          'long_time_stability',
        })
          f: statusHist(f),
      },
      'accuracy': {
        'clean_accept_rate': cleanAccepted / cleanTotal,
        'clean_mean_rel_err_T': mean(cleanErrs),
        'clean_mean_rel_err_omega': mean(cleanOmegaErrs),
        'clean_max_rel_err_T':
            cleanErrs.isEmpty ? null : cleanErrs.reduce(math.max),
      },
      'false_positives': {
        'random_ok_count': randomOk,
        'random_trials': randomTrials,
        'random_ok_rate': falsePositiveRate,
        'snr_ok_threshold': ActivitySpectralOmegaEstimatorContract.snrOk,
      },
      'civil_collision': {
        'cases': civil.length,
        'flagged': civilFlagged,
        'civil_collision_status': civilStatusOk,
      },
      'competing_periods': {
        'cases': competing.length,
        'ambiguous': competingAmbiguous,
      },
      'harmonics': {
        'cases': harmonics.length,
        'silent_harmonic_ok': harmonicSilentHarmonicOk,
        'results': [
          for (final c in harmonics)
            {
              'id': c['id'],
              'status': c['status'],
              'period_seconds': c['period_seconds'],
              'accepted': c['accepted'],
            },
        ],
      },
      'findings': findings,
      'ready_to_bind_phase_on_same_oscillator': readyToBindPhase,
      'recommendation': recommendation,
      'cases': cases,
    };

    final outDir = Directory('docs/matching/reports');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final outFile = File(
      'docs/matching/reports/activity_spectral_omega_stress_v1.json',
    );
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(report),
    );
    expect(outFile.existsSync(), isTrue);
  });
}
