import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import 'support/frequency_behavior_v2_helpers.dart';

String _sha256File(String relative) {
  final bytes = File('${Directory.current.path}/$relative').readAsBytesSync();
  return sha256.convert(bytes).toString();
}

void main() {
  late Map<String, dynamic> pool;
  late Map<String, dynamic> revised;
  late Map<String, dynamic> fresh;
  late Map<String, Map<String, dynamic>> review;
  late String report;

  setUpAll(() {
    pool = jsonDecode(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPoolRelativePath}',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    revised = jsonDecode(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2eRevisedProposalRelativePath}',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    fresh = jsonDecode(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2eRewritten10ProposalRelativePath}',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    review = FrequencyBehaviorV2DraftLoader.reviewByItemId();
    report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2eApplyReportRelativePath}',
    ).readAsStringSync();
  });

  test(
      'archive stays 426/1704; 2E DROPs remain; 2E artifacts are proposal-only',
      () {
    expect(pool['runtime_selectable'], isFalse);
    expect((pool['items'] as List), hasLength(426));
    var opts = 0;
    final itemIds = <String>{};
    final optIds = <String>{};
    for (final raw in pool['items'] as List) {
      final item = Map<String, dynamic>.from(raw as Map);
      itemIds.add(item['item_id'] as String);
      expect(item['options'], hasLength(4));
      for (final oRaw in item['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        optIds.add(o['option_id'] as String);
        opts++;
      }
    }
    expect(opts, 1704);
    expect(itemIds, hasLength(426));
    expect(optIds, hasLength(1704));

    var rewritePending = 0;
    var dualSel = 0;
    for (final id in itemIds) {
      final r = review[id]!;
      if (r['rewrite_pending'] == true) rewritePending++;
      if (r['selector_eligible'] == true) {
        final item = (pool['items'] as List)
            .cast<Map>()
            .firstWhere((e) => e['item_id'] == id);
        expect((item['primary_dimensions'] as List), hasLength(1), reason: id);
        if ((item['primary_dimensions'] as List).length > 1) dualSel++;
      }
    }
    expect(dualSel, 0);
    expect(rewritePending, 0);
    for (final id
        in FrequencyBehaviorV2DraftLoader.phase1fDropFromSelectableIds) {
      expect(review[id]!['drop_from_selectable'], isTrue, reason: id);
      expect(review[id]!['selector_eligible'], isFalse);
    }
    for (final id in FrequencyBehaviorV2DraftLoader.phase2eNewDropIds) {
      expect(review[id]!['drop_from_selectable'], isTrue, reason: id);
      expect(review[id]!['selector_eligible'], isFalse);
      expect(itemIds, contains(id));
    }
    expect(revised['applied_to_pool'], isFalse);
    expect(fresh['applied_to_pool'], isFalse);
  });

  test('revised proposal excludes new DROPs and stale rewritten evidence', () {
    expect(revised['applied_to_pool'], isFalse);
    expect(revised['q0375_keep_override'], isTrue);
    expect(
      revised['question_field_corrections_applied'],
      FrequencyBehaviorV2Contract.phase2eQuestionFieldCorrectionCount,
    );
    expect(
      revised['dv_too_low_corrections_applied'],
      FrequencyBehaviorV2Contract.phase2eDvTooLowCorrectionCount,
    );
    expect(
      revised['dv_justified_left_unchanged'],
      FrequencyBehaviorV2Contract.phase2eDvJustifiedUnchangedCount,
    );
    final items = revised['items'] as List;
    expect(
        items,
        hasLength(
            FrequencyBehaviorV2Contract.phase2eRevisedProposalQuestionCount));
    final ids = {
      for (final raw in items)
        Map<String, dynamic>.from(raw as Map)['question_id'] as String,
    };
    for (final id in FrequencyBehaviorV2DraftLoader.phase2eNewDropIds) {
      expect(ids.contains(id), isFalse, reason: id);
    }
    for (final id in FrequencyBehaviorV2DraftLoader.phase2eRewriteIds) {
      expect(ids.contains(id), isFalse, reason: id);
    }
    expect(ids, contains('frequency_v2_q0375'));
    for (final raw in items) {
      final q = Map<String, dynamic>.from(raw as Map);
      for (final oRaw in q['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        final em = Map<String, dynamic>.from(o['evidence_meta'] as Map);
        for (final key in FrequencyBehaviorV2Contract.evidenceMetaKeys) {
          expect(
            FrequencyBehaviorV2Contract.isAllowedEvidenceValue(
              (em[key] as num).toDouble(),
            ),
            isTrue,
          );
        }
      }
    }
  });

  test(
      'fresh 10-question evidence proposal has 40 on-grid scores and stayed proposal-only',
      () {
    expect(fresh['applied_to_pool'], isFalse);
    expect(fresh['stale_phase2b_evidence_invalidated'], isTrue);
    final items = fresh['items'] as List;
    expect(items, hasLength(10));
    var optN = 0;
    final expected = FrequencyBehaviorV2DraftLoader.loadPhase2eRewrites();
    for (final raw in items) {
      final q = Map<String, dynamic>.from(raw as Map);
      final spec = expected[q['question_id'] as String]!;
      expect(q['options'], hasLength(4));
      expect(q['primary_dimension'], spec.primary);
      for (final oRaw in q['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        optN++;
        expect(o['option_text'], spec.optionTexts[o['option_id']]);
        final em = Map<String, dynamic>.from(o['evidence_meta'] as Map);
        expect(em['review_status'], 'proposed');
        expect(em['calibration_status'], 'uncalibrated');
        for (final key in FrequencyBehaviorV2Contract.evidenceMetaKeys) {
          expect(
            FrequencyBehaviorV2Contract.isAllowedEvidenceValue(
              (em[key] as num).toDouble(),
            ),
            isTrue,
            reason: '${o['option_id']} $key=${em[key]}',
          );
        }
      }
    }
    expect(optN, 40);
    expect(
      revised['source_pool_fingerprint_sha256_after_rewrites'],
      FrequencyBehaviorV2Contract.draftPoolContentFingerprintSha256Phase2e,
    );
    expect(report.contains('406'), isTrue);
    expect(report.contains('NO EVIDENCE VALUES APPLIED TO POOL'), isTrue);
  });

  test('Phase 2E does not touch V1, live routing, or C2', () {
    expect(
      _sha256File(FrequencyBehaviorV2Contract.liveV1BankPaths[0]),
      '1ab16a99f75b4d5122bda3b9cd450e13cb7da87895ffadfb5459dc5cf4fe4744',
    );
    expect(
      _sha256File(FrequencyBehaviorV2Contract.liveV1BankPaths[1]),
      '367836025990121ed0fbc8703dcaabcba8ab39dd49ceb36d97e175c8f33afba4',
    );
    expect(FrequencyBankContract.trAssetPath,
        contains('frequency_bank_tr_v1.json'));
    expect(
      File('${Directory.current.path}/pubspec.yaml')
          .readAsStringSync()
          .contains('frequency_behavior_pool_tr_v2'),
      isFalse,
    );
  });
}
