# QMatch Frequency Canonical Migration Audit v1

**Phase:** P2C-2A-8R1 (read-only audit + offline math freeze)  
**Date:** 2026-08-09  
**Tip at audit:** `47458b1dc0ada4f7444ee1fb4bd15f62c1c76fc5`

**Decision:**

```text
P2C-2A-8R1 = BLOCKED

BLOCKED_FREQUENCY_SEPARATOR_ITEM_COVERAGE
BLOCKED_FREQUENCY_QUALITY_ITEM_COVERAGE

Canonical Frequency taxonomy = FROZEN (matches registry)
Canonical Frequency scoring math = FROZEN (offline scorer implemented)
TR/EN 50-item runtime-candidate banks = NOT_CREATED
Live Frequency runtime = NOT_STARTED
Measured profile = 14 / 20 (unchanged)
```

Do **not** invent separator or quality-only items to force completion.

---

## 1. Live Frequency path (unchanged in R1)

```
FrequencyIntroScreen → FrequencyTestScreen
  → FrequencyService / assessment_sets/frequency_sets.json
  → legacy dimension keys (depth, socialEnergy, …)
  → reverseScored Likert / set totals
  → Persona reveal dependency (legacy)
```

Files (not modified in R1):

- `lib/features/assessment/screens/frequency_intro_screen.dart`
- `lib/features/assessment/screens/frequency_test_screen.dart`
- `lib/features/assessment/services/frequency_service.dart`
- `assets/data/assessment_sets/frequency_sets.json`

---

## 2. LEGACY_CONTENT

| Asset | Notes |
|-------|-------|
| `frequency_sets.json` | Many 12-item sets; legacy aliases; `reverseScored`; no explicit `dimension_deltas` |
| Live Frequency screens/services | Aggregate / keyed path; not canonical 6D signed evidence |
| Historical alias docs | `depth`, `socialEnergy`, `emotionalOpenness`, `conversationPace`, etc. |

Legacy quantity does **not** imply canonical suitability.

Likert + `reverseScored` without authoritative explicit delta maps ⇒ **not** eligible for silent Likert→δ invention  
(`BLOCKED_FREQUENCY_RESPONSE_TO_DELTA_MAPPING` if promoted without maps).

---

## 3. CANONICAL_CANDIDATE_CONTENT

| Asset | Notes |
|-------|-------|
| `assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json` | 50 `scenario_mcq` items; canonical 6D IDs; explicit signed `dimension_deltas` ∈ [-1,1]; option IDs `A`–`D`; no correctness keys; no EQ cross-group deltas |
| `frequency_pilot_tr_v1_review_candidate_1.json` | Sibling review candidate; same structural limits |
| `pair_registry.behavioral_isomorph_groups` | **6 groups × 2 items = 12** related evidence items (2 per dimension) |
| Semantic / reverse pairs | Present; reverse uses `behavioral_correspondence` (do not double-invert signed deltas) |

Primary allocation in pilot (all items as primary): 9/9/8/8/8/8 — enough raw stock to **select** 5 core/non-isomorph items per dimension **if** separator + quality slots existed.

---

## 4. INCOMPATIBLE_CONTENT

| Content | Why incompatible for runtime candidate |
|---------|------------------------------------------|
| Live `frequency_sets.json` | Legacy IDs; no signed deltas; reverse Likert without δ maps |
| Pilot as-is labeled `runtime_candidate` | Missing item roles for 30/12/6/2 blueprint; `separator_targets` empty for all 50 |
| EN fields in pilot | Schema stubs: `"EN equivalent pending…"` — not authored translations |
| Trait-scoring via `correctAnswer` | Must not be used for Frequency |

---

## 5. MISSING_REQUIRED_METADATA

| Requirement | Pilot evidence |
|-------------|----------------|
| 6 forced-choice **separator** items with canonical separator metadata | **0** (`separator_targets` null/empty for all items) |
| 2 **quality-only** protocol items (no forced trait deltas) | **0** (all options carry trait deltas; RVI roles exist but still score traits) |
| Stable `item_role` tags (`core` / `behavioral_equivalence` / `separator` / `quality`) | Absent on pilot items |
| Authored EN bank with structural parity | Absent (stubs only) |
| Content version + review state for promoted runtime candidate | Pilot status = `pilot` / uncalibrated |

---

## 6. Coverage vs blueprint

| Slot | Required | Supported by existing content without invention? |
|------|---------:|--------------------------------------------------|
| Core (5×6) | 30 | **Yes** (selectable from non-isomorph pilot items) |
| Behavioral equivalence (2×6) | 12 | **Yes** (isomorph groups) |
| Separators | 6 | **No** → `BLOCKED_FREQUENCY_SEPARATOR_ITEM_COVERAGE` |
| Quality | 2 | **No** → `BLOCKED_FREQUENCY_QUALITY_ITEM_COVERAGE` |
| **Total** | **50** | **No** |

---

## 7. Offline work delivered despite bank block

* Taxonomy freeze aligned with `CanonicalDimensions.frequency`
* Policy `frequency_6d_uncalibrated_signed_evidence_v1`
* Pure `CanonicalFrequencyScorer` + math fixtures
* Bank validator contracts ready for a future 50-item candidate
* Docs: math, bank audit, TR/EN parity (blocked), gap register, current state

---

## 8. Explicit non-goals (R1)

* Live Frequency screen / navigation / Firestore writes
* Frequency → 20D adapter
* Persona / Matching / QRCF / quantum
* Inventing new questions or scientific deltas
* Activating RVI gates or reliability estimates
