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

  test('full coverage max-primary produces all ten EQ dimensions', () {
    final r = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.fullCoverageMaxPrimary(items),
      ),
    );
    expect(r.module.dimensionScores.length, 10);
    for (final d in PersonaDimensionIds.eq) {
      expect(r.module.dimensionScores[d], isNotNull);
      expect(r.module.dimensionScores[d]!, inInclusiveRange(0.0, 1.0));
    }
  });

  test('balanced mixed scores available dimensions finitely', () {
    final r = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.balancedMixed(items),
      ),
    );
    expect(r.module.dimensionScores.length, greaterThanOrEqualTo(8));
    for (final s in r.module.dimensionScores.values) {
      expect(s.isFinite, isTrue);
      expect(s, inInclusiveRange(0.0, 1.0));
    }
  });

  test('high empathy exceeds low empathy; negative evidence lowers score', () {
    final high = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.highEmpathy(items),
      ),
    );
    final low = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.lowEmpathy(items),
      ),
    );
    expect(
      high.module.dimensionScores['empathy']!,
      greaterThan(low.module.dimensionScores['empathy']!),
    );
  });

  test('omitted empathy primaries leave empathy missing/unpublished', () {
    final r = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.omitPrimaryDimension(items, 'empathy'),
      ),
    );
    expect(r.module.dimensionScores.containsKey('empathy'), isFalse);
    expect(
      r.module.missingDimensions.contains('empathy') ||
          r.module.insufficientDimensions.contains('empathy'),
      isTrue,
    );
    final detail =
        r.module.dimensionDetails.firstWhere((d) => d.dimensionId == 'empathy');
    expect(detail.score, isNot(0.5));
    expect(detail.score, isNot(0.42));
  });

  test('duplicate and unknown responses fail explicitly', () {
    final base = EqPilotV1Loader.balancedMixed(items);
    expect(
      () => EqPilotV1Loader.validateResponses(
        items: items,
        responses: [...base, base.first],
      ),
      throwsA(isA<TraitScoringValidationException>()),
    );
    expect(
      () => EqPilotV1Loader.validateResponses(
        items: items,
        responses: const [
          AssessmentResponse(
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
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.balancedMixed(items),
      ),
    );
    expect(r.module.rawAnswers.containsKey('persona_id'), isFalse);
    expect(r.runtimeType.toString(), contains('TraitScoringResult'));
  });

  test('pattern fixtures score finitely', () {
    for (final responses in [
      EqPilotV1Loader.highBoundaryLowOpenness(items),
      EqPilotV1Loader.highOpennessLowBoundary(items),
      EqPilotV1Loader.highRegulation(items),
      EqPilotV1Loader.alwaysOptionA(items),
      EqPilotV1Loader.alwaysOptionD(items),
      EqPilotV1Loader.randomSeeded(items),
    ]) {
      final r = service.scoreModule(
        EqPilotV1Loader.session(
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

  test('partial completion remains incomplete', () {
    final r = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.balancedMixed(items).take(8).toList(),
        assessmentStatus: 'incomplete',
      ),
    );
    expect(r.module.status, ModuleTraitStatus.incomplete);
  });
}
