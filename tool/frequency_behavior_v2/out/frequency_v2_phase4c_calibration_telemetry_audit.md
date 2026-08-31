# Frequency V2 Phase 4C — Calibration telemetry audit

Status: **offline / dormant**. `runtime_selectable` remains false.
live_collection_enabled: false
response schema: `qmatch_frequency_behavior_v2_response_telemetry_v1`
session schema: `qmatch_frequency_behavior_v2_session_telemetry_v1`
aggregate schema: `qmatch_frequency_behavior_v2_calibration_aggregate_v1`
bank_version: `frequency_behavior_pool_tr_v2_draft1`
selector_version: `frequency_behavior_v2_selector_v1`
scorer_version: `frequency_behavior_v2_scorer_v1`
retention_policy: `configurable`
MIN_COHORT_N: 100
Synthetic sessions: 8
Synthetic events: 400

Telemetry is separate from canonical answers, 12D scoring, provisional confidence, eligibility, and matching. This audit does **not** enable live collection and does **not** auto-update evidence priors.

## Synthetic checks

| Check | Result |
|---|---|
| option position recoverable | **true** |
| A→B→C change count = 2 | **true** |
| latency does not change normalized_behavior | **true** |
| latency does not change provisional_confidence | **true** |
| score JSON identical without telemetry inputs | **true** |
| cohort metadata does not change selector | **true** |
| missing cohort metadata is valid | **true** |
| low-N cohort slices suppressed (`n_below_min_cohort_n`) | **true** |
| question/option impression counts reconcile | **true** |
| selection_share sums to 1.0 | **true** |
| selection_by_presented_position sums to selections | **true** |
| bank/selector/scorer versions frozen on events | **true** |
| invalid latency flagged (`latency_valid=false`) | **true** |
| shrinkToGlobal returns null | **true** |
| publishLive throws | **true** |
| forbidden PII keys absent | **true** |
| events omit weights / evidence | **true** |
| runtime_selectable | **false** |

## Position recovery example

question_id: `frequency_v2_q0103`
presented_option_order: `[frequency_v2_q0103_d, frequency_v2_q0103_a, frequency_v2_q0103_b, frequency_v2_q0103_c]`
selected_option_id: `frequency_v2_q0103_a`
selected_presented_position: `1`

## Answer-change example

question_id: `frequency_v2_q0103`
selection_sequence: `[frequency_v2_q0103_d, frequency_v2_q0103_b, frequency_v2_q0103_a]`
changed_answer_count: 2
final_changed: true

Event-write time does not label the respondent uncertain, dishonest, or confused.

## Latency sanitizer

Valid analytics range: 0 … 1800000 ms.
Session 0 / index 0 raw `-50` → analytics `0`, valid `false`.
Session 0 / index 1 raw `9000000` → analytics `1800000`, valid `false`.
Example stored event: question `frequency_v2_q0103` response_latency_ms=0 latency_valid=false.

The scorer does not read latency. Fast/slow is not good/bad.

## Cohort slices (small-N safety)

| key | value | n | suppressed | reason |
|---|---|---|---|---|
| age_bucket | 25-34 | 7 | true | n_below_min_cohort_n |
| country | TR | 7 | true | n_below_min_cohort_n |

Cohort fields are optional and nullable. They are never inputs to the selector or scorer. Do not interpret slices below MIN_COHORT_N.

## Cross-check calibration (not lie detection)

pair rows: 471
directional_agreement total: 488
directional_disagreement total: 15

Disagreement is not lying, dishonesty, or inconsistent character.

Highest pair_count sample (up to 8):

| dimension | q_a | q_b | pair_count | agree | disagree | n |
|---|---|---|---|---|---|---|
| adaptability | frequency_v2_q0096 | frequency_v2_q0255 | 3 | 3 | 0 | 3 |
| structure_preference | frequency_v2_q0151 | frequency_v2_q0285 | 3 | 3 | 0 | 3 |
| contact_need | frequency_v2_q0077 | frequency_v2_q0169 | 2 | 2 | 0 | 2 |
| contact_need | frequency_v2_q0077 | frequency_v2_q0187 | 2 | 2 | 0 | 2 |
| contact_need | frequency_v2_q0205 | frequency_v2_q0279 | 2 | 2 | 0 | 2 |
| contact_need | frequency_v2_q0254 | frequency_v2_q0279 | 2 | 2 | 0 | 2 |
| contact_need | frequency_v2_q0254 | frequency_v2_q0386 | 2 | 2 | 0 | 2 |
| contact_need | frequency_v2_q0279 | frequency_v2_q0386 | 2 | 2 | 0 | 2 |

## Aggregate sample sizes

question rows: 256
session_count: 8
event_count: 400
shrinkage_enabled: false

Highest-impression questions (up to 8):

| question_id | primary | impressions / sample_size | final_changed_rate | latency median (valid) |
|---|---|---|---|---|
| frequency_v2_q0077 | contact_need | 4 | 0.000 | 834 |
| frequency_v2_q0096 | adaptability | 4 | 0.000 | 912 |
| frequency_v2_q0104 | uncertainty_tolerance | 4 | 0.250 | 741 |
| frequency_v2_q0151 | structure_preference | 4 | 0.000 | 947 |
| frequency_v2_q0248 | closeness_pace | 4 | 0.250 | 794 |
| frequency_v2_q0279 | contact_need | 4 | 0.250 | 946 |
| frequency_v2_q0283 | reassurance_need | 4 | 0.000 | 796 |
| frequency_v2_q0285 | structure_preference | 4 | 0.000 | 771 |

## Privacy

Canonical assessment data and calibration telemetry are separate. Events do not contain name, email, phone, free-text bio, precise GPS, advertising IDs, contacts, or photos. Retention is configurable, not permanent-by-default. No live collection clock is started.

## What this phase does not do

- deploy or enable live telemetry
- activate V2
- modify scoring, confidence, selector, or evidence priors
- auto-recalibrate anything
- use age / location / profession for question selection
- create lie detection
- touch V1 / Firebase / C2 / Discover / Persona / matching
- implement quantum layer

FREQUENCY V2 PHASE 4C CALIBRATION TELEMETRY CONTRACT READY — NO LIVE COLLECTION — V2 STILL DORMANT
