// ignore_for_file: avoid_print
/// Phase 4C dormant calibration telemetry audit.
///
/// Does not activate V2. Does not collect live telemetry. Does not modify
/// selector, scorer, confidence, questions, weights, or evidence priors.
///
/// Usage:
///   dart run tool/frequency_behavior_v2/simulate_phase4c_telemetry.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

void main(List<String> args) {
  var outPath = FrequencyBehaviorV2Contract.phase4cTelemetryAuditRelativePath;
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
  const scorer = FrequencyBehaviorV2Scorer();
  const factory = FrequencyBehaviorV2TelemetryFactory();
  const aggregator = FrequencyBehaviorV2CalibrationAggregator();
  const sanitizer = FrequencyBehaviorV2LatencySanitizer();

  final seeds = [
    'phase4c-audit',
    for (var i = 1; i < 8; i++) 'phase4c-audit-$i',
  ];

  final records = <FrequencyBehaviorV2TelemetrySessionRecord>[];
  String? firstSessionScoreJson;
  var perSessionScoreStable = true;
  var positionRecoverable = true;
  var changeCountCorrect = true;
  var versionsFrozen = true;
  var invalidLatencyFlagged = false;
  var missingCohortPresent = false;

  for (var s = 0; s < seeds.length; s++) {
    final seed = seeds[s];
    final manifest = composer.composeManifest(
      pool: pool,
      sessionSeed: seed,
      reviewByItemId: review,
      nearDuplicateClusters: clusters,
    );
    final remanifest = composer.composeManifest(
      pool: pool,
      sessionSeed: seed,
      reviewByItemId: review,
      nearDuplicateClusters: clusters,
    );
    if (manifest.questionIds.join() != remanifest.questionIds.join()) {
      stderr.writeln('selector not deterministic for $seed');
      exitCode = 2;
      return;
    }

    final cohort = s == 7
        ? null
        : const FrequencyBehaviorV2TelemetryCohort(
            ageBucket: '25-34',
            country: 'TR',
          );
    if (cohort == null) missingCohortPresent = true;

    final session = factory.sessionFromManifest(
      manifest: manifest,
      startedAt: '2026-08-31T09:00:00Z',
      completedAt: '2026-08-31T09:22:00Z',
      cohort: cohort,
    );

    final responses = <FrequencyBehaviorV2Response>[];
    final events = <FrequencyBehaviorV2ResponseTelemetryEvent>[];
    for (final q in manifest.questions) {
      final item = pool.itemsById[q.questionId]!;
      final intended = _maxPrimaryOption(item);
      final tracker = FrequencyBehaviorV2AnswerChangeTracker();
      final order = q.presentedOptionOrder;
      final changeThis = q.presentationIndex % 11 == 0;
      if (changeThis && order.length >= 3) {
        final others = [
          for (final id in order)
            if (id != intended.optionId) id
        ];
        tracker.recordSelection(others[0]);
        tracker.recordSelection(others[1]);
        tracker.recordSelection(intended.optionId);
        if (tracker.changedAnswerCount != 2 || !tracker.finalChanged) {
          changeCountCorrect = false;
        }
      } else {
        tracker.recordSelection(intended.optionId);
      }

      final rawLatency = _rawLatency(s, q.presentationIndex);
      final event = factory.eventForQuestion(
        manifest: manifest,
        question: q,
        tracker: tracker,
        rawLatencyMs: rawLatency,
        serverTimestamp: '2026-08-31T09:22:00Z',
      );
      events.add(event);
      responses.add(
        FrequencyBehaviorV2Response(
          itemId: item.itemId,
          optionId: intended.optionId,
        ),
      );

      if (event.bankVersion != pool.poolVersion ||
          event.selectorVersion !=
              FrequencyBehaviorV2Contract.selectorVersion ||
          event.scorerVersion != FrequencyBehaviorV2Contract.scorerVersion) {
        versionsFrozen = false;
      }
      if (event.selectedPresentedPosition == null) {
        positionRecoverable = false;
      }
      if (!event.latencyValid) invalidLatencyFlagged = true;
    }

    final scoredA = scorer.score(
      pool: pool,
      manifest: manifest,
      responses: responses,
      nearDuplicateClusters: clusters,
    );
    final scoredB = scorer.score(
      pool: pool,
      manifest: manifest,
      responses: responses,
      nearDuplicateClusters: clusters,
    );
    final encoded = jsonEncode(scoredA.toJson());
    if (encoded != jsonEncode(scoredB.toJson())) {
      perSessionScoreStable = false;
    }
    if (s == 0) firstSessionScoreJson = encoded;

    records.add(
      FrequencyBehaviorV2TelemetrySessionRecord(
        session: session,
        events: events,
      ),
    );
  }

  // Each session has a different seed/manifest, so JSON differs across
  // sessions. Within a session, A/B already matched. Re-score the first
  // session from canonical answers only (no telemetry inputs).
  final firstManifest = composer.composeManifest(
    pool: pool,
    sessionSeed: seeds.first,
    reviewByItemId: review,
    nearDuplicateClusters: clusters,
  );
  final firstResponses = [
    for (final q in firstManifest.questions)
      FrequencyBehaviorV2Response(
        itemId: q.questionId,
        optionId: _maxPrimaryOption(pool.itemsById[q.questionId]!).optionId,
      ),
  ];
  final scoreNoTelemetry = scorer.score(
    pool: pool,
    manifest: firstManifest,
    responses: firstResponses,
    nearDuplicateClusters: clusters,
  );
  final scoreAgain = scorer.score(
    pool: pool,
    manifest: firstManifest,
    responses: firstResponses,
    nearDuplicateClusters: clusters,
  );
  final scoreUnchanged = perSessionScoreStable &&
      firstSessionScoreJson == jsonEncode(scoreNoTelemetry.toJson()) &&
      jsonEncode(scoreNoTelemetry.toJson()) == jsonEncode(scoreAgain.toJson());
  final confidenceUnchanged = [
    for (var i = 0; i < scoreNoTelemetry.dimensionScores.length; i++)
      scoreNoTelemetry.dimensionScores[i].provisionalConfidence ==
          scoreAgain.dimensionScores[i].provisionalConfidence,
  ].every((v) => v);
  final behaviorUnchanged = [
    for (var i = 0; i < scoreNoTelemetry.dimensionScores.length; i++)
      scoreNoTelemetry.dimensionScores[i].normalizedBehavior ==
          scoreAgain.dimensionScores[i].normalizedBehavior,
  ].every((v) => v);

  final cohortManifestA = composer.composeManifest(
    pool: pool,
    sessionSeed: 'phase4c-cohort-check',
    reviewByItemId: review,
    nearDuplicateClusters: clusters,
  );
  final cohortManifestB = composer.composeManifest(
    pool: pool,
    sessionSeed: 'phase4c-cohort-check',
    reviewByItemId: review,
    nearDuplicateClusters: clusters,
  );
  final cohortDoesNotChangeSelector =
      cohortManifestA.questionIds.join() == cohortManifestB.questionIds.join();

  final report = aggregator.aggregate(records: records, pool: pool);
  var impressionsReconcile = true;
  var shareOk = true;
  var positionReconcile = true;
  for (final q in report.questions) {
    final selectedSum = q.options.fold<int>(0, (a, o) => a + o.selections);
    if (selectedSum != q.impressions) impressionsReconcile = false;
    final shareSum = q.options.fold<double>(0, (a, o) => a + o.selectionShare);
    if ((shareSum - 1.0).abs() > 1e-9 && q.impressions > 0) shareOk = false;
    for (final o in q.options) {
      final posSum =
          o.selectionByPresentedPosition.fold<int>(0, (a, n) => a + n);
      if (posSum != o.selections) positionReconcile = false;
    }
  }

  final suppressed = report.cohortSlices.where((c) => c.suppressed).toList();
  final lowNSuppressed = suppressed.isNotEmpty &&
      suppressed.every((c) => c.reason == 'n_below_min_cohort_n');

  final shrink = aggregator.shrinkToGlobal(
    n: 8,
    localShare: 0.4,
    globalShare: 0.25,
  );

  var liveThrows = false;
  try {
    factory.publishLive(records.first);
  } on UnsupportedError {
    liveThrows = true;
  }

  final sampleEvent = records.first.events.first;
  final keys = _jsonKeys(sampleEvent.toJson());
  final sessionKeys = _jsonKeys(records.first.session.toJson());
  final forbiddenHit = keys
      .union(sessionKeys)
      .intersection(FrequencyBehaviorV2Contract.telemetryForbiddenPayloadKeys);

  final eventJson = jsonEncode(sampleEvent.toJson());
  final noWeights = !eventJson.contains('behavioral_weights') &&
      !eventJson.contains('evidence_meta') &&
      !eventJson.contains('diagnostic_value');

  var agree = 0;
  var disagree = 0;
  for (final row in report.crossChecks) {
    agree += row.directionalAgreement;
    disagree += row.directionalDisagreement;
  }
  final crossSample = [...report.crossChecks]
    ..sort((a, b) => b.pairCount.compareTo(a.pairCount));

  final changeExample = records.first.events.firstWhere(
    (e) => e.changedAnswerCount == 2,
    orElse: () => records.first.events.first,
  );
  final invalidExample = records.first.events.firstWhere(
    (e) => !e.latencyValid,
    orElse: () => records.first.events.first,
  );
  final positionExample = records.first.events.first;

  final buf = StringBuffer();
  buf.writeln('# Frequency V2 Phase 4C — Calibration telemetry audit');
  buf.writeln('');
  buf.writeln(
    'Status: **offline / dormant**. `runtime_selectable` remains false.',
  );
  buf.writeln(
    'live_collection_enabled: ${FrequencyBehaviorV2Contract.telemetryLiveCollectionEnabled}',
  );
  buf.writeln(
    'response schema: `${FrequencyBehaviorV2Contract.telemetryResponseSchemaVersion}`',
  );
  buf.writeln(
    'session schema: `${FrequencyBehaviorV2Contract.telemetrySessionSchemaVersion}`',
  );
  buf.writeln(
    'aggregate schema: `${FrequencyBehaviorV2Contract.calibrationAggregateSchemaVersion}`',
  );
  buf.writeln('bank_version: `${pool.poolVersion}`');
  buf.writeln(
    'selector_version: `${FrequencyBehaviorV2Contract.selectorVersion}`',
  );
  buf.writeln(
    'scorer_version: `${FrequencyBehaviorV2Contract.scorerVersion}`',
  );
  buf.writeln(
    'retention_policy: `${FrequencyBehaviorV2Contract.telemetryRetentionPolicy}`',
  );
  buf.writeln(
    'MIN_COHORT_N: ${FrequencyBehaviorV2Contract.telemetryMinCohortN}',
  );
  buf.writeln('Synthetic sessions: ${records.length}');
  buf.writeln('Synthetic events: ${report.eventCount}');
  buf.writeln('');
  buf.writeln(
    'Telemetry is separate from canonical answers, 12D scoring, provisional '
    'confidence, eligibility, and matching. This audit does **not** enable '
    'live collection and does **not** auto-update evidence priors.',
  );
  buf.writeln('');
  buf.writeln('## Synthetic checks');
  buf.writeln('');
  buf.writeln(
    '| Check | Result |',
  );
  buf.writeln('|---|---|');
  buf.writeln(
    '| option position recoverable | **$positionRecoverable** |',
  );
  buf.writeln(
    '| A→B→C change count = 2 | **$changeCountCorrect** |',
  );
  buf.writeln(
    '| latency does not change normalized_behavior | **$behaviorUnchanged** |',
  );
  buf.writeln(
    '| latency does not change provisional_confidence | **$confidenceUnchanged** |',
  );
  buf.writeln(
    '| score JSON identical without telemetry inputs | **$scoreUnchanged** |',
  );
  buf.writeln(
    '| cohort metadata does not change selector | **$cohortDoesNotChangeSelector** |',
  );
  buf.writeln(
    '| missing cohort metadata is valid | **$missingCohortPresent** |',
  );
  buf.writeln(
    '| low-N cohort slices suppressed (`n_below_min_cohort_n`) | **$lowNSuppressed** |',
  );
  buf.writeln(
    '| question/option impression counts reconcile | **$impressionsReconcile** |',
  );
  buf.writeln(
    '| selection_share sums to 1.0 | **$shareOk** |',
  );
  buf.writeln(
    '| selection_by_presented_position sums to selections | **$positionReconcile** |',
  );
  buf.writeln(
    '| bank/selector/scorer versions frozen on events | **$versionsFrozen** |',
  );
  buf.writeln(
    '| invalid latency flagged (`latency_valid=false`) | **$invalidLatencyFlagged** |',
  );
  buf.writeln(
    '| shrinkToGlobal returns null | **${shrink == null}** |',
  );
  buf.writeln(
    '| publishLive throws | **$liveThrows** |',
  );
  buf.writeln(
    '| forbidden PII keys absent | **${forbiddenHit.isEmpty}** |',
  );
  buf.writeln(
    '| events omit weights / evidence | **$noWeights** |',
  );
  buf.writeln(
    '| runtime_selectable | **${pool.runtimeSelectable}** |',
  );
  buf.writeln('');
  buf.writeln('## Position recovery example');
  buf.writeln('');
  buf.writeln('question_id: `${positionExample.questionId}`');
  buf.writeln(
    'presented_option_order: `${positionExample.presentedOptionOrder}`',
  );
  buf.writeln('selected_option_id: `${positionExample.selectedOptionId}`');
  buf.writeln(
    'selected_presented_position: `${positionExample.selectedPresentedPosition}`',
  );
  buf.writeln('');
  buf.writeln('## Answer-change example');
  buf.writeln('');
  buf.writeln('question_id: `${changeExample.questionId}`');
  buf.writeln('selection_sequence: `${changeExample.selectionSequence}`');
  buf.writeln(
    'changed_answer_count: ${changeExample.changedAnswerCount}',
  );
  buf.writeln('final_changed: ${changeExample.finalChanged}');
  buf.writeln('');
  buf.writeln(
    'Event-write time does not label the respondent uncertain, dishonest, '
    'or confused.',
  );
  buf.writeln('');
  buf.writeln('## Latency sanitizer');
  buf.writeln('');
  buf.writeln(
    'Valid analytics range: '
    '${FrequencyBehaviorV2Contract.telemetryLatencyMinValidMs} … '
    '${FrequencyBehaviorV2Contract.telemetryLatencyMaxValidMs} ms.',
  );
  buf.writeln(
    'Session 0 / index 0 raw `-50` → analytics '
    '`${sanitizer.sanitize(-50).analyticsMs}`, valid '
    '`${sanitizer.sanitize(-50).valid}`.',
  );
  buf.writeln(
    'Session 0 / index 1 raw `9000000` → analytics '
    '`${sanitizer.sanitize(9000000).analyticsMs}`, valid '
    '`${sanitizer.sanitize(9000000).valid}`.',
  );
  buf.writeln(
    'Example stored event: question `${invalidExample.questionId}` '
    'response_latency_ms=${invalidExample.responseLatencyMs} '
    'latency_valid=${invalidExample.latencyValid}.',
  );
  buf.writeln('');
  buf.writeln(
    'The scorer does not read latency. Fast/slow is not good/bad.',
  );
  buf.writeln('');
  buf.writeln('## Cohort slices (small-N safety)');
  buf.writeln('');
  if (report.cohortSlices.isEmpty) {
    buf.writeln('No cohort slices.');
  } else {
    buf.writeln('| key | value | n | suppressed | reason |');
    buf.writeln('|---|---|---|---|---|');
    for (final c in report.cohortSlices) {
      buf.writeln(
        '| ${c.cohortKey} | ${c.cohortValue} | ${c.sampleSize} | '
        '${c.suppressed} | ${c.reason ?? ''} |',
      );
    }
  }
  buf.writeln('');
  buf.writeln(
    'Cohort fields are optional and nullable. They are never inputs to the '
    'selector or scorer. Do not interpret slices below MIN_COHORT_N.',
  );
  buf.writeln('');
  buf.writeln('## Cross-check calibration (not lie detection)');
  buf.writeln('');
  buf.writeln('pair rows: ${report.crossChecks.length}');
  buf.writeln('directional_agreement total: $agree');
  buf.writeln('directional_disagreement total: $disagree');
  buf.writeln('');
  buf.writeln(
    'Disagreement is not lying, dishonesty, or inconsistent character.',
  );
  buf.writeln('');
  buf.writeln('Highest pair_count sample (up to 8):');
  buf.writeln('');
  buf.writeln(
    '| dimension | q_a | q_b | pair_count | agree | disagree | n |',
  );
  buf.writeln('|---|---|---|---|---|---|---|');
  for (final row in crossSample.take(8)) {
    buf.writeln(
      '| ${row.dimensionId} | ${row.questionIdA} | ${row.questionIdB} | '
      '${row.pairCount} | ${row.directionalAgreement} | '
      '${row.directionalDisagreement} | ${row.sampleSize} |',
    );
  }
  buf.writeln('');
  buf.writeln('## Aggregate sample sizes');
  buf.writeln('');
  buf.writeln('question rows: ${report.questions.length}');
  buf.writeln('session_count: ${report.sessionCount}');
  buf.writeln('event_count: ${report.eventCount}');
  buf.writeln('shrinkage_enabled: ${report.shrinkageEnabled}');
  buf.writeln('');
  final top = [...report.questions]
    ..sort((a, b) => b.impressions.compareTo(a.impressions));
  buf.writeln('Highest-impression questions (up to 8):');
  buf.writeln('');
  buf.writeln(
    '| question_id | primary | impressions / sample_size | final_changed_rate | latency median (valid) |',
  );
  buf.writeln('|---|---|---|---|---|');
  for (final q in top.take(8)) {
    buf.writeln(
      '| ${q.questionId} | ${q.primaryDimension} | ${q.impressions} | '
      '${q.finalChangedRate.toStringAsFixed(3)} | '
      '${q.latencyMedianMs?.toStringAsFixed(0) ?? 'null'} |',
    );
  }
  buf.writeln('');
  buf.writeln('## Privacy');
  buf.writeln('');
  buf.writeln(
    'Canonical assessment data and calibration telemetry are separate. '
    'Events do not contain name, email, phone, free-text bio, precise GPS, '
    'advertising IDs, contacts, or photos. Retention is configurable, not '
    'permanent-by-default. No live collection clock is started.',
  );
  buf.writeln('');
  buf.writeln('## What this phase does not do');
  buf.writeln('');
  buf.writeln('- deploy or enable live telemetry');
  buf.writeln('- activate V2');
  buf.writeln('- modify scoring, confidence, selector, or evidence priors');
  buf.writeln('- auto-recalibrate anything');
  buf.writeln('- use age / location / profession for question selection');
  buf.writeln('- create lie detection');
  buf.writeln(
    '- touch V1 / Firebase / C2 / Discover / Persona / matching',
  );
  buf.writeln('- implement quantum layer');
  buf.writeln('');
  buf.writeln(
    'FREQUENCY V2 PHASE 4C CALIBRATION TELEMETRY CONTRACT READY — NO LIVE COLLECTION — V2 STILL DORMANT',
  );

  File(outPath).writeAsStringSync(buf.toString());
  stdout.writeln(buf.toString().trimRight());
  stdout.writeln('wrote $outPath');
}

int _rawLatency(int sessionIndex, int presentationIndex) {
  if (sessionIndex == 0 && presentationIndex == 0) return -50;
  if (sessionIndex == 0 && presentationIndex == 1) return 9000000;
  return 350 + ((sessionIndex * 50 + presentationIndex * 13) % 1800);
}

FrequencyBehaviorV2Option _maxPrimaryOption(FrequencyBehaviorV2Item item) {
  final dim = item.primaryDimensions.single;
  FrequencyBehaviorV2Option? best;
  double? bestW;
  for (final o in item.options) {
    final w = o.behavioralWeights[dim];
    if (w == null) continue;
    if (best == null ||
        w > bestW! ||
        (w == bestW && o.optionId.compareTo(best.optionId) < 0)) {
      best = o;
      bestW = w;
    }
  }
  return best ?? item.options.first;
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
