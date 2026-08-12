# QMatch Mixed-State Quantum Shadow Contract v1

| Field | Value |
| --- | --- |
| Contract id | `quantum_mixed_state_shadow_v1` |
| Status | `validated_shadow_not_live` (see [policy freeze](./qmatch_quantum_mixed_state_shadow_policy_freeze_v1.md)) |
| Scope | Shadow research implementation + math contract. **No Discover ranking/UI.** |
| Depends on | [Quantum-Inspired Matching Model v1](./qmatch_quantum_inspired_matching_model_v1.md), [Wave Phase Reference Policy v1](./qmatch_wave_phase_reference_policy_v1.md), [Periodicity/Omega Estimator Contract v1](./qmatch_periodicity_omega_estimator_contract_v1.md), Validated Periodic Phase Binder v1, Amplitude Semantics v1 |
| Peer signals (remain separate) | \(D_{\mathrm{structural}}\), `phase_alignment`, `activity_level_gap` |
| Prohibited | Pure-state QI as a separate Matching signal; free \(\lambda\); questionnaire-derived states; Persona; RVI; Discover ranking; fake state completion; fusing mixed QI with structural/wave scores; ranking weights |
| Real-data validation | **Pending** |

---

## 0. Why this contract exists

The equatorial pure-state QI construction is algebraically redundant with Tier-1 `phase_alignment`:

\[
|\langle\psi_u|\psi_v\rangle|^2=\frac{1+\cos\Delta\phi}{2}.
\]

A **mixed** density matrix can add independent information only when \(\rho_u\) encodes a **data-backed ensemble** of accepted phases on the **same** oscillator — not a reparameterization of a single \(\phi_u\).

This contract defines that ensemble path. It does **not** claim humans are physical quantum systems; it uses quantum-information mathematics as a modeling formalism for evidential mixing.

---

## 1. Ensemble contract (eligibility)

### 1.1 Oscillator identity

All ensemble members for user \(u\) MUST share:

| Field | Rule |
| --- | --- |
| `oscillator_id` | Identical string (e.g. accepted activity spectral id) |
| \(\omega\) / \(T^\star\) | Compatible within Wave Phase Reference / omega relative tolerance |
| `phase_class` | `validatedPeriodic` (Class B) |
| `time_basis` | Identical (`utc` for spectral Class B) |
| `reference_epoch` policy | Identical policy (e.g. `window_start_utc`); pairwise compare still requires matching epoch strings when folding phases for fidelity |
| Omega status | Each member’s upstream omega estimate for that window is `ok` (not `civilCollision` / `ambiguous` / `sparse` / `unavailable`) |

Civil-collision periods stay on the Class A civil path — **not** in this mixed spectral ensemble.

### 1.2 Minimum ensemble size

\[
K_u \ge 2
\]

accepted Class-B phase estimates \(\{\phi_{u,k}\}_{k=1}^{K_u}\).

If \(K_u=1\) → do **not** emit mixed \(\rho_u\) (use pure-state path elsewhere, or unavailable for *mixed* diagnostics).  
If \(K_u=0\) → unavailable.

### 1.3 Window / estimate definition

A **member** \(k\) is one accepted temporal slice, for example:

| Member type | Definition |
| --- | --- |
| Contiguous calendar windows | Non-overlapping (or lightly overlapping) intervals of length \(L_w\) (e.g. 14–28 days) inside a larger observation span |
| Split-half | First/second half of one observation window (exactly \(K=2\) when both accept) |
| Rolling accepted estimates | Successive windows that each independently pass omega+phase gates |

Each member \(k\) MUST carry:

- its own accepted \(\phi_{u,k}\) from the Validated Periodic Phase Binder on that window’s timestamps  
- optional evidence stats used only for **weighting**: event count \(n_k\), coverage, SNR, \(\bar R_k\), split-half diagnostics from that window  
- provenance: `oscillator_id`, \(T^\star/\omega\), epoch policy, binder source version

**Hard rule:** \(\phi_{u,k}\) is never questionnaire-derived.

### 1.4 Ensemble status

| Status | Meaning |
| --- | --- |
| `ok` | \(K_u\ge 2\), all members Class-B compatible, weights valid, \(\rho_u\) constructed |
| `sparse` | Observation span could support multiple windows but fewer than 2 accept (diagnostics only; no mixed \(\rho\)) |
| `inconsistent` | Members fail same-oscillator / ω / epoch-policy compatibility |
| `unavailable` | Missing timestamps, invalid windows, or no accepted members |

---

## 2. Weight policy candidates (\(p_k\) from evidence only)

Weights \(\{p_k\}\) MUST satisfy

\[
p_k\ge 0,\qquad \sum_{k=1}^{K_u}p_k=1.
\]

**No free \(\lambda\).** No hand-tuned decoherence. No “default 10% noise.”

### 2.1 Allowed policies (choose one per scoring_version; document on wire)

#### Policy E — Equal-window

\[
p_k=\frac{1}{K_u}.
\]

Use when windows are pre-balanced (similar length / similar eligibility) and no calibrated uncertainty model exists yet.

#### Policy C — Coverage-weighted

Let \(c_k\) be a non-negative coverage score from real evidence, e.g.

- \(c_k=n_k\) (in-window event count), or  
- \(c_k=n_k\cdot\mathbf{1}[\text{window length}\ge L_{\min}]\), or  
- \(c_k=\) fraction of non-empty bins  

Then

\[
p_k=\frac{c_k}{\sum_j c_j}
\]

(requires \(\sum_j c_j>0\); else unavailable).

#### Policy U — Uncertainty-weighted (inverse-variance style)

Only when a **data-defined** uncertainty proxy \(\sigma_k>0\) exists per window, e.g. from:

- circular concentration: \(\sigma_k^2 \propto 1/\bar R_k\) with \(\bar R_k\) from that window’s binder, or  
- bootstrap/circular std of \(\phi\) within the window  

Then

\[
w_k=\frac{1}{\sigma_k^2},\qquad
p_k=\frac{w_k}{\sum_j w_j}.
\]

**Forbidden until calibrated:** inventing \(\sigma_k\) from global constants; mixing Policy U with an extra depolarizing term.

### 2.2 Policy selection rule (v1)

| Stage | Policy |
| --- | --- |
| First shadow implementation | **Policy E** (equal-window) or **Policy C** with \(c_k=n_k\) |
| After uncertainty calibration study | Optionally Policy U |
| Never in v1 | Free \(\lambda\), temperature, or ad-hoc smoothing toward \(I/2\) |

Wire MUST record `weight_policy_id` ∈ {`equal_window`, `coverage_n`, `uncertainty_inv_var`, …}.

---

## 3. Density-matrix construction

### 3.1 Per-member pure state (equatorial default)

For each accepted \(\phi_{u,k}\), use the Quantum-Inspired v1 equatorial pure state (activity level **not** fused into \(|\psi\rangle\)):

\[
|\psi_{u,k}\rangle
=
\frac{1}{\sqrt{2}}\Big(|0\rangle+e^{i\phi_{u,k}}|1\rangle\Big).
\]

### 3.2 Mixed state

\[
\rho_u
=
\sum_{k=1}^{K_u} p_k\,|\psi_{u,k}\rangle\langle\psi_{u,k}|.
\]

### 3.3 Axioms (mandatory checks)

\[
\rho_u=\rho_u^\dagger,
\qquad
\rho_u\ge 0,
\qquad
\mathrm{Tr}(\rho_u)=1.
\]

Implementation tests MUST verify eigenvalues \(\ge 0\) and trace \(1\) within numerical tolerance. Failure → `unavailable` (do not clamp silently into an invalid operator).

### 3.4 Explicit Bloch form (2D equatorial mixtures)

For equatorial pure states, each projector has Bloch vector
\(\mathbf{r}_k=(\cos\phi_{u,k},\sin\phi_{u,k},0)\). Then

\[
\rho_u=\frac{I+\mathbf{r}_u\cdot\boldsymbol{\sigma}}{2},
\qquad
\mathbf{r}_u=\sum_k p_k\,\mathbf{r}_k.
\]

Purity and fidelity then depend on \(\|\mathbf{r}_u\|\) and the angle between \(\mathbf{r}_u,\mathbf{r}_v\) — i.e. on the **distribution** of phases, not only one mean phase.

---

## 4. Purity, fidelity, trace distance

### 4.1 Purity

\[
\mathrm{Purity}(\rho_u)=\mathrm{Tr}(\rho_u^2)\in\Big[\tfrac12,1\Big]
\quad\text{for qubit}\ \mathcal{H}_2.
\]

For the equatorial mixture above:

\[
\mathrm{Tr}(\rho_u^2)=\frac{1+\|\mathbf{r}_u\|^2}{2}.
\]

- \(\mathrm{Tr}(\rho^2)=1\): all mass on one phase (pure / fully consistent windows).  
- \(\mathrm{Tr}(\rho^2)\to 1/2\): phases cancel on the equator (high temporal phase variability).

### 4.2 Pair fidelity

Uhlmann–Jozsa fidelity:

\[
F(\rho_u,\rho_v)
=
\Big(\mathrm{Tr}\sqrt{\sqrt{\rho_u}\,\rho_v\sqrt{\rho_u}}\Big)^2
\in[0,1].
\]

For qubits with Bloch vectors \(\mathbf{r}_u,\mathbf{r}_v\):

\[
F
=
\frac{1+\mathbf{r}_u\cdot\mathbf{r}_v
+\sqrt{(1-\|\mathbf{r}_u\|^2)(1-\|\mathbf{r}_v\|^2)}}{2}.
\]

**Contrast with Tier-1** `phase_alignment`\(=\cos\Delta\phi\) from single accepted (or primary) phases: mixed fidelity depends on **means and lengths** of Bloch vectors (ensemble concentration).

### 4.3 Optional trace distance

\[
D_{\mathrm{tr}}(\rho_u,\rho_v)=\frac12\mathrm{Tr}|\rho_u-\rho_v|.
\]

For qubits:

\[
D_{\mathrm{tr}}=\frac12\|\mathbf{r}_u-\mathbf{r}_v\|_2.
\]

Dissimilarity only — not a “match %”.

### 4.4 Recommended shadow wire fields (separate)

| Field | Definition |
| --- | --- |
| `qi_mixed_status` | `ok` \| `sparse` \| `inconsistent` \| `unavailable` |
| `qi_mixed_weight_policy` | policy id |
| `qi_mixed_member_count` | \(K_u\) |
| `qi_purity_u` / `qi_purity_v` | \(\mathrm{Tr}(\rho^2)\) |
| `qi_mixed_fidelity` | \(F(\rho_u,\rho_v)\) or null |
| `qi_mixed_trace_distance` | optional \(D_{\mathrm{tr}}\) or null |

**Do not** replace or overwrite `phase_alignment`, `activity_level_gap`, or \(D_{\mathrm{structural}}\).

---

## 5. What mixedness means behaviorally

| QI language | Behavioral / evidential meaning in QMatch |
| --- | --- |
| High purity | User’s accepted window phases concentrate near one angle on this oscillator (stable timing habit across windows) |
| Low purity | Accepted windows disagree on phase (timing habit drifts, multimodal schedules, unstable periodicity fold) |
| Mixed fidelity high | Both users have concentrated, mutually aligned ensembles |
| Mixed fidelity mid/low while `phase_alignment` high | Primary/single-window phases agree, but one or both ensembles are diffuse → agreement is fragile |
| Mixed fidelity vs pure overlap diverge | Ensemble geometry adds information beyond one \(\cos\Delta\phi\) |

This is **epistemic / temporal variability**, not physical decoherence.

---

## 6. How this differs from `phase_alignment` — when fidelity adds information

| Object | Uses |
| --- | --- |
| `phase_alignment` | Typically one accepted (or primary) \(\phi_u,\phi_v\) → \(\cos\Delta\phi\) |
| Mixed \(F(\rho_u,\rho_v)\) | Full weighted cloud \(\{\phi_{u,k},p_k\}\), \(\{\phi_{v,\ell},q_\ell\}\) |

**Independent information appears when** at least one user’s phase ensemble is non-degenerate (\(\|\mathbf{r}\|<1\)), e.g.:

- same mean phase, different spreads → different purity and different \(F\) to a sharp partner  
- bimodal window phases → \(\mathbf{r}\approx 0\) even if some pairwise window cosines look fine  
- one stable and one drifting user → asymmetric purity; fidelity penalizes drift

**No independent information when** \(K=1\) or all \(\phi_{u,k}\) identical (then \(\rho\) pure and \(F\) collapses to the pure-state function of \(\cos\Delta\phi\)).

---

## 7. Missing-data / unavailable rules

| Situation | Mixed QI status | Emit \(\rho\) / \(F\)? |
| --- | --- | --- |
| \(K_u<2\) | `sparse` or `unavailable` | No mixed \(\rho_u\) |
| Member omega not `ok` | Exclude member; if \(K<2\) after filter → sparse/unavailable | No |
| Oscillator / ω / epoch-policy mismatch across members | `inconsistent` | No |
| Weight denominator zero / invalid \(p_k\) | `unavailable` | No |
| Pair: either side not `ok` mixed | pair fields null | No \(F\) |
| Pair: incompatible oscillators between \(u\) and \(v\) | unavailable (pair) | No |
| Missing timestamps in a window | that window ineligible | No imputation |
| Questionnaire-only user | unavailable | Never build state from questionnaire |

**No fake completion** toward \(I/2\) or uniform phase.

---

## 8. Separation firewall

Keep as distinct shadow diagnostics:

1. \(D_{\mathrm{structural}}\)  
2. `phase_alignment`  
3. `activity_level_gap`  
4. Mixed-state QI (`qi_purity_*`, `qi_mixed_fidelity`, optional trace distance)

Do **not** invent a combined score, weights across these families, or Discover ranking in this version.

No Persona. No RVI.

---

## 9. Recommended first shadow implementation (when code is allowed later)

Still out of scope for **this** task (spec only). When implemented:

1. Partition eligible timestamps into \(K\ge 2\) windows (start with split-half or fixed non-overlap).  
2. Run existing spectral omega + validated phase binder **per window**.  
3. Keep members with omega `ok` + phase available on same `oscillator_id`.  
4. If \(K\ge 2\), build \(\rho_u\) with **Policy E** or **Policy C** (`n_k`).  
5. Emit purity; for compatible pairs emit `qi_mixed_fidelity` (+ optional trace distance).  
6. Leave \(D_{\mathrm{structural}}\) / `phase_alignment` / `activity_level_gap` unchanged and unfused.  
7. Offline stress: compare \(F(\rho_u,\rho_v)\) residuals vs `phase_alignment` under controlled ensemble spread.

### Explicit non-goals for first implementation

- No free \(\lambda\) channel  
- No questionnaire states  
- No multi-mode Frequency QI  
- No Discover / Persona / RVI  

---

## 10. Acceptance checklist for a future implementation PR

- [ ] Status remains shadow / not live Discover  
- [ ] \(K\ge 2\) enforced; same `oscillator_id` / compatible ω / epoch policy  
- [ ] `weight_policy_id` recorded; \(\sum p_k=1\); no \(\lambda\)  
- [ ] \(\rho\ge 0\), \(\mathrm{Tr}\rho=1\) tested  
- [ ] Missing/inconsistent → unavailable/sparse (no imputation)  
- [ ] Wire separates mixed QI from structural/wave fields  
- [ ] Docs say quantum-inspired formalism, not physical quantum humans  

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-12 | Initial mixed-state shadow contract after pure-state QI redundancy audit |
| v1 freeze | 2026-08-12 | Status → `validated_shadow_not_live`; equal-window implementation frozen; pure-state QI barred as separate signal |
