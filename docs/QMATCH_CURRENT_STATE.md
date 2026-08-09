# QMatch Current State

**Authority:** This file + the repository code are the source of truth for
project continuity across ChatGPT/Cursor sessions.

---

## Repository Checkpoint

| Field | Value |
|-------|-------|
| Branch | `main` |
| Last completed phase | **P2C-2A-8R2 — Live Canonical Frequency Runtime + Frequency→20D** |
| Continuity document | `docs/QMATCH_CURRENT_STATE.md` |
| Checkpoint date | 2026-08-09 |

---

## Status

```text
P2C-2A-8R1A = COMPLETE
P2C-2A-8R1 = COMPLETE
P2C-2A-8R2 = COMPLETE
P2C-2A-8 = COMPLETE

Canonical IQ = COMPLETE (4)
Canonical EQ = COMPLETE (10)
Canonical Frequency = COMPLETE (6)

measured profile = 20 / 20
missing dimensions = 0
profile_status = complete
canonical_profile_ready = true

Frequency scoring policy = frequency_6d_uncalibrated_signed_evidence_v1
Frequency session policy = frequency_50_full_bank_deterministic_v1
Frequency live result schema = qmatch_frequency_6d_live_result_v1
Frequency→20D adapter = frequency_to_20d_runtime_adapter_v1

Psychometric calibration = NOT_STARTED
RVI runtime = NOT_ACTIVE
Canonical Persona runtime = NOT_STARTED
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

---

## GitHub Checkpoints

| Phase | Commit |
|-------|--------|
| P2C-2A-8R1A Frequency banks complete | `6424956e726107d580d0f002623db8de864fdcff` |
| Continuity tip before Frequency R2 | `2366ac37fc2124391011d751288edc9cc64e6dbc` |

---

## Next Exact Phase

**Persona canonical runtime** (or product-prioritized next phase).

Do **not** auto-start Persona / Matching / quantum from Frequency completion.

---

## Continuity Rule

Update this file at the end of every implementation phase.
