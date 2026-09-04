# Frequency V2 — Versioned compatibility fusion (Phase 8B.2)

**Status:** source + tests only. **Not activated. Not deployed.**
**Date:** 2026-09-04
**Baseline:** `8cd7a2028152deaf24e61414fb715fcbb48cfd96`
**`runtime_selectable`:** `false`
**Live Discover ranking:** `structural_l2_v1` (unchanged)

This phase defines the frozen **50/50 Frequency V2 compatibility fusion
policy**. It is diagnostic-only. It does **not** change Discover ordering,
activate Frequency V2, deploy `finalizeFrequencyV2`, or write production
users.

---

## Why V1 Frequency is excluded

Canonical Stage B2 already includes:

| Module | Frozen weight |
|--------|----------------|
| IQ | `0.133333` |
| EQ | `0.400000` |
| Frequency V1 | `0.466667` |

Therefore this fusion is **invalid**:

```
0.50 * existing Stage B2 structural_distance
+ 0.50 * Frequency V2 pair-fit
```

That would count Frequency twice (V1 inside Stage B2 plus V2 on top).

Product requirement: Frequency V2 ≈ **50%** of final compatibility. The
remaining ≈50% is **non-frequency structural** compatibility from IQ + EQ
only.

---

## Policy pins

| Pin | Value |
|-----|--------|
| Policy version | `qmatch_compatibility_fusion_v2_policy_v1` |
| Schema version | `qmatch_compatibility_fusion_v2_schema_v1` |
| `NON_FREQUENCY_STRUCTURAL_WEIGHT` | `0.50` |
| `FREQUENCY_V2_WEIGHT` | `0.50` |
| Weight sum | `1` |

These are frozen source constants. They are **not** remotely tunable.

---

## Exact formula

### Non-frequency structural half

Reuse the existing IQ/EQ dimension registries and module-distance math
(`per-module MSE → sqrt → missing-module omission → available-module weight
renormalization → no imputation`).

Do **not** use the six V1 Frequency dimensions.

When both IQ and EQ are available:

```
weightSum = iqWeight + eqWeight
effectiveIqWeight = iqWeight / weightSum
effectiveEqWeight = eqWeight / weightSum
```

Using the frozen constants this is approximately IQ ≈ 25% / EQ ≈ 75%
**inside the structural half**. Those percentages are **derived**, not
independently hardcoded as `0.25` / `0.75`.

```
nonFrequencyStructuralDistance = compareIqEqMeasuredPresence(a, b).combinedDistance
nonFrequencyStructuralFit = clamp01(1 - nonFrequencyStructuralDistance)
```

Canonical normalized IQ/EQ values are `[0,1]`, so the distance stays in
`[0,1]`. Clamp is numerical safety only. No sigmoid / logistic transform.

Coverage denominator for this half is **14** (4 IQ + 10 EQ), not 20.

Existing `compareMeasuredPresence()` (20D, including Frequency V1) is
**unchanged**. Live `structural_distance` still comes from that 20D path.

### Frequency V2 half

Reuse Phase 8B.1 `overall_supported_fit` (confidence/support-adjusted).

```
frequencyV2Fit = overall_supported_fit   // [0,1]
```

Not used:

- `overall_raw_fit` as the ranking input
- V1 Frequency distance
- `frequency_fit_index` as a second fusion variable
- 24D overlap, density matrices, Persona, RVI, activity, soft preferences

Zero pair-support still follows the existing V2 policy:
`supportedFit = 0.5 + support * (rawFit - 0.5)` → **0.5**.

### Final fusion

```
finalFit =
  0.50 * nonFrequencyStructuralFit
  + 0.50 * frequencyV2Fit

finalCompatibilityIndex = 100 * finalFit
```

### Derived contribution (not independently tuned)

```
IQ_final   = 0.50 * (IQ_WEIGHT / (IQ_WEIGHT + EQ_WEIGHT))  ≈ 12.5%
EQ_final   = 0.50 * (EQ_WEIGHT / (IQ_WEIGHT + EQ_WEIGHT))  ≈ 37.5%
V2_final   = 0.50                                           = 50%
```

---

## Missing-data policy

Do **not** neutral-fill missing Frequency V2.
Do **not** silently renormalize the top-level 50/50 split.

A full `compatibility_v2` result requires:

1. non-frequency structural comparison available **and**
2. Frequency V2 pair-fit available

| Condition | Result |
|-----------|--------|
| Frequency V2 missing / malformed | `available: false` (`viewer_frequency_v2_missing`, `candidate_frequency_v2_malformed`, or `frequency_v2_unavailable`) |
| No shared IQ/EQ data | `available: false` (`non_frequency_structural_unavailable`) |
| IQ missing, EQ present | structural half available via existing module renormalization |
| EQ missing, IQ present | structural half available via existing module renormalization |
| IQ and EQ both missing | structural half unavailable → final fusion unavailable |

Partial evidence is never presented as a complete final compatibility score.

---

## Public privacy-safe diagnostic

Nested `compatibility_v2` (opt-in responses only):

```
compatibility_v2: {
  available,
  compatibility_index,       // when available
  policy_version,            // qmatch_compatibility_fusion_v2_policy_v1
  structural_fit,            // when available
  frequency_fit,             // when available (overall_supported_fit)
  structural_coverage,       // when available
  frequency_pair_support,    // when available
  unavailable_reason         // when unavailable
}
```

### Never returned

IQ vector, EQ vector, V1 Frequency vector, 12D V2 vector, per-dimension V2
values, confidence rows, answers, session IDs, density matrices, raw
Firestore data, UIDs inside the nested object.

Default Stage B2 pairs still use only:

`available`, `structural_distance`, `total_coverage`, `comparable_dimensions`,
`unavailable_reason`

---

## Stage B2 opt-in

- Default / absent / non-boolean: **no V2 reads**, no `compatibility_v2`,
  no `frequency_v2`. Byte/semantic Stage B2 behavior unchanged.
- `include_compatibility_v2_diagnostics === true`: reuse the 8B.1 V2 batch
  reads (internally implied) and attach `compatibility_v2`. Does **not**
  attach public `frequency_v2` unless that 8B.1 flag is also true.
- Both flags true: **one** Admin batch-get; no duplicate Firestore fetches.
- Reverse-blocked candidates remain omitted entirely.
- 8B.1 `include_frequency_v2_diagnostics` continues to work independently.

Production Flutter callers do **not** set either opt-in.

Live ranking still uses `DiscoverStructuralL2Ranking.compare()` on
`structural_distance` only. `compatibility_index` is not a ranking input.

---

## Pure server module

`functions/src/compatibility_fusion_v2.js`

- No Firestore access
- Inputs: already-parsed IQ/EQ structural result + Frequency V2 pair-fit
- No UID, no raw vectors

Flutter: `DiscoverStageB2CompatibilityV2Diagnostic` parses the nested object
backward-compatibly. It is **not** displayed as a user-facing percentage.

---

## Legacy / grandfather V2 transition — still unresolved

Production currently has **no completed trusted Frequency V2 population**.

Do **not** solve missing legacy V2 by:

- mapping V1 6D Frequency to V2 12D
- inventing V2 results
- neutral-filling V2
- copying the V1 Frequency score
- manufacturing trusted completion

Until a real V2 result exists for both people in a pair, fusion is
**unavailable**. That is intentional.

Before live V2 ranking we must decide how old / grandfathered users obtain a
**real** V2 result.

---

## Remaining activation sequence (do not perform in 8B.2)

1. Deploy `finalizeFrequencyV2`
2. Bundle reviewed TR/EN V2 pools in Flutter
3. Run device / end-to-end V2 finalize test
4. Decide / implement trusted completion treatment for V2
5. Flip V2 runtime selection
6. Establish legacy / grandfather V2 completion transition
7. Enable `compatibility_v2` server diagnostics in real clients
8. **Only then** switch live ranking to `qmatch_compatibility_fusion_v2_policy_v1`

---

## Reused components (not redone)

Trusted Stage B2 backend, canonical 20D structural matcher, server V2
persisted-result parser, server Frequency V2 pair-fit, JS/Dart pair-fit
parity, V2 Flutter runtime bridge, V2 scorer / selector,
`finalizeFrequencyV2`, optional Stage B2 V2 diagnostic, trusted Discover /
grandfather migration.

---

**Activation is not complete. Ranking is unchanged. V2 is still dormant.**
