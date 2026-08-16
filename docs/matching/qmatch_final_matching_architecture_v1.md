# QMatch Final Matching Architecture v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_final_matching_architecture_v1` |
| Policy id | `final_matching_architecture_v1` |
| Status | `architecture_frozen_not_live` (layer boundaries); Discover L2 ranking cut over separately |
| Scope | **Architecture freeze** of layer boundaries and eligibility. Discover structural ranking is live via trusted backend L2 (`structural_l2_v1`). L3/L4 v1 are **non-ranking diagnostics**. This document does not invent fusion weights or promote L5. |
| Depends on | Structural production-candidate policy; Wave-State amplitude semantics; Quantum mixed-state policy freeze; Temporal / phase / omega contracts |
| Explicitly out of scope | Final fusion weights; single combined “match %”; Persona as Matching key; RVI; inventing missing values |

---

## 0. Purpose

Define the **final layered Matching architecture** using currently frozen work, so engineering and product share one map of:

- what may eventually enter production ranking,
- what must stay shadow / research,
- how layers compose **without** premature fusion,
- how legacy Discover migrates safely.

This document freezes **layer boundaries and eligibility**, not a weighted blend formula.

### Freeze confirmation (`architecture_frozen_not_live`)

| Rule | Frozen value |
| --- | --- |
| L1 hard eligibility | Hard pass / fail / unknown — not a soft score |
| L2 structural | Group-normalized 20D \(D_{\mathrm{structural}}\) — live Discover ranking via trusted backend `compareStageB2Structural` (`structural_l2_v1`) |
| L3 preferences / values | Discover L3 v1 = **profile** soft-preference **diagnostics** (non-ranking). CM values = **future L3 extension**, not fused in v1 |
| L4 temporal | Post-match **diagnostics** (cadence family production; circadian conditional; Class B / `phase_alignment` research shadow). **Non-ranking.** Mixed-state / multi-mode = **L5** |
| L5 mixed-state QI | Shadow only (`validated_shadow_not_live`) |
| Persona / RVI / pure-state QI | **Prohibited** as Matching keys |
| Client Dart 20D matcher | Formula replica only — `liveDiscoverRanking=false`; does **not** rank Discover |
| Legacy Discover | `CompatibilityScoring` **rollback only** (`legacy_v1`) |
| Fusion weights | **Not invented yet**; no combined shadow score |
| Rollback | `DiscoverRankingMode.legacyV1` → CompatibilityScoring |

---

## 1. Layer architecture

Matching is a **pipeline of layers**, not one score. Each layer has its own inputs, availability rules, and wire fields. Downstream layers must not silently rewrite upstream fields.

```text
┌─────────────────────────────────────────────────────────────┐
│ L1  Hard eligibility / constraints                          │
│     binary / categorical gates (pass | fail | unknown)      │
└────────────────────────────┬────────────────────────────────┘
                             │ only pairs that pass L1
┌────────────────────────────▼────────────────────────────────┐
│ L2  Structural compatibility                                │
│     group-normalized canonical 20D distance (traits/rhythm  │
│     coordinates) — live via trusted backend L2              │
└────────────────────────────┬────────────────────────────────┘
                             │ soft ranking signal (live)
┌────────────────────────────▼────────────────────────────────┐
│ L3  Preferences                                             │
│     Discover v1: profile soft-preference diagnostics        │
│     (age + interests production diagnostics; distance       │
│      evaluated, not production-promoted; non-ranking)       │
│     Future extension: CM values / directional pref-fit      │
└────────────────────────────┬────────────────────────────────┘
                             │ diagnostics only in v1 (no rank)
┌────────────────────────────▼────────────────────────────────┐
│ L4  Temporal (post-match diagnostics, non-ranking)          │
│     Production: cadence / burst / regularity / reply /      │
│     participation. Circadian Class A if TZ+gates.           │
│     Research shadow: Class B ω, periodic φ, phase_alignment │
└────────────────────────────┬────────────────────────────────┘
                             │ diagnostics only in v1 (no rank)
┌────────────────────────────▼────────────────────────────────┐
│ L5  Quantum-inspired shadow diagnostics                     │
│     mixed-state purity / fidelity / trace distance          │
│     (validated_shadow_not_live; not compatibility alone)    │
└─────────────────────────────────────────────────────────────┘

Live Discover today: trusted backend L2 (`structural_l2_v1`); client Dart matcher does not rank
Legacy CompatibilityScoring: rollback only (`legacy_v1`)
Persona / RVI / pure-state QI: prohibited as Matching keys
```

### 1.1 Layer definitions

#### L1 — Hard eligibility / constraints

**Role:** Decide whether a pair is **allowed to be considered** at all.

Examples (product-configured; not scored as similarity):

- Blocks / reports / bans / legal age gates
- Explicit seek / offer mismatches the product treats as hard (e.g. gender/orientation filters when configured as hard)
- Geographic / distance hard caps when product policy says hard
- Account / safety / verification gates

**Output:** `eligible | ineligible | unknown` (unknown must not become “eligible by default” without explicit product policy).

**Not:** a distance, a %, or a soft “compatibility” knob.

#### L2 — Structural compatibility

**Role:** Soft ranking geometry on **measured** canonical 20D coordinates.

| Item | Value |
| --- | --- |
| Signal | \(D_{\mathrm{structural}}\) from `canonical_20d_group_normalized_shadow_distance_v1` |
| Discover ranking | **Live** via trusted backend `compareStageB2Structural` (`structural_l2_v1`) |
| Client Dart matcher | **Not** live ranking (`production_candidate_not_live`, `liveDiscoverRanking=false`) |
| Policy | [qmatch_structural_matching_production_candidate_policy_v1.md](./qmatch_structural_matching_production_candidate_policy_v1.md) |
| Module weights | Frozen IQ / EQ / Frequency (0.133333 / 0.400000 / 0.466667) |
| Baseline (not candidate) | Equal-20D `canonical_20d_shadow_distance_v1` — regression only |

Structural answers: “how close are trait / static Frequency preference coordinates?”  
It does **not** answer temporal co-timing or value-alignment by itself.

#### L3 — Preferences

**Discover L3 v1 (this freeze):** explicit **profile** soft-preference diagnostics — `age`/`age_range`, `interests`, and (evaluated but not production-promoted) `location`/`distance_preference`. Contract: [qmatch_l3_soft_preference_signal_contract_v1.md](./qmatch_l3_soft_preference_signal_contract_v1.md) (`production_diagnostics_non_ranking_v1`).

Evaluated **after** trusted structural L2. Separate from L2. **Non-ranking in v1.** No fusion, no weights, no hard filtering. Missing = unknown (never a fake neutral). Known age mismatch ≠ unknown.

**Future L3 extension (not current Discover L3):** Core Method directional preference fit and relationship-value comparison. Offline today; requires live persistence + content review before any Discover use.

**Hard rule:** L3 must not be collapsed into L2 or replaced by Persona labels. CM values must not be treated as Discover L3 v1.

#### L4 — Temporal behavioral signals

**L4 v1 freeze:** [qmatch_l4_temporal_diagnostics_contract_v1.md](./qmatch_l4_temporal_diagnostics_contract_v1.md) (`production_diagnostics_non_ranking_v1`).

**Post-match only** — observed thread/message metadata. **No pre-match inference.** **Does not affect Discover order.** No fusion with L2/L3. Missing = unavailable (never a fake neutral). `gates_calibrated=false`. No real cohort yet. `last_active_at` is **not** an L4 signal.

| Field | L4 v1 role | Notes |
| --- | --- | --- |
| Cadence / burstiness / regularity / reply-turn / participation | **Production diagnostic** | `TemporalShadowExtractor` |
| Class A circadian (`circadian_activity_24h`) | **Conditional diagnostic** | Requires valid TZ + evidence gates |
| Class B ω, periodic phase, `phase_alignment=\cos\Delta\phi`, activity amplitude | **Research shadow only** | Not production-promoted |
| Mixed-state QI / multi-window \(\rho\) / multi-mode Wave-State | **Not L4** | Remain **L5** |

Do not copy global activity phase onto Frequency 6D. Do not treat cadence as \(\omega\).

#### L5 — Quantum-inspired shadow diagnostics

**Role:** Multi-window **state-distribution** diagnostics on the **same** Class-B oscillator.

| Field | Status |
| --- | --- |
| `purity_A` / `purity_B` | `validated_shadow_not_live` — must stay visible |
| `qi_mixed_fidelity` | `validated_shadow_not_live` — similarity of ensembles, **not** compatibility alone |
| `qi_trace_distance` | `validated_shadow_not_live` |
| Weight policy | Frozen `equal_window_v1` |

Policy: [qmatch_quantum_mixed_state_shadow_policy_freeze_v1.md](./qmatch_quantum_mixed_state_shadow_policy_freeze_v1.md).

**Hard rule:** Pure-state equatorial QI (\(F=\frac{1+\cos\Delta\phi}{2}\)) is **redundant** with `phase_alignment` and **must not** be a separate Matching signal.

---

## 2. Signal eligibility matrix (A / B)

### A. Eligible for production **now** (with caveats)

| Signal / system | Production role **now** | Caveat |
| --- | --- | --- |
| Trusted backend L2 (`compareStageB2Structural`) | **Live** Discover structural ranking | `structural_l2_v1`; missing L2 never imputed as 0 / 0.5 / 0.42 |
| L1 hard constraints already enforced in product | Live gates | Keep as hard filters; do not convert to soft % |
| Client Dart group-normalized matcher | **Not** Discover ranking | Formula replica / diagnostics (`production_candidate_not_live`) |
| Legacy `CompatibilityScoring` | **Rollback only** | `legacy_v1` via `DiscoverRankingMode.legacyV1` |

Nothing in L3–L5 is production-**ranking**-eligible today. Discover L3 v1 **diagnostics** (age + interests) and L4 v1 **cadence-family diagnostics** (post-match) are production-contracted and **non-ranking**. L4 Class B / `phase_alignment` remain research shadow. CM values remain a future L3 extension.

### B. Must remain shadow / not live

| Signal | Status | Why |
| --- | --- | --- |
| Client Dart \(D_{\mathrm{structural}}\) matcher | `production_candidate_not_live` | Replica only; does not rank Discover |
| Equal-20D distance | Baseline only | Not the production ranking path |
| `phase_alignment` | L4 research shadow | Needs real temporal streams + calibrated gates; **not** L4 v1 production |
| `activity_level_*` / gap | L4 research shadow | Separate diagnostic; no fusion; no canonical live \(A_u\) |
| Mixed-state QI fields | `validated_shadow_not_live` | Synthetic-validated; real multi-window data pending |
| Wave-State multi-mode / \(c_{\mathrm{abs}}\) as “resonance” | Research / gated | Mode-specific oscillators missing |
| Modal static amplitude / fused \(r_{\mathrm{wave}}\) | Spec / research | Envelope ≠ phase alignment |
| Persona prototypes | **Prohibited** as Matching key | Narrative only, if anywhere |
| RVI | **Prohibited** | Out of Matching architecture |
| Pure-state QI as separate wire field | **Prohibited** | Algebraically redundant with \(\cos\Delta\phi\) |

---

## 3. Hard constraints vs soft ranking signals (C)

| Kind | Layers | Behavior |
| --- | --- | --- |
| **Hard** | L1 | Fail → pair excluded (or held in `unknown`). No partial credit. |
| **Soft ranking** | L2 (when promoted); L3 ranking **not in v1** | Ordered / scored among eligible pairs. Missing → omit / degrade gracefully, never invent. |
| **Soft diagnostic** | Discover L3 v1 (profile prefs); L4 v1 post-match temporal (cadence family; circadian conditional) | Inform QA / future RFCs. **Must not** enter Discover ranking until an explicit ranking RFC. L4 Class B / `phase_alignment` remain research shadow. |
| **Forbidden pseudo-hard** | — | Do not treat low QI fidelity, low purity, or Persona mismatch as silent hard filters without an explicit future hard-constraint RFC. |

**v1 ranking rule (Stage C cutover complete):** among L1-eligible pairs, order by trusted backend L2 (smaller \(D_{\mathrm{structural}}\) first). Discover L3 v1 and L4 v1 are **non-ranking diagnostics**. Additional ranking use requires an explicit RFC. Rollback is `legacy_v1` CompatibilityScoring.

---

## 4. Missing-data policy (D) and never-impute list (E)

### D. How missing signals are handled

| Layer | Missing behavior |
| --- | --- |
| L1 | `unknown` or `ineligible` per product rule; do not pretend pass |
| L2 | Per-module omit when no shared measured dims; renormalize remaining module weights; if no modules → structural unavailable |
| L3 | Partial / unavailable statuses from existing preference/value services; **known mismatch ≠ unknown**; do not fill with neutral 0.5 “for ranking” |
| L4 | Production cadence family: sparse/unavailable per extractor gates. Circadian: unavailable without TZ. Class B research path: unavailable when ω not `ok` / provenance mismatch. Never impute; `last_active_at` is not L4 |
| L5 | `unavailable` when \(K<2\), inconsistent ensemble, provenance mismatch, or invalid \(\rho\) |
| Cross-layer | Absence of L4/L5 **must not** invent defaults that change L2 rank |

Wire should record **availability / reason**, not silent zeros.

### E. What must never be imputed

1. Missing 20D dimension scores (never 0 / 0.5 / 50)
2. Missing module distances
3. Phase \(\phi\), \(\omega\), or activity level from questionnaire alone
4. Copying global activity phase onto Frequency 6D modes
5. Fake ensemble members or depolarizing noise via free \(\lambda\)
6. Questionnaire-derived mixed \(\rho\)
7. Persona / archetype as a stand-in for structural or temporal distance
8. “Neutral” Compatibility / QI placeholders that affect ordering without evidence

---

## 5. Separation firewall (no fusion yet)

**Do not invent final fusion weights in this version.**

Keep at least these families as **separate fields** forever until an explicit fusion RFC:

1. L1 eligibility flags  
2. \(D_{\mathrm{structural}}\)  
3. Preference-fit / values outputs (L3)  
4. `phase_alignment`  
5. `activity_level_gap` (and levels)  
6. `purity_*`, `qi_mixed_fidelity`, `qi_trace_distance`

**Do not** combine shadow signals into one score.  
**Do not** ship a Discover “match %” that secretly blends L2–L5.

---

## 6. Legacy Discover migration path (F)

### F.1 Current state

| Path | Role |
| --- | --- |
| Live | Trusted backend `compareStageB2Structural` orders Discover (`structural_l2_v1`) |
| Client Dart matcher | Formula replica / diagnostics — does **not** rank Discover |
| Rollback | `CompatibilityScoring` via `DiscoverRankingMode.legacyV1` |
| Shadow temporal / QI | Diagnostics only; no Discover import |

### F.2 Migration stages

| Stage | Action | Discover ranking |
| --- | --- | --- |
| **A — Architecture freeze** | This document | Historical: legacy |
| **B — Dual-path shadow audit** | For the same L1-eligible pairs, compute legacy score **and** \(D_{\mathrm{structural}}\) offline / debug; report disagreement, coverage, missing-module rates | Historical: unchanged |
| **C — Structural cutover** | **Complete.** Discover soft ranking is trusted backend L2; legacy is explicit rollback | L2 live; `legacy_v1` rollback |
| **D — Temporal shadow on real data** | Ingest real timestamps → omega/phase → `phase_alignment` / activity levels in shadow stores | Still no L4 in ranking |
| **E — QI ensemble shadow on real windows** | Multi-window Class-B ensembles → purity / mixed fidelity | Still no L5 in ranking |
| **F — Optional soft-layer RFCs** | Only after real-data calibration: consider L3 **ranking** and/or gated L4 as **additional** soft signals with published weights | Requires new RFC; Discover L3 v1 ranking is **not** defined here (diagnostics only) |

Persona remains prohibited as a Matching key at every stage.

### F.3 Rollback

Any live cutover (Stage C+) must retain:

- `DiscoverRankingMode.legacyV1` → legacy CompatibilityScoring,
- parity dashboards for rank disagreement,
- no silent imputation when rolling forward.

---

## 7. Promotion conditions (G)

### G.1 Structural L2 Discover ranking (Stage C — complete)

Trusted backend L2 is the active Discover ranking path (`structural_l2_v1`). The client Dart matcher remains `liveDiscoverRanking=false`. Rollback is `legacy_v1`.

Historical promotion gates (dual-path audit, no Persona ranking key, missing-data never imputed, L4/L5 not required) remain the rationale; they are not reopened by this cutover.

### G.2 Before promoting **temporal L4 ranking** or Class B `phase_alignment`

L4 v1 **cadence-family diagnostics** are already frozen (non-ranking, post-match). Promoting Class B ω / `phase_alignment` / activity amplitude, or any L4 **rank** key, still requires all of:

1. Real temporal observation pipeline meeting Temporal Observation / Feature Extraction contracts  
2. Omega + phase binder gates calibrated on real cohorts (`gates_calibrated` may flip only after study)  
3. Provenance: same `oscillator_id` / epoch policy pairwise  
4. Demonstrated independence / value vs \(D_{\mathrm{structural}}\) on real data (keep fields separate)  
5. Explicit fusion RFC if ever combined with L2 — **weights not invented here**  
6. Civil-collision / sparse / ambiguous → unavailable, not imputed  
7. Timezone persistence before unconditional circadian production use 

### G.3 Before promoting **QI L5** (mixed-state)

All required:

1. L4 real-data path stable enough to yield \(K\ge 2\) accepted Class-B windows per user at meaningful rates  
2. Real-cohort study reproducing “information beyond mean phase” (synthetic stress is necessary but not sufficient)  
3. Purity kept as a visible separate diagnostic  
4. Product agreement that fidelity is **distribution similarity**, not a compatibility score  
5. Still no free \(\lambda\); weight policy changes require a new scoring_version  
6. Separate RFC for any ranking use; default remains shadow  

### G.4 Never promote

- Persona as Matching key  
- RVI as Matching signal  
- Pure-state QI as a separate live field  
- Multi-mode Wave-State resonance without mode-specific oscillators  

---

## 8. Current status snapshot

| Layer | Primary artifact | Status |
| --- | --- | --- |
| L1 | Product hard filters | Live (product) |
| L2 | Trusted backend group-normalized 20D | **Live** Discover ranking (`structural_l2_v1`) |
| L2 client Dart matcher | `Canonical20dGroupNormalizedShadowMatcher` | Not Discover ranking (`production_candidate_not_live`) |
| L3 Discover v1 | Profile age / interests diagnostics; distance evaluated not promoted | **Production diagnostics, non-ranking** (`production_diagnostics_non_ranking_v1`) |
| L3 CM extension | Preference fit / values services | Assessment/research; not Discover L3 v1 |
| L4 Discover v1 | Post-match cadence family; circadian conditional | **Production diagnostics, non-ranking** (`production_diagnostics_non_ranking_v1`) |
| L4 research shadow | Class B ω / periodic φ / `phase_alignment` / \(A_u\) | Implemented; **not** production-promoted |
| L5 | Mixed-state QI | `validated_shadow_not_live` |
| Rollback | Legacy CompatibilityScoring | `legacy_v1` only |

---

## 9. Exact next implementation step

**Stage C structural cutover is complete.** Do not re-open L2 ranking.  
**Discover L3 v1 diagnostics are frozen** (non-ranking). Do not add an L3 rank operator without a new RFC.  
**L4 v1 diagnostics are frozen** (post-match, non-ranking). Do not add an L4 rank operator or pre-match temporal inference without a new RFC.

Next matching work remains **shadow** except the frozen L3/L4 diagnostics:

- L4 research: real metadata cohort + TZ + calibrated gates before promoting Class B / `phase_alignment`
- Stage E — QI ensemble shadow on real windows (not ranking; **L5**)
- Optional later RFCs for additional **ranking** use of L3/L4 — weights not invented here

The client Dart matcher must stay decoupled from Discover ranking.

---

## 10. Non-goals

- No final blend weights  
- No single combined shadow score  
- No Persona / RVI  
- No production ranking code changes **from this document alone** (cutover lives in Discover + trusted callable)  
- No questionnaire→\(\phi/\omega/\rho\)  

---

## 11. Related documents

- [L4 temporal diagnostics contract](./qmatch_l4_temporal_diagnostics_contract_v1.md) (post-match diagnostics)  
- [L3 soft preference signal contract](./qmatch_l3_soft_preference_signal_contract_v1.md) (Discover L3 v1 diagnostics)  
- [Matching constraints contract](./qmatch_matching_constraints_contract_v1.md)  
- [Structural production-candidate policy](./qmatch_structural_matching_production_candidate_policy_v1.md)  
- [Wave-State amplitude semantics](./qmatch_wave_state_amplitude_semantics_v1.md)  
- [Quantum mixed-state policy freeze](./qmatch_quantum_mixed_state_shadow_policy_freeze_v1.md)  
- [Quantum mixed-state contract](./qmatch_quantum_mixed_state_shadow_contract_v1.md)  
- Temporal observation / feature extraction / phase / omega contracts in this folder  

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-12 | Initial final layered Matching architecture; legacy remains live; no fusion weights |
| v1 freeze | 2026-08-12 | Status → `architecture_frozen_not_live`; policy id `final_matching_architecture_v1` |
| v1 Stage C | 2026-08-16 | Trusted backend L2 is live Discover ranking (`structural_l2_v1`); Dart matcher still not a ranker; `legacy_v1` rollback only |
| v1 L3 freeze | 2026-08-16 | Discover L3 v1 = profile diagnostics (non-ranking); CM values = future extension; age mismatch ≠ unknown |
| v1 L4 freeze | 2026-08-16 | L4 v1 = post-match cadence diagnostics; circadian conditional; Class B/`phase_alignment` research shadow; QI/multi-mode remain L5 |
