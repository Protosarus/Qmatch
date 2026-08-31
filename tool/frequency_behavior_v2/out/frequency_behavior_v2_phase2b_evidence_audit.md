# Frequency V2 Phase 2B — Evidence prior proposal audit

Status: **proposal only**. Not applied to the dormant pool.
All values are **uncalibrated reviewer priors**, not validated coefficients,
truth/lie probabilities, personality probabilities, or empirical discrimination.

Source pool fingerprint SHA-256: `d03b2d8c77843d72baf072219c2c0dcae07a0d093dd1bf8c5268f0ef4ca6d56d`

## Counts

- Selectable questions scored: **408**
- Selectable options scored: **1632**
- DROP questions left pending/null: **18**
- DROP options left pending/null: **72** (absent from proposal)
- `needs_human_review=true`: **397**
- Evidence-quality HIGH: **18**
- Evidence-quality MEDIUM: **64**
- Evidence-quality LOW: **326**

## Field distributions (1632 scored options)

### social_desirability

- 0.00: 13
- 0.25: 20
- 0.50: 1490
- 0.75: 105
- 1.00: 4

### obviousness

- 0.00: 0
- 0.25: 343
- 0.50: 1235
- 0.75: 51
- 1.00: 3

### behavioral_plausibility

- 0.00: 0
- 0.25: 244
- 0.50: 103
- 0.75: 1137
- 1.00: 148

### self_presentation_risk

- 0.00: 2
- 0.25: 340
- 0.50: 1236
- 0.75: 52
- 1.00: 2

### diagnostic_value

- 0.00: 112
- 0.25: 608
- 0.50: 547
- 0.75: 271
- 1.00: 94

### ambiguity

- 0.00: 0
- 0.25: 1044
- 0.50: 446
- 0.75: 138
- 1.00: 4

## Same-value siblings

Questions where all four options received the identical grid value:

- `social_desirability`: 288 questions
- `obviousness`: 233 questions
- `behavioral_plausibility`: 256 questions
- `self_presentation_risk`: 232 questions
- `diagnostic_value`: 16 questions
- `ambiguity`: 100 questions

This is allowed. Rankings were not manufactured so that every option differs.

## Flagged subsets

- Any `ambiguity` ≥ 0.75: 132 questions: `frequency_v2_q0002`, `frequency_v2_q0004`, `frequency_v2_q0007`, `frequency_v2_q0009`, `frequency_v2_q0011`, `frequency_v2_q0012`, `frequency_v2_q0020`, `frequency_v2_q0024`, `frequency_v2_q0026`, `frequency_v2_q0030`, `frequency_v2_q0032`, `frequency_v2_q0034`, `frequency_v2_q0036`, `frequency_v2_q0037`, `frequency_v2_q0040`, `frequency_v2_q0041`, `frequency_v2_q0042`, `frequency_v2_q0043`, `frequency_v2_q0045`, `frequency_v2_q0048`, `frequency_v2_q0049`, `frequency_v2_q0050`, `frequency_v2_q0055`, `frequency_v2_q0060`, `frequency_v2_q0062`, `frequency_v2_q0064`, `frequency_v2_q0069`, `frequency_v2_q0071`, `frequency_v2_q0072`, `frequency_v2_q0075`, `frequency_v2_q0078`, `frequency_v2_q0080`, `frequency_v2_q0082`, `frequency_v2_q0087`, `frequency_v2_q0089`, `frequency_v2_q0091`, `frequency_v2_q0095`, `frequency_v2_q0097`, `frequency_v2_q0103`, `frequency_v2_q0106` … +92
- Any `social_desirability` ≥ 0.75: 100 questions: `frequency_v2_q0001`, `frequency_v2_q0002`, `frequency_v2_q0007`, `frequency_v2_q0008`, `frequency_v2_q0009`, `frequency_v2_q0014`, `frequency_v2_q0015`, `frequency_v2_q0019`, `frequency_v2_q0024`, `frequency_v2_q0028`, `frequency_v2_q0038`, `frequency_v2_q0040`, `frequency_v2_q0042`, `frequency_v2_q0043`, `frequency_v2_q0049`, `frequency_v2_q0050`, `frequency_v2_q0053`, `frequency_v2_q0058`, `frequency_v2_q0060`, `frequency_v2_q0086`, `frequency_v2_q0097`, `frequency_v2_q0103`, `frequency_v2_q0111`, `frequency_v2_q0113`, `frequency_v2_q0116`, `frequency_v2_q0123`, `frequency_v2_q0129`, `frequency_v2_q0137`, `frequency_v2_q0140`, `frequency_v2_q0144`, `frequency_v2_q0145`, `frequency_v2_q0148`, `frequency_v2_q0150`, `frequency_v2_q0152`, `frequency_v2_q0154`, `frequency_v2_q0159`, `frequency_v2_q0163`, `frequency_v2_q0164`, `frequency_v2_q0169`, `frequency_v2_q0172` … +60
- Any `self_presentation_risk` ≥ 0.75: 52 questions: `frequency_v2_q0002`, `frequency_v2_q0008`, `frequency_v2_q0015`, `frequency_v2_q0024`, `frequency_v2_q0028`, `frequency_v2_q0043`, `frequency_v2_q0049`, `frequency_v2_q0086`, `frequency_v2_q0097`, `frequency_v2_q0111`, `frequency_v2_q0113`, `frequency_v2_q0116`, `frequency_v2_q0123`, `frequency_v2_q0129`, `frequency_v2_q0140`, `frequency_v2_q0145`, `frequency_v2_q0148`, `frequency_v2_q0150`, `frequency_v2_q0152`, `frequency_v2_q0164`, `frequency_v2_q0169`, `frequency_v2_q0174`, `frequency_v2_q0177`, `frequency_v2_q0186`, `frequency_v2_q0193`, `frequency_v2_q0200`, `frequency_v2_q0203`, `frequency_v2_q0215`, `frequency_v2_q0220`, `frequency_v2_q0223`, `frequency_v2_q0238`, `frequency_v2_q0239`, `frequency_v2_q0240`, `frequency_v2_q0241`, `frequency_v2_q0268`, `frequency_v2_q0278`, `frequency_v2_q0281`, `frequency_v2_q0284`, `frequency_v2_q0295`, `frequency_v2_q0303` … +12
- `diagnostic_value` ≤ 0.25 for two or more options: 261 questions: `frequency_v2_q0001`, `frequency_v2_q0005`, `frequency_v2_q0006`, `frequency_v2_q0009`, `frequency_v2_q0011`, `frequency_v2_q0013`, `frequency_v2_q0019`, `frequency_v2_q0021`, `frequency_v2_q0022`, `frequency_v2_q0024`, `frequency_v2_q0025`, `frequency_v2_q0027`, `frequency_v2_q0030`, `frequency_v2_q0031`, `frequency_v2_q0033`, `frequency_v2_q0034`, `frequency_v2_q0035`, `frequency_v2_q0036`, `frequency_v2_q0038`, `frequency_v2_q0040`, `frequency_v2_q0041`, `frequency_v2_q0042`, `frequency_v2_q0045`, `frequency_v2_q0048`, `frequency_v2_q0052`, `frequency_v2_q0054`, `frequency_v2_q0057`, `frequency_v2_q0062`, `frequency_v2_q0065`, `frequency_v2_q0066`, `frequency_v2_q0067`, `frequency_v2_q0068`, `frequency_v2_q0071`, `frequency_v2_q0072`, `frequency_v2_q0073`, `frequency_v2_q0075`, `frequency_v2_q0076`, `frequency_v2_q0077`, `frequency_v2_q0078`, `frequency_v2_q0079` … +221
- Any `behavioral_plausibility` ≤ 0.25: 147 questions: `frequency_v2_q0059`, `frequency_v2_q0064`, `frequency_v2_q0065`, `frequency_v2_q0067`, `frequency_v2_q0069`, `frequency_v2_q0071`, `frequency_v2_q0072`, `frequency_v2_q0073`, `frequency_v2_q0074`, `frequency_v2_q0076`, `frequency_v2_q0077`, `frequency_v2_q0078`, `frequency_v2_q0079`, `frequency_v2_q0080`, `frequency_v2_q0081`, `frequency_v2_q0082`, `frequency_v2_q0083`, `frequency_v2_q0084`, `frequency_v2_q0085`, `frequency_v2_q0086`, `frequency_v2_q0087`, `frequency_v2_q0088`, `frequency_v2_q0089`, `frequency_v2_q0090`, `frequency_v2_q0091`, `frequency_v2_q0092`, `frequency_v2_q0093`, `frequency_v2_q0095`, `frequency_v2_q0096`, `frequency_v2_q0097`, `frequency_v2_q0098`, `frequency_v2_q0100`, `frequency_v2_q0203`, `frequency_v2_q0204`, `frequency_v2_q0206`, `frequency_v2_q0207`, `frequency_v2_q0208`, `frequency_v2_q0209`, `frequency_v2_q0210`, `frequency_v2_q0211` … +107

## Sanity audit (reported, not auto-corrected)

Mean social_desirability when primary weight is positive: 0.517
Mean social_desirability when primary weight is negative: 0.51
Mean ambiguity when primary weight is positive: 0.349
Mean ambiguity when primary weight is negative: 0.347
Mean diagnostic_value when |primary weight| = 2: 0.632
Mean diagnostic_value otherwise: 0.363

Social desirability means by primary dimension:

- `contact_need`: 0.487
- `closeness_pace`: 0.519
- `initiative`: 0.511
- `autonomy`: 0.502
- `reassurance_need`: 0.471
- `uncertainty_tolerance`: 0.5
- `disclosure_pace`: 0.536
- `boundary_firmness`: 0.517
- `repair_style`: 0.519
- `social_energy`: 0.511
- `structure_preference`: 0.521
- `adaptability`: 0.51

Notes:

- Options with |primary weight|=2 have higher mean diagnostic_value (0.632 vs 0.363). Magnitude was not used as a scoring rule; residual association is reported, not fixed.

## Safety

- Dormant pool not modified
- `review_status=reviewed` not set on the pool
- DROP options not scored
- V2 remains `runtime_selectable=false`
- No V1 / Firebase / matching / Persona / Discover / C2 / locale-routing change
- No `discrimination_power`

FREQUENCY V2 PHASE 2B EVIDENCE PRIOR PROPOSAL COMPLETE — 1632 OPTIONS SCORED — NO VALUES APPLIED — V2 STILL DORMANT
