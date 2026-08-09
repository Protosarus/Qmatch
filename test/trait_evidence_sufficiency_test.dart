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

  test('dimension-specific requirements used; global /3 not applied', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'valid_iq_bank.json',
      module: 'iq',
      config: config,
    );
    final r = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'iq',
        config: config,
        items: items,
        responses: TraitScoringFixtureLoader.loadResponses(
          'valid_iq_responses.json',
        ),
      ),
    );
    final req = config.requireDimension('logical_reasoning');
    final dim = r.module.dimensionDetails
        .firstWhere((d) => d.dimensionId == 'logical_reasoning');
    final expectedBase =
        (dim.primaryEvidenceCount / req.targetPrimaryEvidence).clamp(0.0, 1.0);
    final expectedTotal =
        (dim.totalEvidenceCount / req.targetTotalEvidence).clamp(0.0, 1.0);
    final expectedSufficiency =
        (expectedBase < expectedTotal ? expectedBase : expectedTotal)
            .clamp(0.0, 1.0);
    final contextFactor =
        (dim.independentContextCount / req.minimumIndependentContexts)
            .clamp(0.0, 1.0);
    // Config targets for IQ logical are >3, so sufficiency != min(1, ev/3).
    expect(req.targetPrimaryEvidence, greaterThan(3));
    expect(dim.evidenceSufficiency, lessThan(1.0));
    expect(
      dim.evidenceSufficiency,
      closeTo(expectedSufficiency * contextFactor, 1e-9),
    );
    expect(dim.primaryEvidenceCount, isNot(dim.secondaryEvidenceCount));
  });

  test('incomplete evidence: no fabricated midpoint score', () {
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
            responseTimeMilliseconds: 4000,
          ),
        ],
      ),
    );
    expect(r.module.dimensionScores.containsKey('empathy'), isFalse);
    expect(
        r.module.missingDimensions.contains('empathy') ||
            r.module.insufficientDimensions.contains('empathy'),
        isTrue);
    final detail =
        r.module.dimensionDetails.firstWhere((d) => d.dimensionId == 'empathy');
    expect(detail.score, isNot(0.5));
    expect(detail.score, isNot(0.42));
    expect(detail.status, DimensionScoreStatus.insufficient);
  });

  test('repeated contexts reduce independence credit', () {
    final configLocal = config;
    final items = [
      for (var i = 1; i <= 4; i++)
        AssessmentItemDefinition(
          questionId: 'iso_$i',
          module: 'eq',
          schemaVersion: configLocal.questionSchemaVersion,
          contentVersion: 'x',
          itemType: 'scenario_mcq',
          primaryDimension: 'empathy',
          secondaryDimensions: const [],
          prompt: const {'tr': 'x', 'en': 'x'},
          options: [
            const AssessmentOptionDefinition(
              optionId: 'a',
              localizedText: {'tr': 'a', 'en': 'a'},
              dimensionDeltas: {'empathy': 0.5},
              evidenceStrength: 1.0,
              socialDesirabilityRisk: 'low',
              extremity: 0,
              responseStyleRisk: 'low',
              status: 'active',
            ),
          ],
          behavioralIsomorphGroup: 'same_context',
          exposureClass: 'core_pool',
          securityLevel: 'standard',
          estimatedCompletionSeconds: 20,
        ),
    ];
    final r = service.scoreModule(
      TraitScoringFixtureLoader.session(
        module: 'eq',
        config: config,
        items: items,
        responses: [
          for (final i in items)
            AssessmentResponse(
              questionId: i.questionId,
              selectedOptionId: 'a',
              responseTimeMilliseconds: 5000,
            ),
        ],
      ),
    );
    final emp =
        r.module.dimensionDetails.firstWhere((d) => d.dimensionId == 'empathy');
    expect(emp.independentContextCount, closeTo(1.0, 1e-9));
    // Diminishing weights: 1 + 0.5 + 0.25 + 0.125 = 1.875 < 4
    expect(emp.totalEvidenceCount, lessThan(4.0));
    expect(emp.failedEvidenceRules,
        contains('below_minimum_independent_contexts'));
  });
}
