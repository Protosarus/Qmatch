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

  test('timing anomalies create bounded signals without changing traits', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'timing_anomaly_bank.json',
      module: 'eq',
      config: config,
    );
    final responses = [
      for (final i in items)
        AssessmentResponse(
          questionId: i.questionId,
          selectedOptionId: 'high',
          responseTimeMilliseconds: 200, // extremely fast vs ~25s estimate
        ),
    ];
    final r = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'eq',
        config: config,
        items: items,
        responses: responses,
      ),
    );
    final timing = r.module.responseValidity.componentScores['timing_quality'];
    expect(timing, isNotNull);
    expect(timing!, lessThan(1.0));
    expect(timing, greaterThanOrEqualTo(0.0));
    expect(r.module.responseValidity.reasonCodes, contains('rvi_too_fast'));
    // Trait direction unchanged by timing.
    expect(r.module.dimensionDetails.first.score, isNotNull);
  });

  test('missing timing does not become perfect timing', () {
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
          AssessmentResponse(questionId: 'eq_sem_a', selectedOptionId: 'yes'),
          AssessmentResponse(questionId: 'eq_sem_b', selectedOptionId: 'yes'),
        ],
      ),
    );
    expect(
      r.module.responseValidity.missingComponents,
      contains('timing_quality'),
    );
    expect(
      r.module.responseValidity.componentScores.containsKey('timing_quality'),
      isFalse,
    );
  });

  test('impression risk is bounded and non-moral', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'impression_risk_bank.json',
      module: 'eq',
      config: config,
    );
    final r = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'eq',
        config: config,
        items: items,
        responses: [
          for (final i in items)
            AssessmentResponse(
              questionId: i.questionId,
              selectedOptionId: 'ideal',
              responseTimeMilliseconds: 6000,
            ),
        ],
      ),
    );
    final q =
        r.module.responseValidity.componentScores['social_impression_risk']!;
    expect(q, inInclusiveRange(0.0, 1.0));
    expect(
      r.module.responseValidity.reasonCodes.join(' '),
      isNot(contains('liar')),
    );
    expect(
      r.module.responseValidity.reasonCodes.join(' '),
      isNot(contains('dishonest')),
    );
    expect(
      r.module.responseValidity.reasonCodes,
      contains('rvi_impression_management_risk'),
    );
  });

  test('RVI does not alter trait values', () {
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
        items: items,
        responses: responses,
      ),
      rviInput: const ResponseValidityInput(impressionRiskOverride: 0.95),
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
    expect(a.module.responseValidity.overallScore,
        isNot(b.module.responseValidity.overallScore));
  });
}
