# Structural Profile Similarity — Sensitivity Report v1

Phase: **P2B-1**  
Synthetic fixtures only. **Not empirical calibration.** Not production approved.

Contract: `docs/core_engine/structural_profile_similarity_contract_v1.md`  
Config: `assets/data/core_method_v2/structural_similarity_config_v1.json`

## How differences affect distance

For comparable dimensions with equal weights and confidences, normalized squared
distance reduces to the mean of \((\mu_A-\mu_B)^2\).

| Scenario | \(\lvert\Delta\mu\rvert\) | \(d^2\) (equal q) | \(S\) at \(s=0.35\) |
|----------|---------------------------|-------------------|---------------------|
| Identical | 0 | 0 | 1.000 |
| Small uniform (0.05) | 0.05 | 0.0025 | \(\exp(-0.0025/(2\cdot0.35^2))\approx 0.990\) |
| Large uniform (0.60) | 0.60 | 0.36 | \(\exp(-0.36/(2\cdot0.35^2))\approx 0.230\) |
| Max (1.00) | 1.00 | 1.00 | \(\exp(-1/(2\cdot0.35^2))\approx 0.017\) |

## How confidence changes effective weight

\[
a_{ijk}=w_k\sqrt{q_{ik}q_{jk}}
\]

Higher pair confidence increases a dimension’s contribution to both the
numerator and denominator of \(d^2\). In **multi-dimension** cases, a large
discrepancy with high pair confidence pulls \(d^2\) up more than the same
discrepancy with low pair confidence.

## Why one-dimension similarity may stay unchanged

With a single comparable dimension, \(a_{ijk}\) cancels:

\[
d^2=(\mu_A-\mu_B)^2
\]

So changing both users’ confidences leaves raw \(S\) unchanged, while
\(Q_{\mathrm{struct}}= \mathrm{coverage}\cdot\overline{q}\) decreases.

| Case | \(S\) | \(Q_{\mathrm{struct}}\) |
|------|-------|---------------------------|
| Single dim, high q | unchanged vs low q | higher |
| Single dim, low q | same \(S\) | lower |

## Scale parameter sensitivity

Gaussian kernel \(S=\exp(-d^2/(2s_m^2))\). Larger \(s_m\) flattens the kernel
(smaller differences in \(S\)); smaller \(s_m\) sharpens it. Current offline
provisional scales are all `0.35` for IQ/EQ/Frequency — uncalibrated.

## Missing dimensions

Missing / unpublished / non-publishable dimensions are **excluded** with
structured reason codes. They never become `0`, `0.5`, or `0.42`. Module
dimension count does not inflate similarity: distance is normalized by the sum
of effective weights of **comparable** dimensions only.

## Similarity is not compatibility

Module results remain separate. No module weights, preference fit, values,
hard constraints, complementarity, persona, or final score are applied here.

## Selected deterministic fixture outcomes

See `tool/core_method_v2_out/structural_similarity_simulation_v1_report.json`
for scenario IDs 01–26 (synthetic engineering profiles only).
