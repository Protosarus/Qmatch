import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/temporal_shadow.dart';

/// Offline synthetic stress harness for TemporalShadowExtractor v1.
/// Does not wire Discover. Writes a local diagnostic report only.
void main() {
  test('temporal shadow extractor synthetic stress report', () {
    const extractor = TemporalShadowExtractor();
    const p = 'user_p';
    const q = 'user_q';
    final rng = math.Random(42);

    DateTime utcMs(int ms) =>
        DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

    List<TemporalShadowEvent> ev(List<(String, int)> rows) => [
          for (final r in rows)
            TemporalShadowEvent(timestampMs: r.$2, senderId: r.$1),
        ];

    Map<String, dynamic> gated(GatedDouble g) => {
          'status': g.status.name,
          'value': g.value,
        };

    Map<String, dynamic> summarizeUser(TemporalShadowUserFeatures u) => {
          'event_count': u.eventCount,
          'interval_count': u.interEventIntervalsSeconds.length,
          'cadence_mean_per_day': gated(
            GatedDouble(
              status: u.cadenceMeanPerSecond.status,
              value: u.cadenceMeanPerSecond.value == null
                  ? null
                  : u.cadenceMeanPerSecond.value! * 86400,
            ),
          ),
          'cadence_median_per_day': gated(
            GatedDouble(
              status: u.cadenceMedianPerSecond.status,
              value: u.cadenceMedianPerSecond.value == null
                  ? null
                  : u.cadenceMedianPerSecond.value! * 86400,
            ),
          ),
          'burstiness': gated(u.burstiness),
          'regularity': gated(u.regularity),
          'hour_hist_status': u.hourHistogramStatus.status.name,
          'circadian_theta': gated(u.circadianThetaBar),
          'circadian_r': gated(u.circadianRBar),
        };

    Map<String, dynamic> run({
      required String id,
      required String expected,
      required List<(String, int)> rows,
      required DateTime start,
      required DateTime end,
      Duration? tz,
    }) {
      final r = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: ev(rows),
        windowStart: start,
        windowEnd: end,
        localTimeZoneOffset: tz,
      );
      return {
        'id': id,
        'expected': expected,
        'observed': {
          'user_p': summarizeUser(r.userP),
          'user_q': summarizeUser(r.userQ),
          'dyadic': {
            'n_p': r.dyadic.eventCountP,
            'n_q': r.dyadic.eventCountQ,
            'participation_share_p': gated(r.dyadic.participationShareP),
            'participation_balance': gated(r.dyadic.dyadicParticipationBalance),
            'median_turn_gap_s': gated(r.dyadic.medianTurnGapSeconds),
            'median_reply_p_from_q_s':
                gated(r.dyadic.medianReplyGapPFromQSeconds),
            'median_reply_q_from_p_s':
                gated(r.dyadic.medianReplyGapQFromPSeconds),
            'turn_gap_count': r.dyadic.turnGapCount,
            'circadian_delta_theta': gated(r.dyadic.circadianDeltaTheta),
          },
          'local_tz_available': r.localTimeZoneAvailable,
          'omega': TemporalShadowThreadResult.omegaStatus.name,
        },
      };
    }

    final start = DateTime.utc(2024, 1, 1);
    final end = DateTime.utc(2024, 1, 15); // 14 days
    final startMs = start.millisecondsSinceEpoch;

    List<(String, int)> regular(int n, int intervalSec, {String who = p}) => [
          for (var i = 0; i < n; i++) (who, startMs + i * intervalSec * 1000),
        ];

    // 1. Perfectly regular (P every hour, light Q)
    final s1 = run(
      id: 'perfectly_regular',
      expected: 'B≈-1, high regularity, cadence ok',
      rows: [
        ...regular(48, 3600),
        ...[
          for (var i = 0; i < 12; i++)
            (q, startMs + (i * 2 + 1) * 3600 * 1000),
        ],
      ],
      start: start,
      end: end,
      tz: Duration.zero,
    );

    // 2. Highly bursty
    final burstRows = <(String, int)>[];
    var t = startMs;
    for (var b = 0; b < 8; b++) {
      for (var j = 0; j < 6; j++) {
        burstRows.add((p, t));
        t += 2000; // 2s within burst
      }
      t += 12 * 3600 * 1000; // long quiet
    }
    for (var i = 0; i < 10; i++) {
      burstRows.add((q, startMs + (i + 1) * 86400 * 1000));
    }
    final s2 = run(
      id: 'highly_bursty',
      expected: 'B high (near +1), regularity low',
      rows: burstRows,
      start: start,
      end: end,
      tz: Duration.zero,
    );

    // 3. Fast vs slow cadence
    final s3fast = run(
      id: 'fast_cadence',
      expected: 'high cadence_mean/median',
      rows: [
        ...regular(60, 600), // every 10 min
        ...regular(20, 3600, who: q),
      ],
      start: start,
      end: end,
    );
    final s3slow = run(
      id: 'slow_cadence',
      expected: 'low cadence_mean/median',
      rows: [
        ...regular(20, 12 * 3600), // every 12h
        ...regular(10, 24 * 3600, who: q),
      ],
      start: start,
      end: end,
    );

    // 4. Balanced 50/50
    final bal = <(String, int)>[
      for (var i = 0; i < 40; i++)
        (i.isEven ? p : q, startMs + i * 1800 * 1000),
    ];
    final s4 = run(
      id: 'balanced_50_50',
      expected: 'share=0.5, balance=1.0',
      rows: bal,
      start: start,
      end: end,
    );

    // 5. Strongly imbalanced
    final imb = <(String, int)>[
      for (var i = 0; i < 36; i++) (p, startMs + i * 3600 * 1000),
      for (var i = 0; i < 4; i++) (q, startMs + (40 + i) * 3600 * 1000),
    ];
    final s5 = run(
      id: 'imbalanced_90_10',
      expected: 'share≈0.9, balance≈0.2',
      rows: imb,
      start: start,
      end: end,
    );

    // 6. Alternating fast replies
    final fastAlt = <(String, int)>[
      for (var i = 0; i < 40; i++)
        (i.isEven ? p : q, startMs + i * 60 * 1000), // 1 min turns
    ];
    final s6 = run(
      id: 'alternating_fast_replies',
      expected: 'median turn gap ≈ 60s, ok',
      rows: fastAlt,
      start: start,
      end: end,
    );

    // 7. Long delayed turns
    final slowAlt = <(String, int)>[
      for (var i = 0; i < 24; i++)
        (i.isEven ? p : q, startMs + i * 6 * 3600 * 1000), // 6h
    ];
    final s7 = run(
      id: 'long_delayed_turns',
      expected: 'median turn gap ≈ 6h',
      rows: slowAlt,
      start: start,
      end: end,
    );

    // 8. Sparse/noisy
    final sparse = <(String, int)>[
      (p, startMs + 1000),
      (q, startMs + 2000),
      ('system', startMs + 3000),
      ('noise', startMs + 4000),
      (p, startMs + 2 * 86400 * 1000),
    ];
    final s8 = run(
      id: 'sparse_noisy',
      expected: 'sparse/unavailable gates; system/noise dropped',
      rows: sparse,
      start: start,
      end: DateTime.utc(2024, 1, 4),
    );

    // 9. Clear circadian cluster (local evenings via tz=+3 → UTC 15:00 = local 18:00)
    final circ = <(String, int)>[
      for (var d = 0; d < 12; d++)
        (
          p,
          DateTime.utc(2024, 1, 1 + d, 15).millisecondsSinceEpoch,
        ),
      for (var d = 0; d < 12; d++)
        (
          q,
          DateTime.utc(2024, 1, 1 + d, 15, 5).millisecondsSinceEpoch,
        ),
    ];
    final s9 = run(
      id: 'clear_circadian_cluster',
      expected: 'high R, theta near evening, delta≈0',
      rows: circ,
      start: start,
      end: end,
      tz: const Duration(hours: 3),
    );

    // 10. Uniform 24h activity
    final uniform = <(String, int)>[
      for (var d = 0; d < 10; d++)
        for (var h = 0; h < 24; h++)
          (
            (h + d).isEven ? p : q,
            DateTime.utc(2024, 1, 1 + d, h).millisecondsSinceEpoch,
          ),
    ];
    final s10 = run(
      id: 'uniform_24h',
      expected: 'low R → circadian unavailable or sparse',
      rows: uniform,
      start: start,
      end: end,
      tz: Duration.zero,
    );

    // 11. Timezone shift (same UTC stamps, different tz)
    final clusterUtc = <(String, int)>[
      for (var d = 0; d < 10; d++)
        (p, DateTime.utc(2024, 1, 1 + d, 12).millisecondsSinceEpoch),
      for (var d = 0; d < 10; d++)
        (q, DateTime.utc(2024, 1, 1 + d, 12, 1).millisecondsSinceEpoch),
    ];
    final s11a = run(
      id: 'timezone_utc0',
      expected: 'theta≈π (noon)',
      rows: clusterUtc,
      start: start,
      end: end,
      tz: Duration.zero,
    );
    final s11b = run(
      id: 'timezone_plus3',
      expected: 'theta shifts by +3h vs utc0',
      rows: clusterUtc,
      start: start,
      end: end,
      tz: const Duration(hours: 3),
    );
    final s11c = run(
      id: 'timezone_missing',
      expected: 'circadian unavailable',
      rows: clusterUtc,
      start: start,
      end: end,
      tz: null,
    );

    // 12. System/non-participant noise
    final noise = <(String, int)>[
      for (var i = 0; i < 20; i++) (p, startMs + i * 3600 * 1000),
      for (var i = 0; i < 20; i++) (q, startMs + (i * 2 + 1) * 1800 * 1000),
      for (var i = 0; i < 50; i++) ('system', startMs + i * 1000),
      for (var i = 0; i < 50; i++) ('intruder', startMs + i * 1500),
    ];
    final s12 = run(
      id: 'system_nonparticipant_noise',
      expected: 'counts ignore system/intruder',
      rows: noise,
      start: start,
      end: end,
    );

    // Monte Carlo sensitivity: small N
    final smallN = <Map<String, dynamic>>[];
    for (final n in [2, 3, 4, 5, 6, 8, 10, 12]) {
      final rows = <(String, int)>[
        for (var i = 0; i < n; i++) (p, startMs + i * 3600 * 1000),
        for (var i = 0; i < math.max(1, n ~/ 2); i++)
          (q, startMs + (i * 2 + 1) * 3600 * 1000),
      ];
      final r = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: ev(rows),
        windowStart: start,
        windowEnd: end,
      );
      smallN.add({
        'n_p': n,
        'burstiness': gated(r.userP.burstiness),
        'regularity': gated(r.userP.regularity),
        'cadence_mean': gated(r.userP.cadenceMeanPerSecond),
        'participation_balance': gated(r.dyadic.dyadicParticipationBalance),
      });
    }

    // Correlation sample over random threads
    final corrRows = <Map<String, double?>>[];
    for (var i = 0; i < 200; i++) {
      final rows = <(String, int)>[];
      var tp = startMs;
      var tq = startMs + 1000;
      final nP = 8 + rng.nextInt(40);
      final nQ = 8 + rng.nextInt(40);
      for (var k = 0; k < nP; k++) {
        tp += (300 + rng.nextInt(7200)) * 1000;
        rows.add((p, tp));
      }
      for (var k = 0; k < nQ; k++) {
        tq += (300 + rng.nextInt(7200)) * 1000;
        rows.add((q, tq));
      }
      final r = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: ev(rows),
        windowStart: start,
        windowEnd: DateTime.utc(2024, 2, 1),
      );
      corrRows.add({
        'burstiness': r.userP.burstiness.value,
        'regularity': r.userP.regularity.value,
        'cadence_mean': r.userP.cadenceMeanPerSecond.value,
        'cadence_median': r.userP.cadenceMedianPerSecond.value,
        'balance': r.dyadic.dyadicParticipationBalance.value,
        'turn_gap': r.dyadic.medianTurnGapSeconds.value,
      });
    }

    double? pearson(String a, String b) {
      final xs = <double>[];
      final ys = <double>[];
      for (final row in corrRows) {
        final x = row[a];
        final y = row[b];
        if (x == null || y == null) continue;
        xs.add(x);
        ys.add(y);
      }
      if (xs.length < 10) return null;
      final mx = xs.reduce((u, v) => u + v) / xs.length;
      final my = ys.reduce((u, v) => u + v) / ys.length;
      var num = 0.0, dx = 0.0, dy = 0.0;
      for (var i = 0; i < xs.length; i++) {
        final da = xs[i] - mx;
        final db = ys[i] - my;
        num += da * db;
        dx += da * da;
        dy += db * db;
      }
      final den = math.sqrt(dx * dy);
      if (den == 0) return null;
      return num / den;
    }

    final report = {
      'title': 'Temporal Shadow Extractor v1 synthetic stress',
      'shadow_only': true,
      'gates_calibrated': false,
      'omega': 'always_unavailable',
      'scenarios': [
        s1,
        s2,
        s3fast,
        s3slow,
        s4,
        s5,
        s6,
        s7,
        s8,
        s9,
        s10,
        s11a,
        s11b,
        s11c,
        s12,
      ],
      'small_n_sensitivity': smallN,
      'correlations_random_n200': {
        'burstiness_vs_regularity': pearson('burstiness', 'regularity'),
        'cadence_mean_vs_median': pearson('cadence_mean', 'cadence_median'),
        'burstiness_vs_cadence_mean': pearson('burstiness', 'cadence_mean'),
        'regularity_vs_cadence_mean': pearson('regularity', 'cadence_mean'),
        'balance_vs_turn_gap': pearson('balance', 'turn_gap'),
      },
    };

    final outDir = Directory('docs/matching/reports');
    outDir.createSync(recursive: true);
    final out = File('${outDir.path}/temporal_shadow_extractor_stress_v1.json');
    const encoder = JsonEncoder.withIndent('  ');
    out.writeAsStringSync(encoder.convert(report));

    // Sanity asserts for harness itself
    expect(
      (s1['observed'] as Map)['user_p'] as Map,
      isNotEmpty,
    );
    expect(
      (((s4['observed'] as Map)['dyadic'] as Map)['participation_balance']
          as Map)['value'],
      closeTo(1.0, 1e-9),
    );
    expect(
      (((s5['observed'] as Map)['dyadic'] as Map)['participation_share_p']
          as Map)['value'],
      closeTo(0.9, 1e-9),
    );

    // ignore: avoid_print
    print(encoder.convert({
      'wrote': out.path,
      'scenario_count': (report['scenarios'] as List).length,
      'correlations': report['correlations_random_n200'],
      'highlights': {
        'regular_B': ((s1['observed'] as Map)['user_p']
            as Map)['burstiness'],
        'bursty_B': ((s2['observed'] as Map)['user_p'] as Map)['burstiness'],
        'fast_cadence_day': ((s3fast['observed'] as Map)['user_p']
            as Map)['cadence_mean_per_day'],
        'slow_cadence_day': ((s3slow['observed'] as Map)['user_p']
            as Map)['cadence_mean_per_day'],
        'circadian_cluster': ((s9['observed'] as Map)['user_p']
            as Map)['circadian_r'],
        'uniform_circadian': ((s10['observed'] as Map)['user_p']
            as Map)['circadian_r'],
        'tz_missing': ((s11c['observed'] as Map)['user_p']
            as Map)['circadian_theta'],
      },
    }));
  });
}
