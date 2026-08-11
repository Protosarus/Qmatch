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
    String owner = 'uid_persist_a',
    bool freq = true,
  }) {
    return PersonaRuntimeHandoffRequest(
      ownerUid: owner,
      dimensionScores: scores ?? fullScores(),
      dimensionEvidenceCounts: counts ?? fullCounts(),
      iqCompleted: true,
      eqCompleted: true,
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

  group('PersonaRuntimeHandoffPersistence payload', () {
    test('allowlists only distance-only fields', () {
      final result = handoff.assign(request());
      final fields =
          PersonaRuntimeHandoffPersistence.buildPersistedFields(result);

      expect(
        fields.keys.toSet(),
        PersonaRuntimeHandoffPersistence.allowedResultKeys,
      );
      expect(fields['primary_persona_id'], result.primaryPersonaId);
      expect(fields['secondary_persona_id'], result.secondaryPersonaId);
      expect(fields['raw_delta_d'], result.rawDeltaD);
      expect(fields['scoring_version'], result.scoringVersion);
      expect(fields['config_version'], result.configVersion);
      expect(fields['policy_version'], result.policyVersion);
      expect(fields['prototype_version'], result.prototypeVersion);

      for (final banned
          in PersonaRuntimeHandoffPersistence.forbiddenResultKeys) {
        expect(fields.containsKey(banned), isFalse, reason: banned);
      }
      expect(fields.containsKey('updated_at'), isFalse);
      expect(fields.containsKey('assessment_type'), isFalse);
    });

    test('idempotent: same result builds identical fields', () {
      final result = handoff.assign(request());
      final a = PersonaRuntimeHandoffPersistence.buildPersistedFields(result);
      final b = PersonaRuntimeHandoffPersistence.buildPersistedFields(result);
      expect(a, b);
    });
  });

  group('PersonaRuntimeHandoffPersistence assignAndPersist', () {
    test('writes after valid 20D assign; path is assessments/persona', () async {
      final writes = <Map<String, dynamic>>[];
      final persistence = PersonaRuntimeHandoffPersistence(
        writeForUidOverride: (uid, fields) async {
          writes.add({'uid': uid, ...fields});
        },
      );

      final result = await persistence.assignAndPersist(
        handoff: handoff,
        request: request(owner: 'uid_persist_b'),
      );

      expect(writes, hasLength(1));
      expect(writes.single['uid'], 'uid_persist_b');
      expect(writes.single['primary_persona_id'], result.primaryPersonaId);
      expect(writes.single['secondary_persona_id'], result.secondaryPersonaId);
      expect(writes.single['raw_delta_d'], result.rawDeltaD);
      expect(
        PersonaRuntimeHandoffPersistence.assessmentType,
        'persona',
      );
      // Canonical path convention (no Firebase init required in unit test).
      expect(
        'users/uid_persist_b/assessments/persona',
        'users/${writes.single['uid']}/assessments/'
        '${PersonaRuntimeHandoffPersistence.assessmentType}',
      );

      // Second write with same assignment is safe (idempotent merge contract).
      await persistence.persistResult(
        ownerUid: 'uid_persist_b',
        result: result,
      );
      expect(writes, hasLength(2));
      expect(
        Map<String, dynamic>.from(writes[0])..remove('uid'),
        Map<String, dynamic>.from(writes[1])..remove('uid'),
      );
    });

    test('does not write when 20D is incomplete', () async {
      var wrote = false;
      final persistence = PersonaRuntimeHandoffPersistence(
        writeForUidOverride: (uid, fields) async {
          wrote = true;
        },
      );
      final scores = fullScores();
      scores.remove('empathy');

      expect(
        () => persistence.assignAndPersist(
          handoff: handoff,
          request: request(scores: scores),
        ),
        throwsA(
          isA<PersonaShadowScoringException>().having(
            (e) => e.code,
            'code',
            PersonaShadowFailureCode.incompleteDimensionScores,
          ),
        ),
      );
      expect(wrote, isFalse);
    });

    test('does not import PersonaScoringService', () {
      final source = File(
        'lib/features/assessment/domain/persona_scoring/'
        'persona_runtime_handoff_persistence.dart',
      ).readAsStringSync();
      expect(source.contains('PersonaScoringService'), isFalse);
      expect(source.contains('persona_scoring_service.dart'), isFalse);
      expect(source.contains('similarityTemperature'), isFalse);
    });
  });

  group('Firestore rules coverage for persona', () {
    test('assessments/{docId} owner rule covers persona without patch', () {
      final rules = File('firestore.rules').readAsStringSync();
      expect(rules.contains('match /assessments/{docId}'), isTrue);
      expect(
        rules.contains('allow read, write: if isOwner(uid);'),
        isTrue,
      );
      // No special-case deny for persona; docId includes persona.
      expect(rules.contains("docId == 'persona'"), isFalse);
    });
  });
}
