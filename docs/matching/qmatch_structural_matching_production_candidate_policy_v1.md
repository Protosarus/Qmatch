# QMatch Structural Matching Production-Candidate Policy v1

## Status

| Path | Status |
| --- | --- |
| Discover ranking | **Live** — trusted backend `compareStageB2Structural` under `structural_l2_v1` |
| Client Dart matcher (`Canonical20dGroupNormalizedShadowMatcher`) | **Not live ranking** — `production_candidate_not_live`, `liveDiscoverRanking=false` |
| Legacy `CompatibilityScoring` | **Rollback only** — `legacy_v1` via `DiscoverService(rankingMode: DiscoverRankingMode.legacyV1)` |

Group-normalized canonical 20D is the structural Matching formula.

Discover orders L1-eligible candidates by trusted backend \(D_{\mathrm{structural}}\) (smaller distance first). The in-app Dart matcher is a frozen formula replica for tests and diagnostics; it does **not** rank Discover and does **not** read peer `canonical_v1`.

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
| Trusted backend `compareStageB2Structural` | **Live** Discover structural ranking (`structural_l2_v1`) |
| Client Dart group-normalized matcher | Formula replica / diagnostics — **not** live ranking (`production_candidate_not_live`) |
| Equal-20D shadow (`canonical_20d_shadow_distance_v1`) | **Baseline only** for comparison / regression |
| Legacy `CompatibilityScoring` | **Rollback only** Discover ranking (`legacy_v1`) |

## Prohibited in this structural core

- Persona / narrative prototype assignment as a Matching key
- Quantum layers
- RVI
- Similarity percentages / soft thresholds as the structural score
- Wiring the **client Dart matcher** into Discover ranking or UI
- Inventing an L2 percentage from `structural_distance`

## Implementation

- Contract: `lib/features/matching/domain/canonical_20d_group_normalized_shadow_contract.dart`
- Client matcher (not Discover ranking): `lib/features/matching/domain/canonical_20d_group_normalized_shadow_matcher.dart`
- Trusted backend formula port: `functions/src/canonical_20d_group_normalized_shadow.js`
- Trusted callable: `functions/src/stage_b2_l2_callable.js` (`compareStageB2Structural`)
- Discover ranking: `DiscoverRankingMode.structuralL2V1` + `DiscoverStructuralL2Ranking`
- Rollback: `DiscoverRankingMode.legacyV1`
- Offline comparison report (historical): `docs/matching/reports/legacy_vs_both_20d_shadow_diagnostic_v1.json`

## Non-goals

Does not make the client Dart matcher rank Discover. Does not change Persona assignment. Does not attach a fake L2 % on candidate cards. Does not promote L3–L5 into ranking.
