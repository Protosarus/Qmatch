import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/eq_pilot_review_candidate_1_helpers.dart';

void main() {
  late List<String> bankIds;
  late String redTeam;
  late String changelog;
  late Map<String, dynamic> parent;

  setUpAll(() {
    final form = EqPilotReviewCandidate1Loader.loadForm();
    bankIds = [
      for (final i in form['items'] as List)
        (i as Map)['question_id'] as String,
    ];
    final root = EqPilotReviewCandidate1Loader.repoRoot;
    redTeam = File(
      '$root/docs/core_engine/eq_pilot_tr_v1_red_team_review.md',
    ).readAsStringSync();
    changelog = File(
      '$root/docs/core_engine/eq_pilot_tr_v1_review_candidate_1_changelog.md',
    ).readAsStringSync();
    parent = EqPilotReviewCandidate1Loader.loadParent();
  });

  test('parent v1 remains unchanged identity', () {
    expect(parent['content_version'], 'eq-tr-pilot-v1');
    expect(parent['form_id'], 'eq_tr_pilot_v1');
    expect((parent['items'] as List), hasLength(30));
  });

  test('red-team matrix covers all 30 IDs', () {
    for (final id in bankIds) {
      expect(redTeam.contains('`$id`'), isTrue, reason: id);
    }
    expect(redTeam.contains('| UNRESOLVED | 0 |'), isTrue);
  });

  test('changelog covers all 30 IDs', () {
    for (final id in bankIds) {
      expect(changelog.contains('`$id`'), isTrue, reason: id);
    }
  });

  test('no UNRESOLVED recommended actions', () {
    expect(
      RegExp(r'Recommended action:\*\* UNRESOLVED').hasMatch(redTeam),
      isFalse,
    );
  });

  test('material ID policy: candidate IDs match parent IDs', () {
    final parentIds = {
      for (final i in parent['items'] as List)
        (i as Map)['question_id'] as String,
    };
    expect(bankIds.toSet(), equals(parentIds));
  });
}
