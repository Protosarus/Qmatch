import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'trait_scoring_fixture_loader.dart';

void main() {
  late TraitScoringConfig config;
  late TraitScoringService service;
  late List<AssessmentItemDefinition> items;

  setUpAll(() {
    config = TraitScoringFixtureLoader.loadConfig();
    service = TraitScoringService(config: config);
    items = TraitScoringFixtureLoader.loadBank(
      'valid_iq_bank.json',
      module: 'iq',
      config: config,
    );
  });

  test('IQ produces four independent domain scores and separate total', () {
    final responses = TraitScoringFixtureLoader.loadResponses(
      'valid_iq_responses.json',
    );
    final r = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'iq',
        config: config,
        items: items,
        responses: responses,
      ),
    );
    expect(r.module.legacyRawScore, 12);
    expect(r.module.answeredCount, 16);
    for (final d in PersonaDimensionIds.iq) {
      expect(r.module.dimensionScores.containsKey(d), isTrue, reason: d);
      expect(r.module.dimensionScores[d]!, closeTo(0.75, 1e-9));
      expect(r.module.dimensionPrimaryEvidenceCounts[d]! >= 3, isTrue);
    }
    expect(r.module.dimensionScores.length, 4);
  });

  test('IQ domains remain independent when only one domain is wrong', () {
    final responses = [
      for (final item in items)
        AssessmentResponse(
          questionId: item.questionId,
          selectedOptionId:
              item.primaryDimension == 'verbal_reasoning' ? 'b' : 'a',
          responseTimeMilliseconds: 9000,
        ),
    ];
    final r = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'iq',
        config: config,
        items: items,
        responses: responses,
      ),
    );
    expect(r.module.legacyRawScore, 12);
    expect(r.module.dimensionScores['logical_reasoning'], closeTo(1.0, 1e-9));
    expect(r.module.dimensionScores['verbal_reasoning'], closeTo(0.0, 1e-9));
  });

  test('same IQ input is deterministic and order-invariant', () {
    final responses = TraitScoringFixtureLoader.loadResponses(
      'valid_iq_responses.json',
    );
    final a = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'iq',
        config: config,
        items: items,
        responses: responses,
      ),
    );
    final b = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'iq',
        config: config,
        items: items.reversed.toList(),
        responses: responses.reversed.toList(),
      ),
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
    expect(a.module.legacyRawScore, b.module.legacyRawScore);
  });

  test('untagged IQ domains with no answers stay missing (no fabricated score)',
      () {
    final subset =
        items.where((i) => i.primaryDimension == 'logical_reasoning').toList();
    final responses = [
      for (final i in subset)
        AssessmentResponse(
          questionId: i.questionId,
          selectedOptionId: 'a',
          responseTimeMilliseconds: 5000,
        ),
    ];
    final r = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'iq',
        config: config,
        items: subset,
        responses: responses,
      ),
    );
    expect(r.module.dimensionScores.containsKey('pattern_reasoning'), isFalse);
    expect(r.module.missingDimensions, contains('pattern_reasoning'));
    expect(r.module.dimensionScores.containsKey('pattern_reasoning'), isFalse);
  });
}
