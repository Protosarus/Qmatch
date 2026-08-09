# EQ Evidence Strength Contract v1

**Status:** provisional authoring contract (P2A-2C-2)  
**Applies to:** EQ scenario_mcq options in pilot / review-candidate banks  
**Does not claim:** psychometric discrimination, IRT information, or clinical validity  

---

## 1. Single semantic meaning

`evidence_strength` is the **provisional authoring confidence that the option’s observable behavior supports the attached `dimension_deltas` (and counter-evidence)**.

It answers: *“How clearly does this option’s wording justify the evidence map we attached?”*

It is **not**:

- the size of a dimension delta,
- total L1 magnitude,
- item clarity alone,
- response discriminativeness from participant data,
- reliability,
- evidence count,
- a moral weight,
- a correctness weight.

---

## 2. Valid range

| Bound | Value |
|---|---|
| Minimum usable (pilot) | `0.40` |
| Maximum (uncalibrated pilot) | `0.85` |
| Absolute schema clamp in TraitScoringService | `[0.0, 1.0]` |
| Missing / omitted in JSON | parser default `1.0` — **forbidden in EQ pilot banks**; every option must set an explicit value |

---

## 3. Relationship to dimension deltas

```
contribution_j(option) = evidence_strength(option) * delta_j(option)
```

(as used by TraitScoringService)

| Rule | Requirement |
|---|---|
| Independence | Strength must not be a copy of `|delta_primary|`, `max|delta|`, or `L1` |
| Hierarchy | Large `|delta|` may still have low strength if the mapping is ambiguous |
| Weak map | Ambiguous option → lower strength, smaller or removed deltas |
| Forbidden | Flat identical strength across all options “for consistency” |

---

## 4. Relationship to item clarity

Item clarity can **cap** strength (unclear scenario → no option may exceed ~0.60), but clarity does not set strength by itself. Each option is judged on map defensibility.

---

## 5. Relationship to reliability / evidence count

| Concept | Role of `evidence_strength` |
|---|---|
| Reliability | May enter reliability blends as item-info weight later; **not calibrated here** |
| Evidence count / sufficiency | Does **not** replace evidence units; sufficiency remains count/context based |
| Missing response | Strength unused (no invented evidence) |

---

## 6. Option-specific vs item-specific

`evidence_strength` is **option-specific**.

Item-level clarity / SDR risk are separate metadata (`authoring_notes`, review docs).

---

## 7. Multiplication behavior

Yes — TraitScoringService multiplies `evidence_strength * delta` when accumulating signed evidence.

Therefore strength must remain a **confidence weight**, not a second delta channel.

---

## 8. Evidence sufficiency

Strength does **not** invent sufficiency. An unanswered item contributes nothing regardless of authored strengths on unused options.

---

## 9. Missing-value behavior

| Case | Behavior |
|---|---|
| Option omits field | Parser defaults to `1.0` (over-confident) — **disallowed** in EQ pilot candidate |
| Delta removed as non-inferable | Strength may remain but should be lowered if residual map is thin |

---

## 10. Calibration status

All strengths in EQ pilot / review candidate banks are **uncalibrated provisional authoring hypotheses**.

Expert measurement review and participant data are required before treating strengths as stable.

---

## 11. Provisional bands (authoring only)

| Band | Range | Use when |
|---|---|---|
| Weak map confidence | `0.45–0.54` | Midpoint / mixed / heavily context-dependent option |
| Moderate map confidence | `0.55–0.69` | Clear enough trade-off; some residual ambiguity |
| Strong map confidence | `0.70–0.80` | Behavior clearly supports the attached deltas |
| Reserved | `> 0.85` | Not used in uncalibrated EQ pilot |

Prefer auditable values: `0.45`, `0.50`, `0.55`, `0.60`, `0.65`, `0.75`.

---

## 12. Forbidden interpretations

- Treating `0.72` as a house default
- Equating strength with “how emotionally intelligent the option sounds”
- Using strength to punish reverse-key or low-SDR options
- Using strength as a hidden correct-answer weight
- Claiming strength equals empirical item information

---

## 13. SDR relationship (separate)

| Level | Meaning |
|---|---|
| Item-level SDR risk | How strongly the **item** invites an idealized / authority-approved answer |
| Option-level SDR risk | How socially attractive / unattractive **that option** reads |

They need not be equal. Consistency rule: if any option is `moderate`/`high`, item-level risk should usually be at least `moderate`, unless a documented exception explains why the item still does not invite global idealization.
