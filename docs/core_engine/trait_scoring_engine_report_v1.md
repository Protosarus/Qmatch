# Trait Scoring Engine Report v1 (P2A-2A)

**Status:** pure library implemented; **not** production-wired.  
**Calibration:** provisional / offline fixtures only.  
**Canonical formula owner:** `lib/features/assessment/domain/trait_scoring/trait_scoring_service.dart`  
**Config:** `assets/data/trait_scoring_config_v1.json` (**not** in `pubspec.yaml`)

---

## Explicit non-claims

- **No clinical validation**
- **No real psychometric calibration**
- **No user-visible persona**
- **No production question-bank use**
- **No Firebase scoring authority**
- Engine is offline / test-only in this phase

---

## Architecture

```
schema-v3 item bank + responses
        │
        ▼
TraitScoringParser (strict validation)
        │
        ▼
TraitScoringService  ◄── trait_scoring_config_v1
        │
        ▼
ModuleTraitResult (IQ | EQ | Frequency)
        │
        ▼
CanonicalProfileAssembler
        │
        ▼
PersonaScoringInput (explicit evidenceSufficiency)
        │
        ▼
PersonaScoringService  (optional; not auto-called)
```

- Pure Dart under `lib/features/assessment/domain/trait_scoring/`
- No Flutter widgets, Firebase, network, auth, navigation, or locale-dependent math
- Fixtures under `test/fixtures/trait_scoring/` (not pubspec assets)

## File responsibilities

| Path | Purpose | Runtime-loaded | User-behavior impact |
|---|---|---|---|
| `assets/data/trait_scoring_config_v1.json` | Versioned evidence/reliability/RVI requirements | No (filesystem tests/tools only) | None |
| `lib/.../trait_scoring/*.dart` | Pure engine domain | No | None |
| `test/fixtures/trait_scoring/*` | Offline schema-v3 fixtures | No | None |
| `test/trait_*.dart` / related | Contract + engine tests | No | None |

## Config contract

- Per-dimension: mins/targets for primary & total evidence, max single-item influence, independent contexts, reliability floor, readiness flags
- Sufficiency (provisional):

`E_j = min(1, primary_j / targetPrimary_j, total_j / targetTotal_j) * independenceFactor_j`

- **No global `evidenceCount / 3` denominator**
- Independence: repeated `contextIdentity` / isomorph groups use diminishing weights (`same_context_diminishing_factor`)

## IQ scoring

- Objective correctness vs `correct_option_id`
- Per-domain accuracy in [0,1]; default item weight 1
- `legacyRawScore` = total correct (separate from persona identity)
- Untagged / unanswered domains → missing (never fabricated)

## EQ / Frequency scoring

- Option `dimension_deltas` in [-1,1] with evidence strength
- `r_j = Σ(a·Δ) / Σ(a)` then `x_j = clip((r+1)/2, 0, 1)`
- Primary vs secondary counts kept separate
- Missing evidence → no published score (never 0 / 0.5 / 0.42)

## Evidence independence

- Group traces by `behavioral_isomorph_group` / semantic / reverse / question id
- First context full weight; repeats diminished
- Independent context count feeds sufficiency + reliability

## Dimension reliability

- Weighted blend of available components (evidence sufficiency, context independence, item info; semantic/reverse/timing when present)
- Missing components do not become perfect scores
- Does **not** alter trait direction

## Response Validity Index (RVI)

- Components: semantic, reverse, timing, variation, impression-risk quality, repeated-context (when supplied); person-fit deferred
- Does **not** alter trait values
- No moral labels (`liar` / `dishonest` / etc.)

## Timing / impression policies

- Timing: conservative; missing timing ≠ perfect; anomalies → reason codes
- Impression: only tagged roles; bounded risk signal; non-moral

## Module output + 20D assembly

- `ModuleTraitResult` carries versions, scores, evidence maps, reliability, RVI, readiness
- Assembler requires version compatibility, exact canonical IDs, no collisions
- Missing Frequency blocks persona-ready flag
- `toPersonaScoringInput()` sets `evidenceSufficiencyMode = explicit`

## `/3` migration (PersonaScoringService)

| Mode | Behavior |
|---|---|
| **Canonical** | `dimensionEvidenceSufficiency` + `explicit` |
| **Deprecated adapter** | `withDeprecatedGlobalEvidenceDenominator` → `min(1, ev/3)` |
| **fullEvidence** | explicit sufficiency `1.0` (not `/3`) |

Simulator: `--evidence-mode=compatibility|explicit`

## Why not production-wired

- Live banks still lack full schema-v3 domain/evidence metadata
- No clinical/psychometric validation
- Assessment screens / routing / Firestore unchanged by design

## Conditions before real bank integration

1. Author schema-v3 IQ domain tags + EQ/Frequency option evidence
2. Add config to pubspec only after review
3. Shadow evaluation against production-like sessions
4. Explicit product decision to wire TraitScoring → PersonaScoring → UI
5. Firebase write authority still separate and out of scope here

## Known limitations / provisional assumptions

- Provisional thresholds and weights
- Person-fit RVI deferred
- Fixture banks are tiny and synthetic
- Const Set `==` quirk avoided via `containsAll` in config validation
