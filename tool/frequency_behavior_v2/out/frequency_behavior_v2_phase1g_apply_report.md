# Frequency V2 Phase 1G — Apply 26 human-approved rewrites

Status: **draft_not_runtime**. V2 remains dormant. Evidence-layer values were not assigned.

Authority: `docs/qmatch_frequency_v2_phase1f_final_human_rewrites.txt`

The 26 human-authority IDs matched the Phase 1F rewrite-pending set exactly. No ID mismatch.

## Authoring contract (these 26)

- Positive/negative signs are directions on a behavioral axis, not good/bad scores.
- Exactly one designed primary dimension per item.
- The test stem does not directly name the latent construct.
- Wording is situational and respondent-behavior based.
- Evidence-layer scores are deliberately separate and still pending.

## Counts

- **Rewritten question count:** 26
- **Rewritten option count:** 104
- **Archive questions/options:** 426 / 1704
- **DROP archived/non-selectable count:** 18
- **Rewrite-pending count after apply:** 0
- **Dormant selectable pool count:** 408
- **Selectable questions with exactly one primary:** 408
- **Selectable questions with dual primary:** 0
- **Archive items with exactly one primary:** 416
- **Archive items with empty primary:** 6
- **Archive items with dual primary IDs:** 4 (DROP-only leftovers)
- **Options with zero canonical behavioral evidence:** 0
- **evidence_meta:** still all `null` / `review_status=pending` (unassigned); assigned numeric fields = 0
- **runtime_selectable:** false
- **V1 SHA-256:** not modified in this phase (confirmed by tests): frequency_bank_tr_v1.json 1ab16a99f75b4d5122bda3b9cd450e13cb7da87895ffadfb5459dc5cf4fe4744; frequency_bank_en_v1.json 367836025990121ed0fbc8703dcaabcba8ab39dd49ceb36d97e175c8f33afba4
- **Live routing unchanged:** locale still loads `frequency_bank_*_v1`; pubspec does not list the V2 draft pool; C2 catalog still points at V1 banks

## Selectable primary distribution

- `contact_need`: 20
- `closeness_pace`: 39
- `initiative`: 29
- `autonomy`: 57
- `reassurance_need`: 26
- `uncertainty_tolerance`: 27
- `disclosure_pace`: 35
- `boundary_firmness`: 52
- `repair_style`: 27
- `social_energy`: 23
- `structure_preference`: 36
- `adaptability`: 37

## Safety

- Frequency V1 banks not modified
- pubspec.yaml not modified
- Live locale routing not modified
- Discover / Persona / matching / canonical_v1 / C2 / FrequencyTo20dRuntimeAdapter not modified
- No 12D→6D map
- No Firebase deploy
- No commit/push

FREQUENCY V2 PHASE 1G 26 HUMAN REWRITES APPLIED — 12D BEHAVIORAL LAYER READY FOR EVIDENCE METADATA — V2 STILL DORMANT
