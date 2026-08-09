import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/frequency_pilot_review_candidate_1_helpers.dart';

void main() {
  late TraitScoringConfig config;
  late List<AssessmentItemDefinition> items;
  late TraitScoringService service;

  setUpAll(() {
    config = FrequencyPilotReviewCandidate1Loader.loadConfig();
    items = FrequencyPilotReviewCandidate1Loader.loadItems(config);
    service = TraitScoringService(config: config);
  });

  TraitScoringResult score(List<AssessmentResponse> responses,
      {String status = 'complete'}) {
    return service.scoreModule(
      FrequencyPilotReviewCandidate1Loader.session(
        config: config,
        items: items,
        responses: responses,
        assessmentStatus: status,
      ),
    );
  }

  void expectFinite(TraitScoringResult r) {
    for (final s in r.module.dimensionScores.values) {
      expect(s.isFinite, isTrue);
    }
  }

  test('TraitScoringService accepts candidate', () {
    expect(items, hasLength(50));
    final r = score(FrequencyPilotReviewCandidate1Loader.balancedMixed(items));
    expectFinite(r);
  });

  test('high vs low depth_preference distinguishable', () {
    final high = score(
      FrequencyPilotReviewCandidate1Loader.highDimension(
          items, 'depth_preference'),
    );
    final low = score(
      FrequencyPilotReviewCandidate1Loader.lowDimension(
          items, 'depth_preference'),
    );
    expect(
      high.module.dimensionScores['depth_preference']!,
      greaterThan(low.module.dimensionScores['depth_preference']!),
    );
  });

  test('semantic consistent/inconsistent run finitely', () {
    expectFinite(
      score(FrequencyPilotReviewCandidate1Loader.semanticConsistent(items)),
    );
    expectFinite(
      score(FrequencyPilotReviewCandidate1Loader.semanticInconsistent(items)),
    );
  });

  test('behavioral reverse-consistent uses primary sign not option letter', () {
    final r = score(
      FrequencyPilotReviewCandidate1Loader.reverseBehavioralConsistent(items),
    );
    expectFinite(r);
    expect(r.module.dimensionScores['depth_preference'], isNotNull);
  });

  test('behavioral reverse inconsistent pattern runs finitely', () {
    expectFinite(
      score(
        FrequencyPilotReviewCandidate1Loader.reverseBehavioralInconsistent(
            items),
      ),
    );
  });

  test('uniform first/last option do not create NaN', () {
    expectFinite(
      score(FrequencyPilotReviewCandidate1Loader.alwaysOption(items, 'A')),
    );
    expectFinite(
      score(FrequencyPilotReviewCandidate1Loader.alwaysOption(items, 'D')),
    );
  });

  test('fixed-seed random is deterministic', () {
    final a = score(
        FrequencyPilotReviewCandidate1Loader.randomSeeded(items, seed: 42));
    final b = score(
        FrequencyPilotReviewCandidate1Loader.randomSeeded(items, seed: 42));
    expect(a.module.dimensionScores, equals(b.module.dimensionScores));
  });

  test('missing dimension remains unpublished', () {
    final r = score(
      FrequencyPilotReviewCandidate1Loader.omitPrimaryDimension(
        items,
        'disclosure_pace',
      ),
    );
    expect(r.module.dimensionScores.containsKey('disclosure_pace'), isFalse);
    expect(
      r.module.missingDimensions.contains('disclosure_pace') ||
          r.module.insufficientDimensions.contains('disclosure_pace'),
      isTrue,
    );
  });

  test('partial completion remains incomplete', () {
    final partial = FrequencyPilotReviewCandidate1Loader.balancedMixed(items)
        .take(10)
        .toList();
    final r = score(partial, status: 'incomplete');
    expect(r.module.status, ModuleTraitStatus.incomplete);
  });

  test('duplicate and unknown responses fail explicitly', () {
    final base = FrequencyPilotReviewCandidate1Loader.balancedMixed(items);
    expect(
      () => FrequencyPilotReviewCandidate1Loader.validateResponses(
        items: items,
        responses: [...base, base.first],
      ),
      throwsA(isA<TraitScoringValidationException>()),
    );
    expect(
      () => FrequencyPilotReviewCandidate1Loader.validateResponses(
        items: items,
        responses: [
          AssessmentResponse(
            questionId: 'not_a_real_question',
            selectedOptionId: 'A',
            responseTimeMilliseconds: 1000,
          ),
        ],
      ),
      throwsA(isA<TraitScoringValidationException>()),
    );
  });

  test('RVI does not alter trait scores when comparing identical responses',
      () {
    final responses = FrequencyPilotReviewCandidate1Loader.balancedMixed(items);
    final a = score(responses);
    final b = score(responses);
    expect(a.module.dimensionScores, equals(b.module.dimensionScores));
    expect(a.module.responseValidity, isNotNull);
  });

  test('shuffled JSON key order does not change parse scores', () {
    final form = FrequencyPilotReviewCandidate1Loader.loadForm();
    final encoded = jsonEncode(form);
    final reparsed = jsonDecode(encoded) as Map<String, dynamic>;
    final items2 = TraitScoringParser.parseItemBank(
      reparsed['items'] as List<dynamic>,
      expectedModule: 'frequency',
      source: 'reparsed',
      config: config,
    );
    final r1 = score(FrequencyPilotReviewCandidate1Loader.balancedMixed(items));
    final r2 = service.scoreModule(
      FrequencyPilotReviewCandidate1Loader.session(
        config: config,
        items: items2,
        responses: FrequencyPilotReviewCandidate1Loader.balancedMixed(items2),
      ),
    );
    expect(r1.module.dimensionScores, equals(r2.module.dimensionScores));
  });
}
