import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'trait_scoring_fixture_loader.dart';

void main() {
  late TraitScoringConfig config;
  late TraitScoringService service;
  late CanonicalProfileAssembler assembler;

  setUpAll(() {
    config = TraitScoringFixtureLoader.loadConfig();
    service = TraitScoringService(config: config);
    assembler = CanonicalProfileAssembler(config: config);
  });

  ModuleTraitResult score(String module, String bank, String responses) {
    final items = TraitScoringFixtureLoader.loadBank(
      bank,
      module: module,
      config: config,
    );
    return service
        .scoreModule(
          TraitScoringFixtureLoader.session(
            module: module,
            config: config,
            items: items,
            responses: TraitScoringFixtureLoader.loadResponses(responses),
          ),
        )
        .module;
  }

  test('assembles 20D profile and converts to PersonaScoringInput', () {
    final iq = score('iq', 'valid_iq_bank.json', 'valid_iq_responses.json');
    final eq =
        score('eq', 'valid_eq_bank.json', 'valid_eq_responses_high.json');
    final freq = score(
      'frequency',
      'valid_frequency_bank.json',
      'valid_frequency_responses.json',
    );
    final profile = assembler.assemble(iq: iq, eq: eq, frequency: freq);
    expect(profile.dimensionScores.length, 20);
    expect(profile.missingDimensions, isEmpty);
    expect(profile.dimensionEvidenceSufficiency.length, 20);
    final input = profile.toPersonaScoringInput(
      personaProfileVersion: 'persona_profiles_v2_20d',
      personaScoringVersion: 'test',
    );
    expect(
        input.evidenceSufficiencyMode, PersonaEvidenceSufficiencyMode.explicit);
    expect(input.dimensionEvidenceSufficiency.length, 20);
    expect(input.dimensionScores.length, 20);
    for (final d in PersonaDimensionIds.all) {
      expect(input.dimensionScores.containsKey(d), isTrue);
      expect(input.dimensionEvidenceSufficiency[d], greaterThan(0));
    }
  });

  test('missing Frequency prevents persona-ready profile', () {
    final iq = score('iq', 'valid_iq_bank.json', 'valid_iq_responses.json');
    final eq =
        score('eq', 'valid_eq_bank.json', 'valid_eq_responses_high.json');
    final profile = assembler.assemble(iq: iq, eq: eq);
    expect(profile.readyForPersona, isFalse);
    expect(profile.reasonCodes,
        contains('missing_frequency_prevents_persona_ready'));
    expect(
      profile.missingDimensions.toSet().intersection(
            PersonaDimensionIds.frequency.toSet(),
          ),
      isNotEmpty,
    );
  });

  test('version mismatch blocks assembly', () {
    final iq = score('iq', 'valid_iq_bank.json', 'valid_iq_responses.json');
    final bad = ModuleTraitResult(
      assessmentType: 'eq',
      schemaVersion: iq.schemaVersion,
      contentVersion: 'x',
      traitScoringVersion: 'wrong_version',
      rviVersion: iq.rviVersion,
      setId: 'x',
      locale: 'tr',
      questionCount: 0,
      answeredCount: 0,
      rawAnswers: const {},
      legacyRawScore: null,
      dimensionScores: const {},
      dimensionEvidenceCounts: const {},
      dimensionPrimaryEvidenceCounts: const {},
      dimensionSecondaryEvidenceCounts: const {},
      dimensionIndependentContextCounts: const {},
      dimensionEvidenceSufficiency: const {},
      dimensionReliability: const {},
      missingDimensions: const [],
      insufficientDimensions: const [],
      responseValidity: const ResponseValidityResult(
        rviVersion: 'x',
        overallScore: 0,
        componentScores: {},
        availableComponents: [],
        missingComponents: [],
        status: ResponseValidityStatusBand.insufficientEvidence,
        reasonCodes: [],
        retestRecommended: true,
        publishableRecommendation: false,
      ),
      canonicalProfileReady: false,
      status: ModuleTraitStatus.incomplete,
      startedAt: null,
      completedAt: null,
      reasonCodes: const [],
      dimensionDetails: const [],
    );
    expect(
      () => assembler.assemble(iq: iq, eq: bad),
      throwsA(isA<TraitScoringValidationException>()),
    );
  });
}
