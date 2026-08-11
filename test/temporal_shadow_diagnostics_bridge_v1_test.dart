import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/temporal_shadow.dart';

/// Duck-typed stand-in for cloud_firestore.Timestamp (domain must not import it).
class _MsTimestamp {
  const _MsTimestamp(this.millisecondsSinceEpoch);
  final int millisecondsSinceEpoch;
}

void main() {
  const bridge = TemporalShadowDiagnosticsBridge();

  group('TemporalShadowDiagnosticsBridge privacy', () {
    test('eventFromFirestoreMessageData ignores text/body/content fields', () {
      final event =
          TemporalShadowDiagnosticsBridge.eventFromFirestoreMessageData({
        'sender_id': 'u_a',
        'client_created_at': 1700000000000,
        'text': 'SECRET BODY MUST NOT REACH EXTRACTOR',
        'body': 'also secret',
        'content': 'also secret',
        'last_message_preview': 'preview leak',
      });

      expect(event, isNotNull);
      expect(event!.senderId, 'u_a');
      expect(event.timestampMs, 1700000000000);

      // TemporalShadowEvent has only metadata fields — no text accessor.
      expect(event.toString(), isNot(contains('SECRET')));
      expect(
        TemporalShadowDiagnosticsBridgeContract.forbiddenMessageFieldKeys,
        containsAll(['text', 'body', 'content', 'last_message_preview']),
      );
    });

    test('prefers client_created_at over created_at', () {
      final event =
          TemporalShadowDiagnosticsBridge.eventFromFirestoreMessageData({
        'sender_id': 'u_a',
        'client_created_at': 100,
        'created_at': const _MsTimestamp(999),
        'text': 'ignored',
      });
      expect(event!.timestampMs, 100);
    });

    test('falls back to created_at Timestamp duck-type', () {
      final event =
          TemporalShadowDiagnosticsBridge.eventFromFirestoreMessageData({
        'sender_id': 'u_b',
        'created_at': const _MsTimestamp(555),
        'text': 'ignored',
      });
      expect(event!.timestampMs, 555);
      expect(event.senderId, 'u_b');
    });

    test('returns null when sender or timestamp missing', () {
      expect(
        TemporalShadowDiagnosticsBridge.eventFromFirestoreMessageData({
          'text': 'only body',
          'client_created_at': 1,
        }),
        isNull,
      );
      expect(
        TemporalShadowDiagnosticsBridge.eventFromFirestoreMessageData({
          'sender_id': 'u_a',
          'text': 'no ts',
        }),
        isNull,
      );
    });
  });

  group('eligible participants only', () {
    test('non-participant and system senders do not inflate event counts', () {
      const t0 = 1700000000000;
      final diagnostic = bridge.analyzeThread(
        threadId: 't1',
        participants: const ['alice', 'bob'],
        events: [
          TemporalShadowEvent(timestampMs: t0, senderId: 'alice'),
          TemporalShadowEvent(timestampMs: t0 + 1000, senderId: 'bob'),
          TemporalShadowEvent(timestampMs: t0 + 2000, senderId: 'eve'),
          TemporalShadowEvent(
            timestampMs: t0 + 3000,
            senderId: TemporalShadowExtractorContract.systemSenderId,
          ),
          TemporalShadowEvent(timestampMs: t0 + 4000, senderId: 'alice'),
        ],
      );

      expect(diagnostic, isNotNull);
      expect(diagnostic!.eventCount, 3);
      expect(diagnostic.result.dyadic.eventCountP, 2);
      expect(diagnostic.result.dyadic.eventCountQ, 1);
      expect(diagnostic.result.dyadic.eventCountTotal, 3);
    });

    test('rejects non-dyad participant lists', () {
      expect(
        bridge.analyzeThread(
          threadId: 't2',
          participants: const ['only_one'],
          events: [
            TemporalShadowEvent(timestampMs: 1, senderId: 'only_one'),
          ],
        ),
        isNull,
      );
      expect(
        bridge.analyzeThread(
          threadId: 't3',
          participants: const ['a', 'b', 'c'],
          events: [
            TemporalShadowEvent(timestampMs: 1, senderId: 'a'),
            TemporalShadowEvent(timestampMs: 2, senderId: 'b'),
          ],
        ),
        isNull,
      );
    });
  });

  group('aggregate no-data + optional timezone', () {
    test('empty threads → clear no-data state', () {
      final agg = bridge.analyzeThreads(threads: const []);
      expect(agg.hasData, isFalse);
      expect(agg.noDataReason, 'no_threads');
      expect(agg.toWireMap()['has_data'], isFalse);
      expect(agg.toWireMap()['no_data_reason'], 'no_threads');
      expect(agg.toWireMap()['omega'], {'status': 'unavailable'});
    });

    test('threads without eligible events → no_eligible_events', () {
      final agg = bridge.analyzeThreads(
        threads: [
          TemporalShadowThreadInput(
            threadId: 'empty',
            participants: const ['a', 'b'],
            events: const [],
          ),
        ],
      );
      expect(agg.hasData, isFalse);
      expect(agg.noDataReason, 'no_eligible_events');
      expect(agg.threadCountExamined, 1);
      expect(agg.threadCountWithResults, 0);
    });

    test('real-shaped metadata yields has_data aggregate', () {
      const t0 = 1700000000000;
      final agg = bridge.analyzeThreads(
        threads: [
          TemporalShadowThreadInput(
            threadId: 't_ok',
            participants: const ['p', 'q'],
            events: [
              TemporalShadowEvent(timestampMs: t0, senderId: 'p'),
              TemporalShadowEvent(timestampMs: t0 + 60000, senderId: 'q'),
              TemporalShadowEvent(timestampMs: t0 + 120000, senderId: 'p'),
            ],
          ),
        ],
        localTimeZoneOffset: const Duration(hours: 3),
      );

      expect(agg.hasData, isTrue);
      expect(agg.noDataReason, isNull);
      expect(agg.threadCountWithResults, 1);
      expect(agg.uniqueUserCount, 2);
      expect(agg.totalEligibleEvents, 3);

      final wire = agg.toWireMap();
      expect(wire['shadow_only'], isTrue);
      expect(wire['persists_derived_features'], isFalse);
      expect(wire['affects_discover_ranking'], isFalse);
      expect(wire['gates_calibrated'], isFalse);

      // Sparse N still gates hour hist unavailable even when TZ is provided.
      expect(
        agg.threads.single.result.userP.hourHistogramStatus.status,
        TemporalFeatureStatus.unavailable,
      );
    });

    test('timezone offset enables hour histogram when N is sufficient', () {
      final t0 = DateTime.utc(2024, 1, 1, 12).millisecondsSinceEpoch;
      final events = <TemporalShadowEvent>[
        for (var i = 0; i < 6; i++)
          TemporalShadowEvent(
            timestampMs: t0 + i * 86400000,
            senderId: 'p',
          ),
        for (var i = 0; i < 6; i++)
          TemporalShadowEvent(
            timestampMs: t0 + i * 86400000 + 3600000,
            senderId: 'q',
          ),
      ];
      final withTz = bridge.analyzeThread(
        threadId: 'tz',
        participants: const ['p', 'q'],
        events: events,
        localTimeZoneOffset: const Duration(hours: 3),
      );
      final noTz = bridge.analyzeThread(
        threadId: 'tz',
        participants: const ['p', 'q'],
        events: events,
      );
      expect(
        withTz!.result.userP.hourHistogramStatus.status,
        TemporalFeatureStatus.sparse,
      );
      expect(
        noTz!.result.userP.hourHistogramStatus.status,
        TemporalFeatureStatus.unavailable,
      );
    });
  });

  group('no persistence / ranking coupling', () {
    test('contract freezes shadow-only + no persist + no discover ranking', () {
      expect(TemporalShadowDiagnosticsBridgeContract.shadowOnly, isTrue);
      expect(
        TemporalShadowDiagnosticsBridgeContract.persistsDerivedFeatures,
        isFalse,
      );
      expect(
        TemporalShadowDiagnosticsBridgeContract.affectsDiscoverRanking,
        isFalse,
      );
      expect(
        TemporalShadowDiagnosticsBridgeContract.policyStatus,
        'shadow_only_debug_not_live',
      );
    });

    test('bridge + firestore diagnostics sources do not import Discover', () {
      final roots = [
        'lib/features/matching/domain/temporal_shadow_diagnostics_bridge.dart',
        'lib/features/matching/domain/temporal_shadow_diagnostics_bridge_contract.dart',
        'lib/features/matching/diagnostics/temporal_shadow_firestore_diagnostics.dart',
      ];
      for (final path in roots) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('features/discover')), reason: path);
        expect(src, isNot(contains('DiscoverService')), reason: path);
        expect(src, isNot(contains('CompatibilityScoring')), reason: path);
        expect(src, isNot(contains('.set(')), reason: path);
        expect(src, isNot(contains('.update(')), reason: path);
        expect(src, isNot(contains('writeBatch')), reason: path);
      }
    });

    test('wire output never contains message body keys', () {
      const t0 = 1700000000000;
      final agg = bridge.analyzeThreads(
        threads: [
          TemporalShadowThreadInput(
            threadId: 't',
            participants: const ['a', 'b'],
            events: [
              TemporalShadowDiagnosticsBridge.eventFromFirestoreMessageData({
                'sender_id': 'a',
                'client_created_at': t0,
                'text': 'must not appear in wire',
              })!,
              TemporalShadowDiagnosticsBridge.eventFromFirestoreMessageData({
                'sender_id': 'b',
                'client_created_at': t0 + 1000,
                'body': 'must not appear',
              })!,
            ],
          ),
        ],
      );
      final encoded = agg.toWireMap().toString();
      expect(encoded, isNot(contains('must not appear')));
      expect(encoded, isNot(contains("'text'")));
      expect(encoded, isNot(contains("'body'")));
    });
  });
}
