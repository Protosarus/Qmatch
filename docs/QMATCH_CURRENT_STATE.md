# QMatch Current State

**Authority:** This file + the repository code are the source of truth for
project continuity across ChatGPT/Cursor sessions. Conversation transcripts are
supporting context only when they conflict with the current repository.

---

## Repository Checkpoint

| Field | Value |
|-------|-------|
| Branch | `main` |
| Last completed implementation phase | **P2C-2A-6 — IQ → 20D Runtime Adapter** |
| Last attempted phase | **P2C-2A-7 — Canonical EQ Migration** |
| P2C-2A-7 status | **BLOCKED** (audit only; no false COMPLETE) |
| Continuity document | `docs/QMATCH_CURRENT_STATE.md` |
| Checkpoint date | 2026-08-09 |

Live tip: run `git rev-parse HEAD` / `git rev-parse origin/main` — they must match before starting a phase.

---

## Current Product Direction

QMatch is an existing personality- and frequency-based social matching product.
Users complete assessment modules (IQ, EQ, Frequency), build profiles, and use
Discover/matching surfaces.

---

## Canonical Assessment Architecture

| Module | Live (user-facing) | Notes |
|--------|---------------------|-------|
| **IQ** | Canonical 25-session + 4D + profile adapter | Live wired |
| **EQ** | Legacy keyed 10-item path | Canonical migration **BLOCKED** — see audit |
| **Frequency** | Unchanged live Frequency path | Not started for canonical profile |

---

## Canonical profile status

| Capability | Status |
|------------|--------|
| IQ bank TR/EN + live runtime + 4D scorer | **IMPLEMENTED** |
| IQ → `qmatch_canonical_profile_v1` | **IMPLEMENTED** |
| Measured dimensions | **4 / 20** |
| IQ group | **COMPLETE** |
| EQ group | **NOT_STARTED** (live noncanonical) |
| Frequency group | **NOT_STARTED** |
| `canonical_profile_ready` | **false** |
| Canonical EQ runtime | **BLOCKED / NOT_STARTED** |
| Persona / Matching / Quantum | **NOT_STARTED** |
| Psychometric calibration | **NOT_STARTED** |

---

## P2C-2A-7 blocker summary

Audit: `docs/assessment/qmatch_eq_canonical_migration_audit_v1.md`

| Code | Meaning |
|------|---------|
| `BLOCKED_LEGACY_EQ_CANNOT_MAP_TO_CANONICAL_10D` | Live EQ is `correctAnswer` totals; no evidence maps to 10 registry dims |
| `BLOCKED_CANONICAL_EQ_EN_BANK_ABSENT` | v3 pilot is TR-only; EN fields are explicit non-translations |
| `BLOCKED_CANONICAL_EQ_PILOT_NOT_RUNTIME_APPROVED` | Pilot runtime-loaded=No; expert review pending |

Canonical 10 EQ IDs **exist** in the registry. Offline TraitScoring + TR pilot exist.
They do **not** authorize inventing a live legacy→10D mapping or promoting the
unapproved pilot without EN parity.

---

## Exact canonical EQ dimension IDs (registry; not live-measured)

```
empathy
perspective_taking
self_awareness
emotion_regulation
emotional_openness
boundary_setting
assertiveness
conflict_approach
repair_orientation
social_awareness
```

---

## Current GitHub Checkpoints

| Phase | Commit |
|-------|--------|
| P2C-2A-6 IQ→20D adapter | `7ef5312f7c2e36556fbcb3c679ff083cd6f6d8ef` |
| Continuity tip before P2C-2A-7 | `35b81c05fca108b12f95266b99b0da541694f969` |
| P2C-2A-7 EQ migration BLOCKED audit | `e04f251be30146ccb7d1871a6af45b19783fe8be` |

---

## Next Exact Phase

Do **not** start Frequency / Persona / Matching.

Next work must resolve EQ blockers, likely:

**P2C-2A-7R — Canonical EQ bank readiness** (runtime-approved TR+EN schema-v3 EQ
content + live replacement of keyed path), **then** resume EQ→profile adapter.

Confirm against the EQ audit before coding.

---

## Open Blockers / Risks

1. Live EQ cannot scientifically populate canonical 10D.
2. Canonical EQ EN bank absent.
3. EQ pilot not runtime-approved.
4. Frequency canonical profile not started.
5. Persona/matching must not consume incomplete profiles.

---

## Continuity Rule

**This file must be updated at the completion of every future QMatch
implementation phase.**

Repository code + this file are the authoritative project state.
