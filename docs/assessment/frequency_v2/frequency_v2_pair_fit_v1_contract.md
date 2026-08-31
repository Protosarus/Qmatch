# Frequency V2 pair-fit v1 (dormant)

**Status:** provisional engineering heuristic — **not** live matching  
**pair_fit_version:** `frequency_behavior_v2_pair_fit_v1`  
**pair_fit_policy_version:** `frequency_pair_fit_policy_v1`  
**calibration:** PROVISIONAL / UNCALIBRATED

This is a dormant **Frequency Fit** / **Frequency Alignment** index. It is not
relationship success probability, match probability, love percentage,
soulmate scoring, personality truth, or scientifically validated prediction.

`runtime_selectable` remains `false`.

---

## 1. Signed behavioral distance

```text
delta[d] = |x_a[d] - x_b[d]|          range 0 … 2
linear_proximity[d] = 1 - delta / 2   range 0 … 1
```

---

## 2. Dimension policy types (v1 only)

Two conservative policies. **No complementarity bonus.** Opposition is never
rewarded.

### SIMILARITY_LINEAR

```text
raw_fit = 1 - delta / 2
```

Dimensions:

- contact_need
- closeness_pace
- autonomy
- reassurance_need
- uncertainty_tolerance
- disclosure_pace
- boundary_firmness
- repair_style

### SIMILARITY_TOLERANT

```text
raw_fit = 1 - (delta / 2)²
```

Dimensions:

- initiative
- social_energy
- structure_preference
- adaptability

Moderate differences are penalized less; extreme opposition still yields low fit.
This is **not** evidence that opposites attract.

---

## 3. Support-aware fit

From Phase 5C `pair_support[d]`:

```text
supported_fit[d] = 0.5 + pair_support[d] * (raw_fit[d] - 0.5)
```

- `pair_support = 1` → full behavioral fit signal retained  
- `pair_support = 0` → neutral `0.5`

Low-confidence profiles must not create strong positive or negative fit claims.
`raw_fit` is not altered.

---

## 4. Equal weights

```text
weight[d] = 1 / 12
overall_raw_fit = mean(raw_fit[d])
overall_supported_fit = mean(supported_fit[d])
frequency_fit_index = 100 * overall_supported_fit
overall_pair_support = mean(pair_support[d])
```

Do **not** multiply the final score by `overall_pair_support` again.

---

## 5. Explanation primitives (not in final score)

```text
supported_alignment_strength = pair_support * raw_fit
supported_gap_strength = pair_support * (1 - raw_fit)
```

Rank `top_alignment_dimensions` / `top_gap_dimensions` deterministically.
Use neutral labels such as “similar contact preference” or “larger difference
in structure preference”. No moral labels.

---

## 6. Quantum-inspired diagnostics (excluded from fit formula)

Phase 5C fields are retained on each row for inspection:

- axis_fidelity
- same_pole_expectation / opposite_pole_expectation
- supported_same_pole

They are **not** inputs to `raw_fit` or `frequency_fit_index` in v1.
Specifically excluded: `pure_behavior_overlap`, `mixed_hilbert_schmidt_overlap`.

---

## 7. Symmetry

V1 is symmetric: `Fit(A,B) == Fit(B,A)` for every dimension and global scalar.

No asymmetric need/supply logic yet.

---

## 8. Policy versioning

All assignments and curves are **PROVISIONAL** and **UNCALIBRATED**.

Future telemetry may introduce `frequency_pair_fit_policy_v2`.
Never silently change v1 for existing sessions.

---

## 9. What this phase does not do

- wire into live matching / Discover / Persona
- complementarity bonus
- learned dimension weights
- demographics or latency inputs
- density overlap as final score
- activate V2
- touch V1, Firebase, C2

Offline audit:

```text
dart run tool/frequency_behavior_v2/simulate_phase5d_pair_fit.dart
```
