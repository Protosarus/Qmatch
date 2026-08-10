import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_scoring/eq_scoring_contract.dart';
import 'package:qmatch/features/assessment/domain/frequency_scoring/frequency_scoring_contract.dart';
import 'package:qmatch/features/assessment/domain/iq_scoring/iq_scoring_contract.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';

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

  Map<String, double> fullScores([double v = 0.5]) => {
        for (final d in catalog.dimensionOrder) d: v,
      };

  PersonaRuntimeHandoffRequest request({
    Map<String, double>? scores,
    Map<String, int>? counts,
    String owner = 'uid_handoff_a',
    bool iq = true,
    bool eq = true,
    bool freq = true,
  }) {
    return PersonaRuntimeHandoffRequest(
      ownerUid: owner,
      dimensionScores: scores ?? fullScores(),
      dimensionEvidenceCounts: counts ?? fullCounts(),
      iqCompleted: iq,
      eqCompleted: eq,
      frequencyCompleted: freq,
      iqScoringPolicyVersion: IqScoringContract.scoringPolicyVersion,
      eqScoringPolicyVersion: EqScoringContract.scoringPolicyVersion,
      frequencyScoringPolicyVersion:
          FrequencyScoringContract.scoringPolicyVersion,
      iqBankOrSessionVersion: 'iq_bank_tr_v1',
      eqBankOrSessionVersion: 'eq_bank_tr_v1',
      frequencyBankOrSessionVersion: 'frequency_bank_tr_v1',
      dimensionRegistryVersion: catalog.dimensionRegistryVersion,
    );
  }

  group('PersonaRuntimeHandoffService', () {
    test('assigns primary/secondary + raw delta_D + versions from complete 20D',
        () {
      final result = handoff.assign(request());

      expect(result.primaryPersonaId, isNotEmpty);
      expect(result.secondaryPersonaId, isNotEmpty);
      expect(result.primaryPersonaId, isNot(result.secondaryPersonaId));
      expect(result.rawDeltaD, greaterThanOrEqualTo(0.0));
      expect(result.scoringVersion, PersonaShadowContract.scoringVersion);
      expect(result.configVersion, config.configVersion);
      expect(result.prototypeVersion, catalog.personaProfileVersion);
      expect(
        result.policyVersion,
        PersonaShadowContract.qualityPolicyVersion,
      );

      final wire = result.toWireMap();
      expect(wire['primary_persona_id'], result.primaryPersonaId);
      expect(wire['secondary_persona_id'], result.secondaryPersonaId);
      expect(wire['raw_delta_d'], result.rawDeltaD);
      expect(wire.containsKey('confidence'), isFalse);
      expect(wire.containsKey('confidence_score'), isFalse);
      expect(wire.containsKey('primary_similarity'), isFalse);
      expect(wire.containsKey('affinity'), isFalse);
      expect(wire.containsKey('percentage'), isFalse);
      expect(wire.containsKey('pi_p'), isFalse);
      expect(wire['shadow_only'], isTrue);
    });

    test('buildInput produces PersonaShadowInput for complete profiles', () {
      final input = handoff.buildInput(request());
      expect(input.dimensionScores.length, 20);
      expect(input.source.dimensionEvidenceCounts.length, 20);
      expect(input.dimensionRegistryVersion, catalog.dimensionRegistryVersion);
    });

    test('rejects incomplete 20D (missing dimension score)', () {
      final scores = fullScores();
      scores.remove('empathy');
      expect(
        () => handoff.assign(request(scores: scores)),
        throwsA(
          isA<PersonaShadowScoringException>().having(
            (e) => e.code,
            'code',
            PersonaShadowFailureCode.incompleteDimensionScores,
          ),
        ),
      );
    });

    test('rejects incomplete evidence counts', () {
      final counts = fullCounts();
      counts.remove('depth_preference');
      expect(
        () => handoff.assign(request(counts: counts)),
        throwsA(
          isA<PersonaShadowScoringException>().having(
            (e) => e.code,
            'code',
            PersonaShadowFailureCode.missingEvidenceCount,
          ),
        ),
      );
    });

    test('rejects legacy dimension aliases', () {
      final scores = fullScores();
      scores['numerical'] = 0.4;
      expect(
        () => handoff.assign(request(scores: scores)),
        throwsA(
          isA<PersonaShadowScoringException>().having(
            (e) => e.code,
            'code',
            PersonaShadowFailureCode.legacyDimensionAlias,
          ),
        ),
      );
    });

    test('rejects incomplete assessments via shadow scorer', () {
      expect(
        () => handoff.assign(request(freq: false)),
        throwsA(
          isA<PersonaShadowScoringException>().having(
            (e) => e.code,
            'code',
            PersonaShadowFailureCode.incompleteAssessments,
          ),
        ),
      );
    });

    test('nearest = primary, second-nearest = secondary (self-center)', () {
      final prototype = catalog.byId['analist']!;
      final scores = <String, double>{
        for (final d in catalog.dimensionOrder) d: prototype.targetVector[d]!,
      };
      final result = handoff.assign(request(scores: scores));
      expect(result.primaryPersonaId, 'analist');
      expect(result.secondaryPersonaId, isNot('analist'));
      expect(result.rawDeltaD, greaterThanOrEqualTo(0.0));
    });

    test('does not route through PersonaScoringService affinity path', () {
      final source = File(
        'lib/features/assessment/domain/persona_scoring/'
        'persona_runtime_handoff_service.dart',
      ).readAsStringSync();
      expect(source.contains('PersonaScoringService'), isFalse);
      expect(source.contains('persona_scoring_service.dart'), isFalse);
      expect(source.contains('similarityTemperature'), isFalse);
      expect(source.contains('exp(-'), isFalse);
      expect(source.contains('CanonicalPersonaShadowScorer'), isTrue);
    });
  });
}
