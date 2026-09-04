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
  late Map<String, dynamic> proposal;
  late Map<String, dynamic> pool;
  late Map<String, Map<String, dynamic>> review;

  setUpAll(() {
    proposal = jsonDecode(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2bProposalRelativePath}',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    pool = jsonDecode(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPoolRelativePath}',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    review = FrequencyBehaviorV2DraftLoader.reviewByItemId();
  });

  test('Phase 2B proposal covers 408 questions / 1632 options only', () {
    expect(proposal['applied_to_pool'], isFalse);
    expect(proposal['calibration_status'], 'uncalibrated');
    expect(proposal['review_status'], 'proposed');
    final items = proposal['items'] as List;
    expect(items,
        hasLength(FrequencyBehaviorV2Contract.phase2bSelectableQuestionCount));
    var optN = 0;
    final qids = <String>{};
    final oids = <String>{};
    for (final raw in items) {
      final q = Map<String, dynamic>.from(raw as Map);
      qids.add(q['question_id'] as String);
      expect(q['options'], hasLength(4));
      for (final oRaw in q['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        oids.add(o['option_id'] as String);
        optN++;
      }
    }
    expect(qids, hasLength(408));
    expect(optN, FrequencyBehaviorV2Contract.phase2bSelectableOptionCount);
    expect(oids, hasLength(1632));
  });

  test(
      'every proposed evidence value is on the five-point grid with all six fields',
      () {
    for (final raw in proposal['items'] as List) {
      final q = Map<String, dynamic>.from(raw as Map);
      for (final oRaw in q['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        final em = Map<String, dynamic>.from(o['evidence_meta'] as Map);
        expect(em['version'], FrequencyBehaviorV2Contract.evidenceMetaVersion);
        expect(em['calibration_status'], 'uncalibrated');
        expect(em['review_status'], 'proposed');
        for (final key in FrequencyBehaviorV2Contract.evidenceMetaKeys) {
          expect(em.containsKey(key), isTrue, reason: '${o['option_id']} $key');
          expect(em[key], isA<num>());
          expect(
            FrequencyBehaviorV2Contract.isAllowedEvidenceValue(
              (em[key] as num).toDouble(),
            ),
            isTrue,
            reason: '${o['option_id']} $key=${em[key]}',
          );
        }
        expect(em['reviewer_rationale'], isNotEmpty);
      }
    }
  });

  test(
      'DROP 72 options are absent from the proposal and remain pending in the pool',
      () {
    final drop =
        FrequencyBehaviorV2DraftLoader.phase1fDropFromSelectableIds.toSet();
    expect(drop, hasLength(18));
    final proposed = <String>{};
    for (final raw in proposal['items'] as List) {
      final q = Map<String, dynamic>.from(raw as Map);
      expect(drop.contains(q['question_id']), isFalse);
      for (final oRaw in q['options'] as List) {
        proposed
            .add(Map<String, dynamic>.from(oRaw as Map)['option_id'] as String);
      }
    }
    var dropOpts = 0;
    for (final id in drop) {
      final item = (pool['items'] as List).cast<Map>().firstWhere(
            (e) => e['item_id'] == id,
          );
      expect(review[id]!['drop_from_selectable'], isTrue);
      for (final oRaw in item['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        dropOpts++;
        expect(proposed.contains(o['option_id']), isFalse);
        final em = Map<String, dynamic>.from(o['evidence_meta'] as Map);
        expect(em['review_status'], 'pending');
        for (final key in FrequencyBehaviorV2Contract.evidenceMetaKeys) {
          expect(em[key], isNull);
        }
      }
    }
    expect(dropOpts, FrequencyBehaviorV2Contract.phase2bDropOptionCount);
  });

  test(
      'source pool fingerprint, text, and weights remain; 2B did not author pool evidence',
      () {
    expect(
      proposal['source_pool_fingerprint_sha256'],
      FrequencyBehaviorV2Contract.draftPoolContentFingerprintSha256,
    );
    expect(proposal['applied_to_pool'], isFalse);
    expect(pool['runtime_selectable'], isFalse);
    final poolById = <String, Map<String, dynamic>>{};
    for (final raw in pool['items'] as List) {
      final item = Map<String, dynamic>.from(raw as Map);
      poolById[item['item_id'] as String] = item;
    }
    for (final raw in proposal['items'] as List) {
      final q = Map<String, dynamic>.from(raw as Map);
      if (FrequencyBehaviorV2DraftLoader.phase2eRewriteIds.contains(
        q['question_id'] as String,
      )) {
        continue;
      }
      final src = poolById[q['question_id'] as String]!;
      final srcOpts = {
        for (final oRaw in src['options'] as List)
          Map<String, dynamic>.from(oRaw as Map)['option_id']:
              Map<String, dynamic>.from(oRaw as Map),
      };
      for (final oRaw in q['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        final srcO = srcOpts[o['option_id']]!;
        expect(o['option_text'], srcO['text']);
        expect(
          jsonEncode(o['behavioral_weights']),
          jsonEncode(srcO['behavioral_weights']),
        );
      }
    }
  });

  test(
      'Phase 2B proposal file remains proposal-only; V1 and live routing unchanged',
      () {
    expect(pool['human_decision_phase'], 'phase2f');
    expect(proposal['applied_to_pool'], isFalse);
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
    final audit = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2bAuditRelativePath}',
    ).readAsStringSync();
    expect(audit.contains('proposal only'), isTrue);
    expect(audit.contains('1632'), isTrue);
    expect(
        File('${Directory.current.path}/pubspec.yaml')
            .readAsStringSync()
            .contains('tool/frequency_behavior_v2/out/'),
        isFalse);
  });
}
