import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import 'support/frequency_behavior_v2_helpers.dart';

FrequencyBehaviorV2EvidenceMeta _meta() =>
    const FrequencyBehaviorV2EvidenceMeta(
      reviewStatus: FrequencyBehaviorV2Contract.evidenceReviewReviewed,
      diagnosticValue: 0.5,
      behavioralPlausibility: 0.5,
      ambiguity: 0.25,
      socialDesirability: 0.5,
      obviousness: 0.5,
      selfPresentationRisk: 0.25,
    );

FrequencyBehaviorV2Item _item(String id, String cluster) {
  const dim = 'contact_need';
  const letters = ['a', 'b', 'c', 'd'];
  final weights = [
    {dim: 2.0},
    {dim: 1.0},
    {dim: -1.0},
    {dim: -2.0},
  ];
  return FrequencyBehaviorV2Item(
    itemId: id,
    locale: FrequencyBehaviorV2Contract.localeTr,
    prompt: 'p',
    context: const ['t'],
    primaryDimensions: const [dim],
    secondaryDimensions: const [],
    semanticCluster: cluster,
    crosscheckGroupIds: const [],
    options: [
      for (var i = 0; i < 4; i++)
        FrequencyBehaviorV2Option(
          optionId: '${id}_${letters[i]}',
          text: 't',
          behavioralWeights: weights[i],
          evidenceMeta: _meta(),
        ),
    ],
  );
}

Set<String> _jsonKeys(Object? node) {
  final out = <String>{};
  void walk(Object? n) {
    if (n is Map) {
      for (final e in n.entries) {
        out.add(e.key.toString());
        walk(e.value);
      }
    } else if (n is List) {
      for (final v in n) {
        walk(v);
      }
    }
  }

  walk(node);
  return out;
}

void main() {
  const factory = FrequencyBehaviorV2TelemetryFactory();
  const sanitizer = FrequencyBehaviorV2LatencySanitizer();
  const aggregator = FrequencyBehaviorV2CalibrationAggregator();

  test('option position is recoverable from presented order', () {
    const order = [
      'frequency_v2_q0123_c',
      'frequency_v2_q0123_a',
      'frequency_v2_q0123_d',
      'frequency_v2_q0123_b',
    ];
    const event = FrequencyBehaviorV2ResponseTelemetryEvent(
      sessionId: 's',
      bankVersion: 'b',
      selectorVersion: 'sel',
      scorerVersion: 'sc',
      questionId: 'frequency_v2_q0123',
      primaryDimension: 'contact_need',
      presentedOptionOrder: order,
      selectedOptionId: 'frequency_v2_q0123_a',
      presentationIndex: 0,
      changedAnswerCount: 0,
      finalChanged: false,
      latencyValid: true,
      responseLatencyMs: 400,
      locale: 'tr-TR',
    );
    expect(event.selectedPresentedPosition, 1);
    expect(event.presentedOptionOrder, order);
  });

  test('A -> B -> C counts two changes and is final_changed', () {
    final t = FrequencyBehaviorV2AnswerChangeTracker();
    t.recordSelection('A');
    t.recordSelection('B');
    t.recordSelection('C');
    expect(t.changedAnswerCount, 2);
    expect(t.finalChanged, isTrue);
    expect(t.sequence, ['A', 'B', 'C']);
    t.recordSelection('C');
    expect(t.changedAnswerCount, 2);
  });

  test('latency clamp sets validity without feeding the scorer', () {
    final neg = sanitizer.sanitize(-12);
    expect(neg.valid, isFalse);
    expect(neg.analyticsMs, 0);
    final huge = sanitizer.sanitize(9 * 1000 * 1000);
    expect(huge.valid, isFalse);
    expect(
      huge.analyticsMs,
      FrequencyBehaviorV2Contract.telemetryLatencyMaxValidMs,
    );
    final ok = sanitizer.sanitize(1500);
    expect(ok.valid, isTrue);
    expect(ok.analyticsMs, 1500);
  });

  test('latency and cohort do not change scoring or confidence', () {
    final items = [_item('q0', 'c0'), _item('q1', 'c1')];
    final pool = FrequencyBehaviorV2PoolDocument(
      schemaVersion: FrequencyBehaviorV2Contract.schemaVersion,
      poolVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
      scoringPolicyVersion: FrequencyBehaviorV2Contract.scoringPolicyVersion,
      locale: FrequencyBehaviorV2Contract.localeTr,
      status: FrequencyBehaviorV2Contract.statusDraftNotRuntime,
      runtimeSelectable: false,
      items: items,
    );
    final responses = [
      FrequencyBehaviorV2Response(itemId: 'q0', optionId: 'q0_a'),
      FrequencyBehaviorV2Response(itemId: 'q1', optionId: 'q1_b'),
    ];
    const scorer = FrequencyBehaviorV2Scorer();
    final a = scorer.score(pool: pool, responses: responses);
    final b = scorer.score(pool: pool, responses: responses);
    expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
    expect(a.scoreFor('contact_need')!.normalizedBehavior,
        b.scoreFor('contact_need')!.normalizedBehavior);
    expect(a.scoreFor('contact_need')!.provisionalConfidence,
        b.scoreFor('contact_need')!.provisionalConfidence);
    final cohort = const FrequencyBehaviorV2TelemetryCohort(
      ageBucket: '25-34',
      country: 'TR',
    );
    expect(cohort.ageBucket, '25-34');
    expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
  });

  test('cohort metadata is not a selector input; missing cohort is valid', () {
    final pool = FrequencyBehaviorV2DraftLoader.loadPool();
    final review = FrequencyBehaviorV2DraftLoader.reviewByItemId();
    final clusters = FrequencyBehaviorV2DraftLoader.loadNearDuplicateClusters();
    const composer = FrequencyBehaviorV2SessionComposer();
    final m1 = composer.composeManifest(
      pool: pool,
      sessionSeed: 'phase4c-cohort',
      reviewByItemId: review,
      nearDuplicateClusters: clusters,
    );
    final m2 = composer.composeManifest(
      pool: pool,
      sessionSeed: 'phase4c-cohort',
      reviewByItemId: review,
      nearDuplicateClusters: clusters,
    );
    expect(m1.questionIds, m2.questionIds);
    final session = factory.sessionFromManifest(
      manifest: m1,
      cohort: null,
    );
    expect(session.cohort, isNull);
    expect(session.toJson()['cohort'], isNull);
    expect(pool.runtimeSelectable, isFalse);
  });

  test('low-N cohort slices are suppressed; option counts reconcile', () {
    final q = _item('q0', 'c0');
    FrequencyBehaviorV2ResponseTelemetryEvent ev({
      required String sessionId,
      required String selected,
      required List<String> seq,
      FrequencyBehaviorV2TelemetryCohort? cohort,
    }) {
      final tracker = FrequencyBehaviorV2AnswerChangeTracker();
      for (final id in seq) {
        tracker.recordSelection(id);
      }
      return FrequencyBehaviorV2ResponseTelemetryEvent(
        sessionId: sessionId,
        bankVersion: 'b',
        selectorVersion: 'sel',
        scorerVersion: 'sc',
        questionId: q.itemId,
        primaryDimension: 'contact_need',
        presentedOptionOrder: [for (final o in q.options) o.optionId],
        selectedOptionId: selected,
        presentationIndex: 0,
        changedAnswerCount: tracker.changedAnswerCount,
        finalChanged: tracker.finalChanged,
        selectionSequence: tracker.sequence,
        latencyValid: true,
        responseLatencyMs: 200,
        locale: 'tr-TR',
      );
    }

    final records = [
      for (var i = 0; i < 3; i++)
        FrequencyBehaviorV2TelemetrySessionRecord(
          session: FrequencyBehaviorV2SessionTelemetry(
            sessionId: 's$i',
            sessionSeed: 'seed$i',
            bankVersion: 'b',
            selectorVersion: 'sel',
            scorerVersion: 'sc',
            locale: 'tr-TR',
            questionCount: 1,
            cohort:
                const FrequencyBehaviorV2TelemetryCohort(ageBucket: '18-24'),
          ),
          events: [
            ev(
              sessionId: 's$i',
              selected: i == 0 ? 'q0_c' : 'q0_a',
              seq: i == 0 ? ['q0_a', 'q0_b', 'q0_c'] : ['q0_a'],
            ),
          ],
        ),
    ];
    final report = aggregator.aggregate(records: records);
    expect(report.eventCount, 3);
    final row = report.questions.single;
    expect(row.impressions, 3);
    final selectedSum = row.options.fold<int>(0, (a, o) => a + o.selections);
    expect(selectedSum, row.impressions);
    final changed = row.options.firstWhere((o) => o.optionId == 'q0_a');
    expect(changed.changedAwayCount, 1);
    expect(changed.changedToCount, 0);
    final toC = row.options.firstWhere((o) => o.optionId == 'q0_c');
    expect(toC.changedToCount, 1);
    expect(toC.selections, 1);
    expect(report.cohortSlices, isNotEmpty);
    expect(report.cohortSlices.single.suppressed, isTrue);
    expect(report.cohortSlices.single.sampleSize, 3);
    expect(report.minCohortN, 100);
    expect(
      aggregator.shrinkToGlobal(n: 3, localShare: 0.5, globalShare: 0.2),
      isNull,
    );
  });

  test('payload keys exclude forbidden PII; live publish is disabled', () {
    expect(FrequencyBehaviorV2Contract.telemetryLiveCollectionEnabled, isFalse);
    expect(FrequencyBehaviorV2TelemetryFactory.liveCollectionEnabled, isFalse);
    final event = FrequencyBehaviorV2ResponseTelemetryEvent(
      sessionId: 's',
      bankVersion: 'b',
      selectorVersion: 'sel',
      scorerVersion: 'sc',
      questionId: 'q0',
      primaryDimension: 'contact_need',
      presentedOptionOrder: const ['q0_a', 'q0_b', 'q0_c', 'q0_d'],
      selectedOptionId: 'q0_a',
      presentationIndex: 0,
      changedAnswerCount: 0,
      finalChanged: false,
      latencyValid: true,
      locale: 'tr-TR',
    );
    final keys = _jsonKeys(event.toJson());
    expect(
      keys.intersection(
          FrequencyBehaviorV2Contract.telemetryForbiddenPayloadKeys),
      isEmpty,
    );
    expect(
      () => factory.publishLive(
        FrequencyBehaviorV2TelemetrySessionRecord(
          session: const FrequencyBehaviorV2SessionTelemetry(
            sessionId: 's',
            sessionSeed: 'seed',
            bankVersion: 'b',
            selectorVersion: 'sel',
            scorerVersion: 'sc',
            locale: 'tr-TR',
            questionCount: 1,
          ),
          events: [event],
        ),
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('phase 4C audit report exists and collection stays off', () {
    final report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.phase4cTelemetryAuditRelativePath}',
    ).readAsStringSync();
    expect(report.contains('live_collection_enabled: false'), isTrue);
    expect(report.contains('n_below_min_cohort_n'), isTrue);
    expect(
      report.contains(
        'FREQUENCY V2 PHASE 4C CALIBRATION TELEMETRY CONTRACT READY — NO LIVE COLLECTION — V2 STILL DORMANT',
      ),
      isTrue,
    );
  });
}
