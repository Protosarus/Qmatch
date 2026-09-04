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
  late String packet;
  late Map<String, dynamic> triage;
  late Map<String, dynamic> proposal;
  late Map<String, dynamic> pool;

  setUpAll(() {
    packet = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.draftPhase2dPacketRelativePath}',
    ).readAsStringSync();
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
  });

  test(
      'Phase 2D packet covers the 29 REAL questions and 10 leakage options only',
      () {
    final realIds = (triage['real_review_required_ids'] as List).cast<String>();
    expect(realIds,
        hasLength(FrequencyBehaviorV2Contract.phase2dPacketQuestionCount));
    for (final id in realIds) {
      expect(packet.contains('`$id`'), isTrue, reason: id);
    }
    final leak = [
      for (final raw in (triage['diagnostic_value_bias']
          as Map)['sample_pm1_dv_le_025'] as List)
        if (Map<String, dynamic>.from(raw as Map)['judgment'] ==
            'WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE')
          Map<String, dynamic>.from(raw)['option_id'] as String,
    ];
    expect(
        leak, hasLength(FrequencyBehaviorV2Contract.phase2dLeakageOptionCount));
    for (final id in leak) {
      expect(packet.contains('`$id`'), isTrue, reason: id);
    }
    expect(packet.contains('KEEP_SCORES'), isTrue);
    expect(packet.contains('ADJUST_EVIDENCE_ONLY'), isTrue);
    expect(packet.contains('REWRITE_REQUIRED'), isTrue);
    expect(packet.contains('DROP_FROM_SELECTABLE'), isTrue);
    expect(packet.contains('DV_JUSTIFIED'), isTrue);
    expect(packet.contains('DV_TOO_LOW'), isTrue);
    expect(
      packet.contains(
        'FREQUENCY V2 PHASE 2D HUMAN EVIDENCE DECISION PACKET READY — NO VALUES APPLIED',
      ),
      isTrue,
    );
  });

  test(
      'Phase 2D packet reports expected recommendation counts and does not apply scores',
      () {
    expect(packet.contains('`KEEP_SCORES`: **7**'), isTrue);
    expect(packet.contains('`ADJUST_EVIDENCE_ONLY`: **12**'), isTrue);
    expect(packet.contains('`REWRITE_REQUIRED`: **10**'), isTrue);
    expect(packet.contains('`DROP_FROM_SELECTABLE`: **0**'), isTrue);
    expect(packet.contains('`DV_JUSTIFIED`: **4**'), isTrue);
    expect(packet.contains('`DV_TOO_LOW`: **6**'), isTrue);
    expect(proposal['applied_to_pool'], isFalse);
    expect(triage['applied_to_pool'], isFalse);
    expect(triage['scores_modified'], isFalse);
    expect(pool['runtime_selectable'], isFalse);
    expect(pool['human_decision_phase'], 'phase2f');
  });

  test('DROP items are absent from the packet; V1 and live routing unchanged',
      () {
    final drop = FrequencyBehaviorV2DraftLoader.phase1fDropFromSelectableIds;
    for (final id in drop) {
      expect(packet.contains('### `$id`'), isFalse, reason: id);
    }
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
          .contains('tool/frequency_behavior_v2/out/'),
      isFalse,
    );
  });
}
