import '../../services/canonical_assessment_persistence.dart';
import 'persona_runtime_handoff_request.dart';
import 'persona_runtime_handoff_result.dart';
import 'persona_runtime_handoff_service.dart';
import 'persona_shadow_input.dart';

/// Persist distance-only Persona handoff results to
/// `users/{uid}/assessments/persona`.
///
/// * Writes only after [PersonaRuntimeHandoffService.assign] succeeds
///   (complete valid 20D + evidence + versions).
/// * Idempotent merge via [CanonicalAssessmentPersistence].
/// * Never writes %, confidence, affinity, temperature, RVI, or quantum fields.
/// * No UI, Matching, or Discover coupling.
class PersonaRuntimeHandoffPersistence {
  PersonaRuntimeHandoffPersistence({
    CanonicalAssessmentPersistence? assessmentPersistence,
    Future<void> Function(String uid, Map<String, dynamic> fields)?
        writeForUidOverride,
  })  : _assessmentPersistence =
            assessmentPersistence ?? CanonicalAssessmentPersistence(),
        _writeForUidOverride = writeForUidOverride;

  static const String assessmentType = 'persona';

  /// Exact Firestore field allowlist (plus `assessment_type` / timestamps
  /// added by [CanonicalAssessmentPersistence.upsertCompletedAssessmentForUid]).
  static const Set<String> allowedResultKeys = {
    'primary_persona_id',
    'secondary_persona_id',
    'raw_delta_d',
    'scoring_version',
    'config_version',
    'policy_version',
    'prototype_version',
  };

  static const Set<String> optionalResultKeys = {
    'source',
  };

  static const Set<String> forbiddenResultKeys = {
    'confidence',
    'confidence_score',
    'confidence_level',
    'primary_similarity',
    'secondary_similarity',
    'similarity',
    'affinity',
    'temperature',
    'pi_p',
    'percentage',
    'percent',
    'rvi',
    'quantum',
    'shadow_only',
  };

  final CanonicalAssessmentPersistence _assessmentPersistence;
  final Future<void> Function(String uid, Map<String, dynamic> fields)?
      _writeForUidOverride;

  /// Distance-only payload. No timestamps (writer owns `updated_at`).
  static Map<String, dynamic> buildPersistedFields(
    PersonaRuntimeHandoffResult result,
  ) {
    if (result.primaryPersonaId.trim().isEmpty ||
        result.secondaryPersonaId.trim().isEmpty) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.incompleteDimensionScores,
        'Persona ids required before persistence',
      );
    }
    if (result.primaryPersonaId == result.secondaryPersonaId) {
      throw StateError('primary and secondary persona ids must differ');
    }
    if (!result.rawDeltaD.isFinite || result.rawDeltaD < 0) {
      throw StateError('raw_delta_d must be finite and >= 0');
    }

    final fields = <String, dynamic>{
      'primary_persona_id': result.primaryPersonaId,
      'secondary_persona_id': result.secondaryPersonaId,
      'raw_delta_d': result.rawDeltaD,
      'scoring_version': result.scoringVersion,
      'config_version': result.configVersion,
      'policy_version': result.policyVersion,
      'prototype_version': result.prototypeVersion,
    };
    final source = result.source?.trim();
    if (source != null && source.isNotEmpty) {
      fields['source'] = source;
    }

    assertAllowlist(fields);
    return fields;
  }

  static void assertAllowlist(Map<String, dynamic> fields) {
    for (final key in fields.keys) {
      if (!allowedResultKeys.contains(key) &&
          !optionalResultKeys.contains(key)) {
        throw StateError('Forbidden persona persistence key: $key');
      }
      if (forbiddenResultKeys.contains(key)) {
        throw StateError('Forbidden persona persistence key: $key');
      }
    }
    for (final required in allowedResultKeys) {
      if (!fields.containsKey(required)) {
        throw StateError('Missing persona persistence key: $required');
      }
    }
  }

  /// Score a complete 20D request, then merge-write `assessments/persona`.
  Future<PersonaRuntimeHandoffResult> assignAndPersist({
    required PersonaRuntimeHandoffService handoff,
    required PersonaRuntimeHandoffRequest request,
  }) async {
    final result = handoff.assign(request);
    await persistResult(
      ownerUid: request.ownerUid,
      result: result,
    );
    return result;
  }

  /// Persist an already-assigned distance-only result (idempotent merge).
  Future<void> persistResult({
    required String ownerUid,
    required PersonaRuntimeHandoffResult result,
  }) async {
    if (ownerUid.trim().isEmpty) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.ownerUnavailable,
        'Authenticated owner_uid required',
      );
    }
    final fields = buildPersistedFields(result);
    final writer = _writeForUidOverride;
    if (writer != null) {
      await writer(ownerUid, fields);
      return;
    }
    await _assessmentPersistence.upsertCompletedAssessmentForUid(
      uid: ownerUid,
      assessmentType: assessmentType,
      fields: fields,
    );
  }
}
