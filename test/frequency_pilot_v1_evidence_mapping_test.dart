import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/frequency_pilot_v1_helpers.dart';

void main() {
  late Map<String, dynamic> form;
  late List<Map<String, dynamic>> rawItems;
  late TraitScoringConfig config;
  late List<AssessmentItemDefinition> items;

  setUpAll(() {
    form = FrequencyPilotV1Loader.loadForm();
    rawItems = [
      for (final i in form['items'] as List)
        Map<String, dynamic>.from(i as Map),
    ];
    config = FrequencyPilotV1Loader.loadConfig();
    items = FrequencyPilotV1Loader.loadItems(config);
  });

  test('TraitScoringParser accepts the full Frequency pilot bank', () {
    expect(items.length, 50);
    for (final q in items) {
      expect(q.module, 'frequency');
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

  test('deltas respect range, dimension count, L1 cap, and Frequency-only dims',
      () {
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
          expect(PersonaDimensionIds.frequency, contains(e.key));
          expect(PersonaDimensionIds.eq, isNot(contains(e.key)));
          if (v.abs() > 1e-12) nonzero++;
          l1 += v.abs();
        }
        expect(nonzero, lessThanOrEqualTo(3));
        expect(l1, lessThanOrEqualTo(1.40 + 1e-9));
        expect(l1, lessThanOrEqualTo(config.maxL1DeltaMagnitude + 1e-9));
      }
    }
  });

  test('evidence_strength is varied and not equal to |primary delta|', () {
    final strengths = <double>{};
    for (final j in rawItems) {
      final primary = j['primary_dimension'] as String;
      for (final o in j['options'] as List) {
        final m = o as Map;
        final est = (m['evidence_strength'] as num).toDouble();
        strengths.add(est);
        expect(est, inInclusiveRange(0.40, 0.85));
        final pd = ((m['dimension_deltas'] as Map)[primary] as num).abs();
        expect((est - pd).abs(), greaterThan(1e-9));
      }
    }
    expect(strengths.length, greaterThanOrEqualTo(2));
    expect(strengths.contains(0.72), isFalse);
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
      FrequencyPilotV1Loader.session(
        config: config,
        items: items,
        responses: FrequencyPilotV1Loader.fullCoverageMaxPrimary(items),
      ),
    );
    for (final d in PersonaDimensionIds.frequency) {
      expect(result.module.dimensionPrimaryEvidenceCounts[d], greaterThan(0));
      expect(
          result.module.dimensionSecondaryEvidenceCounts[d]!, greaterThan(0));
    }
  });
}
