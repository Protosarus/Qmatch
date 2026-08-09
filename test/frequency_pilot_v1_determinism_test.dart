import 'dart:convert';
import 'dart:io';

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

  test('same input produces identical scores', () {
    final responses = FrequencyPilotV1Loader.randomSeeded(items, seed: 11);
    final a = service.scoreModule(
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: responses,
      ),
    );
    final b = service.scoreModule(
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: responses,
      ),
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
  });

  test('JSON map ordering does not change scoring', () {
    final form = FrequencyPilotV1Loader.loadForm();
    final reversedItems = (form['items'] as List).reversed.toList();
    final parsed = TraitScoringParser.parseItemBank(
      reversedItems,
      expectedModule: 'frequency',
      config: config,
    );
    final responses = FrequencyPilotV1Loader.sortResponses(
      FrequencyPilotV1Loader.balancedMixed(parsed),
    );
    final a = service.scoreModule(
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: FrequencyPilotV1Loader.sortResponses(
          FrequencyPilotV1Loader.balancedMixed(items),
        ),
      ),
    );
    final b = service.scoreModule(
      FrequencyPilotV1Loader.session(
        config: config,
        items: parsed,
        responses: responses,
      ),
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
  });

  test('shuffled question order is score-deterministic', () {
    final responses = FrequencyPilotV1Loader.sortResponses(
      FrequencyPilotV1Loader.balancedMixed(items),
    );
    final shuffledItems = List<AssessmentItemDefinition>.of(items.reversed);
    final a = service.scoreModule(
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: responses,
      ),
    );
    final b = service.scoreModule(
      FrequencyPilotV1Loader.session(
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
          ['run', 'tool/validate_frequency_pilot_v1.dart'],
          workingDirectory: Directory.current.path,
        );
    final r1 = run();
    expect(r1.exitCode, 0, reason: r1.stderr.toString());
    final j1 = jsonDecode(
      File('tool/frequency_pilot_out/validate_frequency_pilot_v1_report.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final r2 = run();
    expect(r2.exitCode, 0, reason: r2.stderr.toString());
    final j2 = jsonDecode(
      File('tool/frequency_pilot_out/validate_frequency_pilot_v1_report.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(j1['findings'], j2['findings']);
    expect(j1['automated_validation'], isIn(['PASS', 'CONDITIONAL']));
    expect(j1['fingerprint'] ?? j1['error_count'], isNotNull);
  });
}
