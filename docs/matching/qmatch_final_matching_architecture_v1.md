# QMatch Final Matching Architecture v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_final_matching_architecture_v1` |
| Policy id | `final_matching_architecture_v1` |
| Status | `architecture_frozen_not_live` |
| Scope | **Architecture freeze (docs only).** Does **not** change Discover ranking, Discover UI, or live scoring. |
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
| L2 structural | Group-normalized 20D \(D_{\mathrm{structural}}\) — `production_candidate_not_live` |
| L3 preferences / values | Separate from L2; not fused in v1 |
| L4 temporal | Shadow only (`phase_alignment`, activity levels); real temporal data required |
| L5 mixed-state QI | Shadow only (`validated_shadow_not_live`) |
| Persona / RVI / pure-state QI | **Prohibited** as Matching keys |
| Legacy Discover | `CompatibilityScoring` **remains live** until Stage C cutover |
| Fusion weights | **Not invented yet**; no combined shadow score |
| Rollback | Required for any live cutover (feature flag → legacy) |

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
│     coordinates) — production_candidate_not_live            │
└────────────────────────────┬────────────────────────────────┘
                             │ soft ranking signal (when live)
┌────────────────────────────▼────────────────────────────────┐
│ L3  Preferences / values                                    │
│     directional preference fit + relationship values        │
│     (separate from L2; not fused in v1)                     │
└────────────────────────────┬────────────────────────────────┘
                             │ soft diagnostics / future soft rank
┌────────────────────────────▼────────────────────────────────┐
│ L4  Temporal behavioral signals                             │
│     phase_alignment, activity_level_*, omega/phase gates    │
│     (shadow; real temporal data required)                   │
└────────────────────────────┬────────────────────────────────┐
                             │ shadow diagnostics only
┌────────────────────────────▼────────────────────────────────┐
│ L5  Quantum-inspired shadow diagnostics                     │
│     mixed-state purity / fidelity / trace distance          │
│     (validated_shadow_not_live; not compatibility alone)    │
└─────────────────────────────────────────────────────────────┘

Live Discover today: legacy CompatibilityScoring (outside this stack)
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
| Status | `production_candidate_not_live` |
| Policy | [qmatch_structural_matching_production_candidate_policy_v1.md](./qmatch_structural_matching_production_candidate_policy_v1.md) |
| Module weights | Frozen IQ / EQ / Frequency (0.133333 / 0.400000 / 0.466667) |
| Baseline (not candidate) | Equal-20D `canonical_20d_shadow_distance_v1` — regression only |

Structural answers: “how close are trait / static Frequency preference coordinates?”  
It does **not** answer temporal co-timing or value-alignment by itself.

#### L3 — Preferences / values

**Role:** Soft signals for **declared / directional** preference fit and relationship-value agreement.

| Family | Notes |
| --- | --- |
| Directional preference fit | Partner-preference vs other profile; directional (A←B / B←A remain distinct) |
| Relationship values | Value-layer comparison services (Core Method); separate from structural MSE |

**Status in this architecture:** Implemented in Core Method assessment domain for explanation / aggregation research; **not** wired as Discover ranking and **not** given fusion weights here.

**Hard rule:** L3 must not be collapsed into L2 or replaced by Persona labels.

#### L4 — Temporal behavioral signals

**Role:** Evidence-backed timing / activity dynamics on accepted oscillators.

| Field | Status | Notes |
| --- | --- | --- |
| `phase_alignment` = \(\cos\Delta\phi\) | Shadow | Tier-1 global activity oscillator; **real temporal data required** |
| `activity_level_A/B`, `activity_level_gap` | Shadow | Separate from phase; never fused into \(\cos\Delta\phi\) |
| Spectral \(\omega\) / Class-B phase binder | Shadow | Provenance gates; civil-collision stays Class A civil path |
| Multi-mode Frequency temporal attach | Research / unavailable | Requires mode-specific oscillators ([amplitude semantics](./qmatch_wave_state_amplitude_semantics_v1.md)) |

Policy anchors: Wave Phase Reference, Activity Spectral Omega, Validated Periodic Phase Binder, Amplitude Semantics v1.

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
| Legacy `CompatibilityScoring` | **Live** Discover ranking / UI chips | Temporary; migration target is L2 (+ later layers) |
| L1 hard constraints already enforced in product | Live gates | Keep as hard filters; do not convert to soft % |
| Group-normalized 20D \(D_{\mathrm{structural}}\) | **Not live ranking** | Status `production_candidate_not_live` — eligible to **prepare** for promotion only after §7 conditions |

Nothing in L3–L5 is production-ranking-eligible today.

### B. Must remain shadow / not live

| Signal | Status | Why |
| --- | --- | --- |
| \(D_{\mathrm{structural}}\) (group-normalized 20D) | `production_candidate_not_live` | Candidate, not cut over |
| Equal-20D distance | Baseline only | Not the production candidate |
| `phase_alignment` | Shadow | Needs real temporal streams + calibrated gates |
| `activity_level_*` / gap | Shadow | Separate diagnostic; no fusion |
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
| **Soft ranking** | L2 (when promoted); later optionally L3 | Ordered / scored among eligible pairs. Missing → omit / degrade gracefully, never invent. |
| **Soft diagnostic** | L4, L5 | Inform research, QA, future gates. **Must not** enter Discover ranking until promotion criteria in §7 are met. |
| **Forbidden pseudo-hard** | — | Do not treat low QI fidelity, low purity, or Persona mismatch as silent hard filters without an explicit future hard-constraint RFC. |

**v1 ranking rule (when L2 goes live):** among L1-eligible pairs, order by soft L2 (and only later by explicitly approved additional soft layers). Until then, live order remains legacy CompatibilityScoring.

---

## 4. Missing-data policy (D) and never-impute list (E)

### D. How missing signals are handled

| Layer | Missing behavior |
| --- | --- |
| L1 | `unknown` or `ineligible` per product rule; do not pretend pass |
| L2 | Per-module omit when no shared measured dims; renormalize remaining module weights; if no modules → structural unavailable |
| L3 | Partial / unavailable statuses from existing preference/value services; do not fill with neutral 0.5 “for ranking” |
| L4 | `unavailable` when timestamps sparse, omega not `ok`, phase unbound, or provenance mismatch |
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
| Live | `CompatibilityScoring` drives Discover ordering / chips |
| Shadow candidate | Group-normalized 20D structural matcher |
| Shadow temporal / QI | Diagnostics only; no Discover import |

### F.2 Migration stages (ranking unchanged until Stage C)

| Stage | Action | Discover ranking |
| --- | --- | --- |
| **A — Architecture freeze** | This document | Unchanged (legacy) |
| **B — Dual-path shadow audit** | For the same L1-eligible pairs, compute legacy score **and** \(D_{\mathrm{structural}}\) offline / debug; report disagreement, coverage, missing-module rates | Unchanged |
| **C — Structural cutover candidate** | After Stage B acceptance (§7.1), switch Discover soft ranking to L2 under feature flag; keep legacy as fallback | L2 live; legacy fallback |
| **D — Temporal shadow on real data** | Ingest real timestamps → omega/phase → `phase_alignment` / activity levels in shadow stores | Still no L4 in ranking |
| **E — QI ensemble shadow on real windows** | Multi-window Class-B ensembles → purity / mixed fidelity | Still no L5 in ranking |
| **F — Optional soft-layer RFCs** | Only after real-data calibration: consider L3 and/or gated L4 as **additional** soft signals with published weights | Requires new RFC; not defined here |

Persona remains prohibited as a Matching key at every stage.

### F.3 Rollback

Any live cutover (Stage C+) must retain:

- feature flag off → legacy CompatibilityScoring,
- parity dashboards for rank disagreement,
- no silent imputation when rolling forward.

---

## 7. Promotion conditions (G)

### G.1 Before promoting **structural L2** to live Discover ranking

All required:

1. Dual-path cohort report on **real** Discover-eligible pairs (Stage B) reviewed  
2. Missing-module / coverage rates acceptable under product SLA  
3. Explicit product sign-off that Persona is not used as ranking key  
4. Feature-flagged cutover + rollback plan  
5. No dependency on L4/L5 being present  

### G.2 Before promoting **temporal L4** (`phase_alignment` / activity levels)

All required:

1. Real temporal observation pipeline meeting Temporal Observation / Feature Extraction contracts  
2. Omega + phase binder gates calibrated on real cohorts (`gates_calibrated` may flip only after study)  
3. Provenance: same `oscillator_id` / epoch policy pairwise  
4. Demonstrated independence / value vs \(D_{\mathrm{structural}}\) on real data (keep fields separate)  
5. Explicit fusion RFC if ever combined with L2 — **weights not invented here**  
6. Civil-collision / sparse / ambiguous → unavailable, not imputed  

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
| L2 | Group-normalized 20D | `production_candidate_not_live` |
| L3 | Preference fit / values services | Assessment/research; not Discover ranking |
| L4 | `phase_alignment`, activity levels | Shadow; real temporal data required |
| L5 | Mixed-state QI | `validated_shadow_not_live` |
| Live Discover | Legacy CompatibilityScoring | Live until Stage C |

---

## 9. Exact next implementation step

**Stage B dual-path shadow audit (no Discover ranking change):**

Implement an offline / debug-only runner that, for real (or fixture-backed real-shaped) Discover-eligible pairs:

1. Applies existing L1 eligibility as used by Discover today  
2. Computes live legacy `CompatibilityScoring` result (read-only)  
3. Computes \(D_{\mathrm{structural}}\) via `canonical_20d_group_normalized_shadow_distance_v1` with missing-module reporting  
4. Writes a cohort report under `docs/matching/reports/` (coverage, rank disagreement, unavailable reasons)  
5. Touches **no** Discover UI and invents **no** fusion with L4/L5  

That is the only production-candidate signal’s next gate before any live cutover. Temporal ingest and QI real-window ensembles proceed in parallel as **shadow** workstreams, not as ranking prerequisites for Stage B.

---

## 10. Non-goals

- No final blend weights  
- No single combined shadow score  
- No Persona / RVI  
- No production ranking code changes under this document alone  
- No questionnaire→\(\phi/\omega/\rho\)  

---

## 11. Related documents

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
