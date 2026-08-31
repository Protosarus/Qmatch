// ignore_for_file: avoid_print
/// Phase 4B provisional confidence audit.
///
/// Does not activate V2. Does not modify pool, selector, weights, or evidence.
///
/// Usage:
///   dart run tool/frequency_behavior_v2/simulate_phase4b_confidence.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

const _patterns = [
  'HIGH_CONFIDENCE_CLEAN',
  'HIGH_CONFIDENCE_MODERATE_BEHAVIOR',
  'HIGH_PRESENTATION_PRESSURE',
  'LOW_EVIDENCE',
  'CONTEXT_SENSITIVE',
  'NO_CROSS_CONTEXT',
  'LOW_PRIMARY_OBSERVABILITY',
];

void main(List<String> args) {
  var outPath = FrequencyBehaviorV2Contract.phase4bConfidenceAuditRelativePath;
  var distSessions = 200;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out' && i + 1 < args.length) outPath = args[++i];
    if (args[i] == '--dist-sessions' && i + 1 < args.length) {
      distSessions = int.parse(args[++i]);
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

  const composer = FrequencyBehaviorV2SessionComposer();
  const scorer = FrequencyBehaviorV2Scorer();
  final manifest = composer.composeManifest(
    pool: pool,
    sessionSeed: 'phase4b-audit',
    reviewByItemId: review,
    nearDuplicateClusters: clusters,
  );

  final results = <String, FrequencyBehaviorV2ScoreResult>{};
  for (final pattern in _patterns) {
    results[pattern] = scorer.score(
      pool: pool,
      manifest: manifest,
      responses: _answersFor(pool, manifest, pattern),
      nearDuplicateClusters: clusters,
    );
  }
  final repeat = scorer.score(
    pool: pool,
    manifest: manifest,
    responses: _answersFor(pool, manifest, 'HIGH_CONFIDENCE_CLEAN'),
    nearDuplicateClusters: clusters,
  );
  final det = jsonEncode(results['HIGH_CONFIDENCE_CLEAN']!.toJson()) ==
      jsonEncode(repeat.toJson());

  final dist = <double>[];
  for (var n = 0; n < distSessions; n++) {
    final m = composer.composeManifest(
      pool: pool,
      sessionSeed: 'phase4b-dist-$n',
      reviewByItemId: review,
      nearDuplicateClusters: clusters,
    );
    final scored = scorer.score(
      pool: pool,
      manifest: m,
      responses: _answersFor(pool, m, 'HIGH_CONFIDENCE_CLEAN'),
      nearDuplicateClusters: clusters,
    );
    for (final d in scored.dimensionScores) {
      if (d.provisionalConfidence != null) dist.add(d.provisionalConfidence!);
    }
  }
  dist.sort();
  final buckets = List<int>.filled(5, 0);
  for (final v in dist) {
    final i = v >= 1.0 ? 4 : (v / 0.2).floor().clamp(0, 4);
    buckets[i]++;
  }

  final buf = StringBuffer();
  buf.writeln(
      '# Frequency V2 Phase 4B — Provisional dimension confidence audit');
  buf.writeln('');
  buf.writeln(
    'Status: **offline / dormant**. `runtime_selectable` remains false.',
  );
  buf.writeln(
    'Confidence model: `${FrequencyBehaviorV2Contract.confidenceModelVersion}`',
  );
  buf.writeln('Scorer: `${FrequencyBehaviorV2Contract.scorerVersion}`');
  buf.writeln('Session seed: `phase4b-audit`');
  buf.writeln('Session id: `${manifest.sessionId}`');
  buf.writeln('');
  buf.writeln(
    'This is an engineering heuristic. Coefficients and flag thresholds were '
    '**not** retuned after seeing the distribution. '
    '`signal_utilization` is not an input. Behavioral direction is unchanged.',
  );
  buf.writeln('');
  buf.writeln('## Invariants');
  buf.writeln('');
  buf.writeln('- Deterministic HIGH_CONFIDENCE_CLEAN JSON repeat: **$det**');
  buf.writeln(
      '- All named patterns `ok`: **${results.values.every((r) => r.ok)}**');
  buf.writeln('');

  for (final pattern in _patterns) {
    final r = results[pattern]!;
    buf.writeln('### $pattern');
    buf.writeln('');
    buf.writeln(_blurb(pattern));
    buf.writeln('');
    buf.writeln(
      '| dimension | norm | eq | obs | cons | cov | pressure | prov | complete | flags |',
    );
    buf.writeln('|---|---:|---:|---:|---:|---:|---:|---:|---:|---|');
    for (final d in r.dimensionScores) {
      buf.writeln(
        '| `${d.dimensionId}` | ${_n(d.normalizedBehavior)} | '
        '${_n(d.evidenceQuality)} | ${_n(d.primaryObservability)} | '
        '${_n(d.crossContextConsistency)} | ${_n(d.crossContextCoverage)} | '
        '${_n(d.presentationPressure)} | ${_n(d.provisionalConfidence)} | '
        '${_n(d.confidenceCompleteness)} | '
        '${d.confidenceFlags.isEmpty ? '—' : d.confidenceFlags.join(", ")} |',
      );
    }
    buf.writeln('');
    buf.writeln(_observe(pattern, r));
    buf.writeln('');
  }

  buf.writeln('## Synthetic NO_CROSS_CONTEXT (same-cluster mini session)');
  buf.writeln('');
  buf.writeln(
    'The live 50-question bank can still yield eligible cross-context pairs. '
    'This mini session forces one cluster so missing context is not stored as 0.',
  );
  buf.writeln('');
  final synth = _syntheticNoCrossContext();
  final sd = synth.scoreFor('contact_need')!;
  buf.writeln(
    '- `normalized_behavior`: ${_n(sd.normalizedBehavior)} (weights only)',
  );
  buf.writeln(
      '- `cross_context_consistency`: ${_n(sd.crossContextConsistency)}');
  buf.writeln('- `context_component`: ${_n(sd.contextComponent)}');
  buf.writeln('- `provisional_confidence`: ${_n(sd.provisionalConfidence)}');
  buf.writeln('- `confidence_completeness`: ${_n(sd.confidenceCompleteness)}');
  buf.writeln('- flags: ${sd.confidenceFlags.join(", ")}');
  buf.writeln('');

  buf.writeln(
    '## Provisional confidence distribution (`HIGH_CONFIDENCE_CLEAN`, '
    '$distSessions seeds × 12 dimensions)',
  );
  buf.writeln('');
  buf.writeln('- n: **${dist.length}**');
  buf.writeln('- min: **${dist.first.toStringAsFixed(3)}**');
  buf.writeln('- median: **${_median(dist).toStringAsFixed(3)}**');
  buf.writeln(
    '- mean: **${(dist.fold<double>(0, (a, b) => a + b) / dist.length).toStringAsFixed(3)}**',
  );
  buf.writeln('- max: **${dist.last.toStringAsFixed(3)}**');
  buf.writeln('');
  buf.writeln('| bucket | count | pct |');
  buf.writeln('|---|---:|---:|');
  const labels = [
    '[0.0, 0.2)',
    '[0.2, 0.4)',
    '[0.4, 0.6)',
    '[0.6, 0.8)',
    '[0.8, 1.0]'
  ];
  for (var i = 0; i < 5; i++) {
    final pct = 100.0 * buckets[i] / dist.length;
    buf.writeln('| ${labels[i]} | ${buckets[i]} | ${pct.toStringAsFixed(2)} |');
  }
  buf.writeln('');
  buf.writeln('## Safety');
  buf.writeln('');
  buf.writeln(
      '- V2 not activated; selector / weights / evidence priors unchanged');
  buf.writeln('- no global Frequency score, percentile, or lie detection');
  buf.writeln('- confidence is not called scientifically calibrated');
  buf.writeln('');
  buf.writeln(
    'FREQUENCY V2 PHASE 4B PROVISIONAL DIMENSION CONFIDENCE MODEL READY — V2 STILL DORMANT',
  );

  File(outPath).writeAsStringSync(buf.toString());
  stdout.writeln(buf.toString().trimRight());
  stdout.writeln('wrote $outPath');
}

String _n(double? v) => v == null ? 'null' : v.toStringAsFixed(3);

double _median(List<double> sorted) {
  final n = sorted.length;
  if (n.isOdd) return sorted[n ~/ 2];
  return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0;
}

String _blurb(String pattern) {
  switch (pattern) {
    case 'HIGH_CONFIDENCE_CLEAN':
      return 'Max primary-dimension weight on every presented question.';
    case 'HIGH_CONFIDENCE_MODERATE_BEHAVIOR':
      return 'Prefer authored ±1 primary weights (moderate utilization, not a confidence input).';
    case 'HIGH_PRESENTATION_PRESSURE':
      return 'Highest authored `self_presentation_risk` per question.';
    case 'LOW_EVIDENCE':
      return 'Lowest authored `diagnostic_value` per question.';
    case 'CONTEXT_SENSITIVE':
      return 'Alternate max/min primary weight within each dimension (`question_id` order).';
    case 'NO_CROSS_CONTEXT':
      return 'Same max-primary answers as CLEAN. Dimensions whose presented primaries share one cluster show null consistency.';
    case 'LOW_PRIMARY_OBSERVABILITY':
      return 'Prefer options with no primary weight, then 0, then smallest |primary|.';
    default:
      return '';
  }
}

String _observe(String pattern, FrequencyBehaviorV2ScoreResult r) {
  final prov = [
    for (final d in r.dimensionScores)
      if (d.provisionalConfidence != null) d.provisionalConfidence!,
  ];
  final minP = prov.isEmpty ? null : prov.reduce((a, b) => a < b ? a : b);
  final maxP = prov.isEmpty ? null : prov.reduce((a, b) => a > b ? a : b);
  final nullCtx =
      r.dimensionScores.where((d) => d.contextComponent == null).length;
  switch (pattern) {
    case 'HIGH_CONFIDENCE_CLEAN':
      return 'provisional_confidence ${_n(minP)} … ${_n(maxP)}. '
          'Dimensions with unavailable context: $nullCtx (completeness 0.80 there).';
    case 'HIGH_CONFIDENCE_MODERATE_BEHAVIOR':
      return 'Utilization is lower than CLEAN where ±1 is available; confidence is not driven by |weight|.';
    case 'HIGH_PRESENTATION_PRESSURE':
      return 'Presentation means are elevated by construction. '
          '`normalized_behavior` still follows those options’ weights. Max authored discount is 20%.';
    case 'LOW_EVIDENCE':
      return 'Diagnostic means are lowered by construction. Direction still comes from weights.';
    case 'CONTEXT_SENSITIVE':
      return 'Eligible consistency drops where max/min primaries disagree across clusters. '
          'That is a flag, not a reversal of `normalized_behavior`.';
    case 'NO_CROSS_CONTEXT':
      return 'Null consistency is completeness 0.80 + `LIMITED_CROSS_CONTEXT`, not confidence 0.';
    case 'LOW_PRIMARY_OBSERVABILITY':
      return 'Zero primary signal is “not expressing the named axis.” Secondary weights may still move other dimensions.';
    default:
      return '';
  }
}

FrequencyBehaviorV2ScoreResult _syntheticNoCrossContext() {
  const dim = 'contact_need';
  final meta = FrequencyBehaviorV2EvidenceMeta(
    reviewStatus: FrequencyBehaviorV2Contract.evidenceReviewReviewed,
    diagnosticValue: 1,
    behavioralPlausibility: 1,
    ambiguity: 0,
    socialDesirability: 0,
    obviousness: 0,
    selfPresentationRisk: 0,
  );
  const letters = ['a', 'b', 'c', 'd'];
  final items = [
    for (var i = 0; i < 4; i++)
      FrequencyBehaviorV2Item(
        itemId: 'syn$i',
        locale: FrequencyBehaviorV2Contract.localeTr,
        prompt: 's',
        context: const ['t'],
        primaryDimensions: const [dim],
        secondaryDimensions: const [],
        semanticCluster: 'only',
        crosscheckGroupIds: const [],
        options: [
          for (var k = 0; k < 4; k++)
            FrequencyBehaviorV2Option(
              optionId: 'syn$i${letters[k]}',
              text: 't',
              behavioralWeights: {
                dim: [2.0, 1.0, -1.0, -2.0][k],
              },
              evidenceMeta: meta,
            ),
        ],
      ),
  ];
  return const FrequencyBehaviorV2Scorer().score(
    pool: FrequencyBehaviorV2PoolDocument(
      schemaVersion: FrequencyBehaviorV2Contract.schemaVersion,
      poolVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
      scoringPolicyVersion: FrequencyBehaviorV2Contract.scoringPolicyVersion,
      locale: FrequencyBehaviorV2Contract.localeTr,
      status: FrequencyBehaviorV2Contract.statusDraftNotRuntime,
      runtimeSelectable: false,
      items: items,
    ),
    responses: [
      for (final i in items)
        FrequencyBehaviorV2Response(itemId: i.itemId, optionId: '${i.itemId}a'),
    ],
  );
}

List<FrequencyBehaviorV2Response> _answersFor(
  FrequencyBehaviorV2PoolDocument pool,
  FrequencyBehaviorV2SessionManifest manifest,
  String pattern,
) {
  final indexInDim = <String, int>{
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: 0,
  };
  final ordered = [...manifest.questions]
    ..sort((a, b) => a.questionId.compareTo(b.questionId));
  final mixedIndex = <String, int>{};
  for (final q in ordered) {
    mixedIndex[q.questionId] = indexInDim[q.primaryDimension]!;
    indexInDim[q.primaryDimension] = indexInDim[q.primaryDimension]! + 1;
  }
  return [
    for (final q in manifest.questions)
      FrequencyBehaviorV2Response(
        itemId: q.questionId,
        optionId: _pick(
          pool.itemsById[q.questionId]!,
          pattern,
          mixedIndex[q.questionId]!,
        ).optionId,
      ),
  ];
}

FrequencyBehaviorV2Option _pick(
  FrequencyBehaviorV2Item item,
  String pattern,
  int indexInPrimaryDim,
) {
  final primary = item.primaryDimensions.single;
  switch (pattern) {
    case 'HIGH_CONFIDENCE_CLEAN':
    case 'NO_CROSS_CONTEXT':
      return _bestByWeight(item, primary, maximize: true);
    case 'HIGH_CONFIDENCE_MODERATE_BEHAVIOR':
      return _pickModerate(item, primary);
    case 'HIGH_PRESENTATION_PRESSURE':
      return _bestByEvidence(item, (m) => m.selfPresentationRisk,
          maximize: true);
    case 'LOW_EVIDENCE':
      return _bestByEvidence(item, (m) => m.diagnosticValue, maximize: false);
    case 'CONTEXT_SENSITIVE':
      return _bestByWeight(item, primary, maximize: indexInPrimaryDim.isEven);
    case 'LOW_PRIMARY_OBSERVABILITY':
      return _pickLowPrimary(item, primary);
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

FrequencyBehaviorV2Option _pickModerate(
  FrequencyBehaviorV2Item item,
  String dim,
) {
  FrequencyBehaviorV2Option? plus1;
  FrequencyBehaviorV2Option? minus1;
  for (final o in item.options) {
    final w = o.behavioralWeights[dim];
    if (w == 1.0) {
      if (plus1 == null || o.optionId.compareTo(plus1.optionId) < 0) plus1 = o;
    } else if (w == -1.0) {
      if (minus1 == null || o.optionId.compareTo(minus1.optionId) < 0) {
        minus1 = o;
      }
    }
  }
  return plus1 ?? minus1 ?? _bestByWeight(item, dim, maximize: true);
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
      if (zero == null || o.optionId.compareTo(zero.optionId) < 0) zero = o;
      continue;
    }
    final a = w.abs();
    if (small == null ||
        a < smallAbs ||
        (a == smallAbs && o.optionId.compareTo(small.optionId) < 0)) {
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
