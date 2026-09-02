import 'eq_persisted_session_state.dart';
import 'eq_session_contract.dart';

/// Maps a locked local EQ session into the `finalizeEq` request allowlist.
///
/// Does **not** serialize [EqPersistedSessionState.toJson]. Server remains
/// authoritative for structural catalog validation. Uses the frozen
/// `displayed_option_ids` and answers from the locked session — never
/// regenerates item IDs or option order from the bank.
class EqFinalizeRequestMapper {
  EqFinalizeRequestMapper._();

  static const String schemaVersion = 'assessment_finalize_session_v1';
  static const String catalogVersion = 'assessment_finalize_catalog_v1';
  static const String assessmentType = 'eq';
  static const int maxIdLength = 128;

  /// Whitelist payload for `finalizeEq`, or a client-side invariant failure.
  static EqFinalizeRequestMapResult mapLockedSession({
    required EqPersistedSessionState session,
    required String ownerUid,
  }) {
    final uid = ownerUid.trim();
    if (uid.isEmpty) {
      return const EqFinalizeRequestMapResult.fail(
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    if (session.ownerUid != uid) {
      return const EqFinalizeRequestMapResult.fail(
        code: 'owner_mismatch',
        message: 'Session owner does not match caller',
      );
    }
    if (session.status !=
        EqPersistedSessionStatus.completedPendingPersistence) {
      return EqFinalizeRequestMapResult.fail(
        code: 'session_not_locked',
        message: 'Session status is ${session.status.wireValue}',
      );
    }
    if (session.remoteFinalized) {
      return const EqFinalizeRequestMapResult.fail(
        code: 'session_not_locked',
        message: 'Session is already locally remote-finalized',
      );
    }

    final sessionId = session.sessionId.trim();
    if (sessionId.isEmpty || sessionId.length > maxIdLength) {
      return const EqFinalizeRequestMapResult.fail(
        code: 'session_id_invalid',
        message: 'session_id is missing or too long',
      );
    }

    if (session.itemPlans.length != EqSessionContract.sessionItemCount) {
      return const EqFinalizeRequestMapResult.fail(
        code: 'item_plan_count',
        message: 'Locked session must have 30 item plans',
      );
    }
    if (session.answers.length != EqSessionContract.sessionItemCount) {
      return const EqFinalizeRequestMapResult.fail(
        code: 'answer_count',
        message: 'Locked session must have 30 answers',
      );
    }

    final answersByItem = session.answersByItemId;
    if (answersByItem.length != EqSessionContract.sessionItemCount) {
      return const EqFinalizeRequestMapResult.fail(
        code: 'answer_count',
        message: 'Locked session answers must be unique per item',
      );
    }

    final itemPlans = <Map<String, dynamic>>[];
    final answers = <Map<String, dynamic>>[];
    for (final plan in session.itemPlans) {
      final answer = answersByItem[plan.itemId];
      if (answer == null) {
        return EqFinalizeRequestMapResult.fail(
          code: 'answer_missing',
          message: 'Missing answer for ${plan.itemId}',
        );
      }
      itemPlans.add({
        'item_id': plan.itemId,
        'displayed_option_ids': List<String>.from(plan.displayedOptionIds),
        'primary_dimension': plan.primaryDimension,
      });
      answers.add({
        'item_id': plan.itemId,
        'selected_option_id': answer.selectedOptionId,
      });
    }

    return EqFinalizeRequestMapResult.ok({
      'schema_version': schemaVersion,
      'catalog_version': catalogVersion,
      'assessment_type': assessmentType,
      'session_id': sessionId,
      'owner_uid': uid,
      'bank_version': session.bankVersion,
      'bank_locale': session.bankLocale,
      'selection_policy_version': session.selectionPolicyVersion,
      'item_plans': itemPlans,
      'answers': answers,
    });
  }
}

class EqFinalizeRequestMapResult {
  const EqFinalizeRequestMapResult.ok(this.payload)
      : ok = true,
        code = null,
        message = null;

  const EqFinalizeRequestMapResult.fail({
    required this.code,
    this.message,
  })  : ok = false,
        payload = null;

  final bool ok;
  final Map<String, dynamic>? payload;
  final String? code;
  final String? message;
}
