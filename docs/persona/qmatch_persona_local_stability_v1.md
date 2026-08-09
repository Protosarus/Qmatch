# QMatch Persona Local Stability v1

**Phase:** P2C-3A-3
**Source:** `docs/persona/reports/persona_shadow_stress_v1_aggregate.json`
**Seed:** 20260809
**Scorer:** `persona_20d_shadow_distance_v1`

Local stability = fraction of prototype-neighborhood perturbations that keep
the same primary (and stay in Top-2) under shadow distance. Telemetry only;
no invented stability pass/fail threshold.

```text
shadow_only = true
PERSONA_RUNTIME_READY = false
```

---

## Prototype-neighborhood local stability

Aggregate key `local_stability` (n = 720 draws per ε):

| ε | fraction_same_primary | fraction_in_top2 | Δ_D p50 | Δ_D p95 | most_common_competitor |
|---|----------------------:|-----------------:|---------|---------|------------------------|
| 0.01 | 1.0 | 1.0 | 0.009069828511425427 | 0.029618612022086512 | `yargic` |
| 0.03 | 1.0 | 1.0 | 0.009070113862185111 | 0.02812893853475737 | `yargic` |
| 0.05 | 1.0 | 1.0 | 0.009132039485757446 | 0.026954812364642186 | `yargic` |
| 0.10 | 0.9972222222222222 | 1.0 | 0.009344763005742572 | 0.025659373637020023 | `yargic` |

At ε ≤ 0.05, every draw kept the same primary. At ε = 0.10, same-primary held
for 0.99722 of draws; Top-2 containment remained 1.0.

---

## Related family: prototype_neighborhood (n = 18000)

| Metric | Value |
|--------|-------|
| H_norm | 0.9999984430858282 |
| max share | `kararli` 0.05605555555555555 |
| unreachable | 0 |
| Δ_D p50 | 0.009321124602006311 |
| self_secondary_count | 0 |

Per-prototype neighborhood sampling remains near-uniform in primary share by
construction of balanced per-persona draws.

---

## Self-centers (stability at exact centers)

```text
self_center_failure_count = 0
```

Each of the 18 prototype centers ranks itself primary. See
`qmatch_persona_center_magnet_analysis_v1.md` for Δ_D at centers.

---

## Status

```text
local_stability = TELEMETRY_RECORDED
prototypes = provisional / synthetic_validation_only
production Persona reveal = NOT_STARTED
```
