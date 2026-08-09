import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import 'assessment_set_service.dart';
import 'iq_recovery.dart';

/// Canonical dimension IDs from docs/core_engine/canonical_dimension_registry_v1.md
class CanonicalDimensions {
  CanonicalDimensions._();

  static const iq = <String>[
    'logical_reasoning',
    'pattern_reasoning',
    'verbal_reasoning',
    'spatial_reasoning',
  ];

  static const eq = <String>[
    'empathy',
    'perspective_taking',
    'self_awareness',
    'emotion_regulation',
    'emotional_openness',
    'boundary_setting',
    'assertiveness',
    'conflict_approach',
    'repair_orientation',
    'social_awareness',
  ];

  static const frequency = <String>[
    'depth_preference',
    'social_energy',
    'spontaneity',
    'stability',
    'disclosure_pace',
    'communication_pace',
  ];

  /// Live Frequency vector keys → canonical IDs.
  static const frequencyLegacyToCanonical = <String, String>{
    'depth': 'depth_preference',
    'socialEnergy': 'social_energy',
    'spontaneity': 'spontaneity',
    'stability': 'stability',
    'emotionalOpenness': 'disclosure_pace',
    'conversationPace': 'communication_pace',
  };
}

/// Version labels for P1B-1 legacy-compatible persistence (not QRCF scoring).
class CanonicalAssessmentVersions {
  CanonicalAssessmentVersions._();

  static const assessmentVersion = 'assessment_result_v1';
  static const questionSchemaVersion = 'qschema_legacy_v0';
  static const traitScoringVersionLegacyTotal = 'trait_unscored_legacy_total';
  static const traitScoringVersionFrequencyPartial =
      'trait_frequency_legacy_partial_v1';
  static const normalizationVersion = 'norm_v0_missing_explicit';
  static const rviVersion = 'rvi_v0_unscored';
}

/// Shared merge writer for `users/{uid}/assessments/{type}` documents.
///
/// Keeps field conventions auditable: omits optional nulls, preserves
/// `created_at` on update, always refreshes `updated_at`, never invents
/// neutral dimension scores.
class CanonicalAssessmentPersistence {
  CanonicalAssessmentPersistence({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _authOrThrow => _auth ?? FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String type) {
    final db = _firestore ?? FirebaseFirestore.instance;
    return db.collection('users').doc(uid).collection('assessments').doc(type);
  }

  /// Builds a Firestore payload omitting keys whose values are null.
  static Map<String, dynamic> omitNulls(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    for (final e in input.entries) {
      if (e.value != null) out[e.key] = e.value;
    }
    return out;
  }

  Future<void> upsertCompletedAssessment({
    required String assessmentType,
    required Map<String, dynamic> fields,
  }) async {
    final user = _authOrThrow.currentUser;
    if (user == null) {
      throw StateError('User is not authenticated.');
    }
    await upsertCompletedAssessmentForUid(
      uid: user.uid,
      assessmentType: assessmentType,
      fields: fields,
    );
  }

  /// Testable entry that does not require FirebaseAuth currentUser.
  Future<void> upsertCompletedAssessmentForUid({
    required String uid,
    required String assessmentType,
    required Map<String, dynamic> fields,
  }) async {
    final ref = _doc(uid, assessmentType);
    final existing = await ref.get();
    final payload = omitNulls({
      ...fields,
      'assessment_type': assessmentType,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Preserve first-write created_at; never overwrite on merge updates.
    if (!existing.exists) {
      payload['created_at'] = FieldValue.serverTimestamp();
    } else {
      payload.remove('created_at');
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getAssessment(
    String assessmentType, {
    String? uid,
  }) async {
    final resolvedUid = uid ?? _authOrThrow.currentUser?.uid;
    if (resolvedUid == null) return null;
    final snap = await _doc(resolvedUid, assessmentType).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  /// Recovers IQ raw score + question count with explicit unavailable state.
  ///
  /// Denominator order: canonical `question_count` → assignment order/count →
  /// set metadata for persisted `set_id`. User mirror supplies raw only.
  Future<IqRecoveryResult> recoverIqResult({String? uid}) async {
    final resolvedUid = uid ?? _authOrThrow.currentUser?.uid;
    if (resolvedUid == null) {
      return const IqRecoveryResult(
        rawScore: null,
        questionCount: null,
        status: IqRecoveryResult.statusInsufficientMetadata,
        reasonCode: IqRecoveryResult.reasonMissingIqQuestionCount,
      );
    }

    final db = _firestore ?? FirebaseFirestore.instance;
    final canonical = await getAssessment('iq', uid: resolvedUid);

    final assignmentSnap =
        await FirestorePaths.userAssessmentAssignmentDoc(resolvedUid, 'iq')
            .get();
    final assignment = assignmentSnap.data();

    int? setMetadataQuestionCount;
    final beforeSet = IqRecoveryResult.fromSources(
      canonical: canonical,
      assignment: assignment,
    );
    if (!beforeSet.hasQuestionCount) {
      final setId = (canonical?['set_id'] as String?)?.trim().isNotEmpty == true
          ? (canonical!['set_id'] as String).trim()
          : (assignment?['set_id'] as String?)?.trim();
      if (setId != null && setId.isNotEmpty) {
        setMetadataQuestionCount = await AssessmentSetService(
          auth: _auth,
          firestore: db,
        ).questionCountForSet(setId: setId, type: 'iq');
      }
    }

    final beforeMirror = IqRecoveryResult.fromSources(
      canonical: canonical,
      assignment: assignment,
      setMetadataQuestionCount: setMetadataQuestionCount,
    );

    int? mirrorRaw;
    if (beforeMirror.rawScore == null) {
      final userSnap = await db.collection('users').doc(resolvedUid).get();
      final iq = userSnap.data()?['iq_score'];
      if (iq is num) mirrorRaw = iq.toInt();
    }

    return IqRecoveryResult.fromSources(
      canonical: canonical,
      assignment: assignment,
      setMetadataQuestionCount: setMetadataQuestionCount,
      userMirrorRawScore: mirrorRaw,
    );
  }

  /// Recovers legacy IQ raw correct count from canonical IQ doc, else assignment.
  Future<int?> recoverIqRawScore({String? uid}) async {
    final recovered = await recoverIqResult(uid: uid);
    return recovered.rawScore;
  }

  Map<String, dynamic> buildLegacyIqEqPayload({
    required String assessmentType,
    required String setId,
    required String contentVersion,
    required String locale,
    required String languageUsed,
    required int questionCount,
    required int answeredCount,
    required int rawScore,
    required List<String> missingDimensions,
    String? assignmentType,
    String? legacyScoringMode,
    DateTime? startedAt,
  }) {
    assert(assessmentType == 'iq' || assessmentType == 'eq');
    return omitNulls({
      'assessment_version': CanonicalAssessmentVersions.assessmentVersion,
      'question_schema_version':
          CanonicalAssessmentVersions.questionSchemaVersion,
      'content_version': contentVersion,
      'trait_scoring_version':
          CanonicalAssessmentVersions.traitScoringVersionLegacyTotal,
      'normalization_version': CanonicalAssessmentVersions.normalizationVersion,
      'locale': locale,
      'language_used': languageUsed,
      'set_id': setId,
      if (assignmentType != null)
        'assignment_ref': 'assessment_assignments/$assignmentType',
      'question_count': questionCount,
      'answered_count': answeredCount,
      'raw_score': rawScore,
      'performance_summary': {
        'correct_count': rawScore,
        'attempted_count': answeredCount,
      },
      'status': 'completed',
      if (startedAt != null) 'started_at': Timestamp.fromDate(startedAt),
      'completed_at': FieldValue.serverTimestamp(),
      'source': 'client_v1',
      // Truthful: domain traits are not scored yet.
      'dimension_scores': <String, dynamic>{},
      'dimension_evidence_counts': <String, dynamic>{},
      'dimension_reliability': <String, dynamic>{},
      'missing_dimensions': missingDimensions,
      'canonical_profile_ready': false,
      if (legacyScoringMode != null) 'legacy_scoring_mode': legacyScoringMode,
      'response_validity': {
        'rvi_version': CanonicalAssessmentVersions.rviVersion,
        'completion_ratio':
            questionCount == 0 ? 0.0 : answeredCount / questionCount,
        'straightlining_flag': false,
        'too_fast_flag': false,
        'inconsistency_flag': false,
        'quality_band': 'unknown',
      },
    });
  }
}
