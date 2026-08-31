# Frequency V2 mixed density v1 (dormant)

**Status:** domain/calculation model only — **not** pair compatibility  
**mixedness_version:** `frequency_behavior_v2_mixed_density_v1`  
**encoding_version:** `frequency_behavior_v2_signed_pole_state_v1`  
**confidence_version:** `frequency_behavior_v2_confidence_v1`

This is a **quantum-inspired mixed-state representation**. Mixedness is an
engineering parameter. It is not quantum personality, quantum consciousness,
a psychology proof, entanglement between users, wavefunction collapse, or
scientifically validated quantum behavior.

`runtime_selectable` remains `false`.

---

## 1. Dimension effective support

```text
effective_support[d] =
  provisional_confidence[d] * confidence_completeness[d]
```

Both inputs are in `[0, 1]`. The product is an engineering support heuristic.

It is **not** probability of truth, probability that personality is correct,
clinical certainty, or scientific confidence.

Missing `provisional_confidence` or `confidence_completeness` is **not**
replaced with `0`, `0.5`, or `1`. Construction of `rho_user` is refused.

---

## 2. Global state support

All 12 dimensions are equally weighted:

```text
global_support = mean(effective_support[d])
0 <= global_support <= 1
```

Do not weight by `|normalized_behavior|`, `signal_utilization`, age,
profession, location, latency, or raw social desirability.

Evidence metadata enters only indirectly through the already-defined Phase 4B
provisional confidence model.

---

## 3. Mixedness lambda

```text
lambda = 1 - global_support
0 <= lambda <= 1
```

| lambda | meaning |
|---|---|
| `0` | retain the pure behavioral state |
| `1` | no interpretable state support; maximally mixed |

Lambda is **not** uncertainty probability, dishonesty, noise probability, or
psychological entropy. It is a quantum-inspired engineering mixedness parameter.

There is **no** per-dimension lambda in this phase.

---

## 4. Mixed user density matrix

`D = 24`. The **only** Phase 5B transformation is:

```text
rho_user = (1 - lambda) * rho_behavior + lambda * I / 24
```

Do not manipulate `psi`. Do not change behavioral amplitudes.

`rho_behavior` remains the Phase 5A pure outer product `|psi⟩⟨psi|`.

---

## 5. Properties

- `Tr(rho_user) = 1`
- symmetric
- positive semidefinite
- `lambda = 0` ⇒ `rho_user = rho_behavior`, purity ≈ 1
- `lambda = 1` ⇒ `rho_user = I/24`, purity = `1/24`
- `0 < lambda < 1` ⇒ `1/24 < purity < 1`

Analytic purity of a depolarized pure state:

```text
expected_purity = (1 - lambda)^2 + lambda * (2 - lambda) / 24
```

Must match `Tr(rho_user²)` within numeric tolerance.

---

## 6. Separation

Changing confidence/completeness must **not** change:

- `behavior_vector_12d`
- `state_vector_24d`
- `rho_behavior`

It may change only: `effective_support`, `global_support`, `lambda`,
`rho_user`, mixed-state purity.

Opposite all-`+1` / all-`-1` profiles remain distinguishable when `lambda < 1`.
At `lambda = 1` both become `I/24` (expected: zero support removes
distinguishability). Hilbert–Schmidt overlap `Tr(ρ_A ρ_B)` is a diagnostic,
**not** compatibility.

---

## 7. Domain model

| Field | Notes |
|---|---|
| versions | mixedness / encoding / confidence / scorer / bank / session |
| `effective_support_by_dimension[12]` | |
| `global_support` / `lambda` | |
| `pure_state_purity` / `mixed_state_purity` | |
| `trace` | of `rho_user` |
| `behavior_vector_12d` / `state_vector_24d` | copied from Phase 5A |
| `rho_behavior` / `rho_user` | in-memory; omitted from default JSON |

Incomplete confidence yields `ok=false` and **null** `rho_user`.

---

## 8. What this phase does not do

- pair compatibility or matching
- dimension-specific lambda
- alter `psi` or the 12D behavioral vector
- alter Phase 4B confidence, evidence, or selector
- entanglement / collapse metaphors
- activate V2
- touch V1, Firebase, C2, Discover, Persona

Offline audit:

```text
dart run tool/frequency_behavior_v2/simulate_phase5b_mixed_density.dart
```
