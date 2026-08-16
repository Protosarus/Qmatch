# QMatch L4 Temporal Diagnostics Contract v1

| Field | Value |
| --- | --- |
| Contract id | `l4_temporal_diagnostics_contract_v1` |
| Document id | `qmatch_l4_temporal_diagnostics_contract_v1` |
| Status | `production_diagnostics_non_ranking_v1` |
| Scope | **Post-match** temporal diagnostics from observed thread/message metadata. **Non-ranking.** No Discover order change. No fusion with L2/L3. |
| Inputs | `threads/{id}` `participants`; `threads/{id}/messages/{id}` `sender_id` + `created_at` / `client_created_at` |
| Explicitly out of scope | Pre-match inference; `last_active_at` as L4; questionnaire→φ/ω; Discover ranking; L1/L2/L3; L5 mixed-state QI / multi-window ρ / multi-mode Wave-State |

---

## 0. Production freeze

| Rule | Frozen value |
| --- | --- |
| Evaluation context | **After match** — existing thread + human message timestamps |
| Pre-match temporal inference | **Forbidden** |
| Discover ranking | **Does not affect Discover order** |
| Fusion | **No fusion with L2 or L3** |
| Missing data | **Unavailable** — never 0 / 0.5 / 0.42 / “neutral” |
| Questionnaire φ / ω | **Forbidden** |
| `last_active_at` | **Not an L4 signal** (L2 recency tie-break only) |
| `gates_calibrated` | **`false`** |
| Real cohort | **None currently exists** (`threads_analyzed=0`) |

### Production vs research vs not L4

| Class | Signals |
| --- | --- |
| **Production diagnostic** | Cadence (`λ_mean`, `λ_med`); burstiness \(B\); regularity \(R\); reply/turn timing; participation / count diagnostics |
| **Conditional diagnostic** | Class A circadian (`circadian_activity_24h` / alias `circadian_24h`) **only** when valid timezone **and** evidence gates pass |
| **Research shadow only** | Class B ω; periodic phase binder; `phase_alignment=\cos\Delta\phi`; activity amplitude \(A_u\); global activity oscillator pairwise comparisons |
| **Not L4 (remain L5)** | Mixed-state QI; multi-window density matrices; multi-mode Wave-State |

Formulas are those already specified in [Temporal Feature Extraction v1](./qmatch_temporal_feature_extraction_v1.md) and existing shadow estimators. **No new math in this freeze.**

---

## 1. Production diagnostics (thread metadata)

Implemented by `TemporalShadowExtractor` (`temporal_feature_extraction_v1`).

| Signal | Formula (existing) | Missing |
| --- | --- | --- |
| Event counts | \(N_U\), \(N_{PQ}\) | Invalid window → unavailable |
| Cadence | \(\lambda^{\mathrm{mean}}=N/T_W\); \(\lambda^{\mathrm{med}}=1/\mathrm{median}(\delta)\) | Sparse gates; **not** \(\omega\) |
| Burstiness | \(B=(\sigma-m)/(\sigma+m)\) | \(<3\) intervals → unavailable |
| Regularity | \(R=1/(1+\mathrm{CV})\) | Same interval floor |
| Reply / turn | Median sender-flip gaps (24h timeout provisional) | Too few gaps → sparse/unavailable |
| Participation | share \(N_P/(N_P+N_Q)\); balance \(1-2\lvert\mathrm{share}_P-0.5\rvert\) | Low \(N\) → sparse/unavailable |

System messages excluded. No message body. No imputation of timestamps.

**`omega` in this extractor is always `unavailable`.** Class B ω is a separate research estimator.

---

## 2. Conditional diagnostic — Class A circadian

Oscillator: `circadian_activity_24h` (extractor alias `circadian_24h` — **same global activity clock**, not a Frequency mode).

\[
\theta_k=2\pi\,\tau_k/86400,\quad
\bar\theta=\mathrm{atan2}(\bar S,\bar C),\quad
\bar R=\sqrt{\bar C^2+\bar S^2}
\]

\(\omega=2\pi/86400\) is **definitional** (civil day), not detected.

**Required:** local timezone (offset + label). Missing TZ → unavailable (do **not** treat UTC as local).

Provisional gates remain **uncalibrated** (`gates_calibrated=false`): event/day/\(\bar R\) floors in `CircadianActivityPhaseEstimatorContract` / extractor.

---

## 3. Research shadow only (not L4 v1 production-promoted)

Keep implemented; **do not** treat as production L4 diagnostics:

| Artifact | Role |
| --- | --- |
| `ActivitySpectralOmegaEstimator` | Class B \(T^\star\), \(\omega=2\pi/T^\star\) |
| `ValidatedPeriodicPhaseBinder` | Folded circular mean on accepted \(T^\star\) |
| `GlobalActivityPeriodicResonance` | `phase_alignment=\cos\Delta\phi` + caller-supplied \(A_u\) gap |
| Multi-amp `PeriodicWaveStateResonanceAdapter` | Research envelope; not Tier-1 L4 production |

Civil 24h/7d spectral peaks stay `civil_collision` — Class A path, not Class B ω.

---

## 4. Not L4

| System | Layer |
| --- | --- |
| Mixed-state QI (`purity`, mixed fidelity, trace distance) | **L5** |
| Multi-window density matrices (\(K\ge 2\) ensembles) | **L5** |
| Multi-mode Wave-State \(\Psi_u(s,t)\) / six-mode `r_wave` | **L5** (research; mode-specific oscillators missing) |

Do not copy global activity phase onto Frequency 6D modes.

---

## 5. Isolation

- DiscoverService must not rank on L4 fields.
- No L2/L3 blend.
- Cadence must never be labeled \(\omega\).
- `last_active_at` stays L2 tie-break / unavailable fallback only.

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 production freeze | 2026-08-16 | Post-match diagnostics; production cadence family; conditional circadian; Class B / phase_alignment research shadow; L5 remains L5 |
