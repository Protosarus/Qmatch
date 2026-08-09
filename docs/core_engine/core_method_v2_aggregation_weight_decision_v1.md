# Core Method v2 Aggregation Weight Decision v1

Phase: **P2B-4**. Provisional / uncalibrated / offline-only / **not** scientifically established.

## Prior four-component hypothesis (P2B-0 config)

| component | weight |
|-----------|--------|
| IQ | 0.10 |
| EQ | 0.30 |
| Frequency | 0.35 |
| values | 0.25 |
| **sum** | **1.00** |

## Fifth component introduction

Mutual partner-preference fit is an independent engine (P2B-2) and must not be
collapsed into structural similarity or values.

Derivation:

1. Scale the four prior weights by \(0.80\).
2. Allocate \(0.20\) to `mutual_partner_preference`.
3. Preserve relative proportions among the original four.

| component | derivation | weight |
|-----------|------------|--------|
| iq_structural | \(0.10\times 0.80\) | **0.08** |
| eq_structural | \(0.30\times 0.80\) | **0.24** |
| frequency_structural | \(0.35\times 0.80\) | **0.28** |
| mutual_relationship_values | \(0.25\times 0.80\) | **0.20** |
| mutual_partner_preference | new | **0.20** |
| **sum** | | **1.00** |

## Rationale notes (non-empirical)

- Frequency remains the largest single structural/lifestyle mass.
- Partner preference is separate from structural similarity (possible
  double-counting risk if preferences restate the same traits).
- Soft conflict is **not** a weight or penalty in v1.
- Hard constraints remain categorical gates, not weights.

## Required future calibration

Empirical match outcomes, retention, reported friction, and expert review must
precede any production ranking use. Alternative futures may include learned
weights, soft-conflict penalties, or complementarity — all currently prohibited.
