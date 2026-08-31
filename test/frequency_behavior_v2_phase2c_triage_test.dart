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
  late Map<String, dynamic> triage;
  late Map<String, dynamic> proposal;
  late Map<String, dynamic> pool;
  late String triageMd;

  setUpAll(() {
    triage = jsonDecode(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2cTriageJsonRelativePath}',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
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
    triageMd = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2cTriageMdRelativePath}',
    ).readAsStringSync();
  });

  test('Phase 2C covers all 408 selectable questions and does not apply scores',
      () {
    expect(triage['applied_to_pool'], isFalse);
    expect(triage['scores_modified'], isFalse);
    expect(triage['proposal_modified'], isFalse);
    expect(triage['calibration_status'], 'uncalibrated');
    expect(triage['runtime_selectable'], isFalse);
    expect(triage['overall_finding'], 'OVERFLAGGED_BY_REVIEW_RULE');
    final questions = triage['questions'] as List;
    expect(questions,
        hasLength(FrequencyBehaviorV2Contract.phase2cTriageQuestionCount));
    expect(
      (triage['real_review_required_ids'] as List).length,
      FrequencyBehaviorV2Contract.phase2cRealReviewRequiredCount,
    );
  });

  test('triage classes and KEEP/CLEAR split the previous 397 flags', () {
    const allowed = {'CLEAN', 'ACCEPTABLE_COMPLEXITY', 'REAL_REVIEW_REQUIRED'};
    const reasons = {
      'SD_DOMINANCE',
      'OBVIOUS_TEST_ANSWER',
      'LOW_PLAUSIBILITY',
      'OPTION_DUPLICATION',
      'HIGH_AMBIGUITY',
      'PRIMARY_AXIS_CONFUSION',
      'CULTURAL_DEPENDENCE',
      'SELF_PRESENTATION_HEAVY',
      'LOW_DIAGNOSTIC_CONTRAST',
      'OTHER',
    };
    var keep = 0;
    var clear = 0;
    var prev = 0;
    final classC = <String, int>{};
    for (final raw in triage['questions'] as List) {
      final q = Map<String, dynamic>.from(raw as Map);
      expect(allowed.contains(q['triage_class']), isTrue,
          reason: q['question_id'] as String);
      classC[q['triage_class'] as String] =
          (classC[q['triage_class'] as String] ?? 0) + 1;
      if (q['previous_needs_human_review'] == true) {
        prev++;
        expect(
          q['flag_decision'] == 'KEEP_FLAG' ||
              q['flag_decision'] == 'CLEAR_FLAG',
          isTrue,
          reason: q['question_id'] as String,
        );
        if (q['flag_decision'] == 'KEEP_FLAG') keep++;
        if (q['flag_decision'] == 'CLEAR_FLAG') clear++;
      } else {
        expect(q['flag_decision'], isNull);
      }
      for (final code in q['reason_codes'] as List) {
        expect(reasons.contains(code), isTrue, reason: '$code');
      }
      if (q['triage_class'] == 'REAL_REVIEW_REQUIRED') {
        expect(q['flag_decision'], 'KEEP_FLAG');
        expect((q['reason_codes'] as List), isNotEmpty);
      } else if (q['previous_needs_human_review'] == true) {
        expect(q['flag_decision'], 'CLEAR_FLAG');
      }
    }
    expect(prev, 397);
    expect(keep, FrequencyBehaviorV2Contract.phase2cKeepFlagCount);
    expect(clear, FrequencyBehaviorV2Contract.phase2cClearFlagCount);
    expect(keep + clear, 397);
    expect(
      (classC['CLEAN'] ?? 0) +
          (classC['ACCEPTABLE_COMPLEXITY'] ?? 0) +
          (classC['REAL_REVIEW_REQUIRED'] ?? 0),
      408,
    );
    expect(classC['REAL_REVIEW_REQUIRED'],
        FrequencyBehaviorV2Contract.phase2cRealReviewRequiredCount);
    expect(classC['REAL_REVIEW_REQUIRED']! < 397, isTrue);
    expect(classC['ACCEPTABLE_COMPLEXITY']! > classC['REAL_REVIEW_REQUIRED']!,
        isTrue);
  });

  test(
      'DROP questions are absent; proposal scores unchanged; 1F DROP evidence remains pending',
      () {
    final drop =
        FrequencyBehaviorV2DraftLoader.phase1fDropFromSelectableIds.toSet();
    final triaged = {
      for (final raw in triage['questions'] as List)
        Map<String, dynamic>.from(raw as Map)['question_id'] as String,
    };
    expect(triaged.intersection(drop), isEmpty);
    expect(proposal['applied_to_pool'], isFalse);
    expect(
      triage['source_pool_fingerprint_sha256'],
      FrequencyBehaviorV2Contract.draftPoolContentFingerprintSha256,
    );
    expect(
      _sha256File(FrequencyBehaviorV2Contract.draftPhase2bProposalRelativePath),
      triage['proposal_file_sha256_before'],
    );
    expect(pool['runtime_selectable'], isFalse);
    expect(pool['human_decision_phase'], 'phase2f');
    for (final id in drop) {
      final item = (pool['items'] as List).cast<Map>().firstWhere(
            (e) => e['item_id'] == id,
          );
      for (final oRaw in item['options'] as List) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        final em = Map<String, dynamic>.from(o['evidence_meta'] as Map);
        expect(em['review_status'], 'pending');
        expect(em['calibration_status'], 'uncalibrated');
        for (final key in FrequencyBehaviorV2Contract.evidenceMetaKeys) {
          expect(em[key], isNull, reason: o['option_id']);
        }
      }
    }
  });

  test(
      '30-question sample has 10 of each class with four options and six scores',
      () {
    final sample = Map<String, dynamic>.from(triage['audit_sample_30'] as Map);
    for (final klass in [
      'CLEAN',
      'ACCEPTABLE_COMPLEXITY',
      'REAL_REVIEW_REQUIRED'
    ]) {
      final rows = sample[klass] as List;
      expect(rows, hasLength(10), reason: klass);
      for (final raw in rows) {
        final q = Map<String, dynamic>.from(raw as Map);
        expect(q['triage_class'], klass);
        expect(q['options'], hasLength(4));
        for (final oRaw in q['options'] as List) {
          final o = Map<String, dynamic>.from(oRaw as Map);
          final em = Map<String, dynamic>.from(o['evidence_meta'] as Map);
          for (final key in FrequencyBehaviorV2Contract.evidenceMetaKeys) {
            expect(em[key], isA<num>());
            expect(
              FrequencyBehaviorV2Contract.isAllowedEvidenceValue(
                (em[key] as num).toDouble(),
              ),
              isTrue,
            );
          }
        }
      }
    }
    expect(triageMd.contains('REAL_REVIEW_REQUIRED'), isTrue);
    expect(triageMd.contains('KEEP_FLAG'), isTrue);
    expect(triageMd.contains('NO VALUES APPLIED'), isTrue);
  });

  test('Phase 2C does not touch V1 or live routing', () {
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
