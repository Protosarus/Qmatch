# Reverse-Pair Consistency Contract v1

**Status:** frozen for P2A-2D-2.1  
**Scope:** Module-neutral RVI reverse-consistency evaluation  
**Applies to:** IQ / EQ / Frequency TraitScoringService sessions  

## Observed pre-contract behavior

1. Frequency (and EQ review-candidate) reverse pairs are **behaviorally keyed**:
   corresponding behavioral poles store the **same** canonical primary-delta sign.
2. Trait scoring correctly accumulates those signed deltas (trait direction OK).
3. Legacy `_reversePairConsistency` always expected **opposite** stored signs.
4. Therefore trait scores were correct while reverse-consistency RVI was
   uninterpretable for behaviorally keyed banks.

## Non-negotiables

- Trait direction must never be inverted to satisfy RVI.
- Reverse RVI affects confidence / publishability only.
- Option letters and display positions never imply correspondence.
- Pair mode is never inferred from prompt wording.
- Missing pair metadata → reverse component **unavailable**, not fabricated
  inconsistency.

## Declared modes

Every reverse pair evaluated for RVI must declare exactly one mode via
form/session metadata (`pair_registry.reverse_pairs[].consistency_mode` or an
explicit `ReversePairDescriptor` on `TraitScoringSessionInput`).

| Mode wire name | Meaning of consistency |
|---|---|
| `opposite_trait_sign` | Selected options yield **opposite** primary-delta signs |
| `behavioral_correspondence` | Selected options yield the **same** primary-delta sign |
| `explicit_option_mapping` | Selected options match a declared option correspondence map |

### `opposite_trait_sign`

Use when reverse-keyed wording stores opposite primary signs for the same
surface option label (legacy fixture pattern).

### `behavioral_correspondence`

Use when both members are keyed to the same trait pole for the same behavior
(Frequency pilot / EQ review-candidate pattern). Consistency = same primary
sign across members.

### `explicit_option_mapping`

Use when option IDs differ or ordering is shuffled and signs alone are
insufficient. Requires `option_correspondence` map keys of the form
`"<question_id>::<option_id>"` → corresponding option id on the other member.

## Evaluation rules

1. Resolve the pair's `ReversePairDescriptor` by `pair_id`.
2. If descriptor or mode missing → skip pair (do not score as inconsistent).
3. If either response missing → skip pair (partial administration).
4. If mode is `explicit_option_mapping` and map is empty / no key for the
   selected options → skip pair (unavailable).
5. Aggregate available pair scores into `reverse_consistency`.
6. If no pairs available → component missing; may emit
   `rvi_reverse_metadata_unavailable` when pairs exist but all lack metadata.

## Trait scoring isolation

Reverse-pair descriptors are read only inside RVI computation. Dimension
evidence traces and dimension scores ignore pair mode entirely.

## Frequency application

Frequency reverse pairs declare:

```json
"consistency_mode": "behavioral_correspondence"
```

See also: `frequency_reverse_pair_application_review_v1.md`.
