import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'trait_scoring_fixture_loader.dart';

void main() {
  late TraitScoringConfig config;

  setUpAll(() {
    config = TraitScoringFixtureLoader.loadConfig();
  });

  test('valid IQ fixture parses', () {
    final items = TraitScoringFixtureLoader.loadBank(
      'valid_iq_bank.json',
      module: 'iq',
      config: config,
    );
    expect(items.length, 16);
  });

  test('valid EQ and Frequency fixtures parse', () {
    expect(
      TraitScoringFixtureLoader.loadBank(
        'valid_eq_bank.json',
        module: 'eq',
        config: config,
      ).length,
      40,
    );
    expect(
      TraitScoringFixtureLoader.loadBank(
        'valid_frequency_bank.json',
        module: 'frequency',
        config: config,
      ).length,
      24,
    );
  });

  test('retired aliases and EQ correct-answer fields fail explicitly', () {
    final text = File(
      '${Directory.current.path}/test/fixtures/trait_scoring/invalid_schema_bank.json',
    ).readAsStringSync();
    final j = jsonDecode(text) as Map<String, dynamic>;
    expect(
      () => TraitScoringParser.parseItemBank(
        j['items'] as List<dynamic>,
        expectedModule: 'eq',
        source: 'invalid_schema_bank.json',
        config: config,
      ),
      throwsA(
        isA<TraitScoringValidationException>().having(
          (e) => e.errors.map((x) => x.reasonCode).toSet(),
          'codes',
          containsAll([
            'unknown_dimension',
            'eq_frequency_correct_forbidden',
          ]),
        ),
      ),
    );
  });

  test('persona IDs in option evidence fail', () {
    final items = [
      {
        'question_id': 'p1',
        'module': 'eq',
        'schema_version': 'qmatch_question_schema_v3',
        'content_version': 'x',
        'item_type': 'scenario_mcq',
        'primary_dimension': 'empathy',
        'secondary_dimensions': <String>[],
        'prompt': {'tr': 'x', 'en': 'x'},
        'options': [
          {
            'option_id': 'a',
            'localized_text': {'tr': 'a', 'en': 'a'},
            'dimension_deltas': {'empathy': 0.2},
            'persona_id': 'empat',
            'evidence_strength': 1.0,
          }
        ],
        'exposure_class': 'core_pool',
        'security_level': 'standard',
        'estimated_completion_seconds': 10,
      }
    ];
    expect(
      () => TraitScoringParser.parseItemBank(
        items,
        expectedModule: 'eq',
        config: config,
      ),
      throwsA(isA<TraitScoringValidationException>()),
    );
  });

  test('delta outside [-1,1] fails', () {
    expect(
      () => TraitScoringParser.parseItemBank(
        [
          {
            'question_id': 'd1',
            'module': 'eq',
            'schema_version': 'qmatch_question_schema_v3',
            'content_version': 'x',
            'item_type': 'scenario_mcq',
            'primary_dimension': 'empathy',
            'secondary_dimensions': <String>[],
            'prompt': {'tr': 'x', 'en': 'x'},
            'options': [
              {
                'option_id': 'a',
                'localized_text': {'tr': 'a', 'en': 'a'},
                'dimension_deltas': {'empathy': 1.2},
                'evidence_strength': 1.0,
              }
            ],
            'exposure_class': 'core_pool',
            'security_level': 'standard',
            'estimated_completion_seconds': 10,
          }
        ],
        expectedModule: 'eq',
        config: config,
      ),
      throwsA(isA<TraitScoringValidationException>()),
    );
  });
}
