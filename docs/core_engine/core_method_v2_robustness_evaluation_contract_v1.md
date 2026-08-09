# Core Method v2 Robustness Evaluation Contract v1

Phase: **P2B-6**. Offline / synthetic / provisional.

**Synthetic data can evaluate engineering behavior and mathematical
properties. It cannot establish predictive validity, fairness, calibration,
or production readiness.**

## Purpose

Define what offline robustness evaluation may claim for Core Method v2
(structural similarity, partner-preference fit, relationship values, hard
constraints, soft conflicts, five-component aggregation, confidence
shrinkage, structured explanations).

This contract governs CLI experiments under
`tool/simulate_core_method_v2_synthetic_population_v1.dart` and focused
tests in `test/core_method_v2_robustness_evaluation_test.dart`. It does
**not** authorize production ranking, Discover wiring, Firebase I/O, or
real-user data use.

## What synthetic evaluation may claim

- Numerical stability of pure-Dart services under deterministic inputs
- Mathematical invariant compliance (bounds, symmetry, identity policies)
- Engineering score-distribution shape on synthetic cohorts
- Parameter sensitivity and rank/explanation stability under controlled
  perturbations
- Missingness / confidence / hard-gating behavior relative to frozen
  contracts
- Cohort-label non-influence when labels are opaque metadata only

## What synthetic evaluation must not claim

Synthetic data **cannot** establish:

- real-world validity
- predictive accuracy
- relationship outcome calibration
- demographic fairness
- cultural validity
- psychological validity
- production ranking quality

Also forbidden from synthetic-only evidence: psychometric calibration,
causal interpretation of compatibility, and any production-readiness PASS.

## Terminology

### Numerical robustness

Scores, confidences, contributions, and explanation saliences remain finite
and inside configured bounds under seeded synthetic populations, mild input
noise, and parameter perturbations. Includes absence of NaN, infinity, and
divide-by-zero under valid service contracts.

### Mathematical invariant testing

Assertions of contract identities that must hold regardless of population
shape, for example: pair-order invariance of mutual/overall scores where
specified; structural symmetry of identical profiles; available-weight
renormalization; hard-failed withholding (not numeric zero); soft-conflict
non-penalty; explanation score preservation; missingness without imputation.

### Score-distribution analysis

Descriptive histograms, quantiles, means/variances, and available-sample
counts of component and overall scores on synthetic pairs. Used to detect
engineering pathologies (collapse, saturation, neutral pile-up), not to
infer real-user score norms.

### Component dependence

Statistical association among component scores (e.g. Pearson/Spearman) on
synthetic pairs. Dependence is an engineering signal of shared pathways or
generator structure; it is **not** proof of scientific redundancy.

### Redundancy risk

Possibility that two components largely restate the same synthetic signal,
reducing effective dimensionality. Flagged for review; **not** automatic
component removal.

### Double-counting risk

Possibility that overlapping constructs enter the overall score more than
once with separate weights (e.g. structural Frequency plus preference fit on
the same dimensions). Requires conceptual + empirical analysis; synthetic
correlation alone is insufficient for removal decisions.

### Parameter sensitivity

Change in scores and ranks when provisional parameters (weights, scales,
thresholds) are perturbed locally while frozen defaults remain untouched.
Sensitivity informs calibration priority; it does not validate parameters.

### Rank stability

Agreement of pair orderings between baseline and perturbed runs (Spearman,
Kendall-style, top/bottom overlap, absolute rank movement). Synthetic rank
stability ≠ production ranking quality.

### Explanation stability

Stability of structured explanation signal sets under small score/threshold
perturbations (Jaccard, top-k overlap, category stability, threshold
crossings). Does not validate user-facing wording or usefulness.

### Missingness robustness

Behavior when modules/dimensions/components are absent: exclude-without-
imputation, evidence-mass reduction, insufficient-evidence nulls, no
fabricated neutral overall when gates fail.

### Confidence robustness

Response of \(Q_{\mathrm{overall}}\) and confidence-adjusted scores when
component confidences are degraded: shrinkage toward neutral, never-farther
rule, Q/score bounds.

### Hard-gating robustness

Categorical hard outcomes (`passed`, `failed`, `unknown`,
`not_applicable`) continue to gate publishability/ranking eligibility per
aggregation policy; failed never becomes numeric 0; unknown ≠ passed/failed.

### Synthetic cohort-label invariance

Opaque labels (`cohort_alpha`, etc.) attached only as generation metadata
must not change scores, contributions, hard/soft outcomes, or explanation
content. Labels are not demographic features and must not be used as
fairness proxies.

### Calibration readiness

A layered checklist of evidence required before any production ranking
claim. Synthetic robustness may support **engineering** readiness only.
Measurement, product-research, outcome-calibration, and production-ranking
layers remain incomplete until ethically collected, consented,
purpose-limited real data exist.

## Experiment boundaries

- Config: `assets/data/core_method_v2/core_method_v2_robustness_experiment_config_v1.json`
- Outputs: `tool/core_method_v2_out/robustness_v1/` (full) or
  `.../robustness_v1_smoke/` (smoke)
- Real-user data policy: **forbidden in this phase**
- Frozen source configs must not be overwritten by experiments
- Complementarity, temporal layers, persona input, Frequency types, AI
  scoring, soft-conflict penalties: remain disabled/prohibited

## Related documents

- `core_method_v2_component_redundancy_and_double_counting_report_v1.md`
- `core_method_v2_calibration_readiness_framework_v1.md`
- `core_method_v2_uncalibrated_parameter_inventory_v1.md`
- `core_method_v2_robustness_summary_v1.md`
- `core_method_v2_robustness_test_coverage_v1.md`
