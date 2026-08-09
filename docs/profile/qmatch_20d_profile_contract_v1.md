# QMatch Canonical 20D Profile Contract v1

**Phase:** P2C-2A-8R2
**Schema:** `qmatch_canonical_profile_v1`  
**Registry:** `canonical_dimension_registry_v1`

---

## Dimension taxonomy (authoritative)

| Group | Count | IDs |
|-------|-------|-----|
| IQ | 4 | `logical_reasoning`, `pattern_reasoning`, `verbal_reasoning`, `spatial_reasoning` |
| EQ | 10 | `empathy`, `perspective_taking`, `self_awareness`, `emotion_regulation`, `emotional_openness`, `boundary_setting`, `assertiveness`, `conflict_approach`, `repair_orientation`, `social_awareness` |
| Frequency | 6 | `depth_preference`, `social_energy`, `spontaneity`, `stability`, `disclosure_pace`, `communication_pace` |

Total required = **20**.

---

## Profile readiness

| Field | After IQ | After IQ+EQ | After IQ+EQ+Frequency |
|-------|----------|-------------|------------------------|
| `profile_status` | partial | partial | **complete** |
| `canonical_profile_ready` | false | false | **true** |
| measured / required | 4 / 20 | 14 / 20 | **20 / 20** |

Readiness requires the exact registry ID set (not mere count==20).

Adapters: `iq_to_20d_runtime_adapter_v1`, `eq_to_20d_runtime_adapter_v1`, `frequency_to_20d_runtime_adapter_v1`.

---

## Reliability

`reliability_status = not_calibrated`  
Full 20D readiness ≠ psychometric calibration.

---

## Persistence

`users/{uid}/profiles/canonical_v1`

Does not authorize Persona / Matching / quantum merely because `canonical_profile_ready=true`.
