# QMatch Frequency Authored Separator + Quality Items v1

**Phase:** P2C-2A-8R1A
**Date:** 2026-08-09

```text
These eight items are product/measurement hypotheses, not empirically validated psychometric items.
```

Status for all eight:

```text
source = QMatch provisional authoring
calibration = uncalibrated
validation status = pilot required
not psychometrically validated
```

---

## Separator contract (R1A refinement)

```text
item_role = separator
separator_type = dimension_boundary
separator_dimensions = [canonical Frequency IDs]  # length >= 2
separator_persona_targets = []                    # empty is valid; Persona runtime not implemented
```

Do **not** invent Persona targets (`guardian`, `communicator`, `sage`, …).

Separators **are** trait evidence under `frequency_6d_uncalibrated_signed_evidence_v1`
with \(a_{ij}=1\) (no special weight).

---

## 1. `freq_separator_depth_comm_v1`

| Field | Value |
|-------|-------|
| Role | separator |
| Purpose | Dimension-boundary trade-off: depth vs communication pace |
| Dimensions | `depth_preference`, `communication_pace` |
| Format | forced_choice |

Deltas:

| option | depth_preference | communication_pace |
|--------|-----------------:|-------------------:|
| opt_a | -0.45 | +0.70 |
| opt_b | +0.75 | -0.45 |
| opt_c | +0.35 | +0.25 |
| opt_d | -0.55 | -0.35 |

TR/EN source: QMatch provisional authoring (this phase).

---

## 2. `freq_separator_social_stability_v1`

| Field | Value |
|-------|-------|
| Role | separator |
| Purpose | Dimension-boundary: social energy vs stability |
| Dimensions | `social_energy`, `stability` |

| option | social_energy | stability |
|--------|-------------:|----------:|
| opt_a | +0.75 | -0.15 |
| opt_b | +0.10 | +0.65 |
| opt_c | +0.20 | -0.55 |
| opt_d | -0.70 | +0.15 |

---

## 3. `freq_separator_spontaneity_stability_v1`

Dimensions: `spontaneity`, `stability`

| option | spontaneity | stability |
|--------|------------:|----------:|
| opt_a | -0.75 | +0.75 |
| opt_b | -0.25 | +0.45 |
| opt_c | +0.45 | -0.25 |
| opt_d | +0.80 | -0.65 |

---

## 4. `freq_separator_disclosure_depth_v1`

Dimensions: `disclosure_pace`, `depth_preference`

| option | disclosure_pace | depth_preference |
|--------|----------------:|-----------------:|
| opt_a | +0.75 | +0.45 |
| opt_b | +0.25 | +0.55 |
| opt_c | -0.55 | +0.20 |
| opt_d | -0.75 | -0.45 |

---

## 5. `freq_separator_comm_stability_v1`

Dimensions: `communication_pace`, `stability`

| option | communication_pace | stability |
|--------|-------------------:|----------:|
| opt_a | +0.35 | +0.65 |
| opt_b | -0.10 | -0.25 |
| opt_c | +0.55 | +0.45 |
| opt_d | -0.65 | +0.10 |

---

## 6. `freq_separator_social_disclosure_v1`

Dimensions: `social_energy`, `disclosure_pace`

| option | social_energy | disclosure_pace |
|--------|-------------:|----------------:|
| opt_a | +0.75 | -0.45 |
| opt_b | -0.15 | +0.35 |
| opt_c | +0.45 | +0.25 |
| opt_d | -0.55 | -0.15 |

---

## Quality-only contract

```text
item_role = response_quality
trait_scoring = false
dimension_deltas = {}
rvi_runtime_gate = false
protocol_signal_only
RVI_NOT_ACTIVE
```

Must **not** change Frequency \(z_j\) / \(x_j\) / `evidence_count`, IQ, EQ, Persona, or block completion.

---

## 7. `freq_quality_instruction_v1`

| Field | Value |
|-------|-------|
| Role | response_quality |
| Purpose | Instruction-attention protocol check |
| quality_type | instruction_attention |
| expected_protocol_option_id | opt_b |
| deltas | empty on all options |

---

## 8. `freq_quality_protocol_v1`

| Field | Value |
|-------|-------|
| Role | response_quality |
| Purpose | Protocol-attention check |
| quality_type | protocol_attention |
| expected_protocol_option_id | opt_c |
| deltas | empty on all options |

If expected option is not selected: record internal `attention_check_passed = false` only (not implemented as a live gate in R1A).
