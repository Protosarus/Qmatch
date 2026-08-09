# Soft Relationship Conflict Signal Contract v1

Phase: **P2B-3** (offline diagnostic signals only)

## Scope

Produce non-blocking soft-conflict signals from **already computed**
relationship-value field comparisons. Soft conflicts never:

- create hard failure,
- set compatibility to zero,
- apply a numerical penalty in this phase.

## Directional severity

For field \(l\):

\[
C_{(A\leftarrow B,l)}=I_{Al}\cdot(1-p_{(A\leftarrow B,l)})
=I_{Al}\cdot(1-f_{Al})\cdot(1-c_{(A\leftarrow B,l)})
\]

Required:

- severity ∈ [0,1],
- exact fit ⇒ severity 0,
- greater importance never reduces severity,
- greater flexibility never increases severity,
- missing data ⇒ no fabricated severity.

## Mutual field severity (provisional)

\[
C_{\mathrm{mutual},l}=\max(C_{(A\leftarrow B,l)},C_{(B\leftarrow A,l)})
\]

Using max preserves a concern strongly held by either party.  
Label: provisional / uncalibrated / **not a final penalty formula**.

## Severity bands (config-driven)

Default provisional bands:

| band | range |
|------|-------|
| none | \(= 0.00\) |
| low | \(>0.00\) and \(\le 0.25\) |
| moderate | \(>0.25\) and \(\le 0.60\) |
| high | \(>0.60\) and \(\le 1.00\) |

## Explanation codes (structured only)

Examples: `value_alignment_close`, `value_difference_low_importance`,
`value_difference_high_flexibility`, `value_difference_directional`,
`soft_conflict_low`, `soft_conflict_moderate`, `soft_conflict_high`,
`value_comparison_unavailable`, `value_comparison_private`,
`hard_constraint_passed`, `hard_constraint_failed`,
`hard_constraint_unknown`, `hard_constraint_not_applicable`.

No user-facing prose. Do not label a person difficult / unhealthy /
unsuitable / incompatible.

## Single source of truth

Soft-conflict evaluation consumes `RelationshipValueFieldComparison`
records. It must not recompute base compatibility differently from
`RelationshipValueComparisonService`.
