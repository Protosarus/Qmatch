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

  test('reliability is separate from trait direction and finite', () {
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
    final rh = high.module.dimensionReliability['empathy']!;
    final rl = low.module.dimensionReliability['empathy']!;
    expect(rh.isFinite, isTrue);
    expect(rl.isFinite, isTrue);
    expect(rh, closeTo(rl, 0.05));
    expect(high.module.dimensionScores['empathy']!,
        isNot(closeTo(low.module.dimensionScores['empathy']!, 0.05)));
  });

  test('missing reliability components do not become perfect scores', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'incomplete_evidence_bank.json',
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
            questionId: 'eq_one',
            selectedOptionId: 'a',
            responseTimeMilliseconds: 3000,
          ),
        ],
      ),
    );
    final detail =
        r.module.dimensionDetails.firstWhere((d) => d.dimensionId == 'empathy');
    expect(detail.reliability, lessThan(1.0));
    expect(detail.reliabilityComponents.containsKey('semantic_consistency'),
        isFalse);
  });
}
