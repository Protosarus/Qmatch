import '../../services/canonical_assessment_persistence.dart';
import 'persona_handoff_request_builder.dart';
import 'persona_runtime_asset_loader.dart';
import 'persona_runtime_handoff_persistence.dart';
import 'persona_runtime_handoff_result.dart';
import 'persona_runtime_handoff_service.dart';
import 'persona_runtime_result_policy.dart';

enum PersonaAssignmentSource { reused, assigned }

class PersonaAssignmentOutcome {
  const PersonaAssignmentOutcome._({
    required this.ok,
    this.result,
    this.source,
    this.error,
  });

  const PersonaAssignmentOutcome.ok({
    required PersonaRuntimeHandoffResult result,
    required PersonaAssignmentSource source,
  }) : this._(ok: true, result: result, source: source);

  const PersonaAssignmentOutcome.fail(Object error)
      : this._(ok: false, error: error);

  final bool ok;
  final PersonaRuntimeHandoffResult? result;
  final PersonaAssignmentSource? source;
  final Object? error;
}

/// Live assign-or-reuse coordinator (no UI / Matching coupling).
class PersonaAssignmentCoordinator {
  PersonaAssignmentCoordinator({
    CanonicalAssessmentPersistence? persistence,
    PersonaRuntimeHandoffPersistence? handoffPersistence,
    PersonaRuntimeAssetLoader? assetLoader,
    Future<Map<String, dynamic>?> Function(String uid)? loadPersonaDoc,
    Future<Map<String, dynamic>?> Function(String uid)? loadCanonicalProfile,
    Future<Map<String, dynamic>?> Function(String uid, String type)?
        loadAssessment,
    PersonaRuntimeHandoffService? handoffOverride,
  })  : _persistence = persistence ?? CanonicalAssessmentPersistence(),
        _handoffPersistence =
            handoffPersistence ?? PersonaRuntimeHandoffPersistence(),
        _assetLoader = assetLoader ?? PersonaRuntimeAssetLoader(),
        _loadPersonaDoc = loadPersonaDoc,
        _loadCanonicalProfile = loadCanonicalProfile,
        _loadAssessment = loadAssessment,
        _handoffOverride = handoffOverride;

  final CanonicalAssessmentPersistence _persistence;
  final PersonaRuntimeHandoffPersistence _handoffPersistence;
  final PersonaRuntimeAssetLoader _assetLoader;
  final Future<Map<String, dynamic>?> Function(String uid)? _loadPersonaDoc;
  final Future<Map<String, dynamic>?> Function(String uid)?
      _loadCanonicalProfile;
  final Future<Map<String, dynamic>?> Function(String uid, String type)?
      _loadAssessment;
  final PersonaRuntimeHandoffService? _handoffOverride;

  /// Reuse current-version persona when present; otherwise assign+persist.
  Future<PersonaAssignmentOutcome> resolveForUid(String uid) async {
    try {
      final existing = await _personaDoc(uid);
      if (PersonaRuntimeResultPolicy.isCurrentValid(existing)) {
        return PersonaAssignmentOutcome.ok(
          result: _resultFromDoc(existing!),
          source: PersonaAssignmentSource.reused,
        );
      }

      final profile = await _canonicalProfile(uid);
      if (profile == null) {
        throw StateError('canonical_v1 missing for Persona assignment');
      }
      final iq = await _assessment(uid, 'iq');
      final eq = await _assessment(uid, 'eq');
      final frequency = await _assessment(uid, 'frequency');
      if (iq == null || eq == null || frequency == null) {
        throw StateError('IQ/EQ/Frequency assessments required for Persona');
      }

      final request = PersonaHandoffRequestBuilder.fromCanonicalSources(
        ownerUid: uid,
        canonicalProfile: profile,
        iqAssessment: iq,
        eqAssessment: eq,
        frequencyAssessment: frequency,
      );

      final handoff = _handoffOverride ??
          PersonaRuntimeHandoffService(
            scorer: await _assetLoader.loadScorer(),
          );
      final result = await _handoffPersistence.assignAndPersist(
        handoff: handoff,
        request: request,
      );
      return PersonaAssignmentOutcome.ok(
        result: result,
        source: PersonaAssignmentSource.assigned,
      );
    } catch (e) {
      return PersonaAssignmentOutcome.fail(e);
    }
  }

  Future<Map<String, dynamic>?> _personaDoc(String uid) async {
    final custom = _loadPersonaDoc;
    if (custom != null) return custom(uid);
    return _persistence.getAssessment(
      PersonaRuntimeResultPolicy.assessmentType,
      uid: uid,
    );
  }

  Future<Map<String, dynamic>?> _canonicalProfile(String uid) async {
    final custom = _loadCanonicalProfile;
    if (custom != null) return custom(uid);
    return _persistence.getCanonicalProfile(uid: uid);
  }

  Future<Map<String, dynamic>?> _assessment(String uid, String type) async {
    final custom = _loadAssessment;
    if (custom != null) return custom(uid, type);
    return _persistence.getAssessment(type, uid: uid);
  }

  static PersonaRuntimeHandoffResult _resultFromDoc(Map<String, dynamic> doc) {
    return PersonaRuntimeHandoffResult(
      primaryPersonaId: doc['primary_persona_id'] as String,
      secondaryPersonaId: doc['secondary_persona_id'] as String,
      rawDeltaD: (doc['raw_delta_d'] as num).toDouble(),
      scoringVersion: doc['scoring_version'] as String,
      configVersion: doc['config_version'] as String,
      prototypeVersion: doc['prototype_version'] as String,
      policyVersion: doc['policy_version'] as String,
    );
  }
}
