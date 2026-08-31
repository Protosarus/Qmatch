# Frequency V2 Phase 5D — Provisional relationship fit

Status: **offline / dormant**. `runtime_selectable` remains false.
Provisional **Frequency Fit** index. Not relationship success probability, soulmate scoring, or scientifically validated prediction.

pair_fit_policy_version: `frequency_pair_fit_policy_v1`
pair_fit_version: `frequency_behavior_v2_pair_fit_v1`

## Demonstrations

- **support shrinks toward 50:** IDENTICAL_HIGH index 100.000000 vs IDENTICAL_LOW 53.000000 (raw fit both 1.000000).
- **tolerant vs linear at delta=0.5:** contact_need linear raw 0.750000 vs initiative tolerant 0.937500.
- **no opposition reward:** OPPOSITE_HIGH raw fit 0 (index 0).
- **density overlap not in score:** fit uses behavior + pair_support only; pure/mixed overlaps are diagnostic elsewhere.

## Invariants

| Check | Result |
|---|---|
| IDENTICAL_HIGH index ≈ 100 | **true** |
| IDENTICAL zero-support index = 50 | **true** |
| IDENTICAL low-support index < 100 | **true** |
| OPPOSITE_HIGH raw fit = 0 | **true** |
| MODERATE tolerant raw > linear raw | **true** |
| SAME_BEHAVIOR raw fit unchanged under support | **true** |
| SAME_BEHAVIOR supported fit lower with low support | **true** |
| complementarity bonus | **false** |
| live matching wired | **false** |

## IDENTICAL_HIGH_SUPPORT

| global | value |
|---|---|
| overall_raw_fit | 1.000000 |
| overall_supported_fit | 1.000000 |
| frequency_fit_index | 100.000000 |
| overall_pair_support | 1.000000 |
| top_alignment | adaptability, autonomy, boundary_firmness |
| top_gap | adaptability, autonomy, boundary_firmness |

| dimension | policy | x_A | x_B | delta | raw_fit | pair_support | supported_fit |
|---|---|---|---|---|---|---|---|
| contact_need | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| closeness_pace | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| initiative | SIMILARITY_TOLERANT | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| autonomy | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| reassurance_need | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| uncertainty_tolerance | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| disclosure_pace | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| boundary_firmness | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| repair_style | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| social_energy | SIMILARITY_TOLERANT | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| structure_preference | SIMILARITY_TOLERANT | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |
| adaptability | SIMILARITY_TOLERANT | 0.700000 | 0.700000 | 0 | 1.000000 | 1.000000 | 1.000000 |

## IDENTICAL_LOW_SUPPORT

| global | value |
|---|---|
| overall_raw_fit | 1.000000 |
| overall_supported_fit | 0.530000 |
| frequency_fit_index | 53.000000 |
| overall_pair_support | 0.060000 |
| top_alignment | adaptability, autonomy, boundary_firmness |
| top_gap | adaptability, autonomy, boundary_firmness |

| dimension | policy | x_A | x_B | delta | raw_fit | pair_support | supported_fit |
|---|---|---|---|---|---|---|---|
| contact_need | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| closeness_pace | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| initiative | SIMILARITY_TOLERANT | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| autonomy | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| reassurance_need | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| uncertainty_tolerance | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| disclosure_pace | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| boundary_firmness | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| repair_style | SIMILARITY_LINEAR | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| social_energy | SIMILARITY_TOLERANT | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| structure_preference | SIMILARITY_TOLERANT | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |
| adaptability | SIMILARITY_TOLERANT | 0.700000 | 0.700000 | 0 | 1.000000 | 0.060000 | 0.530000 |

## OPPOSITE_HIGH_SUPPORT

| global | value |
|---|---|
| overall_raw_fit | 0 |
| overall_supported_fit | 0 |
| frequency_fit_index | 0 |
| overall_pair_support | 1.000000 |
| top_alignment | adaptability, autonomy, boundary_firmness |
| top_gap | adaptability, autonomy, boundary_firmness |

| dimension | policy | x_A | x_B | delta | raw_fit | pair_support | supported_fit |
|---|---|---|---|---|---|---|---|
| contact_need | SIMILARITY_LINEAR | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| closeness_pace | SIMILARITY_LINEAR | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| initiative | SIMILARITY_TOLERANT | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| autonomy | SIMILARITY_LINEAR | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| reassurance_need | SIMILARITY_LINEAR | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| uncertainty_tolerance | SIMILARITY_LINEAR | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| disclosure_pace | SIMILARITY_LINEAR | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| boundary_firmness | SIMILARITY_LINEAR | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| repair_style | SIMILARITY_LINEAR | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| social_energy | SIMILARITY_TOLERANT | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| structure_preference | SIMILARITY_TOLERANT | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |
| adaptability | SIMILARITY_TOLERANT | 1.000000 | -1.000000 | 2.000000 | 0 | 1.000000 | 0 |

## MODERATE_DIFFERENCE

| global | value |
|---|---|
| overall_raw_fit | 0.812500 |
| overall_supported_fit | 0.812500 |
| frequency_fit_index | 81.250000 |
| overall_pair_support | 1.000000 |
| top_alignment | adaptability, initiative, social_energy |
| top_gap | autonomy, boundary_firmness, closeness_pace |

| dimension | policy | x_A | x_B | delta | raw_fit | pair_support | supported_fit |
|---|---|---|---|---|---|---|---|
| contact_need | SIMILARITY_LINEAR | 0.250000 | -0.250000 | 0.500000 | 0.750000 | 1.000000 | 0.750000 |
| closeness_pace | SIMILARITY_LINEAR | 0.250000 | -0.250000 | 0.500000 | 0.750000 | 1.000000 | 0.750000 |
| initiative | SIMILARITY_TOLERANT | 0.250000 | -0.250000 | 0.500000 | 0.937500 | 1.000000 | 0.937500 |
| autonomy | SIMILARITY_LINEAR | 0.250000 | -0.250000 | 0.500000 | 0.750000 | 1.000000 | 0.750000 |
| reassurance_need | SIMILARITY_LINEAR | 0.250000 | -0.250000 | 0.500000 | 0.750000 | 1.000000 | 0.750000 |
| uncertainty_tolerance | SIMILARITY_LINEAR | 0.250000 | -0.250000 | 0.500000 | 0.750000 | 1.000000 | 0.750000 |
| disclosure_pace | SIMILARITY_LINEAR | 0.250000 | -0.250000 | 0.500000 | 0.750000 | 1.000000 | 0.750000 |
| boundary_firmness | SIMILARITY_LINEAR | 0.250000 | -0.250000 | 0.500000 | 0.750000 | 1.000000 | 0.750000 |
| repair_style | SIMILARITY_LINEAR | 0.250000 | -0.250000 | 0.500000 | 0.750000 | 1.000000 | 0.750000 |
| social_energy | SIMILARITY_TOLERANT | 0.250000 | -0.250000 | 0.500000 | 0.937500 | 1.000000 | 0.937500 |
| structure_preference | SIMILARITY_TOLERANT | 0.250000 | -0.250000 | 0.500000 | 0.937500 | 1.000000 | 0.937500 |
| adaptability | SIMILARITY_TOLERANT | 0.250000 | -0.250000 | 0.500000 | 0.937500 | 1.000000 | 0.937500 |

## MIXED_REALISTIC_PAIR

| global | value |
|---|---|
| overall_raw_fit | 1.000000 |
| overall_supported_fit | 0.925000 |
| frequency_fit_index | 92.500000 |
| overall_pair_support | 0.850000 |
| top_alignment | adaptability, autonomy, boundary_firmness |
| top_gap | adaptability, autonomy, boundary_firmness |

| dimension | policy | x_A | x_B | delta | raw_fit | pair_support | supported_fit |
|---|---|---|---|---|---|---|---|
| contact_need | SIMILARITY_LINEAR | 1.000000 | 1.000000 | 0 | 1.000000 | 0.850000 | 0.925000 |
| closeness_pace | SIMILARITY_LINEAR | -1.000000 | -1.000000 | 0 | 1.000000 | 0.850000 | 0.925000 |
| initiative | SIMILARITY_TOLERANT | 0.500000 | 0.500000 | 0 | 1.000000 | 0.850000 | 0.925000 |
| autonomy | SIMILARITY_LINEAR | -0.500000 | -0.500000 | 0 | 1.000000 | 0.850000 | 0.925000 |
| reassurance_need | SIMILARITY_LINEAR | 0 | 0 | 0 | 1.000000 | 0.850000 | 0.925000 |
| uncertainty_tolerance | SIMILARITY_LINEAR | 0.250000 | 0.250000 | 0 | 1.000000 | 0.850000 | 0.925000 |
| disclosure_pace | SIMILARITY_LINEAR | -0.250000 | -0.250000 | 0 | 1.000000 | 0.850000 | 0.925000 |
| boundary_firmness | SIMILARITY_LINEAR | 0.750000 | 0.750000 | 0 | 1.000000 | 0.850000 | 0.925000 |
| repair_style | SIMILARITY_LINEAR | -0.750000 | -0.750000 | 0 | 1.000000 | 0.850000 | 0.925000 |
| social_energy | SIMILARITY_TOLERANT | 1.000000 | 1.000000 | 0 | 1.000000 | 0.850000 | 0.925000 |
| structure_preference | SIMILARITY_TOLERANT | 0 | 0 | 0 | 1.000000 | 0.850000 | 0.925000 |
| adaptability | SIMILARITY_TOLERANT | -1.000000 | -1.000000 | 0 | 1.000000 | 0.850000 | 0.925000 |

## SAME_BEHAVIOR_DIFFERENT_SUPPORT

| global | value |
|---|---|
| overall_raw_fit | 1.000000 |
| overall_supported_fit | 0.658114 |
| frequency_fit_index | 65.811388 |
| overall_pair_support | 0.316228 |
| top_alignment | adaptability, autonomy, boundary_firmness |
| top_gap | adaptability, autonomy, boundary_firmness |

| dimension | policy | x_A | x_B | delta | raw_fit | pair_support | supported_fit |
|---|---|---|---|---|---|---|---|
| contact_need | SIMILARITY_LINEAR | 1.000000 | 1.000000 | 0 | 1.000000 | 0.316228 | 0.658114 |
| closeness_pace | SIMILARITY_LINEAR | -1.000000 | -1.000000 | 0 | 1.000000 | 0.316228 | 0.658114 |
| initiative | SIMILARITY_TOLERANT | 0.500000 | 0.500000 | 0 | 1.000000 | 0.316228 | 0.658114 |
| autonomy | SIMILARITY_LINEAR | -0.500000 | -0.500000 | 0 | 1.000000 | 0.316228 | 0.658114 |
| reassurance_need | SIMILARITY_LINEAR | 0 | 0 | 0 | 1.000000 | 0.316228 | 0.658114 |
| uncertainty_tolerance | SIMILARITY_LINEAR | 0.250000 | 0.250000 | 0 | 1.000000 | 0.316228 | 0.658114 |
| disclosure_pace | SIMILARITY_LINEAR | -0.250000 | -0.250000 | 0 | 1.000000 | 0.316228 | 0.658114 |
| boundary_firmness | SIMILARITY_LINEAR | 0.750000 | 0.750000 | 0 | 1.000000 | 0.316228 | 0.658114 |
| repair_style | SIMILARITY_LINEAR | -0.750000 | -0.750000 | 0 | 1.000000 | 0.316228 | 0.658114 |
| social_energy | SIMILARITY_TOLERANT | 1.000000 | 1.000000 | 0 | 1.000000 | 0.316228 | 0.658114 |
| structure_preference | SIMILARITY_TOLERANT | 0 | 0 | 0 | 1.000000 | 0.316228 | 0.658114 |
| adaptability | SIMILARITY_TOLERANT | -1.000000 | -1.000000 | 0 | 1.000000 | 0.316228 | 0.658114 |

## Policy note

All policy assignments and curves are **PROVISIONAL** and **UNCALIBRATED**. Future telemetry may create `frequency_pair_fit_policy_v2`.

## What this phase does not do

- wire into live matching
- complementarity bonus or asymmetric need/supply
- learned weights without data
- use density overlap as final score
- activate V2
- touch V1 / Firebase / C2 / Discover / Persona

FREQUENCY V2 PHASE 5D PROVISIONAL RELATIONSHIP FIT MODEL READY — NO LIVE MATCHING — V2 STILL DORMANT
