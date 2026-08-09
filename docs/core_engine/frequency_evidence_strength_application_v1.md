# Frequency Evidence-Strength Application v1

**Status:** provisional (P2A-2D-1)  
**Reuses:** semantic meaning from `docs/core_engine/eq_evidence_strength_contract_v1.md`  
**Scope:** Frequency pilot / review banks only  

---

## 1. Meaning (unchanged from EQ contract)

`evidence_strength` is the **provisional authoring confidence that the option’s observable preference behavior supports the attached `dimension_deltas`**.

It multiplies deltas in TraitScoringService:

```
contribution_j(option) = evidence_strength(option) * delta_j(option)
```

It is **not** psychometric discrimination, clinical confidence, compatibility importance, trait desirability, total L1 magnitude, or persona confidence.

---

## 2. Frequency-specific application rules

| Rule | Requirement |
|---|---|
| Every option | Must set an explicit `evidence_strength` in `[0.40, 0.85]` |
| No flat default | Forbidden to assign one repeated value (e.g. `0.72`) to all options |
| Independence | Must not equal `|delta_primary|`, `max|delta|`, or `L1` by construction |
| Ambiguity | Midpoint / mixed preference options use lower strength (≈0.50–0.55) |
| Clear poles | Clear preference poles use moderate–strong strength (≈0.60–0.75) |
| Item clarity cap | Unclear scenarios should not exceed ≈0.60 on any option |
| Missing response | Strength unused; no invented evidence |
| Sufficiency | Strength does not replace evidence counts / independent contexts |

---

## 3. Provisional Frequency bands

| Band | Range | Typical use |
|---|---|---|
| Weak map confidence | `0.45–0.54` | Mixed / context-heavy options |
| Moderate map confidence | `0.55–0.69` | Clear enough preference map |
| Strong map confidence | `0.70–0.80` | Very clear preference wording |
| Reserved | `> 0.85` | Not used in uncalibrated pilot |

Prefer auditable values: `0.45`, `0.50`, `0.55`, `0.60`, `0.65`, `0.75`.

---

## 4. Calibration

All Frequency strengths are **uncalibrated provisional authoring hypotheses**.
