import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/navigation/assessment_progress_route_gate.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2_contract.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_runtime_test_screen_factory.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_runtime_result_policy.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/screens/frequency_intro_screen.dart';
import 'package:qmatch/features/assessment/screens/frequency_v2_test_screen.dart';
import 'package:qmatch/features/assessment/screens/persona_assignment_gate_screen.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import 'package:qmatch/features/assessment/services/assessment_progress_service.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/services/discover_ranking_mode.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_dual_path_collector.dart';
import 'package:qmatch/features/discover/services/discover_structural_l2_ranking.dart';

Map<String, dynamic> _validFrequencyV2({
  String source = FrequencyV2ResultAuthority.resultSource,
}) {
  return {
    'schema_version': FrequencyV2ResultAuthority.resultSchemaVersion,
    'assessment_type': FrequencyV2ResultAuthority.assessmentType,
    'status': FrequencyV2ResultAuthority.resultStatus,
    'source': source,
    'dimensions': [
      for (final id in FrequencyBehaviorV2Contract.canonicalDimensions)
        {
          'dimension_id': id,
          'normalized_behavior': 0.1,
          'provisional_confidence': 1,
          'confidence_completeness': 1,
        },
    ],
  };
}

Map<String, dynamic> _validPersona() {
  return {
    'primary_persona_id': 'kararli',
    'secondary_persona_id': 'empat',
    'raw_delta_d': 0.18,
    'scoring_version': PersonaRuntimeResultPolicy.scoringVersion,
    'config_version': PersonaRuntimeResultPolicy.configVersion,
    'policy_version': PersonaRuntimeResultPolicy.policyVersion,
    'prototype_version': PersonaRuntimeResultPolicy.prototypeVersion,
  };
}

DiscoverUserModel _candidate(String uid) {
  return DiscoverUserModel(
    uid: uid,
    name: uid,
    age: 28,
    lastActiveAt: Timestamp.fromMillisecondsSinceEpoch(1),
  );
}

void main() {
  test('A/B default and release/profile policy resolve V2', () {
    expect(FrequencyRuntimeSelectionPolicy.resolve(), FrequencyRuntimeTrack.v2);
    expect(
      FrequencyRuntimeSelectionPolicy.resolve(debugInternalV2Override: false),
      FrequencyRuntimeTrack.v2,
    );
    expect(
      FrequencyRuntimeSelectionPolicy.resolve(
        isRuntimeSelectable: (_) => false,
      ),
      FrequencyRuntimeTrack.v2,
    );
    expect(FrequencyRuntimeSelectionPolicy.isV2RuntimeSelectable, isTrue);
    expect(FrequencyRuntimeTrack.values, [FrequencyRuntimeTrack.v2]);
  });

  test('C no production client path constructs FrequencyTestScreen', () {
    final roots = [
      'lib/core',
      'lib/features/assessment/screens',
      'lib/features/assessment/domain/frequency_v2_runtime',
      'lib/features/debug',
    ];
    for (final root in roots) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('frequency_test_screen.dart')) continue;
        final src = entity.readAsStringSync();
        expect(src.contains('FrequencyTestScreen('), isFalse,
            reason: entity.path);
        expect(src.contains('const FrequencyTestScreen'), isFalse,
            reason: entity.path);
      }
    }
    expect(
      FrequencyRuntimeTestScreenFactory.build(),
      isA<FrequencyV2TestScreen>(),
    );
  });

  test('D onboarding factory and intro route to FrequencyV2TestScreen', () {
    expect(
      FrequencyRuntimeTestScreenFactory.build(),
      isA<FrequencyV2TestScreen>(),
    );
    final intro = File(
      'lib/features/assessment/screens/frequency_intro_screen.dart',
    ).readAsStringSync();
    expect(intro.contains('FrequencyRuntimeTestScreenFactory.build()'), isTrue);
    expect(intro.contains('FrequencyTestScreen'), isFalse);
    final built = buildAssessmentDestination(
      const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.frequency,
        openAssessmentTestScreen: false,
        reason: 'progress_routing',
      ),
    );
    expect(built, isA<FrequencyIntroScreen>());
  });

  test('E cold-start pending V2 resumes V2', () {
    final pending = AssessmentColdStartPendingReconciler.decide(
      iqPendingFinalization: false,
      eqPendingFinalization: false,
      frequencyPendingFinalization: false,
      frequencyV2PendingFinalization: true,
      progressDestination: AssessmentFlowDestination.main,
    );
    expect(pending.reason, 'frequency_v2_pending_finalization');
    expect(pending.openAssessmentTestScreen, isTrue);
    final widget = buildAssessmentDestination(pending);
    expect(widget, isA<FrequencyV2TestScreen>());
  });

  test('F/G successful and already-finalized V2 continue to Persona', () {
    final screen = File(
      'lib/features/assessment/screens/frequency_v2_test_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('PersonaAssignmentGateScreen'), isTrue);
    expect(screen.contains('productCompletion'), isTrue);
    expect(screen.contains('internalCompletionTitle'), isFalse);
    expect(screen.contains('Frequency V2 internal test completed'), isFalse);
    final pipeline = File(
      'lib/features/assessment/services/frequency_v2_pending_finalization_pipeline.dart',
    ).readAsStringSync();
    expect(pipeline.contains('FREQUENCY_V2_ALREADY_FINALIZED'), isTrue);
    expect(pipeline.contains('productCompletion'), isTrue);
    expect(
      buildAssessmentDestination(
        const AssessmentColdStartDecision(
          destination: AssessmentFlowDestination.persona,
          openAssessmentTestScreen: false,
          reason: 'v2_persona_required',
        ),
      ),
      isA<PersonaAssignmentGateScreen>(),
    );
  });

  test('H/I authoritative V2 completes Frequency and restart skips it', () {
    final v2 = _validFrequencyV2();
    expect(FrequencyV2ResultAuthority.isAuthoritativeCompleted(v2), isTrue);
    expect(
      FrequencyV2ResultAuthority.isAuthoritativeCompleted(
        _validFrequencyV2(source: 'client_frequency_v2_write'),
      ),
      isFalse,
    );

    final afterV2 = AssessmentProgressService.resolveFromMaps(
      userDoc: {
        'assessment_flow_version': 2,
        'iq_completed': true,
        'eq_completed': true,
      },
      iqAssessment: {'status': 'completed'},
      eqAssessment: {'status': 'completed'},
      frequencyV2Assessment: v2,
    );
    expect(afterV2.frequencyCompleted, isTrue);
    expect(afterV2.resolutionSource, 'v2_assessments_complete');
    expect(afterV2.destination, AssessmentFlowDestination.persona);
    expect(afterV2.reason, 'v2_persona_required');

    final restarted = AssessmentProgressService.resolveFromMaps(
      userDoc: {
        'assessment_flow_version': 2,
        'iq_completed': true,
        'eq_completed': true,
        'profile_completed': true,
      },
      iqAssessment: {'status': 'completed'},
      eqAssessment: {'status': 'completed'},
      frequencyV2Assessment: v2,
      personaAssessment: _validPersona(),
    );
    expect(restarted.frequencyCompleted, isTrue);
    expect(restarted.destination, AssessmentFlowDestination.main);
    expect(restarted.destination, isNot(AssessmentFlowDestination.frequency));
  });

  test('K grandfather V1 Frequency completion still routes without V2', () {
    final grandfather = AssessmentProgressService.resolveFromMaps(
      userDoc: {
        'assessment_flow_version': 2,
        'iq_completed': true,
        'eq_completed': true,
        'frequency_completed': true,
        'profile_completed': true,
      },
      iqAssessment: {'status': 'completed'},
      eqAssessment: {'status': 'completed'},
      frequencyAssessment: {
        'status': 'completed',
        'canonical_profile_ready': true,
        'missing_dimensions': <String>[],
      },
      personaAssessment: _validPersona(),
    );
    expect(grandfather.frequencyCompleted, isTrue);
    expect(grandfather.destination, AssessmentFlowDestination.main);
    expect(grandfather.resolutionSource, isNot('frequency_v2'));
  });

  test('L/M/N live fusion ranks V2; V1 Frequency is unused; missing V2 is safe',
      () {
    expect(
      DiscoverRankingMode.active,
      DiscoverRankingMode.compatibilityFusionV2,
    );
    expect(
      DiscoverStructuralL2Ranking.modeWireValue,
      'compatibility_fusion_v2',
    );
    expect(
      DiscoverStructuralL2Ranking.fusionPolicyVersion,
      'qmatch_compatibility_fusion_v2_policy_v1',
    );

    final high = DiscoverStageB2TrustedPairResult(
      available: true,
      structuralDistance: 0.4,
      totalCoverage: 1,
      comparableDimensions: 14,
      compatibilityV2: const DiscoverStageB2CompatibilityV2Diagnostic(
        available: true,
        compatibilityIndex: 80,
        policyVersion: 'qmatch_compatibility_fusion_v2_policy_v1',
        structuralFit: 0.6,
        frequencyFit: 1,
        structuralCoverage: 1,
        frequencyPairSupport: 1,
      ),
    );
    final missingV2 = DiscoverStageB2TrustedPairResult(
      available: true,
      structuralDistance: 0.05,
      totalCoverage: 1,
      comparableDimensions: 14,
    );
    expect(missingV2.fusionRankDistance, isNull);
    expect(high.fusionRankDistance, closeTo(0.2, 1e-9));

    final ranked = DiscoverStructuralL2Ranking.rankL1Batch(
      l1Eligible: [_candidate('fusion'), _candidate('fallback')],
      pairsByUid: {'fusion': high, 'fallback': missingV2},
    );
    expect(ranked.map((c) => c.uid).toList(), ['fallback', 'fusion']);

    final rankingSrc = File(
      'lib/features/discover/services/discover_structural_l2_ranking.dart',
    ).readAsStringSync();
    expect(rankingSrc.contains('V1 Frequency is never an input'), isTrue);
    expect(rankingSrc.contains('frequency_fit_index'), isFalse);
  });

  test(
      'J/O/P/Q Discover grant stays server-owned; no adapter or canonical write',
      () {
    final eligibility =
        File('functions/src/discover_eligibility.js').readAsStringSync();
    expect(
        eligibility.contains('trusted_discover_assessment_grant_v2'), isTrue);
    expect(eligibility.contains('hasTrustedIqEq'), isTrue);
    expect(eligibility.contains('isTrustedFrequencyV2Proof'), isTrue);

    final index = File('functions/index.js').readAsStringSync();
    expect(
        index.contains('recomputeDiscoverEligibleOnFrequencyV2Write'), isTrue);
    expect(index.contains("document: 'users/{uid}/assessments/frequency_v2'"),
        isTrue);

    final finalize =
        File('functions/src/finalize_frequency_v2_v1.js').readAsStringSync();
    expect(finalize.contains("RESULT_DOC_ID = 'frequency_v2'"), isTrue);
    expect(finalize.contains("doc('canonical_v1')"), isFalse);
    expect(finalize.contains('discover_eligible'), isTrue);
    expect(
      finalize.contains("update({\n    discover_eligible"),
      isFalse,
    );

    final dartLib =
        Directory('lib').listSync(recursive: true).whereType<File>();
    for (final file in dartLib) {
      if (!file.path.endsWith('.dart')) continue;
      final src = file.readAsStringSync();
      expect(src.contains('12D→6D'), isFalse, reason: file.path);
      expect(src.contains('12d_to_6d'), isFalse, reason: file.path);
      expect(src.contains('FrequencyV2ToCanonical'), isFalse,
          reason: file.path);
      expect(src.contains("'discover_eligible': true"), isFalse,
          reason: file.path);
      expect(src.contains('"discover_eligible": true'), isFalse,
          reason: file.path);
    }

    final mapper = File(
      'lib/features/assessment/domain/frequency_v2_runtime/frequency_v2_finalize_request_mapper.dart',
    ).readAsStringSync();
    expect(mapper.contains("'canonical_v1'"), isTrue);
    expect(mapper.contains('forbiddenAuthorityKeys'), isTrue);
  });
}
