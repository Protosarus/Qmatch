# Structural Profile Similarity Contract v1

Phase: **P2B-1** (offline formula execution for structural similarity only)

Machine config: `assets/data/core_method_v2/structural_similarity_config_v1.json`

## Scope

Compare two `CanonicalUserAssessmentProfile` snapshots and compute **separate**
structural similarity results for IQ, EQ, and Frequency.

This contract does **not** define final compatibility, preference fit, values
scoring, hard constraints, soft penalties, module-weight aggregation, or
confidence-to-neutral shrinkage (P2B-4).

## Symbols

For subjects \(i, j\) and canonical dimension \(k\):

| Symbol | Meaning |
|--------|---------|
| \(\mu_{ik}\) | published normalized score of subject \(i\) on \(k\) |
| \(\mu_{jk}\) | published normalized score of subject \(j\) on \(k\) |
| \(q_{ik}\) | dimension-level confidence of subject \(i\) on \(k\) |
| \(q_{jk}\) | dimension-level confidence of subject \(j\) on \(k\) |
| \(w_k\) | configured base dimension weight |
| \(s_m\) | configured module similarity scale for module \(m\) |

## Pair confidence

\[
q_{ijk} = \sqrt{q_{ik} \cdot q_{jk}}
\]

Mode: **geometric mean** (`pair_confidence_mode = geometric_mean`).

## Absolute difference

\[
\delta_{ijk} = \lvert \mu_{ik} - \mu_{jk} \rvert
\]

## Effective dimension weight

\[
a_{ijk} = w_k \cdot q_{ijk}
\]

## Confidence-aware normalized squared distance

Over comparable dimensions \(k\) in module \(m\):

\[
d_{ij,m}^{2}
=
\frac{
\sum_{k} a_{ijk}\,(\mu_{ik}-\mu_{jk})^{2}
}{
\sum_{k} a_{ijk}
}
\]

Required: \(0 \le d_{ij,m}^{2} \le 1\) for scores in \([0,1]\).

## Structural similarity (Gaussian RBF)

\[
S_{ij,m}
=
\exp\!\left(
-\frac{d_{ij,m}^{2}}{2\,s_m^{2}}
\right)
\]

Required: \(0 < S_{ij,m} \le 1\) for valid finite inputs with positive effective
weight sum. Identical profiles yield \(S = 1\). Larger distance never increases
\(S\).

## Comparable dimensions

A dimension is comparable only when all eligibility rules in the companion
service/docs pass (registry membership, module match, `supports_similarity`,
both published/publishable with finite in-bounds scores and confidences,
\(q_{ijk} > 0\), version-compatibility policy). Failures are excluded with
structured exclusion codes — never silently imputed as `0`, `0.5`, or `0.42`.

## Coverage and evidence confidence (not similarity)

Unweighted coverage:

\[
\mathrm{coverage\_count}_m
=
\frac{\#\text{comparable}}{\#\text{active similarity-enabled dims in }m}
\]

Weighted coverage:

\[
\mathrm{coverage\_weight}_m
=
\frac{\sum_{\text{comparable}} w_k}{\sum_{\text{similarity-enabled}} w_k}
\]

Mean pair confidence (comparable only):

\[
\overline{q}_m
=
\frac{\sum w_k\,q_{ijk}}{\sum w_k}
\]

Provisional structural evidence confidence:

\[
Q_{\mathrm{struct},m}
=
\mathrm{coverage\_weight}_m \cdot \overline{q}_m
\]

\(Q_{\mathrm{struct},m}\) is an **evidence-quality summary**, not a
compatibility score. **P2B-1 does not** shrink \(S\) toward neutral using
\(Q\). That adjustment is reserved for P2B-4.

### Single-dimension confidence nuance

When only one dimension is comparable, \(a_{ijk}\) cancels in the normalized
distance, so changing both subjects’ confidences may leave raw \(S\) unchanged
while \(Q_{\mathrm{struct},m}\) decreases. Documented and tested.

## Explicit non-claims

- Raw structural similarity is **not** final compatibility.
- Raw structural similarity is **not** confidence.
- Low evidence confidence does **not** automatically mean low similarity.
- Uncertainty is preserved on measurements but **not** separately multiplied in
  formula v1; confidence is the v1 evidence-weight source.
- Module aggregation weights (0.10 / 0.30 / 0.35 / 0.25) are **not** applied.
- Complementarity is **disabled**.
- Persona input is **prohibited**.
- AI scoring is **prohibited**.

## Required algebraic properties

- Symmetry under A/B reversal
- Identity: identical published comparable inputs → distance 0, similarity 1
- Monotonicity: larger distance never increases similarity
- Order independence: map/registry iteration order must not change fingerprints
- No missing-value imputation

## Calibration status

All scales and equal base weights are **provisional**, **uncalibrated**,
**offline-only**, and **not production approved**.
