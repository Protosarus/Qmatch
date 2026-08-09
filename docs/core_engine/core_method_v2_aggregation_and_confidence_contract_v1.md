# Core Method v2 Aggregation and Confidence Contract v1

Phase: **P2B-4** (offline overall score only)

Config: `assets/data/core_method_v2/core_method_v2_aggregation_config_v1.json`

## Component set

Exactly five provisional components:

| ID | Source score | Source confidence |
|----|--------------|-------------------|
| `iq_structural` | IQ `similarityScore` | IQ `evidenceConfidence` |
| `eq_structural` | EQ `similarityScore` | EQ `evidenceConfidence` |
| `frequency_structural` | Frequency `similarityScore` | Frequency `evidenceConfidence` |
| `mutual_partner_preference` | `mutualRawFitScore` | `mutualEvidenceConfidence` |
| `mutual_relationship_values` | `mutualRawValueFitScore` | `mutualEvidenceConfidence` |

Not scored: directional fits, asymmetries, soft severity, hard outcomes, persona, Frequency type, AI.

## Available set \(A\)

Components with finite scores/confidences in \([0,1]\) and scoreable source status.

## Available configured-weight mass

\[
M_{\mathrm{available}}=\sum_{c\in A} w_c
\]

(configured weights sum to 1).

## Raw aggregation

\[
S_{\mathrm{raw}}=\frac{\sum_{c\in A} w_c S_c}{\sum_{c\in A} w_c}
\]

Unavailable components are **not** imputed as \(0\), \(0.5\), or \(0.42\).
Missingness lowers \(Q\), not \(S_{\mathrm{raw}}\) directly.

No raw score when evidence gates fail, available weight is zero, inputs are
invalid, or hard constraint failed.

## Evidence confidence

\[
Q_{\mathrm{available\_mean}}=\frac{\sum_{c\in A} w_c Q_c}{\sum_{c\in A} w_c}
\]

\[
Q_{\mathrm{overall}}=\sum_{c\in A} w_c Q_c = M_{\mathrm{available}}\cdot Q_{\mathrm{available\_mean}}
\]

Hard/soft outcomes are **not** multiplied into \(Q\).

## Neutral shrinkage

\[
S_{\mathrm{adjusted}}=Q_{\mathrm{overall}}\,S_{\mathrm{raw}}+(1-Q_{\mathrm{overall}})\,S_{\mathrm{neutral}}
\]

with \(S_{\mathrm{neutral}}=0.50\).

Equivalent: \(S_{\mathrm{adjusted}}=0.50+Q_{\mathrm{overall}}(S_{\mathrm{raw}}-0.50)\).

Insufficient evidence ⇒ both scores **null** (never fabricate \(0.50\)).

## Hard-constraint gating

| Outcome | Scores | Status | publishable | rankingEligible |
|---------|--------|--------|-------------|-----------------|
| failed | null | blocked_by_hard_constraint | false | false |
| unknown | may exist offline | partial | false | false |
| passed / not_applicable | if gates pass | complete/partial | offline review only; production false | false |

Failed is **not** converted to numeric 0.

## Soft conflicts and asymmetries

Diagnostics only. No penalty, multiplier, confidence reduction, or hard block.

## Non-claims

- Not production approved / not scientifically validated.
- Not a personality or moral judgment.
- Not predictive validity.
- Offline-only; no Discover/Firebase/live ranking.
