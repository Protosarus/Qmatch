# Persona Scoring Service Report v2 (P1B-2B-2)

**Status:** pure library implemented; **not** production-wired.  
**Calibration:** `synthetic_validation_only`  
**Canonical formula owner:** `lib/features/assessment/domain/persona_scoring/persona_scoring_service.dart`  
**Simulator:** `tool/persona_prototype_simulator.dart` delegates to the same service.

---

## Architecture

```
PersonaScoringInput
        │
        ▼
PersonaScoringService  ◄── PersonaProfileCatalog + PersonaScoringConfig
        │
        ▼
PersonaScoringResult (status, candidates, confidence, explainability)
```

- Pure Dart domain under `lib/features/assessment/domain/persona_scoring/`
- No Flutter widgets, Firebase, network, auth, or navigation
- JSON loaded from repository filesystem for tests/tools only
- v2 JSON **not** added to `pubspec.yaml` assets

## File responsibilities

| File | Role |
|---|---|
| `persona_dimension_profile.dart` | Canonical 20D IDs / groups / forbidden aliases |
| `persona_prototype.dart` | Prototype + catalog models |
| `persona_scoring_config.dart` | Config model |
| `persona_scoring_input.dart` | Input contract |
| `persona_candidate_score.dart` | Per-persona score + explainability |
| `persona_scoring_result.dart` | Result + fingerprint helper |
| `persona_scoring_status.dart` | Status / confidence / RVI enums |
| `persona_scoring_parsers.dart` | Strict parsers (no silent repair) |
| `persona_scoring_service.dart` | Canonical math |
| `persona_scoring_file_loader.dart` | Offline filesystem loader |
| `persona_scoring.dart` | Barrel export |

## Input contract

Required fields:

- `dimensionScores` (present dims only; never invent missing)
- `dimensionEvidenceCounts`
- `dimensionReliability` (default 1.0)
- `missingDimensions`
- `assessmentStatuses`
- `responseValidityStatus`
- `dimensionRegistryVersion`
- `personaProfileVersion`
- `personaScoringVersion`

Quality weight:

`q_j = reliability_j * evidenceSufficiency_j`

**Canonical (P2A-2A+):** `evidenceSufficiency_j` comes from
`PersonaScoringInput.dimensionEvidenceSufficiency` with
`evidenceSufficiencyMode = explicit`. This is produced by the pure trait
scoring engine using dimension-specific targets — **not** `evidenceCount / 3`.

**Deprecated offline adapter only:**
`PersonaScoringInput.withDeprecatedGlobalEvidenceDenominator` sets
`evidenceSufficiencyMode = deprecatedGlobalDenominator`, which reconstructs
`min(1, evidenceCount_j / 3)` for legacy synthetic simulator inputs.
Do not use this path for trait→persona handoff.

`PersonaScoringInput.fullEvidence` sets explicit sufficiency to `1.0`
(canonical path).

Missing dims are excluded from weighted sums and reduce coverage. Never filled with 0 / 0.5 / 0.42 / target / group mean.

## Output contract

- `status`: `insufficientEvidence` | `ambiguous` | `provisional` | `validForShadowEvaluation`
- primary/secondary IDs + similarities (similarity ≠ probability)
- `top2Margin`, `ambiguous`, `insufficientEvidence`
- coverage + failed evidence rules + reason codes
- confidence score/level/components (separate from similarity)
- all 18 candidates with structured explainability
- `productionValid = false` always under synthetic calibration

## Mathematical implementation

Matches P1B-2B-1 provisional formula:

1. Group level distance (IQ/EQ/Frequency separately)
2. Group shape distance (means over present `q_j` only)
3. `D_g = 0.65 * D_level + 0.35 * D_shape`
4. `D_base = 0.15*D_IQ + 0.30*D_EQ + 0.55*D_Frequency` (no partial-group renorm unless config flag)
5. `D = D_base + γA + δM`
6. `S = exp(-D / T)`

Unavailable groups contribute nothing without fabricating a claimed zero distance object (numeric effect matches prior simulator for full-evidence and IQ-optional cases).

## Missing-data policy

- Global EQ/Frequency coverage failures → `insufficientEvidence`
- IQ minimum coverage remains 0.0
- Invalid RVI → block publishable primary
- Diagnostics may still list non-publishable candidate scores

## Anti-trait policy

- Evidence-gated, bounded (`A ≤ 1`), never alone decides persona
- Exposed as `appliedAntiTraits` counter-evidence
- No moral language in engine output

## Ambiguity policy

- Coverage ok + `top2Margin < threshold` (or exact tie) → `ambiguous`
- Preserve primary + secondary + separator targets
- Confidence stays low; no random choice

## Confidence policy

Separate from similarity. Components include coverage, group coverage, critical evidence, reliability, RVI, margin, and provisional calibration marker. High confidence always carries synthetic/provisional marker while calibration is synthetic-only.

## Deterministic tie policy

`lowest_tie_break_rank_then_lexicographic_persona_id`  
Stable across map order, locale, device, and time. Exact ties remain ambiguous.

## Explainability structure

Per candidate:

- strongest supporting / counter-evidence dimensions
- applied anti-traits
- missing critical evidence
- closest competitors + separator targets
- group level/shape/combined distances

No natural-language psychological claims in this phase.

## Simulator parity

- Simulator no longer embeds a second formula (`PersonaEngine` removed)
- Seed 42 / n=200000 assignment counts **identical** to prior P1B-2B-1 run
- Normalized entropy identical: **0.9549509474754291**
- Exact recovery 1.0; near recovery 0.9988333333333334
- Fingerprint line format expanded (status/confidence/margin) → hash differs from P1B-2B-1 text hash, but dual seed-42 runs match each other exactly
- Numerical candidate similarities for full-evidence profiles match the previous engine

## Unit-test results

Focused suites:

- `test/persona_scoring_service_test.dart`
- `test/persona_scoring_determinism_test.dart`
- `test/persona_scoring_missing_data_test.dart`
- `test/persona_scoring_simulator_parity_test.dart`

All passed (plus existing v2 contract tests).

## Known limitations / provisional risks (carry forward)

- Central ambiguity rate ~95.4%
- High near-tie volume (~106k / 200k)
- Confused pairs (empat|sifaci, kararli|uygulayici, …)
- Synthetic-only prototypes; no real-user calibration
- Central-collapse gate remains **CONDITIONAL**
- Adaptive separators not implemented

## Why not production-wired

- Prototypes remain provisional hypotheses
- Uncertainty must be preserved (no forced confident labels)
- No adaptive questions yet
- No Firestore persona contract finalized for v2
- Assessment flow still ends at temporary completion screen

## Conditions before shadow integration

1. Explicit product approval for shadow-only logging (no user-facing reveal)
2. Feature flag + no Discover/matching coupling
3. Persistence schema review for non-publishable/ambiguous states
4. Real-user calibration plan for prototypes + temperature/margins
5. Adaptive separator design for near-tie pairs
6. Confirm RVI wiring and assessment status mapping

Shadow-mode integration may begin **only** as read-only offline/side-channel evaluation after those gates — still not a live reveal.
