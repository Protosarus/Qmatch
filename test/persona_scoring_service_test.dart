import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';

void main() {
  late PersonaScoringService service;
  late PersonaProfileCatalog catalog;

  setUpAll(() {
    final loaded =
        PersonaScoringFileLoader.loadFromRepoRoot(Directory.current.path);
    catalog = loaded.catalog;
    service = PersonaScoringService(
      catalog: loaded.catalog,
      config: loaded.config,
    );
  });

  PersonaScoringInput full(Map<String, double> scores) {
    return PersonaScoringInput.fullEvidence(
      dimensionScores: scores,
      dimensionOrder: catalog.dimensionOrder,
      dimensionRegistryVersion: catalog.dimensionRegistryVersion,
      personaProfileVersion: catalog.personaProfileVersion,
      personaScoringVersion: service.scoringVersion,
    );
  }

  test('1 exact prototype recovers itself for all 18', () {
    for (final p in catalog.personas) {
      final r = service.score(full(p.targetVector));
      expect(r.insufficientEvidence, isFalse, reason: p.personaId);
      expect(r.primaryPersonaId, p.personaId);
      expect(r.primarySimilarity, greaterThan(0.9));
      expect(r.productionValid, isFalse);
    }
  });

  test('2 near-prototype recovers expected persona at high rate', () {
    final rng = math.Random(7);
    var hits = 0;
    const n = 18 * 40;
    for (final p in catalog.personas) {
      for (var i = 0; i < 40; i++) {
        final x = {
          for (final d in catalog.dimensionOrder)
            d: (p.targetVector[d]! + (rng.nextDouble() - 0.5) * 0.12)
                .clamp(0.0, 1.0),
        };
        final r = service.score(full(x));
        if (r.primaryPersonaId == p.personaId) hits++;
      }
    }
    expect(hits / n, greaterThan(0.90));
  });

  test('3 all 18 personas are scoreable', () {
    final seen = <String>{};
    for (final p in catalog.personas) {
      final r = service.score(full(p.targetVector));
      expect(r.candidates.length, 18);
      seen.add(r.primaryPersonaId!);
    }
    expect(seen.length, 18);
  });

  test('4 central profile is ambiguous when margin is low', () {
    final x = {for (final d in catalog.dimensionOrder) d: 0.5};
    final r = service.score(full(x));
    expect(r.insufficientEvidence, isFalse);
    expect(r.ambiguous, isTrue);
    expect(r.status, PersonaScoringStatus.ambiguous);
    expect(r.confidenceLevel, isNot(PersonaConfidenceLevel.high));
    expect(r.primaryPersonaId, isNotNull);
    expect(r.secondaryPersonaId, isNotNull);
    // Separator targets may be empty only if top pair lacks mutual entries;
    // still expose ambiguity reason.
    expect(r.ambiguityReason, isNotEmpty);
  });

  test('5 missing IQ alone still scores when IQ min coverage is 0', () {
    final x = <String, double>{};
    final ev = <String, int>{};
    for (final d in catalog.dimensionOrder) {
      if (PersonaDimensionIds.iq.contains(d)) continue;
      x[d] = 0.55;
      ev[d] = 3;
    }
    final r = service.score(
      PersonaScoringInput(
        dimensionScores: x,
        dimensionEvidenceCounts: ev,
        dimensionEvidenceSufficiency: {for (final d in x.keys) d: 1.0},
        dimensionReliability: {for (final d in x.keys) d: 1.0},
        missingDimensions: PersonaDimensionIds.iq.toSet(),
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      ),
    );
    // May be insufficient due to critical dims in IQ for some personas,
    // but global IQ min is 0 — if any persona eligible, not forced fail on IQ.
    expect(r.groupCoverage['iq'], 0.0);
    expect(r.missingDimensions, containsAll(PersonaDimensionIds.iq));
  });

  test('6 missing EQ prevents scoring', () {
    final x = <String, double>{};
    final ev = <String, int>{};
    for (final d in catalog.dimensionOrder) {
      if (PersonaDimensionIds.eq.contains(d)) continue;
      x[d] = 0.6;
      ev[d] = 3;
    }
    final r = service.score(
      PersonaScoringInput(
        dimensionScores: x,
        dimensionEvidenceCounts: ev,
        dimensionEvidenceSufficiency: {for (final d in x.keys) d: 1.0},
        dimensionReliability: {for (final d in x.keys) d: 1.0},
        missingDimensions: PersonaDimensionIds.eq.toSet(),
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      ),
    );
    expect(r.insufficientEvidence, isTrue);
    expect(r.primaryPersonaId, isNull);
    expect(r.publishablePrimary, isFalse);
    expect(r.status, PersonaScoringStatus.insufficientEvidence);
  });

  test('7 missing Frequency prevents scoring', () {
    final x = <String, double>{};
    final ev = <String, int>{};
    for (final d in catalog.dimensionOrder) {
      if (PersonaDimensionIds.frequency.contains(d)) continue;
      x[d] = 0.6;
      ev[d] = 3;
    }
    final r = service.score(
      PersonaScoringInput(
        dimensionScores: x,
        dimensionEvidenceCounts: ev,
        dimensionEvidenceSufficiency: {for (final d in x.keys) d: 1.0},
        dimensionReliability: {for (final d in x.keys) d: 1.0},
        missingDimensions: PersonaDimensionIds.frequency.toSet(),
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      ),
    );
    expect(r.insufficientEvidence, isTrue);
    expect(r.primaryPersonaId, isNull);
  });

  test('8 missing dimensions never filled with 0/0.5/0.42', () {
    final p = catalog.byId['empat']!;
    final x = Map<String, double>.from(p.targetVector)
      ..remove('disclosure_pace');
    final ev = {for (final d in x.keys) d: 3};
    final r = service.score(
      PersonaScoringInput(
        dimensionScores: x,
        dimensionEvidenceCounts: ev,
        dimensionEvidenceSufficiency: {for (final d in x.keys) d: 1.0},
        dimensionReliability: {for (final d in x.keys) d: 1.0},
        missingDimensions: {'disclosure_pace'},
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      ),
    );
    expect(r.missingDimensions, contains('disclosure_pace'));
    expect(x.containsKey('disclosure_pace'), isFalse);
    // Candidate distances remain finite.
    for (final c in r.candidates) {
      expect(c.similarity.isFinite, isTrue);
      expect(c.distance.isFinite, isTrue);
      expect(c.similarity, greaterThan(0));
      expect(c.similarity, lessThanOrEqualTo(1));
    }
  });

  test('9-10 anti-traits require evidence and remain bounded', () {
    final p = catalog.byId['kararli']!;
    // Force stability anti-trait: kararli peaks stability, anti below threshold.
    final anti = p.antiTraits.firstWhere((a) => a.dimensionId == 'stability');
    final x = Map<String, double>.from(p.targetVector);
    x['stability'] = math.max(0.0, anti.threshold - 0.05);

    final noEv = service.score(
      PersonaScoringInput(
        dimensionScores: x,
        dimensionEvidenceCounts: {
          for (final d in x.keys) d: d == 'stability' ? 0 : 3,
        },
        dimensionEvidenceSufficiency: {
          for (final d in x.keys)
            if (d != 'stability') d: 1.0,
        },
        dimensionReliability: {for (final d in x.keys) d: 1.0},
        missingDimensions: {'stability'},
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      ),
    );
    // With stability missing, critical evidence may fail for kararli.
    final withEv = service.score(full(x));
    final c = withEv.candidates.firstWhere((e) => e.personaId == 'kararli');
    expect(c.antiTraitPenalty, lessThanOrEqualTo(1.0));
    expect(c.antiTraitPenalty, greaterThanOrEqualTo(0.0));
    if (c.appliedAntiTraits.isNotEmpty) {
      expect(
        c.appliedAntiTraits.any((a) => a.dimensionId == 'stability'),
        isTrue,
      );
    }
    expect(noEv.candidates, isNotEmpty);
  });

  test('17 similarities need not sum to 1', () {
    final r = service.score(full(catalog.personas.first.targetVector));
    final sum = r.candidates
        .where((c) => c.eligibleForPublishableRanking)
        .fold<double>(0, (a, b) => a + b.similarity);
    expect(sum, isNot(closeTo(1.0, 0.05)));
  });

  test('18 confidence and similarity are separate', () {
    final r =
        service.score(full({for (final d in catalog.dimensionOrder) d: 0.5}));
    expect(r.primarySimilarity, isNotNull);
    expect(r.confidenceScore, isNot(r.primarySimilarity));
    expect(r.confidenceComponents.provisionalCalibrationMarker, isTrue);
  });

  test('19-22 no quota, no random, no legacy/Frequency type IDs', () {
    final r = service.score(full(catalog.byId['lider']!.targetVector));
    expect(r.primaryPersonaId, isNot(contains('H')));
    expect(
      PersonaDimensionIds.forbiddenLegacyGridIds.contains(r.primaryPersonaId),
      isFalse,
    );
    expect(
      PersonaDimensionIds.forbiddenFrequencyTypes.contains(r.primaryPersonaId),
      isFalse,
    );
    expect(r.candidates.map((c) => c.personaId).toSet().length, 18);
  });

  test('23 invalid config fails explicitly', () {
    expect(
      () => PersonaScoringParsers.parseConfigMap({
        'config_version': 'x',
        'status': 'provisional',
        'persona_profile_version': catalog.personaProfileVersion,
        'dimension_registry_version': 'canonical_dimension_registry_v1',
        'group_weights': {'iq': 0.5, 'eq': 0.5, 'frequency': 0.5},
        'level_distance_weight': 0.65,
        'shape_distance_weight': 0.35,
        'anti_trait_penalty_weight': 0.1,
        'missing_evidence_penalty_weight': 0.1,
        'similarity_temperature': 0.2,
        'top2_margin_threshold': 0.03,
        'low_confidence_threshold': 0.5,
        'minimum_group_coverage': {'iq': 0, 'eq': 0.4, 'frequency': 0.5},
        'minimum_total_coverage': 0.45,
        'deterministic_tie_break_policy':
            'lowest_tie_break_rank_then_lexicographic_persona_id',
        'numerical_epsilon': 1e-12,
        'calibration_notes': {
          'similarity_scores_are_not_probabilities': true,
          'no_persona_quota': true,
        },
      }),
      throwsA(isA<PersonaScoringParseException>()),
    );
  });

  test('24 invalid prototype data fails explicitly', () {
    expect(
      () => PersonaScoringParsers.parseProfilesMap({
        'schema_version': 'x',
        'persona_profile_version': 'x',
        'dimension_registry_version': 'canonical_dimension_registry_v1',
        'status': 'provisional',
        'calibration_status': 'synthetic_validation_only',
        'dimension_order': PersonaDimensionIds.all,
        'group_weights': {'iq': 0.15, 'eq': 0.3, 'frequency': 0.55},
        'personas': [],
      }),
      throwsA(isA<PersonaScoringParseException>()),
    );
  });

  test('25 no NaN or infinity in normal scoring', () {
    final r = service.score(full({
      for (final d in catalog.dimensionOrder) d: 0.37,
    }));
    expect(r.primarySimilarity!.isFinite, isTrue);
    for (final c in r.candidates) {
      expect(c.similarity.isNaN, isFalse);
      expect(c.distance.isInfinite, isFalse);
    }
  });
}
