import 'frequency_persisted_session_state.dart';
import 'frequency_session_contract.dart';

/// Maps a locked local Frequency V1 session into the `finalizeFrequency`
/// request allowlist.
///
/// Does **not** serialize [FrequencyPersistedSessionState.toJson]. Server
/// remains authoritative for structural catalog validation, including
/// `item_role`. Uses the frozen `displayed_option_ids` and answers from the
/// locked session — never regenerates item IDs, option order, or option
/// alphabets from the bank.
///
/// Frequency V1 mixed option IDs are copied exactly:
/// core / behavioral_equivalence → `A`/`B`/`C`/`D`
/// separator / response_quality → `opt_a`/`opt_b`/`opt_c`/`opt_d`
class FrequencyFinalizeRequestMapper {
  FrequencyFinalizeRequestMapper._();

  static const String schemaVersion = 'assessment_finalize_session_v1';
  static const String catalogVersion = 'assessment_finalize_catalog_v1';
  static const String assessmentType = 'frequency';
  static const int maxIdLength = 128;

  /// Whitelist payload for `finalizeFrequency`, or a client-side invariant
  /// failure.
  static FrequencyFinalizeRequestMapResult mapLockedSession({
    required FrequencyPersistedSessionState session,
    required String ownerUid,
  }) {
    final uid = ownerUid.trim();
    if (uid.isEmpty) {
      return const FrequencyFinalizeRequestMapResult.fail(
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    if (session.ownerUid != uid) {
      return const FrequencyFinalizeRequestMapResult.fail(
        code: 'owner_mismatch',
        message: 'Session owner does not match caller',
      );
    }
    if (session.status !=
        FrequencyPersistedSessionStatus.completedPendingPersistence) {
      return FrequencyFinalizeRequestMapResult.fail(
        code: 'session_not_locked',
        message: 'Session status is ${session.status.wireValue}',
      );
    }
    if (session.remoteFinalized) {
      return const FrequencyFinalizeRequestMapResult.fail(
        code: 'session_not_locked',
        message: 'Session is already locally remote-finalized',
      );
    }

    final sessionId = session.sessionId.trim();
    if (sessionId.isEmpty || sessionId.length > maxIdLength) {
      return const FrequencyFinalizeRequestMapResult.fail(
        code: 'session_id_invalid',
        message: 'session_id is missing or too long',
      );
    }

    if (session.itemPlans.length != FrequencySessionContract.sessionItemCount) {
      return const FrequencyFinalizeRequestMapResult.fail(
        code: 'item_plan_count',
        message: 'Locked session must have 50 item plans',
      );
    }
    if (session.answers.length != FrequencySessionContract.sessionItemCount) {
      return const FrequencyFinalizeRequestMapResult.fail(
        code: 'answer_count',
        message: 'Locked session must have 50 answers',
      );
    }

    final answersByItem = session.answersByItemId;
    if (answersByItem.length != FrequencySessionContract.sessionItemCount) {
      return const FrequencyFinalizeRequestMapResult.fail(
        code: 'answer_count',
        message: 'Locked session answers must be unique per item',
      );
    }

    final itemPlans = <Map<String, dynamic>>[];
    final answers = <Map<String, dynamic>>[];
    for (final plan in session.itemPlans) {
      final answer = answersByItem[plan.itemId];
      if (answer == null) {
        return FrequencyFinalizeRequestMapResult.fail(
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

    return FrequencyFinalizeRequestMapResult.ok({
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

class FrequencyFinalizeRequestMapResult {
  const FrequencyFinalizeRequestMapResult.ok(this.payload)
      : ok = true,
        code = null,
        message = null;

  const FrequencyFinalizeRequestMapResult.fail({
    required this.code,
    this.message,
  })  : ok = false,
        payload = null;

  final bool ok;
  final Map<String, dynamic>? payload;
  final String? code;
  final String? message;
}
