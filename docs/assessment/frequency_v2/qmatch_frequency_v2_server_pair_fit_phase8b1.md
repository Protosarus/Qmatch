# Frequency V2 — Server pair-fit diagnostics (Phase 8B.1)

**Status:** source + tests only. **Not activated. Not deployed.**
**Date:** 2026-09-04
**Baseline:** `3fc642323755bf1eb5555b4e8b611c3a93e351fc`
**`runtime_selectable`:** `false`
**Live Discover ranking:** `structural_l2_v1` (unchanged)

This phase adds a privacy-safe **server-side Frequency V2 pair-fit primitive**
on the existing trusted Stage B2 callable. It does **not** define final
compatibility weights, change Discover ordering, or activate Frequency V2.

---

## Reused components

| Piece | Location |
|-------|----------|
| Dart pair-fit / pair-relation math | `lib/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2_pair_fit.dart`, `frequency_behavior_v2_pair_relation.dart` |
| 12D policy membership | Dart `FrequencyBehaviorV2Contract` |
| Trusted V2 result document | `users/{uid}/assessments/frequency_v2` (`qmatch_frequency_behavior_v2_result_v1`, `admin_finalize_frequency_v2_v1`) |
| Stage B2 handler (EU + US) | `handleCompareStageB2Structural` in `functions/src/stage_b2_l2_callable.js` |
| Production Flutter call | `compareStageB2StructuralEu` / `europe-west1` |
| US callable | `compareStageB2Structural` / `us-central1` (rollback/debug only) |
| Canonical 20D structural matcher | `functions/src/canonical_20d_group_normalized_shadow.js` |
| Flutter ranking | `DiscoverStructuralL2Ranking.rankL1Batch()` — structural distance only |

EU and US callables **share** `handleCompareStageB2Structural`. This phase did
not add a second scoring implementation.

---

## New server modules

| Piece | Location |
|-------|----------|
| Pair-fit pins | `functions/src/frequency_behavior_v2_contract.js` (`PAIR_FIT_*`, `PAIR_RELATION_VERSION`, result schema/source) |
| JS pair-fit (Dart mirror) | `functions/src/frequency_behavior_v2_pair_fit.js` |
| Strict V2 result parser | `functions/src/frequency_behavior_v2_result_parser.js` |
| Dormant Stage B2 opt-in | `include_frequency_v2_diagnostics === true` in `stage_b2_l2_callable.js` |
| Flutter optional parser | `DiscoverStageB2FrequencyV2Diagnostic` |
| Flutter optional request | `DiscoverStageB2TrustedL2Client.compareForL1Batch(includeFrequencyV2Diagnostics: false)` |
| JS/Dart parity fixtures | `test/fixtures/frequency_v2/pair_fit_js_dart_parity_v1.json` |

Catalog, selector, scorer, finalizer, and session-validation **semantics were
not changed**. Result documents still must not persist 24D, pair-fit, or
`frequency_fit_index`. Pair-fit is computed on demand.

---

## Pair-fit formula (exact Dart mirror)

For each of the 12 canonical dimensions:

```
xA = normalized_behavior A
xB = normalized_behavior B
delta = abs(xA - xB)
halfDelta = clamp(delta / 2, 0, 1)
```

**SIMILARITY_LINEAR** (`rawFit = 1 - halfDelta`):
`contact_need`, `closeness_pace`, `autonomy`, `reassurance_need`,
`uncertainty_tolerance`, `disclosure_pace`, `boundary_firmness`, `repair_style`

**SIMILARITY_TOLERANT** (`rawFit = 1 - halfDelta^2`):
`initiative`, `social_energy`, `structure_preference`, `adaptability`

```
effectiveSupport = provisional_confidence * confidence_completeness
pairSupport = sqrt(clamp(effectiveSupportA * effectiveSupportB, 0, 1))
supportedFit = 0.5 + pairSupport * (rawFit - 0.5)

overallRawFit = sum(rawFit) / 12
overallSupportedFit = sum(supportedFit) / 12
overallPairSupport = sum(pairSupport) / 12
frequencyFitIndex = 100 * overallSupportedFit
```

No complementarity bonuses. No new tolerance threshold.

---

## Persisted fields consumed

From `users/{uid}/assessments/frequency_v2` only:

- `schema_version`, `assessment_type`, `status`, `source`
- `dimensions[].dimension_id`
- `dimensions[].normalized_behavior` (finite, `[-1, 1]`)
- `dimensions[].provisional_confidence` (finite, `[0, 1]`)
- `dimensions[].confidence_completeness` (finite, `[0, 1]`)

Missing, duplicate, unknown, NaN/Inf, out-of-range, wrong source/schema, or
non-completed results are **rejected**. No inference. No neutral fill.

---

## Public diagnostic fields

Nested `frequency_v2` (opt-in responses only):

```
frequency_v2: {
  available: true | false,
  frequency_fit_index: number,          // when available
  overall_supported_fit: number,        // when available
  overall_pair_support: number,         // when available
  pair_fit_version: "frequency_behavior_v2_pair_fit_v1",
  unavailable_reason: string            // when unavailable
}
```

Default Stage B2 pairs still use only:

`available`, `structural_distance`, `total_coverage`, `comparable_dimensions`,
`unavailable_reason`

### Privacy exclusions (never returned)

`xA` / `xB`, raw 12D values, per-dimension confidence/completeness/support,
session IDs, responses, answers, item IDs, 24D vectors, density matrices,
top alignment/gap dimensions, `overall_raw_fit` (internal/parity only).

---

## Stage B2 opt-in behavior

- Default / absent / non-boolean: **no V2 reads**, no `frequency_v2` field.
- `include_frequency_v2_diagnostics === true`: one Admin batch-get adds
  viewer + candidate `assessments/frequency_v2` docs alongside canonical and
  reverse-block refs. No N sequential Firestore calls.
- `MAX_CANDIDATE_UIDS = 120` unchanged.
- Reverse-blocked candidates are still **omitted entirely** (no V2 leak).
- Missing or malformed V2 **does not fail** structural L2. Structural
  availability follows the existing canonical_v1 rule. V2 may be available
  even when canonical is missing.

Production Flutter callers do **not** set the opt-in.

---

## No ranking impact

`DiscoverStructuralL2Ranking` still orders by `structural_distance` (then
recency, then uid). It does not read `frequency_fit_index`. No
`final_compatibility`, `compatibility_percentage`, or `match_probability`
was added. Legacy CompatibilityScoring, Persona, Activity/RVI, and L3 were
not modified.

---

## JS/Dart parity

Shared fixtures: `test/fixtures/frequency_v2/pair_fit_js_dart_parity_v1.json`

- Fixture count: **12**
- Tolerance: **1e-9**
- Coverage: identical users, opposite linear extremes, tolerant-dimension
  difference, high/low/zero/mixed support, all 12 dimensions, `x=±1`,
  confidence/completeness 0 and 1
- Compared fields: per-dimension `raw_fit`, `supported_fit`, `pair_support`;
  overall raw/supported/pair support; `frequency_fit_index`

---

## Current matching-input audit (8B.2 planning only)

| Input | Status today |
|-------|----------------|
| Canonical structural IQ component (`w=0.133333` inside Stage B2) | **LIVE ranking input** (folded into `structural_distance`) |
| Canonical structural EQ component (`w=0.400000`) | **LIVE ranking input** |
| Canonical V1 Frequency component (`w=0.466667`) | **LIVE ranking input** |
| Trusted Stage B2 reverse-block omission | **LIVE membership filter** |
| Recency (`lastActiveAt`) | **LIVE tie-break only** (not a compatibility weight) |
| Frequency V2 pair-fit / `frequency_fit_index` | **NOT live** (opt-in diagnostic only) |
| Persona shadow (`0.15 / 0.30 / 0.55`) | **SHADOW/diagnostic** (persona, not Discover ranking) |
| Stage B2 dual-path collector | **SHADOW/diagnostic** (debug; `enabled=false` by default) |
| L3 soft preferences | **SHADOW/diagnostic** |
| Activity / temporal / RVI | **NOT live** in Discover ranking (`temporal_included=false`) |
| Legacy `CompatibilityScoring` percent | **ROLLBACK only** (`legacy_v1` order path) |
| Client 20D vectors | **NOT live** (trusted backend Admin-reads `canonical_v1`) |

Live Discover mode remains `DiscoverRankingMode.structuralL2V1`.

---

## Frequency double-count warning (required for 8B.2)

Current Stage B2 **already includes Frequency V1 at 0.466667** of the
canonical 20D structural formula.

Therefore this fusion is **invalid** as a final model:

```
0.50 * existing Stage B2 structural_distance
+ 0.50 * Frequency V2 pair-fit
```

That would count Frequency twice (V1 inside Stage B2 plus V2 on top).

Product intent: Frequency V2 ≈ **50%** of final compatibility. The remaining
~50% **must not** include the old V1 Frequency contribution again.

**Do not select final numbers in 8B.1.** Phase 8B.2 must choose a versioned
fusion policy after the live components above are classified.

---

## Still missing before activation / 8B.2

- Versioned fusion policy that avoids V1+V2 Frequency double-count
- Consuming `frequency_fit_index` in ranking (explicitly out of 8B.1)
- Production deploy of `finalizeFrequencyV2`
- Runtime V2 selection flip
- V2 result writes / production users
- Discover/trust treatment for V2 completion
- Device/production test of opt-in diagnostics

**Activation is not complete. Ranking is unchanged. V2 is still dormant.**
