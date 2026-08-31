# Frequency V2 confidence v1 (provisional dimension index)

**Status:** dormant engineering heuristic — not live-selectable  
**confidence_model_version:** `frequency_behavior_v2_confidence_v1`  
**scorer_version:** `frequency_behavior_v2_scorer_v1`  
**score schema:** `qmatch_frequency_behavior_v2_session_score_v1`

This layer sits on Phase 4A primitives. It is **not** a probability, percentile, lie score, clinical certainty, or scientifically validated confidence estimate.

`runtime_selectable` remains `false`. Behavioral direction is unchanged.

---

## 1. What the number means

`provisional_confidence` means:

> How cleanly and consistently this session supports interpretation of this behavioral dimension under the current authored, uncalibrated model.

It does **not** mean: probability the user is truthful; probability a personality result is correct; clinical certainty; scientific validity.

`signal_utilization` is **not** an input. Moderate ±1 answers may still be highly interpretable.

---

## 2. Evidence quality

```
semantic_clarity = 1 - mean_ambiguity
evidence_quality = mean(
  mean_diagnostic_value,
  mean_behavioral_plausibility,
  semantic_clarity
)
```

Range [0, 1]. All three means must be present; otherwise `evidence_quality` is null and the index is not fabricated.

---

## 3. Primary observability

```
primary_observability = primary_signal_coverage
```

---

## 4. Cross-context component

If `cross_context_consistency` **and** `cross_context_coverage` are available:

```
context_component = 0.75 * cross_context_consistency
                  + 0.25 * cross_context_coverage
```

If consistency is null: `context_component` is **null**. Missing cross-context is never stored as 0.

---

## 5. Presentation pressure

Not deception.

```
presentation_pressure = mean(
  mean_social_desirability,
  mean_obviousness,
  mean_self_presentation_risk
)
presentation_adjustment = 1 - (0.20 * presentation_pressure)
```

Range of the adjustment: **0.80–1.00**. Maximum authored pressure may reduce confidence by at most 20%. It cannot reverse or erase `normalized_behavior`.

If the three presentation means are incomplete, pressure is null and the adjustment is **1.00** (no penalty for missing priors).

---

## 6. Base and provisional index

Nominal weights: evidence_quality **0.50**, primary_observability **0.30**, context_component **0.20**.

If context is available:

```
base_confidence = 0.50 * evidence_quality
                + 0.30 * primary_observability
                + 0.20 * context_component
```

If context is unavailable, renormalize the **available** weights only (divide by 0.80). Do **not** insert a fake neutral context value.

```
provisional_confidence = clamp(base_confidence * presentation_adjustment, 0, 1)
```

`confidence_completeness` is **1.00** when context is available and **0.80** when it is not. Completeness is exposed separately so missing cross-context is not hidden inside the index.

---

## 7. Flags (engineering only)

Deterministic, machine-readable, non-diagnostic:

| Flag | When |
|---|---|
| `LOW_EVIDENCE_QUALITY` | `evidence_quality < 0.50` |
| `HIGH_PRESENTATION_PRESSURE` | `presentation_pressure >= 0.75` |
| `LOW_PRIMARY_OBSERVABILITY` | `primary_observability < 0.50` |
| `LIMITED_CROSS_CONTEXT` | `context_component` is null **or** `cross_context_coverage < 0.50` |
| `CONTEXT_SENSITIVE` | `cross_context_consistency < 0.50` **and** `cross_context_coverage >= 0.50` |

`CONTEXT_SENSITIVE` must never be labeled inconsistent person, dishonest, unstable, or unreliable.

---

## 8. Invariants

Changing evidence metadata may change confidence.

Changing evidence metadata **must not** change `raw_sum`, `capacity`, `normalized_behavior`, primary signals, or behavioral direction.

Changing presentation pressure **must not** reverse or suppress the behavioral vector.

`signal_utilization` **must not** affect `provisional_confidence`.

---

## 9. What this phase does not do

- Activate V2
- Emit a global Frequency score or percentile
- Calibrate a scientific confidence probability
- Lie / deception / clinical claims
- Modify selector, questions, weights, or evidence priors
- Quantum / density-matrix layer
- Touch V1, Firebase, C2, Discover, Persona, matching, or a 12D→6D map

Offline audit:

```text
dart run tool/frequency_behavior_v2/simulate_phase4b_confidence.dart
```
