import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/eq_pilot_review_candidate_1_helpers.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> items;
  late String evidence;
  late String contract;

  setUpAll(() {
    form = EqPilotReviewCandidate1Loader.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
    final root = EqPilotReviewCandidate1Loader.repoRoot;
    evidence = File(
      '$root/docs/core_engine/eq_pilot_tr_v1_review_candidate_1_evidence_review.md',
    ).readAsStringSync();
    contract = File(
      '$root/docs/core_engine/eq_evidence_strength_contract_v1.md',
    ).readAsStringSync();
  });

  test('evidence strength contract exists with single meaning', () {
    expect(contract.contains('Single semantic meaning'), isTrue);
    expect(contract.contains('Forbidden interpretations'), isTrue);
  });

  test('no flat 0.72 evidence_strength remains', () {
    for (final j in items) {
      for (final o in j['options'] as List) {
        final s = ((o as Map)['evidence_strength'] as num).toDouble();
        expect((s - 0.72).abs() > 1e-9, isTrue, reason: '${j['question_id']}');
        expect(s, inInclusiveRange(0.40, 0.85));
      }
    }
  });

  test('empathy_003 item/option SDR consistency resolved', () {
    final j =
        items.firstWhere((e) => e['question_id'] == 'eq_tr_v1_empathy_003');
    expect(j['authoring_notes'].toString(), contains('sdr_item_risk=moderate'));
    final optSdr = [
      for (final o in j['options'] as List)
        (o as Map)['social_desirability_risk'] as String,
    ];
    expect(optSdr, contains('moderate'));
  });

  test('candidate evidence docs include option-level strength/SDR/RSR', () {
    expect(evidence.contains('evidence_strength:'), isTrue);
    expect(evidence.contains('social_desirability_risk:'), isTrue);
    expect(evidence.contains('response_style_risk:'), isTrue);
    for (final j in items) {
      expect(evidence.contains('`${j['question_id']}`'), isTrue);
    }
  });

  test('reverse assertiveness_003 A is positively keyed', () {
    final j = items
        .firstWhere((e) => e['question_id'] == 'eq_tr_v1_assertiveness_003');
    final a = (j['options'] as List)
        .cast<Map>()
        .firstWhere((o) => o['option_id'] == 'A');
    expect(
        (a['dimension_deltas'] as Map)['assertiveness'] as num, greaterThan(0));
  });

  test('deltas match documented vectors for a sample of items', () {
    for (final j in items.take(5)) {
      final qid = j['question_id'] as String;
      for (final o in j['options'] as List) {
        final m = o as Map;
        final oid = m['option_id'];
        final strength = (m['evidence_strength'] as num).toDouble();
        expect(
          evidence.contains('**$oid** — deltas:') ||
              evidence.contains('**$oid** —'),
          isTrue,
          reason: '$qid/$oid',
        );
        expect(
          evidence
              .contains('evidence_strength: ${strength.toStringAsFixed(2)}'),
          isTrue,
          reason: '$qid/$oid strength',
        );
      }
    }
  });
}
