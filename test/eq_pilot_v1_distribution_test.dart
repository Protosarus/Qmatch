import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_dimension_profile.dart';

import 'support/eq_pilot_v1_helpers.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> items;

  setUpAll(() {
    form = EqPilotV1Loader.loadForm();
    items = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
  });

  test('primary allocation is 3 per EQ dimension', () {
    final counts = EqPilotV1Loader.primaryCounts(items);
    for (final d in PersonaDimensionIds.eq) {
      expect(counts[d], 3, reason: d);
    }
  });

  test('scenario family allocation is 3 per family', () {
    final counts = EqPilotV1Loader.scenarioFamilyCounts(form);
    final alloc = form['scenario_family_allocation'] as Map;
    for (final e in alloc.entries) {
      expect(counts[e.key], e.value);
    }
  });

  test('pair registry meets semantic/reverse/isomorph minimums', () {
    final pr = form['pair_registry'] as Map;
    expect((pr['semantic_pairs'] as List).length, greaterThanOrEqualTo(6));
    expect((pr['reverse_pairs'] as List).length, greaterThanOrEqualTo(5));
    expect(
      (pr['behavioral_isomorph_groups'] as List).length,
      greaterThanOrEqualTo(5),
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

  test('each dimension has >=2 secondary appearances and >=3 contexts', () {
    final secondary = EqPilotV1Loader.secondaryAppearances(items);
    final contexts = EqPilotV1Loader.independentContexts(form, items);
    for (final d in PersonaDimensionIds.eq) {
      expect(secondary[d], greaterThanOrEqualTo(2), reason: d);
      expect(contexts[d]!.length, greaterThanOrEqualTo(3), reason: d);
    }
  });

  test('estimated completion seconds within 20-90', () {
    for (final j in items) {
      final secs = j['estimated_completion_seconds'] as num;
      expect(secs, inInclusiveRange(20, 90));
    }
  });
}
