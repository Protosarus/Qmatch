import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/eq_pilot_v1_helpers.dart';

void main() {
  late TraitScoringConfig config;
  late TraitScoringService service;
  late List<AssessmentItemDefinition> items;

  setUpAll(() {
    config = EqPilotV1Loader.loadConfig();
    service = TraitScoringService(config: config);
    items = EqPilotV1Loader.loadItems(config);
  });

  test('semantic-consistent responses score higher semantic_consistency', () {
    final consistent = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.semanticConsistent(items),
      ),
    );
    final inconsistent = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.semanticInconsistent(items),
      ),
    );
    final c = consistent
        .module.responseValidity.componentScores['semantic_consistency'];
    final i = inconsistent
        .module.responseValidity.componentScores['semantic_consistency'];
    expect(c, isNotNull);
    expect(i, isNotNull);
    expect(c!, greaterThanOrEqualTo(i!));
    expect(i, lessThan(1.0));
  });

  test('reverse-consistent responses score higher reverse_consistency', () {
    final consistent = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.reverseConsistent(items),
      ),
    );
    final inconsistent = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.reverseInconsistent(items),
      ),
    );
    final c = consistent
        .module.responseValidity.componentScores['reverse_consistency'];
    final i = inconsistent
        .module.responseValidity.componentScores['reverse_consistency'];
    expect(c, isNotNull);
    expect(i, isNotNull);
    expect(c!, greaterThan(i!));
  });

  test('semantic and reverse RVI do not replace trait evidence', () {
    final traits = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.fullCoverageMaxPrimary(items),
      ),
    );
    expect(traits.module.dimensionScores.length, 10);
    expect(
      traits.module.responseValidity.componentScores.containsKey(
        'semantic_consistency',
      ),
      isTrue,
    );
  });

  test('idealized high-SDR clustering exposes bounded impression component',
      () {
    final r = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.idealizedHighSdrClustering(items),
      ),
    );
    final imp =
        r.module.responseValidity.componentScores['social_impression_risk'];
    expect(imp, isNotNull);
    expect(imp!, inInclusiveRange(0.0, 1.0));
  });

  test('RVI override does not alter trait values', () {
    final responses = EqPilotV1Loader.balancedMixed(items);
    final a = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: responses,
      ),
    );
    final b = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: responses,
      ),
      rviInput: const ResponseValidityInput(impressionRiskOverride: 0.95),
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
    expect(
      a.module.responseValidity.overallScore,
      isNot(b.module.responseValidity.overallScore),
    );
  });
}
