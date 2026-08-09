import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/frequency_pilot_review_candidate_1_helpers.dart';

void main() {
  late List<String> bankIds;
  late String root;

  setUpAll(() {
    root = FrequencyPilotReviewCandidate1Loader.repoRoot;
    final form = FrequencyPilotReviewCandidate1Loader.loadForm();
    bankIds = [
      for (final i in form['items'] as List)
        (i as Map)['question_id'] as String,
    ];
  });

  final requiredDocs = [
    'docs/core_engine/frequency_pilot_tr_v1_red_team_review.md',
    'docs/core_engine/frequency_reverse_pair_application_review_v1.md',
    'docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_changelog.md',
    'docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_evidence_review.md',
    'docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_option_balance_report.md',
    'docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_construct_separation_report.md',
    'docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_quality_report.md',
  ];

  test('all required markdown artifacts exist', () {
    for (final path in requiredDocs) {
      expect(File('$root/$path').existsSync(), isTrue, reason: path);
    }
  });

  test('evidence review covers all 50 IDs', () {
    final evidence = File(
      '$root/docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_evidence_review.md',
    ).readAsStringSync();
    for (final id in bankIds) {
      expect(evidence.contains('`$id`'), isTrue, reason: id);
    }
    expect(evidence, contains('evidence_strength:'));
    expect(evidence, contains('social_desirability_risk:'));
    expect(evidence, contains('response_style_risk:'));
  });

  test('quality report documents CONDITIONAL overall readiness', () {
    final quality = File(
      '$root/docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_quality_report.md',
    ).readAsStringSync();
    expect(quality, contains('**CONDITIONAL**'));
    expect(quality, contains('Reverse-pair readiness'));
    expect(quality, contains('frequency-tr-pilot-v1-review-candidate-1'));
  });

  test('changelog sidecar JSON has 50 entries', () {
    final sidecar = File(
      '$root/tool/frequency_pilot_out/review_candidate_1_changelog.json',
    );
    expect(sidecar.existsSync(), isTrue);
    final text = sidecar.readAsStringSync();
    expect(text.contains('frequency_tr_v1_'), isTrue);
    expect(
      RegExp(r'"original_id"').allMatches(text).length,
      50,
    );
  });
}
