# QMatch Temporal Phase Estimator Contract v1

| Field | Value |
| --- | --- |
| Contract id | `temporal_phase_estimator_contract_v1` |
| Status | `specification_only_not_live` |
| Purpose | Define how real temporal metadata may produce valid `PhaseReferenceV2` for Wave-State Modal Shadow v2 |
| Depends on | [Wave Phase Reference Policy v1](./qmatch_wave_phase_reference_policy_v1.md), [Temporal Observation Contract v1](./qmatch_temporal_observation_contract_v1.md), [Temporal Feature Extraction v1](./qmatch_temporal_feature_extraction_v1.md), implemented `wave_state_modal_shadow_v2` |
| Explicitly out of scope | Production code changes, Discover ranking/UI, Persona, RVI, density-matrix/fidelity, questionnaire→φ/ω, copying one global circadian phase into all Frequency modes, fabricating ω |

---

## 0. Principles

1. **Global activity ≠ modal phase.**  
   Today’s message-timestamp circadian estimate is a **global activity oscillator**. It must **not** be duplicated onto `depth_preference` … `communication_pace` without mode-specific evidence.

2. **Phase needs an oscillator.**  
   \(\phi\) is only meaningful with `oscillator_id`, period/\(\omega\), time basis, and (when Class B) reference epoch — per Phase Reference Policy v1.

3. **No questionnaire phase.**  
   Frequency 6D questionnaire \(\mu_m\) may inform static amplitude priors only. Never \(\phi_m\) or \(\omega_m\).

4. **No fake omega.**  
   Cadence / median inter-event rate is **not** \(\omega\). Periodic \(\omega\) requires a demonstrated oscillator or \(d\phi/dt\) on a valid phase series.

5. **Unavailable is correct.**  
   If a mode lacks a justified event stream + oscillator, emit `phase = unavailable` for that mode. Do not fill gaps.

6. **Shadow only.**  
   Estimators may feed Wave-State v2 shadow diagnostics. Discover ranking stays untouched.

---

## 1. Separated objects

| Object | Role | Attaches to Wave-State mode? |
| --- | --- | --- |
| `circadian_activity_24h` | Global Class A activity-clock phase (circular mean + \(\bar R\)) | **No** — separate diagnostic oscillator |
| `PhaseReferenceV2` on mode \(m\) | Mode-scoped provenanced phase for signed `r_wave` | **Only if** mode-specific stream + oscillator justified |
| Cadence / burstiness / regularity / reply gaps | Tempo & intensity diagnostics | May inform future \(A_m\); **not** φ by themselves |
| Timing lag \(\tau^*\) | Dyadic lag diagnostic | Becomes Δφ only with explicit shared \(T\) |

**Hard rule:** implementing `circadian_activity_24h` does **not** authorize writing the same `PhaseReferenceV2` into all six Frequency modes.

---

## 2. Global circadian oscillator definition

### 2.1 Identity

| Field | Value |
| --- | --- |
| Diagnostic id | `circadian_activity_24h` |
| `oscillator_id` (wire) | `circadian_activity_24h` |
| Phase class | `external_anchored` (Class A) |
| Period | \(T = 86400\,\mathrm{s}\) (24h civil day) |
| \(\omega\) | \(2\pi / 86400\) |
| Time basis | `local_civil` |
| Timezone | **Required** (IANA or offset). Missing TZ → unavailable |
| Reference | Local civil midnight implied by time basis (no free Class B epoch) |
| Event stream | Actor’s **all eligible send timestamps** (system messages excluded); not mode-filtered |

**Naming note.** Prefer `circadian_activity_24h` over bare `circadian_24h` when publishing estimator outputs, to make “global activity clock” explicit. Legacy temporal extraction docs used `circadian_24h` for the same math — treat them as aliases only for the **global diagnostic**, never as a Frequency mode id.

### 2.2 Estimator (circular mean)

For eligible events of actor \(U\) with local time-of-day \(\tau_k\in[0,86400)\):

\[
\theta_k = 2\pi\,\frac{\tau_k}{86400}
\]

\[
\bar C=\frac{1}{N}\sum\cos\theta_k,\quad
\bar S=\frac{1}{N}\sum\sin\theta_k
\]

\[
\bar R_U=\sqrt{\bar C^2+\bar S^2},\qquad
\bar\theta_U=\mathrm{atan2}(\bar S,\bar C)
\]

Dyadic offset (diagnostic):

\[
\Delta\bar\theta_{PQ}=\mathrm{wrap}_{[-\pi,\pi]}(\bar\theta_P-\bar\theta_Q)
\]

only when both sides are available under compatible Class A provenance.

### 2.3 `PhaseReferenceV2` mapping (global diagnostic only)

When gates pass (`ok`):

```text
PhaseReferenceV2 {
  oscillator_id: circadian_activity_24h
  phase_radians: theta_bar
  phase_class: external_anchored
  time_basis: local_civil
  timezone: <required>
  period_seconds: 86400
  omega: 2π/86400
  reference_epoch: null   # civil midnight via time_basis
  periodicity_status: ok | sparse | unavailable  # from R̄ + N + days
  source: temporal_phase_estimator_circadian_activity_v1
}
```

This object is attached to **`circadian_activity_24h`**, not to Frequency mode ids.

### 2.4 What it must not do

- Must not set `WaveStateModeV2.phase` for all six modes to this object.
- Must not claim modal resonance across Frequency modes from activity-clock alignment alone.
- Must not invent per-mode Δφ from global \(\Delta\bar\theta\).

---

## 3. Per-mode phase identifiability audit (today)

“Today” = metadata available from existing chat threads (timestamps, sender_id, participants, optional TZ) plus product features that **actually exist**. Explicit `disclosure_marked` and reliable depth events are **not** generally present.

| Mode | Mode-specific event stream today? | Valid φ estimable today? | Candidate `oscillator_id` | Period / reference / time basis | Quality gate (if ever) | Phase status today |
| --- | --- | --- | --- | --- | --- | --- |
| `depth_preference` | **No.** No content-free depth events; size_class weak proxy only; text NLP forbidden | **No** | none | — | — | **`unavailable`** |
| `social_energy` | **Partial.** Initiation / outbound sends exist, but stream is largely the same global activity set, not a distinct oscillator | **Not as modal φ.** Volume/cadence → future \(A\) only | none for modal φ; global activity uses `circadian_activity_24h` separately | — | — | **`unavailable`** (modal) |
| `spontaneity` | **No phase stream.** Burstiness is irregularity of intervals, not position on a period | **No** | none | — | — | **`unavailable`** |
| `stability` | **No phase stream.** Regularity / day-count consistency ≠ demonstrated periodic phase | **No** as modal φ. Circadian \(\bar R\) may correlate with “clock regularity” only as a **separate** global diagnostic | none for modal φ | — | — | **`unavailable`** (modal) |
| `disclosure_pace` | **No** unless product emits `disclosure_marked` (content-free). Absent today → no stream | **No** | future: e.g. `disclosure_circadian_24h` only if disclosure events exist and are clocked | Would need local_civil + TZ + \(T=24\mathrm{h}\) or validated spectral \(T\) | Count + concentration / SNR gates | **`unavailable`** |
| `communication_pace` | **Partial.** Reply/turn timestamps exist (tempo), but tempo ≠ phase; no validated period for turn-taking oscillator today | **No** as modal φ today. Timing lag \(\tau^*\) may be diagnostic only | future Class B only after spectral/validated period on reply process | Common epoch + shared \(T\) + compatible time basis | Spectral SNR + stability across windows | **`unavailable`** |

### 3.1 Summary verdict

**Zero of six Frequency modes** have a justified mode-specific `PhaseReferenceV2` from current metadata.

The only scientifically honest Class A phase available from current send timestamps is the **global** `circadian_activity_24h` diagnostic.

---

## 4. Supported `PhaseReferenceV2` mappings (v1 contract)

### 4.1 Supported now (specification; shadow research)

| Output target | Mapping | Notes |
| --- | --- | --- |
| `circadian_activity_24h` | Circular mean + \(\bar R\) from eligible send times + local TZ | Class A; global diagnostic only |
| Dyadic \(\Delta\bar\theta\) | Difference of two compatible global circadian phases | Diagnostic offset; not a Frequency mode phase |

### 4.2 Conditionally supported later (not today)

| Output target | Requires | Oscillator class |
| --- | --- | --- |
| Mode-scoped circadian on a **filtered** stream | Mode-justified event type distinct from raw sends (e.g. `disclosure_marked`, initiation-only stream with explicit construct justification) + TZ | Class A, `oscillator_id` must name both construct and period (e.g. `disclosure_circadian_24h`) — **never** reuse global activity id silently |
| Mode-scoped validated periodic phase | Spectral peak `ok` on that mode’s stream + shared epoch + shared \(T\) | Class B |
| Lag→Δφ | \(\tau^*\) plus explicit shared \(T\) from Class A or B above | Reports Δφ diagnostic; still needs policy-compatible provenance |

### 4.3 Wave-State v2 attach rule

```text
For each Frequency mode m:
  if mode-scoped PhaseReferenceV2 exists and gates ok:
      WaveStateModeV2(mode_id=m).phase = that reference
  else:
      WaveStateModeV2(mode_id=m).phase = null   # signed modal contribution unavailable

Never:
  for m in Frequency6:
      mode[m].phase = circadian_activity_24h_phase   # FORBIDDEN duplication
```

Signed modal `r_wave` over Frequency modes therefore remains **unavailable** until at least one mode has a real mode-scoped reference. Global circadian may be compared **outside** the six-mode Wave-State sum (separate diagnostic API).

---

## 5. Unsupported mappings (normative prohibitions)

| Mapping | Why forbidden |
| --- | --- |
| Copy global circadian φ → all 6 modes | No mode-specific evidence; false modal coverage |
| Questionnaire \(\mu_m\) → φ or ω | Fabrication |
| Median inter-send interval → ω | Cadence ≠ periodic frequency |
| Burstiness / regularity → φ | No oscillator / period |
| Reply latency median → φ | Tempo diagnostic, not phase |
| Timing lag \(\tau^*\) → φ without \(T\) | Lag ≠ phase |
| Size_class / message length → depth phase | Weak proxy; NLP/size forbidden as depth proof |
| UTC assumed as local for circadian | Missing TZ → unavailable |
| Gauge-fix unanchored latents into signed modal φ | Phase Reference Policy Class C |
| Discover consumption of any phase estimand under this contract | Out of scope |

---

## 6. Quality gates

### 6.1 Global `circadian_activity_24h` (provisional; not calibrated)

Aligned with temporal feature extraction placeholders; must be retuned on real cohorts before freeze.

| Status | Conditions (all required for row) |
| --- | --- |
| `ok` | Local TZ known; \(N\ge 10\) eligible sends; ≥4 distinct local days; \(\bar R\ge 0.35\) (provisional) |
| `sparse` | TZ known; \(5\le N<10\) or \(0.20\le\bar R<0.35\) or day span weak (e.g. 3 days) |
| `unavailable` | No TZ; \(N<5\); \(\bar R<0.20\); invalid window; or no eligible events |

Signed Wave-State use of this **global** reference (if ever paired outside modal 6D) still requires Phase Reference Policy: Class A compatible, `periodicity_status=ok` by default for signed use.

Mark payloads `gates_calibrated: false`.

### 6.2 Future mode-scoped Class A (template)

| Gate | Requirement |
| --- | --- |
| Stream identity | Event type/filter explicitly justified for mode \(m\) |
| TZ | Required for civil oscillators |
| Count / days | At least as strict as global circadian unless retuned |
| \(\bar R\) | Concentration gate on **that** stream’s clock angles |
| Naming | Distinct `oscillator_id` including mode construct |

### 6.3 Future mode-scoped Class B (template)

| Gate | Requirement |
| --- | --- |
| Spectral SNR / periodicity | Peak stable across ≥2 sub-windows |
| Shared `oscillator_id`, \(T\)/\(\omega\), `reference_epoch`, time basis | Exact policy compatibility |
| Count | ≥30 events, ≥14 days (proposal from observation contract) |
| Status | `ok` required for signed use |

### 6.4 Mode-scoped default today

For all six Frequency modes:

\[
\texttt{periodicity\_status}=\texttt{unavailable},\quad
\texttt{PhaseReferenceV2}=\texttt{null}
\]

---

## 7. Recommended first real phase estimator

**Ship first (shadow-only, non-modal):**

### `temporal_phase_estimator_circadian_activity_v1`

1. Input: per-actor eligible message timestamps + local timezone.  
2. Output: `circadian_activity_24h` with \(\bar\theta\), \(\bar R\), status, full `PhaseReferenceV2` provenance.  
3. Optional dyadic: \(\Delta\bar\theta_{PQ}\) when both `ok` and time bases compatible.  
4. **Do not** attach to Frequency modes.  
5. **Do not** feed six-mode Wave-State signed `r_wave` by duplication.  
6. May sit beside Wave-State v2 as a **separate** shadow diagnostic channel.  
7. No Discover / Persona / RVI / density-matrix wiring.

**Do not ship next:** per-mode φ fillers, questionnaire maps, or ω-from-cadence.

**Second wave (only after product evidence):**

- Mode-specific streams (`disclosure_marked`, justified initiation-only filters, etc.) with **distinct** oscillator ids  
- Then optional Class B spectral phases per stream  
- Only then consider attaching `PhaseReferenceV2` to individual `WaveStateModeV2` entries

---

## 8. Relationship to Wave-State v2

| Wave-State v2 need | This contract |
| --- | --- |
| `PhaseReferenceV2` on mode \(m\) | Unavailable for all 6 modes today |
| Signed modal `r_wave` | Remains unavailable until mode-scoped references exist |
| Diagnostic `c_abs` | Unchanged policy (diagnostic only; not ranking) |
| Global circadian | Separate `circadian_activity_24h` estimator — not modal input |

v1 Wave-State (bare φ) remains lab/math only; scientifically, bare φ without provenance is Class C.

---

## 9. Document control

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-11 | Initial audit: global activity circadian ≠ Frequency modal phase; no mode-scoped φ today |
