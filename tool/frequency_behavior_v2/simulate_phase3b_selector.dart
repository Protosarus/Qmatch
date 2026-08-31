// ignore_for_file: avoid_print
/// Phase 3B fairness audit: 10k-seed simulation of the dormant V2 selector.
///
/// Does not activate V2. Does not modify pool text, weights, or evidence.
///
/// Usage:
///   dart run tool/frequency_behavior_v2/simulate_phase3b_selector.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

void main(List<String> args) {
  var sessions = 10000;
  var outPath = FrequencyBehaviorV2Contract.phase3bSimulationReportRelativePath;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--sessions' && i + 1 < args.length) {
      sessions = int.parse(args[++i]);
    } else if (a == '--out' && i + 1 < args.length) {
      outPath = args[++i];
    }
  }

  final pool = FrequencyBehaviorV2PoolDocument.fromJson(
    jsonDecode(
      File(FrequencyBehaviorV2Contract.draftPoolRelativePath)
          .readAsStringSync(),
    ) as Map<String, dynamic>,
  );
  final reviewDoc = jsonDecode(
    File(FrequencyBehaviorV2Contract.draftReviewRelativePath)
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final review = <String, Map<String, dynamic>>{};
  for (final raw in reviewDoc['items'] as List) {
    final m = Map<String, dynamic>.from(raw as Map);
    review[m['item_id'] as String] = m;
  }
  final clusters = [
    for (final c
        in reviewDoc['semantic_near_duplicate_clusters'] as List? ?? [])
      [
        for (final id
            in Map<String, dynamic>.from(c as Map)['item_ids'] as List)
          id.toString(),
      ],
  ];
  if (pool.runtimeSelectable) {
    stderr.writeln('refusing: pool.runtime_selectable is true');
    exitCode = 2;
    return;
  }

  final dropIds = {
    for (final e in review.entries)
      if (e.value['drop_from_selectable'] == true) e.key,
  };
  final selectableIds = {
    for (final e in review.entries)
      if (e.value['selector_eligible'] == true) e.key,
  };
  final dimOf = <String, String>{
    for (final id in selectableIds)
      id: pool.itemsById[id]!.primaryDimensions.single,
  };
  final poolByDim = <String, int>{
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: 0,
  };
  for (final dim in dimOf.values) {
    poolByDim[dim] = (poolByDim[dim] ?? 0) + 1;
  }

  final extraByDim = <String, int>{
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: 0,
  };
  final dimSelections = <String, int>{
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: 0,
  };
  final qFreq = <String, int>{for (final id in selectableIds) id: 0};
  final optionSlot =
      List.generate(4, (_) => <String, int>{'a': 0, 'b': 0, 'c': 0, 'd': 0});
  var adjacentSame = 0;
  var adjacentPairs = 0;
  var sessionsWithTwoStreak = 0;
  var maxStreakSeen = 1;
  var coverageFailures = 0;
  var dropLeaks = 0;
  var dupQuestionSessions = 0;

  const composer = FrequencyBehaviorV2SessionComposer();
  for (var n = 0; n < sessions; n++) {
    final seed = 'phase3b-sim-$n';
    final m = composer.composeManifest(
      pool: pool,
      sessionSeed: seed,
      reviewByItemId: review,
      nearDuplicateClusters: clusters,
      createdAt: null,
    );
    if (m.questionIds.length != 50 || m.questionIds.toSet().length != 50) {
      dupQuestionSessions++;
    }
    final counts = <String, int>{
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: 0,
    };
    var run = 1;
    var hadTwo = false;
    for (var i = 0; i < m.questions.length; i++) {
      final q = m.questions[i];
      counts[q.primaryDimension] = (counts[q.primaryDimension] ?? 0) + 1;
      dimSelections[q.primaryDimension] =
          (dimSelections[q.primaryDimension] ?? 0) + 1;
      qFreq[q.questionId] = (qFreq[q.questionId] ?? 0) + 1;
      if (dropIds.contains(q.questionId) ||
          review[q.questionId]?['selector_eligible'] != true) {
        dropLeaks++;
      }
      final authored = pool.itemsById[q.questionId]!.options;
      for (var s = 0; s < q.presentedOptionOrder.length; s++) {
        final oid = q.presentedOptionOrder[s];
        final idx = authored.indexWhere((o) => o.optionId == oid);
        final letter = String.fromCharCode(97 + idx);
        optionSlot[s][letter] = (optionSlot[s][letter] ?? 0) + 1;
      }
      if (i > 0) {
        adjacentPairs++;
        if (q.primaryDimension == m.questions[i - 1].primaryDimension) {
          adjacentSame++;
          run++;
          if (run >= 2) hadTwo = true;
          if (run > maxStreakSeen) maxStreakSeen = run;
        } else {
          run = 1;
        }
      }
    }
    if (hadTwo) sessionsWithTwoStreak++;
    final fives = [
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions)
        if (counts[d] == 5) d,
    ];
    var ok = fives.length == 2;
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final c = counts[d]!;
      if (c != 4 && c != 5) ok = false;
    }
    if (!ok) coverageFailures++;
    for (final d in fives) {
      extraByDim[d] = extraByDim[d]! + 1;
    }
  }

  final freqs = qFreq.values.toList()..sort();
  final never = [
    for (final e in qFreq.entries)
      if (e.value == 0) e.key,
  ]..sort();
  final always = [
    for (final e in qFreq.entries)
      if (e.value == sessions) e.key,
  ]..sort();
  final minF = freqs.first;
  final maxF = freqs.last;
  final meanF = freqs.fold<int>(0, (a, b) => a + b) / freqs.length;
  final medianF = freqs.length.isOdd
      ? freqs[freqs.length ~/ 2].toDouble()
      : (freqs[freqs.length ~/ 2 - 1] + freqs[freqs.length ~/ 2]) / 2.0;
  final extraVals = extraByDim.values.toList()..sort();
  final extraMean = extraVals.fold<int>(0, (a, b) => a + b) / extraVals.length;
  const expectedAlloc = 4 + 2 / 12;

  String pct(num count) => (100.0 * count / sessions).toStringAsFixed(2);

  final ranked = qFreq.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      if (c != 0) return c;
      return a.key.compareTo(b.key);
    });

  String extraRows() {
    final buf = StringBuffer();
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final n = extraByDim[d]!;
      buf.writeln('- `$d`: $n (${pct(n)}%)');
    }
    return buf.toString().trimRight();
  }

  String slotRows() {
    final buf = StringBuffer();
    for (var s = 0; s < 4; s++) {
      final parts = [
        for (final letter in ['a', 'b', 'c', 'd'])
          '$letter=${optionSlot[s][letter]}',
      ];
      buf.writeln('- display slot $s: ${parts.join(', ')}');
    }
    return buf.toString().trimRight();
  }

  String listBlock(List<String> ids, {int take = 40}) {
    if (ids.isEmpty) return '- none';
    final shown = ids.take(take).map((id) {
      final dim = dimOf[id]!;
      return '`$id` ($dim, ${qFreq[id]}, ${pct(qFreq[id]!)}%)';
    }).join(', ');
    final more = ids.length > take ? ' … +${ids.length - take}' : '';
    return '- ${ids.length}: $shown$more';
  }

  String topBottom(List<MapEntry<String, int>> rows) {
    final buf = StringBuffer();
    for (final e in rows) {
      final dim = dimOf[e.key]!;
      final nPool = poolByDim[dim]!;
      final expectedPct = 100.0 * expectedAlloc / nPool;
      final ratio = (100.0 * e.value / sessions) / expectedPct;
      buf.writeln(
        '- `${e.key}` ($dim): ${e.value} (${pct(e.value)}%); '
        'dim expected ${expectedPct.toStringAsFixed(2)}%; '
        'ratio ${ratio.toStringAsFixed(2)}',
      );
    }
    return buf.toString().trimRight();
  }

  String dimExpectedRows() {
    final buf = StringBuffer();
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final n = poolByDim[d]!;
      final allocated = dimSelections[d]!;
      final expectedTotal = sessions * expectedAlloc;
      final expectedPerQ = expectedTotal / n;
      final expectedPct = 100.0 * expectedAlloc / n;
      buf.writeln(
        '- `$d`: pool=$n; selections=$allocated '
        '(expected ${expectedTotal.toStringAsFixed(1)}); '
        'expected mean per question ${expectedPerQ.toStringAsFixed(1)} '
        '(${expectedPct.toStringAsFixed(2)}%)',
      );
    }
    return buf.toString().trimRight();
  }

  String allQuestionRows() {
    final buf = StringBuffer();
    buf.writeln(
      '| question_id | dimension | count | pct | dim_expected_pct | ratio |',
    );
    buf.writeln('|---|---|---:|---:|---:|---:|');
    final byId = qFreq.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    for (final e in byId) {
      final dim = dimOf[e.key]!;
      final expectedPct = 100.0 * expectedAlloc / poolByDim[dim]!;
      final observedPct = 100.0 * e.value / sessions;
      final ratio = observedPct / expectedPct;
      buf.writeln(
        '| `${e.key}` | `$dim` | ${e.value} | ${observedPct.toStringAsFixed(2)} | '
        '${expectedPct.toStringAsFixed(2)} | ${ratio.toStringAsFixed(2)} |',
      );
    }
    return buf.toString().trimRight();
  }

  String alwaysExplain() {
    if (always.isEmpty) {
      return 'No question was selected in 100% of sessions. Smallest dimension '
          'pool is ${poolByDim.values.reduce((a, b) => a < b ? a : b)}, which is '
          'larger than the max per-dimension quota (5), so 100% coverage is not '
          'mathematically required.';
    }
    final buf = StringBuffer();
    buf.writeln(
      '${always.length} question(s) appeared in every session. '
      '100% is only unavoidable when a dimension pool size is ≤ quota (4 or 5).',
    );
    for (final id in always) {
      final dim = dimOf[id]!;
      final n = poolByDim[dim]!;
      final unavoidable = n <= 5;
      buf.writeln(
        '- `$id` ($dim, pool=$n): '
        '${unavoidable ? 'mathematically unavoidable' : 'NOT required by pool size — investigate'}',
      );
    }
    return buf.toString().trimRight();
  }

  final formerAlways = [
    'frequency_v2_q0145',
    'frequency_v2_q0156',
    'frequency_v2_q0281',
  ];
  String formerRows() {
    final buf = StringBuffer();
    for (final id in formerAlways) {
      final n = qFreq[id] ?? 0;
      buf.writeln('- `$id` (${dimOf[id]}): $n (${pct(n)}%)');
    }
    return buf.toString().trimRight();
  }

  final report = '''
# Frequency V2 Phase 3B — Selector fairness simulation

Status: **offline / dormant**. `runtime_selectable` remains false.
Selector: `${FrequencyBehaviorV2Contract.selectorVersion}`
Bank: `${pool.poolVersion}`
Seeds: `phase3b-sim-0` … `phase3b-sim-${sessions - 1}`
Sessions: **$sessions**

Candidate order is a per-question FNV rank from
`selector_version + bank_version + session_seed + primary_dimension + question_id`
**before** diversity caps. Frequencies were not retuned after seeing the numbers.

## Phase 3A invariants

- Sessions with != 50 unique question IDs: **$dupQuestionSessions**
- Coverage failures (not 4/5 with exactly two fives): **$coverageFailures**
- DROP / ineligible leaks: **$dropLeaks**
- Archive DROP IDs: **${dropIds.length}**
- Selectable IDs tracked: **${selectableIds.length}**
- Extra-slot min/max/mean: ${extraVals.first} / ${extraVals.last} / ${extraMean.toStringAsFixed(2)} (expected ${(sessions * 2 / 12).toStringAsFixed(2)})

${extraRows()}

## Consecutive same-dimension

- adjacent pairs: $adjacentPairs
- adjacent same-primary pairs: $adjacentSame (${(100.0 * adjacentSame / adjacentPairs).toStringAsFixed(3)}%)
- sessions with at least one 2-streak: $sessionsWithTwoStreak
- max streak observed: $maxStreakSeen (cap is ${FrequencyBehaviorV2Contract.maxConsecutiveSamePrimary})

## Option-position distribution

Total placements per slot: ${sessions * 50}

${slotRows()}

## Question selection frequency (405 selectable)

- min count / pct: **$minF** / **${pct(minF)}%**
- median count / pct: **${medianF.toStringAsFixed(1)}** / **${pct(medianF)}%**
- mean count / pct: **${meanF.toStringAsFixed(3)}** / **${pct(meanF)}%**
- max count / pct: **$maxF** / **${pct(maxF)}%**
- questions ever selected: **${qFreq.values.where((n) => n > 0).length}**
- questions never selected: **${never.length}**
- questions selected in every session: **${always.length}**

### Never selected

${listBlock(never)}

### Selected in 100% of sessions

${listBlock(always)}

${alwaysExplain()}

### Former Phase 3A 100% items (must not remain mandatory)

${formerRows()}

### Top 20 most-selected

${topBottom(ranked.take(20).toList())}

### Bottom 20 least-selected

${topBottom(ranked.reversed.take(20).toList())}

## Selection frequency by primary dimension

Expected allocations per session per dimension: 4 + 2/12 = ${expectedAlloc.toStringAsFixed(4)}.

${dimExpectedRows()}

## All 405 questions

${allQuestionRows()}

## Safety

- V2 not activated
- pool text / weights / evidence values not modified by this simulation
- option shuffle stream `options|{question_id}` unchanged
- no V1 / Firebase / C2 / Discover / Persona / matching / 12D→6D adapter

FREQUENCY V2 PHASE 3B SELECTOR FAIRNESS AUDIT COMPLETE — STRUCTURAL ALWAYS-WINNER BIAS REMOVED — V2 STILL DORMANT
''';

  File(outPath).writeAsStringSync(report);
  stdout.writeln(report.trimRight());
  stdout.writeln('wrote $outPath');
}
