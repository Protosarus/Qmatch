# Directional Partner-Preference Fit Contract v1

Phase: **P2B-2** (offline formula execution for directional preference fit only)

Config: `assets/data/core_method_v2/directional_preference_fit_config_v1.json`

## Scope

Calculate directional preference fit:

\[
F_{(A\leftarrow B)}
\]

= degree to which **B's measured profile** satisfies **A's explicitly declared**
partner-dimension preferences.

Also calculate the reverse direction \(F_{(B\leftarrow A)}\) and, when both are
available:

\[
F_{\mathrm{mutual}} = \sqrt{F_{(A\leftarrow B)}\cdot F_{(B\leftarrow A)}}
\]

\[
A_{\mathrm{pref}} = \lvert F_{(A\leftarrow B)} - F_{(B\leftarrow A)}\rvert
\]

## Explicit non-claims

- Directional preference fit is **not** structural similarity.
- It is **not** final compatibility.
- It is **not** a personality judgment.
- It is **not** a hard-constraint result.
- It is **not** a relationship-value score.
- It does **not** use persona.
- It does **not** infer what A should prefer from self scores by default.
- It is **not** aggregated with IQ/EQ/Frequency structural scores in this phase.
- Module weights and confidence-to-neutral shrinkage are **not** applied.

## Symbols

| Symbol | Meaning |
|--------|---------|
| \(\mu_{Bk}\) | B's published normalized score on dimension \(k\) |
| \(q_{Bk}\) | confidence of B's measurement |
| \(\mu_{Ak}\) | A's published self-score (similarity-to-self only) |
| \(q_{Ak}\) | A's measurement confidence (similarity-to-self only) |
| \(I_{Ak}\) | A's declared importance |
| \(f_{Ak}\) | A's declared flexibility in \([0,1]\) |
| \(p_{Ak}(B)\) | dimension preference-fit value |
| \(q_{Ak}(B)\) | evidence confidence for the preference comparison |
| \(a_{Ak}(B)\) | effective directional weight |

## Effective weight and directional fit

\[
a_{Ak}(B) = I_{Ak}\cdot q_{Ak}(B)
\]

\[
F_{(A\leftarrow B)}
=
\frac{\sum a_{Ak}(B)\,p_{Ak}(B)}{\sum a_{Ak}(B)}
\]

over eligible preference dimensions only.

Required: \(0\le p_{Ak}(B)\le 1\), \(0\le F\le 1\). Direction preserved.
Map order independence. No missing-value imputation (`0` / `0.5` / `0.42`).

Low confidence reduces influence and evidence confidence; it does **not**
automatically mean poor preference fit.

### Single-dimension nuance

With one comparable preference, \(a\) cancels in the normalized raw fit, so
changing measurement confidence may leave raw \(F\) unchanged while
\(Q_{(A\leftarrow B)}\) decreases.

## Range mode

Preferred interval \([L_{Ak}, U_{Ak}]\).

Distance to range \(r_{Ak}(B)\):

- \(0\) if inside
- \(L-\mu\) if below
- \(\mu-U\) if above

Flexibility scale:

\[
\sigma_{Ak}=\sigma_{\min}+f_{Ak}(\sigma_{\max}-\sigma_{\min})
\]

\[
p_{Ak}(B)=\exp\!\left(-\frac{r_{Ak}(B)^2}{2\sigma_{Ak}^2}\right)
\]

Evidence confidence: \(q_{Ak}(B)=q_{Bk}\).

## Similarity-to-self mode

Only when A explicitly selected this mode and has a published self measurement.

\[
r_{Ak}(B)=\lvert\mu_{Ak}-\mu_{Bk}\rvert
\]

Same \(\sigma\) mapping and Gaussian \(p\).

Evidence confidence: \(q_{Ak}(B)=\sqrt{q_{Ak}\cdot q_{Bk}}\).

## Open mode

Explicitly no directional preference: excluded from numerator and denominator;
not scored as 1 or 0.5; reported as explicitly open.

## Unavailable mode

No usable preference: excluded; never inferred.

## Coverage and evidence confidence

Declared scoreable importance mass = Σ \(I\) over explicit `range` /
`similarity_to_self` preferences (open/unavailable excluded).

\[
\mathrm{coverage}_{(A\leftarrow B)}
=
\frac{\text{comparable importance mass}}{\text{declared scoreable importance mass}}
\]

\[
\overline{q}_{(A\leftarrow B)}
=
\frac{\sum I_{Ak}\,q_{Ak}(B)}{\sum I_{Ak}}
\quad\text{(comparable only)}
\]

\[
Q_{(A\leftarrow B)}
=
\mathrm{coverage}_{(A\leftarrow B)}\cdot\overline{q}_{(A\leftarrow B)}
\]

Declaration breadth is reported separately and **not** multiplied into raw fit
in v1.

## Mutual

\[
Q_{\mathrm{mutual}}=\sqrt{Q_{(A\leftarrow B)}\cdot Q_{(B\leftarrow A)}}
\]

If only one direction is available, mutual raw fit is null; the available
direction is retained.

## Calibration

All scales are **provisional**, **uncalibrated**, **offline-only**, and
**not production approved**.
