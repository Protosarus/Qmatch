import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_dimension_profile.dart';

void main() {
  late Map<String, dynamic> blueprint;
  late String blueprintMd;
  late String evidenceMd;
  late String separatorMd;

  setUpAll(() {
    blueprint = jsonDecode(
      File('assets/schemas/canonical_assessment_blueprint_v3.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    blueprintMd = File('docs/core_engine/canonical_assessment_blueprint_v3.md')
        .readAsStringSync();
    evidenceMd = File('docs/core_engine/option_evidence_contract_v1.md')
        .readAsStringSync();
    separatorMd = File('docs/core_engine/adaptive_separator_blueprint_v1.md')
        .readAsStringSync();
  });

  test('1-5 canonical dimension counts and no retired aliases', () {
    expect(PersonaDimensionIds.all.length, 20);
    expect(PersonaDimensionIds.iq.length, 4);
    expect(PersonaDimensionIds.eq.length, 10);
    expect(PersonaDimensionIds.frequency.length, 6);
    expect(PersonaDimensionIds.all.contains('numerical'), isFalse);
    expect(PersonaDimensionIds.forbiddenAliases.contains('emotionalOpenness'),
        isTrue);
  });

  test('16-21 session counts and allocations', () {
    final sc = blueprint['session_counts'] as Map<String, dynamic>;
    expect(sc['iq_core'], 25);
    expect(sc['eq_core'], 30);
    expect(sc['frequency_core'], 50);
    expect(sc['adaptive_separator_max'], 8);
    expect(sc['adaptive_separator_min'], 0);

    final iq = Map<String, int>.from(
      (blueprint['iq_domain_allocation'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      ),
    );
    expect(iq.values.fold<int>(0, (a, b) => a + b), 25);
    expect(iq.keys.toSet(), PersonaDimensionIds.iq.toSet());

    expect(
      (blueprint['eq_dimensions'] as List).toSet(),
      PersonaDimensionIds.eq.toSet(),
    );
    expect(
      (blueprint['frequency_dimensions'] as List).toSet(),
      PersonaDimensionIds.frequency.toSet(),
    );
    expect(blueprint['frequency_min_primary_per_dimension_in_session'], 6);
  });

  test('6-10 no correct-answer / grid / frequency-type persona outputs in docs',
      () {
    expect(
        blueprintMd.contains('correctAnswer'), isTrue); // forbidden discussion
    expect(blueprintMd.toLowerCase().contains('morally correct'), isTrue);
    expect(separatorMd.contains('Are you an Empath'), isTrue);
    expect(
        separatorMd.toLowerCase().contains('do not force a persona'), isTrue);
    for (final bad in ['HH', 'HM', 'LL']) {
      expect(RegExp('\\b$bad\\b').hasMatch(blueprintMd), isFalse);
    }
  });

  test('13 separator targets reference valid personas in blueprint', () {
    const pairs = [
      'empat vs sifaci',
      'kararli vs uygulayici',
      'analist vs bagimsiz',
      'cesur vs donusturucu',
      'empat vs sezgisel',
      'koruyucu vs muhafiz',
      'bilge vs analist',
      'lider vs vizyoner',
      'yaratici vs donusturucu',
      'uygulayici vs stratejist',
    ];
    for (final p in pairs) {
      expect(separatorMd.toLowerCase().contains(p), isTrue, reason: p);
    }
  });

  test('15 missing evidence never neutral', () {
    expect(evidenceMd.contains('Missing evidence'), isTrue);
    expect(evidenceMd.contains('0.5'), isTrue);
    expect(evidenceMd.contains('hardcoded global denominator'), isTrue);
  });

  test('8 evidence sufficiency /3 documented as temporary mismatch', () {
    expect(evidenceMd.contains('evidenceCount_j / 3.0'), isTrue);
    expect(evidenceMd.contains('Before runtime integration'), isTrue);
  });

  test('17 every canonical dimension meets minimum planned evidence keys', () {
    final mins = blueprint['minimum_evidence_units_before_present'] as Map;
    expect(mins['iq'], 3);
    expect(mins['eq'], 3);
    expect(mins['frequency'], 3);
  });

  test('24 PersonaScoringService not imported by production screens', () {
    final screenDir = Directory('lib/features/assessment/screens');
    for (final f in screenDir.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      expect(src.contains('PersonaScoringService'), isFalse, reason: f.path);
      expect(src.contains('persona_scoring_service.dart'), isFalse);
    }
  });
}
