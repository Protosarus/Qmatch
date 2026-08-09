import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_dimension_profile.dart';

import 'support/frequency_pilot_v1_helpers.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> items;
  late String separationDoc;

  setUpAll(() {
    form = FrequencyPilotV1Loader.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
    separationDoc = File(
      '${FrequencyPilotV1Loader.repoRoot}/docs/core_engine/frequency_pilot_tr_v1_construct_separation_report.md',
    ).readAsStringSync();
  });

  test('no EQ dimension deltas appear in Frequency bank', () {
    for (final j in items) {
      for (final o in j['options'] as List) {
        final deltas = (o as Map)['dimension_deltas'] as Map;
        for (final key in deltas.keys) {
          expect(PersonaDimensionIds.eq, isNot(contains(key)),
              reason: '${j['question_id']}/$key');
          expect(key, isNot('emotional_openness'));
        }
      }
    }
  });

  test('forbidden emotionalOpenness alias absent from bank blob', () {
    final blob = jsonEncode(form).toLowerCase();
    expect(blob.contains('emotionalopenness'), isFalse);
    expect(blob.contains('emotional_openness'), isFalse);
    for (final a in PersonaDimensionIds.forbiddenAliases) {
      if (a.toLowerCase().contains('emotional')) {
        expect(blob.contains('"$a"'), isFalse, reason: a);
      }
    }
  });

  test('only Frequency dimensions appear in delta maps', () {
    for (final j in items) {
      for (final o in j['options'] as List) {
        final deltas = (o as Map)['dimension_deltas'] as Map;
        for (final key in deltas.keys) {
          expect(PersonaDimensionIds.frequency, contains(key));
        }
      }
    }
  });

  test('construct separation doc mentions EQ separation and disclosure_pace',
      () {
    expect(separationDoc, contains('EQ / Frequency module separation'));
    expect(separationDoc, contains('disclosure_pace'));
    expect(separationDoc, contains('emotional_openness'));
    expect(separationDoc, contains('EQ dimension deltas found in bank'));
    expect(separationDoc.toLowerCase(), contains('pass'));
  });

  test('quality report references construct separation doc', () {
    final quality = File(
      '${FrequencyPilotV1Loader.repoRoot}/docs/core_engine/frequency_pilot_tr_v1_quality_report.md',
    ).readAsStringSync();
    expect(
      quality,
      contains('frequency_pilot_tr_v1_construct_separation_report.md'),
    );
    expect(quality, contains('disclosure_pace'));
  });
}
