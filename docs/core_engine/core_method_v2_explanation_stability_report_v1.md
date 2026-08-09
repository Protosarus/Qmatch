# Core Method v2 Explanation Stability Report v1

Phase: **P2B-6**. Explanations must not alter source scores.

**Synthetic data cannot establish predictive validity or calibration.**

## Deep-dive explanation stability

Source: `tool/core_method_v2_out/robustness_v1/explanation_stability.json`

| metric | value |
|--------|------:|
| trials | 90 |
| mean Jaccard | ≈ 0.993 |
| min Jaccard | ≈ 0.846 |
| top-1 stability | 1.0 |
| top-3 overlap mean | 1.0 |
| threshold-driven changes | 4 |
| Jaccard bounded [0,1] | true |

Perturbations use experiment-local preference-scale deltas as controlled
numeric stress; legitimate threshold crossings are allowed.

## Score preservation

Harness + scenario suite confirm explanation generation does not mutate
overall raw/adjusted scores or contribution counts.

## Status

`explanation_stability`: **conditional** (stable under small perturbations;
brittle thresholds remain documented, unchanged).
