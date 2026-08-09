# QMatch Current State

**Authority:** This file + the repository code are the source of truth for
project continuity across ChatGPT/Cursor sessions. Conversation transcripts are
supporting context only when they conflict with the current repository.

---

## Repository Checkpoint

| Field | Value |
|-------|-------|
| Branch | `main` |
| Last completed implementation phase | **P2C-2A-5 — Canonical IQ Runtime Integration** |
| Implementation commit (P2C-2A-5) |  |
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
| **IQ** | Canonical 25-session + 4D uncalibrated scorer | Legacy 10-item path retired from **new** sessions |
| **EQ** | Unchanged live EQ path | Not modified in P2C-2A-5 |
| **Frequency** | Unchanged live Frequency path | Not modified in P2C-2A-5 |

---

## Canonical IQ Status

| Capability | Status |
|------------|--------|
| Canonical bank | **IMPLEMENTED** (340 / `tr_v2_340`) |
| Composer | **IMPLEMENTED** |
| Persistence / resume | **IMPLEMENTED** |
| Canonical 4D scorer | **IMPLEMENTED** |
| Live IQ runtime integration | **IMPLEMENTED** |
| Legacy 10-item new-session path | **RETIRED_FROM_ACTIVE_NEW_SESSION_PATH** |
| Psychometric calibration | **NOT_STARTED** |
| 20D adapter | **NOT_STARTED** |
| Cloud session sync | **NOT_STARTED / DEFERRED** |

---

## Live IQ Path (current)

```
IQTestIntro → IQTestScreen (IqCanonicalRuntimeService)
  → UID-scoped SharedPreferences session
  → 25 items / displayedOptionIds / selectedOptionId
  → IqCanonicalScorer
  → users/{uid}/assessments/iq (qmatch_iq_live_result_v1)
  → markIqCompleted(rawScore: null)
  → IqReasoningProfileScreen
  → IqToEqTransition → EQ
```

Scientific label remains: **uncalibrated multidimensional reasoning performance**.
No standardized IQ / percentile.

Locale: bank content is `tr-TR`. UI chrome follows app l10n. Mid-session UI
locale changes do not regenerate the session.

---

## Result persistence

See `docs/assessment/qmatch_iq_live_result_persistence_v1.md`.

Versioned canonical payload in `users/{uid}/assessments/iq`. Legacy scalar
`iq_score` is **not** written for new canonical completions.

---

## Frozen / Do Not Accidentally Modify

- Composer / scoring policy versions without a dedicated phase
- EQ / Frequency / TraitScoring / Core Method / Discover ranking
- Fabricating IQ numbers or calibration
- 20D adapter (next dedicated phase)
- Broad deletion of legacy 10-set assets (cleanup debt only)

---

## Current GitHub Checkpoints

| Phase | Commit |
|-------|--------|
| P2C-2A-3 durable resume | `30d5cdb56953bfd32c4d1705e83d69b48477deca` |
| P2C-2A-4 4D scoring | `149276fe5c876e9d76500e2fa297ce769aba89be` |
| Continuity tip before P2C-2A-5 | `697462c3a2159bf047ebf1a9d9c9622a1961c89a` |
| P2C-2A-5 runtime integration |  |

---

## Current Validation State

| Check | Result |
|-------|--------|
| `dart format` (changed Dart) | clean |
| `flutter analyze` | No issues found |
| dedicated IQ suites (runtime/persistence/scoring/bank/composer/pilot) | PASS |
| `flutter test` (full) | **855** passed |
| `git diff --check` | clean |
| pilot pubspec guard | allows canonical `iq_bank_tr_v1`; rejects pilot assets |

---

## Current Release Readiness

**IQ assessment: NOT scientifically RELEASE READY**

Live canonical path is wired, but content remains desk-reviewed candidate /
uncalibrated. No population IQ interpretation.

---

## Next Exact Phase

**P2C-2A-6 — IQ → 20D Runtime Adapter**

Wire the four uncalibrated IQ dimension provisional scores into the future
20-dimensional profile **without** inventing IQ percentiles or calibration.

Do not implement in this checkpoint.

---

## Open Blockers / Risks

1. Psychometric calibration not started.
2. 20D adapter not started.
3. EN bank content not available (TR bank used for question text).
4. Legacy 10-set asset cleanup debt remains.
5. Historical `iq_score` mirrors may be absent for new completions.

---

## Continuity Rule

**This file must be updated at the completion of every future QMatch
implementation phase.**

Repository code + this file are the authoritative project state.
