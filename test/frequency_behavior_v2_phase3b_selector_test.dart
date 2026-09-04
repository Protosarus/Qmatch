import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import 'support/frequency_behavior_v2_helpers.dart';

const _formerAlwaysWinners = [
  'frequency_v2_q0145',
  'frequency_v2_q0156',
  'frequency_v2_q0281',
];

String _sha256File(String relative) {
  final bytes = File('${Directory.current.path}/$relative').readAsBytesSync();
  return sha256.convert(bytes).toString();
}

int _candidateRank({
  required String bankVersion,
  required String sessionSeed,
  required String dimension,
  required String questionId,
}) {
  return FrequencyBehaviorV2Rng.fromParts([
    FrequencyBehaviorV2Contract.selectorVersion,
    bankVersion,
    sessionSeed,
    dimension,
    questionId,
  ]).nextUint32();
}

void _assertCoverage(FrequencyBehaviorV2SessionManifest manifest) {
  expect(manifest.questionIds, hasLength(50));
  expect(manifest.questionIds.toSet(), hasLength(50));
  expect(manifest.questions, hasLength(50));
  final counts = <String, int>{
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: 0,
  };
  for (var i = 0; i < manifest.questions.length; i++) {
    final q = manifest.questions[i];
    expect(q.presentationIndex, i);
    expect(q.questionId, manifest.questionIds[i]);
    counts[q.primaryDimension] = (counts[q.primaryDimension] ?? 0) + 1;
  }
  final fives = <String>[];
  for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
    final n = counts[d]!;
    expect(n == 4 || n == 5, isTrue, reason: '$d=$n');
    if (n == 5) fives.add(d);
  }
  expect(fives, hasLength(2));
  expect(fives.toSet(), hasLength(2));
}

void main() {
  late FrequencyBehaviorV2PoolDocument pool;
  late Map<String, Map<String, dynamic>> review;
  late List<List<String>> clusters;

  setUpAll(() {
    pool = FrequencyBehaviorV2DraftLoader.loadPool();
    review = FrequencyBehaviorV2DraftLoader.reviewByItemId();
    clusters = FrequencyBehaviorV2DraftLoader.loadNearDuplicateClusters();
  });

  FrequencyBehaviorV2SessionManifest compose(
    String seed, {
    String? createdAt,
    String? sessionId,
  }) {
    return const FrequencyBehaviorV2SessionComposer().composeManifest(
      pool: pool,
      sessionSeed: seed,
      reviewByItemId: review,
      nearDuplicateClusters: clusters,
      createdAt: createdAt,
      sessionId: sessionId,
    );
  }

  test('candidate rank is seed-dependent, not static question-id order', () {
    final ids = [
      for (final item in pool.items)
        if (item.primaryDimensions.length == 1 &&
            item.primaryDimensions.single == 'closeness_pace' &&
            review[item.itemId]?['selector_eligible'] == true)
          item.itemId,
    ]..sort();
    expect(ids.length, greaterThan(8));

    List<String> orderFor(String seed) {
      final ranked = [...ids];
      ranked.sort((a, b) {
        final ra = _candidateRank(
          bankVersion: pool.poolVersion,
          sessionSeed: seed,
          dimension: 'closeness_pace',
          questionId: a,
        );
        final rb = _candidateRank(
          bankVersion: pool.poolVersion,
          sessionSeed: seed,
          dimension: 'closeness_pace',
          questionId: b,
        );
        if (ra != rb) return ra.compareTo(rb);
        return a.compareTo(b);
      });
      return ranked;
    }

    final a = orderFor('phase3b-rank-a');
    final b = orderFor('phase3b-rank-b');
    expect(a, isNot(ids), reason: 'must not keep bank/id order');
    expect(a, isNot(b), reason: 'different seeds must reorder candidates');
    expect(orderFor('phase3b-rank-a'), a);
  });

  test('same selector_version + bank_version + session_seed is bit-stable', () {
    final a = compose('phase3b-det-1', createdAt: '2026-01-01T00:00:00Z');
    final b = compose('phase3b-det-1', createdAt: '2026-12-31T23:59:59Z');
    expect(a.schemaVersion,
        FrequencyBehaviorV2Contract.sessionManifestSchemaVersion);
    expect(a.selectorVersion, FrequencyBehaviorV2Contract.selectorVersion);
    expect(a.bankVersion, pool.poolVersion);
    expect(a.sessionId, b.sessionId);
    expect(a.questionIds, b.questionIds);
    expect(
      a.questions.map((q) => q.presentedOptionOrder.join(',')).toList(),
      b.questions.map((q) => q.presentedOptionOrder.join(',')).toList(),
    );
    expect(jsonEncode(a.toJson()..['created_at'] = null),
        jsonEncode(b.toJson()..['created_at'] = null));
  });

  test('every session is 50 unique selectable questions with 4/5 coverage', () {
    for (final seed in [
      'phase3b-cov-0',
      'phase3b-cov-1',
      'phase3b-cov-2',
      'phase3b-cov-3',
      'phase3b-cov-4',
    ]) {
      final m = compose(seed);
      _assertCoverage(m);
      for (final id in m.questionIds) {
        expect(review[id]!['selector_eligible'], isTrue, reason: id);
        expect(review[id]!['drop_from_selectable'], isNot(isTrue), reason: id);
      }
    }
  });

  test('DROP questions are never selected', () {
    final drop = <String>{
      ...FrequencyBehaviorV2DraftLoader.phase1fDropFromSelectableIds,
      ...FrequencyBehaviorV2DraftLoader.phase2eNewDropIds,
      ...FrequencyBehaviorV2DraftLoader.phase2fNewDropIds,
    };
    expect(drop, hasLength(21));
    for (var i = 0; i < 40; i++) {
      final m = compose('phase3b-drop-$i');
      expect(m.questionIds.toSet().intersection(drop), isEmpty);
    }
  });

  test('no more than two consecutive questions share a primary dimension', () {
    for (var i = 0; i < 30; i++) {
      final m = compose('phase3b-run-$i');
      var run = 1;
      for (var j = 1; j < m.questions.length; j++) {
        if (m.questions[j].primaryDimension ==
            m.questions[j - 1].primaryDimension) {
          run++;
          expect(
            run,
            lessThanOrEqualTo(
              FrequencyBehaviorV2Contract.maxConsecutiveSamePrimary,
            ),
            reason: 'seed=phase3b-run-$i at $j',
          );
        } else {
          run = 1;
        }
      }
    }
  });

  test(
      'option order is a permutation of stable option_ids; same seed is stable',
      () {
    final m = compose('phase3b-opts');
    var authoredOrderCount = 0;
    for (final q in m.questions) {
      final item = pool.itemsById[q.questionId]!;
      final authored = [for (final o in item.options) o.optionId];
      expect(q.presentedOptionOrder.toSet(), authored.toSet());
      expect(q.presentedOptionOrder, hasLength(4));
      if (q.presentedOptionOrder.join() == authored.join()) {
        authoredOrderCount++;
      }
    }
    expect(authoredOrderCount < 50, isTrue);
    final again = compose('phase3b-opts');
    expect(
      m.questions.map((q) => q.presentedOptionOrder.join(',')).toList(),
      again.questions.map((q) => q.presentedOptionOrder.join(',')).toList(),
    );
  });

  test('stored answers reference option_id; display index is not an identity',
      () {
    final m = compose('phase3b-score-id');
    final q = m.questions.first;
    final chosen = q.presentedOptionOrder[2];
    const scorer = FrequencyBehaviorV2Scorer();
    final scored = scorer.score(
      pool: pool,
      responses: [
        FrequencyBehaviorV2Response(itemId: q.questionId, optionId: chosen),
      ],
    );
    expect(scored.ok, isTrue);
    expect(pool.itemsById[q.questionId]!.optionById(chosen), isNotNull);
  });

  test('200-seed sample: former always-winners are not mandatory; no 100% item',
      () {
    final extra = <String, int>{
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: 0,
    };
    final freq = <String, int>{};
    const sessions = 200;
    for (var i = 0; i < sessions; i++) {
      final m = compose('phase3b-sample-$i');
      _assertCoverage(m);
      final counts = <String, int>{};
      for (final q in m.questions) {
        counts[q.primaryDimension] = (counts[q.primaryDimension] ?? 0) + 1;
        freq[q.questionId] = (freq[q.questionId] ?? 0) + 1;
        expect(review[q.questionId]!['drop_from_selectable'], isNot(isTrue));
      }
      for (final e in counts.entries) {
        if (e.value == 5) extra[e.key] = extra[e.key]! + 1;
      }
    }
    expect(extra.values.where((n) => n > 0).length, 12);
    expect(freq.values.reduce((a, b) => a > b ? a : b), lessThan(sessions));
    for (final id in _formerAlwaysWinners) {
      final n = freq[id] ?? 0;
      expect(n, greaterThan(0), reason: '$id disappeared entirely');
      expect(n, lessThan(sessions), reason: '$id still mandatory');
    }
    final poolByDim = <String, int>{};
    for (final e in review.entries) {
      if (e.value['selector_eligible'] != true) continue;
      final dim = pool.itemsById[e.key]!.primaryDimensions.single;
      poolByDim[dim] = (poolByDim[dim] ?? 0) + 1;
    }
    expect(poolByDim.values.every((n) => n > 5), isTrue);
  });

  test('10k fairness report exists with coverage and no structural 100% items',
      () {
    final report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.phase3bSimulationReportRelativePath}',
    ).readAsStringSync();
    expect(report.contains('Sessions: **10000**'), isTrue);
    expect(
      report.contains(
        'Coverage failures (not 4/5 with exactly two fives): **0**',
      ),
      isTrue,
    );
    expect(report.contains('DROP / ineligible leaks: **0**'), isTrue);
    expect(report.contains('questions never selected: **0**'), isTrue);
    expect(
        report.contains('questions selected in every session: **0**'), isTrue);
    expect(report.contains('Sessions with != 50 unique question IDs: **0**'),
        isTrue);
    for (final id in _formerAlwaysWinners) {
      expect(report.contains('`$id`'), isTrue);
      expect(RegExp('`$id`.*100\\.00%').hasMatch(report), isFalse);
    }
    expect(
      report.contains(
        'FREQUENCY V2 PHASE 3B SELECTOR FAIRNESS AUDIT COMPLETE — STRUCTURAL ALWAYS-WINNER BIAS REMOVED — V2 STILL DORMANT',
      ),
      isTrue,
    );
  });

  test('RNG mixer parts are order-sensitive; V2 stays dormant', () {
    final a = FrequencyBehaviorV2Rng.fromParts(['ab', 'c']).nextUint32();
    final b = FrequencyBehaviorV2Rng.fromParts(['a', 'bc']).nextUint32();
    expect(a, isNot(b));
    expect(pool.runtimeSelectable, isFalse);
    expect(
      FrequencyBehaviorV2BankRegistry.isRuntimeSelectable(pool.poolVersion),
      isFalse,
    );
    expect(
      _sha256File(FrequencyBehaviorV2Contract.liveV1BankPaths[0]),
      '1ab16a99f75b4d5122bda3b9cd450e13cb7da87895ffadfb5459dc5cf4fe4744',
    );
    expect(
      _sha256File(FrequencyBehaviorV2Contract.liveV1BankPaths[1]),
      '367836025990121ed0fbc8703dcaabcba8ab39dd49ceb36d97e175c8f33afba4',
    );
    expect(FrequencyBankContract.trAssetPath,
        contains('frequency_bank_tr_v1.json'));
    expect(
      File('${Directory.current.path}/pubspec.yaml')
          .readAsStringSync()
          .contains('tool/frequency_behavior_v2/out/'),
      isFalse,
    );
  });
}
