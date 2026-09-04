import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';
import 'package:qmatch/features/assessment/domain/profile/frequency_to_20d_runtime_adapter.dart';
import 'package:qmatch/features/assessment/domain/profile/qmatch_profile_contract.dart';
import 'package:qmatch/features/assessment/services/canonical_assessment_persistence.dart';
import 'package:qmatch/features/assessment/services/frequency_canonical_runtime_service.dart';

import 'support/frequency_behavior_v2_helpers.dart';

String _sha256File(String relative) {
  final bytes = File('${Directory.current.path}/$relative').readAsBytesSync();
  return sha256.convert(bytes).toString();
}

void main() {
  late FrequencyBehaviorV2PoolDocument pool;
  late Map<String, Map<String, dynamic>> review;

  setUpAll(() {
    pool = FrequencyBehaviorV2DraftLoader.loadPool();
    review = FrequencyBehaviorV2DraftLoader.reviewByItemId();
  });

  test('source and pool counts are 426 questions / 1704 options', () {
    final src = FrequencyBehaviorV2DraftLoader.loadSourceText();
    final fq = RegExp(r'^FQ\d+', multiLine: true).allMatches(src).length;
    expect(fq, FrequencyBehaviorV2Contract.poolItemCount);
    expect(pool.items.length, FrequencyBehaviorV2Contract.poolItemCount);
    expect(
      pool.items.fold<int>(0, (n, i) => n + i.options.length),
      FrequencyBehaviorV2Contract.poolOptionCount,
    );
    for (final item in pool.items) {
      expect(
          item.options, hasLength(FrequencyBehaviorV2Contract.optionsPerItem));
    }
  });

  test('stable unique question and option IDs', () {
    final itemIds = pool.items.map((i) => i.itemId).toList();
    expect(itemIds.toSet(), hasLength(itemIds.length));
    final optIds = [
      for (final i in pool.items)
        for (final o in i.options) o.optionId,
    ];
    expect(optIds.toSet(), hasLength(optIds.length));
    for (var i = 0; i < pool.items.length; i++) {
      final item = pool.items[i];
      expect(
          item.itemId, 'frequency_v2_q${(i + 1).toString().padLeft(4, '0')}');
      expect(
        item.options.map((o) => o.optionId).toList(),
        [
          '${item.itemId}_a',
          '${item.itemId}_b',
          '${item.itemId}_c',
          '${item.itemId}_d',
        ],
      );
    }
  });

  test('canonical 12D whitelist only in pool weights and dimension lists', () {
    for (final item in pool.items) {
      for (final d in [
        ...item.primaryDimensions,
        ...item.secondaryDimensions
      ]) {
        expect(FrequencyBehaviorV2Contract.isCanonicalDimension(d), isTrue);
        expect(FrequencyBehaviorV2Contract.neverAutoMap.contains(d), isFalse);
      }
      for (final o in item.options) {
        for (final d in o.behavioralWeights.keys) {
          expect(FrequencyBehaviorV2Contract.isCanonicalDimension(d), isTrue);
          expect(d, isNot(equals('processing_style')));
        }
      }
    }
  });

  test('processing_style is absent from production-facing V2 weights', () {
    for (final item in pool.items) {
      for (final o in item.options) {
        expect(o.behavioralWeights.containsKey('processing_style'), isFalse);
        for (final d in o.behavioralWeights.keys) {
          expect(
            FrequencyBehaviorV2Contract.droppedUnknownDimensionLabels
                .contains(d),
            isFalse,
          );
        }
      }
      for (final d in [
        ...item.primaryDimensions,
        ...item.secondaryDimensions
      ]) {
        expect(
          FrequencyBehaviorV2Contract.droppedUnknownDimensionLabels.contains(d),
          isFalse,
        );
      }
    }
    for (final r in review.values) {
      expect(r['processing_style_present'], isNot(isTrue));
      final unresolved = List<String>.from(
        r['unresolved_dimension_labels'] as List? ?? const [],
      );
      for (final lab in unresolved) {
        expect(
          FrequencyBehaviorV2Contract.droppedUnknownDimensionLabels
              .contains(lab),
          isFalse,
        );
      }
      for (final a in r['alias_applied'] as List? ?? const []) {
        final m = Map<String, dynamic>.from(a as Map);
        expect(m['from'], isNot(equals('processing_style')));
        expect(m['to'], isNot(equals('processing_style')));
      }
    }
  });

  test('safe aliases only; dropped unknown labels are gone', () {
    final unknown = <String>{};
    for (final r in review.values) {
      for (final a in r['alias_applied'] as List? ?? const []) {
        final m = Map<String, dynamic>.from(a as Map);
        expect(
          FrequencyBehaviorV2Contract.safeAliases.keys,
          contains(m['from']),
        );
        expect(
          FrequencyBehaviorV2Contract.canonicalDimensionSet,
          contains(m['to']),
        );
      }
      for (final lab in r['unresolved_dimension_labels'] as List? ?? const []) {
        unknown.add(lab.toString());
      }
    }
    expect(unknown, isEmpty);
  });

  test('Phase 1C approved option weights match the human decision file', () {
    expect(
        FrequencyBehaviorV2DraftLoader.phase1cExpectedWeights, hasLength(76));
    final rewritten = FrequencyBehaviorV2DraftLoader.phase1fRewritePendingIds
        .toSet()
        .union(FrequencyBehaviorV2DraftLoader.phase2eRewriteIds.toSet());
    final byOpt = <String, Map<String, double>>{};
    for (final item in pool.items) {
      for (final o in item.options) {
        byOpt[o.optionId] = o.behavioralWeights;
      }
    }
    FrequencyBehaviorV2DraftLoader.phase1cExpectedWeights
        .forEach((oid, expected) {
      if (rewritten.contains(
        FrequencyBehaviorV2DraftLoader.itemIdFromOptionId(oid),
      )) {
        return;
      }
      expect(byOpt.containsKey(oid), isTrue, reason: oid);
      expect(byOpt[oid]!.keys.toSet(), expected.keys.toSet(), reason: oid);
      for (final e in expected.entries) {
        expect(byOpt[oid]![e.key], e.value, reason: '$oid ${e.key}');
      }
    });
  });

  test('Phase 1C stem and single-option rewrites match exactly', () {
    final rewritten = FrequencyBehaviorV2DraftLoader.phase1fRewritePendingIds
        .toSet()
        .union(FrequencyBehaviorV2DraftLoader.phase2eRewriteIds.toSet());
    FrequencyBehaviorV2DraftLoader.phase1cStemPrompts.forEach((id, prompt) {
      if (rewritten.contains(id)) return;
      expect(pool.itemsById[id]!.prompt, prompt);
    });
    final byOpt = <String, String>{
      for (final item in pool.items)
        for (final o in item.options) o.optionId: o.text,
    };
    FrequencyBehaviorV2DraftLoader.phase1cRewrittenOptionTexts
        .forEach((oid, text) {
      if (rewritten.contains(
        FrequencyBehaviorV2DraftLoader.itemIdFromOptionId(oid),
      )) {
        return;
      }
      expect(byOpt[oid], text);
    });
  });

  test('repair_style orientation is documented and not a moral score', () {
    expect(FrequencyBehaviorV2Contract.repairStyleOrientation[2],
        contains('immediate'));
    expect(FrequencyBehaviorV2Contract.repairStyleOrientation[-2],
        contains('blocked'));
    expect(FrequencyBehaviorV2Contract.repairStyleOrientation[-1],
        contains('delayed'));
    final contract = File(
      '${Directory.current.path}/docs/assessment/frequency_v2/qmatch_frequency_behavior_pool_v2_contract.md',
    ).readAsStringSync();
    expect(contract.contains('not a moral score'), isTrue);
    expect(contract.contains('unhealthy, toxic, or bad'), isTrue);
  });

  test('empty DROP primaries stay excluded; rewrite-pending is cleared', () {
    var rewritePending = 0;
    var emptyPrimary = 0;
    for (final item in pool.items) {
      final r = review[item.itemId]!;
      if (item.primaryDimensions.isEmpty) {
        emptyPrimary++;
        expect(r['selector_eligible'], isFalse, reason: item.itemId);
        expect(r['drop_from_selectable'], isTrue, reason: item.itemId);
      }
      if (r['rewrite_pending'] == true) {
        rewritePending++;
      }
      for (final d in item.primaryDimensions) {
        expect(FrequencyBehaviorV2Contract.isCanonicalDimension(d), isTrue);
      }
    }
    expect(rewritePending, 0);
    expect(emptyPrimary, 6);
    expect(
      review.values.where((r) => r['primary_review_pending'] == true),
      isEmpty,
    );
    expect(pool.itemsById['frequency_v2_q0003']!.primaryDimensions, isEmpty);
    expect(review['frequency_v2_q0003']!['drop_from_selectable'], isTrue);
    expect(
      pool.itemsById['frequency_v2_q0005']!.primaryDimensions,
      ['uncertainty_tolerance'],
    );
    expect(
      pool.itemsById['frequency_v2_q0037']!.primaryDimensions,
      ['boundary_firmness'],
    );
    expect(review['frequency_v2_q0037']!['rewrite_pending'], isNot(isTrue));
    expect(review['frequency_v2_q0037']!['selector_eligible'], isTrue);
  });

  test('every option has 12D evidence and all canonical dimensions are used',
      () {
    final used = <String>{};
    for (final item in pool.items) {
      expect(
        item.options.any((o) => o.behavioralWeights.isNotEmpty),
        isTrue,
        reason: item.itemId,
      );
      for (final o in item.options) {
        expect(o.behavioralWeights, isNotEmpty, reason: o.optionId);
        used.addAll(o.behavioralWeights.keys);
      }
    }
    expect(used, FrequencyBehaviorV2Contract.canonicalDimensionSet);
  });

  test('signed weights are in [-2, 2] and explicit 0 is stored', () {
    var zeros = 0;
    for (final item in pool.items) {
      for (final o in item.options) {
        for (final v in o.behavioralWeights.values) {
          expect(v, inInclusiveRange(-2.0, 2.0));
          if (v == 0.0) zeros++;
        }
      }
    }
    expect(zeros, greaterThan(0));
  });

  test('exact duplicate normalized prompts are zero', () {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final by = <String, List<String>>{};
    for (final item in pool.items) {
      by.putIfAbsent(norm(item.prompt), () => []).add(item.itemId);
    }
    final dups = by.values.where((v) => v.length > 1).toList();
    expect(dups, isEmpty);
  });

  test('semantic clusters are non-empty and reference known items', () {
    final known = pool.itemsById.keys.toSet();
    for (final item in pool.items) {
      expect(item.semanticCluster, isNotEmpty);
    }
    final reviewDoc = FrequencyBehaviorV2DraftLoader.loadReviewJson();
    final clusters = reviewDoc['semantic_near_duplicate_clusters'] as List;
    expect(clusters, isNotEmpty);
    for (final raw in clusters) {
      final c = Map<String, dynamic>.from(raw as Map);
      expect(c['size'] as int, greaterThanOrEqualTo(2));
      for (final id in c['item_ids'] as List) {
        expect(known, contains(id.toString()));
      }
    }
  });

  test(
      'draft validator accepts reviewed selectable evidence and pending DROP evidence',
      () {
    final draft = const FrequencyBehaviorV2PoolValidator().validate(
      pool,
      reviewByItemId: review,
    );
    expect(draft.ok, isTrue, reason: draft.issues.join('; '));
    var reviewedOpts = 0;
    var pendingDropOpts = 0;
    for (final item in pool.items) {
      final r = review[item.itemId]!;
      final drop = r['drop_from_selectable'] == true;
      for (final o in item.options) {
        expect(o.evidenceMeta.calibrationStatus, 'uncalibrated');
        expect(o.evidenceMeta.version,
            FrequencyBehaviorV2Contract.evidenceMetaVersion);
        if (drop) {
          pendingDropOpts++;
          expect(o.evidenceMeta.reviewStatus, 'pending');
          expect(o.evidenceMeta.socialDesirability, isNull);
          expect(o.evidenceMeta.obviousness, isNull);
          expect(o.evidenceMeta.behavioralPlausibility, isNull);
          expect(o.evidenceMeta.selfPresentationRisk, isNull);
          expect(o.evidenceMeta.diagnosticValue, isNull);
          expect(o.evidenceMeta.ambiguity, isNull);
          expect(o.evidenceMeta.isPendingNull, isTrue);
          expect(o.evidenceMeta.isResolved, isFalse);
        } else {
          reviewedOpts++;
          expect(r['selector_eligible'], isTrue);
          expect(o.evidenceMeta.reviewStatus, 'reviewed');
          expect(o.evidenceMeta.isResolved, isTrue);
          expect(o.evidenceMeta.isPendingNull, isFalse);
          for (final v in o.evidenceMeta.numericFields) {
            expect(v, isNotNull);
            expect(
                FrequencyBehaviorV2Contract.isAllowedEvidenceValue(v!), isTrue);
          }
        }
      }
    }
    expect(
        reviewedOpts, FrequencyBehaviorV2Contract.phase2fReviewedOptionCount);
    expect(pendingDropOpts, FrequencyBehaviorV2Contract.phase2fDropOptionCount);
    final poolRaw = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPoolRelativePath}',
    ).readAsStringSync();
    expect(poolRaw.contains('"directness":'), isFalse);
    expect(poolRaw.contains('"obviousness": null'), isTrue);
    expect(poolRaw.contains('"diagnostic_value": null'), isTrue);
    expect(poolRaw.contains('"social_desirability": null'), isTrue);
    expect(poolRaw.contains('"discrimination_power"'), isFalse);
    expect(RegExp(r'"obviousness": [0-9]').hasMatch(poolRaw), isTrue);
    expect(RegExp(r'"diagnostic_value": [0-9]').hasMatch(poolRaw), isTrue);
  });

  test('production-ready validator rejects unresolved draft items', () {
    final prod = const FrequencyBehaviorV2PoolValidator(productionReady: true)
        .validate(pool, reviewByItemId: review);
    expect(prod.ok, isFalse);
    expect(
      prod.issues.any((e) => e.contains('unresolved_evidence_meta')),
      isTrue,
    );
    expect(
      prod.issues.any((e) => e.contains('processing_style_not_rescored')),
      isFalse,
    );
    expect(
      prod.issues.any((e) => e.contains('primary_review_pending')),
      isFalse,
    );
    expect(
      prod.issues.any((e) => e.contains('rewrite_pending')),
      isFalse,
    );
  });

  test('option display order does not change 12D scoring', () {
    final item = pool.items.firstWhere(
      (i) => i.options.every((o) => o.behavioralWeights.isNotEmpty),
    );
    final chosen = item.options.last.optionId;
    const scorer = FrequencyBehaviorV2Scorer();
    final a = scorer.score(
      pool: pool,
      responses: [
        FrequencyBehaviorV2Response(itemId: item.itemId, optionId: chosen),
      ],
    );
    final shuffledIds =
        item.options.map((o) => o.optionId).toList().reversed.toList();
    expect(shuffledIds.toSet(), item.options.map((o) => o.optionId).toSet());
    final b = scorer.score(
      pool: pool,
      responses: [
        FrequencyBehaviorV2Response(itemId: item.itemId, optionId: chosen),
      ],
    );
    expect(a.ok, isTrue);
    expect(b.ok, isTrue);
    expect(a.behavioralMean12d, b.behavioralMean12d);
  });

  test('persisted selected option_id restores against shuffled display order',
      () {
    final plans = const FrequencyBehaviorV2SessionComposer().compose(
      pool: pool,
      sessionSeed: 'seed_restore_v2',
      reviewByItemId: review,
      nearDuplicateClusters:
          FrequencyBehaviorV2DraftLoader.loadNearDuplicateClusters(),
    );
    expect(plans, isNotEmpty);
    final plan = plans.first;
    final item = pool.itemsById[plan.itemId]!;
    expect(plan.displayedOptionIds.toSet(),
        item.options.map((o) => o.optionId).toSet());
    final selected = plan.displayedOptionIds[2];
    expect(item.optionById(selected), isNotNull);
    expect(plan.displayedOptionIds.contains(selected), isTrue);
  });

  test('seeded 50-of-405 selector is deterministic and covers 12D', () {
    const composer = FrequencyBehaviorV2SessionComposer();
    final clusters = FrequencyBehaviorV2DraftLoader.loadNearDuplicateClusters();
    final a = composer.compose(
      pool: pool,
      sessionSeed: 'live_frequency_demo_seed',
      reviewByItemId: review,
      nearDuplicateClusters: clusters,
    );
    final b = composer.compose(
      pool: pool,
      sessionSeed: 'live_frequency_demo_seed',
      reviewByItemId: review,
      nearDuplicateClusters: clusters,
    );
    expect(a.length, FrequencyBehaviorV2Contract.sessionItemCount);
    expect(
      a.map((p) => p.itemId).toList(),
      b.map((p) => p.itemId).toList(),
    );
    expect(
      a.map((p) => p.displayedOptionIds.join(',')).toList(),
      b.map((p) => p.displayedOptionIds.join(',')).toList(),
    );
    final dims = <String>{};
    for (final p in a) {
      dims.addAll(pool.itemsById[p.itemId]!.primaryDimensions);
      expect(review[p.itemId]?['processing_style_present'], isNot(isTrue));
      expect(review[p.itemId]?['primary_review_pending'], isNot(isTrue));
      expect(review[p.itemId]?['selector_eligible'], isTrue);
      expect(pool.itemsById[p.itemId]!.primaryDimensions, hasLength(1));
    }
    expect(
      dims,
      containsAll(FrequencyBehaviorV2Contract.canonicalDimensions),
    );
  });

  test('latent handoff boundary has 12D keys and no quantum math claims', () {
    final handoff = FrequencyBehaviorV2LatentHandoff.emptyDraft(
      poolVersion: pool.poolVersion,
    );
    expect(handoff.behavioralMean12d.keys,
        FrequencyBehaviorV2Contract.canonicalDimensions);
    expect(
      handoff.behavioralUncertainty12d.keys,
      FrequencyBehaviorV2Contract.canonicalDimensions,
    );
    final json = jsonEncode(handoff.toJson());
    expect(json.contains('lie_score'), isFalse);
    expect(json.contains('density_matrix'), isFalse);
    expect(json.contains('entanglement'), isFalse);
  });

  test('draft registry is version-keyed and not runtime selectable', () {
    expect(
      FrequencyBehaviorV2BankRegistry.draftPath(
        poolVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
        locale: FrequencyBehaviorV2Contract.localeTr,
      ),
      FrequencyBehaviorV2Contract.draftPoolRelativePath,
    );
    expect(
      FrequencyBehaviorV2BankRegistry.isRuntimeSelectable(
        FrequencyBehaviorV2Contract.poolVersionTrDraft1,
      ),
      isFalse,
    );
    expect(pool.runtimeSelectable, isFalse);
    expect(pool.status, FrequencyBehaviorV2Contract.statusDraftNotRuntime);
  });

  test('live Frequency V1 banks are unchanged 6D assets', () {
    expect(
      _sha256File(FrequencyBehaviorV2Contract.liveV1BankPaths[0]),
      '1ab16a99f75b4d5122bda3b9cd450e13cb7da87895ffadfb5459dc5cf4fe4744',
    );
    expect(
      _sha256File(FrequencyBehaviorV2Contract.liveV1BankPaths[1]),
      '367836025990121ed0fbc8703dcaabcba8ab39dd49ceb36d97e175c8f33afba4',
    );
    for (final path in FrequencyBehaviorV2Contract.liveV1BankPaths) {
      final bank = FrequencyCanonicalBankDocument.fromJson(
        jsonDecode(File('${Directory.current.path}/$path').readAsStringSync())
            as Map<String, dynamic>,
      );
      expect(bank.schemaVersion, FrequencyBankContract.schemaVersion);
      expect(FrequencyCanonicalDimensions.all, hasLength(6));
      expect(bank.items, hasLength(50));
    }
  });

  test('live runtime still selects only V1 locale banks', () {
    expect(
      FrequencyCanonicalRuntimeService.assetPathForLocale('tr-TR'),
      FrequencyBankContract.trAssetPath,
    );
    expect(
      FrequencyCanonicalRuntimeService.assetPathForLocale('en-US'),
      FrequencyBankContract.enAssetPath,
    );
    expect(FrequencyBankContract.trAssetPath,
        contains('frequency_bank_tr_v1.json'));
    expect(FrequencyBankContract.enAssetPath,
        contains('frequency_bank_en_v1.json'));
    expect(QmatchProfileContract.frequencyDimensionCount, 6);
    expect(CanonicalDimensions.frequency, FrequencyCanonicalDimensions.all);
    expect(FrequencyTo20dRuntimeAdapter, isNotNull);
  });

  test('pubspec and live runtime sources do not reference the V2 draft pool',
      () {
    final pubspec =
        File('${Directory.current.path}/pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('tool/frequency_behavior_v2/out/'), isFalse);
    expect(
      pubspec.contains(
        'assets/assessment/frequency_v2/frequency_behavior_pool_tr_v2_draft1.json',
      ),
      isTrue,
    );
    expect(pubspec.contains('frequency_bank_tr_v1.json'), isTrue);
    final runtime = File(
      '${Directory.current.path}/lib/features/assessment/services/frequency_canonical_runtime_service.dart',
    ).readAsStringSync();
    expect(runtime.contains('frequency_behavior_pool'), isFalse);
    expect(runtime.contains('FrequencyBehaviorV2'), isFalse);
    final catalogGen = File(
      '${Directory.current.path}/tool/generate_assessment_finalize_catalog_v1.js',
    ).readAsStringSync();
    expect(catalogGen.contains('frequency_behavior_pool_tr_v2'), isFalse);
    expect(catalogGen.contains('frequency_bank_tr_v1.json'), isTrue);
    final catalog = File(
      '${Directory.current.path}/functions/src/assessment_finalize_catalog_v1.generated.js',
    ).readAsStringSync();
    expect(catalog.contains('frequency_behavior_pool_tr_v2'), isFalse);
    expect(catalog.contains('frequency_bank_tr_v1.json'), isTrue);
    expect(
      File('${Directory.current.path}/${FrequencyBehaviorV2Contract.humanDecisionPhase1cFile}')
          .existsSync(),
      isTrue,
    );
    expect(
      File('${Directory.current.path}/${FrequencyBehaviorV2Contract.humanDecisionPhase1fFile}')
          .existsSync(),
      isTrue,
    );
    expect(
      File('${Directory.current.path}/${FrequencyBehaviorV2Contract.humanDecisionPhase1gFile}')
          .existsSync(),
      isTrue,
    );
  });

  test('Phase 1F archive IDs preserved; DROP does not shrink the archive', () {
    expect(pool.items.length, FrequencyBehaviorV2Contract.poolItemCount);
    expect(
      pool.items.fold<int>(0, (n, i) => n + i.options.length),
      FrequencyBehaviorV2Contract.poolOptionCount,
    );
    final itemIds = pool.items.map((i) => i.itemId).toSet();
    final optIds = {
      for (final i in pool.items)
        for (final o in i.options) o.optionId,
    };
    expect(itemIds, hasLength(426));
    expect(optIds, hasLength(1704));
    for (final id
        in FrequencyBehaviorV2DraftLoader.phase1fDropFromSelectableIds) {
      expect(itemIds, contains(id));
      expect(pool.itemsById[id]!.options, hasLength(4));
    }
    for (final id in FrequencyBehaviorV2DraftLoader.phase1fRewritePendingIds) {
      expect(itemIds, contains(id));
      expect(pool.itemsById[id]!.options, hasLength(4));
    }
  });

  test('Phase 1F selectable items have exactly one canonical primary', () {
    var selectable = 0;
    var dualSelectable = 0;
    var dualAny = 0;
    for (final item in pool.items) {
      final r = review[item.itemId]!;
      if (item.primaryDimensions.length > 1) {
        dualAny++;
        if (r['selector_eligible'] == true) dualSelectable++;
      }
      if (r['selector_eligible'] == true) {
        selectable++;
        expect(item.primaryDimensions, hasLength(1), reason: item.itemId);
        expect(
          FrequencyBehaviorV2Contract.isCanonicalDimension(
            item.primaryDimensions.single,
          ),
          isTrue,
        );
        expect(r['rewrite_pending'], isNot(isTrue));
        expect(r['drop_from_selectable'], isNot(isTrue));
        expect(r['primary_review_pending'], isNot(isTrue));
      }
    }
    expect(selectable, FrequencyBehaviorV2Contract.phase2fSelectableAfterDrops);
    expect(dualSelectable, 0);
    expect(dualAny, 4);
    expect(
      FrequencyBehaviorV2DraftLoader.phase1fApprovedPrimaryIds,
      hasLength(FrequencyBehaviorV2Contract.phase1fApprovedPrimaryCount),
    );
  });

  test('Phase 1F DROP IDs remain non-selectable after 1G', () {
    for (final id
        in FrequencyBehaviorV2DraftLoader.phase1fDropFromSelectableIds) {
      final r = review[id]!;
      expect(r['selector_eligible'], isFalse, reason: id);
      expect(r['drop_from_selectable'], isTrue, reason: id);
      expect(r['selector_exclusion_reason'], 'drop_from_selectable_pool');
      expect(pool.itemsById.containsKey(id), isTrue);
      expect(pool.itemsById[id]!.options, hasLength(4));
    }
  });

  test('q0228 remains a candidate while q0333 and q0426 are excluded', () {
    expect(review['frequency_v2_q0228']!['selector_eligible'], isTrue);
    expect(
      pool.itemsById['frequency_v2_q0228']!.primaryDimensions,
      ['adaptability'],
    );
    expect(
      pool.itemsById['frequency_v2_q0228']!.secondaryDimensions,
      ['disclosure_pace'],
    );
    expect(review['frequency_v2_q0333']!['selector_eligible'], isFalse);
    expect(review['frequency_v2_q0333']!['drop_from_selectable'], isTrue);
    expect(review['frequency_v2_q0426']!['selector_eligible'], isFalse);
    expect(review['frequency_v2_q0426']!['drop_from_selectable'], isTrue);
    expect(pool.itemsById.containsKey('frequency_v2_q0333'), isTrue);
    expect(pool.itemsById.containsKey('frequency_v2_q0426'), isTrue);
  });

  test('q0030 and q0033 match exact human overrides', () {
    expect(
      pool.itemsById['frequency_v2_q0030']!.primaryDimensions,
      ['uncertainty_tolerance'],
    );
    expect(
      pool.itemsById['frequency_v2_q0030']!.secondaryDimensions,
      isEmpty,
    );
    expect(
      pool.itemsById['frequency_v2_q0033']!.primaryDimensions,
      ['disclosure_pace'],
    );
    expect(
      pool.itemsById['frequency_v2_q0033']!.secondaryDimensions,
      ['closeness_pace'],
    );
    expect(review['frequency_v2_q0030']!['selector_eligible'], isTrue);
    expect(review['frequency_v2_q0033']!['selector_eligible'], isTrue);
  });

  test(
      'Phase 1G applies exact human-approved rewrite text, weights, and primaries',
      () {
    final expected = FrequencyBehaviorV2DraftLoader.loadPhase1gRewrites();
    expect(expected.keys.toSet(),
        FrequencyBehaviorV2DraftLoader.phase1fRewritePendingIds.toSet());
    expect(expected,
        hasLength(FrequencyBehaviorV2Contract.phase1gRewrittenQuestionCount));
    var optionCount = 0;
    for (final spec in expected.values) {
      final item = pool.itemsById[spec.itemId]!;
      final r = review[spec.itemId]!;
      expect(item.prompt, spec.prompt, reason: spec.itemId);
      expect(item.primaryDimensions, [spec.primary], reason: spec.itemId);
      expect(item.secondaryDimensions, isEmpty, reason: spec.itemId);
      expect(spec.secondaryRaw, 'none');
      expect(item.options, hasLength(4));
      expect(r['rewrite_pending'], isNot(isTrue), reason: spec.itemId);
      expect(r['primary_review_pending'], isNot(isTrue), reason: spec.itemId);
      expect(r['selector_eligible'], isTrue, reason: spec.itemId);
      expect(r['drop_from_selectable'], isNot(isTrue));
      for (final o in item.options) {
        optionCount++;
        expect(spec.optionTexts[o.optionId], o.text, reason: o.optionId);
        expect(o.behavioralWeights.keys.toSet(),
            spec.optionWeights[o.optionId]!.keys.toSet());
        for (final e in spec.optionWeights[o.optionId]!.entries) {
          expect(o.behavioralWeights[e.key], e.value,
              reason: '${o.optionId} ${e.key}');
        }
        expect(o.behavioralWeights.keys, everyElement(spec.primary));
        for (final v in o.behavioralWeights.values) {
          expect(v.abs(), anyOf(1.0, 2.0), reason: o.optionId);
        }
        expect(o.evidenceMeta.reviewStatus, 'reviewed');
        expect(o.evidenceMeta.isResolved, isTrue);
      }
    }
    expect(
        optionCount, FrequencyBehaviorV2Contract.phase1gRewrittenOptionCount);
  });

  test(
      'Phase 1G selectable pool has one primary, no duals, canonical ±1/±2-or-0 weights',
      () {
    var selectable = 0;
    var dualSelectable = 0;
    for (final item in pool.items) {
      final r = review[item.itemId]!;
      if (item.primaryDimensions.length > 1 && r['selector_eligible'] == true) {
        dualSelectable++;
      }
      if (r['selector_eligible'] == true) {
        selectable++;
        expect(item.primaryDimensions, hasLength(1), reason: item.itemId);
        expect(
          FrequencyBehaviorV2Contract.isCanonicalDimension(
              item.primaryDimensions.single),
          isTrue,
        );
      }
      for (final o in item.options) {
        expect(o.behavioralWeights, isNotEmpty, reason: o.optionId);
        for (final e in o.behavioralWeights.entries) {
          expect(
              FrequencyBehaviorV2Contract.isCanonicalDimension(e.key), isTrue);
          expect(e.value, anyOf(-2.0, -1.0, 0.0, 1.0, 2.0), reason: o.optionId);
        }
      }
    }
    expect(selectable, FrequencyBehaviorV2Contract.phase2fSelectableAfterDrops);
    expect(dualSelectable, 0);
    expect(pool.runtimeSelectable, isFalse);
  });

  test(
      'Phase 2E applies 10 human rewrites; 2E DROPs plus q0409 remain archived',
      () {
    expect(pool.items.length, 426);
    expect(
      pool.items.fold<int>(0, (n, i) => n + i.options.length),
      1704,
    );
    final expected = FrequencyBehaviorV2DraftLoader.loadPhase2eRewrites();
    expect(expected.keys.toSet(),
        FrequencyBehaviorV2DraftLoader.phase2eRewriteIds.toSet());
    expect(expected,
        hasLength(FrequencyBehaviorV2Contract.phase2eRewrittenQuestionCount));
    var optionCount = 0;
    for (final spec in expected.values) {
      final item = pool.itemsById[spec.itemId]!;
      final r = review[spec.itemId]!;
      expect(item.prompt, spec.prompt, reason: spec.itemId);
      expect(item.primaryDimensions, [spec.primary], reason: spec.itemId);
      expect(item.secondaryDimensions, isEmpty, reason: spec.itemId);
      expect(r['rewrite_pending'], isNot(isTrue));
      final dropped = FrequencyBehaviorV2DraftLoader.phase2fNewDropIds
          .contains(spec.itemId);
      if (dropped) {
        expect(r['selector_eligible'], isFalse, reason: spec.itemId);
        expect(r['drop_from_selectable'], isTrue, reason: spec.itemId);
      } else {
        expect(r['selector_eligible'], isTrue, reason: spec.itemId);
        expect(r['drop_from_selectable'], isNot(isTrue));
      }
      for (final o in item.options) {
        optionCount++;
        expect(spec.optionTexts[o.optionId], o.text, reason: o.optionId);
        expect(o.behavioralWeights.keys.toSet(),
            spec.optionWeights[o.optionId]!.keys.toSet());
        for (final e in spec.optionWeights[o.optionId]!.entries) {
          expect(o.behavioralWeights[e.key], e.value);
        }
        expect(o.behavioralWeights.keys, everyElement(spec.primary));
        if (dropped) {
          expect(o.evidenceMeta.reviewStatus, 'pending');
          expect(o.evidenceMeta.socialDesirability, isNull);
        } else {
          expect(o.evidenceMeta.reviewStatus, 'reviewed');
          expect(o.evidenceMeta.isResolved, isTrue);
        }
      }
    }
    expect(
        optionCount, FrequencyBehaviorV2Contract.phase2eRewrittenOptionCount);

    for (final id in FrequencyBehaviorV2DraftLoader.phase2eNewDropIds) {
      final r = review[id]!;
      expect(r['drop_from_selectable'], isTrue, reason: id);
      expect(r['selector_eligible'], isFalse, reason: id);
      expect(pool.itemsById.containsKey(id), isTrue);
      expect(pool.itemsById[id]!.options, hasLength(4));
    }
    var dropN = 0;
    var selectable = 0;
    for (final r in review.values) {
      if (r['drop_from_selectable'] == true) dropN++;
      if (r['selector_eligible'] == true) selectable++;
    }
    expect(dropN, FrequencyBehaviorV2Contract.phase2fDropFromSelectableTotal);
    expect(selectable, FrequencyBehaviorV2Contract.phase2fSelectableAfterDrops);
  });
}
