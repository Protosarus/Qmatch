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

const _overrideOptionIds = {
  'frequency_v2_q0020_b',
  'frequency_v2_q0026_a',
  'frequency_v2_q0026_b',
  'frequency_v2_q0030_a',
  'frequency_v2_q0030_b',
  'frequency_v2_q0035_b',
  'frequency_v2_q0035_c',
  'frequency_v2_q0317_a',
  'frequency_v2_q0317_b',
  'frequency_v2_q0393_a',
  'frequency_v2_q0393_b',
};

const _overrideFields = {
  'social_desirability',
  'obviousness',
  'self_presentation_risk',
};

void main() {
  late Map<String, dynamic> pool;
  late Map<String, dynamic> finalEvidence;
  late Map<String, dynamic> fresh;
  late Map<String, Map<String, dynamic>> review;
  late String report;

  setUpAll(() {
    pool = jsonDecode(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPoolRelativePath}',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    finalEvidence = jsonDecode(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2fFinalEvidenceRelativePath}',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    fresh = jsonDecode(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2eRewritten10ProposalRelativePath}',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    review = FrequencyBehaviorV2DraftLoader.reviewByItemId();
    report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2fApplyReportRelativePath}',
    ).readAsStringSync();
  });

  test('archive 426/1704; selectable 405; DROP 21 including q0409', () {
    expect(pool['runtime_selectable'], isFalse);
    expect(pool['human_decision_phase'], 'phase2f');
    expect(pool['human_decision_file'],
        FrequencyBehaviorV2Contract.humanDecisionPhase2fFile);
    expect((pool['items'] as List),
        hasLength(FrequencyBehaviorV2Contract.poolItemCount));
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
    expect(opts, FrequencyBehaviorV2Contract.poolOptionCount);
    expect(itemIds, hasLength(426));
    expect(optIds, hasLength(1704));

    var dropN = 0;
    var selectable = 0;
    var dualSel = 0;
    var rewritePending = 0;
    for (final id in itemIds) {
      final r = review[id]!;
      if (r['drop_from_selectable'] == true) dropN++;
      if (r['rewrite_pending'] == true) rewritePending++;
      if (r['selector_eligible'] == true) {
        selectable++;
        final item = (pool['items'] as List)
            .cast<Map>()
            .firstWhere((e) => e['item_id'] == id);
        expect((item['primary_dimensions'] as List), hasLength(1), reason: id);
        if ((item['primary_dimensions'] as List).length > 1) dualSel++;
      }
    }
    expect(dropN, FrequencyBehaviorV2Contract.phase2fDropFromSelectableTotal);
    expect(selectable, FrequencyBehaviorV2Contract.phase2fSelectableAfterDrops);
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
    for (final id in FrequencyBehaviorV2DraftLoader.phase2fNewDropIds) {
      expect(review[id]!['drop_from_selectable'], isTrue, reason: id);
      expect(review[id]!['selector_eligible'], isFalse);
      expect(review[id]!['selector_exclusion_reason'],
          'drop_from_selectable_pool');
      expect(itemIds, contains(id));
      expect(optIds, containsAll(['${id}_a', '${id}_b', '${id}_c', '${id}_d']));
    }
  });

  test(
      'final evidence dataset has 405 questions / 1620 options and excludes q0409',
      () {
    expect(finalEvidence['applied_to_pool'], isTrue);
    expect(finalEvidence['runtime_selectable'], isFalse);
    expect(finalEvidence['version'],
        FrequencyBehaviorV2Contract.evidenceMetaVersion);
    expect(finalEvidence['calibration_status'], 'uncalibrated');
    expect(finalEvidence['review_status'], 'reviewed');
    expect(
      finalEvidence['human_authority'],
      FrequencyBehaviorV2Contract.humanDecisionPhase2fFile,
    );
    expect(
      finalEvidence['human_override_field_change_count'],
      FrequencyBehaviorV2Contract.phase2fHumanOverrideFieldChangeCount,
    );
    final items = finalEvidence['items'] as List;
    expect(items,
        hasLength(FrequencyBehaviorV2Contract.phase2fReviewedQuestionCount));
    final ids = <String>{};
    var optN = 0;
    for (final raw in items) {
      final q = Map<String, dynamic>.from(raw as Map);
      ids.add(q['question_id'] as String);
      expect(q['options'], hasLength(4));
      for (final oRaw in q['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        optN++;
        final em = Map<String, dynamic>.from(o['evidence_meta'] as Map);
        expect(em['version'], FrequencyBehaviorV2Contract.evidenceMetaVersion);
        expect(em['calibration_status'], 'uncalibrated');
        expect(em['review_status'], 'reviewed');
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
    expect(ids, hasLength(405));
    expect(optN, FrequencyBehaviorV2Contract.phase2fReviewedOptionCount);
    expect(ids.contains('frequency_v2_q0409'), isFalse);
    for (final id
        in FrequencyBehaviorV2DraftLoader.phase2fUnchangedRewrittenIds) {
      expect(ids, contains(id));
    }
    for (final id
        in FrequencyBehaviorV2DraftLoader.phase2fOverrideQuestionIds) {
      expect(ids, contains(id));
    }
  });

  test(
      'selectable pool evidence is reviewed on-grid; DROP including q0409 stays pending/null',
      () {
    var reviewedQ = 0;
    var reviewedOpt = 0;
    var pendingDropOpt = 0;
    final poolById = <String, Map<String, dynamic>>{
      for (final raw in pool['items'] as List)
        Map<String, dynamic>.from(raw as Map)['item_id'] as String:
            Map<String, dynamic>.from(raw as Map),
    };
    final finalById = <String, Map<String, dynamic>>{
      for (final raw in finalEvidence['items'] as List)
        Map<String, dynamic>.from(raw as Map)['question_id'] as String:
            Map<String, dynamic>.from(raw as Map),
    };
    for (final id in poolById.keys) {
      final r = review[id]!;
      final item = poolById[id]!;
      final drop = r['drop_from_selectable'] == true;
      if (drop) {
        expect(finalById.containsKey(id), isFalse, reason: id);
        expect(r['selector_eligible'], isFalse);
        for (final oRaw in item['options'] as List) {
          final o = Map<String, dynamic>.from(oRaw as Map);
          pendingDropOpt++;
          final em = Map<String, dynamic>.from(o['evidence_meta'] as Map);
          expect(em['review_status'], 'pending', reason: o['option_id']);
          expect(em['calibration_status'], 'uncalibrated');
          expect(
              em['version'], FrequencyBehaviorV2Contract.evidenceMetaVersion);
          for (final key in FrequencyBehaviorV2Contract.evidenceMetaKeys) {
            expect(em[key], isNull, reason: '${o['option_id']} $key');
          }
        }
        continue;
      }
      reviewedQ++;
      expect(r['selector_eligible'], isTrue);
      expect(finalById.containsKey(id), isTrue, reason: id);
      final qev = finalById[id]!;
      final evOpts = {
        for (final oRaw in qev['options'] as List)
          Map<String, dynamic>.from(oRaw as Map)['option_id']:
              Map<String, dynamic>.from(oRaw as Map),
      };
      for (final oRaw in item['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        reviewedOpt++;
        final em = Map<String, dynamic>.from(o['evidence_meta'] as Map);
        expect(em['review_status'], 'reviewed', reason: o['option_id']);
        expect(em['calibration_status'], 'uncalibrated');
        expect(em['version'], FrequencyBehaviorV2Contract.evidenceMetaVersion);
        final src = evOpts[o['option_id']]!;
        expect(src['option_text'], o['text']);
        final srcEm = Map<String, dynamic>.from(src['evidence_meta'] as Map);
        for (final key in FrequencyBehaviorV2Contract.evidenceMetaKeys) {
          expect(em[key], isA<num>(), reason: '${o['option_id']} $key');
          expect(
            FrequencyBehaviorV2Contract.isAllowedEvidenceValue(
              (em[key] as num).toDouble(),
            ),
            isTrue,
          );
          expect(
            (em[key] as num).toDouble(),
            closeTo((srcEm[key] as num).toDouble(), 1e-9),
          );
        }
      }
    }
    expect(reviewedQ, FrequencyBehaviorV2Contract.phase2fReviewedQuestionCount);
    expect(reviewedOpt, FrequencyBehaviorV2Contract.phase2fReviewedOptionCount);
    expect(pendingDropOpt, FrequencyBehaviorV2Contract.phase2fDropOptionCount);
  });

  test(
      'Phase 2E human evidence overrides landed exactly; unspecified scores unchanged',
      () {
    expect(_overrideOptionIds, hasLength(11));
    final poolOpts = <String, Map<String, dynamic>>{};
    for (final raw in pool['items'] as List) {
      final item = Map<String, dynamic>.from(raw as Map);
      for (final oRaw in item['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        poolOpts[o['option_id'] as String] = o;
      }
    }
    for (final oid in _overrideOptionIds) {
      final em =
          Map<String, dynamic>.from(poolOpts[oid]!['evidence_meta'] as Map);
      for (final field in _overrideFields) {
        expect(
          (em[field] as num).toDouble(),
          closeTo(0.75, 1e-9),
          reason: '$oid $field',
        );
      }
    }
    expect(
      _overrideOptionIds.length * _overrideFields.length,
      FrequencyBehaviorV2Contract.phase2fHumanOverrideFieldChangeCount,
    );

    final freshById = <String, Map<String, dynamic>>{
      for (final raw in fresh['items'] as List)
        Map<String, dynamic>.from(raw as Map)['question_id'] as String:
            Map<String, dynamic>.from(raw as Map),
    };
    for (final qid
        in FrequencyBehaviorV2DraftLoader.phase2fUnchangedRewrittenIds) {
      final q = freshById[qid]!;
      for (final oRaw in q['options'] as List) {
        final src = Map<String, dynamic>.from(oRaw as Map);
        final poolO = poolOpts[src['option_id'] as String]!;
        final srcEm = Map<String, dynamic>.from(src['evidence_meta'] as Map);
        final poolEm = Map<String, dynamic>.from(poolO['evidence_meta'] as Map);
        expect(poolO['text'], src['option_text']);
        for (final key in FrequencyBehaviorV2Contract.evidenceMetaKeys) {
          expect(
            (poolEm[key] as num).toDouble(),
            closeTo((srcEm[key] as num).toDouble(), 1e-9),
            reason: '${src['option_id']} $key',
          );
        }
      }
    }
    expect(poolOpts.containsKey('frequency_v2_q0409_a'), isTrue);
    final q0409 = Map<String, dynamic>.from(
      (pool['items'] as List)
          .cast<Map>()
          .firstWhere((e) => e['item_id'] == 'frequency_v2_q0409'),
    );
    for (final oRaw in q0409['options'] as List) {
      final em = Map<String, dynamic>.from(
        Map<String, dynamic>.from(oRaw as Map)['evidence_meta'] as Map,
      );
      expect(em['review_status'], 'pending');
      for (final key in FrequencyBehaviorV2Contract.evidenceMetaKeys) {
        expect(em[key], isNull);
      }
    }
  });

  test('apply report and safety: V2 dormant, V1 and live routing unchanged',
      () {
    expect(report.contains('Archive questions: **426**'), isTrue);
    expect(report.contains('DROP questions: **21**'), isTrue);
    expect(report.contains('Dormant selectable questions: **405**'), isTrue);
    expect(
        report.contains('Human override field-change count: **33**'), isTrue);
    expect(report.contains('Pending/null DROP options: **84**'), isTrue);
    expect(
      report.contains(
        'FREQUENCY V2 PHASE 2F FINAL EVIDENCE PRIORS APPLIED TO 405 DORMANT SELECTABLE QUESTIONS — V2 STILL DORMANT',
      ),
      isTrue,
    );
    expect(report.contains('not auto-corrected'), isTrue);
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
