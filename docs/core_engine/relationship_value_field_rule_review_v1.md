# Relationship Value Field Rule Review v1

Phase: **P2B-3**. All rules provisional / uncalibrated / pending expert review /
not production approved. Inference prohibited for every field.

| field_id | comparison rule | rationale | directionality | hard | soft | privacy | pending review | remaining ambiguity |
|----------|-----------------|-----------|----------------|------|------|---------|----------------|---------------------|
| relationship_intent | categorical_compatibility_matrix | Ordered seriousness with mild directional penalty when owner is more serious | directional | yes | yes | medium | yes | Scale distances provisional |
| marriage_intent | categorical_compatibility_matrix | Explicit marriage stance with asymmetric maybe/yes cells | directional | yes | yes | high | yes | Cultural framing of maybe/undecided |
| children_preference | categorical_compatibility_matrix | Want vs do-not-want incompatible; open partial | directional | yes | yes | high | yes | Timing/number of children not modeled |
| monogamy_expectation | exact_match | Exclusivity treated as binary mismatch unless flexibility softens | symmetric | yes | yes | high | yes | Non-monogamy taxonomy incomplete |
| religion_importance | ordered_distance | Explicit ordered importance ladder | symmetric | no | yes | high | yes | Faith identity not modeled (importance only) |
| relocation_willingness | ordered_distance | Willing→conditional→unwilling ladder | symmetric | yes | yes | medium | yes | Conditional conditions unknown |
| preferred_living_location | comparison_pending_review | No defensible geo-distance / free-text rule | n/a | no | yes | medium | yes | Must not invent geography scoring |
| smoking_preference | categorical_compatibility_matrix | Symmetric lifestyle compatibility matrix | symmetric | yes | yes | medium | yes | Habit vs preference conflation |
| alcohol_preference | ordered_distance | none→social→regular ladder | symmetric | no | yes | medium | yes | Quantity/frequency coarse |
| career_priority | ordered_distance | Relative career priority ladder | symmetric | no | yes | low | yes | Work-life tradeoffs underspecified |
| lifestyle_rhythm | set_overlap (Jaccard) | Multi-select rhythm tags via `selected_values` | symmetric | no | yes | low | yes | Tag vocabulary provisional |

## Audit summary (registry)

Every current registry field is categorical, scalar-allowed-values based,
`directly_asked_only=true`, `inference_prohibited=true`, and
`pending_content_review=true`. Safe comparison rules exist only where
explicitly configured above; `preferred_living_location` remains excluded.
