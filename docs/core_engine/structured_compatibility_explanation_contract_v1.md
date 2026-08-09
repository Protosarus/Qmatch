# Structured Compatibility Explanation Contract v1

Phase: **P2B-5**. Provisional / uncalibrated / offline-only / **not** production approved.

Config: `assets/data/core_method_v2/structured_explanation_config_v1.json`  
Codes: `assets/data/core_method_v2/structured_explanation_code_registry_v1.json`

## Categories

1. `overall_status`
2. `strong_alignment`
3. `measured_difference`
4. `partner_preference_fit`
5. `relationship_value_alignment`
6. `soft_conflict`
7. `hard_constraint`
8. `directional_asymmetry`
9. `evidence_limitation`
10. `missing_information`
11. `confidence_adjustment`
12. `production_limitation`

## Polarity

`supportive` | `cautionary` | `neutral` | `unavailable` | `blocking`

## Confidence band

`high` (≥0.75) | `moderate` (≥0.50,<0.75) | `low` (>0,<0.50) | `unavailable`

## Source types

`structural_iq` | `structural_eq` | `structural_frequency` | `partner_preference` |
`relationship_value` | `hard_constraint` | `soft_conflict` | `aggregation` |
`evidence_coverage`

Prohibited source types: persona, Frequency type, AI interpretation, attachment
diagnosis, mental-health diagnosis.

## Salience (provisional)

### Structural

`effectiveWeight` already includes pair confidence.

\[
w'=\frac{w_{\mathrm{eff}}}{\sum w_{\mathrm{eff}}}
\quad
s=w'\cdot m
\]

where \(m=1-\Delta\) (close) or \(m=\Delta\) (different). Thresholds from config.

### Preference / values

\[
s=w'\cdot m
\]

with \(m\) = fit or \(1-\)fit from **existing** source fields only.

### Soft conflict

\[
s=\mathrm{mutualSeverity}\cdot Q_{\mathrm{signal}}
\]

No compatibility penalty.

### Hard constraint

Categorical precedence: failed → unknown → passed → not_applicable. Failed is
blocking. No numeric magnitude.

## Caps & ranking

Total / per-category / per-module caps from config. Tie-break:

1. blocking  
2. salience desc  
3. evidence confidence desc  
4. category priority  
5. source component order  
6. dimension/field display order  
7. signalId lexical  

## Non-modification

Explanation **never** alters raw score, adjusted score, \(Q\), contributions, or
source fingerprints.

## Non-claims

Not predictive. Not clinical. Not moral. Not a production ranking recommendation.
