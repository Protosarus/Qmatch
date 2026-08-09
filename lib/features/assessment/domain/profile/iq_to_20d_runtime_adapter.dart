import '../iq_bank/iq_canonical_dimensions.dart';
import '../iq_scoring/iq_scoring.dart';
import 'qmatch_profile_contract.dart';
import 'qmatch_profile_models.dart';

/// Failure codes for [IqTo20dRuntimeAdapter].
enum IqTo20dFailureCode {
  ownerUnavailable,
  malformedResult,
  missingDimension,
  duplicateDimension,
  unknownDimension,
  outOfRange,
  incompatibleScoringPolicy,
  invalidCalibration,
  unexpectedDimensionCount,
}

class IqTo20dAdapterOutcome {
  const IqTo20dAdapterOutcome._({
    required this.ok,
    this.fragment,
    this.code,
    this.message,
  });

  const IqTo20dAdapterOutcome.ok(QmatchCanonicalProfileFragment fragment)
      : this._(ok: true, fragment: fragment);

  const IqTo20dAdapterOutcome.fail({
    required IqTo20dFailureCode code,
    required String message,
  }) : this._(ok: false, code: code, message: message);

  final bool ok;
  final QmatchCanonicalProfileFragment? fragment;
  final IqTo20dFailureCode? code;
  final String? message;
}

/// Maps a valid canonical IQ 4D result into the IQ portion of the 20D profile.
///
/// Does **not** invent EQ/Frequency values, reliability, percentiles, or IQ
/// scalars. Does not invoke Persona / matching / quantum layers.
class IqTo20dRuntimeAdapter {
  const IqTo20dRuntimeAdapter();

  IqTo20dAdapterOutcome adapt({
    required IqCanonicalScoringResult result,
    required String ownerUid,
    DateTime? clock,
  }) {
    if (ownerUid.trim().isEmpty) {
      return const IqTo20dAdapterOutcome.fail(
        code: IqTo20dFailureCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }

    if (result.schemaVersion.isEmpty ||
        result.sessionId.isEmpty ||
        result.bankVersion.isEmpty ||
        result.bankLocale.isEmpty) {
      return const IqTo20dAdapterOutcome.fail(
        code: IqTo20dFailureCode.malformedResult,
        message: 'Malformed canonical IQ result metadata',
      );
    }

    if (!QmatchProfileContract.acceptedIqScoringPolicies
        .contains(result.scoringPolicyVersion)) {
      return IqTo20dAdapterOutcome.fail(
        code: IqTo20dFailureCode.incompatibleScoringPolicy,
        message: 'Incompatible scoring policy ${result.scoringPolicyVersion}',
      );
    }

    if (result.calibrationStatus != IqCalibrationStatus.uncalibrated) {
      return const IqTo20dAdapterOutcome.fail(
        code: IqTo20dFailureCode.invalidCalibration,
        message: 'Unexpected calibration status',
      );
    }

    final scores = result.dimensionScores;
    if (scores.length != QmatchProfileContract.iqDimensionCount) {
      return IqTo20dAdapterOutcome.fail(
        code: IqTo20dFailureCode.unexpectedDimensionCount,
        message: 'Expected 4 IQ dimensions, found ${scores.length}',
      );
    }

    final seen = <String>{};
    final byId = <String, IqDimensionScore>{};
    for (final d in scores) {
      if (!IqCanonicalDimensions.isCanonical(d.dimension) ||
          IqCanonicalDimensions.isRetired(d.dimension)) {
        return IqTo20dAdapterOutcome.fail(
          code: IqTo20dFailureCode.unknownDimension,
          message: 'Unknown IQ dimension ${d.dimension}',
        );
      }
      if (!seen.add(d.dimension)) {
        return IqTo20dAdapterOutcome.fail(
          code: IqTo20dFailureCode.duplicateDimension,
          message: 'Duplicate IQ dimension ${d.dimension}',
        );
      }
      if (d.provisionalScore < 0.0 || d.provisionalScore > 1.0) {
        return IqTo20dAdapterOutcome.fail(
          code: IqTo20dFailureCode.outOfRange,
          message: 'Out-of-range score for ${d.dimension}',
        );
      }
      if (d.calibrationStatus != IqCalibrationStatus.uncalibrated) {
        return const IqTo20dAdapterOutcome.fail(
          code: IqTo20dFailureCode.invalidCalibration,
          message: 'Per-dimension calibration invalid',
        );
      }
      byId[d.dimension] = d;
    }

    for (final id in QmatchProfileTaxonomy.iq) {
      if (!byId.containsKey(id)) {
        return IqTo20dAdapterOutcome.fail(
          code: IqTo20dFailureCode.missingDimension,
          message: 'Missing IQ dimension $id',
        );
      }
    }

    final now = (clock ?? DateTime.now()).toUtc().toIso8601String();
    final measured = <QmatchProfileDimension>[
      for (final id in QmatchProfileTaxonomy.iq)
        QmatchProfileDimension(
          dimensionId: id,
          module: 'iq',
          measurementState: QmatchMeasurementState.measured,
          value: byId[id]!.provisionalScore,
          source: QmatchProfileContract.measurementSourceCanonicalIq,
          sourceVersion: result.scoringPolicyVersion,
          calibrationStatus: result.calibrationStatus.wireValue,
          reliabilityStatus:
              QmatchProfileContract.reliabilityStatusNotCalibrated,
        ),
    ];

    final missing = <String>[
      ...QmatchProfileTaxonomy.eq,
      ...QmatchProfileTaxonomy.frequency,
    ];

    final fragment = QmatchCanonicalProfileFragment(
      schemaVersion: QmatchProfileContract.schemaVersion,
      registryVersion: QmatchProfileContract.registryVersion,
      adapterVersion: QmatchProfileContract.adapterVersion,
      ownerUid: ownerUid,
      profileStatus: QmatchProfileStatus.partial,
      canonicalProfileReady: false,
      measuredDimensionCount: measured.length,
      requiredDimensionCount: QmatchProfileContract.requiredDimensionCount,
      iqGroupStatus: QmatchGroupCompletionStatus.complete,
      eqGroupStatus: QmatchGroupCompletionStatus.notStarted,
      frequencyGroupStatus: QmatchGroupCompletionStatus.notStarted,
      measuredDimensions: measured,
      missingDimensionIds: missing,
      missingGroups: const ['eq', 'frequency'],
      sourceAssessmentType: 'iq',
      sourceScoringPolicyVersion: result.scoringPolicyVersion,
      sourceBankVersion: result.bankVersion,
      sourceBankLocale: result.bankLocale,
      sourceSessionId: result.sessionId,
      calibrationStatus: result.calibrationStatus.wireValue,
      updatedAtIso: now,
    );

    return IqTo20dAdapterOutcome.ok(fragment);
  }
}
