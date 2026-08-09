# QMatch Persona Scoring Math Contract v1

**Phase:** P2C-3A-1  
**Authority for this phase:** Core Engine v2 Persona math (supersedes older Persona docs on conflict)  
**Repo offline implementation:** `PersonaScoringService` + `persona_scoring_config_v2.json` (provisional)

```text
status = CONTRACT_AUDIT
production_scoring = NOT_AUTHORIZED
```

This document records the **canonical formulas** and whether repository values are
resolved. It does **not** invent missing constants.

---

## 1. Group weights (READY)

Applied **after** each group's normalized distance:

```text
G_IQ = 0.15
G_EQ = 0.30
G_F  = 0.55
```

```math
G_{IQ} + G_{EQ} + G_{F} = 1
```

Do **not** multiply `G_g` into every dimension before within-group aggregation
(that distorts groups with different dimension counts).

**Repo:** `persona_scoring_config_v2.json` / v2 profiles match `0.15 / 0.3 / 0.55`.  
**Obsolete:** v1 `0.10 / 0.55 / 0.35`. Do not use historical `0.15 / 0.50 / 0.35`.

---

## 2. Safe weighted average (READY as rule)

```math
\mathrm{WAvg}(z_r;\omega_r)=\frac{\sum \omega_r z_r}{\sum \omega_r}
\quad\text{only if}\quad \sum\omega_r>0
```

Otherwise: `insufficient_evidence` / NA. Never invent zero for a zero denominator.

---

## 3. Evidence sufficiency (BLOCKED for Persona use)

Core Engine:

```math
E_j=\min\bigl(1,\, n_j / n_j^{\min}\bigr)
```

**Repo facts:**

* `trait_scoring_config_v1.json` defines per-dimension `minimum_primary_evidence` (and a **provisional** alternate sufficiency curve)
* Live 20D profile stores measurement completeness separately from calibrated sufficiency
* Offline Persona service expects explicit `dimensionEvidenceSufficiency` or uses deprecated `min(1, count/3)`

**Status:** **BLOCKED_PERSONA_MINIMUM_EVIDENCE_POLICY**  
Do not set `E_j=1` merely because `canonical_profile_ready=true`.

---

## 4. Reliability / quality weight (BLOCKED)

```math
q_j = R_j E_j
```

Live modules report `reliability_status = not_calibrated`.

**Forbidden inventions:** `R_j=1`, `R_j=0.5`, `R_j=evidence_count`, `R_j=completion_status`.

**Repo fact:** `PersonaScoringService` defaults omitted reliability to `1.0` — **not** an approved production fallback.

**Status:** **BLOCKED_PERSONA_RELIABILITY_POLICY**

---

## 5. User profile shape (formula READY; inputs blocked)

For available group `g`:

```math
\mu_{x,g}=\mathrm{WAvg}(x_j; q_j)_{j\in J_g}
```

```math
s_j = x_j - \mu_{x,g(j)}
```

Do not compute with fabricated `q_j`.

---

## 6. Persona target shape (formula READY; uses provisional w,t)

```math
\mu_{t,p,g}=\mathrm{WAvg}(t_{p,j}; w_{p,j})_{j\in J_g}
```

```math
s_{p,j}=t_{p,j}-\mu_{t,p,g(j)}
```

Structural `t_{p,j}`, `w_{p,j}` exist in v2 for all 18 (provisional / synthetic_validation_only).

---

## 7. Group level distance (formula READY; inputs blocked)

```math
D_{\mathrm{level},g,p}=
\mathrm{WAvg}\bigl((x_j-t_{p,j})^2;\, R_j E_j w_{p,j}\bigr)_{j\in J_g}
```

Not raw unweighted Euclidean unless a later explicit uncalibrated policy says so.

---

## 8. Group shape distance (formula READY; inputs blocked)

```math
D_{\mathrm{shape},g,p}=
\mathrm{WAvg}\bigl((s_j-s_{p,j})^2;\, R_j E_j w_{p,j}\bigr)_{j\in J_g}
```

---

## 9. Frequency-first group combination (READY weights)

```math
D_{\mathrm{level},p}=\frac{\sum_g G_g D_{\mathrm{level},g,p}}{\sum_g G_g}
```

```math
D_{\mathrm{shape},p}=\frac{\sum_g G_g D_{\mathrm{shape},g,p}}{\sum_g G_g}
```

For a complete 20D profile all three groups are expected available.

---

## 10. Level / shape alpha (PROVISIONAL_CONFIG)

```math
D_{\mathrm{core},p}=\alpha D_{\mathrm{level},p}+(1-\alpha)D_{\mathrm{shape},p}
```

```text
α = 0.65   # PROVISIONAL_CONFIG (matches repo level_distance_weight)
```

Not scientifically calibrated.

---

## 11. Anti-trait contract (formula READY; rules provisional in v2)

```math
\nu_{p,r}=\mathrm{clip}\bigl(\sigma_r (x_{j_r}-\theta_r),\,0,\,1\bigr)
```

```math
A_p=\mathrm{WAvg}(\nu_{p,r};\, h_r R_{j_r} E_{j_r})
```

If no rules: `A_p=0`.  
v2 contains provisional anti-trait rules for all 18. **No new thresholds authored in this phase.**

---

## 12. Persona-specific minimum-evidence penalty (formula READY)

```math
\omega_{p,j}=\max\bigl(0,\, e^{\min}_{p,j}-E_j\bigr)
```

```math
\Omega_p=\mathrm{WAvg}(\omega_{p,j};\, w^{\min}_{p,j})
```

If no explicit critical rules: `Ω_p=0`.  
v2 has provisional critical-dimension floors. Do not invent new ones here.

---

## 13. Total Persona distance (CONFLICTED coefficients)

### Core Engine v2 (this phase — authoritative on conflict)

Provisional coefficients:

```text
γ_A = 0.10
γ_Ω = 0.05
```

```math
D_p=\mathrm{clip}\bigl(
(1-\gamma_A-\gamma_\Omega) D_{\mathrm{core},p}
+\gamma_A A_p
+\gamma_\Omega \Omega_p
,\,0,\,1\bigr)
```

### Repo provisional config (offline library)

```text
anti_trait_penalty_weight (γ) = 0.12
missing_evidence_penalty_weight (δ) = 0.18
```

Implemented approximately as additive `D_base + γ A + δ M` (see service report / blueprint).

**Status:** **CONFLICTED** — do not silently pick either set for production without an explicit reconciliation phase.

---

## 14. Primary / secondary / distance margin (READY as rule)

```math
p_1=\arg\min_p D_p
```

```math
p_2=\arg\min_{p\neq p_1} D_p
```

```math
\Delta_D = D_{p_2}-D_{p_1}\ge 0
```

`tie_break_rank` only for exact equality. No randomness.

**This phase:** do **not** implement live ranking.

---

## 15. Temperature / affinity (BLOCKED)

```math
a_p=\exp(-D_p / T),\qquad \pi_p=a_p/\sum_q a_q
```

```text
temperature_status = UNRESOLVED_CANONICAL_CONFIG
```

Repo provisional `similarity_temperature=0.22` is **not** adopted as canonical.

→ **BLOCKED_PERSONA_TEMPERATURE_CONFIG** for production affinity.

`π_p` is **normalized affinity**, never a scientific probability of “being” Persona p.

---

## 16. Top-2 thresholds (BLOCKED)

```text
Top-2 margin thresholds = UNDETERMINED
```

Repo provisional `top2_margin_threshold=0.035` is **not** canonical.

→ **BLOCKED_PERSONA_TOP2_THRESHOLD_POLICY**

---

## 17. Confidence (NOT_READY)

```text
Persona confidence = NOT_READY_FOR_PRODUCTION
```

Depends on fit, separation, evidence, consistency, RVI, reliability — none fully calibrated.

---

## Scientific boundary

Persona is a **narrative prototype layer** over a continuous uncalibrated 20D measurement profile.
It is not a clinical diagnosis, not a calibrated psychometric type, and not a matching key.
