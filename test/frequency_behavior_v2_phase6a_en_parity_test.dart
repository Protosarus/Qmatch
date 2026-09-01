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

  test('translation review status after phase 6B/6C/6D/6E/6E.1/6F/6G EN human review batches', () {
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
      if (n >= 1 && n <= 300) {
        expect(status, FrequencyBehaviorV2Contract.translationReviewReviewed,
            reason: id);
      } else {
        expect(status, isNot(FrequencyBehaviorV2Contract.translationReviewReviewed),
            reason: id);
      }
    }
    expect(
      enReview.values
          .where(
            (r) =>
                r['translation_review_status'] ==
                FrequencyBehaviorV2Contract.translationReviewReviewed,
          )
          .length,
      300,
    );
    final q227 = enReview['frequency_v2_q0227']!;
    expect(
      (q227['translation_review_flags'] as List<dynamic>? ?? const []),
      contains('possible_cultural_mismatch'),
    );
    final q260 = enReview['frequency_v2_q0260']!;
    expect(
      (q260['translation_review_flags'] as List<dynamic>? ?? const []),
      contains('possible_cultural_mismatch'),
    );
    expect(
      (q260['translation_review_flags'] as List<dynamic>? ?? const []),
      contains('possible_intensity_drift'),
    );
  });

  test('phase 6B/6C/6D/6E/6E.1/6F/6G human wording corrections preserved', () {
    final q31 = enPool.itemsById['frequency_v2_q0031']!;
    final q45 = enPool.itemsById['frequency_v2_q0045']!;
    final q49 = enPool.itemsById['frequency_v2_q0049']!;
    final q62 = enPool.itemsById['frequency_v2_q0062']!;
    final q74 = enPool.itemsById['frequency_v2_q0074']!;
    final q82 = enPool.itemsById['frequency_v2_q0082']!;
    final q100 = enPool.itemsById['frequency_v2_q0100']!;
    final q101 = enPool.itemsById['frequency_v2_q0101']!;
    final q105 = enPool.itemsById['frequency_v2_q0105']!;
    final q110 = enPool.itemsById['frequency_v2_q0110']!;
    final q115 = enPool.itemsById['frequency_v2_q0115']!;
    final q129 = enPool.itemsById['frequency_v2_q0129']!;
    final q132 = enPool.itemsById['frequency_v2_q0132']!;
    final q141 = enPool.itemsById['frequency_v2_q0141']!;
    final q150 = enPool.itemsById['frequency_v2_q0150']!;
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
    expect(
      q101.prompt,
      contains("By noon the next day, you still haven't heard from them."),
    );
    expect(q101.prompt, isNot(contains("didn't hear from them until noon")));
    expect(q105.prompt, contains("It's noon on Saturday"));
    expect(q110.prompt, contains('At an earlier stage than you expected'));
    expect(q115.prompt, contains('spending long stretches of time together'));
    expect(q115.prompt.toLowerCase(), isNot(contains('living together')));
    expect(q129.prompt, contains('forgot to do something important for you'));
    expect(q132.prompt, contains('someone they used to date'));
    expect(q132.prompt.toLowerCase(), isNot(contains('old flame')));
    expect(q141.prompt.toLowerCase(), isNot(contains('abroad')));
    expect(q141.prompt.toLowerCase(), isNot(contains('big time difference')));
    expect(
      q150.prompt,
      contains('much clearer about what they want from the relationship'),
    );
    final q178 = enPool.itemsById['frequency_v2_q0178']!;
    final q189 = enPool.itemsById['frequency_v2_q0189']!;
    final q190 = enPool.itemsById['frequency_v2_q0190']!;
    final q193 = enPool.itemsById['frequency_v2_q0193']!;
    final q195 = enPool.itemsById['frequency_v2_q0195']!;
    final q193a = q193.options.firstWhere((o) => o.optionId.endsWith('_a'));
    final q195a = q195.options.firstWhere((o) => o.optionId.endsWith('_a'));
    expect(q178.prompt, contains("You're on a 40-minute drive."));
    expect(q178.prompt, isNot(contains('Forty minutes into a drive')));
    expect(q189.prompt, contains('completely free day off'));
    expect(q190.prompt, contains('At noon on the weekend'));
    expect(q190.prompt, isNot(contains('Saturday afternoon')));
    expect(q193a.text, contains('keep the gift'));
    expect(q193a.text.toLowerCase(), isNot(contains('stash the gift')));
    expect(
      q195a.text,
      contains('enter their password and secretly read the message'),
    );
    final q160 = enPool.itemsById['frequency_v2_q0160']!;
    final trQ160 = trPool.itemsById['frequency_v2_q0160']!;
    expect(trQ160.prompt, contains('senin evinde'));
    expect(q160.prompt, contains('at your place'));
    expect(q160.prompt, contains('T-shirt in your bathroom'));
    final q229 = enPool.itemsById['frequency_v2_q0229']!;
    final q236 = enPool.itemsById['frequency_v2_q0236']!;
    final q223 = enPool.itemsById['frequency_v2_q0223']!;
    final q225 = enPool.itemsById['frequency_v2_q0225']!;
    final q240 = enPool.itemsById['frequency_v2_q0240']!;
    final q248 = enPool.itemsById['frequency_v2_q0248']!;
    final q218a = enPool.itemsById['frequency_v2_q0218']!
        .options
        .firstWhere((o) => o.optionId.endsWith('_a'));
    final q240b = q240.options.firstWhere((o) => o.optionId.endsWith('_b'));
    expect(
      q229.prompt,
      contains(
        "Your partner thinks they're right, and you're insisting on your own view.",
      ),
    );
    expect(q229.prompt.toLowerCase(), isNot(contains('you think your partner is right')));
    expect(q236.prompt, contains('very touch-oriented'));
    expect(q236.prompt.toLowerCase(), isNot(contains('very touchy')));
    expect(q223.prompt, contains('They like to plan things carefully'));
    expect(q225.prompt, contains('imagining a future together'));
    expect(q240b.text, 'I\'d give them the broad outline.');
    expect(q248.prompt, contains('still figuring things out'));
    expect(q218a.text, contains('start the conversation right away'));
    expect(q218a.text.toLowerCase(), isNot(contains('open up right away')));
    final q258 = enPool.itemsById['frequency_v2_q0258']!;
    final q260 = enPool.itemsById['frequency_v2_q0260']!;
    final q265 = enPool.itemsById['frequency_v2_q0265']!;
    final q268d = enPool.itemsById['frequency_v2_q0268']!
        .options
        .firstWhere((o) => o.optionId.endsWith('_d'));
    final q281 = enPool.itemsById['frequency_v2_q0281']!;
    final q285d = enPool.itemsById['frequency_v2_q0285']!
        .options
        .firstWhere((o) => o.optionId.endsWith('_d'));
    final q294 = enPool.itemsById['frequency_v2_q0294']!;
    final q260c = q260.options.firstWhere((o) => o.optionId.endsWith('_c'));
    final tr252 = trPool.itemsById['frequency_v2_q0252']!;
    final tr292 = trPool.itemsById['frequency_v2_q0292']!;
    expect(q258.prompt.toLowerCase(), contains('dismiss it with'));
    expect(q258.prompt.toLowerCase(), isNot(contains('cut you off')));
    expect(q260.prompt, contains('looks a bit disheveled'));
    expect(q260c.text.toLowerCase(), isNot(contains('panic-text')));
    expect(q265.prompt.toLowerCase(), contains("they're having a great time"));
    expect(
      q268d.text,
      'I\'d say, "I\'m freezing—close it," and firmly insist on my own physical comfort.',
    );
    expect(q281.prompt.startsWith("You're in the first weeks"), isTrue);
    expect(q285d.text, contains('leading the way'));
    expect(q285d.text.toLowerCase(), isNot(contains('steering')));
    expect(q294.prompt.toLowerCase(), isNot(contains('balance achieved in bed')));
    expect(tr252.primaryDimensions, isEmpty);
    expect(tr252.semanticCluster, 'unassigned:conflict');
    expect(tr292.primaryDimensions, isEmpty);
    expect(tr292.semanticCluster, 'unassigned:support');
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
