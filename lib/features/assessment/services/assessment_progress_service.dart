import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../domain/frequency_v2_runtime/frequency_v2_result_authority.dart';
import '../domain/persona_scoring/persona_runtime_result_policy.dart';
import '../models/assessment_progress.dart';
import '../models/frequency_model.dart';
import 'canonical_assessment_persistence.dart';
import 'canonical_assessment_profile_reconciler.dart';

/// Resolves and writes assessment progress for flow version 2.
///
/// Authoritative order per module:
/// 1. Canonical `users/{uid}/assessments/{type}` status
/// 2. Assignment `completed`
/// 3. Explicit mirrors (`iq_completed` / `eq_completed` / `frequency_completed`)
///
/// Never infers completion from archetype, category, scores, or persona fields.
class AssessmentProgressService {
  AssessmentProgressService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _authOrThrow => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<AssessmentProgressSnapshot> resolveForCurrentUser() async {
    final uid = _authOrThrow.currentUser?.uid;
    if (uid == null) {
      return AssessmentProgressSnapshot(
        assessmentFlowVersion: null,
        iqStatus: AssessmentModuleStatus.notStarted,
        eqStatus: AssessmentModuleStatus.notStarted,
        frequencyStatus: AssessmentModuleStatus.notStarted,
        frequencyCompleted: false,
        frequencyIncomplete: false,
        iqCompleted: false,
        eqCompleted: false,
        allAssessmentsCompleted: false,
        assessmentFlowCompleted: false,
        canonicalPersonaAvailable: false,
        profileCompleted: false,
        destination: AssessmentFlowDestination.iq,
        resolutionSource: 'unauthenticated',
        reason: 'no_user',
      );
    }
    return resolveForUid(uid);
  }

  Future<AssessmentProgressSnapshot> resolveForUid(
    String uid, {
    Map<String, dynamic>? userDoc,
  }) async {
    final persistence = CanonicalAssessmentPersistence();
    final fetched = await Future.wait<Object?>([
      userDoc == null
          ? FirestorePaths.userDoc(uid).get()
          : Future<DocumentSnapshot<Map<String, dynamic>>?>.value(null),
      FirestorePaths.userAssessmentDoc(uid, 'iq').get(),
      FirestorePaths.userAssessmentDoc(uid, 'eq').get(),
      FirestorePaths.userAssessmentDoc(uid, 'frequency').get(),
      FirestorePaths.userAssessmentDoc(
        uid,
        FrequencyV2ResultAuthority.resultDocId,
      ).get(),
      FirestorePaths.userAssessmentDoc(
        uid,
        PersonaRuntimeResultPolicy.assessmentType,
      ).get(),
      FirestorePaths.userAssessmentAssignmentDoc(uid, 'iq').get(),
      FirestorePaths.userAssessmentAssignmentDoc(uid, 'eq').get(),
      FirestorePaths.userAssessmentAssignmentDoc(uid, 'frequency').get(),
      persistence.getCanonicalProfile(uid: uid),
    ]);

    final resolvedUserDoc = userDoc ??
        (fetched[0] as DocumentSnapshot<Map<String, dynamic>>?)?.data();
    final iqDoc = fetched[1] as DocumentSnapshot<Map<String, dynamic>>;
    final eqDoc = fetched[2] as DocumentSnapshot<Map<String, dynamic>>;
    final freqDoc = fetched[3] as DocumentSnapshot<Map<String, dynamic>>;
    final freqV2Doc = fetched[4] as DocumentSnapshot<Map<String, dynamic>>;
    final personaDoc = fetched[5] as DocumentSnapshot<Map<String, dynamic>>;
    final iqAsg = fetched[6] as DocumentSnapshot<Map<String, dynamic>>;
    final eqAsg = fetched[7] as DocumentSnapshot<Map<String, dynamic>>;
    final freqAsg = fetched[8] as DocumentSnapshot<Map<String, dynamic>>;

    final snapshot = resolveFromMaps(
      userDoc: resolvedUserDoc,
      iqAssessment: iqDoc.data(),
      eqAssessment: eqDoc.data(),
      frequencyAssessment: freqDoc.data(),
      frequencyV2Assessment: freqV2Doc.data(),
      personaAssessment: personaDoc.data(),
      iqAssignment: iqAsg.data(),
      eqAssignment: eqAsg.data(),
      frequencyAssignment: freqAsg.data(),
    );

    // Canonical profile gate: completion mirrors alone are not enough to
    // advance past missing IQ4 / 14/20 fragments.
    final reconciler = CanonicalAssessmentProfileReconciler(
      persistence: persistence,
    );
    var check = reconciler.inspectProfileMap(
      fetched[9] as Map<String, dynamic>?,
    );

    if (snapshot.iqCompleted && !check.hasExactIq4) {
      final repair = await reconciler.ensureIq4(ownerUid: uid);
      check = repair.check ??
          reconciler.inspectProfileMap(
            await persistence.getCanonicalProfile(uid: uid),
          );
      if (!repair.ok || !check.hasExactIq4) {
        return AssessmentProgressSnapshot(
          assessmentFlowVersion: snapshot.assessmentFlowVersion,
          iqStatus: snapshot.iqStatus,
          eqStatus: snapshot.eqStatus,
          frequencyStatus: snapshot.frequencyStatus,
          frequencyCompleted: snapshot.frequencyCompleted,
          frequencyIncomplete: snapshot.frequencyIncomplete,
          iqCompleted: snapshot.iqCompleted,
          eqCompleted: snapshot.eqCompleted,
          allAssessmentsCompleted: snapshot.allAssessmentsCompleted,
          assessmentFlowCompleted: snapshot.assessmentFlowCompleted,
          canonicalPersonaAvailable: snapshot.canonicalPersonaAvailable,
          profileCompleted: snapshot.profileCompleted,
          destination: AssessmentFlowDestination.iq,
          resolutionSource: snapshot.resolutionSource,
          reason: 'iq_canonical_profile_required',
        );
      }
    }

    if (snapshot.iqCompleted && snapshot.eqCompleted && !check.hasExact14) {
      final repair = await reconciler.ensureIq4AndEq10(ownerUid: uid);
      check = repair.check ??
          reconciler.inspectProfileMap(
            await persistence.getCanonicalProfile(uid: uid),
          );
      if (!repair.ok || !check.hasExact14) {
        if (snapshot.destination == AssessmentFlowDestination.frequency) {
          final missingIq4 = !check.hasExactIq4;
          return AssessmentProgressSnapshot(
            assessmentFlowVersion: snapshot.assessmentFlowVersion,
            iqStatus: snapshot.iqStatus,
            eqStatus: snapshot.eqStatus,
            frequencyStatus: snapshot.frequencyStatus,
            frequencyCompleted: snapshot.frequencyCompleted,
            frequencyIncomplete: snapshot.frequencyIncomplete,
            iqCompleted: snapshot.iqCompleted,
            eqCompleted: snapshot.eqCompleted,
            allAssessmentsCompleted: snapshot.allAssessmentsCompleted,
            assessmentFlowCompleted: snapshot.assessmentFlowCompleted,
            canonicalPersonaAvailable: snapshot.canonicalPersonaAvailable,
            profileCompleted: snapshot.profileCompleted,
            destination: missingIq4
                ? AssessmentFlowDestination.iq
                : AssessmentFlowDestination.eq,
            resolutionSource: snapshot.resolutionSource,
            reason: missingIq4
                ? 'iq_canonical_profile_required'
                : 'eq_canonical_profile_required',
          );
        }
      }
    }

    return snapshot;
  }

  /// Pure resolver for unit tests (no Firebase).
  static AssessmentProgressSnapshot resolveFromMaps({
    Map<String, dynamic>? userDoc,
    Map<String, dynamic>? iqAssessment,
    Map<String, dynamic>? eqAssessment,
    Map<String, dynamic>? frequencyAssessment,
    Map<String, dynamic>? frequencyV2Assessment,
    Map<String, dynamic>? personaAssessment,
    Map<String, dynamic>? iqAssignment,
    Map<String, dynamic>? eqAssignment,
    Map<String, dynamic>? frequencyAssignment,
  }) {
    final flowVersion = _readFlowVersion(userDoc);
    final profileCompleted = userDoc?['profile_completed'] == true;
    final legacyTestCompleted = userDoc?['test_completed'] == true;
    final flowCompletedMirror = userDoc?['assessment_flow_completed'] == true;

    final iq = _resolveIqEqModule(
      assessment: iqAssessment,
      assignment: iqAssignment,
      mirrorCompleted: userDoc?['iq_completed'] == true,
    );
    final eq = _resolveIqEqModule(
      assessment: eqAssessment,
      assignment: eqAssignment,
      mirrorCompleted: userDoc?['eq_completed'] == true,
    );
    final frequency = _resolveFrequencyModule(
      assessment: frequencyAssessment,
      assignment: frequencyAssignment,
      mirrorCompleted: userDoc?['frequency_completed'] == true,
      mirrorStatus: userDoc?['frequency_status'] as String?,
      frequencyV2Assessment: frequencyV2Assessment,
    );

    var iqCompleted = iq.status == AssessmentModuleStatus.completed;
    var eqCompleted = eq.status == AssessmentModuleStatus.completed;
    final frequencyCompleted =
        frequency.status == AssessmentModuleStatus.completed;
    final frequencyIncomplete =
        frequency.status == AssessmentModuleStatus.incomplete;

    // Legacy (no flow version): test_completed historically meant IQ+EQ done.
    // Use only to advance toward Frequency — never alone as full-flow complete.
    var resolutionSource = iq.source;
    if (flowVersion == null && legacyTestCompleted) {
      if (!iqCompleted) {
        iqCompleted = true;
        resolutionSource = 'legacy_test_completed';
      }
      if (!eqCompleted) {
        eqCompleted = true;
        resolutionSource = 'legacy_test_completed';
      }
    }

    final allAssessmentsCompleted =
        iqCompleted && eqCompleted && frequencyCompleted;
    final assessmentFlowCompleted =
        flowCompletedMirror || allAssessmentsCompleted;

    final canonicalPersonaAvailable =
        PersonaRuntimeResultPolicy.isCurrentValid(personaAssessment);

    final routed = _route(
      flowVersion: flowVersion,
      iqCompleted: iqCompleted,
      eqCompleted: eqCompleted,
      frequencyCompleted: frequencyCompleted,
      frequencyIncomplete: frequencyIncomplete,
      allAssessmentsCompleted: allAssessmentsCompleted,
      assessmentFlowCompleted: assessmentFlowCompleted,
      canonicalPersonaAvailable: canonicalPersonaAvailable,
      profileCompleted: profileCompleted,
      legacyTestCompleted: legacyTestCompleted,
      iqSource: iq.source,
      eqSource: eq.source,
      frequencySource: frequency.source,
      fallbackSource: resolutionSource,
    );

    return AssessmentProgressSnapshot(
      assessmentFlowVersion: flowVersion,
      iqStatus: iqCompleted ? AssessmentModuleStatus.completed : iq.status,
      eqStatus: eqCompleted ? AssessmentModuleStatus.completed : eq.status,
      frequencyStatus: frequency.status,
      frequencyCompleted: frequencyCompleted,
      frequencyIncomplete: frequencyIncomplete,
      iqCompleted: iqCompleted,
      eqCompleted: eqCompleted,
      allAssessmentsCompleted: allAssessmentsCompleted,
      assessmentFlowCompleted: assessmentFlowCompleted,
      canonicalPersonaAvailable: canonicalPersonaAvailable,
      profileCompleted: profileCompleted,
      destination: routed.destination,
      resolutionSource: routed.source,
      reason: routed.reason,
    );
  }

  static ({
    AssessmentFlowDestination destination,
    String source,
    String? reason
  }) _route({
    required int? flowVersion,
    required bool iqCompleted,
    required bool eqCompleted,
    required bool frequencyCompleted,
    required bool frequencyIncomplete,
    required bool allAssessmentsCompleted,
    required bool assessmentFlowCompleted,
    required bool canonicalPersonaAvailable,
    required bool profileCompleted,
    required bool legacyTestCompleted,
    required String iqSource,
    required String eqSource,
    required String frequencySource,
    required String fallbackSource,
  }) {
    final isV2 = flowVersion == AssessmentProgressSnapshot.flowVersionV2;

    if (isV2) {
      if (!iqCompleted) {
        return (
          destination: AssessmentFlowDestination.iq,
          source: iqSource,
          reason: 'v2_iq_required',
        );
      }
      if (!eqCompleted) {
        return (
          destination: AssessmentFlowDestination.eq,
          source: eqSource,
          reason: 'v2_eq_required',
        );
      }
      if (!frequencyCompleted) {
        return (
          destination: AssessmentFlowDestination.frequency,
          source: frequencySource,
          reason: frequencyIncomplete
              ? 'v2_frequency_incomplete'
              : 'v2_frequency_required',
        );
      }
      if (!canonicalPersonaAvailable) {
        return (
          destination: AssessmentFlowDestination.persona,
          source: 'v2_assessments_complete',
          reason: 'v2_persona_required',
        );
      }
      if (!profileCompleted) {
        return (
          destination: AssessmentFlowDestination.profileSetup,
          source: 'v2_persona_complete',
          reason: 'v2_profile_required',
        );
      }
      return (
        destination: AssessmentFlowDestination.main,
        source: 'v2_complete',
        reason: null,
      );
    }

    // --- Legacy routing (no assessment_flow_version) ---
    //
    // Compatibility: if the user already has a completed profile and was able
    // to use the app historically, do not lock them out of Main when Frequency
    // is missing. Soft Frequency prompts are out of scope for P1B-2A.
    //
    // When the full 20D battery is complete, Persona reveal is required before
    // profile/main — same as v2 — so cold start cannot skip it.
    if (allAssessmentsCompleted && !canonicalPersonaAvailable) {
      return (
        destination: AssessmentFlowDestination.persona,
        source: frequencySource,
        reason: 'legacy_persona_required',
      );
    }

    if (profileCompleted) {
      return (
        destination: AssessmentFlowDestination.main,
        source: 'legacy_active_profile_grandfather',
        reason: 'legacy_profile_complete_allows_main',
      );
    }

    if (frequencyCompleted || assessmentFlowCompleted) {
      return (
        destination: AssessmentFlowDestination.profileSetup,
        source: frequencySource,
        reason: 'legacy_frequency_complete_needs_profile',
      );
    }

    if (legacyTestCompleted || (iqCompleted && eqCompleted)) {
      return (
        destination: AssessmentFlowDestination.frequency,
        source: legacyTestCompleted ? 'legacy_test_completed' : fallbackSource,
        reason: 'legacy_needs_frequency',
      );
    }

    if (!iqCompleted) {
      return (
        destination: AssessmentFlowDestination.iq,
        source: iqSource,
        reason: 'legacy_iq_required',
      );
    }
    if (!eqCompleted) {
      return (
        destination: AssessmentFlowDestination.eq,
        source: eqSource,
        reason: 'legacy_eq_required',
      );
    }

    return (
      destination: AssessmentFlowDestination.frequency,
      source: frequencySource,
      reason: 'legacy_frequency_required',
    );
  }

  static int? _readFlowVersion(Map<String, dynamic>? userDoc) {
    final v = userDoc?['assessment_flow_version'];
    if (v is num) return v.toInt();
    return null;
  }

  static ({AssessmentModuleStatus status, String source}) _resolveIqEqModule({
    required Map<String, dynamic>? assessment,
    required Map<String, dynamic>? assignment,
    required bool mirrorCompleted,
  }) {
    if (assessment != null) {
      final status = assessment['status'] as String?;
      if (status == 'completed') {
        return (status: AssessmentModuleStatus.completed, source: 'canonical');
      }
      if (status == 'in_progress') {
        return (status: AssessmentModuleStatus.inProgress, source: 'canonical');
      }
    }
    if (assignment != null && assignment['completed'] == true) {
      return (status: AssessmentModuleStatus.completed, source: 'assignment');
    }
    if (mirrorCompleted) {
      return (status: AssessmentModuleStatus.completed, source: 'mirror');
    }
    if (assignment != null && assignment['set_id'] != null) {
      return (status: AssessmentModuleStatus.inProgress, source: 'assignment');
    }
    return (status: AssessmentModuleStatus.notStarted, source: 'none');
  }

  static ({AssessmentModuleStatus status, String source})
      _resolveFrequencyModule({
    required Map<String, dynamic>? assessment,
    required Map<String, dynamic>? assignment,
    required bool mirrorCompleted,
    required String? mirrorStatus,
    Map<String, dynamic>? frequencyV2Assessment,
  }) {
    if (FrequencyV2ResultAuthority.isAuthoritativeCompleted(
      frequencyV2Assessment,
    )) {
      return (
        status: AssessmentModuleStatus.completed,
        source: 'frequency_v2',
      );
    }
    if (assessment != null) {
      final status = assessment['status'] as String?;
      if (status == FrequencyResult.statusIncomplete ||
          status == 'incomplete') {
        return (status: AssessmentModuleStatus.incomplete, source: 'canonical');
      }
      if (status == FrequencyResult.statusCompleted || status == 'completed') {
        final ready = assessment['canonical_profile_ready'] == true;
        final missing = assessment['missing_dimensions'];
        final missingEmpty = missing is! List || missing.isEmpty;
        if (ready || missingEmpty) {
          return (
            status: AssessmentModuleStatus.completed,
            source: 'canonical',
          );
        }
        // Completed status but missing dims → treat as incomplete.
        return (status: AssessmentModuleStatus.incomplete, source: 'canonical');
      }
      if (status == 'in_progress') {
        return (status: AssessmentModuleStatus.inProgress, source: 'canonical');
      }
    }

    if (mirrorStatus == FrequencyResult.statusIncomplete ||
        mirrorStatus == 'incomplete') {
      return (status: AssessmentModuleStatus.incomplete, source: 'mirror');
    }

    // Assignment alone is not enough for Frequency complete (may be incomplete
    // evidence). Prefer canonical. Assignment completed + mirror is ok.
    if (mirrorCompleted) {
      return (status: AssessmentModuleStatus.completed, source: 'mirror');
    }
    if (assignment != null && assignment['completed'] == true) {
      // Without canonical ready flag, do not treat assignment as complete.
      return (status: AssessmentModuleStatus.inProgress, source: 'assignment');
    }
    return (status: AssessmentModuleStatus.notStarted, source: 'none');
  }

  /// Intentional v2 write after IQ finishes.
  Future<void> markIqCompleted({required int? rawScore}) async {
    final uid = _authOrThrow.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(
      {
        'iq_completed': true,
        'assessment_flow_version': AssessmentProgressSnapshot.flowVersionV2,
        if (rawScore != null) 'iq_score': rawScore,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// EQ finished in flow v2: no persona / archetype / test_completed.
  Future<void> markEqCompleted({
    int? eqScore,
    int? eqNormalized,
    int? iqScore,
  }) async {
    final uid = _authOrThrow.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(
      {
        'eq_completed': true,
        'assessment_flow_version': AssessmentProgressSnapshot.flowVersionV2,
        if (eqScore != null) 'eq_score': eqScore,
        if (eqNormalized != null) 'eq_normalized': eqNormalized,
        if (iqScore != null) 'iq_score': iqScore,
        // Deliberately omit: test_completed, archetype, category, iq_normalized
        // unless already present (merge does not erase).
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Deprecated leftover. Live Frequency completion does not call this.
  ///
  /// Must not write `test_completed`, `assessment_flow_completed`, or
  /// `test_completed_at` — those are no longer client Discover authority.
  /// Server `finalizeFrequency` already writes `frequency_completed`.
  Future<void> markAssessmentFlowCompleted() async {
    final uid = _authOrThrow.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(
      {
        'frequency_completed': true,
        'assessment_flow_version': AssessmentProgressSnapshot.flowVersionV2,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
