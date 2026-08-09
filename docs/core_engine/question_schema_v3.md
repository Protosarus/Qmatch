# Question Schema v3

**Status:** authoring/contract freeze (P2A-1)  
**Machine-readable:** `assets/schemas/qmatch_question_schema_v3.json`  
**Not runtime-loaded** in production Flutter in this phase.

## Goals

One schema family for IQ, EQ, and Frequency with module-specific required fields. Supports future bank files without changing live JSON in this phase.

## Shared item fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `question_id` | string | yes | Stable unique id |
| `module` | `iq`\|`eq`\|`frequency` | yes | |
| `schema_version` | string | yes | e.g. `qmatch_question_schema_v3` |
| `content_version` | string | yes | Item content generation |
| `locale` | object | yes | At least `tr`, `en` prompt coverage |
| `status` | string | yes | workflow status |
| `review_state` | string | yes | mirrors review workflow |
| `item_type` | string | yes | `mcq_keyed`\|`mcq_evidence`\|`likert`\|`scenario_mcq` |
| `primary_dimension` | string | yes | Canonical dimension id |
| `secondary_dimensions` | string[] | no | Controlled list |
| `prompt` | localized object | yes | `{tr, en}` |
| `options` | array | conditional | Required for MCQ; empty/absent for Likert only if Likert contract present |
| `explanation_availability` | string | no | `none`\|`reviewer_only`\|`post_answer_iq` |
| `anchor_group` | string\|null | no | |
| `semantic_pair_id` | string\|null | no | |
| `reverse_pair_id` | string\|null | no | |
| `behavioral_isomorph_group` | string\|null | no | |
| `separator_targets` | string[] | no | Persona ids for adaptive pool only |
| `response_validity_roles` | string[] | no | See RVI blueprint |
| `exposure_class` | string | yes | |
| `security_level` | string | yes | `standard`\|`elevated`\|`secure_iq` |
| `estimated_completion_seconds` | number | yes | |
| `authoring_notes` | string | no | Internal |
| `created_at` | string (ISO date) | yes | |
| `updated_at` | string (ISO date) | yes | |

## IQ-specific fields

| Field | Required |
|---|---|
| `correct_option_id` | yes |
| `solution_method` | yes |
| `cognitive_domain` | yes (= primary_dimension) |
| `difficulty` | yes (`1..5` provisional) |
| `estimated_discrimination` | provisional optional |
| `distractor_logic` | yes (per distractor or item-level) |
| `calibration_status` | yes |

## EQ/Frequency option fields

| Field | Required |
|---|---|
| `option_id` | yes |
| `localized_text` | yes `{tr,en}` |
| `dimension_deltas` | yes map canonical_dim → number in `[-1,1]` |
| `evidence_strength` | yes `[0,1]` |
| `counter_evidence` | no |
| `social_desirability_risk` | yes `low`\|`moderate`\|`high` |
| `extremity` | yes `[0,1]` |
| `response_style_risk` | yes |
| `rationale` | reviewer |
| `status` | yes |

## Forbidden on EQ/Frequency options

- `correct: true` / `correctAnswer` / `correct_option_id` as scoring truth  
- direct persona id scoring  
- persona points  
- HH/HM…LL classification  
- Frequency descriptive type assignment  

## Likert Frequency items

May use `item_type: likert` with `likert_scale` (`min`,`max`,`reverse_scored`) and map scale points to `dimension_deltas` via explicit `scale_point_deltas` so evidence remains auditable.

## Validation principles

- Unknown dimension ids → reject  
- Persona ids only allowed in `separator_targets`, never as score outputs  
- Schema version must be explicit on every item  
