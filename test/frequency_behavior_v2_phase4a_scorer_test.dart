import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

FrequencyBehaviorV2EvidenceMeta _meta({
  double diagnosticValue = 0.50,
  double behavioralPlausibility = 0.50,
  double ambiguity = 0.25,
  double socialDesirability = 0.50,
  double obviousness = 0.50,
  double selfPresentationRisk = 0.25,
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

FrequencyBehaviorV2Item _item({
  required String id,
  required String primary,
  required String cluster,
  required List<Map<String, double>> weights,
  List<FrequencyBehaviorV2EvidenceMeta>? evidence,
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
          evidenceMeta: evidence != null ? evidence[i] : _meta(),
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

List<Map<String, double>> _primaryLadder(String dim) => [
      {dim: 2.0},
      {dim: 1.0},
      {dim: -1.0},
      {dim: -2.0},
    ];

void main() {
  const scorer = FrequencyBehaviorV2Scorer();
  const dim = 'contact_need';
  const other = 'autonomy';

  FrequencyBehaviorV2ScoreResult score(
    List<FrequencyBehaviorV2Item> items,
    List<String> optionSuffixes, {
    List<List<String>> nearDup = const [],
  }) {
    final pool = _pool(items);
    return scorer.score(
      pool: pool,
      nearDuplicateClusters: nearDup,
      responses: [
        for (var i = 0; i < items.length; i++)
          FrequencyBehaviorV2Response(
            itemId: items[i].itemId,
            optionId: '${items[i].itemId}_${optionSuffixes[i]}',
          ),
      ],
    );
  }

  test('all +2 primary signals normalize to +1 with full consistency', () {
    final items = [
      for (var i = 0; i < 4; i++)
        _item(
          id: 'q$i',
          primary: dim,
          cluster: 'cluster_$i',
          weights: _primaryLadder(dim),
        ),
    ];
    final r = score(items, ['a', 'a', 'a', 'a']);
    expect(r.ok, isTrue);
    final d = r.scoreFor(dim)!;
    expect(d.rawSum, 8);
    expect(d.capacity, 8);
    expect(d.normalizedBehavior, 1.0);
    expect(d.primaryQuestionCount, 4);
    expect(d.nonzeroPrimarySignalCount, 4);
    expect(d.zeroPrimarySignalCount, 0);
    expect(d.primarySignalCoverage, 1.0);
    expect(d.signalUtilization, 1.0);
    expect(d.crossContextConsistency, 1.0);
    expect(d.eligibleCrossContextPairCount, 6);
    expect(d.possibleCrossContextPairCount, 6);
    expect(d.crossContextCoverage, 1.0);
    expect(d.normalizedBehavior, inInclusiveRange(-1.0, 1.0));
  });

  test('all -2 primary signals normalize to -1 with full consistency', () {
    final items = [
      for (var i = 0; i < 4; i++)
        _item(
          id: 'q$i',
          primary: dim,
          cluster: 'cluster_$i',
          weights: _primaryLadder(dim),
        ),
    ];
    final r = score(items, ['d', 'd', 'd', 'd']);
    final d = r.scoreFor(dim)!;
    expect(d.rawSum, -8);
    expect(d.normalizedBehavior, -1.0);
    expect(d.crossContextConsistency, 1.0);
  });

  test('mixed +2 / +1 / -1 / -2 primary signals', () {
    final items = [
      for (var i = 0; i < 4; i++)
        _item(
          id: 'q$i',
          primary: dim,
          cluster: 'cluster_$i',
          weights: _primaryLadder(dim),
        ),
    ];
    final r = score(items, ['a', 'b', 'c', 'd']);
    final d = r.scoreFor(dim)!;
    expect(d.rawSum, 0);
    expect(d.capacity, 8);
    expect(d.normalizedBehavior, 0.0);
    expect(d.absoluteSelectedSignal, 6);
    expect(d.signalUtilization, closeTo(6 / 8, 1e-12));
    expect(d.nonzeroPrimarySignalCount, 4);
    // pairs: (2,1)=0.75 (2,-1)=0.25 (2,-2)=0 (1,-1)=0.50 (1,-2)=0.25 (-1,-2)=0.75
    expect(d.crossContextConsistency, closeTo(2.5 / 6, 1e-12));
  });

  test('selected option missing primary weight counts as zero signal', () {
    final item = _item(
      id: 'q0',
      primary: dim,
      cluster: 'c0',
      weights: [
        {other: 1.0},
        {dim: 2.0},
        {dim: -1.0},
        {dim: -2.0},
      ],
    );
    final r = score([item], ['a']);
    final d = r.scoreFor(dim)!;
    expect(d.rawSum, 0);
    expect(d.capacity, 2);
    expect(d.normalizedBehavior, 0.0);
    expect(d.primaryQuestionCount, 1);
    expect(d.nonzeroPrimarySignalCount, 0);
    expect(d.zeroPrimarySignalCount, 1);
    expect(d.primarySignalCoverage, 0.0);
    expect(r.scoreFor(other)!.rawSum, 1.0);
  });

  test('secondary behavioral weights contribute to their dimensions', () {
    final item = _item(
      id: 'q0',
      primary: 'initiative',
      cluster: 'c0',
      weights: [
        {'initiative': 1.0, 'repair_style': 2.0},
        {'initiative': 2.0},
        {'initiative': -1.0},
        {'initiative': -2.0, 'repair_style': -1.0},
      ],
    );
    final r = score([item], ['a']);
    expect(r.scoreFor('initiative')!.rawSum, 1.0);
    expect(r.scoreFor('initiative')!.capacity, 2.0);
    expect(r.scoreFor('initiative')!.normalizedBehavior, 0.5);
    expect(r.scoreFor('repair_style')!.rawSum, 2.0);
    expect(r.scoreFor('repair_style')!.capacity, 2.0);
    expect(r.scoreFor('repair_style')!.normalizedBehavior, 1.0);
    expect(r.scoreFor('repair_style')!.primaryQuestionCount, 0);
  });

  test('capacity uses max abs weight per question, not question count', () {
    final items = [
      _item(
        id: 'q0',
        primary: dim,
        cluster: 'c0',
        weights: _primaryLadder(dim),
      ),
      _item(
        id: 'q1',
        primary: dim,
        cluster: 'c1',
        weights: [
          {dim: 1.0},
          {dim: 0.0},
          {dim: -1.0},
          {other: 2.0},
        ],
      ),
    ];
    final r = score(items, ['b', 'a']);
    final d = r.scoreFor(dim)!;
    expect(d.rawSum, 2.0);
    expect(d.capacity, 3.0);
    expect(d.normalizedBehavior, closeTo(2 / 3, 1e-12));
  });

  test('cross-context identical signals => consistency 1.0', () {
    final items = [
      _item(
          id: 'q0', primary: dim, cluster: 'c0', weights: _primaryLadder(dim)),
      _item(
          id: 'q1', primary: dim, cluster: 'c1', weights: _primaryLadder(dim)),
    ];
    final d = score(items, ['a', 'a']).scoreFor(dim)!;
    expect(d.crossContextConsistency, 1.0);
    expect(d.eligibleCrossContextPairCount, 1);
  });

  test('cross-context opposite signals => consistency 0.0, not null', () {
    final items = [
      _item(
          id: 'q0', primary: dim, cluster: 'c0', weights: _primaryLadder(dim)),
      _item(
          id: 'q1', primary: dim, cluster: 'c1', weights: _primaryLadder(dim)),
    ];
    final d = score(items, ['a', 'd']).scoreFor(dim)!;
    expect(d.crossContextConsistency, 0.0);
    expect(d.eligibleCrossContextPairCount, 1);
  });

  test('cross-context mixed +2 vs +1 => 0.75', () {
    final items = [
      _item(
          id: 'q0', primary: dim, cluster: 'c0', weights: _primaryLadder(dim)),
      _item(
          id: 'q1', primary: dim, cluster: 'c1', weights: _primaryLadder(dim)),
    ];
    final d = score(items, ['a', 'b']).scoreFor(dim)!;
    expect(d.crossContextConsistency, 0.75);
  });

  test('same-cluster pairs are excluded from cross-context', () {
    final items = [
      _item(
          id: 'q0',
          primary: dim,
          cluster: 'same',
          weights: _primaryLadder(dim)),
      _item(
          id: 'q1',
          primary: dim,
          cluster: 'same',
          weights: _primaryLadder(dim)),
      _item(
          id: 'q2',
          primary: dim,
          cluster: 'other',
          weights: _primaryLadder(dim)),
    ];
    final d = score(items, ['a', 'd', 'a']).scoreFor(dim)!;
    expect(d.possibleCrossContextPairCount, 2);
    expect(d.eligibleCrossContextPairCount, 2);
    // (q0,q2)=1.0 and (q1,q2)=0.0
    expect(d.crossContextConsistency, 0.5);
  });

  test('near-duplicate pairs are excluded even across clusters', () {
    final items = [
      _item(
          id: 'q0', primary: dim, cluster: 'c0', weights: _primaryLadder(dim)),
      _item(
          id: 'q1', primary: dim, cluster: 'c1', weights: _primaryLadder(dim)),
    ];
    final d = score(
      items,
      ['a', 'd'],
      nearDup: const [
        ['q0', 'q1'],
      ],
    ).scoreFor(dim)!;
    expect(d.possibleCrossContextPairCount, 1);
    expect(d.eligibleCrossContextPairCount, 0);
    expect(d.crossContextConsistency, isNull);
    expect(d.crossContextCoverage, 0.0);
  });

  test('insufficient cross-context coverage is null, not zero', () {
    final sameCluster = [
      _item(
          id: 'q0',
          primary: dim,
          cluster: 'only',
          weights: _primaryLadder(dim)),
      _item(
          id: 'q1',
          primary: dim,
          cluster: 'only',
          weights: _primaryLadder(dim)),
    ];
    final same = score(sameCluster, ['a', 'd']).scoreFor(dim)!;
    expect(same.possibleCrossContextPairCount, 0);
    expect(same.eligibleCrossContextPairCount, 0);
    expect(same.crossContextConsistency, isNull);
    expect(same.crossContextCoverage, isNull);

    final one = score([
      _item(
          id: 'q0', primary: dim, cluster: 'c0', weights: _primaryLadder(dim)),
    ], [
      'a'
    ]).scoreFor(dim)!;
    expect(one.crossContextConsistency, isNull);
  });

  test('evidence metadata does not change normalized_behavior', () {
    List<FrequencyBehaviorV2Item> withSpr(double spr) => [
          _item(
            id: 'q0',
            primary: dim,
            cluster: 'c0',
            weights: _primaryLadder(dim),
            evidence: [
              _meta(selfPresentationRisk: spr, diagnosticValue: 0.0),
              _meta(selfPresentationRisk: spr, diagnosticValue: 1.0),
              _meta(selfPresentationRisk: spr),
              _meta(selfPresentationRisk: spr),
            ],
          ),
        ];
    final low = score(withSpr(0.0), ['a']).scoreFor(dim)!;
    final high = score(withSpr(1.0), ['a']).scoreFor(dim)!;
    expect(low.normalizedBehavior, high.normalizedBehavior);
    expect(low.rawSum, high.rawSum);
    expect(low.capacity, high.capacity);
    expect(low.meanSelfPresentationRisk, 0.0);
    expect(high.meanSelfPresentationRisk, 1.0);
    expect(low.meanDiagnosticValue, 0.0);
    expect(high.meanDiagnosticValue, 0.0);
  });

  test('same manifest + answers is bit-stable JSON', () {
    final items = [
      _item(
          id: 'q0', primary: dim, cluster: 'c0', weights: _primaryLadder(dim)),
      _item(
          id: 'q1', primary: dim, cluster: 'c1', weights: _primaryLadder(dim)),
    ];
    final pool = _pool(items);
    final manifest = FrequencyBehaviorV2SessionManifest(
      schemaVersion: FrequencyBehaviorV2Contract.sessionManifestSchemaVersion,
      selectorVersion: FrequencyBehaviorV2Contract.selectorVersion,
      bankVersion: pool.poolVersion,
      sessionId: 'frequency_v2_test',
      sessionSeed: 'phase4a-det',
      locale: pool.locale,
      questionIds: [for (final i in items) i.itemId],
      questions: [
        for (var i = 0; i < items.length; i++)
          FrequencyBehaviorV2SessionQuestion(
            questionId: items[i].itemId,
            primaryDimension: dim,
            presentationIndex: i,
            presentedOptionOrder: [
              for (final o in items[i].options) o.optionId,
            ],
          ),
      ],
    );
    final responses = [
      FrequencyBehaviorV2Response(itemId: 'q0', optionId: 'q0_b'),
      FrequencyBehaviorV2Response(itemId: 'q1', optionId: 'q1_c'),
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
    expect(a.ok, isTrue);
    expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
    expect(a.sessionId, 'frequency_v2_test');
    expect(a.scorerVersion, FrequencyBehaviorV2Contract.scorerVersion);
    expect(pool.runtimeSelectable, isFalse);
  });

  test('phase 4A audit report exists and stays dormant', () {
    final report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.phase4aScorerAuditRelativePath}',
    ).readAsStringSync();
    expect(report.contains('Session seed: `phase4a-audit`'), isTrue);
    expect(report.contains('CONSISTENT_POSITIVE'), isTrue);
    expect(report.contains('CONSISTENT_NEGATIVE'), isTrue);
    expect(report.contains('MIXED_CONTEXT'), isTrue);
    expect(report.contains('LOW_PRIMARY_SIGNAL'), isTrue);
    expect(report.contains('HIGH_SELF_PRESENTATION_PRIOR'), isTrue);
    expect(report.contains('LOW_DIAGNOSTIC_PRIOR'), isTrue);
    expect(
      report.contains(
        'FREQUENCY V2 PHASE 4A DORMANT 12D SCORER AND CONFIDENCE PRIMITIVES READY — V2 STILL DORMANT',
      ),
      isTrue,
    );
  });
}
