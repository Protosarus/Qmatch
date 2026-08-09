# QMatch EQ 10D Scoring Mathematics v1

**Phase:** P2C-2A-7R1  
**Policy:** `eq_10d_uncalibrated_signed_evidence_v1`  
**Status:** Uncalibrated launch contract (not psychometrically validated)

---

## Scientific status

This is an **uncalibrated multidimensional emotional-relational behavioral profile**.

It is **not**:

* a clinical EQ diagnostic
* a standardized emotional intelligence test
* a population percentile instrument
* a validated psychological diagnosis

---

## Taxonomy

Exactly these 10 language-independent IDs:

```text
empathy
perspective_taking
self_awareness
emotion_regulation
emotional_openness
boundary_setting
assertiveness
conflict_approach
repair_orientation
social_awareness
```

EQ trait scoring must **not** use correctness (`correctAnswer`, accuracy, answer keys).

User instruction concept:

```text
Which response is closest to what you would actually tend to do?
```

---

## Signed option evidence

For item \(i\), selected option \(o_i\), dimension \(j\):

$$
\delta_{ij}(o_i) \in [-1,1]
$$

| Value | Meaning |
|------:|---------|
| \(-1\) | strong evidence toward the low pole |
| \(0\) | neutral / no directional evidence **when explicitly present** |
| \(+1\) | strong evidence toward the high pole |

A missing map entry means **no evidence** for that dimension (do not invent \(\delta=0\)).

---

## Safe weighted average

$$
\mathrm{WAvg}(z_r; w_r) =
\begin{cases}
\frac{\sum w_r z_r}{\sum w_r} & \text{if } \sum w_r > 0 \\
\mathrm{NA} & \text{otherwise}
\end{cases}
$$

---

## Current uncalibrated weighting (\(a_{ij}=1\))

The future Core Engine supports:

$$
a_{ij} = q_i\, d_{ij}\, e_{ij}
$$

Those parameters are **not** empirically calibrated. P2C-2A-7R1 does **not** invent them.

Uncalibrated v1 launch policy:

$$
a_{ij} = 1
$$

for every valid **explicit** dimension-delta contribution.

Equal weighting is **not** claimed to be empirically optimal.

---

## Dimension scoring (v1)

Over selected responses that contain an explicit finite \(\delta_{ij}\) for dimension \(j\):

$$
z_j = \frac{1}{n_j} \sum \delta_{ij}(o_i)
$$

with \(z_j \in [-1,1]\) and \(n_j =\) evidence count.

Normalized score:

$$
x_j = \frac{z_j + 1}{2} \quad\Rightarrow\quad x_j \in [0,1]
$$

Examples:

| \(z\) | \(x\) |
|------:|------:|
| \(-1.0\) | \(0.0\) |
| \(-0.5\) | \(0.25\) |
| \(0.0\) | \(0.50\) |
| \(+0.5\) | \(0.75\) |
| \(+1.0\) | \(1.0\) |

If \(n_j = 0\): **`insufficient_evidence`**. Do **not** invent \(z_j=0\) or \(x_j=0.5\).

A measured \(x_j=0.50\) is **not** the same as missing evidence.

---

## Future calibrated weighting (documented, not active)

After calibration:

$$
a_{ij} = q_i\, d_{ij}\, e_{ij}
$$

$$
z_j = \mathrm{WAvg}(\delta_{ij}; a_{ij})
$$

$$
x_j = \frac{z_j + 1}{2}
$$

Not activated before calibration; no fake pilot coefficients.

---

## Reliability

```text
calibration_status = uncalibrated
reliability_status = not_calibrated
```

No Cronbach \(\alpha\), \(\omega\), IRT information, or confidence percentages.

Evidence count \(\neq\) reliability.

---

## Consistency / RVI (prepared, not gating)

Pair metadata (`semantic_pair_id`, `reverse_pair_id`) may exist from the pilot registry.

```text
RVI runtime gate = NOT_CALIBRATED / NOT_ACTIVE
```

Consistency must not alter \(x_j\). No production RVI thresholds.

---

## Implementation

* Scorer: `CanonicalEqScorer`
* Math helper: `EqSignedEvidenceMath`
* Banks: `eq_bank_tr_v1.json`, `eq_bank_en_v1.json`
