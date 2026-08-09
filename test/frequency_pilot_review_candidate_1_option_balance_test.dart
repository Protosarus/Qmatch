import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/frequency_pilot_review_candidate_1_helpers.dart';

void main() {
  late List<Map<String, dynamic>> items;
  late String report;

  setUpAll(() {
    final form = FrequencyPilotReviewCandidate1Loader.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
    report = File(
      '${FrequencyPilotReviewCandidate1Loader.repoRoot}/docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_option_balance_report.md',
    ).readAsStringSync();
  });

  test('options A-D with unique ids per item', () {
    for (final j in items) {
      final ids = (j['options'] as List)
          .map((o) => (o as Map)['option_id'] as String)
          .toList();
      expect(ids.toSet(), {'A', 'B', 'C', 'D'});
    }
  });

  test('option length ratio is at most 1.50 for every item', () {
    var maxRatio = 0.0;
    for (final j in items) {
      final lens = [
        for (final o in j['options'] as List)
          (((o as Map)['localized_text'] as Map)['tr'] as String).length,
      ]..sort();
      final ratio = lens.last / lens.first;
      if (ratio > maxRatio) maxRatio = ratio;
      expect(ratio, lessThanOrEqualTo(1.50), reason: j['question_id']);
    }
    expect(maxRatio, lessThanOrEqualTo(1.50));
  });

  test('option balance report documents candidate form', () {
    expect(report, contains('frequency_tr_pilot_v1_review_candidate_1'));
    expect(report, contains('max item ratio'));
  });
}
