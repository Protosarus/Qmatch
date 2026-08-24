import 'package:cloud_firestore/cloud_firestore.dart';

import '../../assessment/services/canonical_assessment_persistence.dart';
import '../domain/relationship_analysis_state.dart';
import '../domain/relationship_dimensions.dart';

/// Persist under `users/{uid}/assessments/relationship`.
/// Hard wall: never writes Persona / 20D / Matching fields.
class RelationshipAnalysisPersistence {
  RelationshipAnalysisPersistence({
    CanonicalAssessmentPersistence? assessmentPersistence,
    Future<Map<String, dynamic>?> Function(String uid)? loadOverride,
    Future<void> Function(String uid, Map<String, dynamic> fields)?
        writeOverride,
  })  : _assessmentPersistence =
            assessmentPersistence ?? CanonicalAssessmentPersistence(),
        _loadOverride = loadOverride,
        _writeOverride = writeOverride;

  final CanonicalAssessmentPersistence _assessmentPersistence;
  final Future<Map<String, dynamic>?> Function(String uid)? _loadOverride;
  final Future<void> Function(String uid, Map<String, dynamic> fields)?
      _writeOverride;

  static const assessmentType = RelationshipAnalysisContract.assessmentType;

  /// Sentinel used by [writeOverride] merge helpers: remove `active_micro_scan`.
  static const clearActiveMicroScanSentinel = Object();

  Future<RelationshipAnalysisState> loadForUid(String uid) async {
    if (uid.trim().isEmpty) return RelationshipAnalysisState.empty();
    final loader = _loadOverride;
    final doc = loader != null
        ? await loader(uid)
        : await _assessmentPersistence.getAssessment(
            assessmentType,
            uid: uid,
          );
    return RelationshipAnalysisState.fromPersistence(doc);
  }

  Future<void> saveForUid({
    required String uid,
    required RelationshipAnalysisState state,
  }) async {
    if (uid.trim().isEmpty) {
      throw StateError('Owner UID required for Relationship Analysis');
    }

    final raw = state.toPersistenceFields();
    final shouldClearActiveMicroScan = raw['active_micro_scan'] == null;

    final fields = CanonicalAssessmentPersistence.omitNulls(raw);

    const forbidden = {
      'primary_persona_id',
      'secondary_persona_id',
      'raw_delta_d',
      'compatibility_score',
      'structural_distance',
      'measured_dimensions',
    };
    for (final key in forbidden) {
      fields.remove(key);
    }

    // omitNulls + Firestore merge would otherwise leave a stale active_micro_scan.
    if (shouldClearActiveMicroScan) {
      final writer = _writeOverride;
      if (writer != null) {
        fields['active_micro_scan'] = clearActiveMicroScanSentinel;
        await writer(uid, fields);
        return;
      }
      fields['active_micro_scan'] = FieldValue.delete();
      await _assessmentPersistence.upsertCompletedAssessmentForUid(
        uid: uid,
        assessmentType: assessmentType,
        fields: fields,
      );
      return;
    }

    final writer = _writeOverride;
    if (writer != null) {
      await writer(uid, fields);
      return;
    }

    await _assessmentPersistence.upsertCompletedAssessmentForUid(
      uid: uid,
      assessmentType: assessmentType,
      fields: fields,
    );
  }

  /// In-memory merge helper for tests / overrides that understand the sentinel.
  static void mergeFields(
    Map<String, dynamic> target,
    Map<String, dynamic> incoming,
  ) {
    for (final e in incoming.entries) {
      if (identical(e.value, clearActiveMicroScanSentinel) || e.value == null) {
        target.remove(e.key);
      } else {
        target[e.key] = e.value;
      }
    }
  }
}
