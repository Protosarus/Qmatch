import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../domain/eq_bank/eq_bank_contract.dart';
import '../domain/eq_scoring/eq_scoring.dart';
import '../domain/eq_session/eq_session_contract.dart';
import '../domain/frequency_bank/frequency_bank.dart';
import '../domain/frequency_scoring/frequency_scoring.dart';
import '../domain/frequency_session/frequency_session_contract.dart';
import '../domain/iq_scoring/iq_scoring_models.dart';
import '../domain/profile/profile.dart';
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
  static const traitScoringVersionIq4dUncalibrated =
      'iq_4d_uncalibrated_accuracy_v1';
  static const traitScoringVersionEq10dUncalibrated =
      'eq_10d_uncalibrated_signed_evidence_v1';
  static const traitScoringVersionFrequencyPartial =
      'trait_frequency_legacy_partial_v1';
  static const normalizationVersion = 'norm_v0_missing_explicit';
  static const rviVersion = 'rvi_v0_unscored';
  static const iqLiveResultSchemaVersion = 'qmatch_iq_live_result_v1';
  static const eqLiveResultSchemaVersion = 'qmatch_eq_10d_live_result_v1';
  static const frequencyLiveResultSchemaVersion =
      'qmatch_frequency_6d_live_result_v1';
  static const traitScoringVersionFrequency6dUncalibrated =
      'frequency_6d_uncalibrated_signed_evidence_v1';
  static const canonicalProfileSchemaVersion =
      QmatchProfileContract.schemaVersion;
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

  /// Upserts the versioned partial/full canonical profile document.
  ///
  /// Path: `users/{uid}/profiles/canonical_v1`
  /// Idempotent for the same IQ contribution (merge replace of IQ fields).
  Future<void> upsertCanonicalProfileFragment(
    QmatchCanonicalProfileFragment fragment,
  ) async {
    final user = _authOrThrow.currentUser;
    if (user == null) {
      throw StateError('User is not authenticated.');
    }
    if (fragment.ownerUid != user.uid) {
      throw StateError('Profile owner UID mismatch.');
    }
    await upsertCanonicalProfileFragmentForUid(fragment);
  }

  Future<void> upsertCanonicalProfileFragmentForUid(
    QmatchCanonicalProfileFragment fragment,
  ) async {
    final db = _firestore ?? FirebaseFirestore.instance;
    final ref = db
        .collection('users')
        .doc(fragment.ownerUid)
        .collection('profiles')
        .doc('canonical_v1');
    final existing = await ref.get();
    final payload = omitNulls({
      ...fragment.toFirestoreFields(),
      // Server timestamps for audit; keep ISO updated_at from fragment too.
      'persisted_at': FieldValue.serverTimestamp(),
    });
    if (!existing.exists) {
      payload['created_at'] = FieldValue.serverTimestamp();
    } else {
      payload.remove('created_at');
    }
    await ref.set(payload, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getCanonicalProfile({String? uid}) async {
    final resolvedUid = uid ?? _authOrThrow.currentUser?.uid;
    if (resolvedUid == null) return null;
    final db = _firestore ?? FirebaseFirestore.instance;
    final snap = await db
        .collection('users')
        .doc(resolvedUid)
        .collection('profiles')
        .doc('canonical_v1')
        .get();
    if (!snap.exists) return null;
    return snap.data();
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

  /// Versioned canonical 4D IQ live result (P2C-2A-5).
  ///
  /// Does **not** overwrite the meaning of legacy scalar `iq_score`.
  /// Stores uncalibrated provisional scores only — no answer keys / IQ / percentiles.
  Map<String, dynamic> buildCanonicalIq4dPayload({
    required IqCanonicalScoringResult result,
    required String locale,
    required String languageUsed,
    DateTime? startedAt,
  }) {
    final dimensionScores = <String, dynamic>{};
    final evidenceCounts = <String, dynamic>{};
    for (final d in result.dimensionScores) {
      dimensionScores[d.dimension] = d.provisionalScore;
      evidenceCounts[d.dimension] = d.answeredCount;
    }
    return omitNulls({
      'assessment_version': CanonicalAssessmentVersions.assessmentVersion,
      'live_result_schema_version':
          CanonicalAssessmentVersions.iqLiveResultSchemaVersion,
      'question_schema_version': 'qmatch_iq_bank_v1',
      'content_version': result.bankVersion,
      'bank_version': result.bankVersion,
      'bank_locale': result.bankLocale,
      'selection_policy_version': result.selectionPolicyVersion,
      'scoring_policy_version': result.scoringPolicyVersion,
      'trait_scoring_version':
          CanonicalAssessmentVersions.traitScoringVersionIq4dUncalibrated,
      'normalization_version': CanonicalAssessmentVersions.normalizationVersion,
      'locale': locale,
      'language_used': languageUsed,
      'session_id': result.sessionId,
      'question_count': 25,
      'answered_count': result.totalAnswered,
      // Explicitly omit legacy scalar raw_score / iq identity.
      'status': 'completed',
      if (startedAt != null) 'started_at': Timestamp.fromDate(startedAt),
      'completed_at': FieldValue.serverTimestamp(),
      'source': 'client_canonical_iq_v1',
      'calibration_status': result.calibrationStatus.wireValue,
      'dimension_scores': dimensionScores,
      'dimension_evidence_counts': evidenceCounts,
      // Reliability not available — do not fabricate.
      'dimension_reliability': <String, dynamic>{},
      'missing_dimensions': <String>[],
      'canonical_profile_ready': false,
      'iq_result_kind': 'uncalibrated_reasoning_profile_v1',
      'canonical_dimensions': [
        for (final d in result.dimensionScores)
          {
            'dimension': d.dimension,
            'item_count': d.itemCount,
            'correct_count': d.correctCount,
            'incorrect_count': d.incorrectCount,
            'answered_count': d.answeredCount,
            'raw_accuracy': d.rawAccuracy,
            'provisional_score': d.provisionalScore,
            'calibration_status': d.calibrationStatus.wireValue,
          },
      ],
      'response_validity': {
        'rvi_version': CanonicalAssessmentVersions.rviVersion,
        'completion_ratio': 1.0,
        'straightlining_flag': false,
        'too_fast_flag': false,
        'inconsistency_flag': false,
        'quality_band': 'unknown',
      },
      'structural_flags': result.structuralFlags.toJson(),
    });
  }

  /// Versioned canonical 10D EQ live result (P2C-2A-7R2).
  ///
  /// Uncalibrated signed-evidence profile — no scalar EQ / percentiles /
  /// answer keys / fabricated reliability.
  Map<String, dynamic> buildCanonicalEq10dPayload({
    required EqCanonicalScoringResult result,
    required String sessionId,
    required String locale,
    required String languageUsed,
    DateTime? startedAt,
  }) {
    final dimensionScores = <String, dynamic>{};
    final evidenceCounts = <String, dynamic>{};
    final rawSigned = <String, dynamic>{};
    for (final d in result.dimensionScores) {
      dimensionScores[d.dimensionId] = d.normalizedScore;
      evidenceCounts[d.dimensionId] = d.evidenceCount;
      rawSigned[d.dimensionId] = d.rawSignedEvidence;
    }
    return omitNulls({
      'assessment_version': CanonicalAssessmentVersions.assessmentVersion,
      'live_result_schema_version':
          CanonicalAssessmentVersions.eqLiveResultSchemaVersion,
      'question_schema_version': EqBankContract.schemaVersion,
      'content_version': result.bankVersion,
      'bank_version': result.bankVersion,
      'bank_locale': result.bankLocale,
      'selection_policy_version': EqSessionContract.selectionPolicyVersion,
      'scoring_policy_version': result.scoringPolicyVersion,
      'trait_scoring_version':
          CanonicalAssessmentVersions.traitScoringVersionEq10dUncalibrated,
      'normalization_version': CanonicalAssessmentVersions.normalizationVersion,
      'locale': locale,
      'language_used': languageUsed,
      'session_id': sessionId,
      'question_count': 30,
      'answered_count': result.totalAnswered,
      'status': 'completed',
      if (startedAt != null) 'started_at': Timestamp.fromDate(startedAt),
      'completed_at': FieldValue.serverTimestamp(),
      'source': 'client_canonical_eq_v1',
      'calibration_status': result.calibrationStatus.wireValue,
      'reliability_status': result.reliabilityStatus.wireValue,
      'dimension_scores': dimensionScores,
      'dimension_raw_signed_evidence': rawSigned,
      'dimension_evidence_counts': evidenceCounts,
      'dimension_reliability': <String, dynamic>{},
      'missing_dimensions': <String>[],
      'canonical_profile_ready': false,
      'eq_result_kind':
          'uncalibrated_emotional_relational_behavioral_profile_v1',
      'canonical_dimensions': [
        for (final d in result.dimensionScores)
          {
            'dimension_id': d.dimensionId,
            'evidence_status': d.evidenceStatus.wireValue,
            'evidence_count': d.evidenceCount,
            'raw_signed_evidence': d.rawSignedEvidence,
            'normalized_score': d.normalizedScore,
            'calibration_status': d.calibrationStatus.wireValue,
            'reliability_status': d.reliabilityStatus.wireValue,
          },
      ],
      'response_validity': {
        'rvi_version': CanonicalAssessmentVersions.rviVersion,
        'rvi_runtime_gate': result.rviRuntimeGate,
        'completion_ratio': 1.0,
        'quality_band': 'unknown',
      },
      'structural_flags': result.structuralFlags.toJson(),
      // Explicit absences:
      'overall_eq_score': null,
      'percentile': null,
      'correct_count': null,
    });
  }

  /// Versioned canonical 6D Frequency live result (P2C-2A-8R2).
  ///
  /// Uncalibrated signed-evidence profile — no scalar Frequency / percentiles /
  /// answer keys / fabricated reliability / Persona.
  Map<String, dynamic> buildCanonicalFrequency6dPayload({
    required FrequencyCanonicalScoringResult result,
    required String sessionId,
    required String locale,
    required String languageUsed,
    required Map<String, dynamic> qualitySignals,
    DateTime? startedAt,
  }) {
    final dimensionScores = <String, dynamic>{};
    final evidenceCounts = <String, dynamic>{};
    final rawSigned = <String, dynamic>{};
    for (final d in result.dimensionScores) {
      dimensionScores[d.dimensionId] = d.normalizedScore;
      evidenceCounts[d.dimensionId] = d.evidenceCount;
      rawSigned[d.dimensionId] = d.rawSignedEvidence;
    }
    return omitNulls({
      'assessment_version': CanonicalAssessmentVersions.assessmentVersion,
      'live_result_schema_version':
          CanonicalAssessmentVersions.frequencyLiveResultSchemaVersion,
      'question_schema_version': FrequencyBankContract.schemaVersion,
      'content_version': result.bankVersion,
      'bank_version': result.bankVersion,
      'bank_locale': result.bankLocale,
      'selection_policy_version':
          FrequencySessionContract.selectionPolicyVersion,
      'session_policy_version': FrequencySessionContract.selectionPolicyVersion,
      'scoring_policy_version': result.scoringPolicyVersion,
      'trait_scoring_version': CanonicalAssessmentVersions
          .traitScoringVersionFrequency6dUncalibrated,
      'normalization_version': CanonicalAssessmentVersions.normalizationVersion,
      'locale': locale,
      'language_used': languageUsed,
      'session_id': sessionId,
      'question_count': 50,
      'answered_count': result.totalAnswered,
      'status': 'completed',
      if (startedAt != null) 'started_at': Timestamp.fromDate(startedAt),
      'completed_at': FieldValue.serverTimestamp(),
      'source': 'client_canonical_frequency_v1',
      'calibration_status': result.calibrationStatus.wireValue,
      'reliability_status': result.reliabilityStatus.wireValue,
      'dimension_scores': dimensionScores,
      'dimension_raw_signed_evidence': rawSigned,
      'dimension_evidence_counts': evidenceCounts,
      'dimension_reliability': <String, dynamic>{},
      'missing_dimensions': <String>[],
      // Assessment-doc readiness for Frequency module; full 20D readiness lives
      // on profiles/canonical_v1 after Frequency→20D merge.
      'canonical_profile_ready': true,
      'frequency_result_kind':
          'uncalibrated_relational_rhythm_behavioral_preference_profile_v1',
      'canonical_dimensions': [
        for (final d in result.dimensionScores)
          {
            'dimension_id': d.dimensionId,
            'evidence_status': d.evidenceStatus.wireValue,
            'evidence_count': d.evidenceCount,
            'raw_signed_evidence': d.rawSignedEvidence,
            'normalized_score': d.normalizedScore,
            'calibration_status': d.calibrationStatus.wireValue,
            'reliability_status': d.reliabilityStatus.wireValue,
          },
      ],
      'quality_signals': qualitySignals,
      'response_validity': {
        'rvi_version': CanonicalAssessmentVersions.rviVersion,
        'rvi_runtime_gate': result.rviRuntimeGate,
        'completion_ratio': 1.0,
        'quality_band': 'unknown',
        'protocol_signal_only': true,
      },
      'structural_flags': result.structuralFlags.toJson(),
      // Explicit absences:
      'overall_frequency_score': null,
      'percentile': null,
      'correct_count': null,
      'persona': null,
      'matching_score': null,
    });
  }
}
