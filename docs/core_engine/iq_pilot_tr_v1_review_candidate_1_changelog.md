# IQ Pilot TR v1 → Review Candidate 1 Changelog

**Parent:** `iq-tr-pilot-v1`  
**Candidate:** `iq-tr-pilot-v1-review-candidate-1`  
**Policy:** minor clarity may keep ID; material rule/construct/answer/solution changes or replacements get new IDs.

## `iq_tr_v1_logical_005` (clarity_edit)

- Revised ID: `iq_tr_v1_logical_005` (retained)
- Old correct: `A` / New correct after rebalance: `A`
- Old difficulty: 3 / New: 3
- Notes: clarity_edit from v1; two-state lamp made explicit
- Remains anchor: False

## `iq_tr_v1_logical_007` (clarity_edit)

- Revised ID: `iq_tr_v1_logical_007` (retained)
- Old correct: `B` / New correct after rebalance: `C`
- Old difficulty: 4 / New: 4
- Notes: clarity_edit from v1; yalnızca disambiguated as only-if / necessary condition
- Remains anchor: False

## REPLACE `iq_tr_v1_pattern_006` → `iq_tr_v1_pattern_007` (semantic_rewrite)

- Change type: `semantic_rewrite` (material rule presentation → new ID)
- Revised ID: `iq_tr_v1_pattern_007` (new; does not reuse retired `pattern_006`)
- Old prompt: bare sequence 1, 2, 6, 24, 120 with factorial discovery
- New prompt: explicit increasing multipliers with worked steps; ask 120×6
- Old correct: `B` / New correct after rebalance: `A`
- Old difficulty: 4 / New: 3
- Reason: remove school-factorial prerequisite while keeping numerical target
- Remains anchor: False
- Remaining concern: still arithmetic fluency contamination (low–moderate)

## `iq_tr_v1_verbal_002` (clarity_edit)

- Revised ID: `iq_tr_v1_verbal_002` (retained)
- Old correct: `D` / New correct after rebalance: `D`
- Old difficulty: 2 / New: 2
- Notes: clarity_edit from v1; explicit non-empty participant set
- Remains anchor: False

## `iq_tr_v1_verbal_004` (difficulty_revision)

- Revised ID: `iq_tr_v1_verbal_004` (retained)
- Old correct: `A` / New correct after rebalance: `B`
- Old difficulty: 3 / New: 2
- Notes: difficulty_revision from v1; category odd-one-out is easy, not medium
- Remains anchor: False

## `iq_tr_v1_spatial_005` (clarity_edit)

- Revised ID: `iq_tr_v1_spatial_005` (retained)
- Old correct: `A` / New correct after rebalance: `A`
- Old difficulty: 3 / New: 3
- Notes: clarity_edit from v1; viewpoint axes defined
- Remains anchor: False

## REPLACE `iq_tr_v1_spatial_003` → `iq_tr_v1_spatial_007`

- Change type: `item_replacement`
- Old prompt: cube tip-forward rotation
- New prompt: map 4 east then 3 south
- Old correct: `B` / New correct: `B` (rebalanced)
- Reason: text-only cube orientation underdetermined without figure
- Anchor: transferred to `iq_tr_v1_spatial_007`
- Remaining concern: expert spatial wording review

## Unchanged items (PASS)

- `iq_tr_v1_logical_001` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_logical_002` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_logical_003` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_logical_004` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_logical_006` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_pattern_001` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_pattern_002` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_pattern_003` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_pattern_004` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_pattern_005` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_verbal_001` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_verbal_003` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_verbal_005` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_verbal_006` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_spatial_001` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_spatial_002` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_spatial_004` — unchanged content (answer letter may be rebalanced)
- `iq_tr_v1_spatial_006` — unchanged content (answer letter may be rebalanced)

## ID policy decisions

- Retained IDs for clarity/difficulty edits that keep the same reasoning rule: logical_005/007, verbal_002/004, spatial_005
- New ID `iq_tr_v1_pattern_007` for material semantic rewrite of pattern_006 (rule presentation/construct change)
- New ID `iq_tr_v1_spatial_007` for material replacement of spatial_003
- Correct-answer positions rebalanced after semantic lock; not encoded in IDs
