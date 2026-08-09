import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/iq_pilot_v1_helpers.dart';

void main() {
  late TraitScoringConfig config;
  late TraitScoringService service;
  late List<AssessmentItemDefinition> items;

  setUpAll(() {
    config = IqPilotV1Loader.loadConfig();
    service = TraitScoringService(config: config);
    items = IqPilotV1Loader.loadItems(config);
  });

  test('all-correct produces 1.0 in all four domains; legacy=25', () {
    final r = service.scoreModule(
      IqPilotV1Loader.session(
        config: config,
        items: items,
        responses: IqPilotV1Loader.allCorrect(items),
      ),
    );
    for (final d in PersonaDimensionIds.iq) {
      expect(r.module.dimensionScores[d], closeTo(1.0, 1e-9));
    }
    expect(r.module.legacyRawScore, 25);
    expect(r.module.dimensionScores.length, 4);
  });

  test('all-incorrect produces 0.0 in all four domains; legacy=0', () {
    final r = service.scoreModule(
      IqPilotV1Loader.session(
        config: config,
        items: items,
        responses: IqPilotV1Loader.allIncorrect(items),
      ),
    );
    for (final d in PersonaDimensionIds.iq) {
      expect(r.module.dimensionScores[d], closeTo(0.0, 1e-9));
    }
    expect(r.module.legacyRawScore, 0);
  });

  test('domain-isolated correctness affects only that domain', () {
    final r = service.scoreModule(
      IqPilotV1Loader.session(
        config: config,
        items: items,
        responses: IqPilotV1Loader.oneCorrectPerDomain(items),
      ),
    );
    for (final d in PersonaDimensionIds.iq) {
      final score = r.module.dimensionScores[d]!;
      expect(score, greaterThan(0.0));
      expect(score, lessThan(1.0));
    }
    // Domains remain independent values (not forced equal).
    final vals =
        PersonaDimensionIds.iq.map((d) => r.module.dimensionScores[d]!).toSet();
    expect(vals.length, greaterThan(1));
  });

  test('omitted domain is missing/unpublished; not 0/0.5/0.42', () {
    final r = service.scoreModule(
      IqPilotV1Loader.session(
        config: config,
        items: items,
        responses: IqPilotV1Loader.omitDomain(items, 'verbal_reasoning'),
      ),
    );
    expect(r.module.dimensionScores.containsKey('verbal_reasoning'), isFalse);
    expect(
      r.module.missingDimensions.contains('verbal_reasoning') ||
          r.module.insufficientDimensions.contains('verbal_reasoning'),
      isTrue,
    );
    final detail = r.module.dimensionDetails
        .firstWhere((d) => d.dimensionId == 'verbal_reasoning');
    expect(detail.score, isNot(0.5));
    expect(detail.score, isNot(0.42));
  });

  test('duplicate and unknown responses fail explicitly', () {
    final base = IqPilotV1Loader.allCorrect(items);
    expect(
      () => IqPilotV1Loader.validateResponses(
        items: items,
        responses: [...base, base.first],
      ),
      throwsA(isA<TraitScoringValidationException>()),
    );
    expect(
      () => IqPilotV1Loader.validateResponses(
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
      IqPilotV1Loader.session(
        config: config,
        items: items,
        responses: IqPilotV1Loader.allCorrect(items),
      ),
    );
    expect(r.module.rawAnswers.containsKey('persona_id'), isFalse);
    expect(r.runtimeType.toString(), contains('TraitScoringResult'));
  });

  test('alternating / random / always-A patterns score finitely', () {
    for (final responses in [
      IqPilotV1Loader.alternating(items),
      IqPilotV1Loader.randomSeeded(items),
      IqPilotV1Loader.alwaysOptionA(items),
    ]) {
      final r = service.scoreModule(
        IqPilotV1Loader.session(
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

  test('incomplete assessment status remains incomplete', () {
    final r = service.scoreModule(
      IqPilotV1Loader.session(
        config: config,
        items: items,
        responses: IqPilotV1Loader.allCorrect(items).take(3).toList(),
        assessmentStatus: 'incomplete',
      ),
    );
    expect(r.module.status, ModuleTraitStatus.incomplete);
  });
}
