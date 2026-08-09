import '../eq_bank/eq_canonical_dimensions.dart';
import '../eq_scoring/eq_scoring.dart';
import 'qmatch_profile_contract.dart';
import 'qmatch_profile_models.dart';

enum EqTo20dFailureCode {
  ownerUnavailable,
  malformedResult,
  missingDimension,
  duplicateDimension,
  unknownDimension,
  outOfRange,
  incompatibleScoringPolicy,
  invalidCalibration,
  unexpectedDimensionCount,
  insufficientEvidence,
  iqPreservationFailed,
}

class EqTo20dAdapterOutcome {
  const EqTo20dAdapterOutcome._({
    required this.ok,
    this.fragment,
    this.code,
    this.message,
  });

  const EqTo20dAdapterOutcome.ok(QmatchCanonicalProfileFragment fragment)
      : this._(ok: true, fragment: fragment);

  const EqTo20dAdapterOutcome.fail({
    required EqTo20dFailureCode code,
    required String message,
  }) : this._(ok: false, code: code, message: message);

  final bool ok;
  final QmatchCanonicalProfileFragment? fragment;
  final EqTo20dFailureCode? code;
  final String? message;
}

/// Maps canonical EQ 10D into the 20D profile while preserving IQ dims.
///
/// Does not invent Frequency values, reliability, Persona, matching, or quantum.
class EqTo20dRuntimeAdapter {
  const EqTo20dRuntimeAdapter();

  EqTo20dAdapterOutcome adapt({
    required EqCanonicalScoringResult result,
    required String ownerUid,
    required String sessionId,
    List<QmatchProfileDimension> existingIqDimensions = const [],
    DateTime? clock,
  }) {
    if (ownerUid.trim().isEmpty) {
      return const EqTo20dAdapterOutcome.fail(
        code: EqTo20dFailureCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }

    if (result.schemaVersion.isEmpty ||
        sessionId.isEmpty ||
        result.bankVersion.isEmpty ||
        result.bankLocale.isEmpty) {
      return const EqTo20dAdapterOutcome.fail(
        code: EqTo20dFailureCode.malformedResult,
        message: 'Malformed canonical EQ result metadata',
      );
    }

    if (!QmatchProfileContract.acceptedEqScoringPolicies
        .contains(result.scoringPolicyVersion)) {
      return EqTo20dAdapterOutcome.fail(
        code: EqTo20dFailureCode.incompatibleScoringPolicy,
        message: 'Incompatible scoring policy ${result.scoringPolicyVersion}',
      );
    }

    if (result.calibrationStatus != EqCalibrationStatus.uncalibrated ||
        result.reliabilityStatus != EqReliabilityStatus.notCalibrated) {
      return const EqTo20dAdapterOutcome.fail(
        code: EqTo20dFailureCode.invalidCalibration,
        message: 'Unexpected calibration/reliability status',
      );
    }

    if (result.dimensionScores.length !=
        QmatchProfileContract.eqDimensionCount) {
      return EqTo20dAdapterOutcome.fail(
        code: EqTo20dFailureCode.unexpectedDimensionCount,
        message:
            'Expected 10 EQ dimensions, found ${result.dimensionScores.length}',
      );
    }

    final seen = <String>{};
    final byId = <String, EqDimensionScore>{};
    for (final d in result.dimensionScores) {
      if (!EqCanonicalDimensions.isCanonical(d.dimensionId)) {
        return EqTo20dAdapterOutcome.fail(
          code: EqTo20dFailureCode.unknownDimension,
          message: 'Unknown EQ dimension ${d.dimensionId}',
        );
      }
      if (!seen.add(d.dimensionId)) {
        return EqTo20dAdapterOutcome.fail(
          code: EqTo20dFailureCode.duplicateDimension,
          message: 'Duplicate EQ dimension ${d.dimensionId}',
        );
      }
      if (d.evidenceStatus != EqDimensionEvidenceStatus.measured ||
          d.normalizedScore == null) {
        return EqTo20dAdapterOutcome.fail(
          code: EqTo20dFailureCode.insufficientEvidence,
          message: 'Insufficient evidence for ${d.dimensionId}',
        );
      }
      final x = d.normalizedScore!;
      if (x < 0.0 || x > 1.0) {
        return EqTo20dAdapterOutcome.fail(
          code: EqTo20dFailureCode.outOfRange,
          message: 'Out-of-range score for ${d.dimensionId}',
        );
      }
      byId[d.dimensionId] = d;
    }

    for (final id in EqCanonicalDimensions.all) {
      if (!byId.containsKey(id)) {
        return EqTo20dAdapterOutcome.fail(
          code: EqTo20dFailureCode.missingDimension,
          message: 'Missing EQ dimension $id',
        );
      }
    }

    // Preserve IQ measured dimensions exactly (no recompute).
    final iqById = <String, QmatchProfileDimension>{};
    for (final d in existingIqDimensions) {
      if (d.module != 'iq') continue;
      if (d.measurementState != QmatchMeasurementState.measured) continue;
      if (d.value == null) continue;
      iqById[d.dimensionId] = d;
    }
    if (iqById.length != QmatchProfileContract.iqDimensionCount) {
      return const EqTo20dAdapterOutcome.fail(
        code: EqTo20dFailureCode.iqPreservationFailed,
        message: 'Existing IQ measured dimensions incomplete',
      );
    }
    for (final id in QmatchProfileTaxonomy.iq) {
      final d = iqById[id];
      if (d == null || d.value == null) {
        return EqTo20dAdapterOutcome.fail(
          code: EqTo20dFailureCode.iqPreservationFailed,
          message: 'Missing preserved IQ dimension $id',
        );
      }
    }

    final now = (clock ?? DateTime.now()).toUtc().toIso8601String();
    final measured = <QmatchProfileDimension>[
      for (final id in QmatchProfileTaxonomy.iq) iqById[id]!,
      for (final id in EqCanonicalDimensions.all)
        QmatchProfileDimension(
          dimensionId: id,
          module: 'eq',
          measurementState: QmatchMeasurementState.measured,
          value: byId[id]!.normalizedScore,
          source: QmatchProfileContract.measurementSourceCanonicalEq,
          sourceVersion: result.scoringPolicyVersion,
          calibrationStatus: result.calibrationStatus.wireValue,
          reliabilityStatus:
              QmatchProfileContract.reliabilityStatusNotCalibrated,
        ),
    ];

    final missing = List<String>.from(QmatchProfileTaxonomy.frequency);

    final fragment = QmatchCanonicalProfileFragment(
      schemaVersion: QmatchProfileContract.schemaVersion,
      registryVersion: QmatchProfileContract.registryVersion,
      adapterVersion: QmatchProfileContract.eqAdapterVersion,
      ownerUid: ownerUid,
      profileStatus: QmatchProfileStatus.partial,
      canonicalProfileReady: false,
      measuredDimensionCount: measured.length,
      requiredDimensionCount: QmatchProfileContract.requiredDimensionCount,
      iqGroupStatus: QmatchGroupCompletionStatus.complete,
      eqGroupStatus: QmatchGroupCompletionStatus.complete,
      frequencyGroupStatus: QmatchGroupCompletionStatus.incomplete,
      measuredDimensions: measured,
      missingDimensionIds: missing,
      missingGroups: const ['frequency'],
      sourceAssessmentType: 'eq',
      sourceScoringPolicyVersion: result.scoringPolicyVersion,
      sourceBankVersion: result.bankVersion,
      sourceBankLocale: result.bankLocale,
      sourceSessionId: sessionId,
      calibrationStatus: result.calibrationStatus.wireValue,
      updatedAtIso: now,
    );

    if (fragment.measuredDimensionCount != 14 ||
        fragment.missingDimensionIds.length != 6 ||
        fragment.canonicalProfileReady) {
      return const EqTo20dAdapterOutcome.fail(
        code: EqTo20dFailureCode.malformedResult,
        message: 'Profile completeness invariants failed',
      );
    }

    return EqTo20dAdapterOutcome.ok(fragment);
  }
}
