# QMatch IQ 4D Scoring Contract v1

**Phase:** P2C-2A-4
**Status:** IMPLEMENTED_OFFLINE
**Scientific label:** uncalibrated multidimensional reasoning performance
**Not:** standardized IQ, percentile, IRT theta, or clinical classification

---

## Scoring policy version

`scoring_policy_version` = **`iq_4d_uncalibrated_accuracy_v1`**

Meaning:

For each canonical dimension:

```
rawAccuracy = correctCount / itemCount
provisionalScore = rawAccuracy
```

Quotas:

| Dimension | itemCount |
|-----------|-----------|
| logical_reasoning | 7 |
| pattern_reasoning | 6 |
| verbal_reasoning | 6 |
| spatial_reasoning | 6 |

Range: `0.0 ≤ provisionalScore ≤ 1.0`

Explicitly **does not** apply difficulty weighting, IRT, z-scores, percentiles,
or nonlinear transforms.

---

## Correctness derivation

```
correct ⇔ answer.selected_option_id == bank_item.correct_option_id
```

Never score by displayed A/B/C/D position or list index.

---

## Result schema (`qmatch_iq_canonical_scoring_result_v1`)

- schema_version, bank_version, bank_locale
- selection_policy_version, scoring_policy_version
- session_id
- dimension_scores[4] in fixed order
- total_answered (=25)
- created_at
- calibration_status = `uncalibrated`
- structural_flags: complete_session, quota_valid, canonical_bank_valid
- reliability_estimate = null
- empirical_uncertainty = null

### Per dimension

correct_count, incorrect_count, answered_count, item_count,
raw_accuracy, provisional_score, calibration_status

### Explicitly absent

overallIq, iqScore, percentile, strongest/weakest labels, quantum fields,
correct answers, question text, PII.

---

## Preconditions

Only a **completed** validated 25-answer session is scored.
Incomplete → `session_incomplete` (no partial final profile).

---

## UI note

A later presentation layer may show `100 * provisionalScore` as a
**dimension performance percentage**. That percentage must **not** be labeled IQ.
