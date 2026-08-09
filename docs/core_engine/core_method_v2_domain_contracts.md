# Core Method v2 Domain Contracts

Phase: **P2B-0** (contracts only — no formula execution, no production wiring)

## 1. Scope

Define versioned, registry-driven, pure-Dart domain contracts for:

- canonical assessment measurements
- complete user assessment profiles
- partner dimension preferences
- relationship values and intentions
- hard constraints and soft conflict signals
- pair-comparison inputs and compatibility result shapes
- provisional offline configuration

## 2. Non-goals

This phase does **not**:

- implement structural similarity, mutual preference scoring, hard-constraint evaluation, soft penalties, or final compatibility scores
- connect Discover, matching, Firebase, screens, routing, or production assessment flows
- modify TraitScoringService scoring behavior, reverse-pair behavior, or PersonaScoringService
- treat persona as a matching input
- claim scientific validation

## 3. Current 20-dimension registry

Machine-readable SoT: `assets/data/core_method_v2/canonical_dimension_registry_v1.json`

- IQ (4): logical_reasoning, pattern_reasoning, verbal_reasoning, spatial_reasoning
- EQ (10): empathy, perspective_taking, self_awareness, emotion_regulation, emotional_openness, boundary_setting, assertiveness, conflict_approach, repair_orientation, social_awareness
- Frequency (6): depth_preference, social_energy, spontaneity, stability, disclosure_pace, communication_pace

**20 is the current registry size, not a mathematical limit.**

## 4. Registry extensibility beyond 20

Adding dimensions requires registry/content review, not engine rewrites. Domain models iterate `registry.activeDimensions` / `registry.dimensions` and must not hardcode `dimensionCount = 20` as a behavioral dependency. A test-only 24-dimension fixture proves parse/represent extensibility without adding real canonical dimensions.

## 5. Measurement versus preference

- **Measurement** (`DimensionMeasurement`): what was observed from assessment evidence
- **Preference** (`PartnerDimensionPreference`): what a user wants in a partner on a dimension
- Preferences are never inferred from self-scores by default
- Missing preference stays unavailable; it is not imputed as 0.5 / similarity / complementarity

## 6. Compatibility versus confidence

- Compatibility scores and confidence are distinct fields
- Confidence must never be presented as compatibility
- Uncertainty is not silently assumed to equal `1 - confidence` unless a later contract explicitly defines that calculation

## 7. Missing-data policy

- Missing data remains unpublished / unavailable
- Do not fabricate numeric scores for unpublished measurements
- Missing counterpart hard-constraint data yields `unknown`, not pass/fail
- Config policy id: `leave_unpublished_never_impute_neutral`

## 8. Partner preference contract

`PartnerDimensionPreference` + `PartnerPreferenceProfile`

Modes (provisional): `range`, `similarity_to_self`, `open`, `unavailable`

Rules: min ≤ max when ranges present; importance/flexibility bounded; only registry dimensions with `supports_partner_preference`; explicit vs inferred sources remain distinguishable; preferences never auto-promote to hard constraints.

## 9. Value and intention contract

Registry: `assets/data/core_method_v2/relationship_value_registry_v1.json`

Responses: `RelationshipValueResponse` / `RelationshipValueProfile`

Sensitive fields are `directly_asked_only` and `inference_prohibited`. No UI questions are authored in this phase. Values are never inferred from IQ/EQ/Frequency, messages, or behavior.

## 10. Hard versus soft constraints

- Hard constraints require `supports_hard_constraint` + explicit user enablement
- Soft preferences/conflicts are signals only; they must not set Match = 0 or frame people as defective
- Violence/abuse/threat/harassment belong to safety/moderation systems, not normal compatibility dimensions

## 11. Pair-directionality

`CompatibilityPairInput` preserves A/B order. Symmetrical profile similarity and directional preference fit (A←B / B←A) remain separate concepts for later formula phases.

## 12. Result contract

`CompatibilityResult` can represent nullable module/overall scores, confidence separately, hard-constraint outcomes, soft conflicts, strengths/friction explanation codes, missing modules, and evaluation status (`complete`, `partial`, `insufficient_evidence`, `blocked_by_hard_constraint`, `invalid_input`). Blocked results must not fabricate overall scores. No persona IDs. No Frequency type labels. Explanation signals are structured codes, not AI prose.

## 13. Persona separation

Persona scoring remains a separate explanatory projection. Persona IDs must not appear on assessment profiles, pair inputs, or compatibility results as matching identity.

## 14. Frequency / EQ construct separation

Frequency `disclosure_pace` is not EQ `emotional_openness`. Construct separation established in Frequency pilot work remains in force.

## 15. Versioning

Registries, config, freeze manifest, and profiles carry version identifiers. Scoring contract versions and assessment content versions are recorded on measurements/profiles.

## 16. Serialization

Manual `toJson` / strict `fromJson`, sorted map keys for fingerprints, reject NaN/∞, reject out-of-range scores, preserve explicit null/missing semantics.

## 17. Security / privacy boundaries

Values carry visibility policy and comparison permission fields. Sensitive relationship data must remain directly asked. No Firebase writes in this phase. Domain layer has no Firebase dependency.

## 18. Calibration status

All Core Method v2 registries/config are **provisional / uncalibrated / offline-only**. No result produced by these contracts is scientifically validated yet.

## 19. Future formula phases

Later phases (starting with structural-profile similarity) will consume these contracts. Compatibility formulas are not implemented here.

## 20. Migration considerations

- Adapter plan from TraitScoringService → `DimensionMeasurement` exists as offline documentation-as-code only (`TraitScoringToDimensionMeasurementAdapterPlan`)
- Do not silently change production `CompatibilityScoring`, Discover, or Firestore models
- Existing WIP assessment banks remain offline and unwired
