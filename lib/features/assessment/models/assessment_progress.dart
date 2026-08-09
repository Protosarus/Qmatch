/// Assessment progress for flow version 2 (P1B-2A).
///
/// [test_completed] compatibility:
/// - **Legacy (no `assessment_flow_version`):** historically meant IQ+EQ HH…LL
///   grid finished (often before Frequency existed).
/// - **Flow v2:** set only after IQ + EQ + complete Frequency — used as a
///   legacy Discover/`discover_eligible` gate, not as the sole router.
enum AssessmentModuleStatus {
  notStarted,
  inProgress,
  completed,

  /// Frequency only: persisted `status: incomplete`.
  incomplete,
}

/// Where AuthWrapper / onboarding should send the user next.
enum AssessmentFlowDestination {
  iq,
  eq,
  frequency,
  profileSetup,
  main,
}

/// Immutable resolved progress (prefer over raw booleans alone).
class AssessmentProgressSnapshot {
  static const int flowVersionV2 = 2;

  /// User-doc `assessment_flow_version` when intentionally written; else null.
  final int? assessmentFlowVersion;

  final AssessmentModuleStatus iqStatus;
  final AssessmentModuleStatus eqStatus;
  final AssessmentModuleStatus frequencyStatus;

  /// True only when Frequency is fully complete (not `incomplete`).
  final bool frequencyCompleted;

  /// True when Frequency doc/status is explicitly incomplete.
  final bool frequencyIncomplete;

  final bool iqCompleted;
  final bool eqCompleted;

  /// IQ + EQ + Frequency all fully complete.
  final bool allAssessmentsCompleted;

  /// User-doc `assessment_flow_completed` or derived from modules.
  final bool assessmentFlowCompleted;

  /// Always false until the 18-persona engine ships.
  final bool canonicalPersonaAvailable;

  final bool profileCompleted;

  final AssessmentFlowDestination destination;

  /// Human-auditable source label, e.g. `canonical`, `assignment`, `mirror`,
  /// `legacy_test_completed`, `legacy_active_profile_grandfather`.
  final String resolutionSource;

  final String? reason;

  const AssessmentProgressSnapshot({
    required this.assessmentFlowVersion,
    required this.iqStatus,
    required this.eqStatus,
    required this.frequencyStatus,
    required this.frequencyCompleted,
    required this.frequencyIncomplete,
    required this.iqCompleted,
    required this.eqCompleted,
    required this.allAssessmentsCompleted,
    required this.assessmentFlowCompleted,
    required this.canonicalPersonaAvailable,
    required this.profileCompleted,
    required this.destination,
    required this.resolutionSource,
    this.reason,
  });

  /// Next assessment module still required (null if all assessments done).
  AssessmentFlowDestination? get nextRequiredAssessment {
    if (!iqCompleted) return AssessmentFlowDestination.iq;
    if (!eqCompleted) return AssessmentFlowDestination.eq;
    if (!frequencyCompleted) return AssessmentFlowDestination.frequency;
    return null;
  }

  bool get isFlowVersion2 => assessmentFlowVersion == flowVersionV2;
}
