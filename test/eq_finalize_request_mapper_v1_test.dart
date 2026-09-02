import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_bank/eq_bank.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';

EqCanonicalBankDocument _loadBank() {
  return EqCanonicalBankDocument.fromJson(
    jsonDecode(File(EqBankContract.trAssetPath).readAsStringSync())
        as Map<String, dynamic>,
  );
}

Future<EqPersistedSessionState> _lockedSession({
  required EqCanonicalBankDocument bank,
  required String uid,
  required String seed,
}) async {
  final repo = EqSessionMemoryRepository();
  final manager = EqSessionManager(
    bank: bank,
    repository: repo,
    idFactory: EqSessionIdFactory(random: Random(21)),
    shuffleRandom: Random(seed.hashCode),
    clock: () => DateTime.utc(2026, 9, 2, 12),
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
      'test_completed',
      'assessment_flow_completed',
      'discover_eligible',
      'score',
      'scores',
      'eq_score',
      'overall_eq_score',
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
  late EqCanonicalBankDocument bank;

  setUpAll(() {
    bank = _loadBank();
  });

  test('30-item locked session maps to exact finalizeEq allowlist', () async {
    const uid = 'uid_eq_map';
    final session = await _lockedSession(
      bank: bank,
      uid: uid,
      seed: 'eq-map-seed',
    );
    expect(session.itemPlans.length, 30);
    expect(session.answers.length, 30);
    expect(
      session.status,
      EqPersistedSessionStatus.completedPendingPersistence,
    );

    final mapped = EqFinalizeRequestMapper.mapLockedSession(
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
    expect(payload['assessment_type'], 'eq');
    expect(payload['session_id'], session.sessionId);
    expect(payload['owner_uid'], uid);
    expect(payload['bank_version'], session.bankVersion);
    expect(payload['bank_locale'], session.bankLocale);
    expect(
      payload['selection_policy_version'],
      EqSessionContract.selectionPolicyVersion,
    );
    expect(
      payload['selection_policy_version'],
      session.selectionPolicyVersion,
    );

    final plans = payload['item_plans'] as List;
    final answers = payload['answers'] as List;
    expect(plans.length, 30);
    expect(answers.length, 30);

    var shuffledVsBankDefault = false;
    for (var i = 0; i < 30; i++) {
      final plan = Map<String, dynamic>.from(plans[i] as Map);
      final answer = Map<String, dynamic>.from(answers[i] as Map);
      final source = session.itemPlans[i];
      expect(plan.keys.toSet(), {
        'item_id',
        'displayed_option_ids',
        'primary_dimension',
      });
      expect(answer.keys.toSet(), {'item_id', 'selected_option_id'});
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
      final bankItem = bank.itemsById[source.itemId]!;
      final bankDefault = [for (final o in bankItem.options) o.optionId];
      if (source.displayedOptionIds.join('|') != bankDefault.join('|')) {
        shuffledVsBankDefault = true;
      }
    }
    expect(shuffledVsBankDefault, isTrue);

    _assertNoForbiddenKeys(payload);
    final encoded = jsonEncode(payload);
    expect(encoded.contains('answered_at'), isFalse);
    expect(encoded.contains('remote_finalized'), isFalse);
    expect(encoded.contains('eq_completed'), isFalse);
    expect(encoded.contains('test_completed'), isFalse);
    expect(encoded.contains('assessment_flow_completed'), isFalse);
    expect(encoded.contains('discover_eligible'), isFalse);
    expect(encoded.contains('completed_pending_persistence'), isFalse);
    expect(encoded.contains('overall_eq_score'), isFalse);
    expect(encoded.contains('dimension_scores'), isFalse);
  });

  test('does not map in-progress or owner-mismatched sessions', () async {
    final session = await _lockedSession(
      bank: bank,
      uid: 'uid_a',
      seed: 'eq-map-fail',
    );
    final inProgress = session.copyWith(
      status: EqPersistedSessionStatus.inProgress,
    );
    expect(
      EqFinalizeRequestMapper.mapLockedSession(
        session: inProgress,
        ownerUid: 'uid_a',
      ).ok,
      isFalse,
    );
    expect(
      EqFinalizeRequestMapper.mapLockedSession(
        session: session,
        ownerUid: 'uid_other',
      ).code,
      'owner_mismatch',
    );
    expect(
      EqFinalizeRequestMapper.mapLockedSession(
        session: session,
        ownerUid: '',
      ).code,
      'owner_unavailable',
    );
    expect(
      EqFinalizeRequestMapper.mapLockedSession(
        session: session.copyWith(remoteFinalized: true),
        ownerUid: 'uid_a',
      ).code,
      'session_not_locked',
    );
  });

  test('mapper is not a toJson dump', () {
    final src = File(
      'lib/features/assessment/domain/eq_session/eq_finalize_request_mapper.dart',
    ).readAsStringSync();
    expect(src.contains('toJson()'), isFalse);
    expect(src.contains('assessment_finalize_session_v1'), isTrue);
    expect(src.contains("assessmentType = 'eq'"), isTrue);
  });
}
