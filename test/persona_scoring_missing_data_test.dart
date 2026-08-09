import 'dart:io';

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

  test('missing Frequency reduces coverage and blocks persona', () {
    final x = <String, double>{};
    final ev = <String, int>{};
    for (final d in catalog.dimensionOrder) {
      if (PersonaDimensionIds.frequency.contains(d)) continue;
      x[d] = 0.7;
      ev[d] = 3;
    }
    final r = service.score(
      PersonaScoringInput(
        dimensionScores: x,
        dimensionEvidenceCounts: ev,
        dimensionReliability: {for (final d in x.keys) d: 1.0},
        missingDimensions: {...PersonaDimensionIds.frequency},
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      ),
    );
    expect(r.groupCoverage['frequency'], 0.0);
    expect(r.totalCoverage, closeTo(14 / 20, 1e-9));
    expect(r.insufficientEvidence, isTrue);
    expect(r.primaryPersonaId, isNull);
    expect(r.failedEvidenceRules, isNotEmpty);
    expect(
      r.reasonCodes.any((c) => c.contains('frequency')) ||
          r.failedEvidenceRules.any((c) => c.contains('frequency')),
      isTrue,
    );
  });

  test('missing EQ never imputed as 0.5 or target match', () {
    final proto = catalog.byId['bilge']!;
    final x = Map<String, double>.from(proto.targetVector);
    for (final d in PersonaDimensionIds.eq) {
      x.remove(d);
    }
    final r = service.score(
      PersonaScoringInput(
        dimensionScores: x,
        dimensionEvidenceCounts: {for (final d in x.keys) d: 3},
        dimensionReliability: {for (final d in x.keys) d: 1.0},
        missingDimensions: {...PersonaDimensionIds.eq},
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      ),
    );
    expect(r.missingDimensions.toSet().containsAll(PersonaDimensionIds.eq),
        isTrue);
    expect(r.insufficientEvidence, isTrue);
    // Ensure input map was not mutated with fillers.
    expect(x.length, 10); // 4 IQ + 6 Frequency
  });

  test('partial missing dimensions reduce q_j without fabricating scores', () {
    final proto = catalog.byId['lider']!;
    final x = Map<String, double>.from(proto.targetVector)
      ..remove('social_energy')
      ..remove('assertiveness');
    final r = service.score(
      PersonaScoringInput(
        dimensionScores: x,
        dimensionEvidenceCounts: {for (final d in x.keys) d: 3},
        dimensionReliability: {for (final d in x.keys) d: 1.0},
        missingDimensions: {'social_energy', 'assertiveness'},
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      ),
    );
    expect(
        r.missingDimensions, containsAll(['social_energy', 'assertiveness']));
    expect(r.totalCoverage, closeTo(18 / 20, 1e-9));
    for (final c in r.candidates) {
      expect(c.similarity.isFinite, isTrue);
      expect(c.distance.isNaN, isFalse);
    }
  });

  test('invalid RVI blocks publishable persona', () {
    final r = service.score(
      PersonaScoringInput.fullEvidence(
        dimensionScores: catalog.byId['cesur']!.targetVector,
        dimensionOrder: catalog.dimensionOrder,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
        responseValidityStatus: ResponseValidityStatus.invalid,
      ),
    );
    expect(r.insufficientEvidence, isTrue);
    expect(r.primaryPersonaId, isNull);
    expect(r.reasonCodes, contains('rvi_invalid'));
  });

  test('low reliability reduces quality weight impact', () {
    final proto = catalog.byId['stratejist']!;
    final high = service.score(
      PersonaScoringInput(
        dimensionScores: proto.targetVector,
        dimensionEvidenceCounts: {
          for (final d in catalog.dimensionOrder) d: 3,
        },
        dimensionReliability: {
          for (final d in catalog.dimensionOrder) d: 1.0,
        },
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      ),
    );
    final low = service.score(
      PersonaScoringInput(
        dimensionScores: proto.targetVector,
        dimensionEvidenceCounts: {
          for (final d in catalog.dimensionOrder) d: 3,
        },
        dimensionReliability: {
          for (final d in catalog.dimensionOrder) d: 0.2,
        },
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      ),
    );
    // Same relative shape; distances scale with q but cancel in normalized
    // MSE — similarities should match when all q scaled equally.
    expect(high.primaryPersonaId, low.primaryPersonaId);
    expect(
      high.primarySimilarity,
      closeTo(low.primarySimilarity!, 1e-9),
    );
  });
}
