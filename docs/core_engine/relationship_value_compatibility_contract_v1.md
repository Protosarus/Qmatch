# Relationship Value Compatibility Contract v1

Phase: **P2B-3** (offline formula execution for relationship values only)

Config: `assets/data/core_method_v2/relationship_value_comparison_config_v1.json`  
Registry: `assets/data/core_method_v2/relationship_value_registry_v1.json`

## Scope

Calculate directional relationship-value fit:

\[
V_{(A\leftarrow B)}
\]

= degree to which **B's explicitly provided values** satisfy **A's**
explicitly declared value field (with A's importance and flexibility).

Also calculate \(V_{(B\leftarrow A)}\) and, when both are available:

\[
V_{\mathrm{mutual}}=\sqrt{V_{(A\leftarrow B)}\cdot V_{(B\leftarrow A)}}
\]

\[
A_{\mathrm{values}}=\lvert V_{(A\leftarrow B)}-V_{(B\leftarrow A)}\rvert
\]

## Explicit non-claims

- Value fit is **not** final compatibility.
- A low field fit is **not** a diagnosis.
- A value difference is **not** inherently immoral.
- Hard constraints are evaluated **separately** (categorical).
- Soft conflicts are **diagnostic signals**, not penalties in this phase.
- No structural similarity aggregation.
- No partner-preference aggregation.
- No IQ/EQ/Frequency module-weight application.
- No confidence-to-neutral shrinkage.
- No persona / Frequency-type / AI input.

## Symbols

| Symbol | Meaning |
|--------|---------|
| \(x_{Al}\), \(x_{Bl}\) | Explicit values (scalar or set) |
| \(c_{(A\leftarrow B,l)}\) | Configured base compatibility |
| \(I_{Al}\) | A's importance |
| \(f_{Al}\) | A's flexibility |
| \(p_{(A\leftarrow B,l)}\) | Flexibility-adjusted directional fit |
| \(q_{(A\leftarrow B,l)}\) | Field evidence confidence |
| \(a_{(A\leftarrow B,l)}\) | Effective weight \(I\cdot q\) |

## Flexibility-adjusted fit

\[
p_{(A\leftarrow B,l)}=c_{(A\leftarrow B,l)}+f_{Al}(1-c_{(A\leftarrow B,l)})
=1-(1-f_{Al})(1-c_{(A\leftarrow B,l)})
\]

Required:

- base fit 1 remains 1,
- flexibility 0 preserves base fit,
- greater flexibility never lowers fit,
- flexibility 1 makes the field non-penalizing (\(p=1\)),
- importance ≠ flexibility ≠ evidence confidence.

## Effective weight and directional value fit

\[
a_{(A\leftarrow B,l)}=I_{Al}\cdot q_{(A\leftarrow B,l)}
\]

\[
V_{(A\leftarrow B)}
=
\frac{\sum a_{(A\leftarrow B,l)}\,p_{(A\leftarrow B,l)}}{\sum a_{(A\leftarrow B,l)}}
\]

over eligible fields only.

Provisional v1 field evidence confidence when both values are explicit,
structurally valid, and comparison-permitted:

\[
q_{(A\leftarrow B,l)}=1
\]

This does **not** claim truthfulness, permanence, or relationship success.

## Coverage and evidence confidence

Declared scoreable importance mass = Σ \(I\) over explicit fields with a
valid configured comparison rule that is **not** `comparison_pending_review`.

\[
\mathrm{coverage}_{(A\leftarrow B)}
=
\frac{\text{comparable importance mass}}{\text{declared scoreable importance mass}}
\]

\[
\overline{q}_{(A\leftarrow B)}
=
\frac{\sum I_{Al}\,q_{(A\leftarrow B,l)}}{\sum I_{Al}}
\quad\text{(comparable only)}
\]

\[
Q_{(A\leftarrow B)}=\mathrm{coverage}_{(A\leftarrow B)}\cdot\overline{q}_{(A\leftarrow B)}
\]

\[
Q_{\mathrm{mutual}}=\sqrt{Q_{(A\leftarrow B)}\cdot Q_{(B\leftarrow A)}}
\]

Declaration breadth is **not** multiplied into raw \(V\).

## Comparison modes

Implemented only when explicitly configured per field:

1. `exact_match`
2. `categorical_compatibility_matrix` (row = owner value, column = evaluated)
3. `ordered_distance` (explicit ordered list; never alphabetical inference)
4. `set_overlap` (Jaccard when configured; missing ≠ empty set)
5. `comparison_pending_review` (exclude; never score)

Directional matrices are **not** silently symmetrized.

## Eligibility

A field is comparable only when registry/config/version/permission/visibility/
explicitness/validity/importance/flexibility/effective-weight rules all pass.
Otherwise emit a structured exclusion code. Never impute `0` / `0.5` / `0.42`.

## Status labels

All rules: provisional, uncalibrated, pending expert/content review,
not production approved.
