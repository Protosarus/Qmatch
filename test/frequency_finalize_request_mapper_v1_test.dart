import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';

FrequencyCanonicalBankDocument _loadBank() {
  return FrequencyCanonicalBankDocument.fromJson(
    jsonDecode(File(FrequencyBankContract.trAssetPath).readAsStringSync())
        as Map<String, dynamic>,
  );
}

Future<FrequencyPersistedSessionState> _lockedSession({
  required FrequencyCanonicalBankDocument bank,
  required String uid,
  required String seed,
}) async {
  final repo = FrequencySessionMemoryRepository();
  final manager = FrequencySessionManager(
    bank: bank,
    repository: repo,
    idFactory: FrequencySessionIdFactory(random: Random(21)),
    shuffleRandom: Random(seed.hashCode),
    clock: () => DateTime.utc(2026, 9, 3, 12),
  );
  final created = await manager.getOrCreateActiveSession(
    ownerUid: uid,
    sessionSeed: seed,
  );
  final sid = created.state!.sessionId;
  for (final p in created.state!.itemPlans) {
    await manager.answer(
      ownerUid: uid,
      sessionId: sid,
      itemId: p.itemId,
      selectedOptionId: p.displayedOptionIds.last,
    );
  }
  final completed = await manager.complete(ownerUid: uid, sessionId: sid);
  expect(completed.ok, isTrue);
  return completed.state!;
}

void _assertNoForbiddenKeys(Object? node) {
  if (node is Map) {
    const forbidden = {
      'status',
      'remote_finalized',
      'answered_at',
      'completed',
      'completed_at',
      'eq_completed',
      'iq_completed',
      'frequency_completed',
      'test_completed',
      'assessment_flow_completed',
      'discover_eligible',
      'score',
      'scores',
      'overall_frequency_score',
      'dimension_scores',
      'normalized_score',
      'canonical_dimensions',
      'canonical_v1',
      'started_at',
      'updated_at',
      'session_seed',
      'current_question_index',
      'prompt',
      'prompts',
      'scoring_policy_version',
      'item_role',
    };
    for (final key in node.keys) {
      expect(forbidden.contains(key), isFalse, reason: 'forbidden key $key');
    }
    for (final value in node.values) {
      _assertNoForbiddenKeys(value);
    }
  } else if (node is List) {
    for (final value in node) {
      _assertNoForbiddenKeys(value);
    }
  }
}

void main() {
  late FrequencyCanonicalBankDocument bank;

  setUpAll(() {
    bank = _loadBank();
  });

  test('50-item locked session maps to exact finalizeFrequency allowlist',
      () async {
    const uid = 'uid_freq_map';
    final session = await _lockedSession(
      bank: bank,
      uid: uid,
      seed: 'freq-map-seed',
    );
    expect(session.itemPlans.length, 50);
    expect(session.answers.length, 50);
    expect(
      session.status,
      FrequencyPersistedSessionStatus.completedPendingPersistence,
    );

    final mapped = FrequencyFinalizeRequestMapper.mapLockedSession(
      session: session,
      ownerUid: uid,
    );
    expect(mapped.ok, isTrue);
    final payload = mapped.payload!;
    expect(payload.keys.toSet(), {
      'schema_version',
      'catalog_version',
      'assessment_type',
      'session_id',
      'owner_uid',
      'bank_version',
      'bank_locale',
      'selection_policy_version',
      'item_plans',
      'answers',
    });
    expect(payload['schema_version'], 'assessment_finalize_session_v1');
    expect(payload['catalog_version'], 'assessment_finalize_catalog_v1');
    expect(payload['assessment_type'], 'frequency');
    expect(payload['session_id'], session.sessionId);
    expect(payload['owner_uid'], uid);
    expect(payload['bank_version'], session.bankVersion);
    expect(payload['bank_locale'], session.bankLocale);
    expect(
      payload['selection_policy_version'],
      FrequencySessionContract.selectionPolicyVersion,
    );
    expect(
      payload['selection_policy_version'],
      session.selectionPolicyVersion,
    );

    final plans = payload['item_plans'] as List;
    final answers = payload['answers'] as List;
    expect(plans.length, 50);
    expect(answers.length, 50);

    var shuffledVsBankDefault = false;
    var sawNullPrimary = false;
    var sawNamedPrimary = false;
    var sawAbcd = false;
    var sawOptAlphabet = false;
    for (var i = 0; i < 50; i++) {
      final plan = Map<String, dynamic>.from(plans[i] as Map);
      final answer = Map<String, dynamic>.from(answers[i] as Map);
      final source = session.itemPlans[i];
      expect(plan.keys.toSet(), {
        'item_id',
        'displayed_option_ids',
        'primary_dimension',
      });
      expect(answer.keys.toSet(), {'item_id', 'selected_option_id'});
      expect(plan.containsKey('item_role'), isFalse);
      expect(plan['item_id'], source.itemId);
      expect(plan['primary_dimension'], source.primaryDimension);
      expect(
        List<String>.from(plan['displayed_option_ids'] as List),
        source.displayedOptionIds,
      );
      expect(answer['item_id'], source.itemId);
      expect(
        answer['selected_option_id'],
        session.answersByItemId[source.itemId]!.selectedOptionId,
      );
      expect(
        answer['selected_option_id'],
        source.displayedOptionIds.last,
      );

      if (source.primaryDimension == null) {
        sawNullPrimary = true;
        expect(plan.containsKey('primary_dimension'), isTrue);
        expect(plan['primary_dimension'], isNull);
      } else {
        sawNamedPrimary = true;
        expect(
          FrequencyCanonicalDimensions.allSet.contains(source.primaryDimension),
          isTrue,
        );
      }

      final displayed = List<String>.from(plan['displayed_option_ids'] as List);
      if (displayed.contains('A') ||
          displayed.contains('B') ||
          displayed.contains('C') ||
          displayed.contains('D')) {
        sawAbcd = true;
      }
      if (displayed.contains('opt_a') ||
          displayed.contains('opt_b') ||
          displayed.contains('opt_c') ||
          displayed.contains('opt_d')) {
        sawOptAlphabet = true;
      }

      final bankItem = bank.itemsById[source.itemId]!;
      final bankDefault = [for (final o in bankItem.options) o.optionId];
      if (source.displayedOptionIds.join('|') != bankDefault.join('|')) {
        shuffledVsBankDefault = true;
      }

      if (bankItem.itemRole == FrequencyBankContract.itemRoleCore ||
          bankItem.itemRole ==
              FrequencyBankContract.itemRoleBehavioralEquivalence) {
        expect(
          displayed.every((id) => const {'A', 'B', 'C', 'D'}.contains(id)),
          isTrue,
          reason: '${source.itemId} core/BE must keep A/B/C/D',
        );
        expect(
          displayed.any((id) => id.startsWith('opt_')),
          isFalse,
        );
      }
      if (bankItem.itemRole == FrequencyBankContract.itemRoleSeparator ||
          bankItem.itemRole == FrequencyBankContract.itemRoleQuality) {
        expect(
          displayed.every(
            (id) =>
                const {'opt_a', 'opt_b', 'opt_c', 'opt_d'}.contains(id),
          ),
          isTrue,
          reason: '${source.itemId} separator/quality must keep opt_*',
        );
        expect(displayed.contains('A'), isFalse);
        expect(displayed.contains('B'), isFalse);
      }
    }
    expect(shuffledVsBankDefault, isTrue);
    expect(sawNullPrimary, isTrue);
    expect(sawNamedPrimary, isTrue);
    expect(sawAbcd, isTrue);
    expect(sawOptAlphabet, isTrue);

    _assertNoForbiddenKeys(payload);
    final encoded = jsonEncode(payload);
    expect(encoded.contains('answered_at'), isFalse);
    expect(encoded.contains('remote_finalized'), isFalse);
    expect(encoded.contains('frequency_completed'), isFalse);
    expect(encoded.contains('test_completed'), isFalse);
    expect(encoded.contains('assessment_flow_completed'), isFalse);
    expect(encoded.contains('discover_eligible'), isFalse);
    expect(encoded.contains('completed_pending_persistence'), isFalse);
    expect(encoded.contains('overall_frequency_score'), isFalse);
    expect(encoded.contains('dimension_scores'), isFalse);
    expect(encoded.contains('item_role'), isFalse);
    expect(encoded.contains('scoring_policy_version'), isFalse);
    expect(encoded.contains('session_seed'), isFalse);
  });

  test('does not map in-progress or owner-mismatched sessions', () async {
    final session = await _lockedSession(
      bank: bank,
      uid: 'uid_a',
      seed: 'freq-map-fail',
    );
    final inProgress = session.copyWith(
      status: FrequencyPersistedSessionStatus.inProgress,
    );
    expect(
      FrequencyFinalizeRequestMapper.mapLockedSession(
        session: inProgress,
        ownerUid: 'uid_a',
      ).ok,
      isFalse,
    );
    expect(
      FrequencyFinalizeRequestMapper.mapLockedSession(
        session: session,
        ownerUid: 'uid_other',
      ).code,
      'owner_mismatch',
    );
    expect(
      FrequencyFinalizeRequestMapper.mapLockedSession(
        session: session,
        ownerUid: '',
      ).code,
      'owner_unavailable',
    );
    expect(
      FrequencyFinalizeRequestMapper.mapLockedSession(
        session: session.copyWith(remoteFinalized: true),
        ownerUid: 'uid_a',
      ).code,
      'session_not_locked',
    );
  });

  test('mapper is not a toJson dump and does not invent item_role', () {
    final src = File(
      'lib/features/assessment/domain/frequency_session/frequency_finalize_request_mapper.dart',
    ).readAsStringSync();
    expect(src.contains('toJson()'), isFalse);
    expect(src.contains('assessment_finalize_session_v1'), isTrue);
    expect(src.contains("assessmentType = 'frequency'"), isTrue);
    expect(src.contains("'item_role'"), isFalse);
  });
}
