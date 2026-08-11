import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/temporal_shadow.dart';

void main() {
  const extractor = TemporalShadowExtractor();
  const p = 'user_p';
  const q = 'user_q';
  const tz = Duration(hours: 3);

  DateTime utc(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  List<TemporalShadowEvent> eventsAt({
    required List<(String sender, int ms)> rows,
  }) =>
      [
        for (final r in rows)
          TemporalShadowEvent(timestampMs: r.$2, senderId: r.$1),
      ];

  group('TemporalShadowExtractor', () {
    test('sparse data → gated sparse/unavailable, still reports counts', () {
      final start = utc(0);
      final end = utc(const Duration(days: 2).inMilliseconds);
      final ev = eventsAt(rows: [
        (p, const Duration(hours: 1).inMilliseconds),
        (q, const Duration(hours: 2).inMilliseconds),
        (p, const Duration(hours: 3).inMilliseconds),
      ]);

      final r = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: ev,
        windowStart: start,
        windowEnd: end,
        localTimeZoneOffset: tz,
      );

      expect(r.dyadic.eventCountTotal, 3);
      expect(r.userP.eventCount, 2);
      expect(r.userQ.eventCount, 1);
      expect(
        r.userP.cadenceMeanPerSecond.status,
        TemporalFeatureStatus.sparse,
      );
      expect(
        r.dyadic.participationShareP.status,
        TemporalFeatureStatus.sparse,
      );
      expect(TemporalShadowThreadResult.gatesCalibrated, isFalse);
      expect(TemporalShadowThreadResult.omegaStatus,
          TemporalFeatureStatus.unavailable);
      expect(r.toWireMap()['omega'], {'status': 'unavailable'});
    });

    test('balanced vs imbalanced participation', () {
      final start = utc(0);
      final end = utc(const Duration(days: 10).inMilliseconds);
      final balanced = <(String, int)>[];
      final imbalanced = <(String, int)>[];
      for (var i = 0; i < 10; i++) {
        balanced.add((p, (i * 2) * 3600 * 1000));
        balanced.add((q, (i * 2 + 1) * 3600 * 1000));
        imbalanced.add((p, i * 3600 * 1000));
      }
      // 10p + 0q already; add nothing for q → 100/0
      // For 75/25 use 15p + 5q
      final mixed = <(String, int)>[];
      for (var i = 0; i < 15; i++) {
        mixed.add((p, i * 3600 * 1000));
      }
      for (var i = 0; i < 5; i++) {
        mixed.add((q, (100 + i) * 3600 * 1000));
      }

      final bal = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: balanced),
        windowStart: start,
        windowEnd: end,
      );
      expect(bal.dyadic.participationShareP.value, closeTo(0.5, 1e-12));
      expect(bal.dyadic.dyadicParticipationBalance.value, closeTo(1.0, 1e-12));
      expect(bal.dyadic.participationShareP.status, TemporalFeatureStatus.ok);

      final imb = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: imbalanced),
        windowStart: start,
        windowEnd: end,
      );
      expect(imb.dyadic.participationShareP.value, 1.0);
      expect(imb.dyadic.dyadicParticipationBalance.value, 0.0);

      final m75 = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: mixed),
        windowStart: start,
        windowEnd: end,
      );
      expect(m75.dyadic.participationShareP.value, closeTo(0.75, 1e-12));
      expect(m75.dyadic.dyadicParticipationBalance.value, closeTo(0.5, 1e-12));
    });

    test('regular vs bursty cadence', () {
      final start = utc(0);
      final end = utc(const Duration(days: 14).inMilliseconds);

      // Regular: every 3600s
      final regular = <(String, int)>[
        for (var i = 0; i < 12; i++) (p, i * 3600 * 1000),
      ];
      // Bursty: many close then long gap
      final bursty = <(String, int)>[
        (p, 0),
        (p, 1000),
        (p, 2000),
        (p, 3000),
        (p, 4000),
        (p, 5 * 3600 * 1000),
        (p, 5 * 3600 * 1000 + 1000),
        (p, 5 * 3600 * 1000 + 2000),
        (p, 10 * 3600 * 1000),
        (p, 10 * 3600 * 1000 + 500),
        (p, 12 * 3600 * 1000),
        (p, 12 * 3600 * 1000 + 800),
      ];

      // Need Q participant present in API; add minimal Q traffic far away
      for (final list in [regular, bursty]) {
        list.add((q, const Duration(days: 1).inMilliseconds));
        list.add((q, const Duration(days: 2).inMilliseconds));
      }

      final reg = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: regular),
        windowStart: start,
        windowEnd: end,
      );
      final bur = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: bursty),
        windowStart: start,
        windowEnd: end,
      );

      expect(reg.userP.burstiness.status, TemporalFeatureStatus.ok);
      expect(bur.userP.burstiness.status, TemporalFeatureStatus.ok);
      expect(reg.userP.regularity.value!, greaterThan(bur.userP.regularity.value!));
      expect(bur.userP.burstiness.value!, greaterThan(reg.userP.burstiness.value!));
      expect(reg.userP.cadenceMeanPerSecond.value, isNotNull);
      // cadence is rate, not omega
      expect(reg.toWireMap().containsKey('omega'), isTrue);
    });

    test('alternating turns produce reply/turn gap stats', () {
      final start = utc(0);
      final end = utc(const Duration(days: 14).inMilliseconds);
      final rows = <(String, int)>[];
      // Alternate every 30 minutes
      for (var i = 0; i < 20; i++) {
        rows.add((i.isEven ? p : q, i * 30 * 60 * 1000));
      }
      final r = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: rows),
        windowStart: start,
        windowEnd: end,
      );

      expect(r.dyadic.turnGapCount, greaterThanOrEqualTo(8));
      expect(r.dyadic.medianTurnGapSeconds.status, TemporalFeatureStatus.ok);
      expect(
        r.dyadic.medianTurnGapSeconds.value,
        closeTo(30 * 60.0, 1e-6),
      );
      expect(r.dyadic.replyGapCountPFromQ, greaterThan(0));
      expect(r.dyadic.replyGapCountQFromP, greaterThan(0));
    });

    test('symmetry P↔Q for participation balance and turn median', () {
      final start = utc(0);
      final end = utc(const Duration(days: 14).inMilliseconds);
      final rows = <(String, int)>[
        for (var i = 0; i < 12; i++) (i.isEven ? p : q, i * 3600 * 1000),
        for (var i = 0; i < 4; i++) (p, (20 + i) * 3600 * 1000),
      ];

      final ab = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: rows),
        windowStart: start,
        windowEnd: end,
        localTimeZoneOffset: tz,
      );
      final ba = extractor.extractThread(
        participantP: q,
        participantQ: p,
        events: eventsAt(rows: rows),
        windowStart: start,
        windowEnd: end,
        localTimeZoneOffset: tz,
      );

      expect(
        ab.dyadic.dyadicParticipationBalance.value,
        ba.dyadic.dyadicParticipationBalance.value,
      );
      expect(
        ab.dyadic.participationShareP.value! + ba.dyadic.participationShareP.value!,
        closeTo(1.0, 1e-12),
      );
      expect(
        ab.dyadic.medianTurnGapSeconds.value,
        ba.dyadic.medianTurnGapSeconds.value,
      );
    });

    test('missing timezone → circadian/hour unavailable', () {
      final start = utc(0);
      final end = utc(const Duration(days: 14).inMilliseconds);
      final rows = <(String, int)>[
        for (var i = 0; i < 20; i++)
          (i.isEven ? p : q, i * 3600 * 1000 + 15 * 3600 * 1000),
      ];
      final r = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: rows),
        windowStart: start,
        windowEnd: end,
        localTimeZoneOffset: null,
      );

      expect(r.localTimeZoneAvailable, isFalse);
      expect(
        r.userP.hourHistogramStatus.status,
        TemporalFeatureStatus.unavailable,
      );
      expect(r.userP.hourOfDayHistogram, isNull);
      expect(
        r.userP.circadianThetaBar.status,
        TemporalFeatureStatus.unavailable,
      );
      expect(
        r.userP.circadianRBar.status,
        TemporalFeatureStatus.unavailable,
      );
      expect(
        r.dyadic.circadianDeltaTheta.status,
        TemporalFeatureStatus.unavailable,
      );

      final withTzRows = <(String, int)>[
        for (var d = 0; d < 10; d++)
          (
            p,
            DateTime.utc(2024, 1, 1 + d, 18).millisecondsSinceEpoch,
          ),
        for (var d = 0; d < 10; d++)
          (
            q,
            DateTime.utc(2024, 1, 1 + d, 18, 0, 1).millisecondsSinceEpoch,
          ),
      ];
      final withTz = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: withTzRows),
        windowStart: DateTime.utc(2024, 1, 1),
        windowEnd: DateTime.utc(2024, 1, 20),
        localTimeZoneOffset: tz,
      );
      // Clustered at a consistent hour → concentrated circadian when TZ known.
      expect(withTz.localTimeZoneAvailable, isTrue);
      expect(
        withTz.userP.circadianRBar.status,
        isNot(TemporalFeatureStatus.unavailable),
      );
      expect(withTz.userP.circadianThetaBar.value, isNotNull);
    });

    test('system messages excluded; excludes non-participants', () {
      final start = utc(0);
      final end = utc(const Duration(days: 10).inMilliseconds);
      final r = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: [
          ('system', 1000),
          ('other', 2000),
          (p, 3000),
          (q, 4000),
        ]),
        windowStart: start,
        windowEnd: end,
      );
      expect(r.dyadic.eventCountTotal, 2);
    });

    test('circadian theta formula at known local noon', () {
      // UTC noon with tz=+0 → theta = π
      final noon = DateTime.utc(2024, 1, 1, 12).millisecondsSinceEpoch;
      final start = DateTime.utc(2024, 1, 1);
      final end = DateTime.utc(2024, 1, 20);
      final rows = <(String, int)>[
        for (var d = 0; d < 10; d++)
          (p, noon + d * const Duration(days: 1).inMilliseconds),
        for (var d = 0; d < 10; d++)
          (q, noon + d * const Duration(days: 1).inMilliseconds + 1000),
      ];
      final r = extractor.extractThread(
        participantP: p,
        participantQ: q,
        events: eventsAt(rows: rows),
        windowStart: start,
        windowEnd: end,
        localTimeZoneOffset: Duration.zero,
      );
      expect(r.userP.circadianThetaBar.status, TemporalFeatureStatus.ok);
      expect(r.userP.circadianThetaBar.value, closeTo(math.pi, 1e-6));
      expect(r.userP.circadianRBar.value!, greaterThan(0.9));
    });
  });

  group('isolation', () {
    test('no Discover / Persona / questionnaire coupling', () {
      final src = File(
        'lib/features/matching/domain/temporal_shadow_extractor.dart',
      ).readAsStringSync();
      expect(src.contains('DiscoverService'), isFalse);
      expect(src.contains('persona_scoring'), isFalse);
      expect(src.contains('CompatibilityScoring'), isFalse);
      expect(src.contains('measuredScores'), isFalse);

      final discover = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(discover.contains('TemporalShadowExtractor'), isFalse);
      expect(discover.contains('temporal_feature_extraction'), isFalse);
    });
  });
}
