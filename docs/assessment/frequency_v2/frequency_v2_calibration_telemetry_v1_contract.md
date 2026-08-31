# Frequency V2 calibration telemetry v1 (dormant)

**Status:** contract + offline tooling — **no live collection**  
**response schema:** `qmatch_frequency_behavior_v2_response_telemetry_v1`  
**session schema:** `qmatch_frequency_behavior_v2_session_telemetry_v1`  
**aggregate schema:** `qmatch_frequency_behavior_v2_calibration_aggregate_v1`  
**live_collection_enabled:** `false`

Telemetry is a **separate** layer from canonical answers, 12D scoring, provisional confidence, eligibility, and matching. Writing or aggregating telemetry **must not** change the current session result.

`runtime_selectable` remains `false`.

---

## 1. Response event

Per presented question:

| Field | Notes |
|---|---|
| `schema_version` | response telemetry schema |
| `bank_version` | frozen with the session |
| `selector_version` | frozen |
| `scorer_version` | frozen |
| `session_id` | pseudonymous session id |
| `question_id` | stable id |
| `primary_dimension` | named primary |
| `presented_option_order` | actual shuffled `option_id`s |
| `selected_option_id` | final answer; never display index |
| `presentation_index` | 0..49 |
| `response_latency_ms` | analytics value (clamped) |
| `latency_valid` | false if instrumentation was broken/extreme |
| `changed_answer_count` | distinct option transitions after the first tap |
| `final_changed` | `changed_answer_count > 0` |
| `selection_sequence` | ordered `option_id`s including the first tap (needed for changed-away / changed-to) |
| `locale` | e.g. `tr-TR` |
| `server_timestamp` | optional ISO-8601; not mixed into scoring |

Do **not** copy `behavioral_weights` or `evidence_meta` into telemetry.

Example presented order:

```json
[
  "frequency_v2_q0123_c",
  "frequency_v2_q0123_a",
  "frequency_v2_q0123_d",
  "frequency_v2_q0123_b"
]
```

---

## 2. Answer changes

`A → B → C` ⇒ `selection_sequence = [A, B, C]`, `changed_answer_count = 2`, `final_changed = true`.

Event-write time does **not** label the respondent uncertain, dishonest, or confused.

---

## 3. Latency

Elapsed monotonic client time from the question becoming interactable until final submit.

Valid range for analytics: **0 ms … 1,800,000 ms (30 min)**.

Outside that range: `latency_valid = false`, store a **clamped** `response_latency_ms` for analytics only.

The live scorer **must not** read latency. Fast/slow is not good/bad.

---

## 4. Session telemetry

| Field | Notes |
|---|---|
| versions | `schema_version`, `bank_version`, `selector_version`, `scorer_version` |
| `session_id` / `session_seed` | identity of the dormant compose |
| `locale` | |
| `question_count` | 50 |
| `started_at` / `completed_at` | optional timestamps |
| `cohort` | optional coarse fields, all nullable |

Do **not** store the 12D score or confidence payload here.

---

## 5. Optional cohort metadata

May exist when already legitimately available:

`age_bucket`, `profession_category`, `country`, `region`, `city`

Must remain **null** when missing. Must **not** affect selector or scorer.

Never store: date of birth, employer name, precise GPS. Never derive location secretly. Do **not** implement cohort-based item selection.

---

## 6. Privacy

Canonical assessment data and calibration telemetry are separate stores.

Telemetry must not contain: name, email, phone, free-text bio, precise GPS, advertising IDs, contacts, photos.

Prefer session-level / pseudonymous aggregation. User identifiers only if a future backend strictly requires them (not in this dormant contract).

**Retention is configurable, not permanent-by-default** (`telemetryRetentionPolicy = configurable`). No retention clock is started because live collection is off.

---

## 7. Offline aggregates

Tooling only. Does **not** auto-update evidence priors.

Per question: `impressions`, `final_changed_rate`, latency p25/median/p75 (valid samples only), `sample_size`.

Per option: `selections`, `selection_share`, `selection_by_presented_position` (slots 0–3), `changed_away_count`, `changed_to_count`, option-level latency percentiles, `sample_size`.

`shrinkToGlobal` exists as a **disabled** shrinkage hook and returns null. This phase does not invent calibrated coefficients.

---

## 8. Cross-check calibration

For pairs of questions with the **same primary** and **different** `semantic_cluster`, over sessions where both were answered with a nonzero primary weight:

- `directional_agreement` — same sign
- `directional_disagreement` — opposite sign
- `pair_count` / `sample_size`

Disagreement is **not** lying, dishonesty, or inconsistent character.

---

## 9. Small-N safety

Every aggregate row exposes `sample_size`.

Cohort-specific slices with `n < MIN_COHORT_N` (**default 100**) are emitted as `suppressed=true` with reason `n_below_min_cohort_n`. Do not interpret those slices.

---

## 10. Version freeze

Every event retains `bank_version`, `selector_version`, `scorer_version`.

Future calibration changes require a **new** evidence/config version. Never silently alter an in-progress session.

---

## 11. What this phase does not do

- Deploy or enable live collection (`publishLive` throws)
- Activate V2
- Modify selector, scorer, confidence, questions, weights, or evidence priors
- Auto-recalibrate
- Lie detection
- Touch V1, Firebase, C2, Discover, Persona, matching
- Quantum layer

Offline audit:

```text
dart run tool/frequency_behavior_v2/simulate_phase4c_telemetry.dart
```
