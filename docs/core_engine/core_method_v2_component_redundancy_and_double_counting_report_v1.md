# Core Method v2 Component Redundancy and Double-Counting Report v1

Phase: **P2B-6**. Conceptual + synthetic engineering analysis only.

**Synthetic correlation cannot establish predictive validity, fairness,
calibration, or production readiness. Do not remove a component from
synthetic correlation alone.**

## Scope

Five aggregation components (weights provisional):

| component | weight |
|-----------|-------:|
| `iq_structural` | 0.08 |
| `eq_structural` | 0.24 |
| `frequency_structural` | 0.28 |
| `mutual_partner_preference` | 0.20 |
| `mutual_relationship_values` | 0.20 |

Observed synthetic correlations (when present) live in
`tool/core_method_v2_out/robustness_v1/component_correlations.json` and
`redundancy_alerts.json`. This report states mechanisms and mitigations;
numeric tables are filled after population runs.

## Conceptual overlap

| pair | overlap type | distinct semantics |
|------|--------------|--------------------|
| structural IQ/EQ/Frequency modules | shared distance kernel family; different dimension sets | different constructs (cognitive / emotional / lifestyle rhythm) |
| structural vs preference | both can reward “closeness” when prefs are `similarity_to_self` | structural = measured profile distance; preference = explicit desired partner range/self-similarity with importance/flexibility |
| Frequency structural + Frequency prefs | same Frequency dimensions may appear in both pathways | structural compares both profiles; preference scores how partner fits A’s declared Frequency prefs (and vice versa) |
| values vs partner expectations | both can encode lifestyle/relationship wants | values layer uses registry fields + matrices/ordered rules; preference layer uses dimensional prefs on assessment dimensions |
| soft conflict vs values/prefs | soft signals may cite same fields | soft conflict is **diagnostics-only** in v1 (no numeric penalty) |

## Synthetic correlation caveats

- Generator families (`frequency_preference_correlated`,
  `values_preference_correlated`, etc.) **inject** dependence by design.
- High \(r\) under `independent_uniform` is more concerning than under
  correlated families, but still not scientific proof of redundancy.
- Alert thresholds in experiment config (`moderate` 0.40, `high` 0.70,
  `very_high` 0.85) are engineering triage only.
- Alerts must **not** auto-change frozen weights.

## Shared pathways

1. **Assessment dimensions → structural similarity**  
   Module scores feed RBF similarity with provisional scales (0.35).

2. **Same dimensions → directional preference fit**  
   When a user declares prefs (range or `similarity_to_self`), partner
   measurements on those dimensions feed preference fit.

3. **Aggregation**  
   Structural Frequency and mutual preference are separate weighted terms;
   if prefs largely restate structural closeness, mass can be double-applied.

4. **Values registry → mutual values (+ optional soft conflict)**  
   Explicit value fields can also appear in soft-conflict diagnostics without
   changing \(S_{\mathrm{raw}}\) / \(S_{\mathrm{adjusted}}\) / \(Q\).

## Focused double-counting mechanisms

### `similarity_to_self` prefs vs structural similarity

If both parties prefer partners like themselves and profiles are close,
structural similarity and preference fit both rise. Overlap increases when
importance is high and flexibility is low. Independence increases when prefs
use **range** modes that target complementary or non-self regions, or when
prefs are open/unavailable (excluded).

### Frequency structural + preference

Frequency carries the largest structural weight (0.28) and often strong
lifestyle signal. Preference evidence on Frequency dimensions can reinforce
the same lifestyle closeness. Overlap increases in
`frequency_preference_correlated` families; independence is expected under
`frequency_preference_independent` and when Frequency prefs are missing.

### Explicit values vs partner expectations

Relationship-value matrices (intent, children, smoking, etc.) can encode
expectations that users may also express via dimensional prefs. Semantics
differ (registry field rules vs continuous dimension prefs), but product
copy and user mental models may conflate them. Synthetic correlation under
`values_preference_correlated` flags engineering dependence only.

## Conditions that increase vs decrease overlap

**Increase:** correlated generators; `similarity_to_self` dominant; high
preference importance on dimensions already close structurally; dense
Frequency evidence on both pathways; value fields that restates lifestyle
prefs.

**Decrease:** independent generators; range prefs targeting non-self bands;
missing/open prefs; values-only or structural-only available components;
evidence gates dropping one pathway.

## Current mitigation (v1)

- Separate engines and contribution audit trails (not collapsed scores)
- Soft conflict **not** applied as a penalty
- Missing components excluded without imputation / renormalization
- Confidence shrinkage toward neutral (does not remove conceptual overlap)
- Documented weight provisionality and production prohibition
- Redundancy alerts are review-only

## Future empirical analysis required

Before any component removal, weight merge, or production ranking:

1. Ethically collected, consented, purpose-limited pair outcomes
2. Partial-correlation / ablation studies on real (not synthetic) profiles
3. Expert review of construct maps (Frequency × preference × values)
4. Fairness and cultural validity analyses (cannot use opaque synthetic
   cohort labels as demographic proxies)
5. Explicit decision record if weights or components change

**Decision rule:** synthetic correlation → investigate; real-data ablation +
expert review → decide. No automatic removal from P2B-6 alerts.

## Observed full-mode deep-dive correlations

Family `independent_uniform`, seed `424242`, n=10000 pairs:

| pair | Pearson | band |
|------|--------:|------|
| EQ structural vs mutual preference | 0.064 | low |
| Frequency structural vs mutual preference | 0.050 | low |
| preference vs values | 0.002 | low |
| Frequency structural vs values | 0.016 | low |

`redundancy_alerts.json` reports **21** alerts, primarily under synthetic dependence families (e.g. preference-correlated generators). Alerts do not auto-reweight or remove components.
