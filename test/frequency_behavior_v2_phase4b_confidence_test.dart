import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

FrequencyBehaviorV2EvidenceMeta _meta({
  double diagnosticValue = 1.0,
  double behavioralPlausibility = 1.0,
  double ambiguity = 0.0,
  double socialDesirability = 0.0,
  double obviousness = 0.0,
  double selfPresentationRisk = 0.0,
}) {
  return FrequencyBehaviorV2EvidenceMeta(
    reviewStatus: FrequencyBehaviorV2Contract.evidenceReviewReviewed,
    diagnosticValue: diagnosticValue,
    behavioralPlausibility: behavioralPlausibility,
    ambiguity: ambiguity,
    socialDesirability: socialDesirability,
    obviousness: obviousness,
    selfPresentationRisk: selfPresentationRisk,
  );
}

List<FrequencyBehaviorV2EvidenceMeta> _four(
        FrequencyBehaviorV2EvidenceMeta m) =>
    [m, m, m, m];

FrequencyBehaviorV2Item _item({
  required String id,
  required String primary,
  required String cluster,
  required List<Map<String, double>> weights,
  required List<FrequencyBehaviorV2EvidenceMeta> evidence,
}) {
  const letters = ['a', 'b', 'c', 'd'];
  return FrequencyBehaviorV2Item(
    itemId: id,
    locale: FrequencyBehaviorV2Contract.localeTr,
    prompt: 'prompt $id',
    context: const ['test'],
    primaryDimensions: [primary],
    secondaryDimensions: const [],
    semanticCluster: cluster,
    crosscheckGroupIds: const [],
    options: [
      for (var i = 0; i < 4; i++)
        FrequencyBehaviorV2Option(
          optionId: '${id}_${letters[i]}',
          text: 'opt $i',
          behavioralWeights: weights[i],
          evidenceMeta: evidence[i],
        ),
    ],
  );
}

FrequencyBehaviorV2PoolDocument _pool(List<FrequencyBehaviorV2Item> items) {
  return FrequencyBehaviorV2PoolDocument(
    schemaVersion: FrequencyBehaviorV2Contract.schemaVersion,
    poolVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    scoringPolicyVersion: FrequencyBehaviorV2Contract.scoringPolicyVersion,
    locale: FrequencyBehaviorV2Contract.localeTr,
    status: FrequencyBehaviorV2Contract.statusDraftNotRuntime,
    runtimeSelectable: false,
    items: items,
  );
}

List<Map<String, double>> _ladder(String dim) => [
      {dim: 2.0},
      {dim: 1.0},
      {dim: -1.0},
      {dim: -2.0},
    ];

void main() {
  const scorer = FrequencyBehaviorV2Scorer();
  const dim = 'contact_need';

  FrequencyBehaviorV2ScoreResult score(
    List<FrequencyBehaviorV2Item> items,
    List<String> suffixes, {
    List<List<String>> nearDup = const [],
  }) {
    return scorer.score(
      pool: _pool(items),
      nearDuplicateClusters: nearDup,
      responses: [
        for (var i = 0; i < items.length; i++)
          FrequencyBehaviorV2Response(
            itemId: items[i].itemId,
            optionId: '${items[i].itemId}_${suffixes[i]}',
          ),
      ],
    );
  }

  List<FrequencyBehaviorV2Item> clustered({
    required FrequencyBehaviorV2EvidenceMeta meta,
    int n = 4,
    String Function(int i)? clusterOf,
  }) {
    return [
      for (var i = 0; i < n; i++)
        _item(
          id: 'q$i',
          primary: dim,
          cluster: clusterOf?.call(i) ?? 'cluster_$i',
          weights: _ladder(dim),
          evidence: _four(meta),
        ),
    ];
  }

  test('perfect evidence / observability / cross-context', () {
    final d =
        score(clustered(meta: _meta()), ['a', 'a', 'a', 'a']).scoreFor(dim)!;
    expect(d.normalizedBehavior, 1.0);
    expect(d.semanticClarity, 1.0);
    expect(d.evidenceQuality, 1.0);
    expect(d.primaryObservability, 1.0);
    expect(d.contextComponent, 1.0);
    expect(d.presentationPressure, 0.0);
    expect(d.presentationAdjustment, 1.0);
    expect(d.baseConfidence, 1.0);
    expect(d.provisionalConfidence, 1.0);
    expect(d.confidenceCompleteness, 1.0);
    expect(d.confidenceFlags, isEmpty);
  });

  test('context unavailable renormalizes and sets completeness 0.80', () {
    final d = score(
      clustered(meta: _meta(), clusterOf: (_) => 'only'),
      ['a', 'a', 'a', 'a'],
    ).scoreFor(dim)!;
    expect(d.crossContextConsistency, isNull);
    expect(d.contextComponent, isNull);
    expect(d.normalizedBehavior, 1.0);
    expect(d.baseConfidence, 1.0);
    expect(d.provisionalConfidence, 1.0);
    expect(d.confidenceCompleteness, 0.80);
    expect(
      d.confidenceFlags,
      [FrequencyBehaviorV2Contract.flagLimitedCrossContext],
    );
  });

  test('high presentation pressure discounts at most 20% and does not reverse',
      () {
    final d = score(
      clustered(
        meta: _meta(
          socialDesirability: 1.0,
          obviousness: 1.0,
          selfPresentationRisk: 1.0,
        ),
      ),
      ['a', 'a', 'a', 'a'],
    ).scoreFor(dim)!;
    expect(d.normalizedBehavior, 1.0);
    expect(d.presentationPressure, 1.0);
    expect(d.presentationAdjustment, 0.80);
    expect(d.baseConfidence, 1.0);
    expect(d.provisionalConfidence, 0.80);
    expect(
      d.confidenceFlags,
      [FrequencyBehaviorV2Contract.flagHighPresentationPressure],
    );
  });

  test('low diagnostic value and high ambiguity lower evidence quality', () {
    final low = score(
      clustered(
        meta: _meta(
          diagnosticValue: 0.0,
          behavioralPlausibility: 0.0,
          ambiguity: 1.0,
        ),
      ),
      ['a', 'a', 'a', 'a'],
    ).scoreFor(dim)!;
    expect(low.normalizedBehavior, 1.0);
    expect(low.semanticClarity, 0.0);
    expect(low.evidenceQuality, 0.0);
    expect(low.baseConfidence, 0.50);
    expect(low.provisionalConfidence, 0.50);
    expect(
      low.confidenceFlags,
      [FrequencyBehaviorV2Contract.flagLowEvidenceQuality],
    );

    final ambOnly = score(
      clustered(meta: _meta(ambiguity: 1.0)),
      ['a', 'a', 'a', 'a'],
    ).scoreFor(dim)!;
    expect(ambOnly.evidenceQuality, closeTo(2 / 3, 1e-12));
    expect(ambOnly.confidenceFlags, isEmpty);
  });

  test('low primary observability flags without erasing direction', () {
    final items = [
      for (var i = 0; i < 4; i++)
        _item(
          id: 'q$i',
          primary: dim,
          cluster: 'cluster_$i',
          weights: i == 0
              ? _ladder(dim)
              : [
                  {'autonomy': 1.0},
                  {dim: 2.0},
                  {dim: -1.0},
                  {dim: -2.0},
                ],
          evidence: _four(_meta()),
        ),
    ];
    final d = score(items, ['a', 'a', 'a', 'a']).scoreFor(dim)!;
    expect(d.primaryObservability, 0.25);
    expect(d.normalizedBehavior, closeTo(0.25, 1e-12));
    expect(
      d.confidenceFlags,
      contains(FrequencyBehaviorV2Contract.flagLowPrimaryObservability),
    );
  });

  test('low cross-context consistency is CONTEXT_SENSITIVE', () {
    final d =
        score(clustered(meta: _meta()), ['a', 'a', 'd', 'd']).scoreFor(dim)!;
    expect(d.crossContextCoverage, 1.0);
    expect(d.crossContextConsistency, lessThan(0.50));
    expect(d.signalUtilization, 1.0);
    expect(
      d.confidenceFlags,
      [FrequencyBehaviorV2Contract.flagContextSensitive],
    );
    expect(
      d.confidenceFlags,
      isNot(contains(FrequencyBehaviorV2Contract.flagLimitedCrossContext)),
    );
  });

  test('low cross-context coverage is LIMITED, consistency stays null', () {
    final d = score(
      clustered(meta: _meta(), n: 2),
      ['a', 'd'],
      nearDup: const [
        ['q0', 'q1'],
      ],
    ).scoreFor(dim)!;
    expect(d.crossContextConsistency, isNull);
    expect(d.crossContextCoverage, 0.0);
    expect(d.contextComponent, isNull);
    expect(d.confidenceCompleteness, 0.80);
    expect(
      d.confidenceFlags,
      [FrequencyBehaviorV2Contract.flagLimitedCrossContext],
    );
  });

  test('moderate ±1 with high consistency matches ±2 confidence', () {
    final plus1 =
        score(clustered(meta: _meta()), ['b', 'b', 'b', 'b']).scoreFor(dim)!;
    final plus2 =
        score(clustered(meta: _meta()), ['a', 'a', 'a', 'a']).scoreFor(dim)!;
    expect(plus1.signalUtilization, 0.5);
    expect(plus2.signalUtilization, 1.0);
    expect(plus1.normalizedBehavior, 0.5);
    expect(plus2.normalizedBehavior, 1.0);
    expect(plus1.provisionalConfidence, plus2.provisionalConfidence);
    expect(plus1.crossContextConsistency, 1.0);
    expect(plus2.crossContextConsistency, 1.0);
  });

  test('same behavior vector with different evidence changes only confidence',
      () {
    final clean =
        score(clustered(meta: _meta()), ['a', 'a', 'a', 'a']).scoreFor(dim)!;
    final pressured = score(
      clustered(
        meta: _meta(
          diagnosticValue: 0.25,
          behavioralPlausibility: 0.25,
          ambiguity: 0.75,
          socialDesirability: 1.0,
          obviousness: 1.0,
          selfPresentationRisk: 1.0,
        ),
      ),
      ['a', 'a', 'a', 'a'],
    ).scoreFor(dim)!;
    expect(pressured.rawSum, clean.rawSum);
    expect(pressured.capacity, clean.capacity);
    expect(pressured.normalizedBehavior, clean.normalizedBehavior);
    expect(pressured.primarySignalCoverage, clean.primarySignalCoverage);
    expect(pressured.provisionalConfidence, isNot(clean.provisionalConfidence));
    expect(pressured.provisionalConfidence,
        lessThan(clean.provisionalConfidence!));
  });

  test('same manifest + answers is deterministic including confidence', () {
    final items = clustered(meta: _meta());
    final pool = _pool(items);
    final manifest = FrequencyBehaviorV2SessionManifest(
      schemaVersion: FrequencyBehaviorV2Contract.sessionManifestSchemaVersion,
      selectorVersion: FrequencyBehaviorV2Contract.selectorVersion,
      bankVersion: pool.poolVersion,
      sessionId: 'frequency_v2_conf',
      sessionSeed: 'phase4b-det',
      locale: pool.locale,
      questionIds: [for (final i in items) i.itemId],
      questions: [
        for (var i = 0; i < items.length; i++)
          FrequencyBehaviorV2SessionQuestion(
            questionId: items[i].itemId,
            primaryDimension: dim,
            presentationIndex: i,
            presentedOptionOrder: [
              for (final o in items[i].options) o.optionId
            ],
          ),
      ],
    );
    final responses = [
      for (final i in items)
        FrequencyBehaviorV2Response(
            itemId: i.itemId, optionId: '${i.itemId}_b'),
    ];
    final a = scorer.score(
      pool: pool,
      manifest: manifest,
      responses: responses,
    );
    final b = scorer.score(
      pool: pool,
      manifest: manifest,
      responses: responses,
    );
    expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
    expect(
      a.confidenceModelVersion,
      FrequencyBehaviorV2Contract.confidenceModelVersion,
    );
    expect(pool.runtimeSelectable, isFalse);
  });

  test('phase 4B audit report exists and stays dormant', () {
    final report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.phase4bConfidenceAuditRelativePath}',
    ).readAsStringSync();
    expect(report.contains('HIGH_CONFIDENCE_CLEAN'), isTrue);
    expect(report.contains('HIGH_CONFIDENCE_MODERATE_BEHAVIOR'), isTrue);
    expect(report.contains('HIGH_PRESENTATION_PRESSURE'), isTrue);
    expect(report.contains('LOW_EVIDENCE'), isTrue);
    expect(report.contains('CONTEXT_SENSITIVE'), isTrue);
    expect(report.contains('NO_CROSS_CONTEXT'), isTrue);
    expect(report.contains('LOW_PRIMARY_OBSERVABILITY'), isTrue);
    expect(
      report.contains(
        'FREQUENCY V2 PHASE 4B PROVISIONAL DIMENSION CONFIDENCE MODEL READY — V2 STILL DORMANT',
      ),
      isTrue,
    );
  });
}
