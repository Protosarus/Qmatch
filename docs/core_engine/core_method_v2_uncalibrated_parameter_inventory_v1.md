# Core Method v2 Uncalibrated Parameter Inventory v1

Phase: **P2B-6**. **None of these parameters are empirically validated.**

**Synthetic data cannot establish predictive validity, fairness, calibration,
or production readiness.** Every row below has
`evidence_status = uncalibrated`.

Legend: **PB?** = production-blocking if used for ranking without calibration
(yes for all ranking-affecting parameters).

| path | parameter | current value | mathematical role | reason | evidence | calibration data required | risk if misspecified | PB? | future decision owner |
|------|-----------|---------------|-------------------|--------|----------|---------------------------|----------------------|-----|------------------------|
| `structural_similarity_config_v1.json` | `module_similarity_scales.iq` | 0.35 | RBF length-scale for IQ distance→similarity | provisional engineering default | uncalibrated | consented measurement + outcome pairs | over/under-sensitive IQ differences | yes | measurement + core method owners |
| same | `module_similarity_scales.eq` | 0.35 | EQ RBF scale | same | uncalibrated | same | EQ dominance/weakness vs truth | yes | same |
| same | `module_similarity_scales.frequency` | 0.35 | Frequency RBF scale | same | uncalibrated | same | lifestyle closeness mis-scaled | yes | same |
| same | `default_dimension_weight` | 1.0 | equal within-module base weights | simplicity pending calibration | uncalibrated | item information / reliability | unequal dims treated equal | yes | measurement owner |
| same | `minimum_comparable_dimensions_per_module` | iq:2 eq:4 frequency:3 | evidence gates for module similarity | engineering floor from contracts | uncalibrated | coverage vs reliability study | too-loose/too-strict nulls | yes | assessment eng owner |
| `directional_preference_fit_config_v1.json` | `minimum_flexibility_scale` | 0.10 | maps flexibility→distance tolerance (lower) | provisional linear map endpoints | uncalibrated | preference UX + outcome labels | over-penalizes mild misses | yes | product-research + core method |
| same | `maximum_flexibility_scale` | 0.35 | upper flexibility mapping | same | uncalibrated | same | under-penalizes strict prefs | yes | same |
| same | `flexibility_mapping` | `linear_scale` | functional form of flexibility | simplest provisional form | uncalibrated | model comparison on real prefs | wrong decay shape | yes | core method owner |
| same | `minimum_comparable_preferences` | 1 | evidence gate for preference fit | allow sparse prefs offline | uncalibrated | reliability of sparse prefs | unstable fits | yes | assessment eng owner |
| `relationship_value_comparison_config_v1.json` | `field_rules.*.matrix` cells | see config (intent, marriage, children, smoking, …) | categorical compatibility scores | authored provisional matrices | uncalibrated | expert review + consented outcomes | systematic value mis-fit | yes | content/expert review + core method |
| same | `field_rules.*.ordered_values` | religion, relocation, alcohol, career orders | ordered-distance ladders | provisional orderings | uncalibrated | expert + cultural review | wrong ordinal topology | yes | same |
| same | `field_rules.lifestyle_rhythm.set_overlap_metric` | `jaccard` | set similarity | provisional | uncalibrated | outcome sensitivity | over/under-count overlap | yes | same |
| same | `soft_conflict_severity_bands` | none/low/moderate/high cuts at 0 / 0.25 / 0.6 / 1.0 | diagnostic severity banding only | provisional triage bands | uncalibrated | user-research on conflict meaning | misleading diagnostics (v1 no penalty) | conditional* | product-research |
| same | `minimum_comparable_value_fields` | 1 | values evidence gate | sparse allow | uncalibrated | field reliability | unstable V_mutual | yes | assessment eng owner |
| `core_method_v2_aggregation_config_v1.json` | `component_weights.iq_structural` | 0.08 | contribution to \(S_{\mathrm{raw}}\) | prior 0.10×0.80 | uncalibrated | outcome ablation / expert | IQ under/over-weighted | yes | core method owner |
| same | `component_weights.eq_structural` | 0.24 | same | prior 0.30×0.80 | uncalibrated | same | EQ mass wrong | yes | same |
| same | `component_weights.frequency_structural` | 0.28 | same | prior 0.35×0.80 | uncalibrated | same | lifestyle dominates wrongly | yes | same |
| same | `component_weights.mutual_partner_preference` | 0.20 | same | new fifth component allocation | uncalibrated | same + redundancy study | double-count vs structural | yes | same |
| same | `component_weights.mutual_relationship_values` | 0.20 | same | prior 0.25×0.80 | uncalibrated | same | values mass wrong | yes | same |
| same | `neutral_score` | 0.50 | shrinkage target; insufficient ≠ fabricate | midpoint convention | uncalibrated | calibration of “unknown quality” | biased shrinkage center | yes | core method owner |
| same | `minimum_available_component_count` | 2 | evidence gate | provisional | uncalibrated | coverage study | score too early / too often null | yes | same |
| same | `minimum_available_weight_mass` | 0.5 | evidence gate | provisional | uncalibrated | same | same | yes | same |
| same | `hard_constraint_unknown_policy` | calculate offline but not publishable/ranking | gating semantics | safety-first provisional | uncalibrated | product policy + fairness | over/under-withhold | yes | product + trust/safety |
| same | `hard_constraint_failed_policy` | block and withhold overall scores | categorical fail | contract | uncalibrated | false-positive/negative hard rates | wrongful blocks | yes | same |
| same | `soft_conflict_policy` | diagnostics_only_no_numeric_penalty | no score effect | pending calibration | uncalibrated | whether/how to penalize | ignored vs over-penalized conflict | yes if changed | core method + research |
| `structured_explanation_config_v1.json` | `maximum_total_signals` | 12 | cap emitted signals | UX budget provisional | uncalibrated | explanation UX studies | clutter or omission | no (UX) / yes if used for ranking | product-research |
| same | `maximum_signals_per_category` | 3 | diversity cap | same | uncalibrated | same | category starvation | no/yes† | same |
| same | `maximum_signals_per_module` | 2 | module diversity cap | same | uncalibrated | same | module under-report | no/yes† | same |
| same | `minimum_signal_confidence` | 0.25 | suppress low-Q signals | provisional | uncalibrated | comprehension study | hide useful / show weak | no/yes† | same |
| same | `high_confidence_threshold` / `moderate_confidence_threshold` | 0.75 / 0.50 | confidence wording bands | provisional | uncalibrated | same | mislabeled confidence | no/yes† | same |
| same | `structural_close_threshold` / `structural_difference_threshold` | 0.2 / 0.45 | close vs difference codes | provisional | uncalibrated | same | wrong difference narrative | no/yes† | same |
| same | `preference_strong_fit_threshold` / `preference_weak_fit_threshold` | 0.8 / 0.4 | pref strength codes | provisional | uncalibrated | same | wrong fit narrative | no/yes† | same |
| same | `value_strong_fit_threshold` / `value_weak_fit_threshold` | 0.8 / 0.4 | value strength codes | provisional | uncalibrated | same | wrong value narrative | no/yes† | same |
| same | `asymmetry_reporting_threshold` | 0.25 | emit asymmetry signals | provisional | uncalibrated | same | noise asymmetry alerts | no/yes† | same |
| same | `tie_breaking_policy` / `category_priority` / `source_component_order` | see config | salience ranking order | deterministic engineering order | uncalibrated | UX priority research | wrong emphasis | no/yes† | same |
| same | structural salience rule | `normalized_effective_weight × magnitude` | salience for structural diffs | documented provisional rule | uncalibrated | outcome/UX study | wrong “why” ranking | no/yes† | same |
| `core_method_v2_robustness_experiment_config_v1.json` | alert/perturbation thresholds | see config | experiment triage only | offline engineering | uncalibrated (by design) | N/A for production ranking | false engineering alerts | no | P2B-6 eng owner |

\* Soft bands do not change scores in v1; still production-blocking if later used as penalties without calibration.  
† Explanation params are not score inputs today; become production-blocking if explanations drive ranking or trust UI without research.

## Claims

- **Empirically validated parameters: none.**
- All frozen scoring defaults remain provisional / offline-only /
  `scientifically_validated: false`.
- Changing any PB? = yes parameter for production requires a documented
  calibration decision with consented purpose-limited data.
