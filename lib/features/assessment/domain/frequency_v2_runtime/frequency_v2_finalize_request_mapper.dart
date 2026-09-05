import 'frequency_v2_persisted_session_state.dart';
import 'frequency_v2_runtime_contract.dart';

class FrequencyV2FinalizeRequestMapResult {
  const FrequencyV2FinalizeRequestMapResult.ok(this.payload)
      : ok = true,
        code = null,
        message = null;

  const FrequencyV2FinalizeRequestMapResult.fail({
    required this.code,
    this.message,
  })  : ok = false,
        payload = null;

  final bool ok;
  final Map<String, dynamic>? payload;
  final String? code;
  final String? message;
}

/// Maps a locked local V2 session into the `finalizeFrequencyV2` allowlist.
///
/// Never includes scores, confidence, pair-fit, Discover flags, or
/// `canonical_v1`.
class FrequencyV2FinalizeRequestMapper {
  FrequencyV2FinalizeRequestMapper._();

  static const Set<String> allowedKeys = {
    'schema_version',
    'catalog_version',
    'session_id',
    'owner_uid',
    'assessment_type',
    'bank_version',
    'bank_locale',
    'selection_policy_version',
    'selector_version',
    'session_seed',
    'translation_version',
    'item_plans',
    'answers',
  };

  static const Set<String> forbiddenAuthorityKeys = {
    'score',
    'normalized_behavior',
    'behavioral_mean_12d',
    'provisional_confidence',
    'confidence_flags',
    'pair_fit',
    'pair_relation',
    'signed_pole',
    'mixed_density',
    'canonical_v1',
    'discover_eligible',
    'test_completed',
    'assessment_flow_completed',
    'frequency_completed',
    'frequency_vector',
  };

  static FrequencyV2FinalizeRequestMapResult mapLockedSession({
    required FrequencyV2PersistedSessionState session,
    required String ownerUid,
  }) {
    final uid = ownerUid.trim();
    if (uid.isEmpty) {
      return const FrequencyV2FinalizeRequestMapResult.fail(
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    if (session.ownerUid != uid) {
      return const FrequencyV2FinalizeRequestMapResult.fail(
        code: 'owner_mismatch',
        message: 'Session owner does not match caller',
      );
    }
    if (session.status !=
        FrequencyV2PersistedSessionStatus.completedPendingPersistence) {
      return FrequencyV2FinalizeRequestMapResult.fail(
        code: 'session_not_locked',
        message: 'Session status is ${session.status.wireValue}',
      );
    }
    if (session.remoteFinalized) {
      return const FrequencyV2FinalizeRequestMapResult.fail(
        code: 'session_not_locked',
        message: 'Session is already locally remote-finalized',
      );
    }
    final sessionId = session.sessionId.trim();
    if (sessionId.isEmpty ||
        sessionId.length > FrequencyV2RuntimeContract.maxIdLength) {
      return const FrequencyV2FinalizeRequestMapResult.fail(
        code: 'session_id_invalid',
        message: 'session_id is missing or too long',
      );
    }
    if (session.itemPlans.length !=
        FrequencyV2RuntimeContract.sessionItemCount) {
      return const FrequencyV2FinalizeRequestMapResult.fail(
        code: 'item_plan_count',
        message: 'Locked session must have 50 item plans',
      );
    }
    if (session.answersByItemId.length !=
        FrequencyV2RuntimeContract.sessionItemCount) {
      return const FrequencyV2FinalizeRequestMapResult.fail(
        code: 'answer_count',
        message: 'Locked session must have 50 answers',
      );
    }

    final itemPlans = <Map<String, dynamic>>[];
    final answers = <Map<String, dynamic>>[];
    for (final plan in session.itemPlans) {
      final answer = session.answersByItemId[plan.itemId];
      if (answer == null) {
        return FrequencyV2FinalizeRequestMapResult.fail(
          code: 'answer_missing',
          message: 'Missing answer for ${plan.itemId}',
        );
      }
      itemPlans.add({
        'item_id': plan.itemId,
        'presented_option_order': List<String>.from(plan.presentedOptionOrder),
      });
      answers.add({
        'item_id': plan.itemId,
        'selected_option_id': answer.selectedOptionId,
      });
    }

    final payload = <String, dynamic>{
      'schema_version': FrequencyV2RuntimeContract.finalizeSchemaVersion,
      'catalog_version': FrequencyV2RuntimeContract.catalogVersion,
      'assessment_type': FrequencyV2RuntimeContract.assessmentType,
      'session_id': sessionId,
      'owner_uid': uid,
      'bank_version': session.bankVersion,
      'bank_locale': session.bankLocale,
      'selection_policy_version': session.selectionPolicyVersion,
      'selector_version': session.selectorVersion,
      'session_seed': session.sessionSeed,
      'item_plans': itemPlans,
      'answers': answers,
    };
    if (session.bankLocale == 'en-US') {
      final translation = session.translationVersion;
      if (translation == null || translation.isEmpty) {
        return const FrequencyV2FinalizeRequestMapResult.fail(
          code: 'translation_version_missing',
          message: 'EN sessions require translation_version',
        );
      }
      payload['translation_version'] = translation;
    }

    for (final key in payload.keys) {
      if (!allowedKeys.contains(key)) {
        return FrequencyV2FinalizeRequestMapResult.fail(
          code: 'unexpected_field',
          message: key,
        );
      }
    }
    return FrequencyV2FinalizeRequestMapResult.ok(payload);
  }
}
