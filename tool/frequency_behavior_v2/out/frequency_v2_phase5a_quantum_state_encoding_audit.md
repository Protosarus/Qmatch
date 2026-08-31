# Frequency V2 Phase 5A — Signed-pole quantum-inspired state encoding

Status: **offline / dormant**. `runtime_selectable` remains false.
This is a **quantum-inspired mathematical representation**. It is not quantum psychology, not a claim that a person is a quantum system, and not pair compatibility.

encoding_version: `frequency_behavior_v2_signed_pole_state_v1`
scorer_version: `frequency_behavior_v2_scorer_v1`
bank_version: `frequency_behavior_pool_tr_v2_draft1`
basis size: 24

## Invariants

| Check | Result |
|---|---|
| all example states pure (trace/purity/PSD/rho²≈rho) | **true** |
| same 12D vector → identical psi | **true** |
| psi_ALL_POSITIVE ≠ psi_ALL_NEGATIVE | **true** |
| rho_ALL_POSITIVE ≠ rho_ALL_NEGATIVE | **true** |
| opposite-profile state-vector dot product | **0** |
| opposite-profile density-matrix overlap Tr(ρ_A ρ_B) | **0** |
| opposite-profile similarity is not 1 | **true** |
| SINGLE_AXIS +1 vs -1 distinct poles | **true** |
| SINGLE_AXIS density overlap ≠ 1 | **true** |
| forbidden 12D-as-psi encoding would make +1/−1 collide | **true** |
| mixedness lambda defined | **false** |
| pair compatibility defined | **false** |

## Forbidden encoding (why signed poles exist)

If the signed 12D vector were used as a normalized amplitude vector, then `psi_all_minus = - psi_all_plus` and `ρ = |psi⟩⟨psi|` would be **identical** for globally opposite profiles (overlap = 1). Signed plus/minus poles keep those profiles distinguishable (overlap ≈ 0).

## ALL_POSITIVE

12D input:

| dimension | x |
|---|---|
| contact_need | 1.000000 |
| closeness_pace | 1.000000 |
| initiative | 1.000000 |
| autonomy | 1.000000 |
| reassurance_need | 1.000000 |
| uncertainty_tolerance | 1.000000 |
| disclosure_pace | 1.000000 |
| boundary_firmness | 1.000000 |
| repair_style | 1.000000 |
| social_energy | 1.000000 |
| structure_preference | 1.000000 |
| adaptability | 1.000000 |

24D amplitudes (signed poles, before `/sqrt(12)`):

| basis | amplitude | psi |
|---|---|---|
| contact_need:+ | 1.000000 | 0.288675 |
| contact_need:- | 0 | 0 |
| closeness_pace:+ | 1.000000 | 0.288675 |
| closeness_pace:- | 0 | 0 |
| initiative:+ | 1.000000 | 0.288675 |
| initiative:- | 0 | 0 |
| autonomy:+ | 1.000000 | 0.288675 |
| autonomy:- | 0 | 0 |
| reassurance_need:+ | 1.000000 | 0.288675 |
| reassurance_need:- | 0 | 0 |
| uncertainty_tolerance:+ | 1.000000 | 0.288675 |
| uncertainty_tolerance:- | 0 | 0 |
| disclosure_pace:+ | 1.000000 | 0.288675 |
| disclosure_pace:- | 0 | 0 |
| boundary_firmness:+ | 1.000000 | 0.288675 |
| boundary_firmness:- | 0 | 0 |
| repair_style:+ | 1.000000 | 0.288675 |
| repair_style:- | 0 | 0 |
| social_energy:+ | 1.000000 | 0.288675 |
| social_energy:- | 0 | 0 |
| structure_preference:+ | 1.000000 | 0.288675 |
| structure_preference:- | 0 | 0 |
| adaptability:+ | 1.000000 | 0.288675 |
| adaptability:- | 0 | 0 |

| norm(psi) | 1.000000 |
| Σ pole² | 12.000000 |
| trace | 1.000000 |
| purity | 1.000000 |

## ALL_NEGATIVE

12D input:

| dimension | x |
|---|---|
| contact_need | -1.000000 |
| closeness_pace | -1.000000 |
| initiative | -1.000000 |
| autonomy | -1.000000 |
| reassurance_need | -1.000000 |
| uncertainty_tolerance | -1.000000 |
| disclosure_pace | -1.000000 |
| boundary_firmness | -1.000000 |
| repair_style | -1.000000 |
| social_energy | -1.000000 |
| structure_preference | -1.000000 |
| adaptability | -1.000000 |

24D amplitudes (signed poles, before `/sqrt(12)`):

| basis | amplitude | psi |
|---|---|---|
| contact_need:+ | 0 | 0 |
| contact_need:- | 1.000000 | 0.288675 |
| closeness_pace:+ | 0 | 0 |
| closeness_pace:- | 1.000000 | 0.288675 |
| initiative:+ | 0 | 0 |
| initiative:- | 1.000000 | 0.288675 |
| autonomy:+ | 0 | 0 |
| autonomy:- | 1.000000 | 0.288675 |
| reassurance_need:+ | 0 | 0 |
| reassurance_need:- | 1.000000 | 0.288675 |
| uncertainty_tolerance:+ | 0 | 0 |
| uncertainty_tolerance:- | 1.000000 | 0.288675 |
| disclosure_pace:+ | 0 | 0 |
| disclosure_pace:- | 1.000000 | 0.288675 |
| boundary_firmness:+ | 0 | 0 |
| boundary_firmness:- | 1.000000 | 0.288675 |
| repair_style:+ | 0 | 0 |
| repair_style:- | 1.000000 | 0.288675 |
| social_energy:+ | 0 | 0 |
| social_energy:- | 1.000000 | 0.288675 |
| structure_preference:+ | 0 | 0 |
| structure_preference:- | 1.000000 | 0.288675 |
| adaptability:+ | 0 | 0 |
| adaptability:- | 1.000000 | 0.288675 |

| norm(psi) | 1.000000 |
| Σ pole² | 12.000000 |
| trace | 1.000000 |
| purity | 1.000000 |

## NEUTRAL

12D input:

| dimension | x |
|---|---|
| contact_need | 0 |
| closeness_pace | 0 |
| initiative | 0 |
| autonomy | 0 |
| reassurance_need | 0 |
| uncertainty_tolerance | 0 |
| disclosure_pace | 0 |
| boundary_firmness | 0 |
| repair_style | 0 |
| social_energy | 0 |
| structure_preference | 0 |
| adaptability | 0 |

24D amplitudes (signed poles, before `/sqrt(12)`):

| basis | amplitude | psi |
|---|---|---|
| contact_need:+ | 0.707107 | 0.204124 |
| contact_need:- | 0.707107 | 0.204124 |
| closeness_pace:+ | 0.707107 | 0.204124 |
| closeness_pace:- | 0.707107 | 0.204124 |
| initiative:+ | 0.707107 | 0.204124 |
| initiative:- | 0.707107 | 0.204124 |
| autonomy:+ | 0.707107 | 0.204124 |
| autonomy:- | 0.707107 | 0.204124 |
| reassurance_need:+ | 0.707107 | 0.204124 |
| reassurance_need:- | 0.707107 | 0.204124 |
| uncertainty_tolerance:+ | 0.707107 | 0.204124 |
| uncertainty_tolerance:- | 0.707107 | 0.204124 |
| disclosure_pace:+ | 0.707107 | 0.204124 |
| disclosure_pace:- | 0.707107 | 0.204124 |
| boundary_firmness:+ | 0.707107 | 0.204124 |
| boundary_firmness:- | 0.707107 | 0.204124 |
| repair_style:+ | 0.707107 | 0.204124 |
| repair_style:- | 0.707107 | 0.204124 |
| social_energy:+ | 0.707107 | 0.204124 |
| social_energy:- | 0.707107 | 0.204124 |
| structure_preference:+ | 0.707107 | 0.204124 |
| structure_preference:- | 0.707107 | 0.204124 |
| adaptability:+ | 0.707107 | 0.204124 |
| adaptability:- | 0.707107 | 0.204124 |

| norm(psi) | 1.000000 |
| Σ pole² | 12.000000 |
| trace | 1.000000 |
| purity | 1.000000 |

## MIXED_PROFILE

12D input:

| dimension | x |
|---|---|
| contact_need | 1.000000 |
| closeness_pace | -1.000000 |
| initiative | 0.500000 |
| autonomy | -0.500000 |
| reassurance_need | 0 |
| uncertainty_tolerance | 0.250000 |
| disclosure_pace | -0.250000 |
| boundary_firmness | 0.750000 |
| repair_style | -0.750000 |
| social_energy | 1.000000 |
| structure_preference | 0 |
| adaptability | -1.000000 |

24D amplitudes (signed poles, before `/sqrt(12)`):

| basis | amplitude | psi |
|---|---|---|
| contact_need:+ | 1.000000 | 0.288675 |
| contact_need:- | 0 | 0 |
| closeness_pace:+ | 0 | 0 |
| closeness_pace:- | 1.000000 | 0.288675 |
| initiative:+ | 0.866025 | 0.250000 |
| initiative:- | 0.500000 | 0.144338 |
| autonomy:+ | 0.500000 | 0.144338 |
| autonomy:- | 0.866025 | 0.250000 |
| reassurance_need:+ | 0.707107 | 0.204124 |
| reassurance_need:- | 0.707107 | 0.204124 |
| uncertainty_tolerance:+ | 0.790569 | 0.228218 |
| uncertainty_tolerance:- | 0.612372 | 0.176777 |
| disclosure_pace:+ | 0.612372 | 0.176777 |
| disclosure_pace:- | 0.790569 | 0.228218 |
| boundary_firmness:+ | 0.935414 | 0.270031 |
| boundary_firmness:- | 0.353553 | 0.102062 |
| repair_style:+ | 0.353553 | 0.102062 |
| repair_style:- | 0.935414 | 0.270031 |
| social_energy:+ | 1.000000 | 0.288675 |
| social_energy:- | 0 | 0 |
| structure_preference:+ | 0.707107 | 0.204124 |
| structure_preference:- | 0.707107 | 0.204124 |
| adaptability:+ | 0 | 0 |
| adaptability:- | 1.000000 | 0.288675 |

| norm(psi) | 1.000000 |
| Σ pole² | 12.000000 |
| trace | 1.000000 |
| purity | 1.000000 |

## SINGLE_AXIS_OPPOSITES

`contact_need = +1` versus `contact_need = -1`, all other dimensions 0 (behavioral center, not missing / not low confidence).

| | +1 pole | -1 pole |
|---|---|---|
| contact_need:+ amplitude | 1.000000 | 0 |
| contact_need:- amplitude | 0 | 1.000000 |
| state-vector dot product | 0.916667 | |
| density-matrix overlap | 0.840278 | |
| psi norm (+) | 1.000000 | |
| trace (+) | 1.000000 | |
| purity (+) | 1.000000 | |

## SINGLE_AXIS_+1

12D input:

| dimension | x |
|---|---|
| contact_need | 1.000000 |
| closeness_pace | 0 |
| initiative | 0 |
| autonomy | 0 |
| reassurance_need | 0 |
| uncertainty_tolerance | 0 |
| disclosure_pace | 0 |
| boundary_firmness | 0 |
| repair_style | 0 |
| social_energy | 0 |
| structure_preference | 0 |
| adaptability | 0 |

24D amplitudes (signed poles, before `/sqrt(12)`):

| basis | amplitude | psi |
|---|---|---|
| contact_need:+ | 1.000000 | 0.288675 |
| contact_need:- | 0 | 0 |
| closeness_pace:+ | 0.707107 | 0.204124 |
| closeness_pace:- | 0.707107 | 0.204124 |
| initiative:+ | 0.707107 | 0.204124 |
| initiative:- | 0.707107 | 0.204124 |
| autonomy:+ | 0.707107 | 0.204124 |
| autonomy:- | 0.707107 | 0.204124 |
| reassurance_need:+ | 0.707107 | 0.204124 |
| reassurance_need:- | 0.707107 | 0.204124 |
| uncertainty_tolerance:+ | 0.707107 | 0.204124 |
| uncertainty_tolerance:- | 0.707107 | 0.204124 |
| disclosure_pace:+ | 0.707107 | 0.204124 |
| disclosure_pace:- | 0.707107 | 0.204124 |
| boundary_firmness:+ | 0.707107 | 0.204124 |
| boundary_firmness:- | 0.707107 | 0.204124 |
| repair_style:+ | 0.707107 | 0.204124 |
| repair_style:- | 0.707107 | 0.204124 |
| social_energy:+ | 0.707107 | 0.204124 |
| social_energy:- | 0.707107 | 0.204124 |
| structure_preference:+ | 0.707107 | 0.204124 |
| structure_preference:- | 0.707107 | 0.204124 |
| adaptability:+ | 0.707107 | 0.204124 |
| adaptability:- | 0.707107 | 0.204124 |

| norm(psi) | 1.000000 |
| Σ pole² | 12.000000 |
| trace | 1.000000 |
| purity | 1.000000 |

## SINGLE_AXIS_-1

12D input:

| dimension | x |
|---|---|
| contact_need | -1.000000 |
| closeness_pace | 0 |
| initiative | 0 |
| autonomy | 0 |
| reassurance_need | 0 |
| uncertainty_tolerance | 0 |
| disclosure_pace | 0 |
| boundary_firmness | 0 |
| repair_style | 0 |
| social_energy | 0 |
| structure_preference | 0 |
| adaptability | 0 |

24D amplitudes (signed poles, before `/sqrt(12)`):

| basis | amplitude | psi |
|---|---|---|
| contact_need:+ | 0 | 0 |
| contact_need:- | 1.000000 | 0.288675 |
| closeness_pace:+ | 0.707107 | 0.204124 |
| closeness_pace:- | 0.707107 | 0.204124 |
| initiative:+ | 0.707107 | 0.204124 |
| initiative:- | 0.707107 | 0.204124 |
| autonomy:+ | 0.707107 | 0.204124 |
| autonomy:- | 0.707107 | 0.204124 |
| reassurance_need:+ | 0.707107 | 0.204124 |
| reassurance_need:- | 0.707107 | 0.204124 |
| uncertainty_tolerance:+ | 0.707107 | 0.204124 |
| uncertainty_tolerance:- | 0.707107 | 0.204124 |
| disclosure_pace:+ | 0.707107 | 0.204124 |
| disclosure_pace:- | 0.707107 | 0.204124 |
| boundary_firmness:+ | 0.707107 | 0.204124 |
| boundary_firmness:- | 0.707107 | 0.204124 |
| repair_style:+ | 0.707107 | 0.204124 |
| repair_style:- | 0.707107 | 0.204124 |
| social_energy:+ | 0.707107 | 0.204124 |
| social_energy:- | 0.707107 | 0.204124 |
| structure_preference:+ | 0.707107 | 0.204124 |
| structure_preference:- | 0.707107 | 0.204124 |
| adaptability:+ | 0.707107 | 0.204124 |
| adaptability:- | 0.707107 | 0.204124 |

| norm(psi) | 1.000000 |
| Σ pole² | 12.000000 |
| trace | 1.000000 |
| purity | 1.000000 |

## Neutrality

For `x = 0`, plus and minus pole amplitudes are equal (`sqrt(0.5)`). That is behavioral center. It is not unknown, low confidence, or missing.

## What this phase does not do

- define mixedness lambda
- inject confidence / evidence / latency into psi
- create pair compatibility or entanglement
- create collapse / measurement metaphors
- claim quantum mechanics validates personality
- modify scorer, confidence, selector, or evidence
- activate V2 or persist the 24×24 matrix
- touch V1 / Firebase / C2 / Discover / Persona / matching

FREQUENCY V2 PHASE 5A SIGNED 24D QUANTUM-INSPIRED BEHAVIORAL STATE READY — V2 STILL DORMANT
