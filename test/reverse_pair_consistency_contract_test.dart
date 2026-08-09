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

  AssessmentItemDefinition item({
    required String id,
    required String pairId,
    required Map<String, double> aDeltas,
    required Map<String, double> bDeltas,
    String primary = 'boundary_setting',
  }) {
    return AssessmentItemDefinition(
      questionId: id,
      module: 'eq',
      schemaVersion: config.questionSchemaVersion,
      contentVersion: 'fixture_v1',
      itemType: 'scenario_mcq',
      primaryDimension: primary,
      secondaryDimensions: const [],
      prompt: const {'tr': 'x', 'en': 'x'},
      options: [
        AssessmentOptionDefinition(
          optionId: 'A',
          localizedText: const {'tr': 'A', 'en': 'A'},
          dimensionDeltas: aDeltas,
          evidenceStrength: 0.6,
          socialDesirabilityRisk: 'low',
          extremity: 0.2,
          responseStyleRisk: 'low',
          status: 'active',
        ),
        AssessmentOptionDefinition(
          optionId: 'B',
          localizedText: const {'tr': 'B', 'en': 'B'},
          dimensionDeltas: bDeltas,
          evidenceStrength: 0.6,
          socialDesirabilityRisk: 'low',
          extremity: 0.2,
          responseStyleRisk: 'low',
          status: 'active',
        ),
      ],
      reversePairId: pairId,
      exposureClass: 'core_pool',
      securityLevel: 'standard',
      estimatedCompletionSeconds: 20,
    );
  }

  TraitScoringResult score({
    required List<AssessmentItemDefinition> items,
    required List<AssessmentResponse> responses,
    required List<ReversePairDescriptor> descriptors,
  }) {
    return service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'eq',
        config: config,
        items: items,
        responses: responses,
        reversePairDescriptors: descriptors,
      ),
    );
  }

  test('same-sign behavioral correspondence is consistent', () {
    final items = [
      item(
        id: 'beh_a',
        pairId: 'beh_1',
        aDeltas: const {'boundary_setting': 0.6},
        bDeltas: const {'boundary_setting': -0.6},
      ),
      item(
        id: 'beh_b',
        pairId: 'beh_1',
        aDeltas: const {'boundary_setting': 0.6},
        bDeltas: const {'boundary_setting': -0.6},
      ),
    ];
    final r = score(
      items: items,
      responses: const [
        AssessmentResponse(questionId: 'beh_a', selectedOptionId: 'A'),
        AssessmentResponse(questionId: 'beh_b', selectedOptionId: 'A'),
      ],
      descriptors: const [
        ReversePairDescriptor(
          pairId: 'beh_1',
          questionIds: ['beh_a', 'beh_b'],
          consistencyMode: ReversePairConsistencyMode.behavioralCorrespondence,
        ),
      ],
    );
    expect(
      r.module.responseValidity.componentScores['reverse_consistency'],
      closeTo(1.0, 1e-9),
    );
  });

  test('opposite-sign reverse pairs remain supported', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'reverse_pair_bank.json',
      module: 'eq',
      config: config,
    );
    final descriptors = TraitScoringFixtureLoader.loadReversePairDescriptors(
      'reverse_pair_bank.json',
    );
    final r = score(
      items: items,
      responses: const [
        AssessmentResponse(questionId: 'eq_rev_a', selectedOptionId: 'yes'),
        AssessmentResponse(questionId: 'eq_rev_b', selectedOptionId: 'yes'),
      ],
      descriptors: descriptors,
    );
    expect(
      r.module.responseValidity.componentScores['reverse_consistency'],
      closeTo(1.0, 1e-9),
    );
  });

  test('explicit option mapping ignores raw letter coincidence', () {
    final items = [
      item(
        id: 'map_a',
        pairId: 'map_1',
        aDeltas: const {'boundary_setting': 0.6},
        bDeltas: const {'boundary_setting': -0.6},
      ),
      item(
        id: 'map_b',
        pairId: 'map_1',
        // Shuffled surface: option A is the low pole here.
        aDeltas: const {'boundary_setting': -0.6},
        bDeltas: const {'boundary_setting': 0.6},
      ),
    ];
    final descriptors = [
      ReversePairDescriptor(
        pairId: 'map_1',
        questionIds: const ['map_a', 'map_b'],
        consistencyMode: ReversePairConsistencyMode.explicitOptionMapping,
        optionCorrespondence: const {
          'map_a::A': 'B', // high on A maps to B on second item
          'map_a::B': 'A',
          'map_b::A': 'B',
          'map_b::B': 'A',
        },
      ),
    ];
    final consistent = score(
      items: items,
      responses: const [
        AssessmentResponse(questionId: 'map_a', selectedOptionId: 'A'),
        AssessmentResponse(questionId: 'map_b', selectedOptionId: 'B'),
      ],
      descriptors: descriptors,
    );
    final inconsistent = score(
      items: items,
      responses: const [
        AssessmentResponse(questionId: 'map_a', selectedOptionId: 'A'),
        AssessmentResponse(questionId: 'map_b', selectedOptionId: 'A'),
      ],
      descriptors: descriptors,
    );
    expect(
      consistent.module.responseValidity.componentScores['reverse_consistency'],
      closeTo(1.0, 1e-9),
    );
    expect(
      inconsistent
          .module.responseValidity.componentScores['reverse_consistency'],
      closeTo(0.0, 1e-9),
    );
  });

  test('missing metadata yields unavailable reverse RVI, not fabricated fail',
      () {
    final items = [
      item(
        id: 'miss_a',
        pairId: 'miss_1',
        aDeltas: const {'boundary_setting': 0.6},
        bDeltas: const {'boundary_setting': -0.6},
      ),
      item(
        id: 'miss_b',
        pairId: 'miss_1',
        aDeltas: const {'boundary_setting': 0.6},
        bDeltas: const {'boundary_setting': -0.6},
      ),
    ];
    final r = score(
      items: items,
      responses: const [
        AssessmentResponse(questionId: 'miss_a', selectedOptionId: 'A'),
        AssessmentResponse(questionId: 'miss_b', selectedOptionId: 'A'),
      ],
      descriptors: const [],
    );
    expect(
      r.module.responseValidity.componentScores
          .containsKey('reverse_consistency'),
      isFalse,
    );
    expect(
      r.module.responseValidity.missingComponents,
      contains('reverse_consistency'),
    );
    expect(
      r.module.responseValidity.reasonCodes,
      contains('rvi_reverse_metadata_unavailable'),
    );
  });

  test('partial pair responses leave reverse consistency unavailable', () {
    final items = [
      item(
        id: 'part_a',
        pairId: 'part_1',
        aDeltas: const {'boundary_setting': 0.6},
        bDeltas: const {'boundary_setting': -0.6},
      ),
      item(
        id: 'part_b',
        pairId: 'part_1',
        aDeltas: const {'boundary_setting': 0.6},
        bDeltas: const {'boundary_setting': -0.6},
      ),
    ];
    final r = score(
      items: items,
      responses: const [
        AssessmentResponse(questionId: 'part_a', selectedOptionId: 'A'),
      ],
      descriptors: const [
        ReversePairDescriptor(
          pairId: 'part_1',
          questionIds: ['part_a', 'part_b'],
          consistencyMode: ReversePairConsistencyMode.behavioralCorrespondence,
        ),
      ],
    );
    expect(
      r.module.responseValidity.componentScores
          .containsKey('reverse_consistency'),
      isFalse,
    );
  });

  test('RVI mode does not change trait direction or scores', () {
    final items = [
      item(
        id: 'tr_a',
        pairId: 'tr_1',
        aDeltas: const {'boundary_setting': 0.75},
        bDeltas: const {'boundary_setting': -0.75},
      ),
      item(
        id: 'tr_b',
        pairId: 'tr_1',
        aDeltas: const {'boundary_setting': 0.75},
        bDeltas: const {'boundary_setting': -0.75},
      ),
    ];
    const responses = [
      AssessmentResponse(questionId: 'tr_a', selectedOptionId: 'A'),
      AssessmentResponse(questionId: 'tr_b', selectedOptionId: 'A'),
    ];
    final withMeta = score(
      items: items,
      responses: responses,
      descriptors: const [
        ReversePairDescriptor(
          pairId: 'tr_1',
          questionIds: ['tr_a', 'tr_b'],
          consistencyMode: ReversePairConsistencyMode.behavioralCorrespondence,
        ),
      ],
    );
    final withoutMeta = score(
      items: items,
      responses: responses,
      descriptors: const [],
    );
    expect(withMeta.module.dimensionScores, withoutMeta.module.dimensionScores);
    final withDetail = withMeta.module.dimensionDetails
        .firstWhere((d) => d.dimensionId == 'boundary_setting');
    final withoutDetail = withoutMeta.module.dimensionDetails
        .firstWhere((d) => d.dimensionId == 'boundary_setting');
    expect(withDetail.signedEvidenceMean, withoutDetail.signedEvidenceMean);
    expect(withDetail.signedEvidenceMean, greaterThan(0.0));
  });

  test('deterministic reverse RVI across repeated calls', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'reverse_pair_bank.json',
      module: 'eq',
      config: config,
    );
    final descriptors = TraitScoringFixtureLoader.loadReversePairDescriptors(
      'reverse_pair_bank.json',
    );
    const responses = [
      AssessmentResponse(questionId: 'eq_rev_a', selectedOptionId: 'yes'),
      AssessmentResponse(questionId: 'eq_rev_b', selectedOptionId: 'yes'),
    ];
    final a =
        score(items: items, responses: responses, descriptors: descriptors);
    final b =
        score(items: items, responses: responses, descriptors: descriptors);
    expect(
      a.module.responseValidity.componentScores['reverse_consistency'],
      b.module.responseValidity.componentScores['reverse_consistency'],
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
  });
}
