// ignore_for_file: avoid_print
/// Offline 10k-seed simulation for the dormant Frequency V2 selector.
///
/// Does not activate V2. Does not modify pool text, weights, or evidence.
///
/// Usage:
///   dart run tool/frequency_behavior_v2/simulate_phase3a_selector.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

void main(List<String> args) {
  var sessions = 10000;
  var outPath = FrequencyBehaviorV2Contract.phase3aSimulationReportRelativePath;
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

  final extraByDim = <String, int>{
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
    final seed = 'phase3a-sim-$n';
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
  final minF = freqs.first;
  final maxF = freqs.last;
  final meanF = freqs.fold<int>(0, (a, b) => a + b) / freqs.length;
  final extraVals = extraByDim.values.toList()..sort();
  final extraMean = extraVals.fold<int>(0, (a, b) => a + b) / extraVals.length;

  String extraRows() {
    final buf = StringBuffer();
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final n = extraByDim[d]!;
      final pct = (100.0 * n / sessions).toStringAsFixed(2);
      buf.writeln('- `$d`: $n ($pct%)');
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

  final always = [
    for (final e in qFreq.entries)
      if (e.value == sessions) e.key,
  ]..sort();
  String alwaysBlock() {
    if (always.isEmpty) return '- none';
    final shown = always.take(20).map((id) {
      final dim = pool.itemsById[id]!.primaryDimensions.single;
      return '`$id` ($dim)';
    }).join(', ');
    final more = always.length > 20 ? ' … +${always.length - 20}' : '';
    return '- ${always.length} questions at max: $shown$more';
  }

  String neverBlock() {
    if (never.isEmpty) return '- none';
    final shown = never.take(40).map((id) {
      final dim = pool.itemsById[id]!.primaryDimensions.single;
      return '`$id` ($dim)';
    }).join(', ');
    final more = never.length > 40 ? ' … +${never.length - 40}' : '';
    return '- ${never.length} questions: $shown$more';
  }

  final extraRowsText = extraRows();
  final neverBlockText = neverBlock();
  final alwaysBlockText = alwaysBlock();
  final slotRowsText = slotRows();

  final report = '''
# Frequency V2 Phase 3A — Selector simulation

Status: **offline / dormant**. `runtime_selectable` remains false.
Selector: `${FrequencyBehaviorV2Contract.selectorVersion}`
Bank: `${pool.poolVersion}`
Seeds: `phase3a-sim-0` … `phase3a-sim-${sessions - 1}`
Sessions: **$sessions**

This report is actual output. Scores and quotas were not retuned after seeing the numbers.

## Invariants

- Sessions with != 50 unique question IDs: **$dupQuestionSessions**
- Coverage failures (not 4/5 with exactly two fives): **$coverageFailures**
- DROP / ineligible leaks: **$dropLeaks**
- Archive DROP IDs: **${dropIds.length}**
- Selectable IDs tracked: **${selectableIds.length}**

## Extra-slot distribution (dimension received 5 questions)

Expected if uniform: ${(sessions * 2 / 12).toStringAsFixed(2)} per dimension.

min extra=${extraVals.first}, max extra=${extraVals.last}, mean=${extraMean.toStringAsFixed(2)}

$extraRowsText

## Question selection frequency (among 405 selectable)

- min: **$minF**
- max: **$maxF**
- mean: **${meanF.toStringAsFixed(3)}**
- questions ever selected: **${qFreq.values.where((n) => n > 0).length}**
- questions never selected: **${never.length}**
- questions selected in every session: **${always.length}**

$neverBlockText
$alwaysBlockText

## Option-position distribution (authored A/B/C/D vs display slot)

Total placements per slot: ${sessions * 50}

$slotRowsText

## Consecutive same-dimension

- adjacent pairs: $adjacentPairs
- adjacent same-primary pairs: $adjacentSame (${(100.0 * adjacentSame / adjacentPairs).toStringAsFixed(3)}%)
- sessions with at least one 2-streak: $sessionsWithTwoStreak
- max streak observed: $maxStreakSeen (cap is ${FrequencyBehaviorV2Contract.maxConsecutiveSamePrimary})

## Safety

- V2 not activated
- pool text / weights / evidence values not modified by this simulation
- no V1 / Firebase / C2 / Discover / Persona / matching / 12D→6D adapter

FREQUENCY V2 PHASE 3A DORMANT 50-QUESTION SELECTOR READY — V2 STILL DORMANT
''';

  File(outPath).writeAsStringSync(report);
  stdout.writeln(report.trimRight());
  stdout.writeln('wrote $outPath');
}
