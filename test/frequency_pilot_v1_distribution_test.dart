import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_dimension_profile.dart';

import 'support/frequency_pilot_v1_helpers.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> items;

  setUpAll(() {
    form = FrequencyPilotV1Loader.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
  });

  test('primary allocation matches JSON plan 9/9/8/8/8/8', () {
    final counts = FrequencyPilotV1Loader.primaryCounts(items);
    final alloc = form['primary_dimension_allocation'] as Map;
    for (final e in alloc.entries) {
      expect(counts[e.key], e.value, reason: e.key);
    }
    expect(counts['depth_preference'], 9);
    expect(counts['communication_pace'], 9);
    expect(counts['social_energy'], 8);
    expect(counts['spontaneity'], 8);
    expect(counts['stability'], 8);
    expect(counts['disclosure_pace'], 8);
  });

  test('scenario family allocation is 5 per family', () {
    final counts = FrequencyPilotV1Loader.scenarioFamilyCounts(form);
    final alloc = form['scenario_family_allocation'] as Map;
    for (final e in alloc.entries) {
      expect(counts[e.key], e.value);
      expect(e.value, 5);
    }
  });

  test('pair registry meets semantic/reverse/isomorph minimums', () {
    final pr = form['pair_registry'] as Map;
    expect((pr['semantic_pairs'] as List).length, greaterThanOrEqualTo(8));
    expect((pr['reverse_pairs'] as List).length, greaterThanOrEqualTo(6));
    expect(
      (pr['behavioral_isomorph_groups'] as List).length,
      greaterThanOrEqualTo(6),
    );
  });

  test('RVI roles appear across the form', () {
    final roles = <String>{};
    for (final j in items) {
      roles.addAll((j['response_validity_roles'] as List).cast<String>());
    }
    for (final r in [
      'semantic_consistency',
      'reverse_consistency',
      'response_variation',
      'social_impression_risk',
      'repeated_context_stability',
      'timing_quality',
    ]) {
      expect(roles, contains(r));
    }
  });

  test('each dimension has >=5 secondary appearances and >=5 contexts', () {
    final secondary = FrequencyPilotV1Loader.secondaryAppearances(items);
    final contexts = FrequencyPilotV1Loader.independentContexts(form, items);
    for (final d in PersonaDimensionIds.frequency) {
      expect(secondary[d], greaterThanOrEqualTo(5), reason: d);
      expect(contexts[d]!.length, greaterThanOrEqualTo(5), reason: d);
    }
  });

  test('estimated completion seconds within 20-90', () {
    for (final j in items) {
      final secs = j['estimated_completion_seconds'] as num;
      expect(secs, inInclusiveRange(20, 90));
    }
  });
}
