# Frequency V2 EN semantic parity v1 (Phase 6A)

**Status:** dormant draft — not live-selectable  
**schema_version:** `qmatch_frequency_behavior_pool_v2`  
**EN pool_version:** `frequency_behavior_pool_en_v2_draft1`  
**TR source pool_version:** `frequency_behavior_pool_tr_v2_draft1`  
**scoring_policy_version:** `frequency_behavior_12d_signed_evidence_v2` (shared)  
**locale:** `en-US`  
**translation_version:** `frequency_v2_en_semantic_v1`  
**source_locale:** `tr-TR`

TR and EN are two semantic presentations of the **same behavioral assessment version**. EN does not introduce a new bank version, new weights, or new evidence priors.

Live routing remains unchanged:

```
FrequencyCanonicalRuntimeService.assetPathForLocale
  tr-TR → frequency_bank_tr_v1.json   (V1 live)
  en-US → frequency_bank_en_v1.json   (V1 live)
```

V2 TR and EN draft pools remain `runtime_selectable=false`.

---

## 1. Full archive parity

| Metric | TR | EN |
|---|---:|---:|
| Questions | 426 | 426 |
| Options | 1704 | 1704 |
| Selectable | 405 | 405 |
| DROP (archived) | 21 | 21 |

All `item_id` and `option_id` values are identical across locales. DROP questions stay DROP in EN.

---

## 2. Immutable structural fields

EN must match TR exactly for:

- `item_id`, `option_id`
- `primary_dimensions`, `secondary_dimensions`
- `behavioral_weights` (primary and secondary)
- `semantic_cluster`
- `crosscheck_group_ids`, `context`
- near-duplicate cluster metadata
- selector/review metadata: `selector_eligible`, `drop_from_selectable`, `rewrite_pending`, provenance fields
- `evidence_meta`: version, calibration_status, review_status, diagnostic_value, behavioral_plausibility, ambiguity, social_desirability, obviousness, self_presentation_risk

**Only user-facing language may differ:** `prompt`, option `text`, item `locale`, pool-level locale metadata.

---

## 3. Translation principle

EN wording is a **semantic translation**, not a new assessment.

- Same behavioral situation, decision pressure, relationship context, trade-off
- Same intended behavioral direction per option weight
- Same approximate intensity ordering between options (+2, +1, -1, -2)
- No moral framing or “correct answer” cues
- Do not rewrite options to sound healthier, kinder, or more socially desirable than TR

---

## 4. Translation review metadata (EN-only layer)

Separate from evidence review. Allowed `translation_review_status` values:

| Status | Meaning |
|---|---|
| `PENDING_HUMAN_REVIEW` | Default for machine-generated candidates |
| `REVIEWED` | Explicit human approval only |
| `CROSS_CULTURAL_REVIEW_REQUIRED` | Scenario may not transfer cross-culturally |
| `EVIDENCE_PARITY_REVIEW_REQUIRED` | Translation may shift obviousness / social desirability / ambiguity |

Machine triage flags (non-authoritative):

- `possible_polarity_drift`
- `possible_intensity_drift`
- `possible_unnatural_english`
- `possible_cultural_mismatch`
- `possible_ambiguity_change`
- `possible_social_desirability_shift`

Flags do **not** auto-rewrite text or change evidence priors.

---

## 5. Machine parity validator

`FrequencyBehaviorV2LocaleParityValidator` compares TR master vs EN presentation.

Fails on mismatch in:

- question/option counts and IDs
- primary/secondary dimensions
- behavioral weights
- evidence metadata
- DROP/selectable status
- semantic cluster and near-duplicate metadata
- selector/scorer-facing review fields

Build-time Python validator in `build_phase6a_en_semantic_parity_pool.py` provides the same checks for artifact generation.

---

## 6. Artifacts

| Artifact | Path |
|---|---|
| EN pool | `tool/frequency_behavior_v2/out/frequency_behavior_pool_en_v2_draft1.json` |
| EN review metadata | `tool/frequency_behavior_v2/out/frequency_behavior_pool_en_v2_draft1_review_metadata.json` |
| Phase 6A audit | `tool/frequency_behavior_v2/out/frequency_v2_phase6a_en_parity_audit.md` |
| Human review batches | `tool/frequency_behavior_v2/out/en_human_review/frequency_v2_en_review_*.md` |
| Build tool | `tool/frequency_behavior_v2/build_phase6a_en_semantic_parity_pool.py` |

---

## 7. Explicit non-goals (Phase 6A)

- Does **not** activate EN or V2 runtime routing
- Does **not** modify TR wording, weights, evidence priors, selector, scorer, confidence, or pair-fit policy
- Does **not** touch V1 banks, Firebase, C2, Discover, Persona, or matching
- Does **not** imply human-approved EN semantic quality

Human review is mandatory before runtime activation.
