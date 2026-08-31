# Frequency V2 Phase 5C — Pair-relation primitives

Status: **offline / dormant**. `runtime_selectable` remains false.
These are quantum-inspired **relation primitives**. They are **not** a compatibility score. Same pole is not compatible; opposite pole is not incompatible.

pair_model_version: `frequency_behavior_v2_pair_relation_v1`

## Demonstrations

- **neutral/neutral:** fidelity=1 but same_pole=0.5 (got fidelity=1.000000, same_pole=0.500000).
- **opposite extremes:** fidelity=0 and same_pole=0 (got fidelity=0, same_pole=0).
- **low support:** behavior relation stays unchanged, supported relation moves toward neutral (OPPOSITE_EXTREME same_pole=0, LOW_SUPPORT_OPPOSITES same_pole=0, supported_same=0.490000, pair_support=0.020000).

## Invariants

| Check | Result |
|---|---|
| operator same-pole = (1+xA xB)/2 | **true** |
| IDENTICAL same_pole=1 fidelity=1 | **true** |
| OPPOSITE same_pole=0 fidelity=0 | **true** |
| NEUTRAL fidelity=1 same_pole=0.5 | **true** |
| SAME_BEHAVIOR axis_fidelity unchanged under support change | **true** |
| SAME_BEHAVIOR same_pole unchanged under support change | **true** |
| SAME_BEHAVIOR supported_same shrinks with lower pair_support | **true** |
| LOW_SUPPORT_OPPOSITES supported_same nearer 0.5 | **true** |
| compatibility score emitted | **false** |
| entanglement constructed | **false** |

## IDENTICAL_EXTREME

| global | value |
|---|---|
| pure_behavior_overlap | 1.000000 |
| mixed_hilbert_schmidt_overlap | 1.000000 |

| dimension | x_A | x_B | axis_fidelity | same_pole | opposite_pole | pair_support | supported_same_pole |
|---|---|---|---|---|---|---|---|
| contact_need | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| closeness_pace | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| initiative | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| autonomy | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| reassurance_need | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| uncertainty_tolerance | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| disclosure_pace | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| boundary_firmness | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| repair_style | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| social_energy | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| structure_preference | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |
| adaptability | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 1.000000 | 1.000000 |

## OPPOSITE_EXTREME

| global | value |
|---|---|
| pure_behavior_overlap | 0 |
| mixed_hilbert_schmidt_overlap | 0 |

| dimension | x_A | x_B | axis_fidelity | same_pole | opposite_pole | pair_support | supported_same_pole |
|---|---|---|---|---|---|---|---|
| contact_need | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| closeness_pace | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| initiative | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| autonomy | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| reassurance_need | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| uncertainty_tolerance | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| disclosure_pace | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| boundary_firmness | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| repair_style | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| social_energy | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| structure_preference | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |
| adaptability | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 1.000000 | 0 |

## IDENTICAL_NEUTRAL

| global | value |
|---|---|
| pure_behavior_overlap | 1.000000 |
| mixed_hilbert_schmidt_overlap | 1.000000 |

| dimension | x_A | x_B | axis_fidelity | same_pole | opposite_pole | pair_support | supported_same_pole |
|---|---|---|---|---|---|---|---|
| contact_need | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| closeness_pace | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| initiative | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| autonomy | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| reassurance_need | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| uncertainty_tolerance | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| disclosure_pace | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| boundary_firmness | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| repair_style | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| social_energy | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| structure_preference | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |
| adaptability | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 1.000000 | 0.500000 |

## MODERATE_ALIGNED

| global | value |
|---|---|
| pure_behavior_overlap | 1.000000 |
| mixed_hilbert_schmidt_overlap | 1.000000 |

| dimension | x_A | x_B | axis_fidelity | same_pole | opposite_pole | pair_support | supported_same_pole |
|---|---|---|---|---|---|---|---|
| contact_need | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| closeness_pace | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| initiative | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| autonomy | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| reassurance_need | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| uncertainty_tolerance | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| disclosure_pace | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| boundary_firmness | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| repair_style | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| social_energy | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| structure_preference | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |
| adaptability | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 1.000000 | 0.625000 |

## MODERATE_OPPOSED

| global | value |
|---|---|
| pure_behavior_overlap | 0.750000 |
| mixed_hilbert_schmidt_overlap | 0.750000 |

| dimension | x_A | x_B | axis_fidelity | same_pole | opposite_pole | pair_support | supported_same_pole |
|---|---|---|---|---|---|---|---|
| contact_need | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| closeness_pace | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| initiative | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| autonomy | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| reassurance_need | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| uncertainty_tolerance | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| disclosure_pace | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| boundary_firmness | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| repair_style | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| social_energy | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| structure_preference | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |
| adaptability | 0.500000 | -0.500000 | 0.750000 | 0.375000 | 0.625000 | 1.000000 | 0.375000 |

## SAME_BEHAVIOR_DIFFERENT_SUPPORT

| global | value |
|---|---|
| pure_behavior_overlap | 1.000000 |
| mixed_hilbert_schmidt_overlap | 0.137500 |

| dimension | x_A | x_B | axis_fidelity | same_pole | opposite_pole | pair_support | supported_same_pole |
|---|---|---|---|---|---|---|---|
| contact_need | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 0.316228 | 0.658114 |
| closeness_pace | -1.000000 | -1.000000 | 1.000000 | 1.000000 | 0 | 0.316228 | 0.658114 |
| initiative | 0.500000 | 0.500000 | 1.000000 | 0.625000 | 0.375000 | 0.316228 | 0.539528 |
| autonomy | -0.500000 | -0.500000 | 1.000000 | 0.625000 | 0.375000 | 0.316228 | 0.539528 |
| reassurance_need | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 0.316228 | 0.500000 |
| uncertainty_tolerance | 0.250000 | 0.250000 | 1.000000 | 0.531250 | 0.468750 | 0.316228 | 0.509882 |
| disclosure_pace | -0.250000 | -0.250000 | 1.000000 | 0.531250 | 0.468750 | 0.316228 | 0.509882 |
| boundary_firmness | 0.750000 | 0.750000 | 1.000000 | 0.781250 | 0.218750 | 0.316228 | 0.588939 |
| repair_style | -0.750000 | -0.750000 | 1.000000 | 0.781250 | 0.218750 | 0.316228 | 0.588939 |
| social_energy | 1.000000 | 1.000000 | 1.000000 | 1.000000 | 0 | 0.316228 | 0.658114 |
| structure_preference | 0 | 0 | 1.000000 | 0.500000 | 0.500000 | 0.316228 | 0.500000 |
| adaptability | -1.000000 | -1.000000 | 1.000000 | 1.000000 | 0 | 0.316228 | 0.658114 |

## LOW_SUPPORT_OPPOSITES

| global | value |
|---|---|
| pure_behavior_overlap | 0 |
| mixed_hilbert_schmidt_overlap | 0.041650 |

| dimension | x_A | x_B | axis_fidelity | same_pole | opposite_pole | pair_support | supported_same_pole |
|---|---|---|---|---|---|---|---|
| contact_need | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| closeness_pace | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| initiative | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| autonomy | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| reassurance_need | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| uncertainty_tolerance | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| disclosure_pace | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| boundary_firmness | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| repair_style | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| social_energy | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| structure_preference | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |
| adaptability | 1.000000 | -1.000000 | 0 | 0 | 1.000000 | 0.020000 | 0.490000 |

## What this phase does not do

- final compatibility score
- similarity vs complementarity policy
- dimension weights / matching
- entanglement or 576×576 pair matrices
- modify user rho, scorer, confidence, evidence, selector
- activate V2
- touch V1 / Firebase / C2 / Discover / Persona

FREQUENCY V2 PHASE 5C QUANTUM-INSPIRED PAIR RELATION PRIMITIVES READY — NO COMPATIBILITY SCORE YET — V2 STILL DORMANT
