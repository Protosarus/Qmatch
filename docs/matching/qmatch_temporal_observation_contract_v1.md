# QMatch Temporal Observation Contract v1

| Field | Value |
| --- | --- |
| Contract id | `temporal_observation_contract_v1` |
| Status | `production_diagnostics_non_ranking_v1` for L4 v1 cadence family (see [L4 contract](./qmatch_l4_temporal_diagnostics_contract_v1.md)); observation instrumentation still incomplete |
| Purpose | Define metadata-only behavioral observations that may later support modal amplitude, phase, and periodic frequency |
| Depends on | [Modal Resonance Model v1](./qmatch_modal_resonance_model_v1_specification.md), Frequency 6D taxonomy |
| Explicitly out of scope | Message-content NLP, questionnaire→phase/ω maps, Persona, quantum, RVI, Discover ranking/UI, structural Matching changes |

---

## 0. Principles

1. **Metadata only.** Timestamps, counts, intervals, initiation/reciprocity flags — not message body semantics or NLP.
2. **No fabrication.** Questionnaire Frequency scores must never become \(\phi\) or \(\omega\). Static amplitudes remain questionnaire priors via `modal_static_amplitude_shadow_v1` until temporal estimators qualify.
3. **Four distinct quantities.** Never conflate:
   - **Cadence / event rate** — how often events occur
   - **Periodic frequency** \(\omega_m\) — rate of a *demonstrated oscillator*
   - **Phase** \(\phi_m\) — position on a *defined* oscillator/period
   - **Amplitude** \(A_m\) — intensity / engagement strength
4. **Mode-justified mapping.** Signals map only where the behavioral construct is justified; weak proxies must be labeled weak.
5. **Separation.** \(D_{\mathrm{structural}}\) and static modal amplitude stay separate from temporal modal state.
6. **Sparse honesty.** Below gates → `unavailable` / `sparse`, never imputed.
7. **Privacy-first.** Prefer aggregates; minimize raw event retention for Matching.

Canonical Frequency modes \(\mathcal{F}\):

| Id | Construct |
| --- | --- |
| `depth_preference` | Preference for deeper exchange (not message length alone) |
| `social_energy` | Initiation / social activation intensity |
| `spontaneity` | Irregularity / burstiness of contact |
| `stability` | Consistency / regularity of contact |
| `disclosure_pace` | Pace of *explicit* disclosure events (content-free tags only) |
| `communication_pace` | Messaging tempo / turn cadence |

---

## 1. Separated definitions (corrected semantics)

### 1.1 Cadence / event rate (not \(\omega\))

From inter-event intervals \(\delta_k = t_{k+1}-t_k\):

\[
\lambda^{\mathrm{med}}
=
\frac{1}{\mathrm{median}(\delta_k)}
\quad\text{(events per unit time)}
\]

Also usable: mean rate, sends/day, initiation rate.

**Naming rule:** call these **cadence** or **event rate**.  
**Do not** call \(2\pi/\mathrm{median}(\delta)\) angular frequency. It is not \(\omega_m\).

### 1.2 Periodic frequency \(\omega_m\) (reserved)

\(\omega_m\) is allowed **only** when periodic structure is demonstrated:

1. **Spectral peak with gates:** dominant frequency of a binned / point-process spectrum in window \(W\), with SNR (or equivalent periodicity) above threshold and a stable peak across sub-windows; or
2. **Derivative of a valid phase process:** \(\omega_m(t)\approx d\phi_m/dt\) only when \(\phi_m\) itself is `ok` on a defined oscillator (§1.3).

If neither holds → \(\omega_m=\texttt{unavailable}\).  
**Forbidden:** \(\omega_m\leftarrow\mu_m\), \(\omega_m\leftarrow A_m\), \(\omega_m\leftarrow 2\pi/\mathrm{median}(\delta)\).

### 1.3 Phase \(\phi_m\) (requires a defined oscillator)

Phase is meaningful only relative to a **named period** \(T\) (or oscillator id), e.g.:

- circadian: \(T=24\,\mathrm{h}\) → \(\phi^{\mathrm{circ}} \in [0,2\pi)\) from circular mean of event clock times
- weekly: \(T=7\,\mathrm{d}\)
- a **validated** spectral component with period \(T_m=2\pi/\omega_m\) when \(\omega_m\) is `ok`

Dyadic difference on the same oscillator:

\[
\Delta\phi_m^{(PQ)}
=
\phi_m^{(P)}-\phi_m^{(Q)}
\pmod{2\pi}.
\]

**Cross-correlation lag \(\tau^*\) alone is not phase.**  
It may be reported as a **timing lag** diagnostic. It becomes a phase candidate only after conversion

\[
\Delta\phi = 2\pi\,\tau^*/T
\]

with an **explicit** \(T\) from a defined oscillator (circadian or validated periodic component). Without \(T\), leave as \(\tau^*\) — do not label \(\phi\).

**Forbidden:** \(\phi\leftarrow\mu\); absolute person-level phase without oscillator id; treating turn-lead fraction as \(\phi\) without stating the oscillator/reference.

### 1.4 Amplitude \(A_m\)

Intensity in \([0,1]\) (questionnaire prior and/or temporal intensity). Distinct from cadence, \(\omega\), and \(\phi\).

---

## A. Observable signals (metadata)

Events \(e_k=(t_k,\mathrm{actor}_k,\mathrm{type}_k,\mathrm{thread}_k,\mathrm{meta}_k)\) with `meta` excluding free-text semantics.

### A.1 Allowed event types

| Event type | Allowed fields |
| --- | --- |
| `message_sent` | `t`, `sender_id`, `thread_id`, optional coarse `size_class`, optional `is_first_human_in_thread` |
| `message_read` | `t`, `actor_id`, `thread_id` (only if peer receipts actually work) |
| `conversation_opened` | `t`, `initiator_id`, `peer_id` |
| `session_active` | `t_start`, `t_end`, `user_id` |
| `disclosure_marked` | `t`, `actor_id`, `thread_id` — **explicit content-free user affordance only** |

**Disallowed:** body NLP, sentiment, topics, embeddings as Matching inputs, GPS trajectories.

### A.2 Derived series

| Signal id | Family | Definition |
| --- | --- | --- |
| `msg_timestamps` | raw | Ordered send times |
| `inter_event_interval` | cadence | \(\delta_k\) |
| `event_rate_median` | cadence | \(1/\mathrm{median}(\delta)\) |
| `reply_latency` | cadence / tempo | Reply delay within timeout |
| `turn_interval` | cadence / tempo | Alternating-turn gaps |
| `initiation_rate` | cadence | Opens / first-human-after-idle per time |
| `reciprocity_ratio` | amplitude-related balance | Directed send share |
| `activity_histogram` | cadence + phase support | Hour-of-day / day-of-week counts |
| `burstiness` | cadence irregularity | e.g. Goh–Barabási \(B\) on \(\delta_k\) |
| `regularity` | cadence regularity | e.g. \(1/(1+\mathrm{CV}(\delta))\) |
| `timing_lag` | lag diagnostic | Cross-correlation \(\tau^*\) — **not phase by itself** |
| `circadian_phase` | phase | Circular mean on \(T=24\mathrm{h}\) |
| `spectral_peak_omega` | periodic frequency | Peak \(\omega\) iff SNR/periodicity gate passes |
| `disclosure_event_rate` | amplitude (mode-specific) | Rate of `disclosure_marked` only |

---

## B. Mapping to Frequency 6 modes

| Mode \(m\) | Primary signals | Notes |
| --- | --- | --- |
| `depth_preference` | Optional user-declared deep-share rate; **message `size_class` is a weak proxy only** | Long messages ≠ proof of conversational depth. Size-class must be labeled `weak_proxy` and must not alone certify temporal \(A\) for this mode |
| `social_energy` | `initiation_rate`, outbound send rate, session starts | Cadence/intensity → amplitude candidates |
| `spontaneity` | `burstiness`, histogram irregularity | Not mean rate alone |
| `stability` | `regularity`, stable day counts; circadian concentration as diagnostic | Regularity ≠ \(\omega\) unless spectral gate passes |
| `disclosure_pace` | **`disclosure_marked` rate only** | If no explicit content-free disclosure events → temporal estimands **unavailable** (no size-class substitute) |
| `communication_pace` | Median `reply_latency`, `turn_interval`, in-thread send cadence | Tempo/cadence → amplitude; \(\omega\) only with periodicity gate |

---

## C. Candidate estimators (corrected)

All return status `ok` | `sparse` | `unavailable`.

### C.1 Amplitude \(A_m(t)\)

Map a mode intensity score \(r_m(t)\) (rate, burstiness, regularity, latency inverse, etc.) into \([0,1]\) via cohort quantiles — **not** questionnaire scores as the scale.

Optional shrink to questionnaire prior \(A_m^{\mathrm{q}}\) only when temporal status is `ok`.

| Mode | \(r_m\) candidate | Caveat |
| --- | --- | --- |
| `depth_preference` | Declared deep-share rate; size-class long fraction only as `weak_proxy` | Prefer `unavailable` over weak-proxy-only for “ok” amplitude |
| `social_energy` | Initiation + outbound rate | |
| `spontaneity` | Burstiness | |
| `stability` | Regularity | |
| `disclosure_pace` | Disclosure-marked rate | Else unavailable |
| `communication_pace` | Inverse median reply latency (normalized) | |

### C.2 Phase \(\phi_m(t)\)

Only on a defined oscillator:

1. **Circadian / weekly circular mean** from `activity_histogram` → \(\phi\) with `oscillator_id=circadian_24h` (or `weekly_7d`).
2. **Periodic component phase** when `spectral_peak_omega` is `ok` for period \(T_m\).
3. **Lag→phase conversion** \(\Delta\phi=2\pi\tau^*/T\) only with explicit \(T\) from (1) or (2).

Otherwise emit `timing_lag` (seconds), not `phi`.

### C.3 Periodic frequency \(\omega_m(t)\)

1. Spectral peak + SNR/periodicity gate; or  
2. \(d\phi/dt\) from a valid phase series on a defined oscillator.

Cadence \(\lambda^{\mathrm{med}}\) may be emitted in parallel as `event_rate_median` — **never** as `omega`.

---

## D. Minimum-data rules (proposal, not live)

| Estimand | Min data | Else |
| --- | --- | --- |
| Cadence / \(A_m\) from rates | ≥12 mode-relevant events, ≥7 days | `sparse` / `unavailable` |
| `circadian_phase` | ≥20 events spanning ≥4 distinct days | `unavailable` |
| `timing_lag` | ≥15 alternating turns or ≥20 events/side, ≥14 days | `unavailable` |
| Lag→\(\Delta\phi\) | Same as lag **plus** valid \(T\) | If no \(T\), keep lag only |
| \(\omega_m\) spectral | ≥30 events, ≥14 days, SNR/periodicity gate | `unavailable` |
| \(\omega_m\) from \(d\phi/dt\) | Phase series `ok` on ≥2 windows | `unavailable` |
| `disclosure_pace` temporal | ≥1 `disclosure_marked` scheme in product **and** count gates | Else always `unavailable` |
| `depth_preference` temporal `ok` | Must not rely on size-class alone | Size-class-only → at best `weak_proxy` / prefer unavailable for \(A\) |

No questionnaire backfill for missing \(\phi\)/\(\omega\). Drop events with missing timestamps; do not impute times.

---

## E. Privacy / retention (unchanged intent)

- Prefer aggregates over raw streams for Matching.
- No body/NLP as Matching input; coarse size_class only if stored without text retention for Matching.
- Dyadic \(\Delta\phi\), lag, reciprocity are private to the dyad.
- Proposed: raw buffer ≤90d; aggregates ≤180d; purge on account delete; Matching-research opt-out.
- No export to Persona / quantum / RVI; no Discover consumption under this status.

---

## F. Now vs later (updated after code audit)

### F.1 Computable offline today from existing chat metadata (shadow research only)

Given stored `created_at` / `client_created_at` + `sender_id` + thread `participants`:

- Per-actor / dyadic **send timestamps** and **inter-event intervals**
- **Cadence / event rate**, burstiness, regularity (with sparse gates)
- **Approximate reply latency** and **turn intervals** by ordering sends (derivable, not a first-class field)
- **Reciprocity** from sender counts
- **Hour-of-day / day-of-week histograms** → candidate **circadian phase** (if count gates pass)
- Weak **spectral \(\omega\)** research on dense threads only (most threads will be `unavailable`)

### F.2 Not collectable / not reliable yet

- Peer **read receipts** (message updates blocked; `read_by` sender-only)
- Explicit **conversation_opened** / first-human-initiator flags
- Explicit **turn_index**
- **session_active** / messaging foreground events (`last_active_at` is auth-centric, not chat)
- **size_class** / byte_length fields (body text exists; size-class metadata does not)
- **`disclosure_marked`** events (reveal state on matches is unwired / not a disclosure event stream)
- Working product pipeline for **Discover** temporal ranking (none; L4 v1 is post-match diagnostics only)

### F.3 Later product work before freeze

- Explicit initiator + disclosure-marked events if those modes are required
- Optional size_class **labeled weak** for depth research — never as depth proof
- Peer read events only if rules/product intentionally support them
- Validated periodicity gates before any \(\omega\) shadow attach
- Separate live policy before Discover

---

## G. Version / status

| Key | Value |
| --- | --- |
| `contract_version` | `temporal_observation_contract_v1` |
| `policy_status` | Observation instrumentation: incomplete. L4 v1 **cadence diagnostics** frozen separately as `production_diagnostics_non_ranking_v1` |
| Freeze decision | L4 v1 diagnostics frozen (post-match, non-ranking). Class B / pre-match / TZ productization still open |
| Production Matching ranking | None — L4 does not affect Discover order |

---

## H. Code/data audit — metadata actually available (2026-08)

Audit of production chat/match models (`ChatService`, `MessageModel`, `ChatThreadModel`, `MatchService`). Spec-only; not an implementation.

### H.1 Available today

| Need | Actual |
| --- | --- |
| Message timestamps | **Yes** — `created_at`, `client_created_at`; thread `last_message_at` |
| Sender identity | **Yes** — `sender_id` |
| Receiver identity | **Implied only** via thread `participants` (no `receiver_id` field) |
| Reply timing | **Not stored**; **derivable** from ordered timestamps + alternating senders |
| Initiation | **Partial** — thread/match `created_at`; system “You matched!” message; **no** human initiator flag |
| Turn sequence | **Order only** — no `turn_index` |
| Activity events | **No** messaging session stream; weak `users.last_active_at` (auth), match `last_activity_at` not updated on send |
| Size class | **No** |
| Peer read receipts | **No** (usable) |
| Disclosure events | **No** content-free disclosure stream |

### H.2 Freeze readiness (Step 4)

**L4 v1 (2026-08-16):** cadence / burstiness / regularity / reply-turn / participation are **production diagnostics** on post-match thread metadata (`TemporalShadowExtractor`). Class A circadian is **conditional** on timezone. Class B ω / `phase_alignment` remain research shadow. This observation contract still describes **instrumentation gaps** (no TZ field, no disclosure events, no pre-match stream).

**Not ready** to treat Class B ω or Discover temporal ranking as frozen, because:

1. `gates_calibrated=false`; no real metadata cohort (`threads_analyzed=0`).
2. Timezone is not persisted on user docs.
3. `disclosure_pace` temporal path has no product event.
4. Chat timestamps exist **after match only** — pre-match inference is forbidden under L4 v1.

**Ready as living specification** for instrumentation. Static amplitude shadow remains separate. Mixed-state QI stays **L5**.

### Related artifacts

- Modal Resonance math: `docs/matching/qmatch_modal_resonance_model_v1_specification.md`
- Static amplitude: `lib/features/matching/domain/modal_static_amplitude_shadow_*.dart`
- Structural policy: `docs/matching/qmatch_structural_matching_production_candidate_policy_v1.md`
