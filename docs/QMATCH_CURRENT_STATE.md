# QMatch Current State

**Authority:** This file + the repository code are the source of truth for
project continuity across ChatGPT/Cursor sessions.

---

## Repository Checkpoint

| Field | Value |
|-------|-------|
| Branch | `main` |
| Last completed phase | **P2C-3A-2 — Canonical Persona Shadow Input Policy + Distance Engine** |
| Continuity document | `docs/QMATCH_CURRENT_STATE.md` |
| Checkpoint date | 2026-08-09 |

---

## Status

```text
P2C-3A-1 = COMPLETE
P2C-3A-2 = COMPLETE

canonical measured profile = 20 / 20
canonical_profile_ready = true

canonical 18 Persona prototypes = PROVISIONAL / STRUCTURALLY_READY
canonical Persona distance scorer = IMPLEMENTED_OFFLINE_SHADOW

scoring_version = persona_20d_shadow_distance_v1
quality_policy = persona_shadow_evidence_only_v1
group_weights = 0.15 / 0.30 / 0.55
alpha = 0.65 (provisional)
gamma_A = 0.10
gamma_Omega = 0.05

Persona input reliability policy = RESOLVED_FOR_SHADOW_ONLY (q_j = E_j)
Persona evidence sufficiency policy = RESOLVED_FOR_SHADOW_ONLY
distance coefficient conflict = RESOLVED

temperature = UNRESOLVED / NOT_REQUIRED_FOR_DISTANCE_SHADOW
Top-2 thresholds = UNRESOLVED / NOT_REQUIRED_FOR_RAW_MARGIN
confidence = NOT_CALIBRATED / NOT_COMPUTED

production Persona reveal = NOT_STARTED
live Persona persistence = NOT_STARTED
PERSONA_RUNTIME_READY = false

Matching/QRCF = NOT_STARTED
Quantum = NOT_STARTED
RVI runtime = NOT_ACTIVE
Psychometric calibration = NOT_STARTED
```

---

## Canonical Assessment Architecture

| Module | Live | Notes |
|--------|------|-------|
| **IQ** | Canonical live | |
| **EQ** | Canonical live | |
| **Frequency** | Canonical live | no Persona |
| **Persona** | Offline shadow distance only | no reveal / no Firestore |

---

## GitHub Checkpoints

| Phase | Commit |
|-------|--------|
| P2C-2A-8R2 live Frequency + Frequency→20D | `025e573c8ad3b84fb91070c4568e3b3994dc1fbd` |
| P2C-3A-1 Persona prototype contract audit | `7c7ccc4bffd816ac783b92f4f164f1225b7b3e40` |
| Continuity tip before Persona shadow | `d212d8414bfef55164cdc136b60e851206636377` |
| P2C-3A-2 Persona shadow distance engine | `dd3ebdcd99c7cc2a2d6f7781060f35a426bfcf7e` |

---

## Next Exact Phase

Persona policy completion for **production reveal readiness** (temperature /
affinity / Top-2 / confidence) **or** product-prioritized Matching — without
auto-starting reveal.

---

## Continuity Rule

Update this file at the end of every implementation phase.
