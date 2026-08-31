# Frequency V2 scorer v1 (dormant 12D + confidence primitives)

**Status:** dormant — not live-selectable  
**scorer_version:** `frequency_behavior_v2_scorer_v1`  
**score schema:** `qmatch_frequency_behavior_v2_session_score_v1`  
**selector_version:** `frequency_behavior_v2_selector_v1`  
**bank_version:** `frequency_behavior_pool_tr_v2_draft1`

This scorer reads a dormant 50-question V2 session and signed `behavioral_weights`. It does **not** write Frequency V1 6D slots, does **not** emit a single user-facing Frequency number, and does **not** collapse confidence primitives into one coefficient.

`runtime_selectable` remains `false`. There is no 12D→6D adapter.

---

## 1. Inputs

| Input | Role |
|---|---|
| pool / `bank_version` | Authored options, weights, evidence priors |
| session manifest | Presented 50 `question_id`s (capacity denominator) |
| responses | Selected `option_id` per question |
| near-duplicate clusters | Exclude those pairs from cross-context |

Same pool + manifest + answers ⇒ same score JSON.

Lookup is by stable `option_id`. Display index is never an identity.

Not used for **behavioral direction**:

- evidence metadata (any of the six fields)
- age, profession, location, gender
- previous sessions / personality estimates
- response speed

---

## 2. Behavioral vector (weights only)

For every presented question and every canonical dimension `d`:

```
selected_contribution[d] = selected.behavioral_weights[d] or 0 if absent
question_capacity[q,d]   = max |behavioral_weights[d]| across the four authored options
```

Use **all** authored keys, including secondary weights. Missing key ≠ manufactured primary.

```
raw_sum[d]              = Σ selected_contribution[d]
capacity[d]             = Σ question_capacity[q,d]   over presented questions
normalized_behavior[d]  = raw_sum[d] / capacity[d]   when capacity[d] > 0
```

Range is **[-1.0, +1.0]**. Capacity 0 ⇒ `normalized_behavior` is **null**, not 0.

This is opportunity-aware: a question whose options only reach ±1 does not dominate a question whose options reach ±2.

`normalized_behavior` is **not** labeled good/bad, healthy/unhealthy, secure/insecure, or strong/weak personality.

---

## 3. Primary-dimension signal

For each presented question with exactly one canonical primary `p`:

```
primary_signal = selected.behavioral_weights[p] or 0 if absent
```

Observed values: **-2, -1, 0, +1, +2**. Zero means the answer does not cleanly express the named primary. It is not automatically “inconsistent.”

Per dimension:

- `primary_question_count`
- `nonzero_primary_signal_count`
- `zero_primary_signal_count`
- `primary_signal_coverage` = nonzero / count when count > 0

---

## 4. Cross-context consistency

This is **not** a lie detector. It asks whether primary signals on the same dimension point a similar direction across **different** `semantic_cluster` values.

For each pair of that dimension’s primary questions:

1. Skip if `semantic_cluster` is the same.
2. Remaining pairs are `possible_cross_context_pair_count`.
3. Skip known near-duplicate pairs. Remaining are `eligible_cross_context_pair_count`.
4. `pair_similarity = 1 - abs(signal_a - signal_b) / 4`

Examples: +2 vs +2 → 1.00; +2 vs +1 → 0.75; +1 vs −1 → 0.50; +2 vs −2 → 0.00.

```
cross_context_consistency = mean eligible pair_similarity
cross_context_coverage    = eligible / possible
```

If `eligible == 0`: consistency is **null**, not 0. Missing cross-context data is not treated as disagreement.

Opposite eligible signals **are** 0.00 consistency — that is observed disagreement, not missing data.

---

## 5. Evidence primitives (kept separate)

For each selected option, read the authored uncalibrated priors:

`diagnostic_value`, `behavioral_plausibility`, `ambiguity`, `social_desirability`, `obviousness`, `self_presentation_risk`

Dimension-level **means** are over answered primary questions for that dimension. They must **not**:

- change sign of `normalized_behavior`
- move `raw_sum`
- amplify “positive” answers
- suppress socially desirable answers

Phase 4A does **not** invent a weighted confidence formula, percentile, or deception score. Phase 4B adds a separate labeled heuristic (`frequency_v2_confidence_v1_contract.md`) that still does not move `normalized_behavior`.

---

## 6. Signal coverage (confidence inputs, not direction)

```
absolute_selected_signal[d] = Σ |selected_contribution[d]|
signal_utilization[d]       = absolute_selected_signal[d] / capacity[d]
```

when `capacity[d] > 0`. These describe how much of the available signed range was used. They are not a personality score.

---

## 7. Result model

```json
{
  "schema_version": "qmatch_frequency_behavior_v2_session_score_v1",
  "scorer_version": "frequency_behavior_v2_scorer_v1",
  "bank_version": "frequency_behavior_pool_tr_v2_draft1",
  "selector_version": "frequency_behavior_v2_selector_v1",
  "session_id": "...",
  "dimensions": [
    {
      "dimension_id": "initiative",
      "raw_sum": 0.0,
      "capacity": 0.0,
      "normalized_behavior": null,
      "primary_question_count": 4,
      "nonzero_primary_signal_count": 0,
      "zero_primary_signal_count": 4,
      "primary_signal_coverage": 0.0,
      "absolute_selected_signal": 0.0,
      "signal_utilization": 0.0,
      "cross_context_consistency": null,
      "eligible_cross_context_pair_count": 0,
      "possible_cross_context_pair_count": 0,
      "cross_context_coverage": null,
      "mean_diagnostic_value": null,
      "mean_behavioral_plausibility": null,
      "mean_ambiguity": null,
      "mean_social_desirability": null,
      "mean_obviousness": null,
      "mean_self_presentation_risk": null
    }
  ]
}
```

Canonical 12D: `contact_need`, `closeness_pace`, `initiative`, `autonomy`, `reassurance_need`, `uncertainty_tolerance`, `disclosure_pace`, `boundary_firmness`, `repair_style`, `social_energy`, `structure_preference`, `adaptability`

---

## 8. What this phase does not do

- Activate V2 or set `runtime_selectable=true`
- Emit a single Frequency score, percentile, or norm table
- Combine evidence fields into one confidence coefficient
- Lie / deception / clinical / “true personality” claims
- Quantum / density-matrix layer
- Modify selector, questions, weights, or evidence priors
- Touch V1 banks, Firebase, C2, Discover, Persona, matching
- Build a 12D→6D map

Offline audit:

```text
dart run tool/frequency_behavior_v2/simulate_phase4a_scorer.dart
dart run tool/frequency_behavior_v2/simulate_phase4b_confidence.dart
```
