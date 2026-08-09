# QMatch Persona Shadow Input Policy v1

**Phase:** P2C-3A-2
**Status:** RESOLVED_FOR_SHADOW_ONLY
**Quality policy:** `persona_shadow_evidence_only_v1`
**Scoring version:** `persona_20d_shadow_distance_v1`

```text
production Persona reveal = NOT_STARTED
live Firestore Persona write = NOT_STARTED
```

---

## Reliability (shadow)

```text
reliability_status = not_calibrated
reliability_factor_applied = false
shadow_quality_policy = persona_shadow_evidence_only_v1
```

```math
q_j^{(\mathrm{shadow})} = E_j
```

**Forbidden:** inventing `R_j ∈ {1, 0.5, evidence_count, completion}`.

Future calibrated Core Engine remains:

```math
q_j = R_j E_j
```

---

## Evidence sufficiency

```math
E_j = \min(1,\, n_j / n_j^{\min})
```

Frozen `n_j^{\min}` (blueprint-based provisional):

| Group | Dimensions | n_min |
|-------|------------|-------|
| IQ | logical_reasoning | 7 |
| IQ | pattern_reasoning, verbal_reasoning, spatial_reasoning | 6 |
| EQ | all 10 EQ dims | 3 |
| Frequency | all 6 Frequency dims | 5 |

`E_j = 1` only when counts meet/exceed `n_min` for that dimension.

`canonical_profile_ready=true` alone does **not** imply `E_j=1`.

Source-less / incomplete / missing-policy profiles are **not** shadow-eligible.

---

## Group weights

```text
G_IQ = 0.15
G_EQ = 0.30
G_F  = 0.55
```

Applied **after** within-group distances.

---

## Distance coefficients (conflict resolved)

```text
α = 0.65          # provisional_config
γ_A = 0.10
γ_Ω = 0.05
```

```math
D_p = \mathrm{clip}(0.85 D_{\mathrm{core},p} + 0.10 A_p + 0.05 \Omega_p,\,0,\,1)
```

Older repo additive `0.12 / 0.18` is **not** active for shadow scoring.

---

## Explicitly unused

```text
temperature_status = unresolved
temperature_applied = false
affinity_status = not_computed
top2_threshold_status = unresolved
top2_margin_band = not_computed
confidence_status = not_calibrated
confidence_value = absent
```

Raw `Δ_D` is recorded only.
