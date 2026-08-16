# QMatch Quantum-Inspired Matching Model v1

| Field | Value |
| --- | --- |
| Model id | `quantum_inspired_matching_model_v1` |
| Status | `specification_only_not_live` — L5 v1 retains **mixed-state QI only** ([L5 contract](./qmatch_l5_mixed_state_qi_contract_v1.md)) |
| Scope | Docs/spec only. **No production ranking.** Pure-state QI is **not** an L5 Matching signal. |
| Depends on | [Wave-State Amplitude Semantics v1](./qmatch_wave_state_amplitude_semantics_v1.md), [Wave Phase Reference Policy v1](./qmatch_wave_phase_reference_policy_v1.md), [Modal Resonance Model v1](./qmatch_modal_resonance_model_v1_specification.md), group-normalized 20D structural candidate, Activity Spectral Omega + Validated Periodic Phase Binder |
| Peer signals (remain separate) | \(D_{\mathrm{structural}}\), `phase_alignment`, `activity_level_gap` |
| Prohibited | Claiming humans are physical quantum systems; Persona; RVI; Discover ranking/UI; inventing \(\lambda\)/noise without data; fake state completion; combining quantum diagnostics with structural/wave scores in this version |

---

## 0. Scientific posture

This document defines a **quantum-information formalism** as a *modeling language* for QMatch shadow diagnostics.

It is:

- a mathematical specification for normalized states and (when justified) density operators
- compatible with later shadow implementations beside existing signals
- honest about what current QMatch evidence can and cannot support

It is **not**:

- a claim that people are qubits, wavefunctions, or physical quantum systems
- a license to invent mixing parameters, entanglement narratives, or \(\hbar\)-physics marketing
- a replacement for structural Matching or Tier-1 wave diagnostics
- a Discover ranking formula

**Metaphor hygiene.** Product and research copy must say *quantum-inspired* / *quantum-information formalism*, never *users are quantum*.

**Firewall.** In this version, quantum-inspired pair diagnostics are **separate wire fields**. Do **not** fuse them with \(D_{\mathrm{structural}}\), `phase_alignment`, or `activity_level_gap`. L5 v1 retains mixed-state QI only; the equatorial pure-state construction below is **not** a separate Matching signal.

---

## 1. Existing signals (unchanged, uncombined)

| Signal | Source | Role |
| --- | --- | --- |
| \(D_{\mathrm{structural}}\) | Group-normalized 20D shadow | Questionnaire/profile geometry |
| `phase_alignment` \(=\cos(\Delta\phi)\) | Tier-1 global activity oscillator | Compatible same-\(\omega\) phase agreement |
| `activity_level_gap` \(=\lvert A_u-A_v\rvert\) | Tier-1 scalar activity levels | Intensity difference |

These remain first-class. Quantum-inspired outputs sit **beside** them as additional shadow diagnostics only.

---

## 2. Hilbert space and pure state \(|\psi_u\rangle\)

### 2.1 Modeling Hilbert space (Tier-1 first)

For the **usable** Tier-1 global periodic activity oscillator, the natural complex degree of freedom is one relative phase on a shared \(\omega\).

Define a 2-dimensional modeling space \(\mathcal{H}_2=\mathrm{span}\{|0\rangle,|1\rangle\}\) (computational labels only — not “brain states”).

Given accepted Class-B provenance for user \(u\) on oscillator \(o\) (same \(T^\star,\omega,\mathrm{oscillator\_id}\), `periodicity_status=ok`):

\[
|\psi_u\rangle
=
\cos\!\Big(\frac{\theta_u}{2}\Big)\,|0\rangle
+
e^{i\phi_u}\sin\!\Big(\frac{\theta_u}{2}\Big)\,|1\rangle
\]

**Provisional mapping (must be stated explicitly if implemented):**

| Symbol | QMatch meaning | Gate |
| --- | --- | --- |
| \(\phi_u\) | Validated periodic phase on oscillator \(o\) | Required |
| \(\theta_u\) | Optional polar angle from a **normalized** activity feature | Only if a calibrated map exists; otherwise fix \(\theta_u=\pi/2\) (equator) so amplitude does **not** sneak into phase geometry |

**Default for v1 shadow (recommended):** use equatorial pure states so activity level stays out of \(|\psi\rangle\):

\[
|\psi_u\rangle
=
\frac{1}{\sqrt{2}}\Big(|0\rangle+e^{i\phi_u}|1\rangle\Big)
\qquad(\theta_u=\pi/2).
\]

Then

\[
\big|\langle\psi_u|\psi_v\rangle\big|^2=\cos^2(\Delta\phi/2),
\qquad
\mathrm{Re}\langle\psi_u|\psi_v\rangle=\cos(\Delta\phi/2)\quad\text{(gauge-dependent if global phase free).}
\]

Prefer reporting **overlap intensity** \(\lvert\langle\psi_u|\psi_v\rangle\rvert^2\) and keep Tier-1 `phase_alignment`\(=\cos(\Delta\phi)\) as the separate, already-frozen diagnostic.

**Normalization.** Always require \(\langle\psi_u|\psi_u\rangle=1\). If inputs needed for construction are missing → **do not emit** \(|\psi_u\rangle\) (unavailable), never fill.

### 2.2 Multi-mode pure state (research only)

Frequency 6D multi-mode Wave-State remains **research-only** until mode-specific oscillators exist (Amplitude Semantics v1). A candidate research pure state would look like

\[
|\Psi_u\rangle=\sum_{m=1}^{M}c_{u,m}\,|m\rangle,
\qquad
\sum_m |c_{u,m}|^2=1,
\]

with \(c_{u,m}\propto A_{u,m}e^{i\phi_{u,m}}\) **only when** each mode \(m\) has justified \(\phi_{u,m},\omega_{u,m}\).

**Forbidden today:** copying global activity \(\phi\) into all six Frequency modes to force a 6D \(|\Psi_u\rangle\).

### 2.3 Structural scores are not quantum amplitudes

The 20D structural vector \(\mu_u\in[0,1]^{20}\) is **classical**. It must not be silently reinterpreted as \(\lvert\langle k|\psi_u\rangle\rvert^2\) without an explicit, calibrated embedding contract. Structural information continues to live in \(D_{\mathrm{structural}}\).

---

## 3. Density matrix \(\rho_u\) — when justified

### 3.1 Definition and axioms

A density operator \(\rho_u\) on \(\mathcal{H}\) is justified only if it is a Hermitian PSD operator with unit trace:

\[
\rho_u=\rho_u^\dagger,
\qquad
\rho_u\ge 0,
\qquad
\mathrm{Tr}(\rho_u)=1.
\]

Any implementation **must verify** eigenvalues \(\lambda_i\ge 0\) and \(\sum_i\lambda_i=1\) (within numerical tolerance). Failure → unavailable, not “almost ρ”.

### 3.2 Pure-state density operator (always available when \(|\psi_u\rangle\) is)

If a normalized \(|\psi_u\rangle\) exists:

\[
\rho_u^{\mathrm{(pure)}}=|\psi_u\rangle\langle\psi_u|.
\]

This satisfies \(\rho\ge 0\), \(\mathrm{Tr}\rho=1\), and \(\mathrm{Tr}(\rho^2)=1\) (purity 1).

### 3.3 Mixed states — only with real mixing evidence

A mixed state

\[
\rho_u=\sum_k p_k\,|\psi_{u,k}\rangle\langle\psi_{u,k}|,
\qquad
p_k\ge 0,\ \sum_k p_k=1
\]

is justified **only** when the mixture has an operational QMatch meaning backed by data, for example:

| Candidate mixture source | Justified when | Not justified when |
| --- | --- | --- |
| Split-half / multi-window phase estimates | Multiple accepted Class-B estimates on the same oscillator with stated weights \(p_k\) (e.g. equal weight over windows) | Inventing \(p_k\) or \(\lambda\) “noise” |
| Ensemble over distinct accepted oscillators | Each oscillator separately accepted; mixture is explicit multi-oscillator uncertainty | Collapsing civil + spectral into one ρ without policy |
| Questionnaire response uncertainty | Calibrated likelihood over score embeddings exists | Treating missing answers as uniform mixing |
| Ad-hoc depolarizing \( (1-\lambda)\rho+\lambda I/d \) | \(\lambda\) fit on held-out behavioral outcomes | Any free \(\lambda\) without data |

**Hard rule:** Do **not** invent \(\lambda\), temperature, or decoherence rates in v1.

### 3.4 What “uncertainty / mixing” means in QMatch

In this model, mixing is **epistemic / evidential**, not physical decoherence:

| Phrase | Allowed meaning | Forbidden meaning |
| --- | --- | --- |
| Uncertainty | Incomplete or multi-estimate evidence about phase/oscillator | Quantum vacuum fluctuations in the person |
| Mixing | Convex combination of **accepted** alternative estimates | Random noise injected to “look quantum” |
| Purity \(\mathrm{Tr}(\rho^2)\) | Concentration of evidential mass on one estimate | Consciousness / entanglement metaphor |

If only one accepted estimate exists → use pure \(\rho^{\mathrm{(pure)}}\). If none → **missing** (no ρ).

### 3.5 Missing data policy

| Situation | Action |
| --- | --- |
| Omega not `ok` / civilCollision / ambiguous / sparse | No \(|\psi\rangle\), no \(\rho\) |
| Phase binder unavailable | No \(|\psi\rangle\), no \(\rho\) |
| Mode-specific φ missing for multi-mode research state | Omit that mode; if remaining set empty → unavailable |
| Structural dims missing | Affects \(D_{\mathrm{structural}}\) only; **never** impute into \(\rho\) |

**No fake state completion.** Unavailable is correct.

---

## 4. Pair diagnostics (shadow candidates)

Assume users \(u,v\) are **provenance-compatible** on the same oscillator (Wave Phase Reference Policy). Otherwise emit unavailable for quantum-inspired pair fields.

### 4.1 Pure-state overlap

\[
\mathcal{O}_{uv}=\big|\langle\psi_u|\psi_v\rangle\big|^2\in[0,1].
\]

Optional signed diagnostic (only with shared reference epoch / gauge):

\[
\mathcal{O}_{uv}^{\mathrm{(Re)}}=\mathrm{Re}\langle\psi_u|\psi_v\rangle.
\]

Prefer \(\mathcal{O}_{uv}\) as primary pure-state pair field. Keep Tier-1 `phase_alignment` separate.

### 4.2 Density-matrix fidelity

Uhlmann fidelity:

\[
F(\rho_u,\rho_v)
=
\Big(\mathrm{Tr}\sqrt{\sqrt{\rho_u}\,\rho_v\sqrt{\rho_u}}\Big)^2
\in[0,1].
\]

For pure states, \(F(|\psi_u\rangle\langle\psi_u|,|\psi_v\rangle\langle\psi_v|)=\lvert\langle\psi_u|\psi_v\rangle\rvert^2=\mathcal{O}_{uv}\).

### 4.3 Optional trace distance

\[
D_{\mathrm{tr}}(\rho_u,\rho_v)
=
\frac12\mathrm{Tr}\big|\rho_u-\rho_v\big|
\in[0,1].
\]

For pure states, \(D_{\mathrm{tr}}=\sqrt{1-\mathcal{O}_{uv}}\).

Trace distance is a **dissimilarity**; do not invert it into a marketing “match %”.

### 4.4 Wire separation (v1)

Recommended shadow fields (names provisional):

| Field | Type | Combined with structural/wave? |
| --- | --- | --- |
| `qi_state_overlap` | \(\mathcal{O}_{uv}\) or null | **No** |
| `qi_fidelity` | \(F(\rho_u,\rho_v)\) or null | **No** |
| `qi_trace_distance` | \(D_{\mathrm{tr}}\) or null | **No** |
| `qi_purity_u` / `qi_purity_v` | \(\mathrm{Tr}(\rho^2)\) diagnostics | **No** |

Status flags: `shadow_only=true`, `specification_only_not_live` until a shadow implementation lands; then `shadow_only_not_live`, still not Discover.

---

## 5. Explicit comparison

### A. Pure-state representation

| Pros | Cons |
| --- | --- |
| Matches current Tier-1 evidence (one accepted \(\phi_u\) per oscillator) | Does not encode multi-estimate uncertainty |
| Simple normalization; fidelity collapses to overlap | Easy to over-interpret as “the person is a wavefunction” |
| Natural companion to `phase_alignment` | Multi-mode pure states unsupported without mode oscillators |

**Best fit for first shadow code.**

### B. Mixed-state representation

| Pros | Cons |
| --- | --- |
| Can represent multiple accepted windows/oscillators | Requires real mixture weights from data |
| Purity becomes a meaningful evidence diagnostic | High abuse risk (fake \(\lambda\)) |
| Fidelity generalizes overlap | Numerically heavier; easy to hide imputation |

**Justified only after multi-estimate pipelines exist.**

### C. What current QMatch data actually supports

| Construct | Supported now? |
| --- | --- |
| Equatorial pure \(|\psi_u\rangle\) from accepted spectral \(\phi_u\) | **Yes** (when omega+phase binders `ok`) |
| Pure \(\rho_u=\lvert\psi_u\rangle\langle\psi_u\rvert\) | **Yes** (same gate) |
| Pair \(\mathcal{O}_{uv}\) / pure-state fidelity | **Yes** (compatible pairs) |
| Mixed \(\rho_u\) with calibrated \(p_k\) or \(\lambda\) | **No** |
| 6D Frequency \(|\Psi_u\rangle\) with mode-specific φ | **No** (research gate) |
| Structural→amplitude embedding into \(\mathcal{H}\) | **No** (not defined/calibrated) |
| Combining QI fields with \(D_{\mathrm{structural}}\) into one score | **Forbidden in this version** |

### D. What requires calibration / real behavioral data

1. Any map from activity level \(A_u\) into Bloch polar angle \(\theta_u\).
2. Mixture weights over split-half / multi-window estimates.
3. Any depolarizing or noise parameter \(\lambda\).
4. Predictive value of \(\mathcal{O}_{uv}\) vs `phase_alignment` vs \(D_{\mathrm{structural}}\) on real outcomes (reply quality, retention, mutual engagement) — **evaluation only**, not ranking yet.
5. Mode-specific oscillators before multi-mode QI states.

---

## 6. Physical vs modeling interpretation

| Quantum-info object | Modeling interpretation in QMatch | Not claimed |
| --- | --- | --- |
| \(\mathcal{H}\) | Abstract feature space for phase (and later modes) | Physical Hilbert space of a human |
| \(|\psi_u\rangle\) | Normalized encoding of accepted phase (and optional calibrated features) | Ontological “soul state” |
| \(\rho_u\) | Evidential mixture over accepted estimates | Thermal/quantum decoherence in cortex |
| Fidelity / overlap | Geometry of those encodings | Measurement of entanglement between people |
| Trace distance | Encoding dissimilarity | Physical distinguishability of brains |

---

## 7. Unsupported assumptions to avoid

1. Humans are physical quantum systems / entangled pairs.
2. Questionnaire Frequency ids are quantum mode occupations.
3. Missing evidence ⇒ maximally mixed \(I/d\).
4. Free \(\lambda\) “to add uncertainty”.
5. Copying one global \(\phi\) into six modes to unlock multi-mode QI.
6. Persona / archetype as quantum labels.
7. RVI or density-matrix ranking in Discover.
8. Fusing `qi_fidelity` with \(D_{\mathrm{structural}}\) or `phase_alignment` into one live score in this version.
9. Gauge-fixing unanchored phases to force overlap.
10. Marketing “quantum match %” from fidelity.

---

## 8. Recommended first shadow implementation

**Status target after code exists:** `shadow_only_not_live` (still not Discover).  
**This document:** `specification_only_not_live`.

### Step 1 (recommended first code) — pure-state Tier-1 QI shadow

1. Inputs: accepted `ActivitySpectralOmegaEstimate` + `ValidatedPeriodicPhaseEstimate` for \(u,v\); shared epoch; compatibility gate.
2. Build equatorial \(|\psi_u\rangle,|\psi_v\rangle\) (§2.1 default).
3. Emit `qi_state_overlap` \(=\lvert\langle\psi_u|\psi_v\rangle\rvert^2\) and optional `qi_fidelity` (identical for pure states).
4. Optional `qi_trace_distance` \(=\sqrt{1-\mathcal{O}_{uv}}\).
5. Keep emitting existing separate fields: \(D_{\mathrm{structural}}\), `phase_alignment`, `activity_level_gap`.
6. **Do not** combine; **do not** Discover; **no** Persona/RVI.

### Step 2 (later, data-gated) — mixed ρ

Only when multi-window or multi-estimate accepted sets exist with explicit \(p_k\).

### Step 3 (research) — multi-mode QI

Only after mode-specific oscillators clear Amplitude Semantics Tier-2 gates.

### Explicit non-goals for first implementation

- No structural vector embedded into \(\mathcal{H}\)
- No \(\lambda\) noise channel
- No live ranking
- No density-matrix mystique in product UI

---

## 9. Acceptance checks for any future implementation PR

- [ ] `specification` → code remains `shadow_only`; Discover untouched
- [ ] \(\rho\ge 0\), \(\mathrm{Tr}\rho=1\) asserted in tests
- [ ] Missing omega/phase → unavailable (no imputation)
- [ ] Compatible-pair gates reused from Wave Phase Reference Policy
- [ ] Wire keeps QI fields separate from structural/wave fields
- [ ] Docs/tests state “quantum-inspired formalism”, not physical quantum humans
- [ ] No Persona / RVI / density-matrix ranking

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-12 | Initial specification after structural-vs-wave separation and amplitude-semantics freeze |
