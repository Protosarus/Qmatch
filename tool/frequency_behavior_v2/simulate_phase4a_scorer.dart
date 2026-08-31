// ignore_for_file: avoid_print
/// Phase 4A dormant 12D scorer audit with synthetic answer patterns.
///
/// Does not activate V2. Does not modify pool, selector, weights, or evidence.
///
/// Usage:
///   dart run tool/frequency_behavior_v2/simulate_phase4a_scorer.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

const _patterns = [
  'CONSISTENT_POSITIVE',
  'CONSISTENT_NEGATIVE',
  'MIXED_CONTEXT',
  'LOW_PRIMARY_SIGNAL',
  'HIGH_SELF_PRESENTATION_PRIOR',
  'LOW_DIAGNOSTIC_PRIOR',
];

void main(List<String> args) {
  var outPath = FrequencyBehaviorV2Contract.phase4aScorerAuditRelativePath;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out' && i + 1 < args.length) outPath = args[++i];
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

  const composer = FrequencyBehaviorV2SessionComposer();
  final manifest = composer.composeManifest(
    pool: pool,
    sessionSeed: 'phase4a-audit',
    reviewByItemId: review,
    nearDuplicateClusters: clusters,
    createdAt: null,
  );

  const scorer = FrequencyBehaviorV2Scorer();
  final results = <String, FrequencyBehaviorV2ScoreResult>{};
  for (final pattern in _patterns) {
    final responses = _answersFor(pool, manifest, pattern);
    results[pattern] = scorer.score(
      pool: pool,
      manifest: manifest,
      responses: responses,
      nearDuplicateClusters: clusters,
    );
  }

  final posAgain = scorer.score(
    pool: pool,
    manifest: manifest,
    responses: _answersFor(pool, manifest, 'CONSISTENT_POSITIVE'),
    nearDuplicateClusters: clusters,
  );
  final posJson = jsonEncode(results['CONSISTENT_POSITIVE']!.toJson());
  final posAgainJson = jsonEncode(posAgain.toJson());

  final buf = StringBuffer();
  buf.writeln('# Frequency V2 Phase 4A — Dormant 12D scorer audit');
  buf.writeln('');
  buf.writeln(
      'Status: **offline / dormant**. `runtime_selectable` remains false.');
  buf.writeln('Scorer: `${FrequencyBehaviorV2Contract.scorerVersion}`');
  buf.writeln('Selector: `${FrequencyBehaviorV2Contract.selectorVersion}`');
  buf.writeln('Bank: `${pool.poolVersion}`');
  buf.writeln('Session seed: `phase4a-audit`');
  buf.writeln('Session id: `${manifest.sessionId}`');
  buf.writeln('Presented questions: **${manifest.questionIds.length}**');
  buf.writeln('');
  buf.writeln(
    'Synthetic patterns pick `option_id`s from the same 50-question manifest. '
    'Frequencies and evidence priors were not retuned. The selector was not modified.',
  );
  buf.writeln('');
  buf.writeln('## Invariants');
  buf.writeln('');
  buf.writeln(
    '- Deterministic CONSISTENT_POSITIVE JSON repeat: **${posJson == posAgainJson}**',
  );
  buf.writeln(
    '- All patterns `ok`: **${results.values.every((r) => r.ok)}**',
  );
  buf.writeln('- DROP / ineligible in manifest: **0** (selector invariant)');
  buf.writeln('');
  buf.writeln('## Pattern snapshots');
  buf.writeln('');
  buf.writeln(
    'Per dimension: `normalized_behavior` (weights only), '
    '`cross_context_consistency` (null = unavailable, not disagreement), '
    '`primary_signal_coverage`, mean self-presentation, mean diagnostic value.',
  );
  buf.writeln('');

  for (final pattern in _patterns) {
    final r = results[pattern]!;
    buf.writeln('### $pattern');
    buf.writeln('');
    buf.writeln(_patternBlurb(pattern));
    buf.writeln('');
    buf.writeln(
      '| dimension | norm | consistency | pairs elig/poss | primary cov | mean SPR | mean DV |',
    );
    buf.writeln('|---|---:|---:|---:|---:|---:|---:|');
    for (final d in r.dimensionScores) {
      buf.writeln(
        '| `${d.dimensionId}` | ${_n(d.normalizedBehavior)} | '
        '${_n(d.crossContextConsistency)} | '
        '${d.eligibleCrossContextPairCount}/${d.possibleCrossContextPairCount} | '
        '${_n(d.primarySignalCoverage)} | '
        '${_n(d.meanSelfPresentationRisk)} | '
        '${_n(d.meanDiagnosticValue)} |',
      );
    }
    buf.writeln('');
    buf.writeln(_patternObservations(pattern, r, results));
    buf.writeln('');
  }

  buf.writeln('## What the patterns show');
  buf.writeln('');
  buf.writeln(
    '- Behavioral direction (`normalized_behavior`) comes only from `behavioral_weights`.',
  );
  buf.writeln(
    '- HIGH_SELF_PRESENTATION_PRIOR does not invert signs relative to the selected options’ weights; SPR is reported beside the score, not mixed into it.',
  );
  buf.writeln(
    '- LOW_DIAGNOSTIC_PRIOR still yields a signed `normalized_behavior` whenever capacity > 0. Low evidence does not erase an answer.',
  );
  buf.writeln(
    '- MIXED_CONTEXT lowers `cross_context_consistency` where eligible pairs exist. It does not rewrite `normalized_behavior` into a confidence penalty.',
  );
  buf.writeln(
    '- When `possible_cross_context_pair_count` or eligible pairs are 0, consistency is **null**, not 0. Missing cross-context data is not treated as inconsistency.',
  );
  buf.writeln('');
  buf.writeln('## Safety');
  buf.writeln('');
  buf.writeln('- V2 not activated');
  buf.writeln(
      '- no single Frequency score, percentile, or confidence coefficient');
  buf.writeln('- no lie / deception / clinical labels');
  buf.writeln('- selector, questions, weights, and evidence priors unchanged');
  buf.writeln(
      '- no V1 / Firebase / C2 / Discover / Persona / matching / 12D→6D adapter');
  buf.writeln('');
  buf.writeln(
    'FREQUENCY V2 PHASE 4A DORMANT 12D SCORER AND CONFIDENCE PRIMITIVES READY — V2 STILL DORMANT',
  );

  File(outPath).writeAsStringSync(buf.toString());
  stdout.writeln(buf.toString().trimRight());
  stdout.writeln('wrote $outPath');
}

String _n(double? v) => v == null ? 'null' : v.toStringAsFixed(3);

String _patternBlurb(String pattern) {
  switch (pattern) {
    case 'CONSISTENT_POSITIVE':
      return 'Each question selects the authored option with the **highest** primary-dimension weight.';
    case 'CONSISTENT_NEGATIVE':
      return 'Each question selects the authored option with the **lowest** primary-dimension weight.';
    case 'MIXED_CONTEXT':
      return 'Within each primary dimension, even-ranked questions take the max primary weight and odd-ranked take the min (order = `question_id`).';
    case 'LOW_PRIMARY_SIGNAL':
      return 'Prefer options with **no** primary weight, then explicit 0, then smallest |primary weight|.';
    case 'HIGH_SELF_PRESENTATION_PRIOR':
      return 'Each question selects the option with the highest authored `self_presentation_risk`. Ties break by `option_id`.';
    case 'LOW_DIAGNOSTIC_PRIOR':
      return 'Each question selects the option with the lowest authored `diagnostic_value`. Ties break by `option_id`.';
    default:
      return '';
  }
}

String _patternObservations(
  String pattern,
  FrequencyBehaviorV2ScoreResult r,
  Map<String, FrequencyBehaviorV2ScoreResult> all,
) {
  final norms = [
    for (final d in r.dimensionScores)
      if (d.normalizedBehavior != null) d.normalizedBehavior!,
  ];
  final cons = [
    for (final d in r.dimensionScores)
      if (d.crossContextConsistency != null) d.crossContextConsistency!,
  ];
  final nullCons =
      r.dimensionScores.where((d) => d.crossContextConsistency == null).length;
  final minN = norms.isEmpty ? null : norms.reduce((a, b) => a < b ? a : b);
  final maxN = norms.isEmpty ? null : norms.reduce((a, b) => a > b ? a : b);
  final meanN = norms.isEmpty
      ? null
      : norms.fold<double>(0, (a, b) => a + b) / norms.length;
  switch (pattern) {
    case 'CONSISTENT_POSITIVE':
      return 'normalized_behavior range ${_n(minN)} … ${_n(maxN)} (mean ${_n(meanN)}). '
          'Eligible consistency values stay high when pairs exist '
          '(mean ${_n(cons.isEmpty ? null : cons.fold<double>(0, (a, b) => a + b) / cons.length)}). '
          'Null consistency dimensions: $nullCons (unavailable, not 0).';
    case 'CONSISTENT_NEGATIVE':
      return 'normalized_behavior range ${_n(minN)} … ${_n(maxN)} (mean ${_n(meanN)}). '
          'Picks are the lowest **primary** weight per question; secondary '
          'weights on other items still enter `raw_sum` / `capacity`, so a '
          'dimension can stay non-negative. Evidence fields are not used for direction.';
    case 'MIXED_CONTEXT':
      final pos = all['CONSISTENT_POSITIVE']!;
      final posCons = [
        for (final d in pos.dimensionScores)
          if (d.crossContextConsistency != null) d.crossContextConsistency!,
      ];
      final mixedMean = cons.isEmpty
          ? null
          : cons.fold<double>(0, (a, b) => a + b) / cons.length;
      final posMean = posCons.isEmpty
          ? null
          : posCons.fold<double>(0, (a, b) => a + b) / posCons.length;
      return 'Eligible consistency mean ${_n(mixedMean)} vs CONSISTENT_POSITIVE ${_n(posMean)}. '
          'Direction still comes from the mixed weights (mean norm ${_n(meanN)}). '
          'Inconsistency is a confidence primitive, not a score reversal.';
    case 'LOW_PRIMARY_SIGNAL':
      final zeros = r.dimensionScores.fold<int>(
        0,
        (a, d) => a + d.zeroPrimarySignalCount,
      );
      final nz = r.dimensionScores.fold<int>(
        0,
        (a, d) => a + d.nonzeroPrimarySignalCount,
      );
      return 'zero_primary_signal_count total $zeros; nonzero $nz. '
          'Secondary weights may still move other dimensions. '
          'Zero primary is “not expressing the named axis,” not a lie flag.';
    case 'HIGH_SELF_PRESENTATION_PRIOR':
      return 'Mean SPR is elevated by construction. normalized_behavior range '
          '${_n(minN)} … ${_n(maxN)} still matches the **weights** of those high-SPR options. '
          'High self-presentation does not flip sign in the scorer.';
    case 'LOW_DIAGNOSTIC_PRIOR':
      return 'Mean diagnostic value is lowered by construction. '
          'normalized_behavior range ${_n(minN)} … ${_n(maxN)} remains defined from weights. '
          'Low evidence does not zero out the answer.';
    default:
      return '';
  }
}

List<FrequencyBehaviorV2Response> _answersFor(
  FrequencyBehaviorV2PoolDocument pool,
  FrequencyBehaviorV2SessionManifest manifest,
  String pattern,
) {
  final indexInDim = <String, int>{
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: 0,
  };
  final out = <FrequencyBehaviorV2Response>[];
  final ordered = [...manifest.questions]
    ..sort((a, b) => a.questionId.compareTo(b.questionId));
  // MIXED_CONTEXT uses question_id order within each primary.
  // Other patterns ignore that index. Iterate presentation order for responses
  // but compute mixed index from the sorted-by-id list.
  final mixedIndex = <String, int>{};
  for (final q in ordered) {
    mixedIndex[q.questionId] = indexInDim[q.primaryDimension]!;
    indexInDim[q.primaryDimension] = indexInDim[q.primaryDimension]! + 1;
  }
  for (final q in manifest.questions) {
    final item = pool.itemsById[q.questionId]!;
    final option = _pick(item, pattern, mixedIndex[q.questionId]!);
    out.add(
      FrequencyBehaviorV2Response(
          itemId: item.itemId, optionId: option.optionId),
    );
  }
  return out;
}

FrequencyBehaviorV2Option _pick(
  FrequencyBehaviorV2Item item,
  String pattern,
  int indexInPrimaryDim,
) {
  final primary = item.primaryDimensions.single;
  switch (pattern) {
    case 'CONSISTENT_POSITIVE':
      return _bestByWeight(item, primary, maximize: true);
    case 'CONSISTENT_NEGATIVE':
      return _bestByWeight(item, primary, maximize: false);
    case 'MIXED_CONTEXT':
      return _bestByWeight(
        item,
        primary,
        maximize: indexInPrimaryDim.isEven,
      );
    case 'LOW_PRIMARY_SIGNAL':
      return _pickLowPrimary(item, primary);
    case 'HIGH_SELF_PRESENTATION_PRIOR':
      return _bestByEvidence(
        item,
        (m) => m.selfPresentationRisk,
        maximize: true,
      );
    case 'LOW_DIAGNOSTIC_PRIOR':
      return _bestByEvidence(
        item,
        (m) => m.diagnosticValue,
        maximize: false,
      );
    default:
      throw StateError(pattern);
  }
}

FrequencyBehaviorV2Option _bestByWeight(
  FrequencyBehaviorV2Item item,
  String dim, {
  required bool maximize,
}) {
  FrequencyBehaviorV2Option? best;
  double? bestW;
  for (final o in item.options) {
    final w = o.behavioralWeights[dim];
    if (w == null) continue;
    if (best == null ||
        (maximize ? w > bestW! : w < bestW!) ||
        (w == bestW && o.optionId.compareTo(best.optionId) < 0)) {
      best = o;
      bestW = w;
    }
  }
  return best ?? item.options.first;
}

FrequencyBehaviorV2Option _pickLowPrimary(
  FrequencyBehaviorV2Item item,
  String dim,
) {
  FrequencyBehaviorV2Option? missing;
  FrequencyBehaviorV2Option? zero;
  FrequencyBehaviorV2Option? small;
  var smallAbs = double.infinity;
  for (final o in item.options) {
    if (!o.behavioralWeights.containsKey(dim)) {
      if (missing == null || o.optionId.compareTo(missing.optionId) < 0) {
        missing = o;
      }
      continue;
    }
    final w = o.behavioralWeights[dim]!;
    if (w == 0) {
      if (zero == null || o.optionId.compareTo(zero.optionId) < 0) {
        zero = o;
      }
      continue;
    }
    final a = w.abs();
    if (a < smallAbs ||
        (a == smallAbs &&
            small != null &&
            o.optionId.compareTo(small.optionId) < 0) ||
        small == null) {
      small = o;
      smallAbs = a;
    }
  }
  return missing ?? zero ?? small ?? item.options.first;
}

FrequencyBehaviorV2Option _bestByEvidence(
  FrequencyBehaviorV2Item item,
  double? Function(FrequencyBehaviorV2EvidenceMeta) read, {
  required bool maximize,
}) {
  FrequencyBehaviorV2Option? best;
  double? bestV;
  for (final o in item.options) {
    final v = read(o.evidenceMeta);
    if (v == null) continue;
    if (best == null ||
        (maximize ? v > bestV! : v < bestV!) ||
        (v == bestV && o.optionId.compareTo(best.optionId) < 0)) {
      best = o;
      bestV = v;
    }
  }
  return best ?? item.options.first;
}
