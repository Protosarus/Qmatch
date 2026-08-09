import 'dart:convert';
import 'dart:io';

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

  test('same input produces identical scores', () {
    final responses = IqPilotV1Loader.randomSeeded(items, seed: 7);
    final a = service.scoreModule(
      IqPilotV1Loader.session(
        config: config,
        items: items,
        responses: responses,
      ),
    );
    final b = service.scoreModule(
      IqPilotV1Loader.session(
        config: config,
        items: items,
        responses: responses,
      ),
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
    expect(a.module.legacyRawScore, b.module.legacyRawScore);
  });

  test('JSON map ordering does not change scoring', () {
    final form = IqPilotV1Loader.loadForm();
    final reversedItems = (form['items'] as List).reversed.toList();
    final parsed = TraitScoringParser.parseItemBank(
      reversedItems,
      expectedModule: 'iq',
      config: config,
    );
    final responses = IqPilotV1Loader.allCorrect(parsed);
    final a = service.scoreModule(
      IqPilotV1Loader.session(
        config: config,
        items: items,
        responses: IqPilotV1Loader.allCorrect(items),
      ),
    );
    final b = service.scoreModule(
      IqPilotV1Loader.session(
        config: config,
        items: parsed,
        responses: responses.reversed.toList(),
      ),
    );
    expect(a.module.dimensionScores, b.module.dimensionScores);
  });

  test('near-duplicate report from validator is deterministic', () {
    ProcessResult run() => Process.runSync(
          'dart',
          ['run', 'tool/validate_iq_pilot_v1.dart'],
          workingDirectory: Directory.current.path,
        );
    final r1 = run();
    expect(r1.exitCode, 0, reason: r1.stderr.toString());
    final j1 = jsonDecode(
      File('tool/iq_pilot_out/validate_iq_pilot_v1_report.json')
          .readAsStringSync(),
    );
    final r2 = run();
    expect(r2.exitCode, 0, reason: r2.stderr.toString());
    final j2 = jsonDecode(
      File('tool/iq_pilot_out/validate_iq_pilot_v1_report.json')
          .readAsStringSync(),
    );
    expect(j1['near_duplicates'], j2['near_duplicates']);
    expect(j1['correct_option_sequence'], j2['correct_option_sequence']);
    expect(j1['automated_validation'], 'PASS');
  });
}
