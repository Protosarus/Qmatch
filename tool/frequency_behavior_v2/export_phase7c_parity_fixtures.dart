#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import '../../test/support/frequency_behavior_v2_helpers.dart';

/// Export Phase 7C Dart scorer golden outputs for JS parity tests.
void main() {
  final outPath =
      '${Directory.current.path}/test/fixtures/frequency_v2/phase7c_parity_fixtures.json';
  final fixtures = <Map<String, dynamic>>[];

  void addFixture({
    required String id,
    required String description,
    required FrequencyBehaviorV2PoolDocument pool,
    required Map<String, Map<String, dynamic>> review,
    required List<List<String>> clusters,
    required String sessionSeed,
    String? sessionId,
    int Function(int index)? pickIndex,
  }) {
    final manifest = const FrequencyBehaviorV2SessionComposer().composeManifest(
      pool: pool,
      sessionSeed: sessionSeed,
      reviewByItemId: review,
      nearDuplicateClusters: clusters,
      sessionId: sessionId,
    );
    final responses = <FrequencyBehaviorV2Response>[];
    for (var i = 0; i < manifest.questions.length; i++) {
      final q = manifest.questions[i];
      final order = q.presentedOptionOrder;
      final idx = pickIndex == null ? 0 : pickIndex(i);
      final clamped = idx < 0
          ? 0
          : idx >= order.length
              ? order.length - 1
              : idx;
      responses.add(
        FrequencyBehaviorV2Response(
          itemId: q.questionId,
          optionId: order[clamped],
        ),
      );
    }
    final result = const FrequencyBehaviorV2Scorer().score(
      pool: pool,
      responses: responses,
      manifest: manifest,
      nearDuplicateClusters: clusters,
    );
    if (!result.ok) {
      throw StateError('$id scorer failed: ${result.message}');
    }
    fixtures.add({
      'id': id,
      'description': description,
      'bank_version': pool.poolVersion,
      'bank_locale': pool.locale,
      'session_seed': sessionSeed,
      'session_id': manifest.sessionId,
      'item_plans': [
        for (final q in manifest.questions)
          {
            'item_id': q.questionId,
            'presented_option_order': q.presentedOptionOrder,
          },
      ],
      'answers': [
        for (final r in responses)
          {'item_id': r.itemId, 'selected_option_id': r.optionId},
      ],
      'expected': {
        'schema_version': result.schemaVersion,
        'scorer_version': result.scorerVersion,
        'confidence_model_version': result.confidenceModelVersion,
        'dimensions': [
          for (final d in result.dimensionScores) d.toJson(),
        ],
        'summary': _summary(result.dimensionScores),
      },
    });
  }

  final trPool = FrequencyBehaviorV2DraftLoader.loadPool();
  final trReview = FrequencyBehaviorV2DraftLoader.reviewByItemId();
  final trClusters = FrequencyBehaviorV2DraftLoader.loadNearDuplicateClusters();

  addFixture(
    id: 'tr_standard_seed',
    description: 'TR bank deterministic standard session',
    pool: trPool,
    review: trReview,
    clusters: trClusters,
    sessionSeed: 'phase7c-tr-standard-001',
  );
  addFixture(
    id: 'tr_alternate_seed',
    description: 'TR bank alternate seed coverage',
    pool: trPool,
    review: trReview,
    clusters: trClusters,
    sessionSeed: 'phase7c-tr-alt-002',
  );
  addFixture(
    id: 'tr_first_option_pattern',
    description: 'Always pick first presented option',
    pool: trPool,
    review: trReview,
    clusters: trClusters,
    sessionSeed: 'phase7c-tr-first-opt-003',
    pickIndex: (_) => 0,
  );
  addFixture(
    id: 'tr_mixed_responses',
    description: 'Rotate presented option index',
    pool: trPool,
    review: trReview,
    clusters: trClusters,
    sessionSeed: 'phase7c-tr-mixed-004',
    pickIndex: (i) => i % 4,
  );
  addFixture(
    id: 'tr_last_option_pattern',
    description: 'Always pick last presented option',
    pool: trPool,
    review: trReview,
    clusters: trClusters,
    sessionSeed: 'phase7c-tr-last-opt-005',
    pickIndex: (_) => 3,
  );

  final enPool = FrequencyBehaviorV2DraftLoader.loadEnPool();
  final enReview = FrequencyBehaviorV2DraftLoader.enReviewByItemId();
  final enClusters = FrequencyBehaviorV2DraftLoader.loadEnNearDuplicateClusters();
  addFixture(
    id: 'en_locale_session',
    description: 'EN semantic parity bank session',
    pool: enPool,
    review: enReview,
    clusters: enClusters,
    sessionSeed: 'phase7c-en-standard-001',
  );

  final doc = {
    'schema_version': 'frequency_behavior_v2_phase7c_parity_fixtures_v1',
    'numeric_tolerance': 1e-9,
    'fixture_count': fixtures.length,
    'fixtures': fixtures,
  };
  File(outPath).parent.createSync(recursive: true);
  File(outPath).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(doc));
  print('wrote $outPath (${fixtures.length} fixtures)');
}

Map<String, dynamic> _summary(List<FrequencyBehaviorV2DimensionScore> scores) {
  var withBehavior = 0;
  var supportSum = 0.0;
  var supportN = 0;
  for (final d in scores) {
    if (d.normalizedBehavior != null) {
      withBehavior++;
      if (d.provisionalConfidence != null) {
        supportSum += d.provisionalConfidence! * d.confidenceCompleteness!;
        supportN++;
      }
    }
  }
  return {
    'measured_dimension_count': 12,
    'dimensions_with_behavior': withBehavior,
    'global_support': supportN == 0 ? null : supportSum / supportN,
  };
}
