# Frequency V2 evidence metadata v1 contract

**Status:** schema-only — no option scores assigned  
**evidence_meta.version:** `frequency_evidence_prior_v1`  
**calibration_status:** `uncalibrated`  
**Applies to:** dormant Frequency behavioral V2 pool only

This contract does **not** replace the 12D `behavioral_weights`. It does **not** write Frequency V1 6D slots. It does **not** define a 12D→6D map. It does **not** activate V2.

Live routing remains `frequency_bank_*_v1`.

---

## 1. What evidence metadata is

Evidence scores describe **how confidently an observed answer should be interpreted**.

They are **relative to the other three options in the same question**.

They are not:

- personality scores
- moral values
- truth / lie probabilities
- clinical measurements
- rarity, popularity, or future selection rate
- `discrimination_power` (learned later from usage data)
- response time

`behavioral_weights` remain the behavioral meaning of the selected option. Evidence metadata is structurally independent of those weights.

---

## 2. Six fields

| Field | Meaning |
|---|---|
| `social_desirability` | Socially approved / ideal-self advantage relative to sibling options |
| `obviousness` | How transparent the projected test image is (test transparency, not how common the behavior is) |
| `behavioral_plausibility` | How natural / credible the option is as ordinary behavior in the scenario |
| `self_presentation_risk` | How easy it is to pick the option mainly to look good (not deception) |
| `diagnostic_value` | How informative the option is, if selected sincerely, for the intended axis vs siblings |
| `ambiguity` | How many distinct behavioral readings the same selection could support |

### social_desirability

| Value | Anchor |
|---:|---|
| 0.00 | Almost no socially approved / ideal-self advantage relative to sibling options |
| 0.25 | Slightly more socially attractive |
| 0.50 | Moderate social desirability |
| 0.75 | Clearly presents the respondent in a socially favorable way |
| 1.00 | Strongly resembles an idealized / socially approved answer relative to the other options |

High `social_desirability` does **not** mean the answer is false.

### obviousness

| Value | Anchor |
|---:|---|
| 0.00 | Very difficult to infer which behavioral image the test designer might prefer |
| 0.25 | Weak cue |
| 0.50 | Moderately interpretable |
| 0.75 | Fairly obvious what image the option projects |
| 1.00 | The intended desirable / test-friendly interpretation is extremely obvious |

This is about **test transparency**, not whether the behavior itself is common.

### behavioral_plausibility

| Value | Anchor |
|---:|---|
| 0.00 | Highly artificial, implausible, caricature-like, or unlikely as ordinary behavior |
| 0.25 | Possible but unusual / awkwardly written |
| 0.50 | Reasonably plausible |
| 0.75 | Very believable ordinary behavior |
| 1.00 | Extremely natural and behaviorally credible in the scenario |

Rare behavior can still be highly plausible. Plausibility is independent of the other five fields.

### self_presentation_risk

| Value | Anchor |
|---:|---|
| 0.00 | Little reason to choose this mainly to look good |
| 0.25 | Minor image-management possibility |
| 0.50 | Moderate possibility |
| 0.75 | Strong opportunity for ideal-self presentation |
| 1.00 | Very easy to select primarily because it creates a desirable self-image |

Do **not** infer deception.

### diagnostic_value

| Value | Anchor |
|---:|---|
| 0.00 | Little useful differentiation even if selected sincerely |
| 0.25 | Weak differentiation |
| 0.50 | Moderately informative |
| 0.75 | Strong behavioral contrast |
| 1.00 | Very informative relative to sibling options for distinguishing the intended behavioral axis |

Do **not** define `diagnostic_value` from rarity. Do **not** use future selection rate. This is an uncalibrated reviewer prior.

### ambiguity

| Value | Anchor |
|---:|---|
| 0.00 | Almost one clear behavioral interpretation |
| 0.25 | Small secondary interpretation possible |
| 0.50 | Meaning is somewhat mixed |
| 0.75 | Multiple plausible behavioral interpretations |
| 1.00 | Selection cannot be cleanly interpreted without substantial uncertainty |

---

## 3. Allowed values

Once a numeric field is present it must be exactly one of:

`0.00` · `0.25` · `0.50` · `0.75` · `1.00`

No arbitrary decimals. No values outside `[0, 1]`.

---

## 4. Data shape

```text
evidence_meta:
  version: frequency_evidence_prior_v1
  calibration_status: uncalibrated
  review_status: pending
  social_desirability: null
  obviousness: null
  behavioral_plausibility: null
  self_presentation_risk: null
  diagnostic_value: null
  ambiguity: null
```

`review_status` is the dormant pending/reviewed marker. Phase 2A keeps every option at `pending` with all six scores `null`.

When a later phase marks an option `reviewed`, **all six numeric fields must be present together**, each on the allowed grid. Partial reviewed metadata is invalid.

Current authored priors, once filled, remain **`calibration_status: uncalibrated`** until a later empirical calibration pass. `discrimination_power` is not authored here.

Legacy placeholder key `directness` is **not** part of this contract.

---

## 5. High-level principles

1. Socially desirable ≠ false
2. Unpopular ≠ diagnostic
3. Common ≠ useless
4. Extreme ≠ informative
5. Behavioral plausibility must be considered independently
6. Inconsistency will later affect confidence, not create a liar label
7. Empirical calibration will later revise these priors
8. Current evidence values will be explicitly marked **UNCALIBRATED**
9. `discrimination_power` is **not** authored here; it will be learned from usage data later
10. Response time is **not** part of authored evidence metadata

Forbidden inference labels: `truth_score`, `lie_score`, `deception_score`, `honesty_score`.

---

## 6. Validation

- Draft / dormant: all-null + `review_status=pending` is valid (DROP / unresolved).
- Draft / dormant: complete six-field `review_status=reviewed` on the allowed grid is valid (selectable authored priors).
- Any present numeric value must be one of the five allowed grid values.
- `review_status=reviewed` requires all six fields non-null.
- Mixed (some null, some numeric) is rejected.
- Pending with any numeric value is rejected.
- Behavioral weights are not derived from evidence metadata, and evidence metadata is not derived from weight mass.

Production-ready pool validation still rejects unresolved evidence. V2 remains `runtime_selectable=false` until an explicit later activation.

---

## 7. What this phase does not do

- Does not score the 1,704 options
- Does not activate V2
- Does not modify Frequency V1 banks or live locale routing
- Does not modify Discover, Persona, matching, `canonical_v1`, C2, or Firebase
