import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/diagnostics/temporal_shadow_debug_diagnostics_runner.dart';
import 'package:qmatch/features/matching/diagnostics/temporal_shadow_debug_diagnostics_runner_contract.dart';
import 'package:qmatch/features/matching/domain/temporal_shadow.dart';

void main() {
  group('release isolation', () {
    test('refuses when debugModeOverride is false without collecting', () async {
      var collected = false;
      final runner = TemporalShadowDebugDiagnosticsRunner(
        debugModeOverride: false,
        collectOverride: ({
          Duration? localTimeZoneOffset,
          int maxThreads = 40,
          int maxMessagesPerThread = 500,
        }) async {
          collected = true;
          return TemporalShadowAggregateDiagnostics.noData('should_not_run');
        },
      );

      final report = await runner.run();
      expect(collected, isFalse);
      expect(report.refused, isTrue);
      expect(
        report.refusalReason,
        TemporalShadowDebugDiagnosticsRunnerContract.refusalRequiresDebugMode,
      );
      expect(report.writesPerformed, isFalse);
      expect(report.toWireMap()['production_ui_exposed'], isFalse);
      expect(report.toWireMap()['omega'], {'status': 'unavailable'});
    });

    test('contract freezes debug-only + no production UI + no ranking', () {
      expect(TemporalShadowDebugDiagnosticsRunnerContract.debugOnly, isTrue);
      expect(
        TemporalShadowDebugDiagnosticsRunnerContract.productionUiExposed,
        isFalse,
      );
      expect(
        TemporalShadowDebugDiagnosticsRunnerContract.persistsDerivedFeatures,
        isFalse,
      );
      expect(
        TemporalShadowDebugDiagnosticsRunnerContract.affectsDiscoverRanking,
        isFalse,
      );
    });

    test('production surfaces do not import the debug runner', () {
      final productionPaths = [
        'lib/features/discover/services/discover_service.dart',
        'lib/features/settings/screens/settings_screen.dart',
        'lib/features/debug/debug_home_screen.dart',
        'lib/main.dart',
      ];
      for (final path in productionPaths) {
        final src = File(path).readAsStringSync();
        expect(
          src,
          isNot(contains('temporal_shadow_debug_diagnostics_runner')),
          reason: path,
        );
        expect(
          src,
          isNot(contains('TemporalShadowDebugDiagnosticsRunner')),
          reason: path,
        );
      }
    });
  });

  group('aggregate output + no-data', () {
    test('clear no-data state when collect returns empty', () async {
      final runner = TemporalShadowDebugDiagnosticsRunner(
        debugModeOverride: true,
        collectOverride: ({
          Duration? localTimeZoneOffset,
          int maxThreads = 40,
          int maxMessagesPerThread = 500,
        }) async {
          return TemporalShadowAggregateDiagnostics.noData('no_threads');
        },
      );

      final report = await runner.run();
      expect(report.refused, isFalse);
      expect(report.hasData, isFalse);
      expect(report.noDataReason, 'no_threads');
      expect(report.threadCountExamined, 0);
      expect(report.totalEligibleEvents, 0);
      expect(report.writesPerformed, isFalse);
      expect(report.circadian['included'], isFalse);
    });

    test('summarize emits rates, cadence, burstiness, balance, turn-gap', () {
      const bridge = TemporalShadowDiagnosticsBridge();
      final t0 = DateTime.utc(2024, 1, 1, 12).millisecondsSinceEpoch;
      final events = <TemporalShadowEvent>[
        for (var i = 0; i < 8; i++)
          TemporalShadowEvent(
            timestampMs: t0 + i * 3600000,
            senderId: i.isEven ? 'a' : 'b',
          ),
      ];
      final agg = bridge.analyzeThreads(
        threads: [
          TemporalShadowThreadInput(
            threadId: 't1',
            participants: const ['a', 'b'],
            events: events,
          ),
        ],
        localTimeZoneOffset: const Duration(hours: 3),
      );

      final withTz = TemporalShadowDebugDiagnosticsRunner.summarizeAggregate(
        agg,
        timezoneProvided: true,
      );
      expect(withTz.hasData, isTrue);
      expect(withTz.threadCountWithResults, 1);
      expect(withTz.totalEligibleEvents, greaterThan(0));
      expect(withTz.featureStatusRates.containsKey('burstiness'), isTrue);
      expect(
        withTz.featureStatusRates['dyadic_participation_balance'],
        isNotNull,
      );
      expect(
        withTz.featureStatusRates['median_turn_gap_seconds'],
        isNotNull,
      );
      expect(withTz.cadenceMeanDistribution['count'], isNotNull);
      expect(withTz.burstinessDistribution.containsKey('p50'), isTrue);
      expect(withTz.participationBalanceDistribution.containsKey('mean'), isTrue);
      expect(withTz.turnGapDistribution.containsKey('min'), isTrue);
      expect(withTz.circadian['included'], isTrue);
      expect(
        (withTz.circadian['feature_status_rates'] as Map)
            .containsKey('circadian_theta_bar'),
        isTrue,
      );

      final noTz = TemporalShadowDebugDiagnosticsRunner.summarizeAggregate(
        agg,
        timezoneProvided: false,
      );
      expect(noTz.circadian['included'], isFalse);
      expect(noTz.circadian['reason'], 'timezone_not_provided');
    });
  });

  group('no body / persistence coupling', () {
    test('wire map never contains message body keys or secret text', () async {
      const bridge = TemporalShadowDiagnosticsBridge();
      final event = TemporalShadowDiagnosticsBridge.eventFromFirestoreMessageData({
        'sender_id': 'a',
        'client_created_at': 1700000000000,
        'text': 'SECRET_BODY_MUST_NOT_LEAK',
        'body': 'SECRET_BODY_MUST_NOT_LEAK',
      })!;
      final eventB =
          TemporalShadowDiagnosticsBridge.eventFromFirestoreMessageData({
        'sender_id': 'b',
        'client_created_at': 1700000001000,
        'content': 'SECRET_BODY_MUST_NOT_LEAK',
      })!;

      final agg = bridge.analyzeThreads(
        threads: [
          TemporalShadowThreadInput(
            threadId: 't',
            participants: const ['a', 'b'],
            events: [event, eventB],
          ),
        ],
      );

      final runner = TemporalShadowDebugDiagnosticsRunner(
        debugModeOverride: true,
        collectOverride: ({
          Duration? localTimeZoneOffset,
          int maxThreads = 40,
          int maxMessagesPerThread = 500,
        }) async =>
            agg,
      );
      final wire = (await runner.run()).toWireMap().toString();
      expect(wire, isNot(contains('SECRET_BODY')));
      expect(wire, isNot(contains("'text'")));
      expect(wire, isNot(contains("'body'")));
      expect(wire, isNot(contains('last_message_preview')));
    });

    test('runner + tool sources never write Firestore or touch Discover', () {
      final paths = [
        'lib/features/matching/diagnostics/temporal_shadow_debug_diagnostics_runner.dart',
        'lib/features/matching/diagnostics/temporal_shadow_debug_diagnostics_runner_contract.dart',
        'tool/temporal_shadow_real_diagnostics_runner.dart',
      ];
      for (final path in paths) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('features/discover')), reason: path);
        expect(src, isNot(contains('DiscoverService')), reason: path);
        expect(src, isNot(contains('CompatibilityScoring')), reason: path);
        expect(src, isNot(contains('.set(')), reason: path);
        expect(src, isNot(contains('.update(')), reason: path);
        expect(src, isNot(contains('writeBatch')), reason: path);
        expect(src, isNot(contains('Persona')), reason: path);
        expect(src.toLowerCase(), isNot(contains('quantum')), reason: path);
        expect(src.toLowerCase(), isNot(contains(' rvi')), reason: path);
      }
    });
  });
}
