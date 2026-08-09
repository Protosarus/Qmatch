# QMatch Persona Distance-Only Reveal Policy v1

**Phase:** P2C-3A-3
**Mode:** POLICY / NO LIVE REVEAL
**Companion stress:** `docs/persona/reports/persona_shadow_stress_v1_aggregate.json`

```text
PERSONA_RUNTIME_READY = false
DISTANCE_ONLY_REVEAL_READY_FOR_PRODUCT_REVIEW = false
production Persona reveal = NOT_STARTED
live Firestore persona writer = NOT_STARTED
Matching/QRCF via Persona = FORBIDDEN for now
```

This document records what a **distance-only** reveal candidate would mean —
primary/secondary by argmin D, plus raw Δ_D telemetry — and why it is **not**
product-ready after P2C-3A-3 stress.

---

## Waivers for distance-only candidate (policy labels)

If product later chooses a reveal that exposes only:

* primary persona_id
* secondary persona_id
* raw Δ_D (optional diagnostic; not a user-facing confidence %)

then the following are **not required** for that narrow candidate:

```text
TEMPERATURE_NOT_REQUIRED_FOR_DISTANCE_ONLY_REVEAL_V1
CONFIDENCE_NOT_REQUIRED_FOR_DISTANCE_ONLY_REVEAL_V1
```

Rationale: distance-only reveal does not apply `exp(-D/T)`, does not emit `π_p`
percentages, and does not claim calibrated confidence bands. Affinity / Top-2
product bands remain unresolved if used for UI gating copy.

These waivers **do not** authorize shipping. They only clarify that T and
confidence are not blockers for a hypothetical distance-only surface.

---

## Still blocked before product review can approve

```text
DISTANCE_ONLY_REVEAL_READY_FOR_PRODUCT_REVIEW = false
```

Gates that remain open (non-exhaustive):

| Gate | Status |
|------|--------|
| Product approval of distance-only UX (no % / no T) | OPEN |
| Explainability / reason_code policy | **BLOCKED_PERSONA_REASON_CODE_POLICY** (see explainability audit) |
| Production prototype blessing | OPEN (`provisional` / `synthetic_validation_only`) |
| Live writer + Firestore schema wiring | NOT_STARTED |
| Discover/Profile presentation contract | OPEN (legacy archetype still active) |
| Explicit non-use in Matching/QRCF ranking | must remain FORBIDDEN unless separately decided |

Stress telemetry (overall H_norm ≈ 0.92, unreachable = 0, self_center
failures = 0, midpoint magnet noted) is **not** a product pass.

---

## Explicit non-goals

* No live UI reveal in P2C-3A-3
* No Firestore `assessments/persona` writes
* No invented Top-2 / confidence thresholds
* No Ranking / Matching / QRCF consumption of Persona
