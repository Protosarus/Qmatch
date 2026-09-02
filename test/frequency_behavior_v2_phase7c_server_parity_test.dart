import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import 'support/frequency_behavior_v2_helpers.dart';

void main() {
  final fixtureFile = File(
    '${Directory.current.path}/test/fixtures/frequency_v2/phase7c_parity_fixtures.json',
  );

  test('phase7c parity fixtures exist and match Dart scorer', () {
    expect(fixtureFile.existsSync(), isTrue,
        reason: 'run dart run tool/frequency_behavior_v2/export_phase7c_parity_fixtures.dart');
    final doc =
        jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    expect(doc['fixture_count'], greaterThanOrEqualTo(5));
    final fixtures = doc['fixtures'] as List;
    final trPool = FrequencyBehaviorV2DraftLoader.loadPool();
    final trReview = FrequencyBehaviorV2DraftLoader.reviewByItemId();
    final trClusters = FrequencyBehaviorV2DraftLoader.loadNearDuplicateClusters();
    final enPool = FrequencyBehaviorV2DraftLoader.loadEnPool();
    final enReview = FrequencyBehaviorV2DraftLoader.enReviewByItemId();
    final enClusters =
        FrequencyBehaviorV2DraftLoader.loadEnNearDuplicateClusters();
    const scorer = FrequencyBehaviorV2Scorer();
    const composer = FrequencyBehaviorV2SessionComposer();

    for (final raw in fixtures) {
      final fixture = Map<String, dynamic>.from(raw as Map);
      final bankVersion = fixture['bank_version'] as String;
      final pool = bankVersion == FrequencyBehaviorV2Contract.poolVersionEnDraft1
          ? enPool
          : trPool;
      final review = bankVersion == FrequencyBehaviorV2Contract.poolVersionEnDraft1
          ? enReview
          : trReview;
      final clusters =
          bankVersion == FrequencyBehaviorV2Contract.poolVersionEnDraft1
              ? enClusters
              : trClusters;
      final manifest = composer.composeManifest(
        pool: pool,
        sessionSeed: fixture['session_seed'] as String,
        reviewByItemId: review,
        nearDuplicateClusters: clusters,
        sessionId: fixture['session_id'] as String?,
      );
      final answers = (fixture['answers'] as List)
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList();
      final responses = [
        for (final a in answers)
          FrequencyBehaviorV2Response(
            itemId: a['item_id'] as String,
            optionId: a['selected_option_id'] as String,
          ),
      ];
      final result = scorer.score(
        pool: pool,
        responses: responses,
        manifest: manifest,
        nearDuplicateClusters: clusters,
      );
      expect(result.ok, isTrue, reason: fixture['id']);
      final expected =
          Map<String, dynamic>.from(fixture['expected'] as Map);
      expect(result.scorerVersion, expected['scorer_version']);
      final expectedDims = {
        for (final d in expected['dimensions'] as List)
          (d as Map)['dimension_id'] as String: d,
      };
      for (final dim in result.dimensionScores) {
        final exp = Map<String, dynamic>.from(
          expectedDims[dim.dimensionId]! as Map,
        );
        expect(dim.normalizedBehavior, exp['normalized_behavior']);
        expect(dim.provisionalConfidence, exp['provisional_confidence']);
        expect(dim.confidenceFlags, exp['confidence_flags']);
      }
    }
  });
}
