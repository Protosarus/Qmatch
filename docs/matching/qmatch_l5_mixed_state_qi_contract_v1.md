# QMatch L5 Mixed-State QI Contract v1

| Field | Value |
| --- | --- |
| Contract id | `l5_mixed_state_qi_contract_v1` |
| Document id | `qmatch_l5_mixed_state_qi_contract_v1` |
| Status | `validated_shadow_not_live` |
| Scope | **Validated research shadow.** Non-ranking. Mixed-state QI is the **only** retained L5 v1 candidate. |
| Scoring | `quantum_mixed_state_shadow_v1` / weight policy `equal_window_v1` |
| Inputs | \(K\ge 2\) accepted Class-B phase windows with **shared** oscillator provenance |
| Explicitly out of scope | Discover ranking; L1/L2/L3/L4 logic; fusion with L2/L3/L4; pure-state QI as a separate signal; multi-mode Wave-State in production; fused \(r_{\mathrm{wave}}\) / amplitude×phase as an L5 score; copying global activity phase onto Frequency 6D; questionnaire-derived \(\phi/\omega\); fidelity as a compatibility % |

---

## 0. Research freeze

L5 v1 is a **validated research shadow**. It does **not** affect Discover order. It is **not** a production diagnostic and **not** a rank key.

| Rule | Frozen value |
| --- | --- |
| Retained candidate | Mixed-state QI only |
| Ranking | **Non-ranking.** Does not reorder Discover |
| Fusion | **Forbidden** with L2, L3, or L4 |
| Missing data | **Unavailable** — never 0 / 0.5 / 0.42 / “neutral” |
| Ensemble floor | \(K\ge 2\) accepted Class-B windows per side |
| Provenance | Same `oscillator_id`, compatible \(\omega\) / \(T^\star\), identical reference epoch |
| Weight policy | `equal_window_v1` (\(p_k=1/K\)) |
| `gates_calibrated` | **`false`** |
| Real multi-window cohort | **None currently exists** |
| Real-data replication | **Pending** |
| Ranking RFC | **Required** before any ranking use |

Math is that already specified in the [mixed-state shadow contract](./qmatch_quantum_mixed_state_shadow_contract_v1.md) and [policy freeze](./qmatch_quantum_mixed_state_shadow_policy_freeze_v1.md). **No new math in this freeze.**

---

## 1. Retained vs rejected

### Retained (L5 v1 candidate — shadow only)

Separate diagnostics. Do **not** collapse into one score.

| Field | Existing formula | Role |
| --- | --- | --- |
| `purity_A` / `purity_B` | \(\mathrm{Tr}(\rho^2)=(1+\|\mathbf{r}\|^2)/2\) | Ensemble concentration; **must stay visible** |
| `qi_mixed_fidelity` | \(F=\frac12\bigl(1+\mathbf{r}_A\cdot\mathbf{r}_B+\sqrt{(1-\|\mathbf{r}_A\|^2)(1-\|\mathbf{r}_B\|^2)}\bigr)\) | State-distribution **similarity**, not compatibility |
| `qi_trace_distance` | \(D_{\mathrm{tr}}=\frac12\|\mathbf{r}_A-\mathbf{r}_B\|_2\) | Dissimilarity; not a match % |

Carrier (not a separate score): equal-window equatorial mixture

\[
r_x=\sum_k p_k\cos\phi_k,\quad
r_y=\sum_k p_k\sin\phi_k,\quad
p_k=1/K,\quad
K\ge 2
\]

\[
\rho=\tfrac12\begin{pmatrix}1&r_x-ir_y\\ r_x+ir_y&1\end{pmatrix}
\]

High \(F\) means the two window ensembles are similar. It is **not** a compatibility percentage.

### Rejected from L5 v1 (keep implemented as research / lab math; not this contract)

| Signal | Why rejected |
| --- | --- |
| Pure-state QI \(F=(1+\cos\Delta\phi)/2\) | **Redundant** with L4 research `phase_alignment=\cos\Delta\phi`. Must not be a separate Matching signal |
| Multi-mode Wave-State \(\Psi_u(s,t)\) / Frequency 6D \(r_{\mathrm{wave}}\) | **Not production.** Real-user path `research_only_unavailable` until mode-specific oscillators exist |
| Fused \(r_{\mathrm{wave}}=\cos\Delta\phi\cdot\cos\angle(A,B)\) | Mixes phase with envelope; L4 freeze already split these. **Not an L5 score** |
| \(c_{\mathrm{abs}}=\lvert\cos\angle(A,B)\rvert\) | Phase-blind envelope diagnostic; not resonance; not L5 |
| Copying global activity \(\phi/\omega\) onto Frequency 6D | **Forbidden** |
| Questionnaire-derived \(\phi/\omega/\rho\) | **Forbidden** |

---

## 2. Required inputs (not supplied by L4 v1 production)

Each ensemble member \(k\) is one **accepted Class-B** window:

- `ValidatedPeriodicPhaseEstimate` available
- `ActivitySpectralOmegaEstimate` status `ok` (not civil-collision / ambiguous / sparse / unavailable)
- Shared `oscillator_id`, \(\omega\), \(T^\star\), reference epoch
- \(\phi_k\) never questionnaire-derived

If \(K<2\), provenance mismatch, inconsistent ensemble, or invalid \(\rho\) → `unavailable`.

L4 v1 **production** diagnostics (cadence family; conditional circadian) do **not** emit these windows. L4 Class B ω / phase remain **research shadow** and `gates_calibrated=false`. L5 cannot be computed from L4 production diagnostics today.

---

## 3. Isolation

- DiscoverService must not rank on L5 fields.
- No L2/L3/L4 blend. No free \(\lambda\). No ranking weights.
- Do not treat low fidelity or low purity as a silent hard filter.
- Absence of L5 must not invent defaults that change L2 rank.

Dart: `L5MixedStateQiContract` / `QuantumMixedStateShadowMatcher`.

---

## 4. Promotion requirements (all required)

L5 v1 stays `validated_shadow_not_live` until **all** of:

1. **Calibrated L4 Class-B gates** (`gates_calibrated` may flip only after study)
2. **Real multi-window cohort** yielding \(K\ge 2\) accepted Class-B windows per user at meaningful rates
3. **Replication on real data** of “information beyond mean phase” (synthetic stress is necessary, not sufficient)
4. **Separate ranking RFC** — default remains shadow; fidelity is not a match %; purity stays a visible separate diagnostic; no free \(\lambda\); weight-policy change needs a new scoring version

Never promote: Persona / RVI as Matching keys; pure-state QI as a live field; multi-mode Wave-State without mode-specific oscillators; fused \(r_{\mathrm{wave}}\) as L5.

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 research freeze | 2026-08-16 | L5 v1 = mixed-state QI validated shadow; \(K\ge 2\) Class-B windows; four separate diagnostics; Wave-State / fused \(r_{\mathrm{wave}}\) / pure-state QI rejected |
