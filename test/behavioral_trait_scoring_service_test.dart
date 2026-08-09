import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'trait_scoring_fixture_loader.dart';

void main() {
  late TraitScoringConfig config;
  late TraitScoringService service;

  setUpAll(() {
    config = TraitScoringFixtureLoader.loadConfig();
    service = TraitScoringService(config: config);
  });

  test('EQ signed evidence maps high > low', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'valid_eq_bank.json',
      module: 'eq',
      config: config,
    );
    final high = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'eq',
        config: config,
        items: items,
        responses: TraitScoringFixtureLoader.loadResponses(
          'valid_eq_responses_high.json',
        ),
      ),
    );
    final low = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'eq',
        config: config,
        items: items,
        responses: TraitScoringFixtureLoader.loadResponses(
          'valid_eq_responses_low.json',
        ),
      ),
    );
    expect(high.module.dimensionScores['empathy']!,
        greaterThan(low.module.dimensionScores['empathy']!));
    expect(high.module.dimensionScores['empathy']!, greaterThan(0.7));
    expect(low.module.dimensionScores['empathy']!, lessThan(0.3));
  });

  test('Frequency covers all six dimensions', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'valid_frequency_bank.json',
      module: 'frequency',
      config: config,
    );
    final r = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'frequency',
        config: config,
        items: items,
        responses: TraitScoringFixtureLoader.loadResponses(
          'valid_frequency_responses.json',
        ),
      ),
    );
    expect(r.module.dimensionScores.length, 6);
    expect(r.module.dimensionScores['stability']!, greaterThan(0.7));
  });

  test('reverse pair consistency contributes to RVI without changing traits',
      () {
    final items = TraitScoringFixtureLoader.loadBank(
      'reverse_pair_bank.json',
      module: 'eq',
      config: config,
    );
    final descriptors = TraitScoringFixtureLoader.loadReversePairDescriptors(
      'reverse_pair_bank.json',
    );
    final consistent = [
      const AssessmentResponse(
        questionId: 'eq_rev_a',
        selectedOptionId: 'yes',
        responseTimeMilliseconds: 5000,
      ),
      const AssessmentResponse(
        questionId: 'eq_rev_b',
        selectedOptionId: 'yes',
        responseTimeMilliseconds: 5000,
      ),
    ];
    final r = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'eq',
        config: config,
        items: items,
        responses: consistent,
        reversePairDescriptors: descriptors,
      ),
    );
    expect(
      r.module.responseValidity.componentScores['reverse_consistency'],
      closeTo(1.0, 1e-9),
    );
    final bound = r.module.dimensionDetails
        .firstWhere((d) => d.dimensionId == 'boundary_setting');
    // Trait values come only from deltas; RVI is separate.
    expect(bound.score, isNotNull);
  });

  test('semantic pair agreement is measured', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'semantic_pair_bank.json',
      module: 'eq',
      config: config,
    );
    final r = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'eq',
        config: config,
        items: items,
        responses: const [
          AssessmentResponse(
            questionId: 'eq_sem_a',
            selectedOptionId: 'yes',
            responseTimeMilliseconds: 4000,
          ),
          AssessmentResponse(
            questionId: 'eq_sem_b',
            selectedOptionId: 'yes',
            responseTimeMilliseconds: 4000,
          ),
        ],
      ),
    );
    expect(
      r.module.responseValidity.componentScores['semantic_consistency'],
      closeTo(1.0, 1e-9),
    );
  });

  test('JSON map order does not change EQ results', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'valid_eq_bank.json',
      module: 'eq',
      config: config,
    );
    final responses = TraitScoringFixtureLoader.loadResponses(
      'valid_eq_responses_high.json',
    );
    final a = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'eq',
        config: config,
        items: items,
        responses: responses,
      ),
    );
    final b = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'eq',
        config: config,
        items: List.of(items.reversed),
        responses: List.of(responses.reversed),
      ),
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
  });
}
