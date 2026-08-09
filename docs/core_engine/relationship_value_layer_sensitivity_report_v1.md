# Relationship Value Layer — Sensitivity Report v1

Phase: **P2B-3**  
Synthetic fixtures only. **Not empirical calibration.** Not production approved.

## Exact-match limitations

Exact match returns 1/0. With non-zero flexibility, adjusted fit
\(p=c+f(1-c)\) softens zeros. Exact match is intentional only where different
values are treated as incompatible unless flexibility is declared.

## Matrix-based compatibility

Row = preference owner value, column = evaluated subject value. Directional
matrices are not silently symmetrized. Partial cells allow provisional nuance
(e.g. `yes`/`maybe`) without claiming calibration.

## Flexibility vs importance

- Flexibility raises adjusted fit toward 1; never lowers it.
- Importance changes cross-field influence on \(V\); it is not evidence confidence.
- Soft severity \(C=I(1-f)(1-c)\) rises with importance and falls with flexibility.

## Mutual geometric mean and asymmetry

\(V_{\mathrm{mutual}}=\sqrt{V_{A\leftarrow B}V_{B\leftarrow A}}\). One weak
direction lowers mutual. Asymmetry is diagnostic, not automatically negative.
Pair reversal swaps directions; mutual and asymmetry stay invariant.

## Hard constraints

Categorical only. Precedence: failed > unknown > passed > not_applicable.
Missing/private counterpart → **unknown** (never silent pass/fail).
Disabled → not_applicable. No numeric hard score.

## Soft conflicts

Non-blocking diagnostic bands (none/low/moderate/high). Not subtracted from
any score in this phase. Soft conflict never creates hard failure.

## Separation

Structural similarity and partner-preference fit remain independent engines.
This layer does not aggregate them and does not emit a final compatibility score.

## Simulation counts (derived)

See `tool/core_method_v2_out/relationship_value_layer_simulation_v1_report.json`
for `scenario_count`, `passed_count`, `failed_count`, `scenario_ids`, and
`deterministic_fingerprint`.

Current fingerprint: `-288357f716123148`
