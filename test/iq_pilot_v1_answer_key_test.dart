import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every item has correct option and distractor logic for wrongs', () {
    final form = jsonDecode(
      File('assets/data/assessment_v3/iq/iq_pilot_tr_v1.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final raw in form['items'] as List) {
      final j = Map<String, dynamic>.from(raw as Map);
      final opts = {
        for (final o in j['options'] as List) (o as Map)['option_id']: o,
      };
      final correct = j['correct_option_id'];
      expect(opts.containsKey(correct), isTrue, reason: j['question_id']);
      final dl = Map<String, dynamic>.from(j['distractor_logic'] as Map);
      for (final oid in opts.keys) {
        if (oid == correct) continue;
        expect(dl.containsKey(oid), isTrue, reason: '${j['question_id']} $oid');
      }
      expect((j['solution_method'] as String).length, greaterThan(20));
    }
  });

  test('answer review document exists and covers all IDs', () {
    final review = File(
      'docs/core_engine/iq_pilot_tr_v1_answer_and_solution_review.md',
    ).readAsStringSync();
    final form = jsonDecode(
      File('assets/data/assessment_v3/iq/iq_pilot_tr_v1.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final raw in form['items'] as List) {
      final id = (raw as Map)['question_id'];
      expect(review.contains(id as String), isTrue);
    }
  });
}
