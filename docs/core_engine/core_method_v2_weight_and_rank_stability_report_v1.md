# Core Method v2 Weight and Rank Stability Report v1

Phase: **P2B-6**. Provisional weights remain frozen hypotheses.

**Synthetic rankings are not dating rankings.**

## Weight sensitivity

- Experiment-local weight perturbations only (±10%, ±20% per component, renormalized to 1)
- Frozen file weights unchanged (0.08 / 0.24 / 0.28 / 0.20 / 0.20)
- Sensitivity sample capped at 250 pairs for resource-conscious full mode
- Detail: `tool/core_method_v2_out/robustness_v1/weight_sensitivity.json`

## Rank stability (deep dive sample)

Raw vs confidence-adjusted ranking (n=1000 sampled pairs):

| metric | value |
|--------|------:|
| Spearman | ≈ 0.988 |
| top 1% overlap | 0.70 |
| top 5% overlap | 0.70 |
| top 10% overlap | 0.84 |
| bottom 10% overlap | 0.97 |
| median abs rank movement | 24 |
| max abs rank movement | 149 |

Kendall-style concordance skipped above n=400 by design (`kendall_skipped_for_size`).

## Scale sensitivity

Structural module scales and preference flexibility scales perturbed ±10/20%
on experiment-local config copies only. See `scale_sensitivity.json`.

## Interpretation

Parameter sensitivity remains **conditional**: synthetic stability does not
calibrate production weights. Do not auto-recommend new weights from this phase.
