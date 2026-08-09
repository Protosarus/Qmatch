# QMatch Current State

**Authority:** This file + the repository code are the source of truth for
project continuity across ChatGPT/Cursor sessions. Conversation transcripts are
supporting context only when they conflict with the current repository.

---

## Repository Checkpoint

| Field | Value |
|-------|-------|
| Branch | `main` |
| Last completed recovery phase | **P2C-2A-7R1 — Canonical EQ 10D math + runtime-candidate banks** |
| Live EQ migration phase | **P2C-2A-7 = BLOCKED_PENDING_RUNTIME_INTEGRATION** |
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
| **EQ** | Legacy keyed 10-item path | Offline canonical scorer + TR/EN candidates ready; **not live** |
| **Frequency** | Unchanged live Frequency path | Not started for canonical profile |

---

## Canonical profile status

| Capability | Status |
|------------|--------|
| IQ bank TR/EN + live runtime + 4D scorer | **IMPLEMENTED** |
| IQ → `qmatch_canonical_profile_v1` | **IMPLEMENTED** |
| Measured dimensions | **4 / 20** |
| IQ group | **COMPLETE** |
| EQ taxonomy | **FROZEN** |
| EQ scorer (`eq_10d_uncalibrated_signed_evidence_v1`) | **IMPLEMENTED_OFFLINE** |
| TR/EN EQ runtime candidates | **CREATED / VALIDATED** (uncalibrated) |
| EQ live runtime | **NOT_YET_MIGRATED** |
| EQ → 20D | **NOT_YET_WIRED** |
| EQ group | **NOT_STARTED** (live) |
| Frequency group | **NOT_STARTED** |
| `canonical_profile_ready` | **false** |
| Persona / Matching / Quantum | **NOT_STARTED** |
| Psychometric calibration | **NOT_STARTED** |

---

## P2C-2A-7 / R1 status

```text
P2C-2A-7 = BLOCKED_PENDING_RUNTIME_INTEGRATION
P2C-2A-7R1 = COMPLETE
```

R1 artifacts:

* `docs/assessment/qmatch_eq_10d_scoring_math_v1.md`
* `docs/assessment/qmatch_eq_runtime_candidate_bank_audit_v1.md`
* `docs/assessment/qmatch_eq_bank_tr_en_parity_v1.md`
* `assets/data/assessment_v3/eq/eq_bank_tr_v1.json`
* `assets/data/assessment_v3/eq/eq_bank_en_v1.json`
* `lib/features/assessment/domain/eq_bank/`
* `lib/features/assessment/domain/eq_scoring/`

Live migration remains blocked until an explicit runtime-integration phase reviews
EN semantic quality, wires session persistence, retires keyed EQ for new sessions,
and merges via Eq→20D **without** inventing calibration.

---

## Exact canonical EQ dimension IDs

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
| P2C-2A-7 BLOCKED audit | `e04f251be30146ccb7d1871a6af45b19783fe8be` |
| Continuity tip before R1 | `bb19fad14ecb4ba49f26dca041dc3022d98332ac` |
| P2C-2A-7R1 EQ 10D math + banks | `705a532011933ca78a5885480a240eb84b937122` |

---

## Next Exact Phase

Do **not** auto-start live EQ migration.

Likely next: **P2C-2A-7R2 / P2C-2A-7 resume** — runtime integration only after review of
R1 banks + session contract (still no fabricated calibration / Persona / matching).

---

## Open Blockers / Risks

1. Live EQ still keyed / noncanonical.
2. EN EQ translations are structural candidates — semantic review required.
3. EQ→20D not wired; measured dims remain 4/20.
4. Frequency canonical profile not started.
5. Persona/matching must not consume incomplete profiles.

---

## Continuity Rule

**This file must be updated at the completion of every future QMatch
implementation phase.**

Repository code + this file are the authoritative project state.
