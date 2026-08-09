# QMatch Canonical 20D Profile Contract v1

**Phase:** P2C-2A-6  
**Schema:** `qmatch_canonical_profile_v1`  
**Registry:** `canonical_dimension_registry_v1`

---

## Dimension taxonomy (authoritative)

Source: `docs/core_engine/canonical_dimension_registry_v1.md`

| Group | Count | IDs |
|-------|-------|-----|
| IQ | 4 | `logical_reasoning`, `pattern_reasoning`, `verbal_reasoning`, `spatial_reasoning` |
| EQ | 10 | `empathy`, `perspective_taking`, `self_awareness`, `emotion_regulation`, `emotional_openness`, `boundary_setting`, `assertiveness`, `conflict_approach`, `repair_orientation`, `social_awareness` |
| Frequency | 6 | `depth_preference`, `social_energy`, `spontaneity`, `stability`, `disclosure_pace`, `communication_pace` |

Total required = **20**.

---

## Measurement semantics

| State | Meaning |
|-------|---------|
| `measured` | Value present in `[0,1]` from a canonical source |
| `not_measured` | Listed only in `missing_dimension_ids` — **no numeric placeholder** |

Forbidden fillers for missing dims: `0`, `0.0`, `0.5`, `50`, midpoint, imputed.

---

## Profile readiness

| Field | After IQ only | After IQ+EQ (R2) |
|-------|----------------|------------------|
| `profile_status` | `partial` | `partial` |
| `canonical_profile_ready` | `false` | `false` |
| `iq_group_status` | `complete` | `complete` |
| `eq_group_status` | `not_started` | `complete` |
| `frequency_group_status` | `not_started` | `incomplete` |
| measured / required | 4 / 20 | 14 / 20 |

Adapters: `iq_to_20d_runtime_adapter_v1`, `eq_to_20d_runtime_adapter_v1`.

| `eq_group_status` | `not_started` |
| `frequency_group_status` | `not_started` |
| `measured_dimension_count` | `4` |
| `required_dimension_count` | `20` |

---

## Reliability

`reliability_status = not_calibrated`  
No fabricated `reliability_estimate` / confidence percentages.

---

## Persistence

`users/{uid}/profiles/canonical_v1`

Does not overwrite legacy `iq_score` or invent EQ/Frequency values.
