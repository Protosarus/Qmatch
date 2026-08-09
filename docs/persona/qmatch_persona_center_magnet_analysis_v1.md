# QMatch Persona Center-Magnet Analysis v1

**Phase:** P2C-3A-3
**Source:** `docs/persona/reports/persona_shadow_stress_v1_aggregate.json`
**Seed:** 20260809
**Scorer:** `persona_20d_shadow_distance_v1`

```text
PERSONA_CENTER_MAGNET_RISK = NOTED
shadow_only = true
PERSONA_RUNTIME_READY = false
```

Center magnet = tendency for near-midpoint / center-biased inputs to collapse
onto a small set of Personas with thin Top-2 margins. Telemetry only.

---

## Exact midpoint (x_j = 0.5 ∀ j)

| Field | Value |
|-------|-------|
| primary | `sezgisel` |
| secondary | `bagimsiz` |
| Δ_D | 0.0004654831951182367 |
| distance span | 0.03535326818731061 – 0.053459336009515676 |

Top-5 distances at midpoint: `sezgisel` 0.03535 · `bagimsiz` 0.03582 ·
`vizyoner` 0.03685 · `analist` 0.03854 · `uygulayici` 0.03909.

Margin between #1 and #2 is razor-thin; pack of near-mid distances is tight
(~0.018 span across all 18).

---

## Self-centers

Exact prototype-center inputs (full blueprint evidence):

```text
self_center_failure_count = 0
```

All 18 Personas remain primary at their own centers. Smallest self-center Δ_D
examples: `uygulayici` 0.00286 (secondary `kararli`); `kararli` 0.00313
(secondary `uygulayici`); `muhafiz` 0.00495 (secondary `kararli`).

---

## Midpoint neighborhoods

Perturbations around the exact midpoint (aggregate `midpoint_neighborhood`):

| scale | H_norm | max primary | max share | unreachable | Δ_D p50 |
|-------|--------|-------------|-----------|-------------|---------|
| 0.01 | 0.210090 | `sezgisel` | 0.72 | 15 | 0.000573 |
| 0.03 | 0.369643 | `sezgisel` | 0.4955 | 12 | 0.001142 |
| 0.05 | 0.472371 | `sezgisel` | 0.4035 | 12 | 0.001517 |
| 0.10 | 0.619383 | `sezgisel` | 0.278 | 7 | 0.002132 |

Near the midpoint, mass concentrates on `sezgisel` (with `bagimsiz` as the
persistent runner-up in the exact case). Entropy rises and max share falls as
neighborhood scale increases.

---

## Center-heavy family (n = 15000)

| Metric | Value |
|--------|-------|
| H_norm | 0.517673 |
| max share | `sezgisel` 0.365867 |
| next | `bagimsiz` 0.282333 · `vizyoner` 0.171267 · `uygulayici` 0.114133 |
| unreachable | 10 (family-local) |
| Δ_D p50 | 0.001682 |

Center-biased sampling amplifies the same magnet: `sezgisel` / `bagimsiz` /
`vizyoner` / `uygulayici` dominate; many Personas do not appear as primary in
this family draw.

---

## Interpretation (non-threshold)

* Magnet risk is **noted**, not auto-repaired.
* Overall stress still shows unreachable = 0 and H_norm ≈ 0.92 — magnet is a
  **local / center-biased** phenomenon, not an overall collapse.
* No prototype edits were applied to force midpoint balance.
* Production reveal remains disabled; thin midpoint Δ_D is raw telemetry, not
  a Top-2 product band.
