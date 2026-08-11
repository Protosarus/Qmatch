# QMatch Structural Matching Production-Candidate Policy v1

## Status

`production_candidate_not_live`

Group-normalized canonical 20D is the **structural Matching production-candidate**.
It is **not** live in Discover ranking or UI.

## Scoring version

`canonical_20d_group_normalized_shadow_distance_v1`

Policy version: `structural_matching_production_candidate_policy_v1`

## Frozen module weights

| Module | Weight |
| --- | ---: |
| IQ | 0.133333 |
| EQ | 0.400000 |
| Frequency | 0.466667 |

Weights sum to 1.0 and are **frozen** under this policy.

## Formula (frozen)

Per available module \(m \in \{\mathrm{IQ},\mathrm{EQ},\mathrm{Frequency}\}\) over shared measured dimensions \(K_m\):

\[
d_m^{2}=\frac{1}{|K_m|}\sum_{k\in K_m}(\mu_{A,k}-\mu_{B,k})^{2}
\]

Combined over available modules \(A\):

\[
d^{2}=\sum_{m\in A}\tilde{w}_m\,d_m^{2},\quad
\tilde{w}_m=\frac{w_m}{\sum_{j\in A}w_j},\quad
d=\sqrt{d^{2}}
\]

Rules:

- Missing-module omission when \(|K_m|=0\)
- Remaining module weights renormalized
- **No imputation** of missing values (never 0 / 0.5 / 50)

## Roles outside this structural core

| System | Role |
| --- | --- |
| Group-normalized 20D | Structural production-candidate (this policy) — **not live** |
| Equal-20D shadow (`canonical_20d_shadow_distance_v1`) | **Baseline only** for comparison / regression |
| Legacy `CompatibilityScoring` | **Remains live** Discover ranking |

## Prohibited in this structural core

- Persona / narrative prototype assignment as a Matching key
- Quantum layers
- RVI
- Similarity percentages / soft thresholds as the structural score
- Discover ranking or UI wiring under this policy status

## Implementation

- Contract: `lib/features/matching/domain/canonical_20d_group_normalized_shadow_contract.dart`
- Matcher: `lib/features/matching/domain/canonical_20d_group_normalized_shadow_matcher.dart`
- Offline comparison report (historical): `docs/matching/reports/legacy_vs_both_20d_shadow_diagnostic_v1.json`

## Non-goals

Does not change live Discover ranking, Discover UI, Persona assignment, or legacy CompatibilityScoring behavior.
