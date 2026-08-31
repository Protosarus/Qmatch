# Frequency V2 Phase 4A — Dormant 12D scorer audit

Status: **offline / dormant**. `runtime_selectable` remains false.
Scorer: `frequency_behavior_v2_scorer_v1`
Selector: `frequency_behavior_v2_selector_v1`
Bank: `frequency_behavior_pool_tr_v2_draft1`
Session seed: `phase4a-audit`
Session id: `frequency_v2_aad5b7f2`
Presented questions: **50**

Synthetic patterns pick `option_id`s from the same 50-question manifest. Frequencies and evidence priors were not retuned. The selector was not modified.

## Invariants

- Deterministic CONSISTENT_POSITIVE JSON repeat: **true**
- All patterns `ok`: **true**
- DROP / ineligible in manifest: **0** (selector invariant)

## Pattern snapshots

Per dimension: `normalized_behavior` (weights only), `cross_context_consistency` (null = unavailable, not disagreement), `primary_signal_coverage`, mean self-presentation, mean diagnostic value.

### CONSISTENT_POSITIVE

Each question selects the authored option with the **highest** primary-dimension weight.

| dimension | norm | consistency | pairs elig/poss | primary cov | mean SPR | mean DV |
|---|---:|---:|---:|---:|---:|---:|
| `contact_need` | 0.625 | 1.000 | 5/5 | 1.000 | 0.500 | 0.500 |
| `closeness_pace` | 0.296 | 0.833 | 3/3 | 1.000 | 0.438 | 0.563 |
| `initiative` | 0.515 | 0.906 | 8/8 | 1.000 | 0.350 | 0.600 |
| `autonomy` | 0.190 | 1.000 | 6/6 | 1.000 | 0.500 | 0.563 |
| `reassurance_need` | 0.600 | 0.833 | 6/6 | 1.000 | 0.500 | 0.563 |
| `uncertainty_tolerance` | 0.000 | 0.625 | 6/6 | 1.000 | 0.500 | 0.625 |
| `disclosure_pace` | 0.450 | 1.000 | 5/5 | 1.000 | 0.500 | 0.750 |
| `boundary_firmness` | 0.263 | 1.000 | 3/3 | 1.000 | 0.500 | 0.750 |
| `repair_style` | 0.364 | null | 0/0 | 1.000 | 0.438 | 0.375 |
| `social_energy` | 0.625 | 1.000 | 9/9 | 1.000 | 0.500 | 0.650 |
| `structure_preference` | 0.172 | 0.875 | 6/6 | 1.000 | 0.500 | 0.688 |
| `adaptability` | 0.375 | 1.000 | 5/5 | 1.000 | 0.375 | 0.688 |

normalized_behavior range 0.000 … 0.625 (mean 0.373). Eligible consistency values stay high when pairs exist (mean 0.916). Null consistency dimensions: 1 (unavailable, not 0).

### CONSISTENT_NEGATIVE

Each question selects the authored option with the **lowest** primary-dimension weight.

| dimension | norm | consistency | pairs elig/poss | primary cov | mean SPR | mean DV |
|---|---:|---:|---:|---:|---:|---:|
| `contact_need` | -0.313 | 0.700 | 5/5 | 0.750 | 0.500 | 0.500 |
| `closeness_pace` | -0.148 | 0.833 | 3/3 | 1.000 | 0.375 | 0.625 |
| `initiative` | 0.030 | 0.625 | 8/8 | 1.000 | 0.300 | 0.550 |
| `autonomy` | 0.345 | 0.583 | 6/6 | 1.000 | 0.500 | 0.563 |
| `reassurance_need` | 0.467 | 0.875 | 6/6 | 1.000 | 0.500 | 0.500 |
| `uncertainty_tolerance` | -0.029 | 0.875 | 6/6 | 1.000 | 0.500 | 0.750 |
| `disclosure_pace` | -0.300 | 0.650 | 5/5 | 0.750 | 0.438 | 0.563 |
| `boundary_firmness` | 0.184 | 0.750 | 3/3 | 1.000 | 0.438 | 0.563 |
| `repair_style` | -0.545 | null | 0/0 | 1.000 | 0.375 | 0.438 |
| `social_energy` | -0.500 | 1.000 | 9/9 | 1.000 | 0.500 | 0.550 |
| `structure_preference` | -0.138 | 0.875 | 6/6 | 1.000 | 0.438 | 0.625 |
| `adaptability` | 0.275 | 0.450 | 5/5 | 1.000 | 0.313 | 0.625 |

normalized_behavior range -0.545 … 0.467 (mean -0.056). Picks are the lowest **primary** weight per question; secondary weights on other items still enter `raw_sum` / `capacity`, so a dimension can stay non-negative. Evidence fields are not used for direction.

### MIXED_CONTEXT

Within each primary dimension, even-ranked questions take the max primary weight and odd-ranked take the min (order = `question_id`).

| dimension | norm | consistency | pairs elig/poss | primary cov | mean SPR | mean DV |
|---|---:|---:|---:|---:|---:|---:|
| `contact_need` | 0.125 | 0.300 | 5/5 | 1.000 | 0.500 | 0.500 |
| `closeness_pace` | 0.111 | 0.500 | 3/3 | 1.000 | 0.438 | 0.688 |
| `initiative` | 0.212 | 0.625 | 8/8 | 1.000 | 0.300 | 0.550 |
| `autonomy` | 0.345 | 0.875 | 6/6 | 1.000 | 0.500 | 0.563 |
| `reassurance_need` | 0.467 | 0.833 | 6/6 | 1.000 | 0.500 | 0.563 |
| `uncertainty_tolerance` | -0.059 | 0.458 | 6/6 | 1.000 | 0.500 | 0.625 |
| `disclosure_pace` | 0.100 | 0.450 | 5/5 | 1.000 | 0.500 | 0.625 |
| `boundary_firmness` | 0.211 | 0.833 | 3/3 | 1.000 | 0.438 | 0.625 |
| `repair_style` | -0.182 | null | 0/0 | 1.000 | 0.375 | 0.438 |
| `social_energy` | 0.063 | 0.333 | 9/9 | 1.000 | 0.500 | 0.650 |
| `structure_preference` | 0.069 | 0.417 | 6/6 | 1.000 | 0.500 | 0.813 |
| `adaptability` | 0.300 | 0.400 | 5/5 | 1.000 | 0.375 | 0.625 |

Eligible consistency mean 0.548 vs CONSISTENT_POSITIVE 0.916. Direction still comes from the mixed weights (mean norm 0.147). Inconsistency is a confidence primitive, not a score reversal.

### LOW_PRIMARY_SIGNAL

Prefer options with **no** primary weight, then explicit 0, then smallest |primary weight|.

| dimension | norm | consistency | pairs elig/poss | primary cov | mean SPR | mean DV |
|---|---:|---:|---:|---:|---:|---:|
| `contact_need` | 0.000 | 1.000 | 5/5 | 0.000 | 0.500 | 0.250 |
| `closeness_pace` | 0.222 | 1.000 | 3/3 | 0.000 | 0.500 | 0.313 |
| `initiative` | 0.061 | 1.000 | 8/8 | 0.000 | 0.300 | 0.350 |
| `autonomy` | 0.328 | 1.000 | 6/6 | 0.000 | 0.500 | 0.188 |
| `reassurance_need` | 0.200 | 1.000 | 6/6 | 0.000 | 0.438 | 0.188 |
| `uncertainty_tolerance` | 0.471 | 0.875 | 6/6 | 0.250 | 0.500 | 0.375 |
| `disclosure_pace` | -0.100 | 0.800 | 5/5 | 0.500 | 0.625 | 0.438 |
| `boundary_firmness` | 0.263 | 1.000 | 3/3 | 0.000 | 0.313 | 0.250 |
| `repair_style` | 0.091 | null | 0/0 | 0.000 | 0.438 | 0.375 |
| `social_energy` | 0.063 | 0.917 | 9/9 | 0.200 | 0.500 | 0.350 |
| `structure_preference` | 0.000 | 0.875 | 6/6 | 0.250 | 0.438 | 0.313 |
| `adaptability` | 0.425 | 0.850 | 5/5 | 0.250 | 0.313 | 0.438 |

zero_primary_signal_count total 44; nonzero 6. Secondary weights may still move other dimensions. Zero primary is “not expressing the named axis,” not a lie flag.

### HIGH_SELF_PRESENTATION_PRIOR

Each question selects the option with the highest authored `self_presentation_risk`. Ties break by `option_id`.

| dimension | norm | consistency | pairs elig/poss | primary cov | mean SPR | mean DV |
|---|---:|---:|---:|---:|---:|---:|
| `contact_need` | 0.375 | 0.400 | 5/5 | 1.000 | 0.500 | 0.500 |
| `closeness_pace` | 0.407 | 0.333 | 3/3 | 1.000 | 0.500 | 0.625 |
| `initiative` | 0.545 | 0.531 | 8/8 | 0.800 | 0.400 | 0.550 |
| `autonomy` | 0.190 | 0.667 | 6/6 | 0.500 | 0.500 | 0.375 |
| `reassurance_need` | 0.667 | 0.833 | 6/6 | 1.000 | 0.500 | 0.563 |
| `uncertainty_tolerance` | 0.029 | 0.417 | 6/6 | 0.750 | 0.500 | 0.625 |
| `disclosure_pace` | 0.350 | 0.800 | 5/5 | 1.000 | 0.625 | 0.750 |
| `boundary_firmness` | 0.184 | 0.750 | 3/3 | 0.750 | 0.563 | 0.750 |
| `repair_style` | 0.364 | null | 0/0 | 1.000 | 0.500 | 0.438 |
| `social_energy` | 0.063 | 0.333 | 9/9 | 1.000 | 0.500 | 0.650 |
| `structure_preference` | 0.241 | 0.458 | 6/6 | 1.000 | 0.500 | 0.625 |
| `adaptability` | 0.300 | 0.600 | 5/5 | 0.500 | 0.438 | 0.438 |

Mean SPR is elevated by construction. normalized_behavior range 0.029 … 0.667 still matches the **weights** of those high-SPR options. High self-presentation does not flip sign in the scorer.

### LOW_DIAGNOSTIC_PRIOR

Each question selects the option with the lowest authored `diagnostic_value`. Ties break by `option_id`.

| dimension | norm | consistency | pairs elig/poss | primary cov | mean SPR | mean DV |
|---|---:|---:|---:|---:|---:|---:|
| `contact_need` | -0.125 | 1.000 | 5/5 | 0.000 | 0.500 | 0.250 |
| `closeness_pace` | 0.222 | 0.750 | 3/3 | 0.250 | 0.438 | 0.250 |
| `initiative` | 0.182 | 0.656 | 8/8 | 0.400 | 0.300 | 0.300 |
| `autonomy` | 0.276 | 1.000 | 6/6 | 0.000 | 0.500 | 0.063 |
| `reassurance_need` | 0.200 | 1.000 | 6/6 | 0.000 | 0.375 | 0.125 |
| `uncertainty_tolerance` | 0.324 | 0.750 | 6/6 | 0.250 | 0.500 | 0.375 |
| `disclosure_pace` | -0.100 | 0.700 | 5/5 | 0.500 | 0.438 | 0.375 |
| `boundary_firmness` | 0.158 | 1.000 | 3/3 | 0.000 | 0.313 | 0.125 |
| `repair_style` | 0.000 | null | 0/0 | 0.750 | 0.375 | 0.313 |
| `social_energy` | -0.188 | 0.833 | 9/9 | 0.200 | 0.500 | 0.250 |
| `structure_preference` | 0.276 | 0.667 | 6/6 | 0.500 | 0.438 | 0.313 |
| `adaptability` | 0.425 | 0.700 | 5/5 | 0.250 | 0.375 | 0.375 |

Mean diagnostic value is lowered by construction. normalized_behavior range -0.188 … 0.425 remains defined from weights. Low evidence does not zero out the answer.

## What the patterns show

- Behavioral direction (`normalized_behavior`) comes only from `behavioral_weights`.
- HIGH_SELF_PRESENTATION_PRIOR does not invert signs relative to the selected options’ weights; SPR is reported beside the score, not mixed into it.
- LOW_DIAGNOSTIC_PRIOR still yields a signed `normalized_behavior` whenever capacity > 0. Low evidence does not erase an answer.
- MIXED_CONTEXT lowers `cross_context_consistency` where eligible pairs exist. It does not rewrite `normalized_behavior` into a confidence penalty.
- When `possible_cross_context_pair_count` or eligible pairs are 0, consistency is **null**, not 0. Missing cross-context data is not treated as inconsistency.

## Safety

- V2 not activated
- no single Frequency score, percentile, or confidence coefficient
- no lie / deception / clinical labels
- selector, questions, weights, and evidence priors unchanged
- no V1 / Firebase / C2 / Discover / Persona / matching / 12D→6D adapter

FREQUENCY V2 PHASE 4A DORMANT 12D SCORER AND CONFIDENCE PRIMITIVES READY — V2 STILL DORMANT
