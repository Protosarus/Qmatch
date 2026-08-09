# QMatch Persona Synthetic Simulation v1

**Phase:** P2C-3A-2
**Tool:** `tool/persona_shadow_simulate_v1.dart`
**Seed:** 42 · neighborhood ±0.12 · 200 draws / persona · full evidence

```text
no_quota = true
no_forced_distribution = true
temperature_applied = false
affinity_not_computed = true
```

## Center-magnet (x_j = 0.5 ∀ j)

| Field | Value |
|-------|-------|
| primary | `sezgisel` |
| secondary | `bagimsiz` |
| Δ_D | ≈ 0.00047 |
| distance span | ≈ 0.035 – 0.053 |

```text
PERSONA_CENTER_MAGNET_RISK = NOTED
```

Midpoint distances are tightly packed with a razor-thin Top-2 margin.
No prototype edits were applied to force balance.

## Neighborhood distribution (n = 3600)

Each prototype neighborhood produced **200** primary hits for its Persona
(exact equal by construction of per-persona sampling). Secondaries vary;
some Personas (`bilge`, `iletisimci`, `bagimsiz`) rarely appear as secondary
in this draw — not a reachability failure.

Margin summary: min ≈ 0.0005 · p50 ≈ 0.009 · max ≈ 0.039
(raw telemetry only; no threshold bands).

## Scientific status

```text
Persona prototypes = provisional
Persona shadow scoring = uncalibrated
Dimension reliability = not_calibrated
Reliability factor = not applied
Evidence sufficiency = blueprint-based provisional policy
Temperature = unresolved / unused
Affinity = not computed
Top-2 thresholds = unresolved
Confidence = not computed
Production Persona reveal = disabled
```
