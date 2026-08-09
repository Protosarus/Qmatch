# QMatch Current State

**Authority:** This file + the repository code are the source of truth for
project continuity across ChatGPT/Cursor sessions. Conversation transcripts are
supporting context only when they conflict with the current repository.

---

## Repository Checkpoint

| Field | Value |
|-------|-------|
| Branch | `main` |
| Last completed implementation phase | **P2C-2A-4 — Canonical 4D IQ Scoring** |
| Implementation commit (P2C-2A-4) | `149276fe5c876e9d76500e2fa297ce769aba89be` |
| Verified at P2C-2A-4: local HEAD == `origin/main` | `149276fe5c876e9d76500e2fa297ce769aba89be` |
| Continuity document | `docs/QMATCH_CURRENT_STATE.md` (this file; tip may advance on docs-only updates) |
| Checkpoint date | 2026-08-09 |

Live tip: run `git rev-parse HEAD` / `git rev-parse origin/main` — they must match before starting a phase.

---

## Current Product Direction

QMatch is an existing personality- and frequency-based social matching product.
Users complete assessment modules (IQ, EQ, Frequency), build profiles, and use
Discover/matching surfaces. This checkpoint does **not** redesign the product;
it records engineering truth for the assessment stack and related offline work.

---

## Canonical Assessment Architecture

| Module | Live (user-facing) | Canonical / offline |
|--------|---------------------|---------------------|
| **IQ** | Legacy 10-item assigned set + list-index correct-count | 340-item bank, 25-session composer, local resume, 4D uncalibrated scorer — **not wired** |
| **EQ** | Live EQ test path (unchanged by P2C-2A IQ work) | Separate offline review assets may exist; not part of this IQ checkpoint |
| **Frequency** | Live Frequency path (unchanged) | Offline review candidates may exist; not part of this IQ checkpoint |

**Rule:** Treat offline canonical IQ packages under
`lib/features/assessment/domain/iq_*` as **IMPLEMENTED_OFFLINE** until an
explicit runtime integration phase wires them into `IQTestScreen`.

---

## Canonical IQ Status

| Capability | Status |
|------------|--------|
| Canonical bank | **IMPLEMENTED_OFFLINE** |
| Bank size | **340** items (`tr_v2_340`, locale `tr-TR`) |
| Bank distribution | logical_reasoning **100**, pattern_reasoning **80**, verbal_reasoning **80**, spatial_reasoning **80** |
| Canonical session size | **25** questions |
| Session quota | logical **7**, pattern **6**, verbal **6**, spatial **6** |
| Composer | **IMPLEMENTED_OFFLINE** (`iq_session_selection_v1`) |
| Persistence / resume | **IMPLEMENTED_OFFLINE** (UID-scoped SharedPreferences) |
| Canonical 4D scorer | **IMPLEMENTED_OFFLINE** (`iq_4d_uncalibrated_accuracy_v1`) |
| Psychometric calibration | **NOT_STARTED** |
| 20D adapter | **NOT_STARTED** |
| Live IQ runtime integration | **NOT_STARTED** |
| Cloud session sync | **NOT_STARTED / DEFERRED** |

Key paths (offline):

- Bank: `assets/data/assessment_v3/iq/iq_bank_tr_v1.json`
- Composer: `lib/features/assessment/domain/iq_session/`
- Persistence: `IqSessionManager` + `IqSessionPrefsRepository`
- Scoring: `lib/features/assessment/domain/iq_scoring/`

---

## IQ Session Persistence Contract

Summarized from P2C-2A-3 (`qmatch_iq_persisted_session_v1`):

- **Stable session ID:** `iq_sess_` + 32 hex; generated once on create; reused on resume.
- **UID isolation:** keys `qmatch.iq_session.v1.active.{uid}` / `.session.{uid}.{sessionId}`; no global fallback; empty owner → unavailable.
- **Exact resume:** same seed, 25 item IDs, item order, family IDs, displayed option IDs — **no recompose** when a valid in-progress draft exists.
- **Answer persistence:** `selected_option_id` (stable source IDs); one answer per item; write-through.
- **Current-question persistence:** index `0..24`; invalid indexes rejected.
- **App-kill / relaunch:** durable local store; fresh process instances resume identically (verified offline).
- **Corruption:** typed failures (`corrupt`, etc.); **no** auto-delete on read; **no** silent repair.
- **Bank / policy incompatibility:** `incompatibleBank` / `incompatiblePolicy` / `incompatibleSchema`; **no** silent regeneration.
- **Logout:** Auth sign-out does not currently clear prefs; isolation is by UID key.

---

## Canonical IQ Scoring Contract

| Field | Value |
|-------|-------|
| Scoring policy | `iq_4d_uncalibrated_accuracy_v1` |
| Dimensions | logical_reasoning, pattern_reasoning, verbal_reasoning, spatial_reasoning |
| Formula | `rawAccuracy = correctCount / itemCount`; `provisionalScore = rawAccuracy` |
| Range | `[0.0, 1.0]` |
| Calibration status | `uncalibrated` |
| Correctness identity | `selectedOptionId == canonical correct_option_id` |

**Explicitly not produced:**

- standardized IQ / overall IQ number
- IQ percentile / population norms
- IRT theta / empirical difficulty / discrimination
- fabricated reliability or confidence numbers

Structural flags (`complete_session`, `quota_valid`, `canonical_bank_valid`) are
**not** psychometric confidence.

Scientific label: **uncalibrated multidimensional reasoning performance**.

---

## Current Legacy Live IQ Path

User-facing IQ remains **legacy** (audit: `qmatch_iq_scoring_audit_v1.md`):

```
iq_test_intro_screen
  → IQTestScreen._loadQuestions
    → QuestionService.loadIQAssessment
      → AssessmentSetService.getOrAssignSet(type: 'iq')
    → QuestionModel MCQ UI (10 items)
    → correct-count via list index (_selectedAnswer == correctAnswer)
    → CanonicalAssessmentPersistence (raw_score / empty dimension_scores)
    → AssessmentProgressService.markIqCompleted (iq_score mirror)
```

| Fact | Value |
|------|-------|
| Questions shown | **10** |
| Scoring | list-index correct-count |
| Persistence | `raw_score` / `iq_score`; empty `dimension_scores` |
| Canonical composer / session / scorer in `IQTestScreen` | **NOT wired** |

Field name `iq_score` is colloquial; the live value is a **raw correct count**, not a calibrated IQ.

---

## Frozen / Do Not Accidentally Modify

Until a dedicated phase explicitly owns the change:

- Canonical 340-item bank content and bank version contract
- Composer selection policy (`iq_session_selection_v1`) and 7/6/6/6 quotas
- Persistence / exact-resume semantics and schema version
- Scoring policy (`iq_4d_uncalibrated_accuracy_v1`) and option-ID correctness
- Legacy live IQ flow **until controlled runtime migration**
- EQ and Frequency during IQ runtime migration
- `TraitScoringService` (offline; not live-wired)
- Core Method / compatibility / Discover ranking engines
- Firestore schemas unless a dedicated migration phase requires change

Do not invent standardized IQ numbers or silently delete legacy paths before
canonical runtime is validated.

---

## Current Known Scientific Boundaries

- The 340-item bank is **not** empirically psychometrically calibrated.
- Canonical scores are **multidimensional reasoning performance**, not population IQ.
- No population-relative / norm-referenced interpretation is authorized.
- Empirical calibration (difficulty, discrimination, reliability, optional norming)
  remains future work per `docs/assessment/qmatch_iq_calibration_plan_v1.md`.

---

## Current GitHub Checkpoints

| Phase | Subject | Commit |
|-------|---------|--------|
| P2C-2A-2 | Deterministic 25-question IQ composer | `126bb4592a434c45a626ed9e5e637cc447c0db67` |
| P2C-2A-3 | Durable IQ session resume | `30d5cdb56953bfd32c4d1705e83d69b48477deca` |
| P2C-2A-4 | Canonical 4D IQ scoring | `149276fe5c876e9d76500e2fa297ce769aba89be` |

---

## Current Validation State

Verified at P2C-2A-4 completion (`149276f`):

| Check | Result |
|-------|--------|
| Canonical scoring tests | PASS |
| Composer tests | PASS |
| Persistence / resume tests | PASS |
| Option-shuffle invariance | PASS |
| Item-order invariance | PASS |
| Bank immutability | PASS |
| `flutter analyze` | PASS |
| `flutter test` | PASS (**+844**) |
| Secret scan | clean |
| Local / remote HEAD | matched |

These results validate the **offline** bank / composer / persistence / scorer
stack. They do **not** validate future live runtime integration.

---

## Current Release Readiness

**IQ assessment: NOT RELEASE READY**

Reason: the canonical system is still offline; the live screen uses the legacy
10-question / correct-count path. Calibration and 20D adapter are not started.

---

## Next Exact Phase

**P2C-2A-5 — Canonical IQ Runtime Integration**

High-level goal only (not implemented in this checkpoint):

Replace/bypass the legacy 10-question user-facing IQ execution path with the
canonical 25-question composed/resumable session and canonical 4D scorer, while
preserving controlled rollback and avoiding changes to EQ/Frequency, 20D mapping,
calibration, matching, or Core Method.

---

## Next Phase Hard Boundaries

P2C-2A-5 must **NOT**:

- invent a standardized IQ number or percentile
- implement psychometric calibration
- modify EQ
- modify Frequency
- implement the 20D adapter
- modify compatibility / matching
- modify Core Method
- perform unrelated visual redesign
- silently delete legacy code before canonical runtime is validated

---

## Open Blockers / Risks

1. Canonical runtime not wired to `IQTestScreen`.
2. Legacy 10-question path remains user-facing.
3. Canonical 4D result persistence strategy for live runtime still needs deliberate integration design (no Firestore schema introduced in P2C-2A-3/4 for this).
4. Psychometric calibration not started.
5. 20D adapter not started.

---

## Continuity Rule

**This file must be updated at the completion of every future QMatch
implementation phase.**

Each completed phase should update:

- current / last completed phase
- Git commit (local and remote HEAD)
- implementation statuses
- validation results
- known blockers
- next exact phase

**Repository code + this file are the authoritative project state.**

Historical ChatGPT/Cursor conversation transcripts are supporting context, not
the source of truth when they conflict with the current repository.
