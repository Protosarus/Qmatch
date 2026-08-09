# QMatch IQ Live Result Persistence v1

**Phase:** P2C-2A-5
**Schema:** `qmatch_iq_live_result_v1`
**Collection:** `users/{uid}/assessments/iq`

---

## Design

Prefer a **versioned canonical payload** rather than forcing 4D data into the
legacy scalar `iq_score` field.

`AssessmentProgressService.markIqCompleted(rawScore: null)` still sets
`iq_completed: true` for onboarding routing **without** writing a fake IQ number.

---

## Written fields (canonical)

| Field | Notes |
|-------|-------|
| `live_result_schema_version` | `qmatch_iq_live_result_v1` |
| `bank_version` / `bank_locale` | Bound to session |
| `selection_policy_version` / `scoring_policy_version` | Frozen policy IDs |
| `session_id` | Opaque |
| `question_count` / `answered_count` | 25 / 25 |
| `status` | `completed` |
| `calibration_status` | `uncalibrated` |
| `iq_result_kind` | `uncalibrated_reasoning_profile_v1` |
| `dimension_scores` | map dimension → provisionalScore [0,1] |
| `dimension_evidence_counts` | answered counts |
| `canonical_dimensions[]` | per-dim correct/incorrect/raw/provisional |
| `dimension_reliability` | `{}` (not fabricated) |
| `canonical_profile_ready` | `false` (20D not wired) |
| `structural_flags` | complete/quota/bank |

## Explicitly omitted

- `raw_score` / legacy scalar IQ identity
- `correct_option_id` / answer keys
- question prompts
- percentiles / standardized IQ
- reliability estimates
- PII

## Legacy compatibility

Older clients that only read `users/{uid}.iq_score` may see it **absent** for
new canonical completions. EQ intro accepts `iqScore: 0` and may recover from
Firestore when needed; Discover uses `iq_normalized` / flow completion, not this
scalar, for gating.
