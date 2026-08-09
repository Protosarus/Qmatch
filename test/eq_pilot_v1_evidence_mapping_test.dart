import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/eq_pilot_v1_helpers.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> rawItems;
  late TraitScoringConfig config;
  late List<AssessmentItemDefinition> items;

  setUpAll(() {
    form = EqPilotV1Loader.loadForm();
    rawItems = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
    config = EqPilotV1Loader.loadConfig();
    items = EqPilotV1Loader.loadItems(config);
  });

  test('TraitScoringParser accepts the full EQ pilot bank', () {
    expect(items.length, 30);
    for (final q in items) {
      expect(q.module, 'eq');
      expect(q.options, hasLength(4));
    }
  });

  test('primary dimension key present in every option delta map', () {
    for (final j in rawItems) {
      final primary = j['primary_dimension'] as String;
      for (final o in j['options'] as List) {
        final deltas = (o as Map)['dimension_deltas'] as Map;
        expect(deltas.containsKey(primary), isTrue,
            reason: '${j['question_id']}/${o['option_id']}');
      }
    }
  });

  test('deltas respect range, dimension count, and L1 authoring cap', () {
    for (final j in rawItems) {
      for (final o in j['options'] as List) {
        final deltas = Map<String, dynamic>.from(
          (o as Map)['dimension_deltas'] as Map,
        );
        var l1 = 0.0;
        var nonzero = 0;
        for (final e in deltas.entries) {
          final v = (e.value as num).toDouble();
          expect(v, inInclusiveRange(-1.0, 1.0));
          if (v.abs() > 1e-12) nonzero++;
          l1 += v.abs();
        }
        expect(nonzero, lessThanOrEqualTo(3));
        expect(l1, lessThanOrEqualTo(1.40 + 1e-9));
        expect(l1, lessThanOrEqualTo(config.maxL1DeltaMagnitude + 1e-9));
      }
    }
  });

  test('pair registry ids match item fields', () {
    final pr = form['pair_registry'] as Map;
    for (final p in pr['semantic_pairs'] as List) {
      final pid = (p as Map)['pair_id'] as String;
      for (final qid in p['question_ids'] as List) {
        final item = rawItems.firstWhere((j) => j['question_id'] == qid);
        expect(item['semantic_pair_id'], pid);
      }
    }
    for (final p in pr['reverse_pairs'] as List) {
      final pid = (p as Map)['pair_id'] as String;
      for (final qid in p['question_ids'] as List) {
        final item = rawItems.firstWhere((j) => j['question_id'] == qid);
        expect(item['reverse_pair_id'], pid);
      }
    }
    for (final p in pr['behavioral_isomorph_groups'] as List) {
      final gid = (p as Map)['group_id'] as String;
      for (final qid in p['question_ids'] as List) {
        final item = rawItems.firstWhere((j) => j['question_id'] == qid);
        expect(item['behavioral_isomorph_group'], gid);
      }
    }
  });

  test('primary and secondary evidence counts are non-zero on scored items',
      () {
    final service = TraitScoringService(config: config);
    final result = service.scoreModule(
      EqPilotV1Loader.session(
        config: config,
        items: items,
        responses: EqPilotV1Loader.fullCoverageMaxPrimary(items),
      ),
    );
    for (final d in PersonaDimensionIds.eq) {
      expect(result.module.dimensionPrimaryEvidenceCounts[d], greaterThan(0));
      expect(
          result.module.dimensionSecondaryEvidenceCounts[d]!, greaterThan(0));
    }
  });
}
