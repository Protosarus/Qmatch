/// Versioned canonical QMatch multidimensional profile contracts (P2C-2A-6).
///
/// Taxonomy source: `docs/core_engine/canonical_dimension_registry_v1.md`
/// (mirrored by [CanonicalDimensions] / [PersonaDimensionIds]).
class QmatchProfileContract {
  QmatchProfileContract._();

  static const String schemaVersion = 'qmatch_canonical_profile_v1';
  static const String registryVersion = 'canonical_dimension_registry_v1';
  static const String adapterVersion = 'iq_to_20d_runtime_adapter_v1';
  static const String eqAdapterVersion = 'eq_to_20d_runtime_adapter_v1';
  static const String frequencyAdapterVersion =
      'frequency_to_20d_runtime_adapter_v1';

  static const int requiredDimensionCount = 20;
  static const int iqDimensionCount = 4;
  static const int eqDimensionCount = 10;
  static const int frequencyDimensionCount = 6;

  /// Accepted IQ scoring policies for this adapter.
  static const Set<String> acceptedIqScoringPolicies = {
    'iq_4d_uncalibrated_accuracy_v1',
  };

  static const Set<String> acceptedEqScoringPolicies = {
    'eq_10d_uncalibrated_signed_evidence_v1',
  };

  static const Set<String> acceptedFrequencyScoringPolicies = {
    'frequency_6d_uncalibrated_signed_evidence_v1',
  };

  static const String reliabilityStatusNotCalibrated = 'not_calibrated';
  static const String measurementSourceCanonicalIq = 'canonical_iq';
  static const String measurementSourceCanonicalEq = 'canonical_eq';
  static const String measurementSourceCanonicalFrequency =
      'canonical_frequency';
}

enum QmatchProfileStatus {
  partial('partial'),
  complete('complete');

  const QmatchProfileStatus(this.wireValue);
  final String wireValue;
}

enum QmatchGroupCompletionStatus {
  complete('complete'),
  incomplete('incomplete'),
  notStarted('not_started');

  const QmatchGroupCompletionStatus(this.wireValue);
  final String wireValue;
}

enum QmatchMeasurementState {
  measured('measured'),
  notMeasured('not_measured');

  const QmatchMeasurementState(this.wireValue);
  final String wireValue;
}
