import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_dimension_profile.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/frequency_pilot_review_candidate_1_helpers.dart';

void main() {
  late List<Map<String, dynamic>> items;
  late String separationDoc;

  setUpAll(() {
    final form = FrequencyPilotReviewCandidate1Loader.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
    separationDoc = File(
      '${FrequencyPilotReviewCandidate1Loader.repoRoot}/docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_construct_separation_report.md',
    ).readAsStringSync();
  });

  test('no EQ dimension deltas appear in candidate bank', () {
    for (final j in items) {
      for (final o in j['options'] as List) {
        final deltas = (o as Map)['dimension_deltas'] as Map;
        for (final key in deltas.keys) {
          expect(PersonaDimensionIds.eq, isNot(contains(key)),
              reason: '${j['question_id']}/$key');
          expect(PersonaDimensionIds.frequency, contains(key));
        }
      }
    }
  });

  test('forbidden emotionalOpenness alias absent from bank blob', () {
    final blob = jsonEncode({'items': items}).toLowerCase();
    expect(blob.contains('emotionalopenness'), isFalse);
    expect(blob.contains('emotional_openness'), isFalse);
  });

  test('construct separation doc mentions EQ separation', () {
    expect(separationDoc, contains('EQ / Frequency module separation'));
    expect(separationDoc, contains('disclosure_pace'));
    expect(separationDoc.toLowerCase(), contains('pass'));
  });

  test('quality report references construct separation doc', () {
    final quality = File(
      '${FrequencyPilotReviewCandidate1Loader.repoRoot}/docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_quality_report.md',
    ).readAsStringSync();
    expect(
      quality,
      contains(
          'frequency_pilot_tr_v1_review_candidate_1_construct_separation_report.md'),
    );
    expect(quality, contains('CONDITIONAL'));
  });
}
