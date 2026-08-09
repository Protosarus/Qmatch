import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'trait_scoring_fixture_loader.dart';

void main() {
  late PersonaScoringService persona;
  late PersonaProfileCatalog catalog;
  late TraitScoringConfig traitConfig;
  late TraitScoringService traitService;

  setUpAll(() {
    final loaded =
        PersonaScoringFileLoader.loadFromRepoRoot(Directory.current.path);
    catalog = loaded.catalog;
    persona = PersonaScoringService(
      catalog: loaded.catalog,
      config: loaded.config,
    );
    traitConfig = TraitScoringFixtureLoader.loadConfig();
    traitService = TraitScoringService(config: traitConfig);
  });

  test('canonical path uses explicit sufficiency (not silent /3)', () {
    final p = catalog.personas.first;
    final near = {
      for (final d in catalog.dimensionOrder)
        d: (p.targetVector[d]! * 0.85 + 0.07).clamp(0.0, 1.0),
    };
    final withExplicit = PersonaScoringInput(
      dimensionScores: near,
      dimensionEvidenceCounts: {
        for (final d in catalog.dimensionOrder) d: 3,
      },
      dimensionEvidenceSufficiency: {
        for (final d in catalog.dimensionOrder) d: d == 'stability' ? 0.1 : 1.0,
      },
      dimensionReliability: {
        for (final d in catalog.dimensionOrder) d: 1.0,
      },
      responseValidityStatus: ResponseValidityStatus.valid,
      dimensionRegistryVersion: catalog.dimensionRegistryVersion,
      personaProfileVersion: catalog.personaProfileVersion,
      personaScoringVersion: persona.scoringVersion,
      evidenceSufficiencyMode: PersonaEvidenceSufficiencyMode.explicit,
    );
    final withDeprecated =
        PersonaScoringInput.withDeprecatedGlobalEvidenceDenominator(
      dimensionScores: near,
      dimensionEvidenceCounts: {
        for (final d in catalog.dimensionOrder) d: 3,
      },
      dimensionReliability: {
        for (final d in catalog.dimensionOrder) d: 1.0,
      },
      responseValidityStatus: ResponseValidityStatus.valid,
      dimensionRegistryVersion: catalog.dimensionRegistryVersion,
      personaProfileVersion: catalog.personaProfileVersion,
      personaScoringVersion: persona.scoringVersion,
    );
    final a = persona.score(withExplicit);
    final b = persona.score(withDeprecated);
    expect(a.primarySimilarity, isNotNull);
    expect(b.primarySimilarity, isNotNull);
    expect(a.primarySimilarity, isNot(closeTo(b.primarySimilarity!, 1e-6)));
    expect(
      withDeprecated.evidenceSufficiencyMode,
      PersonaEvidenceSufficiencyMode.deprecatedGlobalDenominator,
    );
  });

  test('trait assembly handoff feeds PersonaScoringService', () {
    final iq = traitService
        .scoreModule(
          TraitScoringFixtureLoader.session(
            module: 'iq',
            config: traitConfig,
            items: TraitScoringFixtureLoader.loadBank(
              'valid_iq_bank.json',
              module: 'iq',
              config: traitConfig,
            ),
            responses: TraitScoringFixtureLoader.loadResponses(
              'valid_iq_responses.json',
            ),
          ),
        )
        .module;
    final eq = traitService
        .scoreModule(
          TraitScoringFixtureLoader.session(
            module: 'eq',
            config: traitConfig,
            items: TraitScoringFixtureLoader.loadBank(
              'valid_eq_bank.json',
              module: 'eq',
              config: traitConfig,
            ),
            responses: TraitScoringFixtureLoader.loadResponses(
              'valid_eq_responses_high.json',
            ),
          ),
        )
        .module;
    final freq = traitService
        .scoreModule(
          TraitScoringFixtureLoader.session(
            module: 'frequency',
            config: traitConfig,
            items: TraitScoringFixtureLoader.loadBank(
              'valid_frequency_bank.json',
              module: 'frequency',
              config: traitConfig,
            ),
            responses: TraitScoringFixtureLoader.loadResponses(
              'valid_frequency_responses.json',
            ),
          ),
        )
        .module;
    final assembly = CanonicalProfileAssembler(config: traitConfig).assemble(
      iq: iq,
      eq: eq,
      frequency: freq,
    );
    final input = assembly.toPersonaScoringInput(
      personaProfileVersion: catalog.personaProfileVersion,
      personaScoringVersion: persona.scoringVersion,
    );
    expect(
        input.evidenceSufficiencyMode, PersonaEvidenceSufficiencyMode.explicit);
    expect(input.dimensionEvidenceSufficiency.length, greaterThanOrEqualTo(1));
    // Score via explicit sufficiency with valid RVI to isolate handoff math.
    final result = persona.score(
      PersonaScoringInput(
        dimensionScores: input.dimensionScores,
        dimensionEvidenceCounts: input.dimensionEvidenceCounts,
        dimensionEvidenceSufficiency: input.dimensionEvidenceSufficiency,
        dimensionReliability: {
          for (final d in input.dimensionScores.keys) d: 1.0,
        },
        missingDimensions: input.missingDimensions,
        assessmentStatuses: const {
          'iq': 'complete',
          'eq': 'complete',
          'frequency': 'complete',
        },
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: persona.scoringVersion,
        evidenceSufficiencyMode: PersonaEvidenceSufficiencyMode.explicit,
      ),
    );
    expect(result.primarySimilarity, isNotNull);
    expect(result.primarySimilarity!.isFinite, isTrue);
    expect(result.candidates.every((c) => c.similarity.isFinite), isTrue);
  });

  test('no production screen imports the trait engine', () {
    final screens = Directory('lib/features/assessment')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) =>
            f.path.contains('/screens/') || f.path.contains('/widgets/'));
    for (final f in screens) {
      final text = f.readAsStringSync();
      expect(text.contains('trait_scoring'), isFalse, reason: f.path);
      expect(text.contains('TraitScoringService'), isFalse, reason: f.path);
    }
  });

  test('pure trait domain has no Firebase imports', () {
    final files = Directory('lib/features/assessment/domain/trait_scoring')
        .listSync()
        .whereType<File>();
    for (final f in files) {
      final text = f.readAsStringSync();
      expect(text.contains('firebase'), isFalse, reason: f.path);
      expect(text.contains('cloud_firestore'), isFalse, reason: f.path);
      expect(text.contains('package:flutter/'), isFalse, reason: f.path);
    }
  });
}
