# Core Method v2 Aggregation Sensitivity Report v1

Phase: **P2B-4**. Synthetic offline examples only. **No predictive validity claimed.**

## Component-weight effects

With equal scores \(S_c=0.5\) and \(Q_c=1\), weights do not change \(S_{\mathrm{raw}}\)
because renormalization cancels. With unequal scores, Frequency (\(w=0.28\))
moves \(S_{\mathrm{raw}}\) more than IQ (\(w=0.08\)).

| component | \(w\) | \(S\) | \(wS\) |
|-----------|------:|------:|------:|
| iq | 0.08 | 1.00 | 0.080 |
| eq | 0.24 | 0.50 | 0.120 |
| frequency | 0.28 | 0.00 | 0.000 |
| preference | 0.20 | 0.80 | 0.160 |
| values | 0.20 | 0.20 | 0.040 |
| **sum** | 1.00 | | **0.400** |

\(S_{\mathrm{raw}}=0.400\).

## Available-weight renormalization

If IQ is missing and the remaining four equal \(0.90\):

\[
S_{\mathrm{raw}}=\frac{0.92\cdot 0.90}{0.92}=0.90
\]

Missing IQ does **not** become \(0\), \(0.5\), or \(0.42\).

## Missingness lowers \(Q_{\mathrm{overall}}\)

Same case: \(M_{\mathrm{available}}=0.92\), \(Q_{\mathrm{available\_mean}}=1\),
\(Q_{\mathrm{overall}}=0.92\). Breadth fell; raw stayed \(0.90\).

## Raw score versus evidence confidence

| case | \(S_{\mathrm{raw}}\) | \(Q\) | \(S_{\mathrm{adjusted}}\) |
|------|--------------------:|------:|-------------------------:|
| high raw, high Q | 0.90 | 1.00 | 0.90 |
| high raw, low Q | 0.90 | 0.20 | 0.58 |
| low raw, high Q | 0.10 | 1.00 | 0.10 |
| low raw, low Q | 0.10 | 0.20 | 0.42 |
| neutral raw, low Q | 0.50 | 0.10 | 0.50 |

## Neutral invariance and never-farther rule

\(S_{\mathrm{raw}}=0.50\) ⇒ \(S_{\mathrm{adjusted}}=0.50\) for any \(Q\).
\(|S_{\mathrm{adjusted}}-0.50|\le|S_{\mathrm{raw}}-0.50|\).

## Hard gating

| outcome | scores | publishable | ranking |
|---------|--------|-------------|---------|
| failed | null | false | false |
| unknown | may exist offline | false | false |
| passed / not_applicable | if gates pass | offline review only | false |

Failed is categorical — never numeric \(0\).

## Soft conflict and asymmetry

Severity and directional asymmetry are diagnostic only in v1. They do not
alter \(S_{\mathrm{raw}}\), \(S_{\mathrm{adjusted}}\), or \(Q_{\mathrm{overall}}\).

## Provisional weights and double-counting

Weights are uncalibrated hypotheses. Partner-preference dimensions may overlap
structural EQ/Frequency content — empirical calibration is required before any
production ranking use.

## Production prohibition

This overall score must not yet drive Discover, ranking, matching, or Firebase
writes.
