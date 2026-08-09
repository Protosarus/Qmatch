# Core Method v2 Missingness and Confidence Robustness Report v1

Phase: **P2B-6**.

**Synthetic data cannot establish predictive validity or calibration.**

## Findings (offline)

Source JSON: `tool/core_method_v2_out/robustness_v1/missingness_confidence.json`

| property | result |
|----------|--------|
| Missing components imputed as neutral | **No** |
| Available-weight renormalization used | **Yes** |
| Available mass falls with missingness | **Yes** |
| Q_overall falls under confidence degradation | **Yes** (when scores exist) |
| Adjusted score moves toward neutral under low Q | **Yes** |
| Insufficient evidence fabricates 0.50 | **No** |

Worked aggregation fixtures (unit/scenario suite):

- Drop IQ (w=0.08): mass → 0.92; equal remaining scores keep raw unchanged
- All missing → null raw/adjusted (not 0.50)
- Soft conflict severity does not change raw/adjusted/Q

## Hard / soft cross-checks

- Hard failed blocks scores (null); audit contributions retained
- Hard unknown remains unknown (never auto-passed/failed)
- Soft conflicts diagnostic-only (`soft_conflict_regression.json` exact equality)
