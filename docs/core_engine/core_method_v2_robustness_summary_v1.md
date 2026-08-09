# Core Method v2 Robustness Summary v1

Phase: **P2B-6**. Offline synthetic evaluation only.

**Synthetic data cannot establish predictive validity, fairness, calibration,
or production readiness.**

## Experiment identity (full mode)

| field | value |
|-------|-------|
| mode | `full` |
| config_version | `core_method_v2_robustness_experiment_config_v1` |
| baseline_seed | `424242` |
| secondary_seeds | `111111, 222222, 333333, 444444` |
| deep-dive family | `independent_uniform` |
| deep-dive population | 2000 subjects |
| sampled / full-pipeline / explanation pairs (requested) | 50000 / 10000 / 2000 |
| deep-dive full-pipeline pairs (actual) | 10000 |
| family sweep | 26 families × 80 subjects |
| invariant violations | **0** |
| unexpected exceptions | **0** |
| engineering alerts | 42 |
| redundancy alerts | 21 |
| outputs | `tool/core_method_v2_out/robustness_v1/` (19 files) |

Smoke mode uses reduced counts under `robustness_v1_smoke/` and is
byte-identical across consecutive runs.

## Numerical classification (pipeline pairs)

| class | count |
|-------|------:|
| valid_complete | 12026 |
| valid_partial | 237 |
| insufficient_evidence | 95 |
| hard_blocked | 762 |
| invalid | 0 |
| unexpected_exceptions | 0 |

## Deep-dive score distributions (engineering only)

| metric | n | mean | neutral-window share | &lt;0.10 | &gt;0.90 |
|--------|--:|-----:|---------------------:|------:|------:|
| raw aggregate | 9496 | 0.617 | 0.146 | 0 | 0 |
| confidence-adjusted | 9496 | 0.591 | 0.210 | 0 | 0 |
| available weight mass | 10000 | 1.000 | — | — | — |

No excessive low/high saturation on overall scores in the primary deep dive.
Neutral concentration on adjusted scores is below the 0.40 alert threshold
for the deep-dive family (alerts elsewhere come from family-specific shapes).

## Separate readiness statuses

| category | status |
|----------|--------|
| numerical_robustness | pass |
| invariant_compliance | pass |
| deterministic_reproducibility | pass |
| missingness_robustness | pass |
| confidence_robustness | pass |
| hard_gating_robustness | pass |
| soft_conflict_regression | pass |
| explanation_stability | conditional |
| parameter_sensitivity | conditional |
| component_redundancy | conditional |
| calibration_readiness | conditional |
| production_readiness | **not_evaluated** |

Do **not** collapse these into one PASS.

## Critical offline interop finding

End-to-end aggregation without a harness namespace view marks
`mutual_relationship_values` invalid because value results carry
`relationship_value_registry_v1` while aggregation config expects
`canonical_dimension_registry_v1`. P2B-6 harness applies a **non-mutating**
registry-namespace view for aggregation/explanation only; authentic layer
outputs remain in the evaluation bundle. This must be resolved before any
production wiring (not by silent formula tweaks in this phase).

## Forbidden claims (always)

- predictive validity
- relationship success prediction
- psychometric calibration
- demographic fairness
- causal interpretation
- production ranking quality
