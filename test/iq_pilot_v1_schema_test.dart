import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_dimension_profile.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> items;

  setUpAll(() {
    form = jsonDecode(
      File('assets/data/assessment_v3/iq/iq_pilot_tr_v1.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
  });

  test('pilot JSON parses with identity fields', () {
    expect(form['form_id'], 'iq_tr_pilot_v1');
    expect(form['set_id'], 'iq_tr_pilot_v1_set_001');
    expect(form['locale'], 'tr-TR');
    expect(form['content_version'], 'iq-tr-pilot-v1');
    expect(form['status'], 'pilot');
    expect(form['question_count'], 25);
    expect(items.length, 25);
  });

  test('schema-v3 item fields present', () {
    for (final j in items) {
      expect(j['schema_version'], 'qmatch_question_schema_v3');
      expect(j['module'], 'iq');
      expect(j['item_type'], 'mcq_keyed');
      expect(j['primary_dimension'], j['cognitive_domain']);
      expect(j['options'], hasLength(4));
      expect(
        (j['options'] as List).any(
          (o) => (o as Map)['option_id'] == j['correct_option_id'],
        ),
        isTrue,
      );
      expect(j['calibration_status'], 'uncalibrated');
      expect(j.containsKey('distractor_logic'), isTrue);
      expect(j.containsKey('solution_method'), isTrue);
    }
  });

  test('no retired aliases, persona, or grid IDs', () {
    final blob = jsonEncode(form).toLowerCase();
    for (final a in PersonaDimensionIds.forbiddenAliases) {
      expect(blob.contains('"$a"'), isFalse, reason: a);
    }
    for (final g in PersonaDimensionIds.forbiddenLegacyGridIds) {
      expect(RegExp('\\b$g\\b').hasMatch(blob), isFalse);
    }
    expect(blob.contains('persona_id'), isFalse);
    expect(blob.contains('uygulayici'), isFalse);
  });
}
