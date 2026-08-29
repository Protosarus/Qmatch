import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';

const _bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';

IqRecoveredBankDocument _loadBank() {
  return IqRecoveredBankDocument.fromJson(
    jsonDecode(File(_bankPath).readAsStringSync()) as Map<String, dynamic>,
  );
}

Future<IqPersistedSessionState> _lockedSession({
  required IqRecoveredBankDocument bank,
  required String uid,
  required String seed,
}) async {
  final repo = IqSessionMemoryRepository();
  final manager = IqSessionManager(
    bank: bank,
    repository: repo,
    idFactory: IqSessionIdFactory(random: Random(21)),
    clock: () => DateTime.utc(2026, 8, 29, 12),
  );
  final created = await manager.getOrCreateActiveSession(
    ownerUid: uid,
    sessionSeed: seed,
  );
  final sid = created.state!.sessionId;
  final byId = {for (final i in bank.items) i.id: i};
  for (final p in created.state!.itemPlans) {
    await manager.answer(
      ownerUid: uid,
      sessionId: sid,
      itemId: p.itemId,
      selectedOptionId: byId[p.itemId]!.correctOptionId,
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
      'iq_completed',
      'test_completed',
      'score',
      'scores',
      'raw_score',
      'provisional_score',
      'normalized_score',
      'canonical_dimensions',
      'started_at',
      'updated_at',
      'session_seed',
      'current_question_index',
      'prompt',
      'prompts',
      'displayed_correct_position',
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
  late IqRecoveredBankDocument bank;

  setUpAll(() {
    bank = _loadBank();
  });

  test('25-item locked session maps to exact finalizeIq allowlist', () async {
    const uid = 'uid_map';
    final session = await _lockedSession(
      bank: bank,
      uid: uid,
      seed: 'map-seed',
    );
    expect(session.itemPlans.length, 25);
    expect(session.answers.length, 25);
    expect(session.status, IqPersistedSessionStatus.completedPendingPersistence);

    final mapped = IqFinalizeRequestMapper.mapLockedSession(
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
    expect(payload['assessment_type'], 'iq');
    expect(payload['session_id'], session.sessionId);
    expect(payload['owner_uid'], uid);
    expect(payload['bank_version'], session.bankVersion);
    expect(payload['bank_locale'], session.bankLocale);
    expect(payload['selection_policy_version'], 'iq_session_selection_v1');
    expect(payload['selection_policy_version'], session.selectionPolicyVersion);

    final plans = payload['item_plans'] as List;
    final answers = payload['answers'] as List;
    expect(plans.length, 25);
    expect(answers.length, 25);

    for (var i = 0; i < 25; i++) {
      final plan = Map<String, dynamic>.from(plans[i] as Map);
      final answer = Map<String, dynamic>.from(answers[i] as Map);
      final source = session.itemPlans[i];
      expect(plan.keys.toSet(), {
        'item_id',
        'displayed_option_ids',
        'dimension',
        'template_family_id',
      });
      expect(answer.keys.toSet(), {'item_id', 'selected_option_id'});
      expect(plan['item_id'], source.itemId);
      expect(plan['dimension'], source.dimension);
      expect(plan['template_family_id'], source.templateFamilyId);
      expect(
        List<String>.from(plan['displayed_option_ids'] as List),
        source.displayedOptionIds,
      );
      expect(answer['item_id'], source.itemId);
      expect(
        answer['selected_option_id'],
        session.answersByItemId[source.itemId]!.selectedOptionId,
      );
    }

    _assertNoForbiddenKeys(payload);
    final encoded = jsonEncode(payload);
    expect(encoded.contains('answered_at'), isFalse);
    expect(encoded.contains('remote_finalized'), isFalse);
    expect(encoded.contains('iq_completed'), isFalse);
    expect(encoded.contains('test_completed'), isFalse);
    expect(encoded.contains('completed_pending_persistence'), isFalse);
    expect(encoded.contains('"prompt"'), isFalse);
    expect(encoded.contains('provisional_score'), isFalse);
  });

  test('does not map in-progress or owner-mismatched sessions', () async {
    final session = await _lockedSession(
      bank: bank,
      uid: 'uid_a',
      seed: 'map-fail',
    );
    final inProgress = session.copyWith(
      status: IqPersistedSessionStatus.inProgress,
    );
    expect(
      IqFinalizeRequestMapper.mapLockedSession(
        session: inProgress,
        ownerUid: 'uid_a',
      ).ok,
      isFalse,
    );
    expect(
      IqFinalizeRequestMapper.mapLockedSession(
        session: session,
        ownerUid: 'uid_other',
      ).code,
      'owner_mismatch',
    );
    expect(
      IqFinalizeRequestMapper.mapLockedSession(
        session: session,
        ownerUid: '',
      ).code,
      'owner_unavailable',
    );
  });

  test('mapper is not a toJson dump', () {
    final src = File(
      'lib/features/assessment/domain/iq_session/iq_finalize_request_mapper.dart',
    ).readAsStringSync();
    expect(src.contains('toJson()'), isFalse);
    expect(src.contains('assessment_finalize_session_v1'), isTrue);
  });
}
