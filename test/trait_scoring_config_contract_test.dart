import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

void main() {
  late TraitScoringConfig config;

  setUpAll(() {
    final text = File(
      '${Directory.current.path}/assets/data/trait_scoring_config_v1.json',
    ).readAsStringSync();
    config = TraitScoringParser.parseConfigJson(text);
  });

  test('exactly 20 canonical dimensions with module mapping', () {
    expect(config.dimensionRequirements.length, 20);
    expect(
        config.dimensionRequirements.keys.toSet(), PersonaDimensionIds.allSet);
    for (final d in PersonaDimensionIds.iq) {
      expect(config.requireDimension(d).module, 'iq');
    }
    for (final d in PersonaDimensionIds.eq) {
      expect(config.requireDimension(d).module, 'eq');
    }
    for (final d in PersonaDimensionIds.frequency) {
      expect(config.requireDimension(d).module, 'frequency');
    }
  });

  test('no global evidence denominator in config', () {
    final raw = jsonDecode(
      File(
        '${Directory.current.path}/assets/data/trait_scoring_config_v1.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(raw['status'], 'provisional');
    expect(raw['calibration_notes']['no_global_evidence_denominator'], isTrue);
    expect(config.traitScoringVersion, 'trait_scoring_v1.0');
    expect(config.rviVersion, 'rvi_v1_provisional');
  });

  test('dimension-specific targets differ across modules', () {
    final iq = config.requireDimension('logical_reasoning');
    final eq = config.requireDimension('empathy');
    final f = config.requireDimension('disclosure_pace');
    expect(iq.targetPrimaryEvidence, isNot(eq.targetPrimaryEvidence));
    expect(eq.minimumTotalEvidence, greaterThan(0));
    expect(f.requiredForPersona, isTrue);
  });

  test('retired aliases are not config keys', () {
    for (final a in PersonaDimensionIds.forbiddenAliases) {
      expect(config.dimensionRequirements.containsKey(a), isFalse);
    }
  });
}
