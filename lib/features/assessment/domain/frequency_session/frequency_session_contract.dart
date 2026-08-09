/// Canonical Frequency live session contracts (P2C-2A-8R2).
class FrequencySessionContract {
  FrequencySessionContract._();

  static const String persistedSchemaVersion =
      'qmatch_frequency_persisted_session_v1';
  static const String selectionPolicyVersion =
      'frequency_50_full_bank_deterministic_v1';
  static const String scoringPolicyVersion =
      'frequency_6d_uncalibrated_signed_evidence_v1';
  static const int sessionItemCount = 50;
}

enum FrequencyPersistedSessionStatus {
  inProgress('in_progress'),
  completed('completed'),
  abandoned('abandoned');

  const FrequencyPersistedSessionStatus(this.wireValue);
  final String wireValue;

  static FrequencyPersistedSessionStatus fromWire(String? raw) {
    final v = raw ?? 'in_progress';
    for (final e in FrequencyPersistedSessionStatus.values) {
      if (e.wireValue == v || e.name == v) return e;
    }
    return FrequencyPersistedSessionStatus.inProgress;
  }
}
