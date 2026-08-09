import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/frequency_pilot_review_candidate_1_helpers.dart';

void main() {
  late TraitScoringConfig config;
  late TraitScoringService service;
  late List<AssessmentItemDefinition> items;

  setUpAll(() {
    config = FrequencyPilotReviewCandidate1Loader.loadConfig();
    service = TraitScoringService(config: config);
    items = FrequencyPilotReviewCandidate1Loader.loadItems(config);
  });

  test('same input produces identical scores', () {
    final responses =
        FrequencyPilotReviewCandidate1Loader.randomSeeded(items, seed: 11);
    final a = service.scoreModule(
      FrequencyPilotReviewCandidate1Loader.session(
        config: config,
        items: items,
        responses: responses,
      ),
    );
    final b = service.scoreModule(
      FrequencyPilotReviewCandidate1Loader.session(
        config: config,
        items: items,
        responses: responses,
      ),
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
  });

  test('shuffled question order is score-deterministic', () {
    final responses = FrequencyPilotReviewCandidate1Loader.sortResponses(
      FrequencyPilotReviewCandidate1Loader.balancedMixed(items),
    );
    final shuffledItems = List<AssessmentItemDefinition>.of(items.reversed);
    final a = service.scoreModule(
      FrequencyPilotReviewCandidate1Loader.session(
        config: config,
        items: items,
        responses: responses,
      ),
    );
    final b = service.scoreModule(
      FrequencyPilotReviewCandidate1Loader.session(
        config: config,
        items: shuffledItems,
        responses: responses,
      ),
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
  });

  test('validator report is deterministic across two runs', () {
    ProcessResult run() => Process.runSync(
          'dart',
          ['run', 'tool/validate_frequency_pilot_review_candidate_1.dart'],
          workingDirectory: Directory.current.path,
        );
    final r1 = run();
    expect(r1.exitCode, 0, reason: r1.stderr.toString());
    final j1 = jsonDecode(
      File(
        'tool/frequency_pilot_out/validate_frequency_pilot_review_candidate_1_report.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final r2 = run();
    expect(r2.exitCode, 0, reason: r2.stderr.toString());
    final j2 = jsonDecode(
      File(
        'tool/frequency_pilot_out/validate_frequency_pilot_review_candidate_1_report.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(j1['findings'], j2['findings']);
    expect(j1['automated_validation'], 'PASS');
    expect(j1['overall_readiness'], 'CONDITIONAL');
    expect(j1['reverse_pair_service_compatibility'], 'PASS');
  });
}
