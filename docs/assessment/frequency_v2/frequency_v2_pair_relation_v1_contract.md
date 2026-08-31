# Frequency V2 pair-relation primitives v1 (dormant)

**Status:** relation measurements only — **no** compatibility score  
**pair_model_version:** `frequency_behavior_v2_pair_relation_v1`

Compatibility is **not** automatically the same thing as similarity. Same pole
is not “compatible.” Opposite pole is not “incompatible.” Later phases may
choose similarity, complementarity, tolerance bands, or asymmetric fit.

This is a **quantum-inspired** local pair representation. It is not
entanglement between users, quantum personality, or a matching rank.

`runtime_selectable` remains `false`.

---

## 1. Local signed state

For dimension `d` and user `u`:

```text
phi_u,d = [ sqrt((1 + x)/2) , sqrt((1 - x)/2) ]
```

Same per-dimension poles as Phase 5A **before** `/sqrt(12)`.

---

## 2. Local pair state

```text
|Phi_AB,d> = |phi_A,d> ⊗ |phi_B,d>
```

Basis order: `|++⟩`, `|+−⟩`, `|−+⟩`, `|−−⟩`.

Do **not** build a global 24×24 tensor pair state. The local 4D pair is enough.

---

## 3. Same-pole / opposite-pole

```text
Π_SAME     = |++⟩⟨++| + |−−⟩⟨−−|
Π_OPPOSITE = |+−⟩⟨+−| + |−+⟩⟨−+|

same_pole_expectation     = ⟨Phi| Π_SAME |Phi⟩
                          = (1 + x_A x_B) / 2
opposite_pole_expectation = 1 - same_pole_expectation
```

Range `[0, 1]`.

| value | meaning |
|---|---|
| `1.0` | strong same-pole orientation |
| `0.5` | no net pole relation / neutral |
| `0.0` | strong opposite-pole orientation |

These are **relation primitives**, not good/bad and not compatibility.

---

## 4. Axis fidelity vs same-pole

```text
axis_fidelity[d] = |⟨phi_A,d | phi_B,d⟩|²
```

- **axis_fidelity:** how similar the two behavioral states are on this axis  
- **same_pole_expectation:** how strongly they share a signed pole  

They are not identical. Neutral/neutral (`x=0`,`x=0`): fidelity `1`, same-pole `0.5`.

Do **not** invent a support-adjusted fidelity. Uncertain mixed states can have
misleadingly high conventional fidelity. Keep behavior similarity and evidence
support separate.

---

## 5. Pair support and supported pole relation

```text
pair_support[d] = sqrt( effective_support_A[d] * effective_support_B[d] )

supported_same_pole[d] =
  0.5 + pair_support[d] * (same_pole_expectation[d] - 0.5)

supported_opposite_pole = 1 - supported_same_pole
```

`pair_support = 1` keeps the behavioral pole relation.  
`pair_support = 0` returns neutral `0.5`.

This does **not** modify either user's `psi`, `rho_behavior`, or `rho_user`.

`pair_support` is not compatibility and not truth probability.

---

## 6. Global diagnostics (not compatibility)

```text
pure_behavior_overlap           = Tr(rho_behavior_A rho_behavior_B)
                                = |⟨psi_A | psi_B⟩|²
mixed_hilbert_schmidt_overlap   = Tr(rho_user_A rho_user_B)
```

The mixed overlap depends on mixedness/purity. It **must not** be used as a
compatibility score.

No dimension weights. No final pair scalar.

---

## 7. What this phase does not do

- final compatibility score
- similarity vs complementarity policy
- dimension weights / matching
- entanglement or 576×576 persisted pair matrices
- modify user ρ, scorer, confidence, evidence, selector
- activate V2
- touch V1, Firebase, C2, Discover, Persona

Offline audit:

```text
dart run tool/frequency_behavior_v2/simulate_phase5c_pair_relation.dart
```
