# QMatch Periodicity / Omega Estimator Contract v1

| Field | Value |
| --- | --- |
| Contract id | `periodicity_omega_estimator_contract_v1` |
| Status | **Research shadow only** under L4 v1 — implemented, **not production-promoted**. `gates_calibrated=false`. |
| Purpose | Define when timestamp-only temporal metadata justifies a real periodic angular frequency \(\omega\) |
| Depends on | [Temporal Observation Contract v1](./qmatch_temporal_observation_contract_v1.md), [Wave Phase Reference Policy v1](./qmatch_wave_phase_reference_policy_v1.md), [Temporal Phase Estimator Contract v1](./qmatch_temporal_phase_estimator_contract_v1.md), `wave_state_modal_shadow_v2` |
| Explicitly out of scope | Production code, Discover ranking/UI, Persona, RVI, density-matrix/fidelity, questionnaire→ω, cadence→ω, attaching estimated ω to Frequency modes without a mode-specific event stream |

---

## 0. Principles

1. **Cadence is not omega.**  
   Event rate \(\lambda\), median inter-event gap, send/day counts, burstiness, and regularity are **tempo/intensity diagnostics**.  
   Forbidden: \(\omega \leftarrow 2\pi/\mathrm{median}(\delta)\), \(\omega \leftarrow \lambda\), \(\omega \leftarrow \mu_{\mathrm{Frequency}}\).

2. **Omega requires demonstrated periodicity.**  
   \(\omega\) exists only when a period \(T\) is statistically/structurally supported on a named event stream and passes quality gates.

3. **Timestamp metadata only.**  
   Inputs are event times (+ actor/thread identity as needed). No message bodies, NLP, or questionnaire scores.

4. **Two legal omega sources**
   - **Class A (externally anchored):** period fixed by civil definition (e.g. \(T=24\mathrm{h}\) for `circadian_activity_24h`). \(\omega=2\pi/T\) is **definitional**, not “detected.” Concentration gates apply to **phase**, not to inventing \(T\).
   - **Class B (validated periodic):** \(T\) estimated from the event process; then \(\omega=2\pi/T\). This contract’s primary subject.

5. **Stream identity matters.**  
   Do **not** attach estimated \(\omega\) to any Frequency mode unless that mode has a justified mode-specific event stream. Global send timestamps support a **global activity** oscillator at most.

6. **Unavailable / sparse / ambiguous are first-class.**  
   Prefer honest non-availability over a weak peak.

---

## 1. Separated quantities (normative)

| Symbol / id | Meaning | Is \(\omega\)? |
| --- | --- | --- |
| \(\lambda^{\mathrm{mean}},\lambda^{\mathrm{med}}\) | Cadence / event rate | **No** |
| \(B\), regularity | Interval irregularity / consistency | **No** |
| Reply / turn medians | Tempo diagnostics | **No** |
| \(T\) | Demonstrated period of an oscillator | Prerequisite for \(\omega\) |
| \(\omega=2\pi/T\) | Angular frequency of that oscillator | **Yes** (when \(T\) accepted) |
| \(\phi\) | Phase on that oscillator | Requires \(T\) + reference (separate estimators) |

---

## 2. Proposed detection method (Class B)

### 2.1 Primary method — binned activity periodogram

For irregular point events \(\{t_k\}_{k=1}^{N}\) on a single stream (e.g. actor send times):

1. Choose observation window \(W=[t_{\mathrm{start}},t_{\mathrm{end}}]\) of length \(L_W=t_{\mathrm{end}}-t_{\mathrm{start}}\).
2. Bin into contiguous bins of width \(\Delta\) (provisional default \(\Delta=1\,\mathrm{h}\)):

\[
x_j = \#\{\,t_k \in \text{bin } j\,\},\quad j=0,\ldots,J-1.
\]

3. Optionally mean-center: \(\tilde x_j = x_j-\bar x\).
4. Compute a periodogram / discrete Fourier power \(P(f)\) over candidate frequencies \(f\) (cycles per unit time), or equivalently periods \(T=1/f\).
5. Select the **dominant admissible peak** under §4–§5 gates.
6. If accepted period is \(T^\star\):

\[
\omega^\star = \frac{2\pi}{T^\star}.
\]

**Justification.** Binning converts an irregular point process into a regularly sampled activity series where classical spectral peak tests apply. It is robust enough for shadow research on chat timestamps and matches the observation contract’s “binned / spectral peak” path.

### 2.2 Allowed alternatives (must meet the same gates)

| Method | When usable | Notes |
| --- | --- | --- |
| Lomb–Scargle on binned or weighted samples | Same binning / window policy | Prefer documenting equivalence to periodogram peaks |
| Autocorrelation peak of \(x_j\) | Same gates on lag peak vs sidelobes | Report lag \(T\) then \(\omega=2\pi/T\) |
| \(d\phi/dt\) on a **valid** Class A/B phase series | Only if phase estimator already `ok` | Not a substitute for detecting \(T\) from scratch |

**Not allowed as omega estimators:** median gap, mean rate, CV, burstiness, questionnaire maps.

### 2.3 Candidate period range (provisional)

Search only inside a declared band \([T_{\min},T_{\max}]\):

| Bound | Provisional default | Rationale |
| --- | --- | --- |
| \(T_{\min}\) | \(\max(2\Delta,\, 6\,\mathrm{h})\) | Above Nyquist-ish bin scale; avoid ultra-short noise |
| \(T_{\max}\) | \(\min(L_W/3,\, 14\,\mathrm{d})\) | Need ≥ ~3 cycles in window; cap near fortnight for chat |

Civil anchors already covered by Class A (24h, optional 7d) should be **reported as Class A**, not “discovered” Class B, when the estimator is intentionally testing the civil oscillator. A Class B search may still **exclude or specially label** exact 24h/7d peaks to avoid double-counting (see §5).

Mark all numeric defaults `gates_calibrated: false`.

---

## 3. Exact omega rule

### 3.1 Acceptance identity

If and only if a unique admissible period \(T^\star\) is accepted under §4–§6:

\[
\boxed{\omega^\star = \dfrac{2\pi}{T^\star}}
\]

with units radians per second when \(T^\star\) is in seconds.

### 3.2 Non-acceptance

If status is `unavailable`, `sparse`, or `ambiguous`:

- Do **not** emit \(\omega^\star\) as `ok`.
- Do **not** fall back to cadence.
- May emit diagnostic peak table (shadow) without promoting a winner.

### 3.3 Class A reminder

For `circadian_activity_24h` (and similar civil oscillators):

\[
\omega_{\mathrm{circ}} = \frac{2\pi}{86400}
\]

is fixed by definition. Periodicity quality for **phase** uses \(\bar R\), \(N\), days — not a spectral search for \(T\).

---

## 4. Quality gates (Class B, provisional)

All gates must pass for status `ok`. Failures map to `sparse` / `unavailable` / `ambiguous` as specified.

### 4.1 Data volume

| Gate | Provisional `ok` | Else |
| --- | --- | --- |
| Event count \(N\) | \(N \ge 30\) | \(12\le N<30\) → prefer `sparse` if a weak peak exists; \(N<12\) → `unavailable` |
| Observation window \(L_W\) | \(L_W \ge 14\,\mathrm{d}\) | \(7\le L_W<14\,\mathrm{d}\) → at best `sparse`; else `unavailable` |
| Cycles in window | \(L_W / T^\star \ge 3\) | Else reject peak (`unavailable` or `ambiguous`) |

### 4.2 Peak strength / SNR

Define continuum / noise floor \(\mathcal{N}\) as median (or robust mean) of \(P(f)\) outside a notch around the peak and its low-order harmonics (implementation detail; must be documented in code later).

\[
\mathrm{SNR}
=
\frac{P(f^\star)}{\mathcal{N}}
\]

| Status | Provisional rule |
| --- | --- |
| `ok` | \(\mathrm{SNR} \ge 6\) (placeholder) **and** peak is unique under §6 |
| `sparse` | \(3 \le \mathrm{SNR} < 6\) and other volume gates marginal |
| `unavailable` | \(\mathrm{SNR} < 3\) or no peak in band |

**Also require split-half / sub-window stability:** peak period in first vs second half of \(W\) agrees within relative tolerance \(\varepsilon_T=0.10\) (provisional). Failure → `ambiguous` or `unavailable` (not `ok`).

### 4.3 Status vocabulary

| Status | Meaning |
| --- | --- |
| `ok` | Single admissible \(T^\star\); \(\omega=2\pi/T^\star\) may enter Class B provenance |
| `sparse` | Weak evidence; diagnostics only; **no** signed Wave-State use |
| `ambiguous` | Multiple competing peaks or harmonic/alias conflict unresolved |
| `unavailable` | Insufficient data or no admissible peak |

Signed Wave-State / `PhaseReferenceV2` use requires `periodicity_status=ok` by Phase Reference Policy default.

---

## 5. Alias / harmonic safeguards

### 5.1 Harmonics

If peak \(T\) and \(T/2\) (or \(2T\)) both strong:

1. Prefer the peak with highest SNR that still satisfies \(L_W/T\ge 3\) and \(T\in[T_{\min},T_{\max}]\).
2. If SNR of fundamental and first harmonic are within factor \(\rho=1.5\) (provisional) → mark **`ambiguous`** unless an external anchor selects one (e.g. known weekly vs semiweekly — rare; must be explicit).
3. Never silently pick \(T/2\) because it “fits more cycles.”

### 5.2 Aliasing / binning

- Reject periods \(T < 2\Delta\) (bin Nyquist-style floor).
- If changing \(\Delta\) (e.g. 1h vs 2h) moves \(T^\star\) by more than \(\varepsilon_T\) relative → `ambiguous`.
- Document \(\Delta\) on wire provenance.

### 5.3 Civil-period collision

If the top Class B peak is within \(\varepsilon_T\) of \(24\mathrm{h}\) or \(7\mathrm{d}\):

- Prefer labeling as **support for Class A civil oscillator**, not a new Class B id; **or**
- Emit Class B only with `oscillator_id` that explicitly says `spectral_*` and note `near_civil_collision=true` in diagnostics.

Do not invent a second “almost circadian” Class B omega that competes with `circadian_activity_24h` in product logic.

---

## 6. Multiple-peak behavior

Let peaks \(\{T_i\}\) be local maxima of \(P\) inside the band with SNR above the sparse floor.

| Situation | Action |
| --- | --- |
| One peak passes `ok` gates | Accept \(T^\star\) |
| Two+ peaks pass SNR≥6 and are not harmonic-related within policy | **`ambiguous`** — no \(\omega^\star\) |
| One dominant + harmonics | Apply §5.1 |
| No peak above sparse floor | `unavailable` |

Wire may include `candidate_peaks[]` for shadow analysis; only `ok` promotes `omega` / `period_seconds`.

---

## 7. Provenance for `PhaseReferenceV2` (when period accepted)

Estimated periodicity yields **Class B** (`validated_periodic`) when phase is also estimated on the **same** oscillator. Minimum fields:

| Field | Rule |
| --- | --- |
| `oscillator_id` | Stable id, e.g. `activity_spectral_<stream>_<Ttag>`; never a Frequency mode id |
| `period_seconds` | \(T^\star\) |
| `omega` | \(2\pi/T^\star\) (must match period) |
| `reference_epoch` | **Required** for Class B — absolute zero for phase (e.g. window start UTC, or first event — must be stated and shared pairwise) |
| `time_basis` | `utc` or `local_civil` (if local, timezone required) |
| `timezone` | Required when `local_civil` |
| `periodicity_status` | `ok` \| `sparse` \| `unavailable` \| map `ambiguous`→ do not emit signed phase |
| `phase_class` | `validatedPeriodic` |
| `phase_radians` | Only if a phase estimator on **this** oscillator is also `ok`; else omit phase / leave unavailable |
| `source` | Estimator version id, never `questionnaire` |

### 7.1 Attach rules

| Target | Allowed? |
| --- | --- |
| Global activity diagnostic oscillator | Yes (shadow), if stream = global sends |
| Frequency mode \(m\) | **Only if** mode-specific event stream exists and `oscillator_id` names that construct |
| Six-mode Wave-State via copying one ω to all modes | **Forbidden** |
| Discover ranking | **Forbidden** under this status |

---

## 8. What current QMatch metadata can support

Available today (typical): message `timestamp` + `sender_id` + thread participants + optional local TZ.

| Capability | Support now |
| --- | --- |
| Cadence / burstiness / regularity | Yes (already in temporal shadow extraction) — **not ω** |
| Class A \(\omega\) for `circadian_activity_24h` | Yes — **definitional** \(2\pi/86400\) with TZ; phase via existing circadian estimator |
| Class B spectral \(\omega\) on global sends | **Research-feasible** when \(N\), \(L_W\) gates pass; not implemented; expect frequent `unavailable`/`ambiguous` on sparse chatters |
| Mode-specific ω (`disclosure_pace`, etc.) | **No** — streams missing (`disclosure_marked`, etc.) |
| Questionnaire ω | **Forbidden** |
| Reliable product ranking use | **No** |

**Honest expectation:** most users/threads will not clear Class B `ok` gates. That is correct behavior.

---

## 9. Recommended first shadow implementation

**Do not start with modal ω.**

### Step 1 (recommended first code)

`periodicity_omega_estimator_activity_spectral_v1` (name provisional):

1. Input: one actor’s eligible send timestamps + window + bin \(\Delta\) + time basis.  
2. Output: status, optional \(T^\star,\omega^\star\), SNR, candidate peak diagnostics, provenance stub for Class B.  
3. Stream id: global activity only (`oscillator_id` prefix `activity_spectral_…`).  
4. **No** Frequency mode attachment.  
5. **No** Discover.  
6. `gates_calibrated: false`, `shadow_only: true`.

### Step 2

Optional: if Class B `ok`, estimate phase on that oscillator (circular mean in folded period, or Fourier phase at \(f^\star\)) and emit full `PhaseReferenceV2` — still global diagnostic only.

### Step 3 (later)

Mode-specific streams only after product evidence; distinct oscillator ids; then optional Wave-State mode attach under Phase Reference Policy.

### Explicit non-goals for v1 implementation

- No cadence→ω fallback  
- No questionnaire  
- No Persona / RVI / density-matrix  
- No six-mode duplication of a single spectral ω  

---

## 10. Relationship to existing estimators

| Existing | Role vs this contract |
| --- | --- |
| Temporal shadow cadence / burstiness | Parallel diagnostics; never ω |
| `temporal_phase_estimator_circadian_activity_v1` | Class A phase; fixed civil ω |
| This contract | Class B period detection → ω |
| Wave-State v2 | Consumes provenanced φ/ω only when compatible; no change required until estimator exists |

---

## 11. Document control

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-11 | Initial Class B spectral/periodogram contract; cadence≠ω; no modal attach without stream |
