# Frequency V2 Phase 4B — Provisional dimension confidence audit

Status: **offline / dormant**. `runtime_selectable` remains false.
Confidence model: `frequency_behavior_v2_confidence_v1`
Scorer: `frequency_behavior_v2_scorer_v1`
Session seed: `phase4b-audit`
Session id: `frequency_v2_51f70aaf`

This is an engineering heuristic. Coefficients and flag thresholds were **not** retuned after seeing the distribution. `signal_utilization` is not an input. Behavioral direction is unchanged.

## Invariants

- Deterministic HIGH_CONFIDENCE_CLEAN JSON repeat: **true**
- All named patterns `ok`: **true**

### HIGH_CONFIDENCE_CLEAN

Max primary-dimension weight on every presented question.

| dimension | norm | eq | obs | cons | cov | pressure | prov | complete | flags |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `contact_need` | 0.611 | 0.688 | 1.000 | 1.000 | 1.000 | 0.500 | 0.759 | 1.000 | — |
| `closeness_pace` | 0.409 | 0.604 | 1.000 | 0.850 | 1.000 | 0.479 | 0.705 | 1.000 | — |
| `initiative` | 0.318 | 0.683 | 1.000 | 0.929 | 1.000 | 0.500 | 0.748 | 1.000 | — |
| `autonomy` | 0.254 | 0.750 | 1.000 | 1.000 | 1.000 | 0.479 | 0.791 | 1.000 | — |
| `reassurance_need` | 0.304 | 0.688 | 1.000 | 1.000 | 1.000 | 0.500 | 0.759 | 1.000 | — |
| `uncertainty_tolerance` | 0.105 | 0.708 | 1.000 | 1.000 | 1.000 | 0.458 | 0.776 | 1.000 | — |
| `disclosure_pace` | 0.278 | 0.708 | 1.000 | 0.625 | 1.000 | 0.625 | 0.698 | 1.000 | — |
| `boundary_firmness` | 0.240 | 0.708 | 1.000 | 1.000 | 1.000 | 0.563 | 0.758 | 1.000 | — |
| `repair_style` | 0.667 | 0.563 | 1.000 | 0.833 | 1.000 | 0.417 | 0.693 | 1.000 | — |
| `social_energy` | 0.421 | 0.667 | 1.000 | 1.000 | 1.000 | 0.458 | 0.757 | 1.000 | — |
| `structure_preference` | 0.290 | 0.688 | 1.000 | 1.000 | 1.000 | 0.500 | 0.759 | 1.000 | — |
| `adaptability` | 0.286 | 0.750 | 1.000 | 1.000 | 1.000 | 0.517 | 0.785 | 1.000 | — |

provisional_confidence 0.693 … 0.791. Dimensions with unavailable context: 0 (completeness 0.80 there).

### HIGH_CONFIDENCE_MODERATE_BEHAVIOR

Prefer authored ±1 primary weights (moderate utilization, not a confidence input).

| dimension | norm | eq | obs | cons | cov | pressure | prov | complete | flags |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `contact_need` | 0.500 | 0.688 | 1.000 | 0.875 | 1.000 | 0.500 | 0.743 | 1.000 | — |
| `closeness_pace` | 0.500 | 0.604 | 1.000 | 0.850 | 1.000 | 0.479 | 0.705 | 1.000 | — |
| `initiative` | 0.182 | 0.650 | 1.000 | 1.000 | 1.000 | 0.500 | 0.742 | 1.000 | — |
| `autonomy` | 0.269 | 0.646 | 1.000 | 0.833 | 1.000 | 0.458 | 0.725 | 1.000 | — |
| `reassurance_need` | 0.348 | 0.708 | 1.000 | 0.875 | 1.000 | 0.500 | 0.752 | 1.000 | — |
| `uncertainty_tolerance` | 0.000 | 0.708 | 1.000 | 0.625 | 1.000 | 0.458 | 0.725 | 1.000 | — |
| `disclosure_pace` | 0.056 | 0.771 | 1.000 | 0.542 | 1.000 | 0.563 | 0.725 | 1.000 | — |
| `boundary_firmness` | 0.120 | 0.646 | 1.000 | 0.583 | 1.000 | 0.375 | 0.703 | 1.000 | — |
| `repair_style` | -0.222 | 0.646 | 1.000 | 0.667 | 1.000 | 0.458 | 0.702 | 1.000 | — |
| `social_energy` | -0.105 | 0.646 | 1.000 | 0.833 | 1.000 | 0.500 | 0.718 | 1.000 | — |
| `structure_preference` | 0.290 | 0.604 | 1.000 | 0.850 | 1.000 | 0.500 | 0.702 | 1.000 | — |
| `adaptability` | 0.286 | 0.750 | 1.000 | 1.000 | 1.000 | 0.517 | 0.785 | 1.000 | — |

Utilization is lower than CLEAN where ±1 is available; confidence is not driven by |weight|.

### HIGH_PRESENTATION_PRESSURE

Highest authored `self_presentation_risk` per question.

| dimension | norm | eq | obs | cons | cov | pressure | prov | complete | flags |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `contact_need` | 0.389 | 0.688 | 1.000 | 0.500 | 1.000 | 0.500 | 0.692 | 1.000 | — |
| `closeness_pace` | 0.500 | 0.604 | 1.000 | 0.850 | 1.000 | 0.479 | 0.705 | 1.000 | — |
| `initiative` | 0.318 | 0.717 | 1.000 | 0.714 | 1.000 | 0.500 | 0.734 | 1.000 | — |
| `autonomy` | 0.075 | 0.646 | 0.000 | 1.000 | 1.000 | 0.500 | 0.471 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `reassurance_need` | 0.522 | 0.646 | 0.750 | 0.750 | 1.000 | 0.500 | 0.639 | 1.000 | — |
| `uncertainty_tolerance` | -0.211 | 0.771 | 1.000 | 0.875 | 1.000 | 0.563 | 0.769 | 1.000 | — |
| `disclosure_pace` | 0.389 | 0.688 | 0.750 | 0.750 | 1.000 | 0.625 | 0.640 | 1.000 | — |
| `boundary_firmness` | 0.040 | 0.646 | 0.500 | 0.667 | 1.000 | 0.604 | 0.548 | 1.000 | — |
| `repair_style` | 0.222 | 0.583 | 0.750 | 0.500 | 1.000 | 0.458 | 0.583 | 1.000 | — |
| `social_energy` | 0.263 | 0.688 | 0.750 | 0.500 | 1.000 | 0.500 | 0.624 | 1.000 | — |
| `structure_preference` | 0.323 | 0.688 | 1.000 | 0.400 | 1.000 | 0.500 | 0.678 | 1.000 | CONTEXT_SENSITIVE |
| `adaptability` | 0.163 | 0.650 | 0.800 | 0.444 | 1.000 | 0.550 | 0.607 | 1.000 | CONTEXT_SENSITIVE |

Presentation means are elevated by construction. `normalized_behavior` still follows those options’ weights. Max authored discount is 20%.

### LOW_EVIDENCE

Lowest authored `diagnostic_value` per question.

| dimension | norm | eq | obs | cons | cov | pressure | prov | complete | flags |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `contact_need` | 0.167 | 0.542 | 0.000 | 1.000 | 1.000 | 0.458 | 0.428 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `closeness_pace` | 0.045 | 0.479 | 0.250 | 0.900 | 1.000 | 0.479 | 0.452 | 1.000 | LOW_EVIDENCE_QUALITY, LOW_PRIMARY_OBSERVABILITY |
| `initiative` | 0.023 | 0.567 | 0.200 | 0.857 | 1.000 | 0.500 | 0.470 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `autonomy` | 0.328 | 0.500 | 0.000 | 1.000 | 1.000 | 0.458 | 0.409 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `reassurance_need` | 0.174 | 0.563 | 0.000 | 1.000 | 1.000 | 0.500 | 0.433 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `uncertainty_tolerance` | 0.368 | 0.521 | 0.000 | 1.000 | 1.000 | 0.500 | 0.414 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `disclosure_pace` | -0.111 | 0.604 | 0.500 | 0.708 | 1.000 | 0.458 | 0.553 | 1.000 | — |
| `boundary_firmness` | 0.160 | 0.542 | 0.250 | 0.750 | 1.000 | 0.563 | 0.451 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `repair_style` | 0.111 | 0.438 | 0.500 | 0.417 | 1.000 | 0.417 | 0.441 | 1.000 | LOW_EVIDENCE_QUALITY, CONTEXT_SENSITIVE |
| `social_energy` | -0.105 | 0.521 | 0.500 | 0.667 | 1.000 | 0.458 | 0.509 | 1.000 | — |
| `structure_preference` | 0.000 | 0.521 | 0.250 | 0.850 | 1.000 | 0.500 | 0.462 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `adaptability` | 0.224 | 0.550 | 0.200 | 0.833 | 1.000 | 0.500 | 0.459 | 1.000 | LOW_PRIMARY_OBSERVABILITY |

Diagnostic means are lowered by construction. Direction still comes from weights.

### CONTEXT_SENSITIVE

Alternate max/min primary weight within each dimension (`question_id` order).

| dimension | norm | eq | obs | cons | cov | pressure | prov | complete | flags |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `contact_need` | 0.333 | 0.688 | 1.000 | 0.500 | 1.000 | 0.500 | 0.692 | 1.000 | — |
| `closeness_pace` | 0.273 | 0.646 | 1.000 | 0.650 | 1.000 | 0.458 | 0.700 | 1.000 | — |
| `initiative` | 0.182 | 0.717 | 1.000 | 0.429 | 1.000 | 0.500 | 0.695 | 1.000 | CONTEXT_SENSITIVE |
| `autonomy` | 0.313 | 0.667 | 1.000 | 0.875 | 1.000 | 0.438 | 0.743 | 1.000 | — |
| `reassurance_need` | 0.522 | 0.708 | 1.000 | 0.875 | 1.000 | 0.500 | 0.752 | 1.000 | — |
| `uncertainty_tolerance` | 0.026 | 0.729 | 1.000 | 0.333 | 1.000 | 0.458 | 0.694 | 1.000 | CONTEXT_SENSITIVE |
| `disclosure_pace` | -0.111 | 0.750 | 1.000 | 0.500 | 1.000 | 0.563 | 0.710 | 1.000 | — |
| `boundary_firmness` | 0.340 | 0.667 | 1.000 | 0.875 | 1.000 | 0.417 | 0.747 | 1.000 | — |
| `repair_style` | 0.333 | 0.563 | 1.000 | 0.583 | 1.000 | 0.417 | 0.659 | 1.000 | — |
| `social_energy` | 0.105 | 0.688 | 1.000 | 0.417 | 1.000 | 0.500 | 0.681 | 1.000 | CONTEXT_SENSITIVE |
| `structure_preference` | 0.032 | 0.688 | 1.000 | 0.400 | 1.000 | 0.500 | 0.678 | 1.000 | CONTEXT_SENSITIVE |
| `adaptability` | 0.143 | 0.717 | 1.000 | 0.556 | 1.000 | 0.567 | 0.702 | 1.000 | — |

Eligible consistency drops where max/min primaries disagree across clusters. That is a flag, not a reversal of `normalized_behavior`.

### NO_CROSS_CONTEXT

Same max-primary answers as CLEAN. Dimensions whose presented primaries share one cluster show null consistency.

| dimension | norm | eq | obs | cons | cov | pressure | prov | complete | flags |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `contact_need` | 0.611 | 0.688 | 1.000 | 1.000 | 1.000 | 0.500 | 0.759 | 1.000 | — |
| `closeness_pace` | 0.409 | 0.604 | 1.000 | 0.850 | 1.000 | 0.479 | 0.705 | 1.000 | — |
| `initiative` | 0.318 | 0.683 | 1.000 | 0.929 | 1.000 | 0.500 | 0.748 | 1.000 | — |
| `autonomy` | 0.254 | 0.750 | 1.000 | 1.000 | 1.000 | 0.479 | 0.791 | 1.000 | — |
| `reassurance_need` | 0.304 | 0.688 | 1.000 | 1.000 | 1.000 | 0.500 | 0.759 | 1.000 | — |
| `uncertainty_tolerance` | 0.105 | 0.708 | 1.000 | 1.000 | 1.000 | 0.458 | 0.776 | 1.000 | — |
| `disclosure_pace` | 0.278 | 0.708 | 1.000 | 0.625 | 1.000 | 0.625 | 0.698 | 1.000 | — |
| `boundary_firmness` | 0.240 | 0.708 | 1.000 | 1.000 | 1.000 | 0.563 | 0.758 | 1.000 | — |
| `repair_style` | 0.667 | 0.563 | 1.000 | 0.833 | 1.000 | 0.417 | 0.693 | 1.000 | — |
| `social_energy` | 0.421 | 0.667 | 1.000 | 1.000 | 1.000 | 0.458 | 0.757 | 1.000 | — |
| `structure_preference` | 0.290 | 0.688 | 1.000 | 1.000 | 1.000 | 0.500 | 0.759 | 1.000 | — |
| `adaptability` | 0.286 | 0.750 | 1.000 | 1.000 | 1.000 | 0.517 | 0.785 | 1.000 | — |

Null consistency is completeness 0.80 + `LIMITED_CROSS_CONTEXT`, not confidence 0.

### LOW_PRIMARY_OBSERVABILITY

Prefer options with no primary weight, then 0, then smallest |primary|.

| dimension | norm | eq | obs | cons | cov | pressure | prov | complete | flags |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `contact_need` | 0.056 | 0.563 | 0.000 | 1.000 | 1.000 | 0.479 | 0.435 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `closeness_pace` | 0.091 | 0.500 | 0.000 | 1.000 | 1.000 | 0.458 | 0.409 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `initiative` | 0.000 | 0.567 | 0.200 | 0.857 | 1.000 | 0.500 | 0.470 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `autonomy` | 0.328 | 0.604 | 0.000 | 1.000 | 1.000 | 0.458 | 0.456 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `reassurance_need` | 0.261 | 0.583 | 0.000 | 1.000 | 1.000 | 0.500 | 0.443 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `uncertainty_tolerance` | 0.342 | 0.521 | 0.000 | 1.000 | 1.000 | 0.500 | 0.414 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `disclosure_pace` | 0.111 | 0.646 | 0.250 | 0.875 | 1.000 | 0.563 | 0.514 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `boundary_firmness` | 0.020 | 0.542 | 0.000 | 1.000 | 1.000 | 0.563 | 0.418 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `repair_style` | -0.111 | 0.500 | 0.000 | 1.000 | 1.000 | 0.458 | 0.409 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `social_energy` | 0.053 | 0.563 | 0.250 | 0.917 | 1.000 | 0.500 | 0.489 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `structure_preference` | 0.065 | 0.563 | 0.000 | 1.000 | 1.000 | 0.500 | 0.433 | 1.000 | LOW_PRIMARY_OBSERVABILITY |
| `adaptability` | 0.245 | 0.583 | 0.000 | 1.000 | 1.000 | 0.500 | 0.443 | 1.000 | LOW_PRIMARY_OBSERVABILITY |

Zero primary signal is “not expressing the named axis.” Secondary weights may still move other dimensions.

## Synthetic NO_CROSS_CONTEXT (same-cluster mini session)

The live 50-question bank can still yield eligible cross-context pairs. This mini session forces one cluster so missing context is not stored as 0.

- `normalized_behavior`: 1.000 (weights only)
- `cross_context_consistency`: null
- `context_component`: null
- `provisional_confidence`: 1.000
- `confidence_completeness`: 0.800
- flags: LIMITED_CROSS_CONTEXT

## Provisional confidence distribution (`HIGH_CONFIDENCE_CLEAN`, 200 seeds × 12 dimensions)

- n: **2400**
- min: **0.540**
- median: **0.736**
- mean: **0.730**
- max: **0.825**

| bucket | count | pct |
|---|---:|---:|
| [0.0, 0.2) | 0 | 0.00 |
| [0.2, 0.4) | 0 | 0.00 |
| [0.4, 0.6) | 21 | 0.88 |
| [0.6, 0.8) | 2341 | 97.54 |
| [0.8, 1.0] | 38 | 1.58 |

## Safety

- V2 not activated; selector / weights / evidence priors unchanged
- no global Frequency score, percentile, or lie detection
- confidence is not called scientifically calibrated

FREQUENCY V2 PHASE 4B PROVISIONAL DIMENSION CONFIDENCE MODEL READY — V2 STILL DORMANT
