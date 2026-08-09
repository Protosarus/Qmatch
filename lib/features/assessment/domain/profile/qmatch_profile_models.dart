import '../../services/canonical_assessment_persistence.dart';
import 'qmatch_profile_contract.dart';

/// One measured or explicitly unmeasured canonical profile dimension.
///
/// Missing dimensions are listed only via completeness metadata — they are
/// **not** stored as numeric 0 / 0.5 / 50 placeholders.
class QmatchProfileDimension {
  const QmatchProfileDimension({
    required this.dimensionId,
    required this.module,
    required this.measurementState,
    required this.value,
    required this.source,
    required this.sourceVersion,
    required this.calibrationStatus,
    required this.reliabilityStatus,
  });

  final String dimensionId;
  final String module; // iq | eq | frequency
  final QmatchMeasurementState measurementState;

  /// Present only when [measurementState] == measured. Always in [0, 1].
  final double? value;

  final String? source;
  final String? sourceVersion;
  final String? calibrationStatus;

  /// Never a fabricated psychometric coefficient — e.g. `not_calibrated`.
  final String reliabilityStatus;

  Map<String, dynamic> toJson() => {
        'dimension_id': dimensionId,
        'module': module,
        'measurement_state': measurementState.wireValue,
        if (value != null) 'value': value,
        if (source != null) 'source': source,
        if (sourceVersion != null) 'source_version': sourceVersion,
        if (calibrationStatus != null) 'calibration_status': calibrationStatus,
        'reliability_status': reliabilityStatus,
      };

  factory QmatchProfileDimension.fromJson(Map<String, dynamic> json) {
    final stateWire = json['measurement_state'] as String? ?? '';
    final state = QmatchMeasurementState.values.firstWhere(
      (e) => e.wireValue == stateWire,
      orElse: () => QmatchMeasurementState.notMeasured,
    );
    return QmatchProfileDimension(
      dimensionId: json['dimension_id'] as String,
      module: json['module'] as String,
      measurementState: state,
      value: (json['value'] as num?)?.toDouble(),
      source: json['source'] as String?,
      sourceVersion: json['source_version'] as String?,
      calibrationStatus: json['calibration_status'] as String?,
      reliabilityStatus: json['reliability_status'] as String? ??
          QmatchProfileContract.reliabilityStatusNotCalibrated,
    );
  }
}

/// Partial or complete canonical profile snapshot (IQ-only → partial).
class QmatchCanonicalProfileFragment {
  const QmatchCanonicalProfileFragment({
    required this.schemaVersion,
    required this.registryVersion,
    required this.adapterVersion,
    required this.ownerUid,
    required this.profileStatus,
    required this.canonicalProfileReady,
    required this.measuredDimensionCount,
    required this.requiredDimensionCount,
    required this.iqGroupStatus,
    required this.eqGroupStatus,
    required this.frequencyGroupStatus,
    required this.measuredDimensions,
    required this.missingDimensionIds,
    required this.missingGroups,
    required this.sourceAssessmentType,
    required this.sourceScoringPolicyVersion,
    required this.sourceBankVersion,
    required this.sourceBankLocale,
    required this.sourceSessionId,
    required this.calibrationStatus,
    required this.updatedAtIso,
  });

  final String schemaVersion;
  final String registryVersion;
  final String adapterVersion;
  final String ownerUid;
  final QmatchProfileStatus profileStatus;
  final bool canonicalProfileReady;
  final int measuredDimensionCount;
  final int requiredDimensionCount;
  final QmatchGroupCompletionStatus iqGroupStatus;
  final QmatchGroupCompletionStatus eqGroupStatus;
  final QmatchGroupCompletionStatus frequencyGroupStatus;

  /// Only **measured** dimensions (no fabricated missing entries).
  final List<QmatchProfileDimension> measuredDimensions;

  final List<String> missingDimensionIds;
  final List<String> missingGroups;
  final String sourceAssessmentType;
  final String sourceScoringPolicyVersion;
  final String sourceBankVersion;
  final String sourceBankLocale;
  final String sourceSessionId;
  final String calibrationStatus;
  final String updatedAtIso;

  /// Deterministic completeness view for later phases.
  QmatchProfileCompleteness get completeness => QmatchProfileCompleteness(
        measuredDimensionIds:
            measuredDimensions.map((d) => d.dimensionId).toList()..sort(),
        missingDimensionIds: List<String>.from(missingDimensionIds)..sort(),
        iqGroupComplete: iqGroupStatus == QmatchGroupCompletionStatus.complete,
        eqGroupComplete: eqGroupStatus == QmatchGroupCompletionStatus.complete,
        frequencyGroupComplete:
            frequencyGroupStatus == QmatchGroupCompletionStatus.complete,
        full20dReady: canonicalProfileReady,
        measuredCount: measuredDimensionCount,
        requiredCount: requiredDimensionCount,
      );

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'registry_version': registryVersion,
        'adapter_version': adapterVersion,
        'owner_uid': ownerUid,
        'profile_status': profileStatus.wireValue,
        'canonical_profile_ready': canonicalProfileReady,
        'measured_dimension_count': measuredDimensionCount,
        'required_dimension_count': requiredDimensionCount,
        'iq_group_status': iqGroupStatus.wireValue,
        'eq_group_status': eqGroupStatus.wireValue,
        'frequency_group_status': frequencyGroupStatus.wireValue,
        'measured_dimensions': [
          for (final d in measuredDimensions) d.toJson(),
        ],
        'missing_dimension_ids': missingDimensionIds,
        'missing_groups': missingGroups,
        'source_assessment_type': sourceAssessmentType,
        'source_scoring_policy_version': sourceScoringPolicyVersion,
        'source_bank_version': sourceBankVersion,
        'source_bank_locale': sourceBankLocale,
        'source_session_id': sourceSessionId,
        'calibration_status': calibrationStatus,
        'updated_at': updatedAtIso,
        // Explicit: no psychometric reliability number.
        'reliability_status':
            QmatchProfileContract.reliabilityStatusNotCalibrated,
      };

  factory QmatchCanonicalProfileFragment.fromJson(Map<String, dynamic> json) {
    final measured = <QmatchProfileDimension>[
      for (final row in (json['measured_dimensions'] as List? ?? const []))
        QmatchProfileDimension.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
    return QmatchCanonicalProfileFragment(
      schemaVersion: json['schema_version'] as String,
      registryVersion: json['registry_version'] as String,
      adapterVersion: json['adapter_version'] as String,
      ownerUid: json['owner_uid'] as String,
      profileStatus: QmatchProfileStatus.values.firstWhere(
        (e) => e.wireValue == json['profile_status'],
        orElse: () => QmatchProfileStatus.partial,
      ),
      canonicalProfileReady: json['canonical_profile_ready'] == true,
      measuredDimensionCount: json['measured_dimension_count'] as int,
      requiredDimensionCount: json['required_dimension_count'] as int,
      iqGroupStatus: QmatchGroupCompletionStatus.values.firstWhere(
        (e) => e.wireValue == json['iq_group_status'],
        orElse: () => QmatchGroupCompletionStatus.incomplete,
      ),
      eqGroupStatus: QmatchGroupCompletionStatus.values.firstWhere(
        (e) => e.wireValue == json['eq_group_status'],
        orElse: () => QmatchGroupCompletionStatus.notStarted,
      ),
      frequencyGroupStatus: QmatchGroupCompletionStatus.values.firstWhere(
        (e) => e.wireValue == json['frequency_group_status'],
        orElse: () => QmatchGroupCompletionStatus.notStarted,
      ),
      measuredDimensions: measured,
      missingDimensionIds: [
        for (final e in (json['missing_dimension_ids'] as List? ?? const []))
          e.toString(),
      ],
      missingGroups: [
        for (final e in (json['missing_groups'] as List? ?? const []))
          e.toString(),
      ],
      sourceAssessmentType: json['source_assessment_type'] as String,
      sourceScoringPolicyVersion:
          json['source_scoring_policy_version'] as String,
      sourceBankVersion: json['source_bank_version'] as String,
      sourceBankLocale: json['source_bank_locale'] as String,
      sourceSessionId: json['source_session_id'] as String,
      calibrationStatus: json['calibration_status'] as String,
      updatedAtIso: json['updated_at'] as String,
    );
  }

  /// Firestore payload — omits nothing required; never includes answer keys.
  Map<String, dynamic> toFirestoreFields() => toJson();
}

/// Deterministic answers for later phases.
class QmatchProfileCompleteness {
  const QmatchProfileCompleteness({
    required this.measuredDimensionIds,
    required this.missingDimensionIds,
    required this.iqGroupComplete,
    required this.eqGroupComplete,
    required this.frequencyGroupComplete,
    required this.full20dReady,
    required this.measuredCount,
    required this.requiredCount,
  });

  final List<String> measuredDimensionIds;
  final List<String> missingDimensionIds;
  final bool iqGroupComplete;
  final bool eqGroupComplete;
  final bool frequencyGroupComplete;
  final bool full20dReady;
  final int measuredCount;
  final int requiredCount;

  /// Convenience: which registry groups are complete.
  List<String> get completeGroups => [
        if (iqGroupComplete) 'iq',
        if (eqGroupComplete) 'eq',
        if (frequencyGroupComplete) 'frequency',
      ];

  List<String> get incompleteGroups => [
        if (!iqGroupComplete) 'iq',
        if (!eqGroupComplete) 'eq',
        if (!frequencyGroupComplete) 'frequency',
      ];
}

/// Taxonomy helpers shared with persistence constants.
class QmatchProfileTaxonomy {
  QmatchProfileTaxonomy._();

  static const iq = CanonicalDimensions.iq;
  static const eq = CanonicalDimensions.eq;
  static const frequency = CanonicalDimensions.frequency;
  static const all = [...iq, ...eq, ...frequency];
}
