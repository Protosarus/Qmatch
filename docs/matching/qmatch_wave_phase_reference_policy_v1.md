# QMatch Wave-State Phase Reference Policy v1

| Field | Value |
| --- | --- |
| Policy id | `wave_phase_reference_policy_v1` |
| Status | `specification_only_not_live` |
| Scope | When phase is scientifically comparable for Wave-State Modal Shadow |
| Depends on | [Modal Resonance Model v1](./qmatch_modal_resonance_model_v1_specification.md), [Temporal Observation Contract v1](./qmatch_temporal_observation_contract_v1.md), [Temporal Feature Extraction v1](./qmatch_temporal_feature_extraction_v1.md), implemented `wave_state_modal_shadow_v1` |
| Explicitly out of scope | Production code changes, Discover ranking/UI, Persona, RVI, density-matrix/fidelity layers, questionnaire→phase maps, fabricating or gauge-fixing unanchored phase into signed overlap |

---

## 0. Purpose and scientific posture

`wave_state_modal_shadow_v1` defines

\[
\Psi_u(s,t)
=\sum_m A_{u,m}\,e_m(s)\,
\exp\bigl(i(\omega_{u,m}\,t+\phi_{u,m})\bigr)
\]

and a normalized complex overlap whose **signed real part** is production `r_wave`.

Synthetic stress (`wave_state_modal_shadow_stress_v1`) showed:

1. **Global relative phase** multiplies the complex overlap by \(e^{i\alpha}\).  
   Then \(\mathrm{Re}\) becomes \(\lvert\langle\Psi_a|\Psi_b\rangle\rvert\cos(\alpha+\theta)\), while \(\lvert\langle\Psi_a|\Psi_b\rangle\rvert\) is invariant.
2. **Exact opposition** (\(\Delta\phi=\pi\)) yields `r_wave = -1` but \(\lvert\langle\cdot\rangle\rvert = 1\) — magnitude alone cannot see opposition.
3. Therefore signed overlap is meaningful **only** when the phase reference is scientifically comparable — not when \(\phi\) is an arbitrary latent angle.

This policy defines **when** \(\phi\) (and thus signed wave overlap) is allowed, and when only magnitude diagnostics may be reported.

**Non-goals**

- Not a claim that humans are physical oscillators or quantum systems.
- Not permission to invent \(\phi\) from Frequency questionnaire scores \(\mu_m\).
- Not a Discover ranking change.
- Not a license to “gauge-fix” unanchored phases into a fake signed score.

---

## 1. Phase classes

### Class A — Externally anchored phase

Phase is measured against an **external, shared physical/civil reference** that both subjects can be mapped into without an arbitrary global rotation.

**Canonical example:** circadian 24h phase referenced to **local civil clock time**

- Oscillator: fixed period \(T=24\,\mathrm{h}\)
- Reference: local solar/civil day (with explicit timezone / time basis)
- \(\phi\) is wall-clock position on that day cycle

**Property:** a global phase difference between people is **meaningful** (e.g. night-owl vs early-bird offset).  
**Rule:** such \(\Delta\phi\) **must NOT** be removed by a free U(1) gauge fix before signed overlap.

Other external anchors (only if equally well-defined):

| Oscillator id (examples) | External reference |
| --- | --- |
| `circadian_24h` | Local civil time-of-day |
| `weekly_7d` | Local civil day-of-week (requires timezone + week basis) |
| calendar-tied seasonal cycles | Explicit civil calendar definition (rare; must be documented) |

### Class B — Validated periodic phase

Phase on a **demonstrated periodic component** that is not necessarily civil-clock, but is still scientifically comparable across people **when provenance matches**.

Required shared definition (all must match for pairwise use):

1. Same `oscillator_id`
2. Same period / frequency definition \(T\) or \(\omega=2\pi/T\)
3. Same **common reference epoch** \(t_0\) (or an equivalent absolute phase zero)
4. Compatible **time basis** (UTC vs local; sampling clock; units)

Examples (future estimators — not live):

- Spectral peak with gated SNR and stable period across sub-windows, with phase reported relative to a stated epoch
- Lag→phase conversion \(\Delta\phi=2\pi\tau^*/T\) **only** when \(T\) comes from a Class A or Class B oscillator already validated

**Property:** signed \(\Delta\phi\) is meaningful **inside that oscillator’s reference frame**.  
**Rule:** do not compare Class B phases across different `oscillator_id`, periods, epochs, or incompatible time bases.

### Class C — Unanchored / arbitrary latent phase

Any \(\phi\) that lacks an external anchor **and** lacks a validated shared periodic reference frame.

Includes:

- Free complex latent angles with no `oscillator_id`
- Phases invented to “fill” Wave-State inputs
- Questionnaire-derived “phase”
- Per-person spectral phases with **different** periods/epochs silently treated as comparable
- Absolute person phase without stated zero

**Property:** overall relative phase between two Wave-States is a **gauge** (unobservable).  
**Rule:** signed \(\mathrm{Re}\) overlap is **`unavailable`**. Do **not** fabricate phase, and do **not** gauge-fix Class C into a signed score that is then treated as scientific resonance.

Magnitude \(\lvert\langle\Psi_a|\Psi_b\rangle\rvert\) (and optionally its square) may still be emitted as **diagnostics only**, with explicit labeling that they discard opposition sign and are not ranking signals.

---

## 2. Compatibility rules (pairwise)

Let person \(P\) and \(Q\) each carry phase metadata on mode \(m\) (or on a shared oscillator used for that mode).

### 2.1 Compatible phase reference (allows signed comparison)

All of the following must hold for every mode included in a **signed** wave overlap:

| Check | Rule |
| --- | --- |
| Class | Both sides Class A or both Class B (same class family as defined below) |
| `oscillator_id` | Identical string |
| Period / \(\omega\) | Same definition within tolerance policy (exact match for civil oscillators; gated equality for spectral \(T\)) |
| `reference_epoch` | Identical for Class B; Class A uses the civil anchor implied by `time_basis` (no free epoch) |
| `time_basis` | Compatible (e.g. both `local_civil` with known TZ, or both `utc` with stated meaning) |
| Quality | Both sides meet minimum periodicity / concentration status (`ok`, or `sparse` only if policy explicitly allows sparse signed use — default: signed requires `ok`) |
| Mode set | Signed sum only over modes that are **complete and compatible**; never mix compatible and incompatible modes in one silent `r_wave` |

**Class mixing**

- Class A ↔ Class A (same `oscillator_id`) → allowed when time basis compatible  
- Class B ↔ Class B (same `oscillator_id`, epoch, period, time basis) → allowed  
- Class A ↔ Class B → **forbidden** unless an explicit documented equivalence map exists (none in v1)  
- Any involvement of Class C → signed overlap **unavailable**

### 2.2 Incompatible → no signed overlap

If any required check fails:

- `r_wave` / signed normalized Re → `unavailable` with reason code (examples below)
- Do not default \(\phi=0\), do not align global phase to maximize Re, do not impute from \(\mu_m\)

Suggested reason codes:

| Code | Meaning |
| --- | --- |
| `missing_phase_metadata` | Required provenance fields absent |
| `incompatible_oscillator_id` | Oscillator ids differ |
| `incompatible_period` | Period/\(\omega\) definitions differ |
| `incompatible_reference_epoch` | Epoch mismatch (Class B) |
| `incompatible_time_basis` | UTC/local/TZ basis mismatch |
| `phase_quality_insufficient` | Periodicity/concentration below gate |
| `unanchored_phase` | Class C detected |
| `questionnaire_phase_forbidden` | Phase claimed from Frequency scores |

### 2.3 Amplitude and \(\omega\) remain separate gates

This policy governs **phase comparability**. Wave-State still requires explicit \(A_m\) and explicit \(\omega_m\) (or period) per its own contract. Passing phase-reference checks does **not** allow fabricating missing amplitude or omega.

---

## 3. When signed overlap is valid

Signed normalized overlap

\[
r_{\mathrm{wave}}
=
\mathrm{Re}
\frac{\langle\Psi_P|\Psi_Q\rangle}
{\lVert\Psi_P\rVert\,\lVert\Psi_Q\rVert}
\]

is **valid to report** only when:

1. Every mode in the comparable set \(M_{PQ}\) has explicit \(A,\phi,\omega\) (Wave-State completeness), **and**
2. Every such mode’s \(\phi\) is Class A or Class B with **pairwise-compatible** provenance (§2), **and**
3. Periodicity quality meets the signed-use gate, **and**
4. No Class C or questionnaire-derived phase is included.

**Externally anchored (Class A) special rule**

- Global \(\Delta\phi\) is retained.  
- **Forbidden:** multiplying one state by \(e^{-i\alpha}\) to force \(\mathrm{Re}=\lvert\langle\cdot\rangle\rvert\) before reporting signed resonance.

**Validated periodic (Class B) special rule**

- Signed \(\Delta\phi\) is relative to the shared epoch/period.  
- Changing epoch is a definition change, not a free gauge cleanup after the fact.

---

## 4. When magnitude-only is allowed

Define diagnostic magnitudes (shadow-only, not ranking):

\[
c_{\mathrm{abs}}
=
\left\lvert
\frac{\langle\Psi_P|\Psi_Q\rangle}
{\lVert\Psi_P\rVert\,\lVert\Psi_Q\rVert}
\right\rvert
,\qquad
c_{\mathrm{abs}}^{2}
=
c_{\mathrm{abs}}^{2}.
\]

### Allowed as diagnostics when

- Wave-State amplitudes (and, if used in \(\Psi(t)\), omegas) are explicit and comparable, **and**
- The consumer labels outputs as **diagnostic only**, **and**
- Signed `r_wave` is either also present (when valid) or explicitly `unavailable`.

### Typical uses

- Dephasing envelope under differing \(\omega\) across modes  
- Coverage / stability checks  
- Stress and offline analysis (as in `wave_state_modal_shadow_stress_v1`)

### Not allowed to mean

- “Phase-aligned match” (magnitude confuses identity with opposition)  
- A substitute ranking score for Discover  
- Proof that Class C phases were “fixed” into meaning  

### Gauge-fixing policy

- **Class A:** do not gauge-remove.  
- **Class B:** do not re-zero epoch ad hoc per pair.  
- **Class C:** do not gauge-fix to create signed Re; if only magnitudes are computable from synthetic latents in lab harnesses, keep them lab-only and never promote to product resonance.

---

## 5. Required phase metadata

Every phase value eligible for Wave-State signed use MUST carry provenance. Minimal wire/object fields:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `oscillator_id` | string | **yes** | e.g. `circadian_24h`, `weekly_7d`, or a validated spectral id |
| `phase_radians` | float | **yes** | \(\phi\in\mathbb{R}\); prefer principal value in \([0,2\pi)\) when published |
| `omega` **or** `period_seconds` | float | **yes** (one of) | Must match oscillator definition; civil oscillators use fixed \(T\) |
| `reference_epoch` | timestamp / string | **yes for Class B**; Class A uses civil anchor via time basis | Absolute zero of phase for that oscillator |
| `time_basis` | enum/string | **yes** | e.g. `local_civil`, `utc`; document units |
| `timezone` | string / offset | **yes if** `time_basis=local_civil` | Missing TZ → circadian Class A phase unavailable |
| `periodicity_quality` / `status` | enum | **yes** | `ok` \| `sparse` \| `unavailable` (and optional SNR / \(\bar R\) diagnostics) |
| `phase_class` | enum | **yes** | `external_anchored` \| `validated_periodic` \| `unanchored` |
| `mode_id` | string | **yes** when phase is mode-scoped | Frequency mode id or explicit `timing_only` oscillator attachment |
| `source` | string | recommended | estimator id / feature version — never `questionnaire` |

### Forbidden provenance

- `source = questionnaire` / Frequency \(\mu_m\mapsto\phi_m\)
- Missing `oscillator_id`
- `phase_class = unanchored` used in signed `r_wave`
- Silent defaults: \(\phi=0\), \(\omega=\mu\), UTC-as-local

### Circadian Class A profile (normative example)

```text
oscillator_id: circadian_24h
phase_class: external_anchored
period_seconds: 86400
omega: 2π / 86400
reference_epoch: implied by local civil midnight (via time_basis)
time_basis: local_civil
timezone: <IANA or offset; required>
periodicity_quality: from concentration gate (e.g. circadian R̄)
phase_radians: circular mean of local event times
```

---

## 6. Interaction with Wave-State v1 (no production change)

Current `wave_state_modal_shadow_v1`:

- Accepts explicit \(A,\phi,\omega\) maps without provenance objects
- Emits signed `r_wave` whenever complete numeric inputs exist

**Policy stance for v1 code (unchanged):** treat naked \(\phi\) without metadata as **operationally Class C** for scientific interpretation. Lab/synthetic tests may still exercise the math; product-facing signed resonance remains unjustified until provenance lands.

This document does **not** modify production code.

---

## 7. Recommended Wave-State v2 contract

Target version id (recommended): `wave_state_modal_shadow_v2`  
Policy status until implemented: `specification_only_not_live`

### 7.1 Input contract

Per mode (or per oscillator attachment):

```text
WaveStateModeV2 {
  mode_id
  amplitude?                  # still allow Frequency-measured A
  phase?: PhaseReferenceV2    # NOT a bare float
  omega? / period_seconds?
}

PhaseReferenceV2 {
  oscillator_id
  phase_radians
  omega | period_seconds
  reference_epoch             # required for validated_periodic
  time_basis
  timezone?                   # required for local_civil
  periodicity_quality/status
  phase_class                 # external_anchored | validated_periodic | unanchored
  source
}
```

### 7.2 Output contract

```text
r_wave                      # signed Re; available ONLY if §3 satisfied
r_wave_unavailable_reason?  # policy reason codes from §2.2
c_abs                       # |normalized overlap|; diagnostic_only=true
c_abs_sq                    # optional diagnostic
phase_compatibility         # compatible | incompatible | unanchored | insufficient_quality
structural_distance_coupled = false
shadow_only = true
live_discover_ranking = false
```

### 7.3 Computation rules (v2)

1. Build comparable mode set with Wave-State completeness **and** phase-reference compatibility.  
2. If compatible Class A/B set non-empty and norms \(>0\) → compute `r_wave` and diagnostics.  
3. If only amplitudes (+ optional ω) comparable but phase Class C / incompatible → `r_wave=unavailable`; optionally still compute `c_abs` **only if** inputs are not pretending to be product phase (prefer withholding product `c_abs` until policy freeze).  
4. Never gauge-fix Class A; never promote Class C via gauge-fix.  
5. Keep structural distance separate; no Persona / RVI / density-matrix layer.

### 7.4 Estimator prerequisites before freezing v2

- Circadian Class A path with TZ-required gates (already sketched in temporal extraction docs)  
- Explicit refusal of questionnaire phase  
- Pairwise compatibility checker as a pure domain function with unit tests  
- Shadow diagnostics only; Discover remains untouched

---

## 8. Summary table

| Phase class | Global Δφ meaningful? | Signed `r_wave` | Magnitude diagnostic | Gauge-fix allowed? |
| --- | --- | --- | --- | --- |
| External anchored (A) | **Yes** | If compatible + quality ok | Yes (diagnostic) | **No** |
| Validated periodic (B) | Yes, within shared epoch/period | If fully compatible | Yes (diagnostic) | **No** (no ad hoc re-epoch) |
| Unanchored (C) | No | **Unavailable** | Lab/diagnostic only; not product resonance | **No** (must not create fake signed meaning) |

---

## 9. Prohibitions (normative)

1. No generic \(\phi\) without provenance.  
2. No questionnaire-derived phase.  
3. No signed wave overlap across incompatible references.  
4. No gauge-removal of externally anchored phase.  
5. No Discover / Persona / RVI / density-matrix changes under this policy.  
6. No production code change required to publish this document.

---

## 10. Document control

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-11 | Initial policy from Wave-State stress findings + temporal oscillator requirements |
