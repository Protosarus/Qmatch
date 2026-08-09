import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/iq_pilot_review_candidate_1_helpers.dart';

void main() {
  late TraitScoringConfig config;
  late TraitScoringService service;
  late List<AssessmentItemDefinition> items;

  setUpAll(() {
    config = IqPilotReviewCandidate1Helpers.loadConfig();
    service = TraitScoringService(config: config);
    items = IqPilotReviewCandidate1Helpers.loadItems(config);
  });

  test('all-correct produces 1.0 in all four domains; legacy=25', () {
    final r = service.scoreModule(
      IqPilotReviewCandidate1Helpers.session(
        config: config,
        items: items,
        responses: IqPilotReviewCandidate1Helpers.allCorrect(items),
      ),
    );
    for (final d in PersonaDimensionIds.iq) {
      expect(r.module.dimensionScores[d], closeTo(1.0, 1e-9));
    }
    expect(r.module.legacyRawScore, 25);
  });

  test('all-incorrect produces 0.0 in all four domains; legacy=0', () {
    final r = service.scoreModule(
      IqPilotReviewCandidate1Helpers.session(
        config: config,
        items: items,
        responses: IqPilotReviewCandidate1Helpers.allIncorrect(items),
      ),
    );
    for (final d in PersonaDimensionIds.iq) {
      expect(r.module.dimensionScores[d], closeTo(0.0, 1e-9));
    }
    expect(r.module.legacyRawScore, 0);
  });

  test('domain-isolated correctness keeps domains independent', () {
    final r = service.scoreModule(
      IqPilotReviewCandidate1Helpers.session(
        config: config,
        items: items,
        responses: IqPilotReviewCandidate1Helpers.oneCorrectPerDomain(items),
      ),
    );
    for (final d in PersonaDimensionIds.iq) {
      final score = r.module.dimensionScores[d]!;
      expect(score, greaterThan(0.0));
      expect(score, lessThan(1.0));
    }
  });

  test('omitted domain is missing; not neutral-filled', () {
    final r = service.scoreModule(
      IqPilotReviewCandidate1Helpers.session(
        config: config,
        items: items,
        responses: IqPilotReviewCandidate1Helpers.omitDomain(
          items,
          'verbal_reasoning',
        ),
      ),
    );
    expect(r.module.dimensionScores.containsKey('verbal_reasoning'), isFalse);
    final detail = r.module.dimensionDetails
        .firstWhere((d) => d.dimensionId == 'verbal_reasoning');
    expect(detail.score, isNot(0.5));
    expect(detail.score, isNot(0.42));
  });

  test('always A/B/C/D and alternating patterns score finitely', () {
    for (final responses in [
      IqPilotReviewCandidate1Helpers.alwaysLetter(items, 'A'),
      IqPilotReviewCandidate1Helpers.alwaysLetter(items, 'B'),
      IqPilotReviewCandidate1Helpers.alwaysLetter(items, 'C'),
      IqPilotReviewCandidate1Helpers.alwaysLetter(items, 'D'),
      IqPilotReviewCandidate1Helpers.alternating(items),
      IqPilotReviewCandidate1Helpers.randomSeeded(items),
    ]) {
      final r = service.scoreModule(
        IqPilotReviewCandidate1Helpers.session(
          config: config,
          items: items,
          responses: responses,
        ),
      );
      for (final s in r.module.dimensionScores.values) {
        expect(s.isFinite, isTrue);
        expect(s, inInclusiveRange(0.0, 1.0));
      }
    }
  });

  test('shuffled question order is deterministic for all-correct', () {
    final forward = service.scoreModule(
      IqPilotReviewCandidate1Helpers.session(
        config: config,
        items: items,
        responses: IqPilotReviewCandidate1Helpers.allCorrect(items),
      ),
    );
    final rev = items.reversed.toList();
    final reversed = service.scoreModule(
      IqPilotReviewCandidate1Helpers.session(
        config: config,
        items: rev,
        responses: IqPilotReviewCandidate1Helpers.allCorrect(rev),
      ),
    );
    expect(
      forward.module.dimensionScores.toString(),
      reversed.module.dimensionScores.toString(),
    );
  });

  test('duplicate and unknown responses fail explicitly', () {
    final base = IqPilotReviewCandidate1Helpers.allCorrect(items);
    expect(
      () => IqPilotReviewCandidate1Helpers.validateResponses(
        items: items,
        responses: [...base, base.first],
      ),
      throwsA(isA<TraitScoringValidationException>()),
    );
    expect(
      () => IqPilotReviewCandidate1Helpers.validateResponses(
        items: items,
        responses: [
          const AssessmentResponse(
            questionId: 'does_not_exist',
            selectedOptionId: 'A',
          ),
        ],
      ),
      throwsA(isA<TraitScoringValidationException>()),
    );
  });

  test('PersonaScoringService is not automatically invoked', () {
    final r = service.scoreModule(
      IqPilotReviewCandidate1Helpers.session(
        config: config,
        items: items,
        responses: IqPilotReviewCandidate1Helpers.allCorrect(items),
      ),
    );
    expect(r.module.rawAnswers.containsKey('persona_id'), isFalse);
    expect(r.runtimeType.toString(), contains('TraitScoringResult'));
  });

  test('partial completion remains incomplete', () {
    final r = service.scoreModule(
      IqPilotReviewCandidate1Helpers.session(
        config: config,
        items: items,
        responses:
            IqPilotReviewCandidate1Helpers.allCorrect(items).take(3).toList(),
        assessmentStatus: 'incomplete',
      ),
    );
    expect(r.module.status, ModuleTraitStatus.incomplete);
  });
}
