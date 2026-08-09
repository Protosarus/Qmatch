import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/frequency_pilot_v1_helpers.dart';

void main() {
  late TraitScoringConfig config;
  late TraitScoringService service;
  late List<AssessmentItemDefinition> items;

  setUpAll(() {
    config = FrequencyPilotV1Loader.loadConfig();
    service = TraitScoringService(config: config);
    items = FrequencyPilotV1Loader.loadItems(config);
  });

  test('full coverage max-primary produces all six Frequency dimensions', () {
    final r = service.scoreModule(
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: FrequencyPilotV1Loader.fullCoverageMaxPrimary(items),
      ),
    );
    expect(r.module.dimensionScores.length, 6);
    for (final d in PersonaDimensionIds.frequency) {
      expect(r.module.dimensionScores[d], isNotNull);
      expect(r.module.dimensionScores[d]!, inInclusiveRange(0.0, 1.0));
    }
  });

  test('balanced mixed scores available dimensions finitely', () {
    final r = service.scoreModule(
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: FrequencyPilotV1Loader.balancedMixed(items),
      ),
    );
    expect(r.module.dimensionScores.length, greaterThanOrEqualTo(5));
    for (final s in r.module.dimensionScores.values) {
      expect(s.isFinite, isTrue);
      expect(s, inInclusiveRange(0.0, 1.0));
    }
  });

  test('high disclosure_pace exceeds low; negative evidence lowers score', () {
    final high = service.scoreModule(
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: FrequencyPilotV1Loader.highDisclosurePace(items),
      ),
    );
    final low = service.scoreModule(
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: FrequencyPilotV1Loader.lowDisclosurePace(items),
      ),
    );
    expect(
      high.module.dimensionScores['disclosure_pace']!,
      greaterThan(low.module.dimensionScores['disclosure_pace']!),
    );
  });

  test('omitted disclosure_pace primaries leave dimension missing/unpublished',
      () {
    final r = service.scoreModule(
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: FrequencyPilotV1Loader.omitPrimaryDimension(
            items, 'disclosure_pace'),
      ),
    );
    expect(r.module.dimensionScores.containsKey('disclosure_pace'), isFalse);
    expect(
      r.module.missingDimensions.contains('disclosure_pace') ||
          r.module.insufficientDimensions.contains('disclosure_pace'),
      isTrue,
    );
    final detail = r.module.dimensionDetails
        .firstWhere((d) => d.dimensionId == 'disclosure_pace');
    expect(detail.score, isNot(0.5));
    expect(detail.score, isNot(0.42));
  });

  test('duplicate and unknown responses fail explicitly', () {
    final base = FrequencyPilotV1Loader.balancedMixed(items);
    expect(
      () => FrequencyPilotV1Loader.validateResponses(
        items: items,
        responses: [...base, base.first],
      ),
      throwsA(isA<TraitScoringValidationException>()),
    );
    expect(
      () => FrequencyPilotV1Loader.validateResponses(
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
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: FrequencyPilotV1Loader.balancedMixed(items),
      ),
    );
    expect(r.module.rawAnswers.containsKey('persona_id'), isFalse);
    expect(r.runtimeType.toString(), contains('TraitScoringResult'));
  });

  test('pattern fixtures score finitely', () {
    for (final responses in [
      FrequencyPilotV1Loader.highDepthPreference(items),
      FrequencyPilotV1Loader.lowDepthPreference(items),
      FrequencyPilotV1Loader.highSocialEnergy(items),
      FrequencyPilotV1Loader.lowSocialEnergy(items),
      FrequencyPilotV1Loader.highSpontaneity(items),
      FrequencyPilotV1Loader.lowSpontaneity(items),
      FrequencyPilotV1Loader.highStability(items),
      FrequencyPilotV1Loader.lowStability(items),
      FrequencyPilotV1Loader.highDepthSlowCommunication(items),
      FrequencyPilotV1Loader.lowDepthFastCommunication(items),
      FrequencyPilotV1Loader.highSpontaneityHighStability(items),
      FrequencyPilotV1Loader.lowSpontaneityLowStability(items),
      FrequencyPilotV1Loader.highStabilityLowSpontaneity(items),
      FrequencyPilotV1Loader.highSpontaneityLowStability(items),
      FrequencyPilotV1Loader.fastDisclosureSlowCommunication(items),
      FrequencyPilotV1Loader.slowDisclosureFastCommunication(items),
      FrequencyPilotV1Loader.highCommunicationPace(items),
      FrequencyPilotV1Loader.highlyIndependentPattern(items),
      FrequencyPilotV1Loader.highlyContactOrientedPattern(items),
      FrequencyPilotV1Loader.idealizedHighSdrClustering(items),
      FrequencyPilotV1Loader.semanticConsistent(items),
      FrequencyPilotV1Loader.semanticInconsistent(items),
      FrequencyPilotV1Loader.reverseConsistent(items),
      FrequencyPilotV1Loader.reverseInconsistent(items),
      FrequencyPilotV1Loader.alwaysOptionA(items),
      FrequencyPilotV1Loader.alwaysOptionD(items),
      FrequencyPilotV1Loader.randomSeeded(items),
    ]) {
      final r = service.scoreModule(
        FrequencyPilotV1Loader.session(
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
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses:
            FrequencyPilotV1Loader.balancedMixed(items).take(12).toList(),
        assessmentStatus: 'incomplete',
      ),
    );
    expect(r.module.status, ModuleTraitStatus.incomplete);
  });
}
