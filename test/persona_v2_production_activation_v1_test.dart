import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_scoring/eq_scoring_contract.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2_contract.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'package:qmatch/features/assessment/domain/iq_scoring/iq_scoring_contract.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';
import 'package:qmatch/features/assessment/domain/profile/qmatch_profile_contract.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/services/assessment_progress_service.dart';

Map<String, dynamic> _validFrequencyV2({
  Map<String, double>? signed,
  String source = FrequencyV2ResultAuthority.resultSource,
}) {
  final values = signed ??
      {
        for (final id in FrequencyBehaviorV2Contract.canonicalDimensions)
          id: 0.1,
      };
  return {
    'schema_version': FrequencyV2ResultAuthority.resultSchemaVersion,
    'assessment_type': FrequencyV2ResultAuthority.assessmentType,
    'status': FrequencyV2ResultAuthority.resultStatus,
    'source': source,
    'bank_version': FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    'dimensions': [
      for (final id in FrequencyBehaviorV2Contract.canonicalDimensions)
        {
          'dimension_id': id,
          'normalized_behavior': values[id] ?? 0.1,
          'provisional_confidence': 1,
          'confidence_completeness': 1,
        },
    ],
  };
}

Map<String, dynamic> _iqEqCanonical({double value = 0.55}) {
  return {
    'measured_dimensions': [
      for (final id in PersonaV2Contract.iq)
        {
          'dimension_id': id,
          'module': 'iq',
          'measurement_state': 'measured',
          'value': value,
          'reliability_status':
              QmatchProfileContract.reliabilityStatusNotCalibrated,
        },
      for (final id in PersonaV2Contract.eq)
        {
          'dimension_id': id,
          'module': 'eq',
          'measurement_state': 'measured',
          'value': value,
          'reliability_status':
              QmatchProfileContract.reliabilityStatusNotCalibrated,
        },
    ],
  };
}

Map<String, dynamic> _module({
  required String policy,
  required String bank,
  required Iterable<String> dims,
}) {
  return {
    'status': 'completed',
    'scoring_policy_version': policy,
    'bank_version': bank,
    'dimension_evidence_counts': {for (final d in dims) d: 6},
  };
}

Map<String, dynamic> _legacyPersonaDoc() {
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

void main() {
  late PersonaProfileCatalog catalog;
  late PersonaShadowScoringConfig shadowConfig;
  late PersonaV2Scorer scorer;

  setUpAll(() {
    final loaded = PersonaScoringFileLoader.loadShadowFromRepoRoot(
      Directory.current.path,
    );
    catalog = loaded.catalog;
    shadowConfig = loaded.config;
    scorer = PersonaV2Scorer(legacyCatalog: catalog);
  });

  PersonaV2HandoffRequest request({
    Map<String, double>? v2Unit,
    double iqEq = 0.55,
    String owner = 'uid_v2_persona',
  }) {
    final scores = <String, double>{
      for (final d in PersonaV2Contract.iq) d: iqEq,
      for (final d in PersonaV2Contract.eq) d: iqEq,
      for (final d in PersonaV2Contract.frequencyV2) d: v2Unit?[d] ?? 0.55,
    };
    return PersonaV2HandoffRequest(
      ownerUid: owner,
      dimensionScores: scores,
      dimensionEvidenceCounts: {
        for (final d in PersonaV2Contract.all) d: 4,
      },
      iqScoringPolicyVersion: IqScoringContract.scoringPolicyVersion,
      eqScoringPolicyVersion: EqScoringContract.scoringPolicyVersion,
      frequencyV2ScoringPolicyVersion:
          FrequencyBehaviorV2Contract.scoringPolicyVersion,
      iqBankOrSessionVersion: 'iq_bank_tr_v1',
      eqBankOrSessionVersion: 'eq_bank_tr_v1',
      frequencyV2BankOrSessionVersion:
          FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    );
  }

  test('A/B/C/F V2-only user assigns Persona without V1 Frequency or 6D',
      () async {
    final writes = <Map<String, dynamic>>[];
    final coordinator = PersonaAssignmentCoordinator(
      v2ScorerOverride: scorer,
      handoffPersistence: PersonaRuntimeHandoffPersistence(
        writeForUidOverride: (uid, fields) async {
          writes.add(Map<String, dynamic>.from(fields));
        },
      ),
      loadPersonaDoc: (_) async => null,
      loadCanonicalProfile: (_) async => _iqEqCanonical(),
      loadAssessment: (uid, type) async {
        switch (type) {
          case 'iq':
            return _module(
              policy: IqScoringContract.scoringPolicyVersion,
              bank: 'iq_bank_tr_v1',
              dims: PersonaV2Contract.iq,
            );
          case 'eq':
            return _module(
              policy: EqScoringContract.scoringPolicyVersion,
              bank: 'eq_bank_tr_v1',
              dims: PersonaV2Contract.eq,
            );
          case 'frequency_v2':
            return _validFrequencyV2(
              signed: {
                for (final id
                    in FrequencyBehaviorV2Contract.canonicalDimensions)
                  id: id == 'autonomy'
                      ? 0.95
                      : id == 'contact_need'
                          ? -0.9
                          : -0.2,
              },
            );
          case 'frequency':
            fail('V1 Frequency must not be required');
          default:
            return null;
        }
      },
    );

    final outcome = await coordinator.resolveForUid('uid_v2_only');
    expect(outcome.ok, isTrue, reason: '${outcome.error}');
    expect(outcome.source, PersonaAssignmentSource.assigned);
    expect(writes, hasLength(1));
    expect(writes.single['scoring_version'], PersonaV2Contract.scoringVersion);
    expect(writes.single['source'], PersonaV2Contract.source);
    expect(writes.single.containsKey('canonical_v1'), isFalse);
    expect(
      PersonaRuntimeResultPolicy.isCurrentValid(writes.single),
      isTrue,
    );

    final reuse = PersonaAssignmentCoordinator(
      v2ScorerOverride: scorer,
      handoffPersistence: PersonaRuntimeHandoffPersistence(
        writeForUidOverride: (uid, fields) async {
          fail('must not assign a second time');
        },
      ),
      loadPersonaDoc: (_) async => writes.single,
      loadCanonicalProfile: (_) async {
        fail('reuse must not reload canonical');
      },
      loadAssessment: (_, __) async {
        fail('reuse must not reload assessments');
      },
    );
    final second = await reuse.resolveForUid('uid_v2_only');
    expect(second.ok, isTrue);
    expect(second.source, PersonaAssignmentSource.reused);
    expect(second.result!.primaryPersonaId, outcome.result!.primaryPersonaId);
  });

  test('D no 12D→6D adapter exists', () {
    for (final path in [
      'lib/features/assessment/domain/persona_scoring/persona_v2_contract.dart',
      'lib/features/assessment/domain/persona_scoring/persona_v2_request_builder.dart',
      'lib/features/assessment/domain/persona_scoring/persona_v2_scorer.dart',
      'lib/features/assessment/domain/persona_scoring/persona_assignment_coordinator.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src.contains('12d_to_6d'), isFalse, reason: path);
      expect(src.contains('depth_preference'), isFalse, reason: path);
      expect(src.contains('communication_pace'), isFalse, reason: path);
      expect(src.contains('spontaneity'), isFalse, reason: path);
      expect(src.contains('stability'), isFalse, reason: path);
      expect(src.contains("assessmentType: 'frequency'"), isFalse,
          reason: path);
    }
    expect(
      Directory('lib').listSync(recursive: true).whereType<File>().any(
            (f) =>
                f.path.toLowerCase().contains('12d') &&
                f.path.toLowerCase().contains('6d'),
          ),
      isFalse,
    );
  });

  test('E malformed or missing Frequency V2 fails safely', () async {
    Future<PersonaAssignmentOutcome> run(Map<String, dynamic>? v2) {
      return PersonaAssignmentCoordinator(
        v2ScorerOverride: scorer,
        handoffPersistence: PersonaRuntimeHandoffPersistence(
          writeForUidOverride: (uid, fields) async {
            fail('must not persist on invalid V2');
          },
        ),
        loadPersonaDoc: (_) async => null,
        loadCanonicalProfile: (_) async => _iqEqCanonical(),
        loadAssessment: (uid, type) async {
          switch (type) {
            case 'iq':
              return _module(
                policy: IqScoringContract.scoringPolicyVersion,
                bank: 'iq_bank_tr_v1',
                dims: PersonaV2Contract.iq,
              );
            case 'eq':
              return _module(
                policy: EqScoringContract.scoringPolicyVersion,
                bank: 'eq_bank_tr_v1',
                dims: PersonaV2Contract.eq,
              );
            case 'frequency_v2':
              return v2;
            default:
              return null;
          }
        },
      ).resolveForUid('uid_bad_v2');
    }

    final missing = await run(null);
    expect(missing.ok, isFalse);
    expect(missing.result, isNull);

    final malformed = await run(
      _validFrequencyV2(source: 'client_frequency_v2_write'),
    );
    expect(malformed.ok, isFalse);
    expect(malformed.result, isNull);

    final untrustedWithLegacyV1 = await PersonaAssignmentCoordinator(
      v2ScorerOverride: scorer,
      handoffPersistence: PersonaRuntimeHandoffPersistence(
        writeForUidOverride: (uid, fields) async {
          fail('must not persist when V2 is untrusted');
        },
      ),
      loadPersonaDoc: (_) async => null,
      loadCanonicalProfile: (_) async => _iqEqCanonical(),
      loadAssessment: (uid, type) async {
        switch (type) {
          case 'iq':
            return _module(
              policy: IqScoringContract.scoringPolicyVersion,
              bank: 'iq_bank_tr_v1',
              dims: PersonaV2Contract.iq,
            );
          case 'eq':
            return _module(
              policy: EqScoringContract.scoringPolicyVersion,
              bank: 'eq_bank_tr_v1',
              dims: PersonaV2Contract.eq,
            );
          case 'frequency_v2':
            return _validFrequencyV2(source: 'client_frequency_v2_write');
          case 'frequency':
            fail('untrusted V2 must not fall through to V1 Frequency');
          default:
            return null;
        }
      },
    ).resolveForUid('uid_untrusted_v2');
    expect(untrustedWithLegacyV1.ok, isFalse);
    expect(untrustedWithLegacyV1.result, isNull);
  });

  test('G restart after V2 finalize without Persona resumes at Persona', () {
    final snap = AssessmentProgressService.resolveFromMaps(
      userDoc: {
        'assessment_flow_version': 2,
        'iq_completed': true,
        'eq_completed': true,
      },
      iqAssessment: {'status': 'completed'},
      eqAssessment: {'status': 'completed'},
      frequencyV2Assessment: _validFrequencyV2(),
    );
    expect(snap.frequencyCompleted, isTrue);
    expect(snap.destination, AssessmentFlowDestination.persona);
    expect(snap.canonicalPersonaAvailable, isFalse);
  });

  test('H existing Persona is not overwritten', () async {
    var writes = 0;
    final coordinator = PersonaAssignmentCoordinator(
      v2ScorerOverride: scorer,
      handoffPersistence: PersonaRuntimeHandoffPersistence(
        writeForUidOverride: (uid, fields) async {
          writes++;
        },
      ),
      loadPersonaDoc: (_) async => _legacyPersonaDoc(),
      loadCanonicalProfile: (_) async {
        fail('reuse must not reload canonical');
      },
      loadAssessment: (_, __) async {
        fail('reuse must not reload assessments');
      },
    );
    final outcome = await coordinator.resolveForUid('uid_keep');
    expect(outcome.ok, isTrue);
    expect(outcome.source, PersonaAssignmentSource.reused);
    expect(outcome.result!.primaryPersonaId, 'kararli');
    expect(writes, 0);
  });

  test('I legacy V1 Frequency users still assign on the 20D path', () async {
    final loaded = PersonaScoringFileLoader.loadShadowFromRepoRoot(
      Directory.current.path,
    );
    final writes = <Map<String, dynamic>>[];
    final coordinator = PersonaAssignmentCoordinator(
      handoffOverride: PersonaRuntimeHandoffService(
        scorer: CanonicalPersonaShadowScorer(
          catalog: loaded.catalog,
          config: loaded.config,
        ),
      ),
      handoffPersistence: PersonaRuntimeHandoffPersistence(
        writeForUidOverride: (uid, fields) async {
          writes.add(Map<String, dynamic>.from(fields));
        },
      ),
      loadPersonaDoc: (_) async => null,
      loadCanonicalProfile: (_) async => {
        'registry_version': catalog.dimensionRegistryVersion,
        'measured_dimensions': [
          for (final id in PersonaDimensionIds.all)
            {
              'dimension_id': id,
              'module': PersonaDimensionIds.groupOf(id),
              'measurement_state': 'measured',
              'value': 0.5,
              'reliability_status':
                  QmatchProfileContract.reliabilityStatusNotCalibrated,
            },
        ],
      },
      loadAssessment: (uid, type) async {
        switch (type) {
          case 'iq':
            return _module(
              policy: IqScoringContract.scoringPolicyVersion,
              bank: 'iq_bank_tr_v1',
              dims: PersonaDimensionIds.iq,
            )..['dimension_evidence_counts'] = {
                for (final d in PersonaDimensionIds.iq) d: shadowConfig.nMin(d),
              };
          case 'eq':
            return _module(
              policy: EqScoringContract.scoringPolicyVersion,
              bank: 'eq_bank_tr_v1',
              dims: PersonaDimensionIds.eq,
            )..['dimension_evidence_counts'] = {
                for (final d in PersonaDimensionIds.eq) d: shadowConfig.nMin(d),
              };
          case 'frequency':
            return _module(
              policy: 'frequency_6d_uncalibrated_signed_evidence_v1',
              bank: 'frequency_bank_tr_v1',
              dims: PersonaDimensionIds.frequency,
            )..['dimension_evidence_counts'] = {
                for (final d in PersonaDimensionIds.frequency)
                  d: shadowConfig.nMin(d),
              };
          default:
            return null;
        }
      },
    );
    final outcome = await coordinator.resolveForUid('uid_legacy');
    expect(outcome.ok, isTrue);
    expect(
        writes.single['scoring_version'], PersonaShadowContract.scoringVersion);
    expect(writes.single.containsKey('source'), isFalse);
  });

  test('J/K different V2 profiles are deterministic and not a Sezgisel default',
      () {
    PersonaV2HandoffRequest exact(String personaId) {
      final persona = catalog.personas.firstWhere(
        (p) => p.personaId == personaId,
      );
      return PersonaV2HandoffRequest(
        ownerUid: 'uid_$personaId',
        dimensionScores: {
          for (final d in PersonaV2Contract.iq) d: persona.targetVector[d]!,
          for (final d in PersonaV2Contract.eq) d: persona.targetVector[d]!,
          ...PersonaV2FrequencyPrototypes.requireUnitTarget(personaId),
        },
        dimensionEvidenceCounts: {
          for (final d in PersonaV2Contract.all) d: 4,
        },
        iqScoringPolicyVersion: IqScoringContract.scoringPolicyVersion,
        eqScoringPolicyVersion: EqScoringContract.scoringPolicyVersion,
        frequencyV2ScoringPolicyVersion:
            FrequencyBehaviorV2Contract.scoringPolicyVersion,
        iqBankOrSessionVersion: 'iq_bank_tr_v1',
        eqBankOrSessionVersion: 'eq_bank_tr_v1',
        frequencyV2BankOrSessionVersion:
            FrequencyBehaviorV2Contract.poolVersionTrDraft1,
      );
    }

    const ids = ['bagimsiz', 'sifaci', 'muhafiz', 'iletisimci'];
    final assigned = <String, String>{};
    for (final id in ids) {
      final first = scorer.assign(exact(id));
      final second = scorer.assign(exact(id));
      expect(first.primaryPersonaId, id);
      expect(second.primaryPersonaId, first.primaryPersonaId);
      expect(second.secondaryPersonaId, first.secondaryPersonaId);
      expect(second.rawDeltaD, first.rawDeltaD);
      assigned[id] = first.primaryPersonaId;
    }
    expect(assigned.values.toSet(), hasLength(ids.length));

    final midV2 = scorer.assign(
      request(
        v2Unit: {
          for (final d in PersonaV2Contract.frequencyV2) d: 0.5,
        },
      ),
    );
    expect(midV2.primaryPersonaId, isNotEmpty);
    expect(
      PersonaV2FrequencyPrototypes.unitTargets['sezgisel']!.values.every(
        (v) => (v - 0.5).abs() < 1e-9,
      ),
      isFalse,
    );

    final scorerSrc = File(
      'lib/features/assessment/domain/persona_scoring/persona_v2_scorer.dart',
    ).readAsStringSync();
    expect(scorerSrc.contains("= 'sezgisel'"), isFalse);
    expect(scorerSrc.contains('Random'), isFalse);
    expect(scorerSrc.contains('fallback'), isFalse);
  });

  test('L successful Persona continues to ProfileSetup', () {
    final gate = File(
      'lib/features/assessment/screens/persona_assignment_gate_screen.dart',
    ).readAsStringSync();
    expect(gate.contains('AssessmentFlowCompleteScreen'), isTrue);
    expect(gate.contains('PersonaRevealScreen'), isTrue);

    final after = AssessmentProgressService.resolveFromMaps(
      userDoc: {
        'assessment_flow_version': 2,
        'iq_completed': true,
        'eq_completed': true,
        'profile_completed': false,
      },
      iqAssessment: {'status': 'completed'},
      eqAssessment: {'status': 'completed'},
      frequencyV2Assessment: _validFrequencyV2(),
      personaAssessment: {
        'primary_persona_id': 'bagimsiz',
        'secondary_persona_id': 'analist',
        'raw_delta_d': 0.04,
        'scoring_version': PersonaV2Contract.scoringVersion,
        'config_version': PersonaV2Contract.configVersion,
        'policy_version': PersonaV2Contract.policyVersion,
        'prototype_version': PersonaV2Contract.prototypeVersion,
        'source': PersonaV2Contract.source,
      },
    );
    expect(after.canonicalPersonaAvailable, isTrue);
    expect(after.destination, AssessmentFlowDestination.profileSetup);
  });

  test('M no client Discover/completion self-grant is introduced', () {
    final files = [
      'lib/features/assessment/domain/persona_scoring/persona_v2_scorer.dart',
      'lib/features/assessment/domain/persona_scoring/persona_v2_request_builder.dart',
      'lib/features/assessment/domain/persona_scoring/persona_assignment_coordinator.dart',
    ];
    for (final path in files) {
      final src = File(path).readAsStringSync();
      expect(src.contains("'discover_eligible': true"), isFalse);
      expect(src.contains("'frequency_completed': true"), isFalse);
    }
  });

  test('20D midpoint Sezgisel is scorer geometry, not a V2 fallback', () {
    final loaded = PersonaScoringFileLoader.loadShadowFromRepoRoot(
      Directory.current.path,
    );
    final shadow = CanonicalPersonaShadowScorer(
      catalog: loaded.catalog,
      config: loaded.config,
    );
    final mid = PersonaRuntimeHandoffService(scorer: shadow).assign(
      PersonaRuntimeHandoffRequest(
        ownerUid: 'uid_mid',
        dimensionScores: {
          for (final d in loaded.catalog.dimensionOrder) d: 0.5,
        },
        dimensionEvidenceCounts: {
          for (final d in loaded.catalog.dimensionOrder)
            d: loaded.config.nMin(d),
        },
        iqCompleted: true,
        eqCompleted: true,
        frequencyCompleted: true,
        iqScoringPolicyVersion: IqScoringContract.scoringPolicyVersion,
        eqScoringPolicyVersion: EqScoringContract.scoringPolicyVersion,
        frequencyScoringPolicyVersion:
            'frequency_6d_uncalibrated_signed_evidence_v1',
        iqBankOrSessionVersion: 'iq_bank_tr_v1',
        eqBankOrSessionVersion: 'eq_bank_tr_v1',
        frequencyBankOrSessionVersion: 'frequency_bank_tr_v1',
        dimensionRegistryVersion: loaded.catalog.dimensionRegistryVersion,
      ),
    );
    expect(mid.primaryPersonaId, 'sezgisel');
  });
}
