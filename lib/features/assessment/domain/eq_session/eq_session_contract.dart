/// Canonical EQ live session contracts (P2C-2A-7R2).
class EqSessionContract {
  EqSessionContract._();

  static const String persistedSchemaVersion = 'qmatch_eq_persisted_session_v1';
  static const String selectionPolicyVersion =
      'eq_30_full_bank_deterministic_v1';
  static const String scoringPolicyVersion =
      'eq_10d_uncalibrated_signed_evidence_v1';
  static const int sessionItemCount = 30;
}

/// Persisted session lifecycle.
///
/// Wire values:
/// - `in_progress` — answering still open
/// - `completed_pending_persistence` — 30 answers locked; remote finalize pending
/// - `completed` — answers + remote canonical completion finalized
/// - `abandoned`
///
/// Scientific scoring treats pending + completed as complete answer sets.
enum EqPersistedSessionStatus {
  inProgress('in_progress'),
  completedPendingPersistence('completed_pending_persistence'),
  completed('completed'),
  abandoned('abandoned');

  const EqPersistedSessionStatus(this.wireValue);
  final String wireValue;

  /// Answers may still be written.
  bool get isAnswerEditable => this == EqPersistedSessionStatus.inProgress;

  /// Canonical scorer may run (30-answer set locked).
  bool get isScoreable =>
      this == EqPersistedSessionStatus.completed ||
      this == EqPersistedSessionStatus.completedPendingPersistence;

  /// Keep UID active pointer so restart can resume answering or finalization.
  bool get keepsActivePointer =>
      this == EqPersistedSessionStatus.inProgress ||
      this == EqPersistedSessionStatus.completedPendingPersistence;

  static EqPersistedSessionStatus fromWire(String? raw) {
    final v = raw ?? 'in_progress';
    for (final e in EqPersistedSessionStatus.values) {
      if (e.wireValue == v || e.name == v) return e;
    }
    return EqPersistedSessionStatus.inProgress;
  }
}
