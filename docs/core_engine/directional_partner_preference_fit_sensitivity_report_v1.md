# Directional Partner-Preference Fit — Sensitivity Report v1

Phase: **P2B-2**  
Synthetic fixtures only. **Not empirical calibration.** Not production approved.

Contract: `docs/core_engine/directional_partner_preference_fit_contract_v1.md`  
Config: `assets/data/core_method_v2/directional_preference_fit_config_v1.json`

## Range-distance behavior

Inside \([L,U]\) → \(r=0\) → \(p=1\). Outside, Gaussian penalty grows with
\(r^2\). Boundaries count as inside.

| Position vs \([0.4,0.6]\) | \(r\) | qualitative \(p\) |
|--------------------------|-------|-------------------|
| 0.50 (inside) | 0 | 1 |
| 0.40 / 0.60 (boundary) | 0 | 1 |
| 0.35 (slightly below) | 0.05 | high |
| 0.00 (far below) | 0.40 | low |
| 0.65 (slightly above) | 0.05 | high |
| 1.00 (far above) | 0.40 | low |

## Flexibility mapping

\[
\sigma = 0.10 + f\cdot(0.35-0.10)
\]

Strict \(f\) → smaller \(\sigma\) → sharper penalty. Flexible \(f\) → slower
penalty. Outside-range is not a moral defect.

## Similarity-to-self

Identical self/partner scores → \(p=1\). Larger \(\lvert\mu_A-\mu_B\rvert\)
lowers \(p\). Only when explicitly selected.

## Importance and confidence

\(a=I\cdot q\). Across multiple preferences, higher \(I\) or higher \(q\)
increases a dimension’s influence on \(F\).

## Single-dimension confidence cancellation

With one comparable preference, \(a\) cancels in normalized \(F\), so raw fit
may stay unchanged when confidence changes while \(Q\) decreases.

## Mutual geometric mean and asymmetry

\(F_{\mathrm{mutual}}=\sqrt{F_{A\leftarrow B}F_{B\leftarrow A}}\) preserves
mutuality: one weak direction lowers the mutual result. Asymmetry
\(\lvert F_{A\leftarrow B}-F_{B\leftarrow A}\rvert\) is descriptive, not
automatically negative. Pair reversal swaps directions; mutual and asymmetry
remain unchanged.

## Open vs unavailable

Open: explicit non-preference — excluded from mass, not scored 1/0.5.  
Unavailable: no usable preference — excluded, never inferred.

## Structural similarity separation

High structural similarity with low preference fit (and the reverse) are valid
independent outcomes. P2B-2 does not aggregate them.

## Calibration status

All scales are provisional / uncalibrated / offline-only.

## Simulation coverage (derived counts)

Counts are taken from
`tool/core_method_v2_out/directional_preference_fit_simulation_v1_report.json`
after running `dart run tool/simulate_directional_preference_fit_v1.dart`.
Do not treat narrative history as authoritative over that file.

- Required scenario list size: **41** (requirements 1–41 in P2B-2.1)
- `scenario_count`: derived from the scenarios array (currently **41**)
- `passed_count` / `failed_count`: derived from per-scenario `pass` flags
- `scenario_ids`: contiguous `01`…`41` (no gaps; IDs 26 and 30 exist)
- `deterministic_fingerprint`: `599b789307612437`

Manifest:
`docs/core_engine/directional_preference_fit_simulation_manifest_v1.md`

Pre-audit note: an earlier report stated **24** scenarios while still naming
scenario numbers 26 and 30. That was a sparse ID set plus a non-requirement
`meta` row — a reporting/collection gap, not evidence that 26/30 were absent.
