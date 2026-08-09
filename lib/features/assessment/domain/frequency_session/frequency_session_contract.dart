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

/// Persisted session lifecycle.
///
/// Wire values:
/// - `in_progress` — answering still open
/// - `completed_pending_persistence` — 50 answers locked; remote finalize pending
/// - `completed` — answers + remote canonical completion finalized
/// - `abandoned`
///
/// Scientific scoring treats pending + completed as complete answer sets.
enum FrequencyPersistedSessionStatus {
  inProgress('in_progress'),
  completedPendingPersistence('completed_pending_persistence'),
  completed('completed'),
  abandoned('abandoned');

  const FrequencyPersistedSessionStatus(this.wireValue);
  final String wireValue;

  /// Answers may still be written.
  bool get isAnswerEditable =>
      this == FrequencyPersistedSessionStatus.inProgress;

  /// Canonical scorer may run (50-answer set locked).
  bool get isScoreable =>
      this == FrequencyPersistedSessionStatus.completed ||
      this == FrequencyPersistedSessionStatus.completedPendingPersistence;

  /// Keep UID active pointer so restart can resume answering or finalization.
  bool get keepsActivePointer =>
      this == FrequencyPersistedSessionStatus.inProgress ||
      this == FrequencyPersistedSessionStatus.completedPendingPersistence;

  static FrequencyPersistedSessionStatus fromWire(String? raw) {
    final v = raw ?? 'in_progress';
    for (final e in FrequencyPersistedSessionStatus.values) {
      if (e.wireValue == v || e.name == v) return e;
    }
    return FrequencyPersistedSessionStatus.inProgress;
  }
}
