# Structured Compatibility Explanation Sensitivity Report v1

Phase: **P2B-5**. Synthetic offline examples. **No psychological or predictive validity.**

## Salience vs compatibility

Explanation salience ranks presentation evidence. It does **not** change
\(S_{\mathrm{raw}}\), \(S_{\mathrm{adjusted}}\), or \(Q_{\mathrm{overall}}\).

Structural example (effective weight already includes pair confidence):

| dim | \(\Delta\) | \(w'\) | magnitude | salience |
|-----|-----------:|-------:|----------:|---------:|
| close | 0.10 | 0.50 | 0.90 | 0.45 |
| distant | 0.50 | 0.50 | 0.50 | 0.25 |

## Confidence bands

| \(Q\) | band |
|------:|------|
| ≥0.75 | high |
| ≥0.50 | moderate |
| >0 | low |
| ≤0 / null | unavailable |

## Caps and diversity

Provisional caps: total 12, per category 3, per module 2. EQ cannot dominate
solely via dimension count. Supportive and cautionary both retained when space
allows.

## Hard-failure precedence

Failed hard constraints are blocking and rank before supportive signals. Failed
does not become a numeric score.

## Confidence-adjustment explanation

When raw and adjusted differ, emit `score_shrunk_toward_neutral` with
raw/adjusted/neutral/\(Q\)/mass parameters. Language: conservative evidence
adjustment — not “true” or “corrected” score.

## Missing data

Distinct codes for open preference, unavailable preference, missing measurement,
private value, permission denied, pending comparison rule.

## Soft conflicts

Severity is diagnostic magnitude only. No penalty, hard block, or failure
probability claim.

## Privacy

Private/denied counterpart values are redacted from localization parameters.
Fingerprints omit unnecessary raw private content.

## Limitations

Deterministic codes cannot replace human judgment. This layer does not predict
relationship success and is not production ranking approved.
