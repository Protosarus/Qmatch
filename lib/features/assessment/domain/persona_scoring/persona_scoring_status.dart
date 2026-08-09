/// Provisional persona scoring status values (P1B-2B-2).
///
/// Never treat these as production-certified identity claims while prototypes
/// remain `synthetic_validation_only`.
enum PersonaScoringStatus {
  /// Required coverage / evidence rules failed. No publishable primary.
  insufficientEvidence,

  /// Coverage ok but top-2 margin below threshold (or exact tie).
  ambiguous,

  /// Coverage + margin ok, but prototypes/config remain provisional.
  provisional,

  /// Same mathematical readiness as provisional; explicitly shadow-only.
  validForShadowEvaluation,
}

/// Confidence levels are separate from similarity.
enum PersonaConfidenceLevel {
  insufficient,
  low,
  moderate,
  high,
}

/// Response-validity / RVI status for confidence components only.
enum ResponseValidityStatus {
  unknown,
  valid,
  suspect,
  invalid,
}
