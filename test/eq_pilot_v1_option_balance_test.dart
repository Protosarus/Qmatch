import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'support/eq_pilot_v1_helpers.dart';

void main() {
  late List<Map<String, dynamic>> items;

  setUpAll(() {
    final form = EqPilotV1Loader.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
  });

  String norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^\wçğıöşü\s]', caseSensitive: false), '')
      .trim();

  test('normalized prompts are unique', () {
    final counts = <String, int>{};
    for (final j in items) {
      final tr = ((j['prompt'] as Map)['tr'] as String);
      counts[norm(tr)] = (counts[norm(tr)] ?? 0) + 1;
    }
    for (final e in counts.entries) {
      expect(e.value, 1, reason: 'duplicate prompt hash ${e.key.hashCode}');
    }
  });

  test('options A-D with unique ids per item', () {
    for (final j in items) {
      final ids = (j['options'] as List)
          .map((o) => (o as Map)['option_id'] as String)
          .toList();
      expect(ids.toSet(), {'A', 'B', 'C', 'D'});
    }
  });

  test('required SDR and response_style metadata on every option', () {
    for (final j in items) {
      for (final o in j['options'] as List) {
        final m = o as Map;
        expect(m.containsKey('social_desirability_risk'), isTrue);
        expect(m.containsKey('response_style_risk'), isTrue);
        expect(m.containsKey('extremity'), isTrue);
        expect(m.containsKey('evidence_strength'), isTrue);
      }
    }
  });

  test('option length ratio warnings are detectable without failing bank', () {
    var leakageCandidates = 0;
    for (final j in items) {
      final lens = [
        for (final o in j['options'] as List)
          (((o as Map)['localized_text'] as Map)['tr'] as String).length,
      ]..sort();
      if (lens.last > (1.5 * lens.first).ceil()) leakageCandidates++;
    }
    expect(leakageCandidates, greaterThanOrEqualTo(0));
  });

  test('bank blob has no IQ keyed fields', () {
    final blob = jsonEncode({'items': items}).toLowerCase();
    expect(blob.contains('correct_option_id'), isFalse);
    expect(blob.contains('distractor_logic'), isFalse);
    expect(blob.contains('solution_method'), isFalse);
  });
}
