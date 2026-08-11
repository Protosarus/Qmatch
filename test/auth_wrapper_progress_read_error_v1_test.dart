import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/navigation/assessment_progress_route_gate.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget harness({
    required Future<AssessmentColdStartDecision> Function(String uid)
        resolveRoute,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AssessmentProgressRouteGate(
        uid: 'uid-test',
        resolveRoute: resolveRoute,
        buildDestination: (decision) => Text(
          key: Key(
            'auth-dest-${decision.destination.name}'
            '-${decision.openAssessmentTestScreen ? 'test' : 'intro'}',
          ),
          'routed:${decision.destination.name}:${decision.reason}',
        ),
      ),
    );
  }

  testWidgets('progress read fails → error/retry, no IQ redirect',
      (tester) async {
    await tester.pumpWidget(
      harness(
        resolveRoute: (_) async {
          throw Exception('firestore_unavailable');
        },
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('auth-assessment-progress-error')),
        findsOneWidget);
    expect(find.byKey(const Key('auth-assessment-progress-retry')),
        findsOneWidget);
    expect(find.byKey(const Key('auth-dest-iq-intro')), findsNothing);
    expect(find.byKey(const Key('auth-dest-iq-test')), findsNothing);
    expect(find.textContaining('routed:iq'), findsNothing);
  });

  testWidgets('retry succeeds → correct stage is routed', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      harness(
        resolveRoute: (_) async {
          calls++;
          if (calls == 1) {
            throw Exception('network_blip');
          }
          return const AssessmentColdStartDecision(
            destination: AssessmentFlowDestination.eq,
            openAssessmentTestScreen: false,
            reason: 'progress_routing',
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('auth-assessment-progress-error')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('auth-assessment-progress-retry')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('auth-assessment-progress-error')),
        findsNothing);
    expect(find.byKey(const Key('auth-dest-eq-intro')), findsOneWidget);
    expect(find.text('routed:eq:progress_routing'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('normal routing remains unchanged for each destination',
      (tester) async {
    final cases = <AssessmentColdStartDecision>[
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.iq,
        openAssessmentTestScreen: false,
        reason: 'progress_routing',
      ),
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.iq,
        openAssessmentTestScreen: true,
        reason: 'iq_pending_finalization',
      ),
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.eq,
        openAssessmentTestScreen: false,
        reason: 'progress_routing',
      ),
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.frequency,
        openAssessmentTestScreen: true,
        reason: 'frequency_pending_finalization',
      ),
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.persona,
        openAssessmentTestScreen: false,
        reason: 'progress_routing',
      ),
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.profileSetup,
        openAssessmentTestScreen: false,
        reason: 'progress_routing',
      ),
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.main,
        openAssessmentTestScreen: false,
        reason: 'progress_routing',
      ),
    ];

    for (final decision in cases) {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AssessmentProgressRouteGate(
            key: ValueKey(
              '${decision.destination.name}-'
              '${decision.openAssessmentTestScreen}-'
              '${decision.reason}',
            ),
            uid: 'uid-test',
            resolveRoute: (_) async => decision,
            buildDestination: (d) => Text(
              key: Key(
                'auth-dest-${d.destination.name}'
                '-${d.openAssessmentTestScreen ? 'test' : 'intro'}',
              ),
              'routed:${d.destination.name}:${d.reason}',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final suffix = decision.openAssessmentTestScreen ? 'test' : 'intro';
      expect(
        find.byKey(Key('auth-dest-${decision.destination.name}-$suffix')),
        findsOneWidget,
        reason: decision.reason,
      );
      expect(find.byKey(const Key('auth-assessment-progress-error')),
          findsNothing);
    }
  });

  test('AuthWrapper no longer falls back to IQ Intro on progress error', () {
    final wrapper =
        File('lib/core/navigation/auth_wrapper.dart').readAsStringSync();
    final gate = File('lib/core/navigation/assessment_progress_route_gate.dart')
        .readAsStringSync();

    expect(wrapper.contains('AssessmentProgressRouteGate'), isTrue);
    expect(wrapper.contains('IQTestIntroScreen'), isFalse);

    expect(gate.contains('AssessmentProgressService().resolveForUid'), isTrue);
    expect(
      gate.contains('AssessmentColdStartPendingReconciler().reconcile'),
      isTrue,
    );
    expect(gate.contains('AuthAssessmentProgressErrorScaffold'), isTrue);
    expect(
      gate.contains('routeSnap.hasError || !routeSnap.hasData'),
      isTrue,
    );
    // Error path must not open IQ intro.
    final errorBlockStart =
        gate.indexOf('if (routeSnap.hasError || !routeSnap.hasData)');
    expect(errorBlockStart, greaterThanOrEqualTo(0));
    final errorBlock = gate.substring(errorBlockStart, errorBlockStart + 180);
    expect(errorBlock.contains('IQTestIntroScreen'), isFalse);
    expect(errorBlock.contains('AuthAssessmentProgressErrorScaffold'), isTrue);
  });
}
