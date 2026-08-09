# Core Method v2 Synthetic Population Report v1

Phase: **P2B-6**. Engineering distributions only.

**Synthetic data cannot establish predictive validity, fairness, calibration,
or production readiness.**

## Configuration

- Config: `assets/data/core_method_v2/core_method_v2_robustness_experiment_config_v1.json`
- Full outputs: `tool/core_method_v2_out/robustness_v1/`
- Smoke outputs: `tool/core_method_v2_out/robustness_v1_smoke/`
- Seeds: baseline `424242`; secondary `111111, 222222, 333333, 444444`
- Families: 26 declared synthetic profile families (artificial IDs only)

## Counts (derived)

| quantity | full mode |
|----------|----------:|
| deep-dive subjects | 2000 |
| deep-dive full-pipeline pairs | 10000 |
| explanation pair budget | 2000 |
| family-sweep subjects/family | 80 |
| invariant violations | 0 |
| unexpected exceptions | 0 |

## Deep-dive component means (available pairs)

| component | n | mean |
|-----------|--:|-----:|
| iq_structural | 10000 | 0.549 |
| eq_structural | 10000 | 0.529 |
| frequency_structural | 10000 | 0.530 |
| mutual_partner_preference | 10000 | 0.707 |
| mutual_relationship_values | 10000 | 0.781 |
| raw_aggregate | 9496 | 0.617 |
| confidence_adjusted | 9496 | 0.591 |

Hard-blocked pairs (~5% in deep dive after family sweep mix) exclude numeric
overall scores by design.

## Alerts

See `alerts.json` and `redundancy_alerts.json`. Alerts require human
interpretation and do **not** auto-modify frozen formulas or weights.

## Limitations

- Synthetic dependence patterns only
- Opaque cohort labels unused by design (not fairness proof)
- Registry-namespace harness view required for E2E aggregation (documented)
