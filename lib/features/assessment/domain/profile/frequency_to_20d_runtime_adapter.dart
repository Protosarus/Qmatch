import '../frequency_bank/frequency_canonical_dimensions.dart';
import '../frequency_scoring/frequency_scoring.dart';
import 'qmatch_profile_contract.dart';
import 'qmatch_profile_models.dart';

enum FrequencyTo20dFailureCode {
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
  eqPreservationFailed,
  registryIncomplete,
}

class FrequencyTo20dAdapterOutcome {
  const FrequencyTo20dAdapterOutcome._({
    required this.ok,
    this.fragment,
    this.code,
    this.message,
  });

  const FrequencyTo20dAdapterOutcome.ok(QmatchCanonicalProfileFragment fragment)
      : this._(ok: true, fragment: fragment);

  const FrequencyTo20dAdapterOutcome.fail({
    required FrequencyTo20dFailureCode code,
    required String message,
  }) : this._(ok: false, code: code, message: message);

  final bool ok;
  final QmatchCanonicalProfileFragment? fragment;
  final FrequencyTo20dFailureCode? code;
  final String? message;
}

/// Maps canonical Frequency 6D into the 20D profile while preserving IQ+EQ.
///
/// Does not invent reliability, Persona, matching, or quantum outputs.
class FrequencyTo20dRuntimeAdapter {
  const FrequencyTo20dRuntimeAdapter();

  /// Registry-based readiness: exact 20 canonical IDs measured — not mere count.
  static bool registryComplete(Iterable<QmatchProfileDimension> measured) {
    final byId = <String, QmatchProfileDimension>{};
    for (final d in measured) {
      if (d.measurementState != QmatchMeasurementState.measured) continue;
      if (d.value == null) continue;
      byId[d.dimensionId] = d;
    }
    if (byId.length != QmatchProfileContract.requiredDimensionCount) {
      return false;
    }
    for (final id in QmatchProfileTaxonomy.all) {
      if (!byId.containsKey(id)) return false;
    }
    return true;
  }

  FrequencyTo20dAdapterOutcome adapt({
    required FrequencyCanonicalScoringResult result,
    required String ownerUid,
    required String sessionId,
    required List<QmatchProfileDimension> existingIqDimensions,
    required List<QmatchProfileDimension> existingEqDimensions,
    DateTime? clock,
  }) {
    if (ownerUid.trim().isEmpty) {
      return const FrequencyTo20dAdapterOutcome.fail(
        code: FrequencyTo20dFailureCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }

    if (result.schemaVersion.isEmpty ||
        sessionId.isEmpty ||
        result.bankVersion.isEmpty ||
        result.bankLocale.isEmpty) {
      return const FrequencyTo20dAdapterOutcome.fail(
        code: FrequencyTo20dFailureCode.malformedResult,
        message: 'Malformed canonical Frequency result metadata',
      );
    }

    if (!QmatchProfileContract.acceptedFrequencyScoringPolicies
        .contains(result.scoringPolicyVersion)) {
      return FrequencyTo20dAdapterOutcome.fail(
        code: FrequencyTo20dFailureCode.incompatibleScoringPolicy,
        message: 'Incompatible scoring policy ${result.scoringPolicyVersion}',
      );
    }

    if (result.calibrationStatus != FrequencyCalibrationStatus.uncalibrated ||
        result.reliabilityStatus != FrequencyReliabilityStatus.notCalibrated) {
      return const FrequencyTo20dAdapterOutcome.fail(
        code: FrequencyTo20dFailureCode.invalidCalibration,
        message: 'Unexpected calibration/reliability status',
      );
    }

    if (result.dimensionScores.length !=
        QmatchProfileContract.frequencyDimensionCount) {
      return FrequencyTo20dAdapterOutcome.fail(
        code: FrequencyTo20dFailureCode.unexpectedDimensionCount,
        message:
            'Expected 6 Frequency dimensions, found ${result.dimensionScores.length}',
      );
    }

    final seen = <String>{};
    final byId = <String, FrequencyDimensionScore>{};
    for (final d in result.dimensionScores) {
      if (!FrequencyCanonicalDimensions.isCanonical(d.dimensionId)) {
        return FrequencyTo20dAdapterOutcome.fail(
          code: FrequencyTo20dFailureCode.unknownDimension,
          message: 'Unknown Frequency dimension ${d.dimensionId}',
        );
      }
      if (!seen.add(d.dimensionId)) {
        return FrequencyTo20dAdapterOutcome.fail(
          code: FrequencyTo20dFailureCode.duplicateDimension,
          message: 'Duplicate Frequency dimension ${d.dimensionId}',
        );
      }
      if (d.evidenceStatus != FrequencyDimensionEvidenceStatus.measured ||
          d.normalizedScore == null) {
        return FrequencyTo20dAdapterOutcome.fail(
          code: FrequencyTo20dFailureCode.insufficientEvidence,
          message: 'Insufficient evidence for ${d.dimensionId}',
        );
      }
      final x = d.normalizedScore!;
      if (x < 0.0 || x > 1.0) {
        return FrequencyTo20dAdapterOutcome.fail(
          code: FrequencyTo20dFailureCode.outOfRange,
          message: 'Out-of-range score for ${d.dimensionId}',
        );
      }
      byId[d.dimensionId] = d;
    }

    for (final id in FrequencyCanonicalDimensions.all) {
      if (!byId.containsKey(id)) {
        return FrequencyTo20dAdapterOutcome.fail(
          code: FrequencyTo20dFailureCode.missingDimension,
          message: 'Missing Frequency dimension $id',
        );
      }
    }

    final iqById = <String, QmatchProfileDimension>{};
    for (final d in existingIqDimensions) {
      if (d.module != 'iq') continue;
      if (d.measurementState != QmatchMeasurementState.measured) continue;
      if (d.value == null) continue;
      iqById[d.dimensionId] = d;
    }
    if (iqById.length != QmatchProfileContract.iqDimensionCount) {
      return const FrequencyTo20dAdapterOutcome.fail(
        code: FrequencyTo20dFailureCode.iqPreservationFailed,
        message: 'Existing IQ measured dimensions incomplete',
      );
    }
    for (final id in QmatchProfileTaxonomy.iq) {
      if (iqById[id] == null) {
        return FrequencyTo20dAdapterOutcome.fail(
          code: FrequencyTo20dFailureCode.iqPreservationFailed,
          message: 'Missing preserved IQ dimension $id',
        );
      }
    }

    final eqById = <String, QmatchProfileDimension>{};
    for (final d in existingEqDimensions) {
      if (d.module != 'eq') continue;
      if (d.measurementState != QmatchMeasurementState.measured) continue;
      if (d.value == null) continue;
      eqById[d.dimensionId] = d;
    }
    if (eqById.length != QmatchProfileContract.eqDimensionCount) {
      return const FrequencyTo20dAdapterOutcome.fail(
        code: FrequencyTo20dFailureCode.eqPreservationFailed,
        message: 'Existing EQ measured dimensions incomplete',
      );
    }
    for (final id in QmatchProfileTaxonomy.eq) {
      if (eqById[id] == null) {
        return FrequencyTo20dAdapterOutcome.fail(
          code: FrequencyTo20dFailureCode.eqPreservationFailed,
          message: 'Missing preserved EQ dimension $id',
        );
      }
    }

    final now = (clock ?? DateTime.now()).toUtc().toIso8601String();
    final measured = <QmatchProfileDimension>[
      for (final id in QmatchProfileTaxonomy.iq) iqById[id]!,
      for (final id in QmatchProfileTaxonomy.eq) eqById[id]!,
      for (final id in FrequencyCanonicalDimensions.all)
        QmatchProfileDimension(
          dimensionId: id,
          module: 'frequency',
          measurementState: QmatchMeasurementState.measured,
          value: byId[id]!.normalizedScore,
          source: QmatchProfileContract.measurementSourceCanonicalFrequency,
          sourceVersion: result.scoringPolicyVersion,
          calibrationStatus: result.calibrationStatus.wireValue,
          reliabilityStatus:
              QmatchProfileContract.reliabilityStatusNotCalibrated,
        ),
    ];

    if (!registryComplete(measured)) {
      return const FrequencyTo20dAdapterOutcome.fail(
        code: FrequencyTo20dFailureCode.registryIncomplete,
        message: 'Registry-based 20D completeness failed',
      );
    }

    final fragment = QmatchCanonicalProfileFragment(
      schemaVersion: QmatchProfileContract.schemaVersion,
      registryVersion: QmatchProfileContract.registryVersion,
      adapterVersion: QmatchProfileContract.frequencyAdapterVersion,
      ownerUid: ownerUid,
      profileStatus: QmatchProfileStatus.complete,
      canonicalProfileReady: true,
      measuredDimensionCount: measured.length,
      requiredDimensionCount: QmatchProfileContract.requiredDimensionCount,
      iqGroupStatus: QmatchGroupCompletionStatus.complete,
      eqGroupStatus: QmatchGroupCompletionStatus.complete,
      frequencyGroupStatus: QmatchGroupCompletionStatus.complete,
      measuredDimensions: measured,
      missingDimensionIds: const [],
      missingGroups: const [],
      sourceAssessmentType: 'frequency',
      sourceScoringPolicyVersion: result.scoringPolicyVersion,
      sourceBankVersion: result.bankVersion,
      sourceBankLocale: result.bankLocale,
      sourceSessionId: sessionId,
      calibrationStatus: result.calibrationStatus.wireValue,
      updatedAtIso: now,
    );

    if (fragment.measuredDimensionCount != 20 ||
        fragment.missingDimensionIds.isNotEmpty ||
        !fragment.canonicalProfileReady) {
      return const FrequencyTo20dAdapterOutcome.fail(
        code: FrequencyTo20dFailureCode.malformedResult,
        message: 'Profile completeness invariants failed',
      );
    }

    return FrequencyTo20dAdapterOutcome.ok(fragment);
  }
}
