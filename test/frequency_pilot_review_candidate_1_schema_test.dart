import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/frequency_pilot_review_candidate_1_helpers.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> items;

  setUpAll(() {
    form = FrequencyPilotReviewCandidate1Loader.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
  });

  test('candidate form identity', () {
    expect(form['form_id'], 'frequency_tr_pilot_v1_review_candidate_1');
    expect(form['content_version'], 'frequency-tr-pilot-v1-review-candidate-1');
    expect(form['parent_content_version'], 'frequency-tr-pilot-v1');
    expect(form['status'], 'internal_review');
    expect(form['review_state'], 'red_team_reviewed');
    expect(form['calibration_status'], 'uncalibrated');
    expect(items, hasLength(50));
    final notes = Map<String, dynamic>.from(form['notes'] as Map);
    expect(notes['internal_language_review'], 'completed');
    expect(notes['expert_language_review'], 'pending');
    expect(notes['reverse_pair_rvi_service_compatibility'], 'PASS');
  });

  test('schema-v3 scenario_mcq fields', () {
    for (final j in items) {
      expect(j['schema_version'], 'qmatch_question_schema_v3');
      expect(j['module'], 'frequency');
      expect(j['item_type'], 'scenario_mcq');
      expect(j['content_version'], 'frequency-tr-pilot-v1-review-candidate-1');
      expect(j['options'], hasLength(4));
      expect(j.containsKey('correct_option_id'), isFalse);
      expect(j['calibration_status'], 'uncalibrated');
      expect(j['authoring_notes'], contains('red_team=candidate_1'));
      for (final o in j['options'] as List) {
        final om = o as Map;
        expect(om.containsKey('evidence_strength'), isTrue);
        expect((om['evidence_strength'] as num).toDouble(), isNot(0.72));
      }
    }
  });

  test('primary allocation matches parent pilot', () {
    final counts = <String, int>{};
    for (final j in items) {
      final d = j['primary_dimension'] as String;
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final parentAlloc = Map<String, dynamic>.from(
      FrequencyPilotReviewCandidate1Loader.loadParent()[
          'primary_dimension_allocation'] as Map,
    );
    for (final d in PersonaDimensionIds.frequency) {
      expect(counts[d], parentAlloc[d], reason: d);
    }
  });

  test('not in pubspec', () {
    final pub = File('pubspec.yaml').readAsStringSync();
    expect(pub.contains('frequency_pilot_tr_v1_review_candidate_1'), isFalse);
  });
}
