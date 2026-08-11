import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_scoring/eq_scoring_contract.dart';
import 'package:qmatch/features/assessment/domain/frequency_scoring/frequency_scoring_contract.dart';
import 'package:qmatch/features/assessment/domain/iq_scoring/iq_scoring_contract.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';
import 'package:qmatch/features/assessment/domain/profile/qmatch_profile_contract.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/screens/assessment_flow_complete_screen.dart';
import 'package:qmatch/features/assessment/screens/persona_assignment_gate_screen.dart';
import 'package:qmatch/features/assessment/services/assessment_progress_service.dart';
import 'package:qmatch/l10n/app_localizations.dart';

Map<String, dynamic> _validPersonaDoc({
  String primary = 'kararli',
  String secondary = 'empat',
}) {
  return {
    'primary_persona_id': primary,
    'secondary_persona_id': secondary,
    'raw_delta_d': 0.18,
    'scoring_version': PersonaRuntimeResultPolicy.scoringVersion,
    'config_version': PersonaRuntimeResultPolicy.configVersion,
    'policy_version': PersonaRuntimeResultPolicy.policyVersion,
    'prototype_version': PersonaRuntimeResultPolicy.prototypeVersion,
  };
}

Map<String, dynamic> _completedModule({
  required String policy,
  required String bank,
  required Map<String, int> evidence,
}) {
  return {
    'status': 'completed',
    'scoring_policy_version': policy,
    'bank_version': bank,
    'dimension_evidence_counts': evidence,
  };
}

List<Map<String, dynamic>> _measured20d(List<String> order) {
  return [
    for (final id in order)
      {
        'dimension_id': id,
        'module': PersonaDimensionIds.iq.contains(id)
            ? 'iq'
            : PersonaDimensionIds.eq.contains(id)
                ? 'eq'
                : 'frequency',
        'measurement_state': 'measured',
        'value': 0.5,
        'reliability_status':
            QmatchProfileContract.reliabilityStatusNotCalibrated,
      },
  ];
}

void main() {
  late CanonicalPersonaShadowScorer scorer;
  late PersonaRuntimeHandoffService handoff;
  late PersonaProfileCatalog catalog;
  late PersonaShadowScoringConfig config;

  setUpAll(() {
    final loaded = PersonaScoringFileLoader.loadShadowFromRepoRoot(
      Directory.current.path,
    );
    catalog = loaded.catalog;
    config = loaded.config;
    scorer = CanonicalPersonaShadowScorer(
      catalog: catalog,
      config: config,
    );
    handoff = PersonaRuntimeHandoffService(scorer: scorer);
  });

  Map<String, int> fullCounts() => {
        for (final d in catalog.dimensionOrder) d: config.nMin(d),
      };

  Map<String, dynamic> canonicalProfile() => {
        'registry_version': catalog.dimensionRegistryVersion,
        'measured_dimensions': _measured20d(catalog.dimensionOrder),
      };

  group('progress routing: Frequency complete → Persona', () {
    test('normal Frequency completion without Persona → persona destination',
        () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
          'frequency_completed': true,
          'assessment_flow_completed': true,
          'profile_completed': false,
        },
        iqAssessment: {'status': 'completed'},
        eqAssessment: {'status': 'completed'},
        frequencyAssessment: {
          'status': 'completed',
          'canonical_profile_ready': true,
          'missing_dimensions': <String>[],
        },
      );
      expect(s.destination, AssessmentFlowDestination.persona);
      expect(s.canonicalPersonaAvailable, isFalse);
      expect(s.reason, 'v2_persona_required');
    });

    test('existing current-version Persona → profile setup (no re-assign)', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
          'frequency_completed': true,
          'assessment_flow_completed': true,
          'profile_completed': false,
        },
        iqAssessment: {'status': 'completed'},
        eqAssessment: {'status': 'completed'},
        frequencyAssessment: {
          'status': 'completed',
          'canonical_profile_ready': true,
        },
        personaAssessment: _validPersonaDoc(),
      );
      expect(s.canonicalPersonaAvailable, isTrue);
      expect(s.destination, AssessmentFlowDestination.profileSetup);
    });

    test('cold start: completed 20D battery without Persona → persona', () {
      final s = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
          'frequency_completed': true,
          'assessment_flow_completed': true,
          'profile_completed': true,
        },
        iqAssessment: {'status': 'completed'},
        eqAssessment: {'status': 'completed'},
        frequencyAssessment: {
          'status': 'completed',
          'canonical_profile_ready': true,
        },
      );
      expect(s.destination, AssessmentFlowDestination.persona);
      expect(s.reason, 'v2_persona_required');
    });
  });

  group('PersonaAssignmentCoordinator', () {
    test('reuses valid current Persona without assignAndPersist', () async {
      var assignCalls = 0;
      final persistence = PersonaRuntimeHandoffPersistence(
        writeForUidOverride: (uid, fields) async {
          assignCalls++;
        },
      );
      final coordinator = PersonaAssignmentCoordinator(
        handoffPersistence: persistence,
        handoffOverride: handoff,
        loadPersonaDoc: (_) async => _validPersonaDoc(),
        loadCanonicalProfile: (_) async {
          fail('should not load profile when reusing');
        },
        loadAssessment: (_, __) async {
          fail('should not load assessments when reusing');
        },
      );

      final outcome = await coordinator.resolveForUid('uid_reuse');
      expect(outcome.ok, isTrue);
      expect(outcome.source, PersonaAssignmentSource.reused);
      expect(outcome.result!.primaryPersonaId, 'kararli');
      expect(assignCalls, 0);
    });

    test('missing Persona → assignAndPersist once', () async {
      final writes = <Map<String, dynamic>>[];
      final persistence = PersonaRuntimeHandoffPersistence(
        writeForUidOverride: (uid, fields) async {
          writes.add(Map<String, dynamic>.from(fields));
        },
      );
      final evidence = fullCounts();
      final coordinator = PersonaAssignmentCoordinator(
        handoffPersistence: persistence,
        handoffOverride: handoff,
        loadPersonaDoc: (_) async => null,
        loadCanonicalProfile: (_) async => canonicalProfile(),
        loadAssessment: (uid, type) async {
          switch (type) {
            case 'iq':
              return _completedModule(
                policy: IqScoringContract.scoringPolicyVersion,
                bank: 'iq_bank_tr_v1',
                evidence: {
                  for (final d in PersonaDimensionIds.iq) d: evidence[d]!,
                },
              );
            case 'eq':
              return _completedModule(
                policy: EqScoringContract.scoringPolicyVersion,
                bank: 'eq_bank_tr_v1',
                evidence: {
                  for (final d in PersonaDimensionIds.eq) d: evidence[d]!,
                },
              );
            case 'frequency':
              return _completedModule(
                policy: FrequencyScoringContract.scoringPolicyVersion,
                bank: 'frequency_bank_tr_v1',
                evidence: {
                  for (final d in PersonaDimensionIds.frequency)
                    d: evidence[d]!,
                },
              );
            default:
              return null;
          }
        },
      );

      final outcome = await coordinator.resolveForUid('uid_assign');
      expect(outcome.ok, isTrue);
      expect(outcome.source, PersonaAssignmentSource.assigned);
      expect(writes, hasLength(1));
      expect(writes.single['primary_persona_id'], isNotEmpty);
      expect(
        writes.single['scoring_version'],
        PersonaShadowContract.scoringVersion,
      );
    });

    test('persistence failure surfaces as fail outcome', () async {
      final evidence = fullCounts();
      final persistence = PersonaRuntimeHandoffPersistence(
        writeForUidOverride: (uid, fields) async {
          throw StateError('firestore write failed');
        },
      );
      final coordinator = PersonaAssignmentCoordinator(
        handoffPersistence: persistence,
        handoffOverride: handoff,
        loadPersonaDoc: (_) async => null,
        loadCanonicalProfile: (_) async => canonicalProfile(),
        loadAssessment: (uid, type) async {
          switch (type) {
            case 'iq':
              return _completedModule(
                policy: IqScoringContract.scoringPolicyVersion,
                bank: 'iq_bank_tr_v1',
                evidence: {
                  for (final d in PersonaDimensionIds.iq) d: evidence[d]!,
                },
              );
            case 'eq':
              return _completedModule(
                policy: EqScoringContract.scoringPolicyVersion,
                bank: 'eq_bank_tr_v1',
                evidence: {
                  for (final d in PersonaDimensionIds.eq) d: evidence[d]!,
                },
              );
            case 'frequency':
              return _completedModule(
                policy: FrequencyScoringContract.scoringPolicyVersion,
                bank: 'frequency_bank_tr_v1',
                evidence: {
                  for (final d in PersonaDimensionIds.frequency)
                    d: evidence[d]!,
                },
              );
            default:
              return null;
          }
        },
      );

      final outcome = await coordinator.resolveForUid('uid_fail');
      expect(outcome.ok, isFalse);
      expect(outcome.error, isA<StateError>());
    });
  });

  group('PersonaAssignmentGateScreen', () {
    testWidgets('persistence failure → retry; then reveal', (tester) async {
      var attempts = 0;
      final coordinator = PersonaAssignmentCoordinator(
        loadPersonaDoc: (_) async {
          attempts++;
          if (attempts == 1) {
            throw StateError('transient persist failure');
          }
          return _validPersonaDoc(primary: 'analist', secondary: 'empat');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: PersonaAssignmentGateScreen(
            profileCompleted: false,
            uidOverride: 'uid_gate_retry',
            coordinator: coordinator,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('persona-assignment-error')), findsOneWidget);
      expect(find.byKey(const Key('persona-reveal-continue')), findsNothing);

      await tester.tap(find.byKey(const Key('persona-assignment-retry')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('persona-assignment-error')), findsNothing);
      expect(find.byKey(const Key('persona-reveal-continue')), findsOneWidget);
      expect(attempts, 2);
    });

    testWidgets('Continue → AssessmentFlowCompleteScreen', (tester) async {
      final coordinator = PersonaAssignmentCoordinator(
        loadPersonaDoc: (_) async =>
            _validPersonaDoc(primary: 'analist', secondary: 'empat'),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: PersonaAssignmentGateScreen(
            profileCompleted: false,
            uidOverride: 'uid_gate_continue',
            coordinator: coordinator,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('persona-reveal-continue')), findsOneWidget);
      await tester.tap(find.byKey(const Key('persona-reveal-continue')));
      await tester.pumpAndSettle();

      expect(find.byType(AssessmentFlowCompleteScreen), findsOneWidget);
      expect(find.byType(PersonaAssignmentGateScreen), findsNothing);
    });
  });

  group('live wiring isolation', () {
    test('Frequency navigates to Persona gate; scoring unchanged', () {
      final screen = File(
        'lib/features/assessment/screens/frequency_test_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('PersonaAssignmentGateScreen'), isTrue);
      expect(screen.contains('AssessmentFlowCompleteScreen'), isFalse);
      expect(screen.contains('PersonaScoringService'), isFalse);
      expect(screen.contains('assignAndPersist'), isFalse);

      final gate = File(
        'lib/features/assessment/screens/persona_assignment_gate_screen.dart',
      ).readAsStringSync();
      expect(gate.contains('PersonaAssignmentCoordinator'), isTrue);
      expect(gate.contains('PersonaRevealScreen'), isTrue);
      expect(gate.contains('AssessmentFlowCompleteScreen'), isTrue);
      expect(gate.contains('PersonaScoringService'), isFalse);

      final routeGate = File(
        'lib/core/navigation/assessment_progress_route_gate.dart',
      ).readAsStringSync();
      expect(
        routeGate.contains('AssessmentFlowDestination.persona'),
        isTrue,
      );
      expect(routeGate.contains('PersonaAssignmentGateScreen'), isTrue);
    });

    test('policy rejects legacy affinity/confidence payloads', () {
      final legacy = {
        ..._validPersonaDoc(),
        'confidence': 0.9,
      };
      expect(PersonaRuntimeResultPolicy.isCurrentValid(legacy), isFalse);
      expect(
        PersonaRuntimeResultPolicy.isCurrentValid(_validPersonaDoc()),
        isTrue,
      );
    });
  });
}
