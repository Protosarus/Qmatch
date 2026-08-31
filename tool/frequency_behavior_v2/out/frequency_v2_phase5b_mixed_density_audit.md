# Frequency V2 Phase 5B — Confidence-aware mixed density

Status: **offline / dormant**. `runtime_selectable` remains false.
This is a **quantum-inspired mixed-state representation**. Overlap is a Hilbert–Schmidt diagnostic, not compatibility. Lambda is mixedness, not dishonesty or psychological entropy.

mixedness_version: `frequency_behavior_v2_mixed_density_v1`
encoding_version: `frequency_behavior_v2_signed_pole_state_v1`
confidence_version: `frequency_behavior_v2_confidence_v1`
formula: `rho_user = (1-λ) rho_behavior + λ I/24`

## Invariants

| Check | Result |
|---|---|
| analytic purity matches Tr(ρ²) | **true** |
| HIGH_SUPPORT lambda=0 | **true** |
| NO_SUPPORT lambda=1 | **true** |
| HIGH mixed purity ≈ 1 | **true** |
| NO_SUPPORT mixed purity = 1/24 | **true** |
| same psi / rho_behavior across HIGH vs LOW support | **true** |
| lambda_high < lambda_low | **true** |
| mixed purity high > low | **true** |
| opposite profiles distinct at lambda<1 | **true** |
| opposite profiles identical at lambda=1 | **true** |
| missing confidence refuses rho_user | **true** |
| pair compatibility defined | **false** |
| dimension-specific lambda defined | **false** |

## HIGH_SUPPORT

| field | value |
|---|---|
| global_support | 1.00000000 |
| lambda | 0 |
| pure purity | 1.00000000 |
| mixed purity | 1.00000000 |
| analytic mixed purity | 1.00000000 |
| trace | 1.00000000 |
| minimum eigenvalue | 0 |
| maximum eigenvalue | 1.00000000 |

## MEDIUM_SUPPORT

| field | value |
|---|---|
| global_support | 0.48000000 |
| lambda | 0.52000000 |
| pure purity | 1.00000000 |
| mixed purity | 0.26246667 |
| analytic mixed purity | 0.26246667 |
| trace | 1.00000000 |
| minimum eigenvalue | 0.02166667 |
| maximum eigenvalue | 0.50166667 |

## LOW_SUPPORT

| field | value |
|---|---|
| global_support | 0.10000000 |
| lambda | 0.90000000 |
| pure purity | 1.00000000 |
| mixed purity | 0.05125000 |
| analytic mixed purity | 0.05125000 |
| trace | 1.00000000 |
| minimum eigenvalue | 0.03750000 |
| maximum eigenvalue | 0.13750000 |

## NO_SUPPORT

| field | value |
|---|---|
| global_support | 0 |
| lambda | 1.00000000 |
| pure purity | 1.00000000 |
| mixed purity | 0.04166667 |
| analytic mixed purity | 0.04166667 |
| trace | 1.00000000 |
| minimum eigenvalue | 0.04166667 |
| maximum eigenvalue | 0.04166667 |

## SAME_BEHAVIOR_HIGH_VS_LOW_SUPPORT

Identical mixed 12D `normalized_behavior`. Support differs. `psi` and `rho_behavior` stay the same; only mixedness changes.

| | HIGH | LOW |
|---|---|---|
| global_support | 0.95000000 | 0.10000000 |
| lambda | 0.05000000 | 0.90000000 |
| mixed purity | 0.90656250 | 0.05125000 |
| psi identical | **true** | |
| rho_behavior identical | **true** | |

## OPPOSITE_BEHAVIOR_EQUAL_SUPPORT

All dimensions `+1` versus all `-1`, same confidence/completeness (`lambda < 1`). Hilbert–Schmidt overlap is **not** compatibility.

| | A (+1) | B (−1) |
|---|---|---|
| lambda | 0.30000000 | 0.30000000 |
| mixed purity | 0.51125000 | 0.51125000 |
| pure-state overlap Tr(ρ_behavior_A ρ_behavior_B) | 0 | |
| mixed-state Hilbert–Schmidt overlap Tr(ρ_user_A ρ_user_B) | 0.02125000 | |
| lambda=1 overlap (both I/24) | 0.04166667 | |

## OPPOSITE_A_EQUAL_SUPPORT

| field | value |
|---|---|
| global_support | 0.70000000 |
| lambda | 0.30000000 |
| pure purity | 1.00000000 |
| mixed purity | 0.51125000 |
| analytic mixed purity | 0.51125000 |
| trace | 1.00000000 |
| minimum eigenvalue | 0.01250000 |
| maximum eigenvalue | 0.71250000 |

## OPPOSITE_B_EQUAL_SUPPORT

| field | value |
|---|---|
| global_support | 0.70000000 |
| lambda | 0.30000000 |
| pure purity | 1.00000000 |
| mixed purity | 0.51125000 |
| analytic mixed purity | 0.51125000 |
| trace | 1.00000000 |
| minimum eigenvalue | 0.01250000 |
| maximum eigenvalue | 0.71250000 |

## Missing data

ok: **false**
message: `incomplete_confidence:repair_style`
rho_user constructed: **false**

## What this phase does not do

- pair compatibility or matching
- dimension-specific lambda
- alter psi or the 12D behavioral vector
- alter Phase 4B confidence, evidence, or selector
- entanglement / collapse / quantum personality claims
- activate V2
- touch V1 / Firebase / C2 / Discover / Persona / matching

FREQUENCY V2 PHASE 5B CONFIDENCE-AWARE MIXED DENSITY MATRIX READY — V2 STILL DORMANT
