# Modal Resonance Model v1 — Mathematical Specification

| Field | Value |
| --- | --- |
| Model id | `modal_resonance_model_v1` |
| Status | `specification_only_not_live` — **not** an L5 v1 retained candidate |
| Scope | Shadow-only specification. **No production code. No Discover ranking/UI.** |
| Structural peer | Group-normalized 20D production-candidate (`production_candidate_not_live`) |
| Prohibited | Quantum fidelity, density matrices, RVI, Persona-as-matching-key, fabricated phase/ω |

---

## 0. Purpose and scientific posture

This document defines a **string-inspired / oscillatory latent-state model** for a
*modal* (dynamic) layer that sits **beside**, not inside, structural Matching.

It is:

- a mathematical latent-state and overlap specification
- compatible with later behavioral time series
- honest about what questionnaire Frequency 6D can and cannot support

It is **not**:

- string theory
- a claim that humans are physical strings or quantum systems
- physical quantum behavior
- a license to invent phase, angular frequency, or temporal signals from static scores

**Naming note.** Product “Frequency 6D” means *relational rhythm / tempo preference
dimensions*. It must **not** be treated as physical frequency \(\omega\) unless and
until temporal observations estimate \(\omega\).

---

## A. State representation

### A.1 Static 20D structural vector

Let the canonical registry order be:

\[
\mathcal{I} = \text{IQ }(4),\quad
\mathcal{E} = \text{EQ }(10),\quad
\mathcal{F} = \text{Frequency }(6),\quad
|\mathcal{I}\cup\mathcal{E}\cup\mathcal{F}|=20.
\]

Canonical Frequency ids (order fixed):

1. `depth_preference`
2. `social_energy`
3. `spontaneity`
4. `stability`
5. `disclosure_pace`
6. `communication_pace`

For person \(P\), the **structural state** is the measured score vector

\[
\boldsymbol{\mu}^{(P)} \in [0,1]^{20}
\]

with per-dimension measurement gate (measured + finite + in \([0,1]\)). Missing
dimensions are **absent**, never imputed.

Structural Matching remains:

\[
D_{\mathrm{structural}}(\,P,Q\,)
\quad\text{(group-normalized per-module MSE; existing production-candidate).}
\]

This document does **not** redefine \(D_{\mathrm{structural}}\).

### A.2 6D Frequency modal state

The **modal layer** uses only the Frequency subset:

\[
\boldsymbol{\mu}_{\mathcal{F}}^{(P)}
=
\bigl(\mu_m^{(P)}\bigr)_{m\in\mathcal{F}}
\in [0,1]^{6}.
\]

Interpret \(\mu_m\) as a **static modal amplitude prior** (preference intensity /
engagement prior for mode \(m\)), **not** as phase and **not** as \(\omega_m\).

### A.3 Amplitude definition (static / questionnaire-supported)

For each modal dimension \(m\in\mathcal{F}\):

\[
A_m^{(P)}
\;\triangleq\;
\begin{cases}
\mu_m^{(P)} & \text{if } m \text{ is measured for } P,\\
\text{unavailable} & \text{otherwise.}
\end{cases}
\]

Optional energy view (same information, useful for overlap normalization):

\[
E_m^{(P)} = \bigl(A_m^{(P)}\bigr)^{2}
\quad\text{(only when } A_m \text{ available).}
\]

**Justification for using Frequency 6D as amplitudes/priors only**

- Questionnaire items ask about preferred depth, energy, pace, etc. — intensities /
  relative emphases in preference space.
- They do **not** observe oscillation timing, cycle rate, or relative phase between
  people.
- Therefore \(\mu_m \mapsto A_m\) is the only map allowed under current data.
  Maps \(\mu_m\mapsto\phi_m\) or \(\mu_m\mapsto\omega_m\) are **forbidden**.

### A.4 Normalization

Let \(M_{PQ}\subseteq\mathcal{F}\) be the set of modes measured on **both** \(P\)
and \(Q\) (comparable modal set). If \(M_{PQ}=\emptyset\), modal resonance is
**unavailable**.

Define the comparable amplitude vectors

\[
\mathbf{A}_{PQ}^{(P)} = (A_m^{(P)})_{m\in M_{PQ}},\quad
\mathbf{A}_{PQ}^{(Q)} = (A_m^{(Q)})_{m\in M_{PQ}}.
\]

L2 unit normalization over the comparable set (no padding of missing modes):

\[
\hat{\mathbf{A}}^{(P)}
=
\frac{\mathbf{A}_{PQ}^{(P)}}
{\lVert\mathbf{A}_{PQ}^{(P)}\rVert_2},
\quad
\hat{\mathbf{A}}^{(Q)}
=
\frac{\mathbf{A}_{PQ}^{(Q)}}
{\lVert\mathbf{A}_{PQ}^{(Q)}\rVert_2},
\]

provided both norms are \(>0\). If either norm is \(0\) (all comparable amplitudes
exactly \(0\)), resonance is **unavailable** (zero vector is not a valid modal
prior for overlap).

Coverage diagnostics (not a score):

\[
c_{\mathrm{modal}}
=
\frac{|M_{PQ}|}{6},\qquad
c_{\mathrm{modal}}\in[0,1].
\]

---

## B. Temporal extension (future)

### B.1 Complex modal state

When temporal observations exist, each mode may carry a complex state

\[
z_m(t) = A_m(t)\,e^{i\,\phi_m(t)} \in \mathbb{C},
\]

with instantaneous angular rate

\[
\omega_m(t) = \frac{d\phi_m}{dt}.
\]

Static questionnaire amplitudes are the **initial prior** only:

\[
A_m(t_0) \leftarrow A_m^{\mathrm{(questionnaire)}}
\quad\text{(if measured); else unavailable.}
\]

\(\phi_m(t_0)\) and \(\omega_m(t_0)\) remain **unavailable** until temporal
estimators exist. Do **not** set \(\phi=0\) or \(\omega=\mu\) as defaults.

### B.2 What future behavioral signals could estimate

These are **candidate observation channels**, not implemented sensors:

| Target | Candidate behavioral signals (examples) | Notes |
| --- | --- | --- |
| \(A_m(t)\) | Session engagement intensity per rhythm facet; reply length/depth for `depth_preference`; social initiation rate for `social_energy`; schedule variance for `spontaneity`; consistency of contact for `stability`; disclosure rate for `disclosure_pace`; message cadence for `communication_pace` | May refine or replace questionnaire prior; still an intensity, not \(\omega\) |
| \(\phi_m(t)\) | Relative timing within a dyad: who leads/lags in turn-taking; offset between preferred contact windows; lag of emotional disclosure relative to partner | Requires **paired** or clocked events; absolute phase is gauge-dependent — prefer \(\Delta\phi\) |
| \(\omega_m(t)\) | Spectral / period estimates from contact timestamps, typing/send intervals, check-in periodicity, circadian alignment of activity | Needs irregular-time series methods; confidence bounds mandatory |

**Estimator requirements (when implemented later)**

- Explicit observation window and sampling assumptions
- Uncertainty / coverage, not point estimates alone
- No backfill of \(\phi,\omega\) from static \(\mu\)
- Dyadic \(\Delta\phi\) preferred over absolute \(\phi\) when only relative timing exists

---

## C. Pairwise resonance

Modal resonance \(R_{\mathrm{modal}}\) is a **normalized overlap** in \([-1,1]\)
when defined, else `unavailable`. Higher means more aligned modal content under the
chosen form. It is **not** a similarity percentage for UI and **not** combined with
\(D_{\mathrm{structural}}\) in v1.

### C.1 Phase-unavailable form (supported by current QMatch data)

When phases are unavailable (today’s default):

\[
R_{\mathrm{modal}}^{\mathrm{(amp)}}(P,Q)
=
\hat{\mathbf{A}}^{(P)}\cdot\hat{\mathbf{A}}^{(Q)}
=
\sum_{m\in M_{PQ}}
\hat{A}_m^{(P)}\,\hat{A}_m^{(Q)}
\in [-1,1]
\]

but with \(A_m\in[0,1]\) the cosine is in \([0,1]\) for this amplitude construction.

Properties:

- Symmetric: \(R(P,Q)=R(Q,P)\)
- Bounded
- Uses only shared measured modes
- No imputation, no fake phase

**Equal-amplitude alternative (diagnostic only, not primary):**
unnormalized mean absolute amplitude agreement is rejected for the primary
definition because it confuses coverage with alignment. Cosine on comparable
amplitudes is the v1 primary phase-unavailable form.

### C.2 Phase-sensitive form (requires temporal \(\phi\) or \(\Delta\phi\))

When for every \(m\in M_{PQ}\) both amplitudes and phases (or dyadic phase
differences) are available, define complex modal coordinates

\[
z_m^{(P)} = \hat{A}_m^{(P)}\,e^{i\phi_m^{(P)}},
\quad
z_m^{(Q)} = \hat{A}_m^{(Q)}\,e^{i\phi_m^{(Q)}}.
\]

Normalized Hermitian overlap (real part = phase-sensitive resonance):

\[
R_{\mathrm{modal}}^{\mathrm{(phase)}}(P,Q)
=
\mathrm{Re}
\sum_{m\in M_{PQ}}
z_m^{(P)}\,\overline{z_m^{(Q)}}
=
\sum_{m\in M_{PQ}}
\hat{A}_m^{(P)}\,\hat{A}_m^{(Q)}
\cos\bigl(\Delta\phi_m\bigr),
\]

where \(\Delta\phi_m=\phi_m^{(P)}-\phi_m^{(Q)}\) (mod \(2\pi\)).

Because \(\hat{\mathbf{A}}\) are unit-normalized over \(M_{PQ}\),

\[
R_{\mathrm{modal}}^{\mathrm{(phase)}} \in [-1,1].
\]

If only a subset \(M_{PQ}^{\phi}\subset M_{PQ}\) has phase, **do not** mix forms
silently:

- either restrict the sum to \(M_{PQ}^{\phi}\) and renormalize amplitudes on that
  subset, reporting `phase_coverage = |M_{PQ}^{φ}|/6`, or
- mark phase-sensitive resonance `unavailable` and fall back to
  \(R_{\mathrm{modal}}^{\mathrm{(amp)}}\) as a separate field.

v1 recommendation: emit **both** fields when applicable —

- `r_modal_amplitude` (phase-unavailable)
- `r_modal_phase` (phase-sensitive, else unavailable)

Never overwrite amplitude resonance with a fake phase-sensitive value.

### C.3 Instantaneous frequency (optional future diagnostic)

If \(\omega_m\) estimates exist for both people on mode \(m\), a **separate**
rate-agreement diagnostic may be defined later, e.g.

\[
\rho_m^{\omega}
=
\exp\bigl(-\kappa\,|\omega_m^{(P)}-\omega_m^{(Q)}|\bigr),
\]

but \(\rho^{\omega}\) is **not** part of \(R_{\mathrm{modal}}\) in v1 and must not
be derived from questionnaire \(\mu_m\).

---

## D. Missing-data rules

| Situation | Rule |
| --- | --- |
| Mode missing on either side | Exclude from \(M_{PQ}\); never impute \(0/0.5/50\) |
| \(M_{PQ}=\emptyset\) | `r_modal_* = unavailable` |
| \(\lVert\mathbf{A}\rVert_2=0\) on a side | `unavailable` (degenerate) |
| Phase missing | Do **not** set \(\phi=0\); phase-sensitive form unavailable |
| \(\omega\) missing | Do **not** set \(\omega=\mu\) or any questionnaire map; ω diagnostics unavailable |
| Partial phase | No silent blend; see C.2 |
| Structural dims missing | Irrelevant to modal layer except that Frequency subset still follows measurement gates |

Wire-facing result should include:

- `available` / per-form availability flags
- `comparable_mode_count`, `modal_coverage`
- `scoring_version = modal_resonance_model_v1`
- `policy_status = specification_only_not_live`
- `phase_fabricated = false`, `omega_fabricated = false` (invariants)

---

## E. Relationship to structural Matching

Keep **separate outputs**:

\[
\boxed{
D_{\mathrm{structural}}(P,Q)
\quad\text{and}\quad
R_{\mathrm{modal}}(P,Q)
}
\]

v1 **does not** define

\[
S = f(D_{\mathrm{structural}}, R_{\mathrm{modal}}).
\]

Rationale:

- Structural distance answers “how close are preference/trait coordinates?”
- Modal resonance answers “how aligned are rhythm-mode amplitudes (and later
  phases)?”
- Premature fusion hides failure modes and invites UI misuse

Frequency 6D already influences \(D_{\mathrm{structural}}\) via the Frequency
module weight \(0.466667\). \(R_{\mathrm{modal}}\) is an **additional diagnostic /
future dynamic layer**, not a double-count replacement until a later policy
explicitly redesigns fusion.

Equal-20D remains baseline-only. Legacy `CompatibilityScoring` remains live.
Persona / quantum / RVI stay out of this modal core.

---

## F. Scientific boundaries and safeguards

### F.1 What this is

- String-**inspired** metaphor: modes with amplitude (and later phase) as a
  **latent oscillatory state** useful for organizing temporal relational rhythms
- A classical complex-valued latent model when phase exists
- A cosine amplitude overlap when phase does not

### F.2 What this is not

- Not string theory; no Calabi–Yau, no Planck-scale claims, no physics authority
- Not physical quantum behavior; no \(\hbar\), entanglement claims, or particle analogy
- Not quantum Matching: **no** fidelity, density matrix, POVMs, or RVI in v1
- Not a biological claim that brains “vibrate” at Frequency-6D rates

### F.3 Safeguards

1. **Lexical firewall:** never label questionnaire \(\mu_m\) as \(\omega_m\) or “Hz”
2. **Fabrication firewall:** CI/tests must reject any default \(\phi=0\) / \(\omega=\mu\) path
3. **Separation firewall:** `D_structural` and `R_modal` remain distinct wire fields
4. **Status firewall:** `specification_only_not_live` until a later shadow
   implementation policy and then a live policy
5. **Metaphor hygiene:** product copy must not claim humans are strings or quantum
   systems if/when UI ever surfaces modal language

### F.4 Known scientific risks

| Risk | Mitigation |
| --- | --- |
| Reifying metaphor as physics | Explicit non-claims in this spec and future UI copy review |
| Double-counting Frequency in structure + modal | Keep fusion undefined; document overlap; later ablations |
| Pseudophase from static scores | Forbidden maps; unavailable states |
| Overfitting ω from sparse chat timestamps | Require coverage/uncertainty; withhold score when thin |
| Rank contamination of Discover | No Discover wiring under this status |

---

## G. Version / status

| Key | Value |
| --- | --- |
| `model_id` | `modal_resonance_model_v1` |
| `scoring_version` (future code) | `modal_resonance_model_v1` |
| `policy_status` | `specification_only_not_live` |
| Production code | **None** (this document only) |
| Discover ranking/UI | **Unchanged / not permitted to consume** |

### Recommended first shadow implementation (when coding is later authorized)

1. Implement **amplitude-only** \(R_{\mathrm{modal}}^{\mathrm{(amp)}}\) over shared
   Frequency 6D measured scores
2. Emit coverage + unavailable correctly; no phase/ω fields except explicit null /
   unavailable
3. Attach as **offline / shadow diagnostic parallel** to structural distance — not
   ranking
4. Golden tests: identical amplitudes → \(R=1\); orthogonal support patterns;
   missing-mode omission; symmetry; reject fabricated phase
5. Defer phase-sensitive form until a temporal observation contract exists

---

## Appendix — Variable dictionary

| Symbol | Meaning |
| --- | --- |
| \(\boldsymbol{\mu}\) | Canonical 20D structural measured scores in \([0,1]\) |
| \(\mathcal{F}\) | Frequency 6D id set |
| \(A_m\) | Modal amplitude prior for mode \(m\) |
| \(\hat{A}_m\) | L2-normalized amplitude on comparable set |
| \(M_{PQ}\) | Shared measured Frequency modes |
| \(z_m(t)\) | Complex modal state \(A_m(t)e^{i\phi_m(t)}\) |
| \(\phi_m(t)\) | Modal phase (temporal only) |
| \(\omega_m(t)\) | Instantaneous angular rate \(d\phi_m/dt\) (temporal only) |
| \(\Delta\phi_m\) | Dyadic phase difference |
| \(D_{\mathrm{structural}}\) | Group-normalized structural distance |
| \(R_{\mathrm{modal}}^{\mathrm{(amp)}}\) | Phase-unavailable modal resonance |
| \(R_{\mathrm{modal}}^{\mathrm{(phase)}}\) | Phase-sensitive modal resonance |
| \(c_{\mathrm{modal}}\) | Modal coverage \(\lvert M_{PQ}\rvert/6\) |
