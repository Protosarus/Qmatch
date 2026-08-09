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

enum EqPersistedSessionStatus {
  inProgress('in_progress'),
  completed('completed'),
  abandoned('abandoned');

  const EqPersistedSessionStatus(this.wireValue);
  final String wireValue;

  static EqPersistedSessionStatus fromWire(String? raw) {
    final v = raw ?? 'in_progress';
    for (final e in EqPersistedSessionStatus.values) {
      if (e.wireValue == v || e.name == v) return e;
    }
    return EqPersistedSessionStatus.inProgress;
  }
}
