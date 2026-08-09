# QMatch Persona Large-Scale Shadow Stress Simulation v1

**Phase:** P2C-3A-3
**Tool:** `tool/persona_shadow_stress_v1.dart`
**Aggregate:** `docs/persona/reports/persona_shadow_stress_v1_aggregate.json`
**Date:** 2026-08-09

```text
seed = 20260809
generator_version = persona_shadow_stress_generator_v1
scoring_version = persona_20d_shadow_distance_v1
prototype_version = persona_profiles_v2_20d.0
policy_version = persona_shadow_evidence_only_v1
config_version = persona_shadow_scoring_config_v1
overall_n = 100000
determinism_ok = true
tr_en_numeric_invariance = true
shadow_only = true
production_reveal = disabled
PERSONA_RUNTIME_READY = false
```

Offline stress of the canonical shadow distance scorer across synthetic input
families. Numbers below are taken from the aggregate JSON. No scientific
pass/fail thresholds are invented; values are telemetry only.

---

## Sample plan

| Family | n |
|--------|---|
| uniform | 22000 |
| center_heavy | 15000 |
| moderate_center | 15000 |
| extreme | 15000 |
| correlated | 15000 |
| prototype_neighborhood | 18000 |
| **overall** | **100000** |

---

## Overall primary distribution (n = 100000)

| Metric | Value |
|--------|-------|
| H_norm | 0.9234894964343604 |
| max share | `bagimsiz` 0.14761 |
| unreachable (overall) | 0 |
| self_secondary_count | 0 |
| Δ_D p50 | 0.005330048317121937 |
| Δ_D p95 | 0.02485212415150484 |
| Δ_D mean | 0.00803700144750086 |

Primary share order (high → low): `bagimsiz` 0.14761 · `sezgisel` 0.11498 ·
`uygulayici` 0.09795 · `cesur` 0.09358 · `vizyoner` 0.09195 · `analist` 0.07039 ·
`yaratici` 0.06406 · `koruyucu` 0.04919 · `iletisimci` 0.04693 · `empat` 0.03846 ·
`lider` 0.03463 · `bilge` 0.02770 · `sifaci` 0.02668 · `donusturucu` 0.02525 ·
`muhafiz` 0.02163 · `kararli` 0.01913 · `yargic` 0.01560 · `stratejist` 0.01428.

---

## Family telemetry

| Family | H_norm | max primary | max share | unreachable | Δ_D p50 |
|--------|--------|-------------|-----------|-------------|---------|
| uniform | 0.933241 | `cesur` | 0.125045 | 0 | 0.006501 |
| center_heavy | 0.517673 | `sezgisel` | 0.365867 | 10 | 0.001682 |
| moderate_center | 0.779852 | `uygulayici` | 0.1754 | 0 | 0.003360 |
| extreme | 0.952476 | `cesur` | 0.112667 | 0 | 0.009269 |
| correlated | 0.769918 | `bagimsiz` | 0.2274 | 3 | 0.005397 |
| prototype_neighborhood | 0.999998 | `kararli` | 0.056056 | 0 | 0.009321 |

`center_heavy` unreachable in this draw:
`bilge`, `lider`, `muhafiz`, `sifaci`, `yargic`, `kararli`, `yaratici`,
`iletisimci`, `donusturucu`, `stratejist`.

`correlated` unreachable in this draw: `bilge`, `muhafiz`, `kararli`.

Family-local unreachable counts are expected under center-biased / correlated
sampling; they are **not** overall reachability failures (overall unreachable = 0;
self-centers all OK — see center-magnet / reachability docs).

---

## Anchors

| Case | primary | secondary | Δ_D |
|------|---------|-----------|-----|
| midpoint exact (x_j = 0.5) | `sezgisel` | `bagimsiz` | 0.0004654831951182367 |
| all_high | `iletisimci` | `donusturucu` | 0.004516941031174337 |
| all_low | `bagimsiz` | `analist` | 0.023241775574773776 |
| self_center_failure_count | — | — | **0** |

Closest prototype pair (diagnostic separation): `uygulayici` / `kararli`
(0.0036374844919254204). See collision-matrix doc.

---

## Scientific status

```text
Persona prototypes = provisional / synthetic_validation_only
Persona shadow scoring = uncalibrated
temperature_applied = false
affinity_not_computed = true
confidence_not_computed = true
Top-2 thresholds = unresolved / unused
live Firestore persona writer = NOT_STARTED
production Persona reveal = NOT_STARTED
Matching/QRCF via Persona = FORBIDDEN for now
```
