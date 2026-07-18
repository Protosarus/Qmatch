# Compatibility Guard Runtime QA (Phase 3R-A3)

**Date:** 2026-07-18  
**Scope:** Verify cold-start compatibility guard (3R-A2) at runtime without changing weights, assessment JSON, archetype IDs, or adding percentiles.  
**Mode:** Code-path review + `flutter test` harness (no logged-in app session available this run).  
**Constraints:** No assessment JSON edits · no weight changes · no commit/push · no assessment-content Firestore writes · no fake percentiles.

---

## Executive result

| Check | Result |
|-------|--------|
| Frequency `frequency_vector` write contract | **PASS** (code path) |
| Discover hydration (user doc / assessment fallback) | **PASS** (code path) |
| Missing-data / legacy no-crash | **PASS** (11/11 unit tests) |
| Score differentiation vs archetype-heavy legacy | **PASS** |
| No fake percentile | **PASS** |
| Live Firestore observe after Frequency complete | **SKIPPED** — no running authenticated app session (0 apps; interactive login not performed) |
| Crashes observed | **None** |
| Schema issues | **None** blocking; additive `frequency_vector` only |
| Production weights changed this phase | **No** |

---

## 1. Runtime checks performed

### 1.1 Static / code-path

| Area | Evidence |
|------|----------|
| Frequency save mirrors vector | `FrequencyService.saveFrequencyResult` writes `users/{uid}.frequency_vector: result.vector` alongside type/score/tags; assessment doc still gets `vector` via `FrequencyResult.toFirestore()` |
| 6D keys | `calculateResult` builds exactly: depth, socialEnergy, spontaneity, stability, emotionalOpenness, conversationPace (0..1) |
| Discover hydration | `DiscoverService.getCandidates` hydrates `frequency_type` / `frequency_tags` / `frequency_score` / `frequency_vector` from `assessments/frequency` when user-doc mirrors are null |
| Candidate ranking | Spreads candidate Firestore map into `calculateCompatibility` (vector used if present on user doc) |
| Percentile | Grep of `lib/`: only a “No fake percentiles” comment in `compatibility_scoring.dart` — no percentile fields, storage, or UI |

### 1.2 Automated runtime (unit)

File: `test/compatibility_guard_runtime_qa_test.dart`

```text
flutter test test/compatibility_guard_runtime_qa_test.dart
→ All tests passed! (11)
```

Covers: vector key contract, parse mirrors, both/missing vectors, legacy type-only candidate, missing IQ/EQ, empty tags/interests, differentiation vs legacy, no percentile in output.

### 1.3 Live app / Firestore

| Item | Status |
|------|--------|
| Running Flutter apps | **0** (`list_running_apps`) |
| Devices available | iPhone physical, iOS simulator, macOS, Chrome |
| Complete Frequency as debug user | **Not run** (would require interactive auth + assessment flow) |
| Observed live `users/{uid}.frequency_vector` | **Not observed this session** |

**Implication:** Write path is verified by source + model contract. A follow-up manual check after one Frequency completion should confirm the mirrored map in Firestore console.

---

## 2. Firestore fields (expected contract)

### After Frequency complete (`saveFrequencyResult`)

**`users/{uid}/assessments/frequency`** (unchanged shape; merge):

| Field | Notes |
|-------|--------|
| `completed` | bool |
| `score_total` | 0..100 |
| `vector` | map of 6 dims, 0..1 |
| `type` | Frequency type string |
| `tags` | list |
| `completed_at` / `language_used` / `locale_used` | metadata |
| `answers` | optional raw 1..5 |

**`users/{uid}`** (merge, additive):

| Field | Notes |
|-------|--------|
| `frequency_completed` | true |
| `frequency_type` | type |
| `frequency_score` | scoreTotal |
| `frequency_tags` | tags |
| `frequency_vector` | **same 6D map as `result.vector`** (A2 mirror) |
| `frequency_language_used` | language |
| `updated_at` | server timestamp |

Assessment result data is not replaced by a different schema; mirror is additive.

---

## 3. `frequency_vector` structure

```json
{
  "depth": 0.0,
  "socialEnergy": 0.0,
  "spontaneity": 0.0,
  "stability": 0.0,
  "emotionalOpenness": 0.0,
  "conversationPace": 0.0
}
```

- Values: `double`, clamped conceptually to **0..1** (Likert means).  
- Compatibility parse: `frequency_vector` **or** nested `vector`; missing/empty → `missingSignalNeutral` (**0.42**).  
- No invented dimensions.

---

## 4. Discover hydration

Order for **current user** (`meData`):

1. Read `users/{uid}`.  
2. If `frequency_type` **or** `frequency_tags` **or** `frequency_vector` is null → read `assessments/frequency`.  
3. Fill with `??=` from `type`/`tags`/`scoreTotal`/`vector` (and snake_case aliases).  

**Candidates:** no N+1 assessment reads; use user-doc fields only. Legacy candidates without `frequency_vector` → vector similarity **0.42** (neutral, not a free match).

---

## 5. Missing-data fallback behavior

| Situation | Behavior | Verified |
|-----------|----------|----------|
| Both vectors present | mean-abs-distance → similarity | test |
| Me has vector, candidate missing | vector component **0.42** | test |
| Legacy: type/tags only | vector **0.42**; type/tag path still runs | test |
| Missing IQ or EQ | band affinity **0.42** | test |
| Empty tags both sides | type/tag **0.42** | test |
| Empty interests both sides | **0.42** | test |
| Crashes | none | 11 tests |

Weights **unchanged** this phase (still A2 constants).

---

## 6. Example compatibility scores

Profiles: empty tags/interests → 0.42; `last_active_at = now` → recency **1.0**.  
Vectors: **deep** vs **social** as in the unit test.

| Scenario | Archetype | Vector sim | **Cold-start total** | Legacy (vector unused)* |
|----------|-----------|------------|---------------------:|------------------------:|
| Same MM + similar Frequency (deep×deep) | 0.70 | 1.00 | **0.765** | ~0.798 |
| Same MM + different Frequency (deep×social) | 0.70 | ~0.417 | **0.579** | ~0.798 |
| Diff HH×LL + similar Frequency (deep) | 0.42 | 1.00 | **0.659** | lower arch would still ignore vector |
| Same MM + missing vectors | 0.70 | 0.42 | **0.580** | ~0.798 (0.5 miss neutrals) |
| Me vector, candidate missing | 0.70 | 0.42 | **0.580** | n/a |

\*Legacy A1 reconstruction: `0.35×0.85 + 0.20×0.5 + 0.15×1 + 0.15×1 + 0.10×0.5 + 0.05×1 ≈ 0.798` for both similar and different Frequency — **no differentiation**.

**Cold-start delta (similar − different Frequency, same MM):** ≈ **0.186** vs legacy **0.000**.

Also: **HH×LL + similar vector (0.659) > MM×MM + dissimilar vector (0.579)** → Frequency vector can outrank shared archetype when vectors diverge.

Simulation script (`scripts/simulate_scoring_distribution.py`) shows the same qualitative pattern (weights identical; absolute totals differ slightly due to recency/interest defaults in the script).

---

## 7. Discover works?

| Layer | Status |
|-------|--------|
| Service compiles / analyze clean | Yes |
| Unit logic for ranking inputs | Yes |
| End-to-end Discover with live candidates | **Not exercised** this session (no auth session) |

No code changes required for Discover beyond existing A2 hydration.

---

## 8. Crashes / schema issues

- **Crashes:** none in unit suite.  
- **Schema:** additive `frequency_vector` on user doc only; assessment `vector` preserved.  
- **Risk:** legacy user docs without mirror until re-complete Frequency or hydrate (me only). Candidates stay neutral on vector until mirrored — **by design**.

---

## 9. No fake percentile confirmation

- No percentile computation, storage, or UI fields added.  
- Compatibility labels remain: exceptional / strong / good / potential / low_signal.  
- Doc + code explicitly defer percentiles until N thresholds (see `docs/scoring_calibration_distribution_guard.md` §11).

---

## 10. Validation closeout

```text
flutter analyze                         → No issues found
flutter test test/compatibility_guard_runtime_qa_test.dart → 11 passed
python3 scripts/validate_assessment_sets.py → PASS
python3 scripts/audit_assessment_content_quality.py → PASS WITH NOTES
python3 scripts/simulate_scoring_distribution.py → OK (compat section included)
```

Assessment JSON: **unchanged**. Weights: **unchanged**.

---

## 11. Recommended next phase

| Priority | Recommendation |
|----------|----------------|
| Manual | Complete Frequency once as debug user; confirm `users/{uid}.frequency_vector` in Firestore console (6 keys, 0..1). |
| Manual | Open Discover; confirm ranking loads without errors for mixed legacy/new candidates. |
| Optional | Soft backfill job for legacy `frequency_vector` from `assessments/frequency` (ops, not fake data). |
| **3R-A4 / later** | Sub-dimension / EQ style vectors; still **no** percentiles until N≥100 design / N≥500 product. |
| Product | Tune weights only after real swipe outcomes — not in this QA phase. |

---

## 12. Confirmations

| Action | Done? |
|--------|------|
| Assessment JSON edited | **No** |
| Scoring weights changed | **No** |
| Assessment scoring changed | **No** |
| Archetype IDs changed | **No** |
| Fake percentiles | **No** |
| Commit / push | **No** |
| QA report | **Yes** — this file |
| QA unit tests | **Yes** — `test/compatibility_guard_runtime_qa_test.dart` |
