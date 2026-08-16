# QMatch Temporal Feature Extraction v1

| Field | Value |
| --- | --- |
| Spec id | `temporal_feature_extraction_v1` |
| Status | `production_diagnostics_non_ranking_v1` (cadence family); circadian **conditional**; Class B \(\omega\) **out of scope** here |
| Scope | Post-match shadow/production **diagnostics** from **already stored** chat metadata only. **Does not rank Discover.** |
| Inputs allowed | `created_at` / `client_created_at`, `sender_id`, thread `participants` |
| Explicitly forbidden | Message-body NLP, questionnaire→phase/ω, fabricated \(\omega\), Discover ranking, Persona, quantum, RVI |
| Parents | [Temporal Observation Contract v1](./qmatch_temporal_observation_contract_v1.md), [Modal Resonance Model v1](./qmatch_modal_resonance_model_v1_specification.md) |

---

## 0. Purpose

Define exact, computable **shadow diagnostic** features for offline / future shadow pipelines using only metadata QMatch already persists on `threads/{id}/messages/{id}` and thread participant lists.

This is **not** Modal Resonance with general \(\phi_m\) or \(\omega_m\).  
Circadian timing below is **only** a 24h clock phase on the circadian oscillator.

---

## 1. Input event model (existing data)

For a thread with participants \(\{P,Q\}\), each user message (exclude `sender_id == "system"` unless noted):

\[
e_k = (t_k,\; s_k)
\]

- \(t_k\): prefer `client_created_at` (ms) when present and finite; else `created_at`
- \(s_k \in \{P,Q\}\): `sender_id`

Sort ascending by \(t_k\). Drop events with missing/invalid timestamps. **Do not impute times.**

Window \(W=[t_{\mathrm{start}}, t_{\mathrm{end}}]\) (analysis window). Let \(T_W = t_{\mathrm{end}}-t_{\mathrm{start}}\) in seconds (require \(T_W>0\)).

**Timezone:** convert \(t_k\) to the actor’s **local civil time** when available; if unknown, mark circadian features `unavailable` (do not assume UTC = local).

---

## 2. Exact formulas

All features return a value **or** status `sparse` / `unavailable`. Never invent defaults.

### 2.1 Event count

User-level (actor \(U\in\{P,Q\}\)):

\[
N_U = \#\{k : s_k=U,\; t_k\in W\}
\]

Dyadic (both sides, human messages only):

\[
N_{PQ} = \#\{k : s_k\in\{P,Q\},\; t_k\in W\}
\]

Also emit \(N_P\), \(N_Q\) inside the dyad window.

### 2.2 Inter-event intervals

For actor \(U\), let ordered times \(t^{(U)}_1 < \cdots < t^{(U)}_{N_U}\).

\[
\delta^{(U)}_j = t^{(U)}_{j+1} - t^{(U)}_j
\quad (j=1,\ldots,N_U-1),\quad \delta>0
\]

Dyadic send stream (all human messages in order), intervals \(\delta^{(PQ)}_j\) similarly on the merged timeline.

Reject non-positive intervals (clock anomalies) by dropping that interval, not imputing.

### 2.3 Cadence / event rate (not \(\omega\))

\[
\lambda^{\mathrm{mean}}_U = \frac{N_U}{T_W}
\qquad
\lambda^{\mathrm{med}}_U =
\begin{cases}
1\big/\mathrm{median}\{\delta^{(U)}_j\} & N_U\ge 2 \text{ and } \ge 1 \text{ valid }\delta \\
\texttt{unavailable} & \text{otherwise}
\end{cases}
\]

Units: events per second (or report per day as \(\lambda\cdot 86400\)).  
**Label:** `event_rate_*` / `cadence_*`. **Never** `omega`.

### 2.4 Burstiness

Goh–Barabási burstiness on actor intervals (requires \(\ge 3\) intervals ⇒ \(N_U\ge 4\)):

\[
m=\mathrm{mean}(\delta),\quad
\sigma=\mathrm{stdev}(\delta)\quad\text{(sample stdev)}
\]

\[
B_U = \frac{\sigma - m}{\sigma + m} \in (-1,1]
\]

If \(m+\sigma=0\) (degenerate) → `unavailable`.

### 2.5 Regularity

Coefficient of variation on intervals:

\[
\mathrm{CV}_U = \frac{\sigma}{m}
\quad (m>0),\qquad
R_U = \frac{1}{1+\mathrm{CV}_U} \in (0,1]
\]

Same minimum interval count as burstiness. High \(R\) ⇒ more regular cadence (still **not** periodic \(\omega\)).

### 2.6 Approximate turn / reply gaps

**Derivation only** (no `reply_to` field exists).

Scan merged ordered human messages. A **reply candidate** occurs when \(s_{k}\neq s_{k-1}\):

\[
g_k = t_k - t_{k-1}
\]

Collect gaps for:

- \(G_{P\leftarrow Q}\): \(s_k=P\), \(s_{k-1}=Q\) (P replies to Q)
- \(G_{Q\leftarrow P}\): \(s_k=Q\), \(s_{k-1}=P\)

Optional timeout: discard \(g_k > T_{\mathrm{reply}}\) (provisional default \(T_{\mathrm{reply}}=24\mathrm{h}\), **not calibrated**).

Summaries:

\[
\mathrm{medReply}_{P\leftarrow Q}=\mathrm{median}(G_{P\leftarrow Q}),
\quad
\mathrm{medTurn}_{PQ}=\mathrm{median}(\text{all alternating }g_k)
\]

These are **approximate tempo diagnostics**, not phase and not \(\omega\).

### 2.7 Participation share and dyadic participation balance

These are **send-count participation diagnostics only**.  
They are **not** full behavioral reciprocity. Reply/turn timing remains a separate dyadic signal (§2.6).

\[
\mathrm{participation\_share}_P
=
\frac{N_P}{N_P+N_Q}
\in [0,1]
\quad (N_P+N_Q\ge 1)
\]

\[
\mathrm{participation\_share}_Q
=
1-\mathrm{participation\_share}_P
\]

\[
\mathrm{dyadic\_participation\_balance}
=
1 - 2\,\bigl|\mathrm{participation\_share}_P - 0.5\bigr|
\in [0,1]
\]

Interpretation of balance:

| Split | \(\mathrm{participation\_share}_P\) | \(\mathrm{dyadic\_participation\_balance}\) |
| --- | ---: | ---: |
| 50/50 | 0.5 | 1.0 |
| 75/25 | 0.75 | 0.5 |
| 100/0 | 1.0 | 0.0 |

Not a Matching score.

### 2.8 Hour-of-day activity distribution

For actor \(U\), local hour \(h_k\in\{0,\ldots,23\}\) from \(t_k\):

\[
c_U(h) = \#\{k:s_k=U,\; h_k=h\}
\quad
\hat{c}_U(h)=\frac{c_U(h)}{N_U}
\quad (N_U\ge 1)
\]

Emit histogram vector \(\hat{\mathbf{c}}_U\in\Delta^{23}\) (24-simplex) or raw counts + \(N_U\).

### 2.9 Circadian timing phase (24h oscillator only)

**Oscillator id (required on wire):** `circadian_24h`.  
This is **not** general modal \(\phi_m\).

For each event of actor \(U\), local time-of-day \(\tau_k\in[0,86400)\):

\[
\theta_k = 2\pi\,\frac{\tau_k}{86400}
\]

Circular mean:

\[
\bar{C}=\frac{1}{N_U}\sum_k\cos\theta_k,
\quad
\bar{S}=\frac{1}{N_U}\sum_k\sin\theta_k
\]

\[
\bar{R}_U=\sqrt{\bar{C}^2+\bar{S}^2}\in[0,1]
\quad\text{(resultant length / concentration)}
\]

\[
\bar{\theta}_U=
\mathrm{atan2}(\bar{S},\bar{C})
\in(-\pi,\pi]
\quad\text{(or mapped to }[0,2\pi)\text{)}
\]

Dyadic circadian offset (same oscillator):

\[
\Delta\bar{\theta}_{PQ}
=
\mathrm{wrap}_{[-\pi,\pi]}(\bar{\theta}_P-\bar{\theta}_Q)
\]

only when both \(\bar{\theta}_P,\bar{\theta}_Q\) are available.

**If** \(\bar{R}_U\) below concentration gate → phase `sparse`/`unavailable` even if \(N_U\) is large (uniform hours ⇒ no meaningful clock preference).

---

## 3. Availability gates

### 3.1 Provisional minimum-data gates — **NOT CALIBRATED**

These are engineering placeholders for shadow diagnostics. They are **not** product SLOs and must be retuned on real cohorts before any freeze.

| Feature | Provisional `ok` | Provisional `sparse` | `unavailable` |
| --- | --- | --- | --- |
| Event count | always emit \(N\) when window valid | — | invalid window |
| Intervals | \(N_U\ge 2\) | — | \(N_U<2\) |
| \(\lambda^{\mathrm{mean}}\) | \(N_U\ge 5\), \(T_W\ge 3\mathrm{d}\) | \(1\le N_U<5\) or \(1\mathrm{d}\le T_W<3\mathrm{d}\) | \(N_U=0\) or \(T_W\) too small |
| \(\lambda^{\mathrm{med}}\) | \(N_U\ge 5\), \(\#\delta\ge 4\), \(T_W\ge 3\mathrm{d}\) | fewer intervals | no intervals |
| Burstiness / regularity | \(\#\delta\ge 5\) (\(N_U\ge 6\)), \(T_W\ge 7\mathrm{d}\) | \(3\le\#\delta<5\) | \(\#\delta<3\) |
| Reply / turn gaps | \(\#g\ge 8\) in relevant set, \(T_W\ge 7\mathrm{d}\) | \(3\le\#g<8\) | \(\#g<3\) |
| Participation share / dyadic participation balance | \(N_P+N_Q\ge 10\) | \(2\le N_P+N_Q<10\) | \(N_P+N_Q<2\) |
| Hour histogram | \(N_U\ge 10\), ≥3 distinct local days | \(5\le N_U<10\) | \(N_U<5\) or no local TZ |
| Circadian \(\bar{\theta},\bar{R}\) | histogram `ok` **and** \(\bar{R}\ge 0.35\) (provisional) **and** ≥4 distinct days | histogram `sparse` or \(0.20\le\bar{R}<0.35\) | no TZ, \(N\) low, or \(\bar{R}<0.20\) |
| \(\omega\) (periodic) | **out of scope for v1 extraction** | — | always `unavailable` here |

Mark every payload with `gates_calibrated: false`.

### 3.2 Hard rules

- Missing timestamp / missing local TZ (for circadian) → exclude or unavailable; no imputation.
- System messages excluded from cadence/reply/circadian by default.
- No questionnaire values enter these features.
- No message text length/content enters these features.

---

## 4. User-level vs dyadic features

| Feature | User-level | Dyadic |
| --- | --- | --- |
| Event count | \(N_U\) | \(N_{PQ}, N_P, N_Q\) |
| Intervals / cadence | \(\delta^{(U)},\lambda_U\) | optional merged-stream cadence |
| Burstiness / regularity | \(B_U, R_U\) | optional on merged stream (label clearly) |
| Reply / turn gaps | — | \(G_{P\leftarrow Q}\), \(G_{Q\leftarrow P}\), medians |
| Participation share / balance | — | \(\mathrm{participation\_share}_P\), \(\mathrm{dyadic\_participation\_balance}\) |
| Hour histogram | \(\hat{\mathbf{c}}_U\) | side-by-side compare only |
| Circadian \(\bar{\theta},\bar{R}\) | per actor | \(\Delta\bar{\theta}_{PQ}\) when both ok |

Recommended shadow attach unit: **per thread dyad** plus optional **per-user aggregate across threads** (separate status/coverage).

---

## 5. Which Frequency modes each feature may inform (if any)

Informational mapping for later modal amplitude research — **not** an implemented \(A_m(t)\) estimator and **not** structural Matching.

| Feature | May inform (weak→strong) | Must not claim |
| --- | --- | --- |
| Event count / \(\lambda\) | `social_energy` (activity volume) | depth, disclosure, \(\omega\) |
| Burstiness \(B\) | `spontaneity` | \(\omega\), phase |
| Regularity \(R\) | `stability` | demonstrated periodicity |
| Reply/turn medians | `communication_pace` (tempo) | circadian \(\phi_m\), \(\omega\) |
| Participation share / balance | send-count balance diagnostic only (not full reciprocity) | any Frequency mode alone |
| Hour histogram | support for circadian timing | modal \(\phi_m\) |
| Circadian \(\bar{\theta},\bar{R}\) | **circadian timing only**; stability/social timing research | general \(\phi_m\), questionnaire phase |
| \(\Delta\bar{\theta}_{PQ}\) | dyadic clock-offset diagnostic | Modal Resonance phase without policy |

---

## 6. What must remain unavailable in this v1 extraction

| Item | Reason |
| --- | --- |
| General modal \(\phi_m\) | Only `circadian_24h` timing phase is defined here |
| \(\omega_m\) / angular frequency | No periodicity demonstration pipeline in v1 |
| Questionnaire→phase/frequency | Forbidden |
| `disclosure_pace` temporal | No `disclosure_marked` events |
| `depth_preference` from text/size | No size_class field; text NLP forbidden |
| Peer read-latency | Receipts not usable |
| Session_active features | Not stored |
| Human initiator rate (clean) | No first-human-initiator flag (only derivable heuristics — leave out of v1) |
| Fusion into Discover / structural score | Out of scope |

---

## 7. Wire shape (shadow diagnostic)

Suggested JSON keys (illustrative):

```text
temporal_feature_extraction_v1:
  scoring_version: temporal_feature_extraction_v1
  policy_status: production_diagnostics_non_ranking_v1
  gates_calibrated: false
  shadow_only: true
  affects_discover_ranking: false
  window: { start, end }
  user_features: { ... }
  dyadic_features: { ... }
  circadian_24h: { theta_bar, R_bar, status, oscillator_id: circadian_24h }  # conditional on TZ
  omega: unavailable
  notes: []
```

---

## 8. Implementation status

Implemented: `TemporalShadowExtractor` under `lib/features/matching/domain/temporal_shadow*.dart`.  
L4 v1 freeze: [qmatch_l4_temporal_diagnostics_contract_v1.md](./qmatch_l4_temporal_diagnostics_contract_v1.md).

Does **not** wire Discover ranking, Persona, quantum/L5, RVI, or structural Matching.  
`last_active_at` is not an input. Class B \(\omega\) stays unavailable in this extractor.

---

## 9. Version / status

| Key | Value |
| --- | --- |
| `scoring_version` | `temporal_feature_extraction_v1` |
| `policy_status` | `production_diagnostics_non_ranking_v1` |
| Production ranking | None |
| Discover ranking/UI | Unchanged |
