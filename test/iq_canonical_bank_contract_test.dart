import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';

const _iqDir = 'assets/data/assessment_v3/iq';
const _pilotPath = '$_iqDir/iq_pilot_tr_v1.json';
const _schemaPath = '$_iqDir/iq_item_schema_v1.json';
const _targetBankPath = '$_iqDir/iq_bank_tr_v1.json';

Map<String, dynamic> _validItem({
  String id = 'iq_logical_demo_001',
  String dimension = IqCanonicalDimensions.logicalReasoning,
  String subskill = 'conditional_inference',
  String prompt = 'Kural: A ise B. B dogru. Hangisi kesin?',
  String status = 'draft',
  String correct = 'A',
}) {
  return {
    'id': id,
    'schema_version': IqBankContract.schemaVersion,
    'bank_version': 'iq_bank_tr_v1_draft',
    'locale': 'tr-TR',
    'dimension': dimension,
    'subskill': subskill,
    'prompt': prompt,
    'options': [
      {'id': 'A', 'text': 'Zorunlu degil'},
      {'id': 'B', 'text': 'A dogrudur'},
      {'id': 'C', 'text': 'A yanlistir'},
      {'id': 'D', 'text': 'B yanlistir'},
    ],
    'correct_option_id': correct,
    'rationale': 'Sartli onermede sonucun dogrulugu onculu zorunlu kilmaz.',
    'difficulty_band': 'medium',
    'estimated_time_seconds': 45,
    'language_dependency': 'medium',
    'cognitive_load': 'medium',
    'answer_order_policy': 'shuffle_allowed',
    'status': status,
    'source': 'unit_test',
    'review_state': 'unreviewed',
    'tags': <String>['unit'],
  };
}

void main() {
  test('canonical four-dimension acceptance', () {
    expect(IqCanonicalDimensions.all.length, 4);
    for (final d in IqCanonicalDimensions.all) {
      expect(IqCanonicalDimensions.isCanonical(d), isTrue);
    }
  });

  test('retired numerical rejection', () {
    final item =
        _validItem(dimension: 'numerical', subskill: 'numeric_sequence');
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'retired_dimension'),
      isTrue,
    );
  });

  test('unsupported dimension rejection', () {
    final item =
        _validItem(dimension: 'memory_span', subskill: 'conditional_inference');
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'unsupported_dimension'),
      isTrue,
    );
  });

  test('valid item schema', () {
    final report = IqItemValidator.validateItems([_validItem()]);
    expect(report.hasErrors, isFalse);
  });

  test('missing required field', () {
    final item = _validItem()..remove('rationale');
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'missing_required_field'),
      isTrue,
    );
  });

  test('duplicate item ID', () {
    final report = IqItemValidator.validateItems([
      _validItem(id: 'iq_dup_001'),
      _validItem(id: 'iq_dup_001', prompt: 'Farkli prompt ama ayni id'),
    ]);
    expect(
      report.errors.any((e) => e.code == 'duplicate_item_id'),
      isTrue,
    );
  });

  test('duplicate option ID', () {
    final item = _validItem();
    item['options'] = [
      {'id': 'A', 'text': 'bir'},
      {'id': 'A', 'text': 'iki'},
      {'id': 'C', 'text': 'uc'},
      {'id': 'D', 'text': 'dort'},
    ];
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'duplicate_option_id'),
      isTrue,
    );
  });

  test('missing correct option', () {
    final item = _validItem(correct: 'A');
    item['correct_option_id'] = 'Z';
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'missing_correct_option'),
      isTrue,
    );
  });

  test('repeated option text', () {
    final item = _validItem();
    item['options'] = [
      {'id': 'A', 'text': 'Ayni'},
      {'id': 'B', 'text': 'Ayni'},
      {'id': 'C', 'text': 'Farkli'},
      {'id': 'D', 'text': 'Baska'},
    ];
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'repeated_option_text'),
      isTrue,
    );
  });

  test('duplicate normalized prompt', () {
    final report = IqItemValidator.validateItems([
      _validItem(id: 'iq_p_001', prompt: 'Ayni  prompt'),
      _validItem(id: 'iq_p_002', prompt: 'Ayni   prompt'),
    ]);
    expect(
      report.errors.any((e) => e.code == 'duplicate_normalized_prompt'),
      isTrue,
    );
  });

  test('invalid difficulty', () {
    final item = _validItem();
    item['difficulty_band'] = 'legendary';
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'invalid_difficulty'),
      isTrue,
    );
  });

  test('invalid locale', () {
    final item = _validItem();
    item['locale'] = 'en-US';
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'invalid_locale'),
      isTrue,
    );
  });

  test('empty rationale', () {
    final item = _validItem();
    item['rationale'] = '   ';
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'empty_rationale'),
      isTrue,
    );
  });

  test('control character rejection', () {
    final item = _validItem(prompt: 'Kotu\u0001prompt burasi yeterince uzun');
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'control_characters'),
      isTrue,
    );
  });

  test('multiple correct-answer representation impossible / rejected', () {
    final item = _validItem();
    item['correct_option_ids'] = ['A', 'B'];
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'multiple_correct_representation'),
      isTrue,
    );
  });

  test('pilot count and 7/6/6/6 distribution', () {
    final form = jsonDecode(
      File(_pilotPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final report = IqItemValidator.validatePilotForm(form);
    expect(report.itemCount, IqBankContract.pilotItems);
    expect(report.hasErrors, isFalse);
    expect(report.dimensionCounts['logical_reasoning'], 7);
    expect(report.dimensionCounts['pattern_reasoning'], 6);
    expect(report.dimensionCounts['verbal_reasoning'], 6);
    expect(report.dimensionCounts['spatial_reasoning'], 6);
  });

  test('bank target 340 with verified recovered distribution', () {
    expect(IqBankContract.targetUniqueItems, 340);
    final recoveredSum = IqBankContract.recoveredDimensionDistribution.values
        .fold<int>(0, (a, b) => a + b);
    expect(recoveredSum, 340);
    expect(IqBankContract.recoveredDimensionDistribution['logical_reasoning'],
        100);
    expect(
        IqBankContract.recoveredDimensionDistribution['pattern_reasoning'], 80);
    expect(
        IqBankContract.recoveredDimensionDistribution['verbal_reasoning'], 80);
    expect(
        IqBankContract.recoveredDimensionDistribution['spatial_reasoning'], 80);
    // Historical equal-split placeholder retained only as deprecated constant.
    expect(IqBankContract.targetPerDimension, 85);
  });

  test('legacy source is not silently canonical', () {
    final legacy = File('assets/data/assessment_sets/iq_sets.json');
    expect(legacy.existsSync(), isTrue);
    final data = jsonDecode(legacy.readAsStringSync()) as Map;
    final first = (((data['sets'] as List).first as Map)['questions'] as List)
        .first as Map;
    expect(first.containsKey('primary_dimension'), isFalse);
    expect(first.containsKey('dimension'), isFalse);
    expect(first.containsKey('schema_version'), isFalse);
  });

  test('candidate status is not runtime eligible', () {
    final item = _validItem(status: 'draft');
    final report = IqItemValidator.validateItems(
      [item],
      treatCandidateAsRuntime: true,
    );
    expect(
      report.errors.any((e) => e.code == 'candidate_not_runtime_eligible'),
      isTrue,
    );
    expect(IqBankContract.isRuntimeEligibleStatus('draft'), isFalse);
  });

  test('editorial difficulty is not treated as calibrated', () {
    expect(IqBankContract.treatsDifficultyAsCalibrated, isFalse);
    final report = IqItemValidator.validateItems([_validItem()]);
    expect(report.toJson()['difficulty_is_calibrated'], isFalse);
  });

  test('source inventory reports runtime reachability', () {
    final inv = File(
      'docs/assessment/qmatch_iq_source_inventory_v1.md',
    ).readAsStringSync();
    expect(inv.contains('Production reachable'), isTrue);
    expect(inv.contains('legacy_runtime'), isTrue);
    expect(inv.contains('FOUND_RECOVERABLE'), isTrue);
    expect(inv.contains('IMPLEMENTED_OFFLINE'), isTrue);
  });

  test('recovered 340 bank exists offline and is not runtime-wired', () {
    expect(File(_targetBankPath).existsSync(), isTrue);
    final inv = File(
      'docs/assessment/qmatch_iq_source_inventory_v1.md',
    ).readAsStringSync();
    expect(inv.contains('IMPLEMENTED_OFFLINE'), isTrue);
    expect(inv.contains('NOT_STARTED'), isTrue);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('iq_bank_tr_v1.json'), isFalse);
  });

  test('no quantum field appears in canonical IQ item schema', () {
    final schema = jsonDecode(File(_schemaPath).readAsStringSync())
        as Map<String, dynamic>;
    final props = schema['properties'] as Map<String, dynamic>;
    expect(props.containsKey('quantum_score'), isFalse);
    expect(props.containsKey('quantum_amplitude'), isFalse);
    final item = _validItem();
    item['quantum_score'] = 0.5;
    final report = IqItemValidator.validateItems([item]);
    expect(
      report.errors.any((e) => e.code == 'forbidden_field'),
      isTrue,
    );
  });

  test(
      'current runtime IQ loader path remains legacy (unchanged by this phase)',
      () {
    final screen = File('lib/features/assessment/screens/iq_test_screen.dart')
        .readAsStringSync();
    final service =
        File('lib/features/assessment/services/question_service.dart')
            .readAsStringSync();
    expect(screen.contains('loadIQAssessment'), isTrue);
    expect(service.contains('loadIQAssessment'), isTrue);
    expect(service.contains('iq_bank_tr_v1'), isFalse);
    expect(service.contains('assessment_v3/iq'), isFalse);
  });

  test('subskill registry covers all four dimensions', () {
    for (final d in IqCanonicalDimensions.all) {
      expect(IqSubskillRegistry.byDimension[d], isNotEmpty);
    }
  });
}
