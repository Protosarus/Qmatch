# Frequency V2 Phase 1F — Apply final primary decisions

Status: **draft_not_runtime**. V2 remains dormant. Evidence-layer values were not assigned.
Question text and option weights were not rewritten in the live draft.

Authority: `docs/qmatch_frequency_v2_phase1e_final_human_primary_decisions.txt`

## Counts

- **Approved primary decisions applied:** 54
- **Rewrite-pending count:** 26
- **Drop-from-selectable count:** 18
- **Archive question IDs preserved:** 426
- **Archive option IDs preserved:** 1704
- **Selectable pool count after exclusions/pending:** 382
- **Count with exactly one primary (archive-wide):** 390
- **Count with primary pending (rewrite_pending / not one primary):** 26
- **Count with empty primary_dimensions:** 32
- **Count with multiple stored primary IDs (archive):** 4
- **Count with multiple stored primary IDs (selectable):** 0 (target 0)
- **KEEP dual collapsed to one named primary:** 110
- **evidence_meta:** still all `null` / `review_status=pending` (unassigned)
- **V1 SHA-256:** not modified in this phase (confirmed by tests)
- **Live runtime:** unchanged (`runtime_selectable=false`; locale still loads `frequency_bank_*_v1`)

## Human overrides applied

- `frequency_v2_q0030`: primary=`uncertainty_tolerance`; secondary=`disclosure_pace`
- `frequency_v2_q0033`: primary=`disclosure_pace`; secondary=`closeness_pace`
- `frequency_v2_q0228` remains selector-eligible; `q0333` and `q0426` dropped as redundant
- `frequency_v2_q0373` dropped

## Selectable primary distribution

- `contact_need`: 19
- `closeness_pace`: 38
- `initiative`: 27
- `autonomy`: 53
- `reassurance_need`: 24
- `uncertainty_tolerance`: 26
- `disclosure_pace`: 33
- `boundary_firmness`: 45
- `repair_style`: 27
- `social_energy`: 23
- `structure_preference`: 33
- `adaptability`: 34

## Architecture

Selectable questions: exactly one `primary_dimension`, zero or more `secondary_dimensions`.
DROP items remain in the archive with provenance; `selector_eligible=false`.
REWRITE items keep original stem/options/weights; primary cleared; `selector_eligible=false` until human-approved rewrite.

## Safety

- Frequency V1 banks not modified
- pubspec.yaml not modified
- Live locale routing not modified
- Discover / Persona / matching / canonical_v1 / C2 / FrequencyTo20dRuntimeAdapter not modified
- No 12D→6D map
- No Firebase deploy
- No commit/push

FREQUENCY V2 PHASE 1F FINAL PRIMARY DECISIONS APPLIED — 26 REWRITES AWAIT HUMAN APPROVAL — V2 STILL DORMANT
