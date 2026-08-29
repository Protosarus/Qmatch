import 'iq_persisted_session_state.dart';
import 'iq_session_contract.dart';

/// Maps a locked local IQ session into the `finalizeIq` request allowlist.
///
/// Does **not** serialize [IqPersistedSessionState.toJson]. Server remains
/// authoritative for structural catalog validation.
class IqFinalizeRequestMapper {
  IqFinalizeRequestMapper._();

  static const String schemaVersion = 'assessment_finalize_session_v1';
  static const String catalogVersion = 'assessment_finalize_catalog_v1';
  static const String assessmentType = 'iq';
  static const int maxIdLength = 128;

  /// Whitelist payload for `finalizeIq`, or a client-side invariant failure.
  static IqFinalizeRequestMapResult mapLockedSession({
    required IqPersistedSessionState session,
    required String ownerUid,
  }) {
    final uid = ownerUid.trim();
    if (uid.isEmpty) {
      return const IqFinalizeRequestMapResult.fail(
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    if (session.ownerUid != uid) {
      return const IqFinalizeRequestMapResult.fail(
        code: 'owner_mismatch',
        message: 'Session owner does not match caller',
      );
    }
    if (session.status !=
        IqPersistedSessionStatus.completedPendingPersistence) {
      return IqFinalizeRequestMapResult.fail(
        code: 'session_not_locked',
        message: 'Session status is ${session.status.wireValue}',
      );
    }
    if (session.remoteFinalized) {
      return const IqFinalizeRequestMapResult.fail(
        code: 'session_not_locked',
        message: 'Session is already locally remote-finalized',
      );
    }

    final sessionId = session.sessionId.trim();
    if (sessionId.isEmpty || sessionId.length > maxIdLength) {
      return const IqFinalizeRequestMapResult.fail(
        code: 'session_id_invalid',
        message: 'session_id is missing or too long',
      );
    }

    if (session.itemPlans.length != IqSessionContract.sessionItemCount) {
      return const IqFinalizeRequestMapResult.fail(
        code: 'item_plan_count',
        message: 'Locked session must have 25 item plans',
      );
    }
    if (session.answers.length != IqSessionContract.sessionItemCount) {
      return const IqFinalizeRequestMapResult.fail(
        code: 'answer_count',
        message: 'Locked session must have 25 answers',
      );
    }

    final answersByItem = session.answersByItemId;
    if (answersByItem.length != IqSessionContract.sessionItemCount) {
      return const IqFinalizeRequestMapResult.fail(
        code: 'answer_count',
        message: 'Locked session answers must be unique per item',
      );
    }

    final itemPlans = <Map<String, dynamic>>[];
    final answers = <Map<String, dynamic>>[];
    for (final plan in session.itemPlans) {
      final answer = answersByItem[plan.itemId];
      if (answer == null) {
        return IqFinalizeRequestMapResult.fail(
          code: 'answer_missing',
          message: 'Missing answer for ${plan.itemId}',
        );
      }
      itemPlans.add({
        'item_id': plan.itemId,
        'displayed_option_ids': List<String>.from(plan.displayedOptionIds),
        'dimension': plan.dimension,
        'template_family_id': plan.templateFamilyId,
      });
      answers.add({
        'item_id': plan.itemId,
        'selected_option_id': answer.selectedOptionId,
      });
    }

    return IqFinalizeRequestMapResult.ok({
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

class IqFinalizeRequestMapResult {
  const IqFinalizeRequestMapResult.ok(this.payload)
      : ok = true,
        code = null,
        message = null;

  const IqFinalizeRequestMapResult.fail({
    required this.code,
    this.message,
  })  : ok = false,
        payload = null;

  final bool ok;
  final Map<String, dynamic>? payload;
  final String? code;
  final String? message;
}
