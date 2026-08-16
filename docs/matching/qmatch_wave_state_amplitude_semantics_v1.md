# QMatch Wave-State Amplitude Semantics v1

| Field | Value |
| --- | --- |
| Policy id | `wave_state_amplitude_semantics_v1` |
| Status | `shadow_only_not_live` — L4 v1: Tier 1 is **research shadow** (not production-promoted). Tier 2 multi-mode is **research-only, rejected from L5 v1**. |
| Purpose | Freeze two distinct Wave-State tiers after periodic resonance stress |
| Depends on | Wave Phase Reference Policy v1, Activity Spectral Omega v1, Validated Periodic Phase Binder v1, Wave-State Modal Shadow v1/v2 |
| Explicitly out of scope | Discover ranking, Persona, RVI, density-matrix, copying global activity φ into Frequency 6D |

---

## 0. Why this freeze exists

Stress on `PeriodicWaveStateResonanceAdapter` showed that under compatible same-ω gates:

\[
r_{\mathrm{wave}}=\cos(\Delta\phi)\cdot\cos\angle(A,B),\qquad
c_{\mathrm{abs}}=|\cos\angle(A,B)|
\]

So fused multi-amplitude \(r_{\mathrm{wave}}\) mixes **phase alignment** with **envelope geometry**, and \(c_{\mathrm{abs}}\) is **phase-blind**. That is not acceptable as a single “resonance” score for the global activity oscillator.

This policy separates tiers.

---

## 1. Tier 1 — Global periodic activity oscillator (L4 **research shadow**)

Not an L4 v1 production diagnostic. `phase_alignment` and activity amplitude stay research-only until a real cohort + calibrated gates exist.

### 1.1 State

For user \(u\):

\[
z_u(t)=A_u\exp\!\big(i(\omega t+\phi_u)\big)
\]

where \(\omega,\phi_u\) come from the **same** accepted Class-B oscillator (`ActivitySpectralOmegaEstimate` + `ValidatedPeriodicPhaseEstimate`), and \(A_u>0\) is a scalar activity level (not a Frequency-mode vector).

### 1.2 Compatible same-ω pairwise outputs (separate fields)

| Field | Definition | Notes |
| --- | --- | --- |
| `phase_alignment` | \(\cos(\Delta\phi)\) | Phase-only; **not** scaled by \(A\) |
| `activity_level_A` | \(A_u\) | Scalar intensity |
| `activity_level_B` | \(A_v\) | Scalar intensity |
| `activity_level_gap` | \(\lvert A_u-A_v\rvert\) | Separate diagnostic |

**Hard rule:** do **not** fuse activity level into phase alignment (no \(A_u A_v\cos\Delta\phi\) as the sole returned “resonance”).

### 1.3 Implementation

- API: `GlobalActivityPeriodicResonance` (`global_activity_periodic_resonance_v1`)
- Reuses Wave-State v2 phase-reference compatibility gates
- `attaches_to_frequency_modes = false`
- Shadow only; `gates_calibrated = false`

### 1.4 Forbidden

- Copying \(\phi\) / \(\omega\) into all six Frequency modes
- Calling \(c_{\mathrm{abs}}\) “resonance”
- Discover ranking use

---

## 2. Tier 2 — Multi-mode Wave-State v2 (**research-only, not L5 v1**)

### 2.1 Status

| Flag | Value |
| --- | --- |
| `tier2_real_user_resonance_enabled` | `false` |
| `tier2_requires_mode_specific_oscillators` | `true` |
| `tier2_real_user_status` | `research_only_unavailable` |
| `may_copy_global_phase_to_frequency_modes` | `false` |
| `tier2_l5_v1_retained_candidate` | `false` |
| `fused_r_wave_is_l5_score` | `false` |

Existing Wave-State v1 / v2 code remains for offline math and research. The **real-user multi-mode path is gated unavailable** until each Frequency mode has a genuinely mode-specific oscillator and phase provenance.

Gate API: `WaveStateMultimodeRealUserGate`.

### 2.2 \(c_{\mathrm{abs}}\) semantics

| Statement | Value |
| --- | --- |
| \(c_{\mathrm{abs}}\) is resonance | **false** |
| \(c_{\mathrm{abs}}\) is amplitude-envelope diagnostic only | **true** |
| \(c_{\mathrm{abs}}\) used for ranking | **false** |

The multi-amplitude adapter (`periodic_wave_state_resonance_adapter_v1`) is marked `research_envelope_diagnostic_only = true` / `real_user_usable_path = false`.

### 2.3 Attach rule

Global activity spectral / circadian phase **must not** be duplicated onto `depth_preference` … `communication_pace`. Mode attach requires mode-scoped streams (Temporal Phase Estimator Contract).

---

## 3. Relationship summary

| Path | Real-user shadow? | Role |
| --- | --- | --- |
| Tier 1 scalar global activity oscillator | Research shadow (not L4 v1 production) | Separated \(\cos\Delta\phi\) + activity levels |
| Class A `circadian_activity_24h` | L4 **conditional diagnostic** | Civil / external-anchored clock |
| Wave-State v1 bare φ | Lab / math | No provenance |
| Wave-State v2 multi-mode | Research-only; **not L5 v1** | Gated until mode-specific oscillators |
| Multi-amp periodic adapter | Research diagnostic; **not an L5 score** | Envelope geometry; not Tier-1 API |

---

## 4. Non-goals

- No Discover / UI ranking
- No Persona / RVI / density-matrix
- No loosening of ω / phase compatibility
- No removal of existing Wave-State v1/v2 code

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-11 | Freeze after periodic Wave-State resonance stress |
| v1 L5 boundary | 2026-08-16 | Tier 2 / fused \(r_{\mathrm{wave}}\) rejected from L5 v1; L4 Tier-1 flags unchanged |
