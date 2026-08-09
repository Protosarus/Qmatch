import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/eq_pilot_review_candidate_1_helpers.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> items;

  setUpAll(() {
    form = EqPilotReviewCandidate1Loader.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
  });

  test('candidate form identity', () {
    expect(form['form_id'], 'eq_tr_pilot_v1_review_candidate_1');
    expect(form['content_version'], 'eq-tr-pilot-v1-review-candidate-1');
    expect(form['parent_content_version'], 'eq-tr-pilot-v1');
    expect(form['status'], 'internal_review');
    expect(form['review_state'], 'red_team_reviewed');
    expect(form['calibration_status'], 'uncalibrated');
    expect(items, hasLength(30));
    final notes = Map<String, dynamic>.from(form['notes'] as Map);
    expect(notes['internal_language_review'], 'completed');
    expect(notes['expert_language_review'], 'pending');
    expect(notes['reverse_rvi_service_gap'], isNotEmpty);
  });

  test('schema-v3 scenario_mcq fields', () {
    for (final j in items) {
      expect(j['schema_version'], 'qmatch_question_schema_v3');
      expect(j['module'], 'eq');
      expect(j['item_type'], 'scenario_mcq');
      expect(j['content_version'], 'eq-tr-pilot-v1-review-candidate-1');
      expect(j['options'], hasLength(4));
      expect(j.containsKey('correct_option_id'), isFalse);
      expect(j['calibration_status'], 'uncalibrated');
      for (final o in j['options'] as List) {
        final om = o as Map;
        expect(om.containsKey('evidence_strength'), isTrue);
        expect((om['evidence_strength'] as num).toDouble(), isNot(0.72));
      }
    }
  });

  test('primary allocation 3 per dimension', () {
    final counts = <String, int>{};
    for (final j in items) {
      final d = j['primary_dimension'] as String;
      counts[d] = (counts[d] ?? 0) + 1;
    }
    for (final d in [
      'empathy',
      'perspective_taking',
      'self_awareness',
      'emotion_regulation',
      'emotional_openness',
      'boundary_setting',
      'assertiveness',
      'conflict_approach',
      'repair_orientation',
      'social_awareness',
    ]) {
      expect(counts[d], 3, reason: d);
    }
  });

  test('not in pubspec', () {
    final pub = File('pubspec.yaml').readAsStringSync();
    expect(pub.contains('review_candidate_1'), isFalse);
    expect(pub.contains('eq_pilot_tr_v1_review_candidate'), isFalse);
  });
}
