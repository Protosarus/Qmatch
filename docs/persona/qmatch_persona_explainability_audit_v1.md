# QMatch Persona Explainability Audit v1

**Phase:** P2C-3A-3
**Mode:** READ-ONLY AUDIT
**Prototype asset:** `assets/data/persona_profiles_v2_20d.json`
**Scorer:** `persona_20d_shadow_distance_v1` (offline shadow)

```text
PERSONA_RUNTIME_READY = false
production Persona reveal = NOT_STARTED
```

---

## Finding: reason_code fields absent

Inspection of `persona_profiles_v2_20d.json` shows **no** `reason_code` (or
`reason_codes`) fields on Persona prototypes or per-dimension rules.

Shadow distance outputs primary / secondary / distances / Δ_D and scoring
metadata. They do **not** emit stable explanation tokens tied to prototype
content.

---

## Production implication

If product requires user-facing explanation (why this Persona / why this
secondary) as a mandatory reveal gate:

```text
BLOCKED_PERSONA_REASON_CODE_POLICY
```

Distance-only IDs without explanation do not satisfy a mandatory
explainability requirement. See
`qmatch_persona_distance_reveal_policy_v1.md`:

```text
DISTANCE_ONLY_REVEAL_READY_FOR_PRODUCT_REVIEW = false
```

even when:

```text
TEMPERATURE_NOT_REQUIRED_FOR_DISTANCE_ONLY_REVEAL_V1
CONFIDENCE_NOT_REQUIRED_FOR_DISTANCE_ONLY_REVEAL_V1
```

---

## What exists today (non-production)

| Artifact | Explainability content |
|----------|------------------------|
| v2 20D prototypes | targets, weights, anti-traits, min evidence, tie ranks — **no reason_code** |
| Catalog TR/EN titles | labels only |
| v2 descriptions | labels-only / legacy prose elsewhere — not a reason_code policy |
| Shadow scorer metadata | scoring/policy versions; no explanation tokens |
| CM v2 other modules | some `reason_code` patterns exist outside Persona prototypes; **not** wired as Persona reveal explanations |

---

## Status

```text
Persona explainability policy = UNRESOLVED
BLOCKED_PERSONA_REASON_CODE_POLICY = true (if explanation mandatory)
prototypes = provisional / synthetic_validation_only
live reveal = disabled
```

No reason_code taxonomy was invented in this phase.
