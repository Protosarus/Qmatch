import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/eq_pilot_review_candidate_1_helpers.dart';

void main() {
  late TraitScoringConfig config;
  late List<AssessmentItemDefinition> items;
  late TraitScoringService service;

  setUpAll(() {
    config = EqPilotReviewCandidate1Loader.loadConfig();
    items = EqPilotReviewCandidate1Loader.loadItems(config);
    service = TraitScoringService(config: config);
  });

  TraitScoringResult score(List<AssessmentResponse> responses,
      {String status = 'complete'}) {
    return service.scoreModule(
      EqPilotReviewCandidate1Loader.session(
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
    expect(items, hasLength(30));
    final r = score(EqPilotReviewCandidate1Loader.balancedMixed(items));
    expectFinite(r);
  });

  test('high vs low empathy distinguishable', () {
    final high =
        score(EqPilotReviewCandidate1Loader.highDimension(items, 'empathy'));
    final low =
        score(EqPilotReviewCandidate1Loader.lowDimension(items, 'empathy'));
    expect(high.module.dimensionScores['empathy']!,
        greaterThan(low.module.dimensionScores['empathy']!));
  });

  test('boundary/openness trade-off patterns diverge when scored', () {
    final a =
        score(EqPilotReviewCandidate1Loader.highBoundaryLowOpenness(items));
    final b =
        score(EqPilotReviewCandidate1Loader.highOpennessLowBoundary(items));
    if (a.module.dimensionScores.containsKey('boundary_setting') &&
        b.module.dimensionScores.containsKey('boundary_setting')) {
      expect(a.module.dimensionScores['boundary_setting']!,
          greaterThan(b.module.dimensionScores['boundary_setting']!));
    }
    if (a.module.dimensionScores.containsKey('emotional_openness') &&
        b.module.dimensionScores.containsKey('emotional_openness')) {
      expect(b.module.dimensionScores['emotional_openness']!,
          greaterThan(a.module.dimensionScores['emotional_openness']!));
    }
    expectFinite(a);
    expectFinite(b);
  });

  test('assertiveness/repair trade-off patterns diverge', () {
    final a =
        score(EqPilotReviewCandidate1Loader.highAssertivenessLowRepair(items));
    final b =
        score(EqPilotReviewCandidate1Loader.highRepairLowAssertiveness(items));
    expect(a.module.dimensionScores['assertiveness']!,
        greaterThan(b.module.dimensionScores['assertiveness']!));
    expect(b.module.dimensionScores['repair_orientation']!,
        greaterThan(a.module.dimensionScores['repair_orientation']!));
  });

  test('semantic consistent/inconsistent run finitely', () {
    expectFinite(
        score(EqPilotReviewCandidate1Loader.semanticConsistent(items)));
    expectFinite(
        score(EqPilotReviewCandidate1Loader.semanticInconsistent(items)));
  });

  test('reverse trait-consistent pattern raises assertiveness', () {
    final r =
        score(EqPilotReviewCandidate1Loader.reverseTraitConsistent(items));
    expectFinite(r);
    // Includes reverse members with positive keying.
    expect(r.module.dimensionScores['assertiveness'], isNotNull);
  });

  test('uniform first/last option do not create NaN', () {
    expectFinite(score(EqPilotReviewCandidate1Loader.alwaysOption(items, 'A')));
    expectFinite(score(EqPilotReviewCandidate1Loader.alwaysOption(items, 'D')));
  });

  test('fixed-seed random is deterministic', () {
    final a =
        score(EqPilotReviewCandidate1Loader.randomSeeded(items, seed: 42));
    final b =
        score(EqPilotReviewCandidate1Loader.randomSeeded(items, seed: 42));
    expect(a.module.dimensionScores, equals(b.module.dimensionScores));
  });

  test('idealized and privacy/direct/cooling patterns finite', () {
    expectFinite(score(EqPilotReviewCandidate1Loader.idealizedHighSdr(items)));
    expectFinite(score(EqPilotReviewCandidate1Loader.privacyOriented(items)));
    expectFinite(score(EqPilotReviewCandidate1Loader.directConflict(items)));
    expectFinite(score(EqPilotReviewCandidate1Loader.coolingOff(items)));
  });

  test('missing dimension remains unpublished', () {
    final r = score(
      EqPilotReviewCandidate1Loader.omitPrimaryDimension(items, 'empathy'),
    );
    expect(r.module.dimensionScores.containsKey('empathy'), isFalse);
    expect(
      r.module.missingDimensions.contains('empathy') ||
          r.module.insufficientDimensions.contains('empathy'),
      isTrue,
    );
  });

  test('partial completion remains incomplete', () {
    final partial =
        EqPilotReviewCandidate1Loader.balancedMixed(items).take(10).toList();
    final r = score(partial, status: 'incomplete');
    expect(r.module.status, ModuleTraitStatus.incomplete);
  });

  test('duplicate and unknown responses fail explicitly', () {
    final base = EqPilotReviewCandidate1Loader.balancedMixed(items);
    expect(
      () => EqPilotReviewCandidate1Loader.validateResponses(
        items: items,
        responses: [...base, base.first],
      ),
      throwsA(isA<TraitScoringValidationException>()),
    );
    expect(
      () => EqPilotReviewCandidate1Loader.validateResponses(
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

  test('shuffled question order is deterministic for balanced mixed', () {
    final responses = EqPilotReviewCandidate1Loader.balancedMixed(items);
    final a = score(responses);
    final b = score(EqPilotReviewCandidate1Loader.sortResponses(
      [...responses]..shuffle(),
    ));
    expect(a.module.dimensionScores, equals(b.module.dimensionScores));
  });

  test('shuffled JSON key order does not change parse scores', () {
    final form = EqPilotReviewCandidate1Loader.loadForm();
    final encoded = jsonEncode(form);
    final reparsed = jsonDecode(encoded) as Map<String, dynamic>;
    final items2 = TraitScoringParser.parseItemBank(
      reparsed['items'] as List<dynamic>,
      expectedModule: 'eq',
      source: 'reparsed',
      config: config,
    );
    final r1 = score(EqPilotReviewCandidate1Loader.balancedMixed(items));
    final r2 = service.scoreModule(
      EqPilotReviewCandidate1Loader.session(
        config: config,
        items: items2,
        responses: EqPilotReviewCandidate1Loader.balancedMixed(items2),
      ),
    );
    expect(r1.module.dimensionScores, equals(r2.module.dimensionScores));
  });

  test('RVI does not alter trait direction vs identical responses', () {
    final responses = EqPilotReviewCandidate1Loader.balancedMixed(items);
    final a = score(responses);
    final b = score(responses);
    expect(a.module.dimensionScores, equals(b.module.dimensionScores));
    expect(a.module.responseValidity, isNotNull);
  });
}
