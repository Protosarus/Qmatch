# Option Evidence Contract v1

**Status:** provisional measurement contract (P2A-1)  
**Applies to:** EQ and Frequency evidence options (and Frequency Likert scale-point deltas)  
**Does not apply as trait ethics:** deltas are descriptive evidence, not moral grades  

---

## 1. Core definition

For option `o` on item `i` and dimension `j`:

```
delta_i,j(o) ∈ [-1, 1]
```

| Sign | Meaning |
|---|---|
| `> 0` | Positive evidence toward higher values of `j` |
| `< 0` | Negative evidence (toward lower values) / reverse alignment |
| `= 0` | No evidence on `j` |

## 2. Evidence kinds

| Kind | Definition |
|---|---|
| Primary evidence | Non-zero delta on item `primary_dimension` |
| Secondary evidence | Non-zero delta on declared secondary dimensions only |
| Counter-evidence | Delta opposing the respondent’s emerging profile peak on a watched dim (explainability), not a moral penalty |
| Reverse alignment | Negative delta on a positively worded construct (or reverse-keyed Likert) |
| Ambiguous evidence | Near-zero deltas on all dims; should be rare and flagged in review |
| Invalid evidence | Unknown dim ids, out-of-range deltas, forbidden correct-answer fields |
| Missing evidence | Item unanswered / void → contributes nothing (never invent `0`, `0.5`, or `0.42` as a trait) |

## 3. Aggregation (conceptual)

For dimension `j` over answered items `I_j`:

```
raw_j = sum_i ( evidence_strength_i(o) * delta_i,j(o) * q_item_i )
score_j = normalize(raw_j) ∈ [0,1]   # versioned normalization
evidence_count_j = sum_i evidence_units_i,j
```

`evidence_units_i,j` is typically `1` for a primary hit with `|delta| ≥ 0.25`, else a fractional unit for weaker secondary hits (scoring_version decides).

Missing dims: omit from `dimension_scores`; list in `missing_dimensions`.

## 4. Influence limits (provisional)

| Rule | Limit |
|---|---|
| Max `\|delta\|` on primary dim per option | `0.85` |
| Max dimensions with `\|delta\| > 0` per option | `3` |
| Max L1 magnitude `sum_j \|delta_j\|` per option | `1.6` |
| Max contribution of one item to one dimension after strength weighting | ≤ 35% of that dimension’s session evidence mass |
| Min independent contexts per dimension before “present” | `3` (see blueprint) |

No single answer may produce or eliminate a persona. PersonaScoringService already forbids single-dimension persona determination at the prototype layer; item banks must not bypass this with extreme deltas.

## 5. Evidence counts & reliability for PersonaScoringService

`PersonaScoringInput` expects:

- `dimensionEvidenceCounts[j]`
- `dimensionReliability[j]`
- quality `q_j = reliability_j * evidenceSufficiency_j`

### Current pure service finding (P1B-2B-2)

The implemented service uses:

```
evidenceSufficiency_j = min(1.0, evidenceCount_j / 3.0)
```

when `evidenceCount_j > 0`, else `0`.

| Question | Finding |
|---|---|
| Is `/3` global? | **Yes — hardcoded global denominator for all dimensions** |
| Module-specific? | No |
| Dimension-specific? | No |
| Config-driven? | **No** (not in `persona_scoring_config_v2.json`) |

### Mismatch / recommendation

Canonical registry and this blueprint intend **dimension-aware** minimum evidence (IQ feedback often wants ≥4; EQ/Frequency ≥3). The hardcoded `/3` is an acceptable **temporary parity constant** for offline persona validation, but it is **not** a permanent measurement law.

**Before runtime integration**, introduce a versioned map such as:

```json
"evidence_sufficiency_denominators": {
  "logical_reasoning": 4,
  "empathy": 3,
  "depth_preference": 3
}
```

in scoring config (or normalization_version), and stop relying on a silent global `3`.

**This phase does not modify PersonaScoringService.**

## 6. IQ note

IQ uses keyed correctness, not signed EQ-style deltas. Domain evidence units increment on attempted keyed items; scores derive from proportion correct within domain under `scoring_version`.
