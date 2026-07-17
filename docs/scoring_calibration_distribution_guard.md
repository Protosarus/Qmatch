# Scoring Calibration & Distribution Guard (Phases 3R-A1 → 3R-A2)

**Dates:** 2026-07-18 (A1 audit), 2026-07-18 (A2 cold-start compatibility)
**Mode:** A1 diagnostic; A2 implements Discover compatibility guard only
**Constraints:** No assessment JSON edits · no IQ/EQ/Frequency scoring output changes · no archetype ID / result label changes · no fake percentiles · no commit/push · no assessment-content Firestore writes

**Tooling:** Code review + `scripts/simulate_scoring_distribution.py` (bundled assets only)

---

## Executive summary

Qmatch scores **IQ and EQ as binary “correct answer” counts** (10 questions each → 11 discrete normalized values), maps them into a **3×3 H/M/L grid (HH…LL)**, and scores **Frequency as a 6-dimension Likert mean** (often ~50 under neutral/random answering).

**Phase 3R-A2** changed Discover **compatibility ranking only**: Frequency **6D vector** is now the primary cold-start signal; IQ/EQ use **H/M/L bands** (not raw closeness); archetype weight dropped; missing data uses a **below-midpoint neutral (0.42)** instead of a free 0.5 match. Assessment scoring and JSON are unchanged.

| Layer | Midpoint / compression pattern |
|-------|--------------------------------|
| IQ (effortful / mixed answering) | Strong pull into **40–60 (M band)** |
| EQ (socially desirable answering) | Pull into **high** scores → **MH/HH** archetype dominance |
| Frequency | **Strong midpoint attractor** (~50) + **Balanced Frequency** type (~65% random) |
| Compatibility (post-A2) | Vector-first when present; bands + lower archetype weight reduce discrete-score / HH…LL dominance |

**Verdict:** Do **not** invent percentiles. Keep raw scores; cold-start uses rule bands + Frequency vectors. Percentile calibration waits for real-user N.

---

## 1. Current scoring map

### 1.1 IQ

| Item | Current behavior |
|------|------------------|
| Source | Assigned set from `iq_sets.json` (50×10 MCQ) |
| Raw | Count of `selectedIndex == correctAnswer` |
| Normalized | `round(raw / 10 * 100)` → 0,10,…,100 |
| `correctAnswer` | Option index; **options shuffled** at assignment for IQ |
| Questions / user | **10** |
| Score range | Raw 0–10; normalized 0–100 |
| Archetype | Combined with EQ after EQ finishes |
| Persist | Assignment `score`; user `iq_score` / `iq_normalized` on EQ completion |

**Key code:** `iq_test_screen.dart` (`_nextQuestion`), `ArchetypeCalculator` in `archetype_model.dart`, `AuthService.updateTestCompletion`.

### 1.2 EQ

| Item | Current behavior |
|------|------------------|
| Source | Assigned set from `eq_sets.json` (50×10 MCQ) |
| Raw | Same binary correct count as IQ |
| Normalized | Same formula |
| `correctAnswer` | Option index; **no option shuffle** |
| Archetype | `iqBand + eqBand` → HH…LL name map |
| Band thresholds | H `>66`, M `34–66`, L `<34` |
| With 10Q | Raw 0–3 → L; 4–6 → M; 7–10 → H |

**Product implication:** EQ is scored like a quiz with a “best” social answer, not a multi-style preference inventory. Desirable answering inflates EQ.

### 1.3 Frequency

| Item | Current behavior |
|------|------------------|
| Source | `frequency_sets.json` (50×12 Likert) |
| Scale | 1–5; `reverseScored` → `6 - raw` |
| Normalize item | `(scored - 1) / 4` → 0..1 |
| Dimensions | depth, socialEnergy, spontaneity, stability, emotionalOpenness, conversationPace (2 items each) |
| `scoreTotal` | mean(6 dims) × 100 |
| Type | Priority cascade (Deep Connector → … → **Balanced Frequency**) |
| Tags | Thresholds ~0.70 (pace dual thresholds) |
| Persist | `assessments/frequency` + user `frequency_*` |

**Key code:** `FrequencyService.calculateResult`.

### 1.4 Compatibility / Discover — **before 3R-A2 (legacy)**

| Component | Weight | Signal used |
|-----------|-------:|-------------|
| Archetype affinity | 0.35 | Category / name match |
| Frequency | 0.20 | Tag Jaccard or type match (**vector unused**) |
| IQ closeness | 0.15 | raw `iq_normalized` closeness |
| EQ closeness | 0.15 | raw `eq_normalized` closeness |
| Interests | 0.10 | Tag Jaccard |
| Recency | 0.05 | last active |

Closeness: `1 - |a−b|`. Missing → **0.5**. Same category affinity **0.85**.

### 1.5 Compatibility / Discover — **after 3R-A2 (cold-start)**

Implemented in `lib/core/utils/compatibility_scoring.dart`. Weights are named constants (sum **1.0**):

| Constant | Weight | Signal |
|----------|-------:|--------|
| `frequencyVectorWeight` | **0.32** | 6D vector mean-abs-distance → similarity |
| `frequencyTypeTagWeight` | **0.10** | Tag Jaccard, else type (Balanced Frequency type-only = **0.48**) |
| `archetypeWeight` | **0.15** | Category / name (same category **0.70**, was 0.85) |
| `iqBandWeight` | **0.08** | H/M/L band affinity (not raw 51 vs 59) |
| `eqBandWeight` | **0.08** | H/M/L band affinity |
| `interestsWeight` | **0.15** | Interests Jaccard |
| `recencyWeight` | **0.12** | last active |

**IQ/EQ bands:** same H `>66` / M `34–66` / L `<34`. Affinity: same **0.72**, adjacent **0.52**, H↔L **0.32**.

**Frequency vector:** dimensions `depth`, `socialEnergy`, `spontaneity`, `stability`, `emotionalOpenness`, `conversationPace`. Similarity = `1 − mean(|aᵢ−bᵢ|)` on shared keys. Missing either side → `missingSignalNeutral` (**0.42**).

**User-doc mirror (additive):** on Frequency save, `frequency_vector` is written to `users/{uid}` alongside existing `frequency_*` fields so Discover can rank without N+1 assessment reads. Legacy users: hydrate **current user** vector from `assessments/frequency` when missing; candidates without mirrored vector stay at neutral (no fake dims).

**Discover cards:** still expose type/tags/score for UI; ranking uses vectors from user maps when present. No UI redesign.

Labels unchanged: exceptional ≥0.85, strong ≥0.70, good ≥0.55, potential ≥0.40, else low_signal.

#### Missing-data fallbacks (cold-start)

| Situation | Fallback | Rationale |
|-----------|----------|-----------|
| Missing Frequency vector (either side) | **0.42** | Not a free match; not zero |
| Both Frequency tags empty + no type | **0.42** | Was 0.5 — too rewarding |
| One side tags empty | **0.38** | Soft penalty |
| Both interests empty | **0.42** | Same as tags |
| Missing IQ or EQ | **0.42** band affinity | No raw invent |
| Missing archetype both sides | **0.42** | Unless identical archetype name → 0.62 |
| Same “Balanced Frequency” type only | **0.48** | Common type should not look strong |
| Missing `last_active_at` | **0.40** | Unchanged spirit |

#### Why no fake percentiles

Percentiles need a real population distribution. With N≪100, ranks would be unstable and marketing-misleading. Cold-start uses **rule bands + vectors** until calibration (see §11).

---

## 2. Distribution risks

1. **Discrete IQ/EQ ladder** — Only 11 possible normalized scores → many identical pairs → closeness often 1.0.
2. **M-band IQ under effort** — Simulation mixed IQ (p≈0.45) put **~58%** in 40–60.
3. **EQ moral-answer inflation** — Desirable EQ (p≈0.70 correct) mean **~77**, archetype **MH ~48%**.
4. **Frequency midpoint** — Neutral → **exactly 50**; random Likert mean **~49.9**, **~62%** in 40–60.
5. **Balanced Frequency collapse** — **~65%** of random responders.
6. **Empty / sparse tags** — Compatibility falls back to type or 0.5.
7. **Vector unused in matching (A1)** — Mitigated in A2 when `frequency_vector` is present.
8. **Archetype weight 35% (A1)** — Reduced to **15%** in A2.
9. **10 items noise** — Small n → unstable individual scores (still true; bands soften ranking).
10. **EQ not shuffled** — Position bias / answer learning risk.
11. **Fallback Frequency reverse keys differ** from assets if asset load fails.
12. **51 vs 59** — A2 uses bands so within-band raw gaps do not drive closeness.

---

## 3. Simulation results

Script: `scripts/simulate_scoring_distribution.py`
Inputs: bundled `iq_sets.json`, `eq_sets.json`, `frequency_sets.json` only.
N = 2000 Monte Carlo draws (seed 42).

### Deterministic extremes (set_001)

| Profile | IQ/EQ or Frequency | Outcome |
|---------|--------------------|---------|
| Always correct | 10/10 + 10/10 | HH |
| Always wrong | 0/0 | LL |
| High IQ / low EQ | 10/0 | HL |
| Low IQ / high EQ | 0/10 | LH |
| Frequency all 3 | score 50 | Balanced, no tags |
| Frequency depth+stability high | 66.7 | Deep Connector |
| Frequency social+spontaneity high | 66.7 | Social Spark |

### Monte Carlo highlights

| Scenario | Key result |
|----------|------------|
| Uniform random MCQ (p≈0.25) | Means ~25; archetypes **LL-heavy** (not mid) |
| Mixed IQ + desirable EQ | IQ mid-heavy; EQ high; **MH dominant** |
| Frequency random | Mean ~50; **Balanced Frequency 64.7%** |
| Frequency all-neutral | **Exactly 50** always |

### Limitation (stated)

EQ “secure / passive / punitive” **cannot** be inferred from JSON without option-style metadata. Simulation uses **correctAnswer vs non-correct** proxies only.

---

## 4. Is midpoint clustering likely?

**Yes — especially for Frequency and for “trying” IQ / desirable EQ users.**

- Pure guessing → **low** IQ/EQ (LL), not mid.
- Realistic effort + “good EQ answers” → **mid IQ + high EQ** → MH/HH compression.
- Frequency → **mid total score + Balanced type**.
- Discover then **overweights shared archetype**.

So the product risk is real: **profiles feel similar** even when answer patterns differ, because total score / 2-letter code / Balanced type erase vector nuance.

---

## 5. Recommended scoring / calibration architecture

### A. Raw score
Keep forever for debug / support (`iq_score`, `eq_score`, Frequency answers).

### B. Normalized 0–100
Keep, but **never use alone** for matching or identity.

### C. Percentile (post-threshold)
Per `(assessment_type, content_version, locale)` store p10/p25/p50/p75/p90.
Compare only within same version.
**Do not enable** until N ≥ ~100 (early) / ≥ ~500 (stable).

### D. Sub-dimension vectors (primary cold-start differentiator)

| Assessment | Vector direction |
|------------|------------------|
| Frequency | **Already exists** — use in matching ASAP (future phase) |
| EQ | Response-style dims (empathy, boundary, assertiveness, …) once options are tagged; stop relying only on correctAnswer |
| IQ | Reasoning family tags if/when metadata exists (verbal / quantitative / pattern) |

### E. Archetype distribution guard
Emit:
- primary category (HH…LL)
- secondary trait (e.g. top Frequency tags / EQ style)
- confidence (based on margin vs band edges)
- optional percentile band label (post-N)
- answer-style vector hash for diversity

Avoid showing only “The Realist” to a plurality of users without secondary signal.

### F. Match scoring (future)
- Similarity: IQ closeness, Frequency vector cosine / dim L1, shared interests
- Complementarity: selected EQ styles / Frequency energy pairs (product rule)
- Soft dealbreakers: hard preference ranges
- Cap single-factor dominance (archetype ≤ ~20–25% once vectors exist)

### G. Minimum data threshold
| Stage | N (per type×version×locale) |
|-------|------------------------------|
| Early experimental percentiles | ≥ 100 |
| Product-facing percentiles | ≥ 500 |
| Fine buckets / locale splits | higher |

### H. Cold-start mode (now → beta)
- Rule bands (current H/M/L) OK as **coarse** labels
- Prefer **Frequency vector** + future EQ style vector for ranking
- Broad compatibility labels
- **No fake percentiles**

---

## 6. Firestore calibration data model (proposal only — no writes)

```text
calibration_stats/{assessmentType}_{contentVersion}_{locale}
  n
  updated_at
  score_histogram          // optional coarse bins
  percentiles: { p10, p25, p50, p75, p90 }
  archetype_counts         // IQ/EQ only
  frequency_type_counts
  frequency_tag_counts
  vector_means             // Frequency dims
  schema_version
```

Rules:
- Aggregate only; no raw answers in this doc.
- Versioned by assessment set / content version.
- Read in app after threshold; ignore if `n < threshold`.

---

## 7. Implementation roadmap

| Phase | Scope |
|-------|--------|
| **3R-A2** | **Done** — Cold-start compatibility guard (vector-first, band IQ/EQ, lower archetype weight) |
| **3R-A3** | Scoring metadata / sub-dimension schema (EQ option styles; IQ families) |
| **3R-A4** | Local scoring vector output while preserving raw/normalized |
| **3R-A5** | Firestore calibration stats **design** (still no assessment-content writes) |
| **3R-A6** | Percentile calibration after real-user threshold |

---

## 8. Before Firestore assessment publish vs after beta

### Must consider **before** publish (content / scoring readiness)

- Accept that EQ `correctAnswer` quiz model **biases** desirable answering.
- Frequency vectors are used in matching when mirrored (A2); backfill / re-complete Frequency for legacy users still helpful.
- Do **not** market percentile ranks yet.
- Keep assignment versioning so future calibration can key off content version.

### Can wait **until after beta users**

- Percentile computation & UI.
- Full EQ style taxonomy rewrite (if desired).
- Live calibration aggregation jobs.
- Further weight tuning from real swipe/match outcomes.

---

## 9. Validation

```text
python3 scripts/simulate_scoring_distribution.py
python3 scripts/validate_assessment_sets.py
python3 scripts/audit_assessment_content_quality.py
flutter analyze
```

Assessment JSON and IQ/EQ/Frequency **test scoring outputs**: unchanged. Compatibility ranking: **updated (A2)**.

---

## 10. Confirmations

| Action | A1 | A2 |
|--------|----|----|
| IQ/EQ/Frequency **test scoring** changed | No | **No** |
| Assessment JSON edited | No | **No** |
| Compatibility ranking changed | No | **Yes** |
| Additive user-doc `frequency_vector` mirror | — | **Yes** (on Frequency save) |
| Fake percentiles | No | **No** |
| Assessment-content Firestore writes | No | **No** |
| Commit / push | No | **No** |
| Script | Yes | Extended with compatibility sim |
| Report | Yes | Updated (this file) |

---

## 11. What still waits for beta data

| Milestone | Revisit |
|-----------|---------|
| **N ≥ 100** completed Frequency (+ IQ/EQ) | Re-check weight balance vs swipe outcomes; measure vector vs archetype correlation; consider soft backfill of `frequency_vector` for legacy user docs |
| **N ≥ 500** | First empirical distribution for **percentile design only** (still no UI claim until stable); revisit band thresholds if population skews hard |
| Later | Percentile calibration (3R-A6); EQ multi-style scoring; CI distribution gates |

Until then: keep cold-start constants; do not invent percentiles from simulation or tiny cohorts.
