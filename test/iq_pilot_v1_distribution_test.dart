import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Map<String, dynamic>> items;

  setUpAll(() {
    final form = jsonDecode(
      File('assets/data/assessment_v3/iq/iq_pilot_tr_v1.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
  });

  test('domain allocation 7/6/6/6', () {
    int c(String d) => items.where((i) => i['primary_dimension'] == d).length;
    expect(c('logical_reasoning'), 7);
    expect(c('pattern_reasoning'), 6);
    expect(c('verbal_reasoning'), 6);
    expect(c('spatial_reasoning'), 6);
  });

  test('difficulty allocation 8/12/5 via 2/3/4', () {
    int c(int d) => items.where((i) => i['difficulty'] == d).length;
    expect(c(2), 8);
    expect(c(3), 12);
    expect(c(4), 5);
  });

  test('answer positions balanced and run<=2', () {
    final counts = <String, int>{};
    final seq = <String>[];
    for (final i in items) {
      final k = i['correct_option_id'] as String;
      counts[k] = (counts[k] ?? 0) + 1;
      seq.add(k);
    }
    expect(counts['A'], anyOf(6, 7));
    expect(counts['B'], anyOf(6, 7));
    expect(counts['C'], anyOf(6, 7));
    expect(counts['D'], anyOf(6, 7));
    expect(counts.values.fold<int>(0, (a, b) => a + b), 25);
    var run = 1;
    var maxRun = 1;
    for (var i = 1; i < seq.length; i++) {
      if (seq[i] == seq[i - 1]) {
        run++;
        maxRun = maxRun > run ? maxRun : run;
      } else {
        run = 1;
      }
    }
    expect(maxRun, lessThanOrEqualTo(2));
  });

  test('four anchors, one per domain', () {
    final anchors = items.where((i) => i['anchor_group'] != null).toList();
    expect(anchors, hasLength(4));
    expect(
      anchors.map((a) => a['primary_dimension']).toSet(),
      {
        'logical_reasoning',
        'pattern_reasoning',
        'verbal_reasoning',
        'spatial_reasoning',
      },
    );
    for (final a in anchors) {
      expect(a['exposure_class'], 'anchor');
      expect(a['difficulty'], 3);
    }
  });
}
