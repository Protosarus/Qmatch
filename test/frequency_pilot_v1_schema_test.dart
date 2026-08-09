import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_dimension_profile.dart';

import 'support/frequency_pilot_v1_helpers.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> items;

  setUpAll(() {
    form = FrequencyPilotV1Loader.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
  });

  test('pilot JSON parses with identity fields', () {
    expect(form['form_id'], 'frequency_tr_pilot_v1');
    expect(form['set_id'], 'frequency_tr_pilot_v1_set_001');
    expect(form['module'], 'frequency');
    expect(form['locale'], 'tr-TR');
    expect(form['content_version'], 'frequency-tr-pilot-v1');
    expect(form['status'], 'pilot');
    expect(form['review_state'], 'internal_review');
    expect(form['calibration_status'], 'uncalibrated');
    expect(form['question_count'], 50);
    expect(items.length, 50);
  });

  test('schema-v3 item fields present for scenario_mcq', () {
    final idPattern = RegExp(r'^frequency_tr_v1_[a-z_]+_\d{3}$');
    for (final j in items) {
      expect(j['schema_version'], 'qmatch_question_schema_v3');
      expect(j['module'], 'frequency');
      expect(j['item_type'], 'scenario_mcq');
      expect(j['content_version'], form['content_version']);
      expect(j['review_state'], 'internal_review');
      expect(j['options'], hasLength(4));
      expect(idPattern.hasMatch(j['question_id'] as String), isTrue);
      expect(j['calibration_status'], 'uncalibrated');
      expect(j.containsKey('response_validity_roles'), isTrue);
      expect(j.containsKey('authoring_notes'), isTrue);
    }
  });

  test('no correct-answer, persona, grid, or frequency type leakage', () {
    final blob = jsonEncode(form).toLowerCase();
    expect(blob.contains('correct_option_id'), isFalse);
    expect(blob.contains('correctanswer'), isFalse);
    expect(blob.contains('persona_id'), isFalse);
    expect(blob.contains('persona_points'), isFalse);
    for (final a in PersonaDimensionIds.forbiddenAliases) {
      expect(blob.contains('"$a"'), isFalse, reason: a);
    }
    for (final g in PersonaDimensionIds.forbiddenLegacyGridIds) {
      expect(RegExp('\\b$g\\b').hasMatch(blob), isFalse);
    }
    for (final f in PersonaDimensionIds.forbiddenFrequencyTypes) {
      expect(blob.contains(f.toLowerCase()), isFalse, reason: f);
    }
  });

  test('primary dimensions are canonical Frequency only', () {
    for (final j in items) {
      expect(PersonaDimensionIds.frequency, contains(j['primary_dimension']));
      for (final s in j['secondary_dimensions'] as List) {
        expect(PersonaDimensionIds.frequency, contains(s));
      }
    }
  });

  test('question ids are unique', () {
    final ids = items.map((j) => j['question_id'] as String).toList();
    expect(ids.toSet().length, ids.length);
  });
}
