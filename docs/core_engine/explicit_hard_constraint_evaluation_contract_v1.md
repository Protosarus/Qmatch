# Explicit Hard Constraint Evaluation Contract v1

Phase: **P2B-3** (offline categorical evaluation only)

## Scope

Evaluate explicitly enabled hard constraints owned by A against B's known
values, and the reverse direction. Produce directional and mutual **categorical**
outcomes. Do **not** produce a numeric hard-constraint score.

## Requirements for a constraint to apply

Hard constraints must be:

- explicitly created,
- explicitly enabled (`explicitly_enabled == true`),
- based only on registry fields with `supports_hard_constraint`,
- based on directly provided counterpart values,
- independent of IQ/EQ/Frequency scores, persona, and inferred values.

## Per-constraint outcomes

For one constraint owned by A evaluated against B:

### `not_applicable`

- constraint is disabled, **or**
- the field does not apply under its explicit configuration.

### `unknown`

- B's value is missing,
- B's value is invalid,
- comparison permission is denied,
- visibility blocks comparison,
- required registry/config metadata is unavailable.

Missing or private counterpart data must return **`unknown`**.  
It must **never** silently return passed, failed, compatible, or incompatible.

### `failed`

- B has a known value explicitly rejected by A, **or**
- A declared a non-empty accepted-value whitelist and B's known value does not
  satisfy the configured match mode.

### `passed`

- B's known value satisfies the explicit accepted/rejected rules under the
  configured match mode.

## Accepted / rejected rules

- `accepted_values` and `rejected_values` must be **disjoint**.
- Empty accepted list ⇒ no whitelist requirement.
- Empty rejected list ⇒ no blacklist restriction.
- No constraint may be silently enabled.
- No assessment/test dimension may become a hard constraint.
- Missing counterpart data is never `passed`.
- `unknown` is not failure.
- `not_applicable` is not `passed`.

## Multi-select match modes (explicit only)

Configured modes (never inferred from field name):

| mode | meaning |
|------|---------|
| `any_allowed` | If accepted non-empty: counterpart scalar/set intersects accepted. Also fails on rejected overlap. |
| `all_required` | Every accepted value must appear in counterpart set; fails on rejected overlap. |
| `no_rejected_overlap` | Passes iff counterpart set ∩ rejected = ∅ (and counterpart known). |

## Directional aggregate \(H_{(A\leftarrow B)}\)

1. `failed` if ≥1 applicable constraint failed.
2. Else `unknown` if ≥1 applicable constraint is unknown.
3. Else `passed` if ≥1 applicable constraint passed and none failed/unknown.
4. Else `not_applicable`.

## Mutual aggregate

1. `failed` if either directional aggregate failed.
2. Else `unknown` if either directional aggregate is unknown.
3. Else `passed` if ≥1 direction passed and neither failed nor unknown.
4. Else `not_applicable`.

## Non-claims

- Do not convert passed→1, failed→0, unknown→0.5.
- Do not create a final blocked `CompatibilityResult` in this phase.
- A failure may be exposed as `future_final_result_should_be_blocked: true`
  on the P2B-3 layer container only.
