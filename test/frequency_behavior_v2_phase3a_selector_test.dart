import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import 'support/frequency_behavior_v2_helpers.dart';

String _sha256File(String relative) {
  final bytes = File('${Directory.current.path}/$relative').readAsBytesSync();
  return sha256.convert(bytes).toString();
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

  test('same selector_version + bank_version + session_seed is bit-stable', () {
    final a = compose('phase3a-det-1', createdAt: '2026-01-01T00:00:00Z');
    final b = compose('phase3a-det-1', createdAt: '2026-12-31T23:59:59Z');
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

  test('created_at is metadata only and is not mixed into selection', () {
    final a = compose('phase3a-clock', createdAt: '2020-01-01T00:00:00Z');
    final b = compose('phase3a-clock', createdAt: '2030-01-01T00:00:00Z');
    expect(a.createdAt, '2020-01-01T00:00:00Z');
    expect(b.createdAt, '2030-01-01T00:00:00Z');
    expect(a.questionIds, b.questionIds);
  });

  test('different seeds produce different 50-question sessions', () {
    final a = compose('phase3a-diff-a');
    final b = compose('phase3a-diff-b');
    expect(a.questionIds, isNot(b.questionIds));
    expect(a.sessionId, isNot(b.sessionId));
  });

  test('every session is 50 unique selectable questions with 4/5 coverage', () {
    for (final seed in [
      'phase3a-cov-0',
      'phase3a-cov-1',
      'phase3a-cov-2',
      'phase3a-cov-3',
      'phase3a-cov-4',
    ]) {
      final m = compose(seed);
      _assertCoverage(m);
      for (final id in m.questionIds) {
        expect(review[id]!['selector_eligible'], isTrue, reason: id);
        expect(review[id]!['drop_from_selectable'], isNot(isTrue), reason: id);
        expect(pool.itemsById[id]!.primaryDimensions, hasLength(1));
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
      final m = compose('phase3a-drop-$i');
      expect(m.questionIds.toSet().intersection(drop), isEmpty);
    }
  });

  test('no more than two consecutive questions share a primary dimension', () {
    for (var i = 0; i < 30; i++) {
      final m = compose('phase3a-run-$i');
      var run = 1;
      for (var j = 1; j < m.questions.length; j++) {
        if (m.questions[j].primaryDimension ==
            m.questions[j - 1].primaryDimension) {
          run++;
          expect(
            run,
            lessThanOrEqualTo(
                FrequencyBehaviorV2Contract.maxConsecutiveSamePrimary),
            reason: 'seed=phase3a-run-$i at $j',
          );
        } else {
          run = 1;
        }
      }
    }
  });

  test(
      'option order is a permutation of stable option_ids, not authored ABCD by default',
      () {
    final m = compose('phase3a-opts');
    var authoredOrderCount = 0;
    for (final q in m.questions) {
      final item = pool.itemsById[q.questionId]!;
      final authored = [for (final o in item.options) o.optionId];
      expect(q.presentedOptionOrder.toSet(), authored.toSet());
      expect(q.presentedOptionOrder, hasLength(4));
      if (q.presentedOptionOrder.join() == authored.join())
        authoredOrderCount++;
    }
    expect(authoredOrderCount < 50, isTrue);
    final again = compose('phase3a-opts');
    expect(
      m.questions.map((q) => q.presentedOptionOrder.join(',')).toList(),
      again.questions.map((q) => q.presentedOptionOrder.join(',')).toList(),
    );
  });

  test('stored answers reference option_id; display index is not an identity',
      () {
    final m = compose('phase3a-score-id');
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

  test('manifest omits weights and evidence scores', () {
    final raw = jsonEncode(compose('phase3a-manifest').toJson());
    expect(raw.contains('behavioral_weights'), isFalse);
    expect(raw.contains('social_desirability'), isFalse);
    expect(raw.contains('diagnostic_value'), isFalse);
    expect(raw.contains('evidence_meta'), isFalse);
  });

  test('200-seed sample: extra slots rotate; no DROP; coverage holds', () {
    final extra = <String, int>{
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: 0,
    };
    final freq = <String, int>{};
    var adjacentSame = 0;
    var adjacentPairs = 0;
    for (var i = 0; i < 200; i++) {
      final m = compose('phase3a-sample-$i');
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
      for (var j = 1; j < m.questions.length; j++) {
        adjacentPairs++;
        if (m.questions[j].primaryDimension ==
            m.questions[j - 1].primaryDimension) {
          adjacentSame++;
        }
      }
    }
    expect(extra.values.where((n) => n > 0).length, 12);
    expect(extra.values.reduce((a, b) => a < b ? a : b) > 0, isTrue);
    expect(freq.length, lessThanOrEqualTo(405));
    expect(adjacentSame < adjacentPairs, isTrue);
  });

  test('10k simulation report exists with coverage invariants', () {
    final report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.phase3aSimulationReportRelativePath}',
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
      report.contains(
        'FREQUENCY V2 PHASE 3A DORMANT 50-QUESTION SELECTOR READY — V2 STILL DORMANT',
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
          .contains('frequency_behavior_pool_tr_v2'),
      isFalse,
    );
  });
}
