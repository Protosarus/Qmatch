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
| Implementation commit (P2C-2A-6) | `7ef5312f7c2e36556fbcb3c679ff083cd6f6d8ef` |
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
| **IQ** | Canonical 25-session + 4D uncalibrated scorer | Live wired |
| **EQ** | Unchanged live EQ path | Not modified in P2C-2A-6 |
| **Frequency** | Unchanged live Frequency path | Not modified in P2C-2A-6 |

---

## Canonical IQ Status

| Capability | Status |
|------------|--------|
| Canonical bank TR + EN | **IMPLEMENTED** |
| Composer / resume / 4D scorer / live runtime | **IMPLEMENTED** |
| IQ → canonical profile adapter | **IMPLEMENTED** |
| Measured canonical profile dimensions | **4** |
| IQ group | **COMPLETE** |
| EQ group | **NOT_STARTED** (live EQ unchanged / noncanonical) |
| Frequency group | **NOT_STARTED** (live Frequency unchanged / noncanonical) |
| Full 20D profile | **INCOMPLETE** |
| `canonical_profile_ready` | **false** |
| Psychometric calibration | **NOT_STARTED** |
| Persona from canonical profile | **NOT_STARTED** |
| Matching / QRCF / quantum from profile | **NOT_STARTED** |

---

## Live IQ → Profile Path (current)

```
IQ completion
  → IqCanonicalScorer (4D)
  → users/{uid}/assessments/iq (qmatch_iq_live_result_v1)
  → IqTo20dRuntimeAdapter
  → users/{uid}/profiles/canonical_v1 (qmatch_canonical_profile_v1, partial)
  → IqReasoningProfileScreen
  → EQ
```

Scientific label remains: **uncalibrated multidimensional reasoning performance**.
Profile schema: `qmatch_canonical_profile_v1`. Registry:
`canonical_dimension_registry_v1`.

Missing 16 dimensions are listed as `not_measured` IDs only — never filled with
0 / 0.5 / 50.

---

## Frozen / Do Not Accidentally Modify

- IQ scoring policy / banks without a dedicated phase
- Fabricating EQ/Frequency profile values
- Persona / matching / quantum from partial IQ-only profile
- Group weights for Persona/matching

---

## Current GitHub Checkpoints

| Phase | Commit |
|-------|--------|
| P2C-2A-5 runtime integration | `8df90ec07463aaaddbc35a78aa22d7ab64087b78` |
| P2C-2A-5 locale integrity | `28a8b4e48d4dafca256554a7d2dff12959677458` |
| Continuity tip before P2C-2A-6 | `70f6ac7cbccb3d387bce0dfc14e4b1e711a991a4` |
| P2C-2A-6 IQ→20D adapter | `7ef5312f7c2e36556fbcb3c679ff083cd6f6d8ef` |

---

## Current Validation State

| Check | Result |
|-------|--------|
| `dart format` (changed Dart) | clean |
| `flutter analyze` | No issues found |
| adapter + IQ regression suites | PASS |
| `flutter test` (full) | **878** passed |
| `git diff --check` | clean |

---

## Current Release Readiness

**IQ assessment: NOT scientifically RELEASE READY**
**Canonical 20D profile: INCOMPLETE (4/20 measured)**

---

## Next Exact Phase

**P2C-2A-7 — EQ Canonical Migration** (or equivalent EQ→canonical profile phase)

Bring the 10 EQ dimensions into the same `qmatch_canonical_profile_v1`
boundary without inventing placeholders. Confirm against repository gap
register before starting.

Do not implement in this checkpoint.

---

## Open Blockers / Risks

1. EQ canonical profile contribution not started.
2. Frequency canonical profile contribution not started.
3. Psychometric IQ calibration not started.
4. Persona / matching must not consume partial IQ-only profiles.
5. Legacy 10-set cleanup debt remains.

---

## Continuity Rule

**This file must be updated at the completion of every future QMatch
implementation phase.**

Repository code + this file are the authoritative project state.
