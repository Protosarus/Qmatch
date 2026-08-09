# QMatch Persona Shadow Scoring Contract v1

**Phase:** P2C-3A-2
**Scorer:** `CanonicalPersonaShadowScorer`
**Config:** `assets/data/persona_shadow_scoring_config_v1.json`
**Prototypes:** `assets/data/persona_profiles_v2_20d.json` (never v1)

```text
shadow_only = true
```

## Pipeline

1. Validate source evidence (owner, IQ+EQ+Frequency complete, policy + bank/session versions, 20 scores, evidence counts).
2. Compute `E_j = min(1, n_j / n_min)`.
3. User group means with weights `E_j`; shapes `s_j = x_j - μ_{x,g}`.
4. Persona means with weights `w_{p,j}`; shapes `s_{p,j}`.
5. Group level/shape distances with weights `E_j w_{p,j}`.
6. Combine groups: `0.15 IQ + 0.30 EQ + 0.55 F`.
7. `D_core = 0.65 D_level + 0.35 D_shape`.
8. Anti-trait `A` from existing v2 rules, weighted by `h_r E_{j_r}` (no R).
9. Ω from existing v2 critical floors mapped to sufficiency via `e_min = min(1, crit_count / n_min)`.
10. `D = clip(0.85 D_core + 0.10 A + 0.05 Ω, 0, 1)`.
11. Primary/secondary = argmin distances; ties → `tie_break_rank` then persona_id.
12. Record raw `Δ_D ≥ 0`.

## Non-goals

* No `exp(-D/T)`, no `π_p`, no percentages
* No confidence bands / Top-2 threshold bands
* No Firestore `assessments/persona` writes
* No UI reveal / Matching / QRCF / quantum

## Output metadata

```text
scoring_version = persona_20d_shadow_distance_v1
policy_version = persona_shadow_evidence_only_v1
reliability_factor_applied = false
temperature_applied = false
affinity_not_computed = true
confidence_not_computed = true
shadow_only = true
```
