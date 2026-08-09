import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Independent answer key agreement for the review candidate.
/// Stored keys must match the re-evaluated solutions document.
void main() {
  test('independent solutions document agrees with stored keys', () {
    final form = jsonDecode(
      File(
        'assets/data/assessment_v3/iq/iq_pilot_tr_v1_review_candidate_1.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final solutions = File(
      'docs/core_engine/iq_pilot_tr_v1_review_candidate_1_solutions.md',
    ).readAsStringSync();
    final redTeam = File('docs/core_engine/iq_pilot_tr_v1_red_team_review.md')
        .readAsStringSync();

    expect(redTeam.contains('Answer-key disagreements | 0'), isTrue);

    for (final raw in form['items'] as List) {
      final j = Map<String, dynamic>.from(raw as Map);
      final id = j['question_id'] as String;
      final correct = j['correct_option_id'] as String;
      expect(solutions.contains('## $id'), isTrue, reason: id);
      // Each solution section states "Final correct: `X`"
      final sectionStart = solutions.indexOf('## $id');
      final next = solutions.indexOf('\n## ', sectionStart + 4);
      final section = next < 0
          ? solutions.substring(sectionStart)
          : solutions.substring(sectionStart, next);
      expect(
        section.contains('Final correct: `$correct`'),
        isTrue,
        reason: '$id expected Final correct: `$correct`',
      );
    }
  });
}
