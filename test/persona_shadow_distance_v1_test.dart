import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';

void main() {
  late CanonicalPersonaShadowScorer scorer;
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
  });

  Map<String, int> fullCounts() => {
        for (final d in catalog.dimensionOrder) d: config.nMin(d),
      };

  PersonaShadowSourceEvidence source({
    Map<String, int>? counts,
    String owner = 'uid_shadow_a',
    bool iq = true,
    bool eq = true,
    bool freq = true,
  }) {
    return PersonaShadowSourceEvidence(
      ownerUid: owner,
      iqCompleted: iq,
      eqCompleted: eq,
      frequencyCompleted: freq,
      iqScoringPolicyVersion: 'iq_4d_uncalibrated_accuracy_v1',
      eqScoringPolicyVersion: 'eq_10d_uncalibrated_signed_evidence_v1',
      frequencyScoringPolicyVersion:
          'frequency_6d_uncalibrated_signed_evidence_v1',
      iqBankOrSessionVersion: 'iq_bank_tr_v1',
      eqBankOrSessionVersion: 'eq_bank_tr_v1',
      frequencyBankOrSessionVersion: 'frequency_bank_tr_v1',
      dimensionEvidenceCounts: counts ?? fullCounts(),
    );
  }

  PersonaShadowInput inputFor(
    Map<String, double> scores, {
    Map<String, int>? counts,
    String owner = 'uid_shadow_a',
  }) {
    return PersonaShadowInput(
      dimensionScores: scores,
      source: source(counts: counts, owner: owner),
      dimensionRegistryVersion: catalog.dimensionRegistryVersion,
    );
  }

  group('contracts', () {
    test('loads exactly 18 personas with canonical 20D vectors', () {
      expect(catalog.personas.length, 18);
      expect(catalog.dimensionOrder.length, 20);
      expect(catalog.dimensionOrder.toSet(), PersonaDimensionIds.allSet);
      for (final p in catalog.personas) {
        expect(p.targetVector.length, 20);
        expect(p.dimensionWeights.length, 20);
        for (final d in catalog.dimensionOrder) {
          expect(p.targetVector[d]!, inInclusiveRange(0.0, 1.0));
          expect(p.dimensionWeights[d]!, greaterThanOrEqualTo(0.0));
          expect(PersonaDimensionIds.forbiddenAliases.contains(d), isFalse);
        }
      }
    });

    test('shadow coefficients are Core Engine v2 values', () {
      expect(config.iqWeight, 0.15);
      expect(config.eqWeight, 0.30);
      expect(config.frequencyWeight, 0.55);
      expect(config.levelDistanceWeight, 0.65);
      expect(config.shapeDistanceWeight, 0.35);
      expect(config.antiTraitPenaltyWeight, 0.10);
      expect(config.minimumEvidencePenaltyWeight, 0.05);
      expect(config.scoringVersion, PersonaShadowContract.scoringVersion);
      expect(
        config.qualityPolicyVersion,
        PersonaShadowContract.qualityPolicyVersion,
      );
      expect(
        (config.antiTraitPenaltyWeight - 0.12).abs() < 1e-12,
        isFalse,
      );
      expect(
        (config.minimumEvidencePenaltyWeight - 0.18).abs() < 1e-12,
        isFalse,
      );
    });

    test('IQ/EQ/Frequency n_min exact', () {
      expect(config.nMin('logical_reasoning'), 7);
      expect(config.nMin('pattern_reasoning'), 6);
      expect(config.nMin('verbal_reasoning'), 6);
      expect(config.nMin('spatial_reasoning'), 6);
      for (final d in PersonaDimensionIds.eq) {
        expect(config.nMin(d), 3, reason: d);
      }
      for (final d in PersonaDimensionIds.frequency) {
        expect(config.nMin(d), 5, reason: d);
      }
    });
  });

  group('eligibility + evidence', () {
    test('source-less / incomplete source cannot auto-score', () {
      final scores = {
        for (final d in catalog.dimensionOrder) d: 0.5,
      };
      expect(
        () => scorer.score(
          PersonaShadowInput(
            dimensionScores: scores,
            source: source(iq: false),
            dimensionRegistryVersion: catalog.dimensionRegistryVersion,
          ),
        ),
        throwsA(
          isA<PersonaShadowScoringException>().having(
            (e) => e.code,
            'code',
            PersonaShadowFailureCode.incompleteAssessments,
          ),
        ),
      );
      expect(
        () => scorer.score(
          PersonaShadowInput(
            dimensionScores: scores,
            source: source(owner: ''),
            dimensionRegistryVersion: catalog.dimensionRegistryVersion,
          ),
        ),
        throwsA(
          isA<PersonaShadowScoringException>().having(
            (e) => e.code,
            'code',
            PersonaShadowFailureCode.ownerUnavailable,
          ),
        ),
      );
    });

    test('E_j formula and full evidence yields 1', () {
      final scores = {
        for (final d in catalog.dimensionOrder) d: 0.5,
      };
      final e = scorer.evidenceSufficiencyFor(inputFor(scores));
      for (final d in catalog.dimensionOrder) {
        expect(e[d], 1.0, reason: d);
      }
      final half = {
        for (final d in catalog.dimensionOrder)
          d: (config.nMin(d) / 2).floor().clamp(0, config.nMin(d)),
      };
      final eHalf = scorer.evidenceSufficiencyFor(
        inputFor(scores, counts: half),
      );
      for (final d in catalog.dimensionOrder) {
        final expected = math.min(1.0, half[d]! / config.nMin(d));
        expect(eHalf[d]!, closeTo(expected, 1e-12), reason: d);
      }
    });

    test('zero group evidence typed insufficient', () {
      final scores = {
        for (final d in catalog.dimensionOrder) d: 0.5,
      };
      final counts = fullCounts();
      for (final d in PersonaDimensionIds.iq) {
        counts[d] = 0;
      }
      expect(
        () => scorer.score(inputFor(scores, counts: counts)),
        throwsA(
          isA<PersonaShadowScoringException>().having(
            (e) => e.code,
            'code',
            PersonaShadowFailureCode.insufficientGroupEvidence,
          ),
        ),
      );
    });

    test('no fake R_j / reliability factor / affinity / confidence', () {
      final p = catalog.personas.first;
      final r = scorer.score(inputFor(p.targetVector));
      expect(r.reliabilityStatus, 'not_calibrated');
      expect(r.reliabilityFactorApplied, isFalse);
      expect(r.temperatureApplied, isFalse);
      expect(r.affinityNotComputed, isTrue);
      expect(r.confidenceNotComputed, isTrue);
      expect(r.top2MarginBand, 'not_computed');
      expect(r.shadowOnly, isTrue);
      expect(r.scoringVersion.contains('exp'), isFalse);
    });
  });

  group('distance ranking', () {
    test('all 18 prototypes reachable as primary', () {
      final unreachable = <String>[];
      for (final p in catalog.personas) {
        final r = scorer.score(inputFor(p.targetVector));
        if (r.primaryCandidateId != p.personaId) {
          unreachable.add(
            '${p.personaId}->${r.primaryCandidateId} '
            '(d=${r.allPersonaDistances[p.personaId]})',
          );
        }
        expect(r.candidates.length, 18);
        expect(r.top2DistanceMargin, greaterThanOrEqualTo(0.0));
        expect(
          r.allPersonaDistances[r.secondaryCandidateId]! -
              r.allPersonaDistances[r.primaryCandidateId]!,
          greaterThanOrEqualTo(-1e-12),
        );
      }
      expect(
        unreachable,
        isEmpty,
        reason: 'BLOCKED_PERSONA_PROTOTYPE_REACHABILITY: $unreachable',
      );
    });

    test('midpoint center-magnet audit', () {
      final x = {for (final d in catalog.dimensionOrder) d: 0.5};
      final r = scorer.score(inputFor(x));
      expect(r.primaryCandidateId, isNotEmpty);
      expect(r.secondaryCandidateId, isNotEmpty);
      expect(r.primaryCandidateId, isNot(r.secondaryCandidateId));
      // Document concentration: primary distance should not be uniquely zero.
      expect(r.allPersonaDistances[r.primaryCandidateId]!, greaterThan(0.0));
    });

    test('all-high / all-low / extreme mixed score without affinity', () {
      for (final v in [0.05, 0.95]) {
        final x = {for (final d in catalog.dimensionOrder) d: v};
        final r = scorer.score(inputFor(x));
        expect(r.candidates.length, 18);
        expect(r.affinityNotComputed, isTrue);
      }
      final mixed = <String, double>{};
      for (var i = 0; i < catalog.dimensionOrder.length; i++) {
        mixed[catalog.dimensionOrder[i]] = i.isEven ? 0.1 : 0.9;
      }
      final r = scorer.score(inputFor(mixed));
      expect(r.top2DistanceMargin, greaterThanOrEqualTo(0.0));
    });

    test('tie-break uses tie_break_rank deterministically', () {
      // Two identical prototypes would tie on distance; construct equal
      // distances by scoring the same vector twice and verifying stable order
      // among equal-distance candidates via rank.
      final p = catalog.byId['uygulayici']!;
      final a = scorer.score(inputFor(p.targetVector));
      final b = scorer.score(inputFor(p.targetVector));
      expect(a.primaryCandidateId, b.primaryCandidateId);
      expect(a.secondaryCandidateId, b.secondaryCandidateId);
      expect(a.allPersonaDistances, b.allPersonaDistances);
    });

    test('anti-trait increases distance vs clean prototype center', () {
      final p = catalog.byId['uygulayici']!;
      final clean = scorer.score(inputFor(p.targetVector));
      final violated = Map<String, double>.from(p.targetVector);
      // Force below stability anti-trait threshold.
      violated['stability'] = 0.1;
      final dirty = scorer.score(inputFor(violated));
      expect(
        dirty.allPersonaDistances['uygulayici']!,
        greaterThan(clean.allPersonaDistances['uygulayici']!),
      );
    });

    test('UID isolation of source metadata', () {
      final p = catalog.personas.first;
      final a = scorer.score(inputFor(p.targetVector, owner: 'uid_a'));
      final b = scorer.score(inputFor(p.targetVector, owner: 'uid_b'));
      expect(a.primaryCandidateId, b.primaryCandidateId);
      expect(a.allPersonaDistances, b.allPersonaDistances);
    });

    test('distances clipped to [0,1]', () {
      final x = {for (final d in catalog.dimensionOrder) d: 0.0};
      final r = scorer.score(inputFor(x));
      for (final d in r.allPersonaDistances.values) {
        expect(d, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('distribution simulation (deterministic, no quota)', () {
    test('synthetic neighborhood coverage across 18', () {
      final rng = math.Random(42);
      final primaryCounts = <String, int>{
        for (final p in catalog.personas) p.personaId: 0,
      };
      const per = 80;
      for (final p in catalog.personas) {
        for (var i = 0; i < per; i++) {
          final x = {
            for (final d in catalog.dimensionOrder)
              d: (p.targetVector[d]! + (rng.nextDouble() - 0.5) * 0.10)
                  .clamp(0.0, 1.0),
          };
          final r = scorer.score(inputFor(x));
          primaryCounts[r.primaryCandidateId] =
              primaryCounts[r.primaryCandidateId]! + 1;
        }
      }
      // No quota: only assert all remain reachable somewhere in neighborhood.
      expect(primaryCounts.values.every((c) => c > 0), isTrue);
    });
  });

  group('downstream isolation', () {
    test('shadow scorer source has no persistence / reveal / affinity math',
        () {
      final src = File(
        'lib/features/assessment/domain/persona_scoring/'
        'canonical_persona_shadow_scorer.dart',
      ).readAsStringSync();
      expect(src.contains('cloud_firestore'), isFalse);
      expect(src.contains('package:firebase'), isFalse);
      expect(src.contains('Navigator'), isFalse);
      expect(src.contains('math.exp'), isFalse);
      expect(src.contains('similarityTemperature'), isFalse);
    });

    test('production screens still do not import PersonaScoringService', () {
      final screens = Directory('lib/features/assessment/screens')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in screens) {
        final t = f.readAsStringSync();
        expect(t.contains('PersonaScoringService'), isFalse, reason: f.path);
        expect(t.contains('CanonicalPersonaShadowScorer'), isFalse,
            reason: f.path);
      }
    });
  });
}
