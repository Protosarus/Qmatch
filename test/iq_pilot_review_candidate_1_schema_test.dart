import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_dimension_profile.dart';

import 'support/iq_pilot_review_candidate_1_helpers.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> items;
  late String redTeam;
  late String changelog;
  late String solutions;

  setUpAll(() {
    form = IqPilotReviewCandidate1Helpers.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
    redTeam = File('docs/core_engine/iq_pilot_tr_v1_red_team_review.md')
        .readAsStringSync();
    changelog = File(
      'docs/core_engine/iq_pilot_tr_v1_review_candidate_1_changelog.md',
    ).readAsStringSync();
    solutions = File(
      'docs/core_engine/iq_pilot_tr_v1_review_candidate_1_solutions.md',
    ).readAsStringSync();
  });

  test('candidate form parses with review identity', () {
    expect(form['form_id'], 'iq_tr_pilot_v1_review_candidate_1');
    expect(form['content_version'], 'iq-tr-pilot-v1-review-candidate-1');
    expect(form['parent_content_version'], 'iq-tr-pilot-v1');
    expect(form['status'], 'internal_review');
    expect(form['calibration_status'], 'uncalibrated');
    expect(form['question_count'], 25);
    expect(items, hasLength(25));
    final notes = Map<String, dynamic>.from(form['notes'] as Map);
    expect(notes['internal_language_review'], 'completed');
    expect(notes['expert_language_review'], 'pending');
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
      expect((j['distractor_logic'] as Map).isNotEmpty, isTrue);
      expect((j['solution_method'] as String).length, greaterThan(20));
    }
  });

  test('red-team matrix covers all original v1 IDs; no UNRESOLVED', () {
    final parent = jsonDecode(
      File('assets/data/assessment_v3/iq/iq_pilot_tr_v1.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final raw in parent['items'] as List) {
      final id = (raw as Map)['question_id'] as String;
      expect(redTeam.contains(id), isTrue, reason: id);
    }
    expect(redTeam.contains('| UNRESOLVED | 0 |'), isTrue);
    expect(
        RegExp(r'Semantic:\s*\*\*UNRESOLVED\*\*').hasMatch(redTeam), isFalse);
  });

  test('solutions cover every candidate item ID', () {
    for (final j in items) {
      final id = j['question_id'] as String;
      expect(solutions.contains(id), isTrue, reason: id);
    }
  });

  test('material revision ID policy', () {
    final ids = {for (final j in items) j['question_id'] as String};
    expect(ids.contains('iq_tr_v1_spatial_003'), isFalse);
    expect(ids.contains('iq_tr_v1_pattern_006'), isFalse);
    expect(ids.contains('iq_tr_v1_spatial_007'), isTrue);
    expect(ids.contains('iq_tr_v1_pattern_007'), isTrue);
    expect(changelog.contains('iq_tr_v1_spatial_007'), isTrue);
    expect(changelog.contains('iq_tr_v1_pattern_007'), isTrue);
    expect(changelog.contains('item_replacement'), isTrue);
    expect(changelog.contains('semantic_rewrite'), isTrue);
  });

  test('changelog covers known changed items', () {
    for (final token in [
      'iq_tr_v1_logical_005',
      'iq_tr_v1_logical_007',
      'iq_tr_v1_pattern_006',
      'iq_tr_v1_pattern_007',
      'iq_tr_v1_verbal_002',
      'iq_tr_v1_verbal_004',
      'iq_tr_v1_spatial_005',
      'iq_tr_v1_spatial_003',
      'iq_tr_v1_spatial_007',
    ]) {
      expect(changelog.contains(token), isTrue, reason: token);
    }
  });

  test('domain and reviewed difficulty allocation', () {
    final domains = <String, int>{};
    final diffs = <int, int>{};
    for (final j in items) {
      final d = j['primary_dimension'] as String;
      domains[d] = (domains[d] ?? 0) + 1;
      final diff = (j['difficulty'] as num).toInt();
      diffs[diff] = (diffs[diff] ?? 0) + 1;
    }
    expect(domains['logical_reasoning'], 7);
    expect(domains['pattern_reasoning'], 6);
    expect(domains['verbal_reasoning'], 6);
    expect(domains['spatial_reasoning'], 6);
    expect(diffs[2], 9);
    expect(diffs[3], 12);
    expect(diffs[4], 4);
    final reviewed = Map<String, dynamic>.from(
        form['reviewed_difficulty_allocation'] as Map);
    expect(reviewed['easy'], 9);
    expect(reviewed['medium'], 12);
    expect(reviewed['hard'], 4);
  });

  test('answer-position balance and anchors', () {
    final counts = <String, int>{};
    for (final j in items) {
      final c = j['correct_option_id'] as String;
      counts[c] = (counts[c] ?? 0) + 1;
    }
    for (final letter in ['A', 'B', 'C', 'D']) {
      expect(counts[letter], anyOf(6, 7));
    }
    expect(counts.values.reduce((a, b) => a + b), 25);
    final anchors = [
      for (final j in items)
        if (j['anchor_group'] != null) j,
    ];
    expect(anchors, hasLength(4));
    final anchorDomains = {
      for (final j in anchors) j['primary_dimension'] as String,
    };
    expect(anchorDomains, containsAll(PersonaDimensionIds.iq));
  });

  test('no high construct contamination retained in candidate notes', () {
    final blob = jsonEncode(form).toLowerCase();
    expect(blob.contains('contamination: high'), isFalse);
    expect(blob.contains('construct contamination: high'), isFalse);
  });

  test('original v1 pilot file still present and distinct', () {
    final v1 = File('assets/data/assessment_v3/iq/iq_pilot_tr_v1.json');
    expect(v1.existsSync(), isTrue);
    final parent = jsonDecode(v1.readAsStringSync()) as Map<String, dynamic>;
    expect(parent['content_version'], 'iq-tr-pilot-v1');
    expect(parent['status'], 'pilot');
  });
}
