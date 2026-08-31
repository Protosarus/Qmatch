# Frequency V2 quantum-inspired signed-pole state encoding v1 (dormant)

**Status:** domain/calculation model only — **not** pair compatibility, mixedness, or live V2  
**encoding_version:** `frequency_behavior_v2_signed_pole_state_v1`  
**schema_version:** `qmatch_frequency_behavior_v2_signed_pole_state_v1`

This is a **quantum-inspired mathematical representation** of signed 12D
`normalized_behavior`. It does not claim that personality is quantum mechanics,
that a person is a quantum system, or that measurement collapse describes
answering a question.

`runtime_selectable` remains `false`.

---

## Forbidden encoding

Do **not** treat the signed 12D vector `x` as a normalized pure-state amplitude
vector and then set

```text
rho = |psi><psi|
```

because `psi` and `-psi` generate the **same** density matrix. Globally
opposite behavioral profiles (all `+1` vs all `-1`) would be indistinguishable.

That encoding is forbidden.

---

## 1. Signed-pole amplitudes

For every canonical dimension `d`:

```text
x_d = normalized_behavior[d]     with  -1 <= x_d <= +1

a_plus[d]  = sqrt( (1 + x_d) / 2 )
a_minus[d] = sqrt( (1 - x_d) / 2 )
```

| `x` | `a_plus` | `a_minus` |
|---|---|---|
| `+1` | `1` | `0` |
| `0` | `sqrt(0.5)` | `sqrt(0.5)` |
| `-1` | `0` | `1` |

`x = 0` is **behavioral center** on that dimension. It is not unknown, low
confidence, or missing. Missing scores are a separate incomplete-vector error
and are never silently filled with 0.

Each pair satisfies `a_plus² + a_minus² = 1`.

---

## 2. 24D state vector

Canonical basis order (24 labels):

```text
contact_need:+ , contact_need:-
closeness_pace:+ , closeness_pace:-
initiative:+ , initiative:-
autonomy:+ , autonomy:-
reassurance_need:+ , reassurance_need:-
uncertainty_tolerance:+ , uncertainty_tolerance:-
disclosure_pace:+ , disclosure_pace:-
boundary_firmness:+ , boundary_firmness:-
repair_style:+ , repair_style:-
social_energy:+ , social_energy:-
structure_preference:+ , structure_preference:-
adaptability:+ , adaptability:-
```

Unnormalized pole amplitudes have `Σ amplitude² = 12`.

Global normalize:

```text
psi_i = amplitude_i / sqrt(12)
<psi|psi> = 1
```

---

## 3. Behavior-only amplitudes

`psi` encodes **behavior only**. Do not mix into amplitudes:

- `provisional_confidence`
- `evidence_quality`
- `presentation_pressure`
- `ambiguity`
- response latency
- social desirability
- cross-context consistency

Those quantities may later control **uncertainty / mixedness**, not direction.
This phase does **not** define mixedness `lambda`.

---

## 4. Pure behavioral density matrix

```text
rho_behavior = |psi><psi|
```

24×24 real symmetric. Numerically:

- `Tr(rho) = 1`
- `rho` symmetric
- `rho` positive semidefinite (within tolerance)
- `rho² ≈ rho`
- purity `Tr(rho²) ≈ 1`

This is the **pure** behavioral representation only. It is **not** the final
user density matrix.

The Dart model holds the matrix in memory. Default `toJson` **omits** it so it
is not persisted to Firebase.

---

## 5. Sign preservation

Profile A: all 12 dimensions `+1`  
Profile B: all 12 dimensions `-1`

Must hold:

- `psi_A ≠ psi_B`
- `rho_A ≠ rho_B`
- state-vector dot product **≠ 1**
- density-matrix overlap `Tr(rho_A rho_B) ≠ 1`

A single dimension at `+1` versus `-1` occupies distinct signed basis poles.

Dot product and overlap here are **diagnostics**, not a compatibility score.
This phase does not define pair compatibility, entanglement, or measurement.

---

## 6. Domain model

| Field | Notes |
|---|---|
| `encoding_version` | `frequency_behavior_v2_signed_pole_state_v1` |
| `scorer_version` / `bank_version` / `session_id` | provenance |
| `basis_labels[24]` | canonical `dimension:+` / `dimension:-` |
| `behavior_vector_12d` | signed `normalized_behavior` only |
| `pole_amplitudes_24d` | before `/sqrt(12)` |
| `state_vector_24d` | unit `psi` |
| `pure_density_matrix_24x24` | in-memory only |
| `trace` / `purity` | scalars |

---

## 7. What this phase does not do

- mixedness `lambda`
- inject confidence into `psi`
- pair compatibility
- entanglement or collapse metaphors
- claim quantum mechanics validates personality
- modify scorer, confidence, selector, or evidence
- activate V2
- touch V1, Firebase, C2, Discover, Persona, matching

Offline audit:

```text
dart run tool/frequency_behavior_v2/simulate_phase5a_quantum_state.dart
```
