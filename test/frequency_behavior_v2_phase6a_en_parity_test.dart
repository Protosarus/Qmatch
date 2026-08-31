import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import 'support/frequency_behavior_v2_helpers.dart';

void main() {
  late FrequencyBehaviorV2PoolDocument trPool;
  late FrequencyBehaviorV2PoolDocument enPool;
  late Map<String, Map<String, dynamic>> trReview;
  late Map<String, Map<String, dynamic>> enReview;
  late List<List<String>> trClusters;
  late List<List<String>> enClusters;

  setUpAll(() {
    trPool = FrequencyBehaviorV2DraftLoader.loadPool();
    enPool = FrequencyBehaviorV2DraftLoader.loadEnPool();
    trReview = FrequencyBehaviorV2DraftLoader.reviewByItemId();
    enReview = FrequencyBehaviorV2DraftLoader.enReviewByItemId();
    trClusters = FrequencyBehaviorV2DraftLoader.loadNearDuplicateClusters();
    enClusters = FrequencyBehaviorV2DraftLoader.loadEnNearDuplicateClusters();
  });

  test('TR archive counts unchanged', () {
    expect(trPool.items.length, FrequencyBehaviorV2Contract.poolItemCount);
    expect(
      trPool.items.fold<int>(0, (n, i) => n + i.options.length),
      FrequencyBehaviorV2Contract.poolOptionCount,
    );
    expect(trPool.runtimeSelectable, isFalse);
    expect(trPool.locale, FrequencyBehaviorV2Contract.localeTr);
  });

  test('EN archive counts match TR', () {
    expect(enPool.items.length, FrequencyBehaviorV2Contract.poolItemCount);
    expect(
      enPool.items.fold<int>(0, (n, i) => n + i.options.length),
      FrequencyBehaviorV2Contract.poolOptionCount,
    );
    expect(enPool.runtimeSelectable, isFalse);
    expect(enPool.locale, FrequencyBehaviorV2Contract.localeEn);
    expect(enPool.poolVersion, FrequencyBehaviorV2Contract.poolVersionEnDraft1);
    expect(
      enPool.scoringPolicyVersion,
      FrequencyBehaviorV2Contract.scoringPolicyVersion,
    );
  });

  test('exact question and option ID parity', () {
    final trIds = trPool.items.map((i) => i.itemId).toSet();
    final enIds = enPool.items.map((i) => i.itemId).toSet();
    expect(trIds, enIds);

    for (final id in trIds) {
      final trOpts = trPool.itemsById[id]!.options.map((o) => o.optionId).toSet();
      final enOpts = enPool.itemsById[id]!.options.map((o) => o.optionId).toSet();
      expect(enOpts, trOpts, reason: id);
    }
  });

  test('DROP and selectable counts', () {
    var trDrop = 0;
    var enDrop = 0;
    var trSel = 0;
    var enSel = 0;
    for (final id in trReview.keys) {
      if (trReview[id]!['drop_from_selectable'] == true) trDrop++;
      if (enReview[id]!['drop_from_selectable'] == true) enDrop++;
      if (trReview[id]!['drop_from_selectable'] != true &&
          trReview[id]!['selector_eligible'] == true) {
        trSel++;
      }
      if (enReview[id]!['drop_from_selectable'] != true &&
          enReview[id]!['selector_eligible'] == true) {
        enSel++;
      }
    }
    expect(trDrop, FrequencyBehaviorV2Contract.phase2fDropFromSelectableTotal);
    expect(enDrop, FrequencyBehaviorV2Contract.phase2fDropFromSelectableTotal);
    expect(trSel, FrequencyBehaviorV2Contract.phase2fSelectableAfterDrops);
    expect(enSel, FrequencyBehaviorV2Contract.phase2fSelectableAfterDrops);
  });

  test('locale parity validator passes', () {
    const validator = FrequencyBehaviorV2LocaleParityValidator();
    final result = validator.validate(
      trPool: trPool,
      enPool: enPool,
      trReviewByItemId: trReview,
      enReviewByItemId: enReview,
      trNearDuplicateClusters: trClusters,
      enNearDuplicateClusters: enClusters,
    );
    expect(result.ok, isTrue, reason: result.issues.join('\n'));
  });

  test('EN wording differs but weights and evidence match per option', () {
    for (final trItem in trPool.items) {
      final enItem = enPool.itemsById[trItem.itemId]!;
      expect(enItem.prompt, isNot(equals(trItem.prompt)), reason: trItem.itemId);
      expect(enItem.primaryDimensions, trItem.primaryDimensions);
      expect(enItem.secondaryDimensions, trItem.secondaryDimensions);
      expect(enItem.semanticCluster, trItem.semanticCluster);

      final enById = {for (final o in enItem.options) o.optionId: o};
      for (final trOpt in trItem.options) {
        final enOpt = enById[trOpt.optionId]!;
        expect(enOpt.text, isNot(equals(trOpt.text)));
        expect(enOpt.behavioralWeights, trOpt.behavioralWeights);
        expect(enOpt.evidenceMeta.version, trOpt.evidenceMeta.version);
        expect(
          enOpt.evidenceMeta.calibrationStatus,
          trOpt.evidenceMeta.calibrationStatus,
        );
        expect(enOpt.evidenceMeta.reviewStatus, trOpt.evidenceMeta.reviewStatus);
        expect(enOpt.evidenceMeta.diagnosticValue, trOpt.evidenceMeta.diagnosticValue);
        expect(
          enOpt.evidenceMeta.behavioralPlausibility,
          trOpt.evidenceMeta.behavioralPlausibility,
        );
        expect(enOpt.evidenceMeta.ambiguity, trOpt.evidenceMeta.ambiguity);
        expect(
          enOpt.evidenceMeta.socialDesirability,
          trOpt.evidenceMeta.socialDesirability,
        );
        expect(enOpt.evidenceMeta.obviousness, trOpt.evidenceMeta.obviousness);
        expect(
          enOpt.evidenceMeta.selfPresentationRisk,
          trOpt.evidenceMeta.selfPresentationRisk,
        );
      }
    }
  });

  test('scoring unchanged for same option IDs across locales', () {
    const scorer = FrequencyBehaviorV2Scorer();
    final sampleIds = trPool.items.take(40).map((i) => i.itemId).toList();
    final responses = [
      for (final id in sampleIds)
        FrequencyBehaviorV2Response(
          itemId: id,
          optionId: '${id}_a',
        ),
    ];
    final trScore = scorer.score(pool: trPool, responses: responses);
    final enScore = scorer.score(pool: enPool, responses: responses);
    expect(trScore.ok, isTrue);
    expect(enScore.ok, isTrue);
    for (final dim in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final trDim = trScore.dimensionScores.firstWhere((d) => d.dimensionId == dim);
      final enDim = enScore.dimensionScores.firstWhere((d) => d.dimensionId == dim);
      expect(enDim.rawSum, trDim.rawSum, reason: dim);
      expect(enDim.capacity, trDim.capacity, reason: dim);
      expect(enDim.normalizedBehavior, trDim.normalizedBehavior, reason: dim);
    }
  });

  test('translation review status after phase 6B/6C EN human review batches', () {
    for (final row in enReview.values) {
      final status = row['translation_review_status'] as String?;
      final id = row['item_id'] as String;
      expect(status, isNotNull);
      expect(
        {
          FrequencyBehaviorV2Contract.translationReviewPendingHuman,
          FrequencyBehaviorV2Contract.translationReviewReviewed,
          FrequencyBehaviorV2Contract.translationReviewCrossCultural,
          FrequencyBehaviorV2Contract.translationReviewEvidenceParity,
        },
        contains(status),
      );
      final n = int.parse(id.split('_q').last);
      if (n >= 1 && n <= 100) {
        expect(status, FrequencyBehaviorV2Contract.translationReviewReviewed,
            reason: id);
      } else {
        expect(status, isNot(FrequencyBehaviorV2Contract.translationReviewReviewed),
            reason: id);
      }
    }
  });

  test('phase 6B/6C human wording corrections preserved', () {
    final q31 = enPool.itemsById['frequency_v2_q0031']!;
    final q45 = enPool.itemsById['frequency_v2_q0045']!;
    final q49 = enPool.itemsById['frequency_v2_q0049']!;
    final q62 = enPool.itemsById['frequency_v2_q0062']!;
    final q74 = enPool.itemsById['frequency_v2_q0074']!;
    final q82 = enPool.itemsById['frequency_v2_q0082']!;
    final q100 = enPool.itemsById['frequency_v2_q0100']!;
    final q31d = q31.options.firstWhere((o) => o.optionId.endsWith('_d'));
    final q62b = q62.options.firstWhere((o) => o.optionId.endsWith('_b'));
    expect(q31d.text, contains("when they're still awake at night"));
    expect(q45.prompt, isNot(contains('[place]')));
    expect(q49.prompt, contains('someone they used to date'));
    expect(q49.prompt.toLowerCase(), isNot(contains(' an ex')));
    expect(q62b.text, contains("I'd be a little disappointed"));
    expect(q74.prompt, contains("You haven't called it a relationship yet."));
    expect(q82.prompt.toLowerCase(), isNot(contains('vibes')));
    expect(q100.prompt, contains('very clear about what they want'));
    expect(q100.prompt.toLowerCase(), isNot(contains('very direct')));
  });

  test('EN bank registry path resolves', () {
    expect(
      FrequencyBehaviorV2BankRegistry.draftPath(
        poolVersion: FrequencyBehaviorV2Contract.poolVersionEnDraft1,
        locale: FrequencyBehaviorV2Contract.localeEn,
      ),
      FrequencyBehaviorV2Contract.draftPoolEnRelativePath,
    );
    expect(
      FrequencyBehaviorV2BankRegistry.isRuntimeSelectable(
        FrequencyBehaviorV2Contract.poolVersionEnDraft1,
      ),
      isFalse,
    );
  });

  test('human review batch files exist (~50 per batch)', () {
    final dir = Directory(
      '${FrequencyBehaviorV2DraftLoader.repoRoot}/${FrequencyBehaviorV2Contract.phase6aEnHumanReviewDirRelativePath}',
    );
    expect(dir.existsSync(), isTrue);
    final batches = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();
    expect(batches.length, greaterThanOrEqualTo(8));
    expect(batches.length, lessThanOrEqualTo(10));
  });

  test('phase 6A audit artifact exists', () {
    final audit = File(
      '${FrequencyBehaviorV2DraftLoader.repoRoot}/${FrequencyBehaviorV2Contract.phase6aEnParityAuditRelativePath}',
    );
    expect(audit.existsSync(), isTrue);
    expect(audit.readAsStringSync(), contains('PASS'));
  });
}
