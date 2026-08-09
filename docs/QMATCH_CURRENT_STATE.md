# QMatch Current State

**Authority:** This file + the repository code are the source of truth for
project continuity across ChatGPT/Cursor sessions.

---

## Repository Checkpoint

| Field | Value |
|-------|-------|
| Branch | `main` |
| Last completed phase | **P2C-2A-7R2 — Live Canonical EQ Runtime + EQ→20D** |
| Last Frequency attempt | **P2C-2A-8R1 — BLOCKED** (separator + quality coverage) |
| Continuity document | `docs/QMATCH_CURRENT_STATE.md` |
| Checkpoint date | 2026-08-09 |

---

## Status

```text
P2C-2A-7R1 = COMPLETE
P2C-2A-7R2 = COMPLETE
P2C-2A-7 = COMPLETE

P2C-2A-8R1 = BLOCKED
P2C-2A-8 = BLOCKED_PENDING_RUNTIME_INTEGRATION

Canonical IQ dimensions = 4 measured
Canonical EQ dimensions = 10 measured
Canonical Frequency dimensions = 0 measured

Canonical measured profile = 14 / 20

IQ = COMPLETE
EQ = COMPLETE
Frequency taxonomy = FROZEN
Frequency scoring math / CanonicalFrequencyScorer = IMPLEMENTED_OFFLINE
Frequency TR/EN 50-item runtime candidates = NOT_CREATED
  blockers:
    BLOCKED_FREQUENCY_SEPARATOR_ITEM_COVERAGE
    BLOCKED_FREQUENCY_QUALITY_ITEM_COVERAGE
Frequency live canonical = NOT_STARTED
Frequency → 20D adapter = NOT_WIRED

canonical_profile_ready = false
profile_status = partial

Persona canonical runtime = NOT_STARTED
Matching/QRCF runtime = NOT_STARTED
Quantum-inspired runtime = NOT_STARTED
Psychometric calibration = NOT_STARTED
```

---

## Canonical Assessment Architecture

| Module | Live | Notes |
|--------|------|-------|
| **IQ** | Canonical 25-session + 4D + profile adapter | Live |
| **EQ** | Canonical 30-session + 10D + profile merge | Live |
| **Frequency** | Legacy Frequency path | Offline 6D math ready; banks blocked; profile not started |

---

## GitHub Checkpoints

| Phase | Commit |
|-------|--------|
| P2C-2A-7R1 | `705a532011933ca78a5885480a240eb84b937122` |
| Continuity tip before R2 | `1b4ee9da01337de390dd5e749ef4113cafe163a3` |
| P2C-2A-7R2 live EQ + Eq→20D | `0698b83d016ed3b284a02b53e2b36d18df66e7b8` |
| Continuity tip before Frequency R1 | `47458b1dc0ada4f7444ee1fb4bd15f62c1c76fc5` |
| P2C-2A-8R1 Frequency math freeze (banks blocked) | `71a82ad1ee4e63f4a654eabefa168e0af0c22d8b` |

---

## Next Exact Phase

Do **not** begin live Frequency R2 until separator + quality-only item coverage exists
from scientifically compatible authored content (no invented deltas).

Do not auto-start Persona / Matching / quantum.

---

## Continuity Rule

Update this file at the end of every implementation phase.
