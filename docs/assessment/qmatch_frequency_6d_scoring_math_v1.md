# QMatch Frequency 6D Scoring Mathematics v1

**Phase:** P2C-2A-8R1  
**Policy:** `frequency_6d_uncalibrated_signed_evidence_v1`  
**Status:** Uncalibrated launch contract (not psychometrically validated)

---

## Scientific status

This is an **uncalibrated multidimensional relational-rhythm / behavioral-preference profile**.

It is **not**:

* a clinical diagnosis
* a psychological certification
* a population percentile test
* a validated medical instrument

Frequency has **no correct / wrong answers**. Responses are preference/behavior evidence.

---

## Taxonomy

Exactly these 6 language-independent IDs:

```text
depth_preference
social_energy
spontaneity
stability
disclosure_pace
communication_pace
```

Do **not** use historical aliases (`depth`, `socialEnergy`, `emotionalOpenness`,
`conversationPace`, `openingRhythm`, `communicationTempo`, `communication_tempo`)
as canonical identity.

Frequency trait scoring must produce **only** these six dimensions unless a later
explicit registry proves cross-group evidence is intended.

---

## Signed option evidence

For item \(i\), selected option \(o_i\), dimension \(j\):

$$
\delta_{ij}(o_i) \in [-1,1]
$$

| Value | Meaning |
|------:|---------|
| \(-1\) | strong evidence toward the low pole |
| \(0\) | neutral directional evidence **when explicitly present** |
| \(+1\) | strong evidence toward the high pole |

A missing map entry means **no evidence** for that dimension (do not invent \(\delta=0\) for evidence-count purposes).

A selected response **may** contribute to multiple canonical Frequency dimensions.

---

## Current uncalibrated weighting (\(a_{ij}=1\))

The future Core Engine supports weighted evidence:

$$
a_{ij} = q_i\, d_{ij}\, e_{ij}
$$

Those coefficients are **not** empirically calibrated. P2C-2A-8R1 does **not** invent them.

Uncalibrated v1 policy:

$$
a_{ij} = 1
$$

for every valid **explicit** canonical Frequency dimension contribution.

Equal weighting is **not** claimed to be empirically optimal.

---

## Dimension scoring (v1)

Let \(I_j\) be selected responses with an explicit valid delta for dimension \(j\),
and \(n_j = |I_j|\).

$$
z_j = \frac{1}{n_j} \sum_{i \in I_j} \delta_{ij}(o_i)
$$

with \(z_j \in [-1,1]\).

Normalized canonical Frequency score:

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

A measured midpoint \(x_j=0.50\) is **not** the same as missing evidence.

`evidence_count = n_j` counts only selected responses with a valid explicit delta for \(j\).

---

## Reverse-scored metadata

Canonical runtime scoring consumes the **final** explicit signed `dimension_deltas`.

Do **not** invert an already-signed delta a second time because `reverse_scored` is true.

```text
explicit signed dimension_deltas = scoring truth
```

`reverse_scored` may remain as authoring / consistency / validator metadata only.

Do **not** invent Likert position → δ maps without a frozen repository contract.

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

## Consistency mathematics (prepare only)

For related items \(i,k\) on comparable dimension \(j\), future alignment supports
\(b_{ik,j} \in \{-1,+1\}\), aligned evidence \(v^*_{k,j} = b_{ik,j} v_{k,j}\),
pair inconsistency \(I_{ik}\), consistency \(Q_{ik}=1-I_{ik}\).

Preserve existing pair / isomorph metadata where present.

Do **not** activate consistency/RVI gating in R1. Do **not** alter \(x_j\) from consistency.

---

## Reliability / RVI

```text
calibration_status = uncalibrated
reliability_status = not_calibrated
RVI = NOT_CALIBRATED / NOT_ACTIVE
```

No Cronbach \(\alpha\), \(\omega\), IRT information, confidence percentages, or honesty labels.

Evidence count \(\neq\) reliability.

---

## Implementation

* Scorer: `CanonicalFrequencyScorer`
* Math helper: `FrequencySignedEvidenceMath`
* Policy: `frequency_6d_uncalibrated_signed_evidence_v1`
* Runtime-candidate banks: **blocked** pending separator + quality-only coverage
* Math fixture (tests only): `test/fixtures/frequency/frequency_math_fixture_v1.json`
