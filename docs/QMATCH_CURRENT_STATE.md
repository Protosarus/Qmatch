# QMatch Current State

**Authority:** This file + the repository code are the source of truth for
project continuity across ChatGPT/Cursor sessions.

---

## Repository Checkpoint

| Field | Value |
|-------|-------|
| Branch | `main` |
| Last completed phase | **P2C-3A-1 — Canonical Persona Prototype + Scoring Contract Audit** |
| Continuity document | `docs/QMATCH_CURRENT_STATE.md` |
| Checkpoint date | 2026-08-09 |

---

## Status

```text
P2C-2A-8R2 = COMPLETE
P2C-2A-8 = COMPLETE
P2C-3A-1 = COMPLETE (docs/audit only)

Canonical IQ = COMPLETE (4)
Canonical EQ = COMPLETE (10)
Canonical Frequency = COMPLETE (6)

measured profile = 20 / 20
missing dimensions = 0
profile_status = complete
canonical_profile_ready = true

Canonical Persona runtime = NOT_STARTED
PERSONA_RUNTIME_READY = false

Persona structural 20D prototypes (v2) = PRESENT_PROVISIONAL
Persona group weights (canonical) = 0.15 / 0.30 / 0.55
Persona reliability policy = BLOCKED_PERSONA_RELIABILITY_POLICY
Persona minimum-evidence handoff = BLOCKED_PERSONA_MINIMUM_EVIDENCE_POLICY
Persona temperature T = BLOCKED_PERSONA_TEMPERATURE_CONFIG
Persona Top-2 thresholds = BLOCKED_PERSONA_TOP2_THRESHOLD_POLICY
Persona confidence = NOT_READY_FOR_PRODUCTION

Psychometric calibration = NOT_STARTED
RVI runtime = NOT_ACTIVE
Matching/QRCF runtime = NOT_STARTED
Quantum-inspired runtime = NOT_STARTED
```

---

## Canonical Assessment Architecture

| Module | Live | Notes |
|--------|------|-------|
| **IQ** | Canonical 25-session + 4D + profile adapter | Live |
| **EQ** | Canonical 30-session + 10D + profile merge | Live |
| **Frequency** | Canonical 50-session + 6D + Frequency→20D | Live; no Persona |
| **Persona** | Offline v2 prototypes + scoring library only | **Not** live; audit blockers open |

---

## GitHub Checkpoints

| Phase | Commit |
|-------|--------|
| P2C-2A-8R1A Frequency banks complete | `6424956e726107d580d0f002623db8de864fdcff` |
| Continuity tip before Frequency R2 | `2366ac37fc2124391011d751288edc9cc64e6dbc` |
| P2C-2A-8R2 live Frequency + Frequency→20D | `025e573c8ad3b84fb91070c4568e3b3994dc1fbd` |
| Continuity tip before Persona audit | `8e7317d2266d4c6ca7865b8012fc88e246556897` |
| P2C-3A-1 Persona prototype contract audit | `7c7ccc4bffd816ac783b92f4f164f1225b7b3e40` |

---

## Next Exact Phase

Resolve Persona **input policies** (reliability, E_j/`n_j_min` handoff, temperature, Top-2), then shadow-mode — **not** automatic production Persona reveal.

Do **not** auto-start Matching / QRCF / quantum.

---

## Continuity Rule

Update this file at the end of every implementation phase.
