import '../domain/persona_scoring/persona_runtime_handoff_persistence.dart';
import 'canonical_assessment_persistence.dart';

class AssignedPersonaResult {
  const AssignedPersonaResult({
    required this.primaryPersonaId,
    required this.secondaryPersonaId,
  });

  final String primaryPersonaId;
  final String secondaryPersonaId;
}

class PersonaResultReader {
  PersonaResultReader({
    CanonicalAssessmentPersistence? persistence,
    Future<Map<String, dynamic>?> Function(String uid)? loadOverride,
  })  : _persistence = persistence ?? CanonicalAssessmentPersistence(),
        _loadOverride = loadOverride;

  final CanonicalAssessmentPersistence _persistence;
  final Future<Map<String, dynamic>?> Function(String uid)? _loadOverride;

  Future<AssignedPersonaResult?> readForUid(String uid) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) return null;

    final doc = await (_loadOverride?.call(trimmedUid) ??
        _persistence.getAssessment(
          PersonaRuntimeHandoffPersistence.assessmentType,
          uid: trimmedUid,
        ));

    if (doc == null || doc.isEmpty) return null;

    final primary = doc['primary_persona_id']?.toString().trim() ?? '';
    final secondary = doc['secondary_persona_id']?.toString().trim() ?? '';

    if (primary.isEmpty || secondary.isEmpty || primary == secondary) {
      return null;
    }

    return AssignedPersonaResult(
      primaryPersonaId: primary,
      secondaryPersonaId: secondary,
    );
  }
}
