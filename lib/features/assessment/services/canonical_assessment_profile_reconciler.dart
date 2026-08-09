import '../domain/eq_scoring/eq_scoring.dart';
import '../domain/iq_scoring/iq_scoring.dart';
import '../domain/profile/profile.dart';
import 'canonical_assessment_persistence.dart';

/// Typed outcomes for canonical profile verification / repair.
enum CanonicalProfileRepairCode {
  ok,
  ownerUnavailable,
  iqAssessmentMissing,
  iqAssessmentInsufficient,
  eqAssessmentMissing,
  eqAssessmentInsufficient,
  iq4Incomplete,
  eq10Incomplete,
  frequency6Incomplete,
  adaptFailed,
  persistFailed,
  incompatiblePolicy,
  invalidRegistrySet,
}

class CanonicalProfileCheckResult {
  const CanonicalProfileCheckResult({
    required this.ok,
    required this.code,
    this.message,
    this.measuredIqIds = const [],
    this.measuredEqIds = const [],
    this.measuredFrequencyIds = const [],
    this.profile,
  });

  final bool ok;
  final CanonicalProfileRepairCode code;
  final String? message;
  final List<String> measuredIqIds;
  final List<String> measuredEqIds;
  final List<String> measuredFrequencyIds;
  final Map<String, dynamic>? profile;

  bool get hasExactIq4 => _exactSet(measuredIqIds, QmatchProfileTaxonomy.iq);
  bool get hasExactEq10 => _exactSet(measuredEqIds, QmatchProfileTaxonomy.eq);
  bool get hasExactFrequency6 =>
      _exactSet(measuredFrequencyIds, QmatchProfileTaxonomy.frequency);
  bool get hasExact14 => hasExactIq4 && hasExactEq10;
  bool get hasExact20 => hasExact14 && hasExactFrequency6;

  static bool _exactSet(List<String> actual, List<String> expected) {
    if (actual.length != expected.length) return false;
    final a = actual.toSet();
    if (a.length != actual.length) return false;
    return a.containsAll(expected);
  }
}

class CanonicalProfileRepairOutcome {
  const CanonicalProfileRepairOutcome({
    required this.ok,
    required this.code,
    this.message,
    this.check,
  });

  final bool ok;
  final CanonicalProfileRepairCode code;
  final String? message;
  final CanonicalProfileCheckResult? check;
}

/// Verifies and safely repairs missing canonical profile fragments from
/// versioned `users/{uid}/assessments/{iq|eq}` documents — never scalars.
class CanonicalAssessmentProfileReconciler {
  CanonicalAssessmentProfileReconciler({
    CanonicalAssessmentPersistence? persistence,
  }) : _persistence = persistence ?? CanonicalAssessmentPersistence();

  final CanonicalAssessmentPersistence _persistence;

  /// Inspect `canonical_v1` measured dimensions for exact registry sets.
  Future<CanonicalProfileCheckResult> inspectProfile({
    required String ownerUid,
  }) async {
    if (ownerUid.trim().isEmpty) {
      return const CanonicalProfileCheckResult(
        ok: false,
        code: CanonicalProfileRepairCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final profile = await _persistence.getCanonicalProfile(uid: ownerUid);
    return inspectProfileMap(profile);
  }

  CanonicalProfileCheckResult inspectProfileMap(Map<String, dynamic>? profile) {
    if (profile == null) {
      return const CanonicalProfileCheckResult(
        ok: false,
        code: CanonicalProfileRepairCode.iq4Incomplete,
        message: 'canonical_v1 missing',
      );
    }
    final iq = <String>[];
    final eq = <String>[];
    final freq = <String>[];
    final rows = profile['measured_dimensions'];
    if (rows is! List) {
      return CanonicalProfileCheckResult(
        ok: false,
        code: CanonicalProfileRepairCode.iq4Incomplete,
        message: 'measured_dimensions missing',
        profile: profile,
      );
    }
    final seen = <String>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final d = QmatchProfileDimension.fromJson(
        Map<String, dynamic>.from(row),
      );
      if (d.measurementState != QmatchMeasurementState.measured) continue;
      if (d.value == null || d.value! < 0.0 || d.value! > 1.0) {
        return CanonicalProfileCheckResult(
          ok: false,
          code: CanonicalProfileRepairCode.invalidRegistrySet,
          message: 'Invalid measured value for ${d.dimensionId}',
          profile: profile,
        );
      }
      if (!seen.add(d.dimensionId)) {
        return CanonicalProfileCheckResult(
          ok: false,
          code: CanonicalProfileRepairCode.invalidRegistrySet,
          message: 'Duplicate dimension ${d.dimensionId}',
          profile: profile,
        );
      }
      if (d.module == 'iq') {
        if (!QmatchProfileTaxonomy.iq.contains(d.dimensionId)) {
          return CanonicalProfileCheckResult(
            ok: false,
            code: CanonicalProfileRepairCode.invalidRegistrySet,
            message: 'Unknown IQ dimension ${d.dimensionId}',
            profile: profile,
          );
        }
        iq.add(d.dimensionId);
      } else if (d.module == 'eq') {
        if (!QmatchProfileTaxonomy.eq.contains(d.dimensionId)) {
          return CanonicalProfileCheckResult(
            ok: false,
            code: CanonicalProfileRepairCode.invalidRegistrySet,
            message: 'Unknown EQ dimension ${d.dimensionId}',
            profile: profile,
          );
        }
        eq.add(d.dimensionId);
      } else if (d.module == 'frequency') {
        if (!QmatchProfileTaxonomy.frequency.contains(d.dimensionId)) {
          return CanonicalProfileCheckResult(
            ok: false,
            code: CanonicalProfileRepairCode.invalidRegistrySet,
            message: 'Unknown Frequency dimension ${d.dimensionId}',
            profile: profile,
          );
        }
        freq.add(d.dimensionId);
      } else {
        return CanonicalProfileCheckResult(
          ok: false,
          code: CanonicalProfileRepairCode.invalidRegistrySet,
          message: 'Unknown module ${d.module}',
          profile: profile,
        );
      }
    }
    final hasIq = CanonicalProfileCheckResult._exactSet(
      iq,
      QmatchProfileTaxonomy.iq,
    );
    return CanonicalProfileCheckResult(
      ok: hasIq,
      code: hasIq
          ? CanonicalProfileRepairCode.ok
          : CanonicalProfileRepairCode.iq4Incomplete,
      measuredIqIds: iq,
      measuredEqIds: eq,
      measuredFrequencyIds: freq,
      profile: profile,
    );
  }

  /// Reconstruct [IqCanonicalScoringResult] from `assessments/iq` only.
  /// Rejects legacy scalar-only docs.
  static IqCanonicalScoringResult? tryParseIqResultFromAssessment(
    Map<String, dynamic> doc, {
    required String ownerUid,
  }) {
    if (doc['status'] != 'completed') return null;
    final policy = doc['scoring_policy_version'] as String?;
    if (policy == null ||
        !QmatchProfileContract.acceptedIqScoringPolicies.contains(policy)) {
      return null;
    }
    // Reject scalar-only legacy: must have canonical_dimensions.
    final rows = doc['canonical_dimensions'];
    if (rows is! List ||
        rows.length != QmatchProfileContract.iqDimensionCount) {
      return null;
    }
    final bankVersion =
        doc['bank_version'] as String? ?? doc['content_version'] as String?;
    final bankLocale = doc['bank_locale'] as String?;
    final selection = doc['selection_policy_version'] as String?;
    final sessionId = doc['session_id'] as String?;
    if (bankVersion == null ||
        bankVersion.isEmpty ||
        bankLocale == null ||
        bankLocale.isEmpty ||
        selection == null ||
        selection.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty) {
      return null;
    }
    final scores = <IqDimensionScore>[];
    final seen = <String>{};
    for (final row in rows) {
      if (row is! Map) return null;
      final m = Map<String, dynamic>.from(row);
      final id = m['dimension'] as String?;
      final provisional = (m['provisional_score'] as num?)?.toDouble();
      final raw = (m['raw_accuracy'] as num?)?.toDouble() ?? provisional;
      final itemCount = m['item_count'] as int?;
      final correct = m['correct_count'] as int?;
      final incorrect = m['incorrect_count'] as int?;
      final answered = m['answered_count'] as int?;
      if (id == null ||
          provisional == null ||
          raw == null ||
          itemCount == null ||
          correct == null ||
          incorrect == null ||
          answered == null) {
        return null;
      }
      if (!QmatchProfileTaxonomy.iq.contains(id)) return null;
      if (!seen.add(id)) return null;
      if (provisional < 0.0 || provisional > 1.0) return null;
      scores.add(
        IqDimensionScore(
          dimension: id,
          correctCount: correct,
          incorrectCount: incorrect,
          answeredCount: answered,
          itemCount: itemCount,
          rawAccuracy: raw,
          provisionalScore: provisional,
          calibrationStatus: IqCalibrationStatus.fromWire(
            m['calibration_status'] as String?,
          ),
        ),
      );
    }
    if (!CanonicalProfileCheckResult._exactSet(
      scores.map((e) => e.dimension).toList(),
      QmatchProfileTaxonomy.iq,
    )) {
      return null;
    }
    // Taxonomy order.
    final byId = {for (final s in scores) s.dimension: s};
    final ordered = [
      for (final id in QmatchProfileTaxonomy.iq) byId[id]!,
    ];
    final flagsRaw = doc['structural_flags'];
    final flags = flagsRaw is Map
        ? IqScoringStructuralFlags.fromJson(
            Map<String, dynamic>.from(flagsRaw),
          )
        : const IqScoringStructuralFlags(
            completeSession: true,
            quotaValid: true,
            canonicalBankValid: true,
          );
    final answeredCount = doc['answered_count'] as int? ??
        ordered.fold<int>(0, (a, b) => a + b.answeredCount);
    return IqCanonicalScoringResult(
      schemaVersion: IqScoringContract.schemaVersion,
      bankVersion: bankVersion,
      bankLocale: bankLocale,
      selectionPolicyVersion: selection,
      scoringPolicyVersion: policy,
      sessionId: sessionId,
      dimensionScores: ordered,
      totalAnswered: answeredCount,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      calibrationStatus: IqCalibrationStatus.fromWire(
        doc['calibration_status'] as String?,
      ),
      structuralFlags: flags,
    );
  }

  /// Reconstruct [EqCanonicalScoringResult] from `assessments/eq`.
  static EqCanonicalScoringResult? tryParseEqResultFromAssessment(
    Map<String, dynamic> doc,
  ) {
    if (doc['status'] != 'completed') return null;
    final policy = doc['scoring_policy_version'] as String?;
    if (policy == null ||
        !QmatchProfileContract.acceptedEqScoringPolicies.contains(policy)) {
      return null;
    }
    final rows = doc['canonical_dimensions'];
    if (rows is! List ||
        rows.length != QmatchProfileContract.eqDimensionCount) {
      return null;
    }
    final bankVersion = doc['bank_version'] as String?;
    final bankLocale = doc['bank_locale'] as String?;
    if (bankVersion == null ||
        bankVersion.isEmpty ||
        bankLocale == null ||
        bankLocale.isEmpty) {
      return null;
    }
    final scores = <EqDimensionScore>[];
    final seen = <String>{};
    for (final row in rows) {
      if (row is! Map) return null;
      final m = Map<String, dynamic>.from(row);
      final id = m['dimension_id'] as String?;
      final evidence = m['evidence_status'] as String?;
      final evidenceCount = m['evidence_count'] as int?;
      final normalized = (m['normalized_score'] as num?)?.toDouble();
      final raw = (m['raw_signed_evidence'] as num?)?.toDouble();
      if (id == null ||
          evidence == null ||
          evidenceCount == null ||
          normalized == null) {
        return null;
      }
      if (!QmatchProfileTaxonomy.eq.contains(id)) return null;
      if (!seen.add(id)) return null;
      if (evidence != EqDimensionEvidenceStatus.measured.wireValue) return null;
      if (normalized < 0.0 || normalized > 1.0) return null;
      scores.add(
        EqDimensionScore(
          dimensionId: id,
          evidenceStatus: EqDimensionEvidenceStatus.measured,
          evidenceCount: evidenceCount,
          rawSignedEvidence: raw,
          normalizedScore: normalized,
          calibrationStatus: EqCalibrationStatus.uncalibrated,
          reliabilityStatus: EqReliabilityStatus.notCalibrated,
        ),
      );
    }
    if (!CanonicalProfileCheckResult._exactSet(
      scores.map((e) => e.dimensionId).toList(),
      QmatchProfileTaxonomy.eq,
    )) {
      return null;
    }
    final byId = {for (final s in scores) s.dimensionId: s};
    final ordered = [
      for (final id in QmatchProfileTaxonomy.eq) byId[id]!,
    ];
    final flagsRaw = doc['structural_flags'];
    final flags = flagsRaw is Map
        ? EqScoringStructuralFlags(
            completeSession: flagsRaw['complete_session'] as bool? ?? true,
            canonicalBankValid:
                flagsRaw['canonical_bank_valid'] as bool? ?? true,
            allDimensionsMeasured:
                flagsRaw['all_dimensions_measured'] as bool? ?? true,
          )
        : const EqScoringStructuralFlags(
            completeSession: true,
            canonicalBankValid: true,
            allDimensionsMeasured: true,
          );
    return EqCanonicalScoringResult(
      schemaVersion: EqScoringContract.schemaVersion,
      bankVersion: bankVersion,
      bankLocale: bankLocale,
      scoringPolicyVersion: policy,
      dimensionScores: ordered,
      totalAnswered: doc['answered_count'] as int? ?? 30,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      calibrationStatus: EqCalibrationStatus.uncalibrated,
      reliabilityStatus: EqReliabilityStatus.notCalibrated,
      rviRuntimeGate: (doc['response_validity'] is Map
              ? (doc['response_validity'] as Map)['rvi_runtime_gate']
              : null) as String? ??
          EqScoringContract.rviRuntimeGate,
      structuralFlags: flags,
    );
  }

  List<QmatchProfileDimension> measuredOfModule(
    Map<String, dynamic>? profile,
    String module,
  ) {
    if (profile == null) return const [];
    final rows = profile['measured_dimensions'];
    if (rows is! List) return const [];
    final out = <QmatchProfileDimension>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final d = QmatchProfileDimension.fromJson(
        Map<String, dynamic>.from(row),
      );
      if (d.module == module &&
          d.measurementState == QmatchMeasurementState.measured &&
          d.value != null) {
        out.add(d);
      }
    }
    return out;
  }

  /// Ensure exact IQ4 on canonical_v1 using assessments/iq (never scalars).
  Future<CanonicalProfileRepairOutcome> ensureIq4({
    required String ownerUid,
    IqCanonicalScoringResult? fromLocalScoredResult,
  }) async {
    if (ownerUid.trim().isEmpty) {
      return const CanonicalProfileRepairOutcome(
        ok: false,
        code: CanonicalProfileRepairCode.ownerUnavailable,
      );
    }
    final existing = await inspectProfile(ownerUid: ownerUid);
    if (existing.hasExactIq4) {
      return CanonicalProfileRepairOutcome(
        ok: true,
        code: CanonicalProfileRepairCode.ok,
        check: existing,
      );
    }

    IqCanonicalScoringResult? result = fromLocalScoredResult;
    if (result == null) {
      final iqDoc = await _persistence.getAssessment('iq', uid: ownerUid);
      if (iqDoc == null) {
        return const CanonicalProfileRepairOutcome(
          ok: false,
          code: CanonicalProfileRepairCode.iqAssessmentMissing,
          message: 'Canonical IQ assessment missing',
        );
      }
      // Explicitly reject scalar-only legacy.
      if (iqDoc.containsKey('iq_score') &&
          iqDoc['canonical_dimensions'] == null &&
          iqDoc['dimension_scores'] is! Map) {
        return const CanonicalProfileRepairOutcome(
          ok: false,
          code: CanonicalProfileRepairCode.iqAssessmentInsufficient,
          message: 'Legacy scalar IQ cannot reconstruct IQ4',
        );
      }
      result = tryParseIqResultFromAssessment(iqDoc, ownerUid: ownerUid);
      if (result == null) {
        return const CanonicalProfileRepairOutcome(
          ok: false,
          code: CanonicalProfileRepairCode.iqAssessmentInsufficient,
          message: 'Canonical IQ assessment insufficient for IQ4',
        );
      }
    }

    final adapted = const IqTo20dRuntimeAdapter().adapt(
      result: result,
      ownerUid: ownerUid,
    );
    if (!adapted.ok || adapted.fragment == null) {
      return CanonicalProfileRepairOutcome(
        ok: false,
        code: CanonicalProfileRepairCode.adaptFailed,
        message: adapted.message ?? 'IQ→20D adapt failed',
      );
    }
    try {
      await _persistence.upsertCanonicalProfileFragment(adapted.fragment!);
    } catch (e) {
      return CanonicalProfileRepairOutcome(
        ok: false,
        code: CanonicalProfileRepairCode.persistFailed,
        message: e.toString(),
      );
    }
    final after = await inspectProfile(ownerUid: ownerUid);
    if (!after.hasExactIq4) {
      return CanonicalProfileRepairOutcome(
        ok: false,
        code: CanonicalProfileRepairCode.iq4Incomplete,
        message: 'IQ4 still incomplete after repair',
        check: after,
      );
    }
    return CanonicalProfileRepairOutcome(
      ok: true,
      code: CanonicalProfileRepairCode.ok,
      check: after,
    );
  }

  /// Ensure IQ4 + EQ10 (14/20) for Frequency precondition.
  Future<CanonicalProfileRepairOutcome> ensureIq4AndEq10({
    required String ownerUid,
    EqCanonicalScoringResult? fromLocalEqResult,
    String? eqSessionId,
  }) async {
    final iqRepair = await ensureIq4(ownerUid: ownerUid);
    if (!iqRepair.ok) return iqRepair;

    final afterIq = iqRepair.check ?? await inspectProfile(ownerUid: ownerUid);
    if (afterIq.hasExactEq10) {
      return CanonicalProfileRepairOutcome(
        ok: true,
        code: CanonicalProfileRepairCode.ok,
        check: afterIq,
      );
    }

    EqCanonicalScoringResult? eqResult = fromLocalEqResult;
    String? sessionId = eqSessionId;
    if (eqResult == null) {
      final eqDoc = await _persistence.getAssessment('eq', uid: ownerUid);
      if (eqDoc == null) {
        return const CanonicalProfileRepairOutcome(
          ok: false,
          code: CanonicalProfileRepairCode.eqAssessmentMissing,
          message: 'Canonical EQ assessment missing',
        );
      }
      eqResult = tryParseEqResultFromAssessment(eqDoc);
      sessionId ??= eqDoc['session_id'] as String?;
      if (eqResult == null || sessionId == null || sessionId.isEmpty) {
        return const CanonicalProfileRepairOutcome(
          ok: false,
          code: CanonicalProfileRepairCode.eqAssessmentInsufficient,
          message: 'Canonical EQ assessment insufficient for EQ10',
        );
      }
    }
    sessionId ??= 'repaired_eq_session';

    final profile = await _persistence.getCanonicalProfile(uid: ownerUid);
    final existingIq = measuredOfModule(profile, 'iq');
    final adapted = const EqTo20dRuntimeAdapter().adapt(
      result: eqResult,
      ownerUid: ownerUid,
      sessionId: sessionId,
      existingIqDimensions: existingIq,
    );
    if (!adapted.ok || adapted.fragment == null) {
      return CanonicalProfileRepairOutcome(
        ok: false,
        code: CanonicalProfileRepairCode.adaptFailed,
        message: adapted.message ?? 'EQ→20D adapt failed',
      );
    }
    try {
      await _persistence.upsertCanonicalProfileFragment(adapted.fragment!);
    } catch (e) {
      return CanonicalProfileRepairOutcome(
        ok: false,
        code: CanonicalProfileRepairCode.persistFailed,
        message: e.toString(),
      );
    }
    final after = await inspectProfile(ownerUid: ownerUid);
    if (!after.hasExact14) {
      return CanonicalProfileRepairOutcome(
        ok: false,
        code: CanonicalProfileRepairCode.eq10Incomplete,
        message: '14/20 still incomplete after EQ repair',
        check: after,
      );
    }
    return CanonicalProfileRepairOutcome(
      ok: true,
      code: CanonicalProfileRepairCode.ok,
      check: after,
    );
  }
}
