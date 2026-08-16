# QMatch L3 Soft Preference Signal Contract v1

| Field | Value |
| --- | --- |
| Contract id | `l3_soft_preference_signal_contract_v1` |
| Document id | `qmatch_l3_soft_preference_signal_contract_v1` |
| Status | `production_diagnostics_non_ranking_v1` |
| Scope | Discover L3 v1 **profile** soft-preference diagnostics. Evaluated **after** trusted structural L2. Separate from L2. **Non-ranking** in v1. No score fusion, no weights, no hard filtering. |
| Depends on | [Matching Constraints Contract v1](./qmatch_matching_constraints_contract_v1.md), [Preferences audit](./qmatch_preferences_constraints_audit_v1.md), [Final Matching Architecture](./qmatch_final_matching_architecture_v1.md) |
| Field shapes | Existing repo only: `age` / `age_range`, `location` / `distance_preference`, `interests` |
| Explicit non-scope | L1 / L2 / L4 / L5; CM relationship-value / directional preference-fit (future L3 extension); `looking_for`; gender/lifestyle self-attributes |

---

## 0. Production freeze (`production_diagnostics_non_ranking_v1`)

**Discover L3 v1** is the explicit **profile** soft-preference layer. It is **not** the Core Method relationship/value preference system.

| Rule | Frozen value |
| --- | --- |
| Evaluation order | After trusted structural L2 (`structural_l2_v1`) on L1-eligible pairs |
| Relation to L2 | Separate fields. Must not be collapsed into \(D_{\mathrm{structural}}\) |
| Ranking | **Non-ranking in v1.** Does not reorder Discover. No lexicographic L3 keys, bounded rerank, windows, or tiers in this freeze |
| Score fusion | **Forbidden** — no `l3_total`, no L2+L3 blend |
| Weights | **Forbidden** |
| Hard filtering | **Forbidden** — L3 miss / mismatch never drops an L1-eligible pair |
| Missing data | **Unknown** — never imputed, never filled with 0 / 0.5 / 0.42 / “neutral” |

| Signal | v1 production role |
| --- | --- |
| Age preference (`age` / `age_range`) | **Active L3 diagnostic** (`production_promoted=true`) |
| Interests (`interests`) | **Active L3 diagnostic** (`production_promoted=true`) |
| Distance (`location` / `distance_preference`) | **Diagnostic only** — evaluated, **not production-promoted** until location privacy is solved |
| `looking_for` | **Inactive** |
| CM relationship / values / directional preference fit | **Inactive** — future L3 extension after live persistence + content review |
| `gender` / lifestyle self-attributes (`religion`, `children`, drinking, smoking, pets, …) | **Not Matching inputs** |

### Age diagnostic class (not a rank key)

Known mismatch is **not** unknown. Ranking is unchanged.

| `diagnostic_class` | Condition | Meaning |
| --- | --- | --- |
| `mutual_fit` | `available=true` and `mutual_fit=true` | Both ages + both ranges valid; both directions in-range |
| `known_mismatch` | `available=true` and `mutual_fit=false` | Both sides evaluable; one-way or both-miss. Still Discover-eligible |
| `unknown` | `available=false` + `unavailable_reason` | Missing/invalid/partial inputs. Not a mismatch |

One-way (`a_accepts_b` XOR `b_accepts_a`) is a **subtype of `known_mismatch`**, not a ranking tier.

---

## 0.1 Hard rules (inherited + restated)

1. **Age and distance remain SOFT** — never L1 eligibility gates in v1.  
2. **Missing preference or attribute ⇒ `unavailable` / `unknown`**, never failure, never imputed defaults, never a fake neutral.  
3. **No combined L3 score** and **no fusion weights** across signals.  
4. **`looking_for` stays inactive** (intent semantics undefined).  
5. **No `interested_in` / gender inference.** Lifestyle self-attributes are not Matching inputs.  
6. Signals are **separate wire fields**; Discover live ranking remains trusted L2.  
7. Evaluate only among pairs that already passed **L1**; L3 does not re-admit L1 fails.  
8. CM relationship-value / partner-preference-fit services are **not** Discover L3 v1.

---

## 1. Shared output conventions

Each signal returns an independent diagnostic object:

| Common field | Type | Meaning |
| --- | --- | --- |
| `available` | `bool` | Whether the soft signal could be computed |
| `unavailable_reason` | `string?` | Stable reason code when `available=false` |
| `scoring_version` | `string` | Signal id (below) |
| `shadow_only` / `affects_discover_ranking` | flags | Spec: not live ranking under this contract |
| `production_promoted` | `bool` | Age/interests `true`; distance `false` in v1 |
| `policy_status` | `string` | `production_diagnostics_non_ranking_v1` |

**Never** invent a single `l3_total` / preference %.

---

## 2. Age soft signal — `l3_age_preference_soft_v1`

### 2.1 Exact inputs (existing shapes)

| Role | Firestore / model | Shape |
| --- | --- | --- |
| Viewer preference | `users/{A}.age_range` | `List<int>` length 2: `[min, max]` inclusive ages (setup slider 18–80) |
| Candidate preference | `users/{B}.age_range` | same |
| Viewer attribute | `users/{A}.age` | `int` (years) |
| Candidate attribute | `users/{B}.age` | `int` |

No other fields. Do not use birthdate (not in model). Do not use `looking_for`.

### 2.2 Directionality / reciprocity

**Mutual required** when applying the soft signal:

\[
\mathrm{inRange}(x,[m,M]) \iff m \le x \le M
\]

One-way checks:

- \(A\to B\): \(\mathrm{inRange}(B.\mathrm{age},\, A.\mathrm{age\_range})\)  
- \(B\to A\): \(\mathrm{inRange}(A.\mathrm{age},\, B.\mathrm{age\_range})\)

**Reciprocal soft outcome** only when **both** preferences and **both** ages are present and valid:

| \(A\to B\) | \(B\to A\) | Soft interpretation |
| --- | --- | --- |
| true | true | Mutual fit |
| true | false | One-way only (A accepts B; B does not accept A) |
| false | true | One-way only (symmetric case) |
| false | false | Mutual miss |

This is a **diagnostic**, not an eligibility fail.

### 2.3 Output fields

| Field | Type | Meaning |
| --- | --- | --- |
| `available` | bool | Both ages + both valid `age_range` present |
| `a_accepts_b` | bool? | \(A\to B\) in-range |
| `b_accepts_a` | bool? | \(B\to A\) in-range |
| `mutual_fit` | bool? | `a_accepts_b && b_accepts_a` |
| `diagnostic_class` | string | `mutual_fit` / `known_mismatch` / `unknown` — **not** a rank key |
| `production_promoted` | bool | `true` for age in v1 |
| `age_a` / `age_b` | int? | Echo attributes used (optional for debug; may omit in privacy-sensitive exports) |
| `range_a` / `range_b` | `[min,max]?` | Echo prefs used (optional) |
| `unavailable_reason` | string? | See §2.4 |

**No** continuous “age closeness” score in v1 — boolean mutual / one-way diagnostics only (keeps no-weights rule). **No** ranking use of `diagnostic_class`.

### 2.4 Unavailable conditions

Set `available=false` (not a Matching failure) when any of:

| Reason code | Condition |
| --- | --- |
| `missing_age_a` / `missing_age_b` | Age absent or non-finite / non-positive |
| `missing_age_range_a` / `missing_age_range_b` | Preference absent |
| `invalid_age_range_a` / `invalid_age_range_b` | Not length-2 ints, or `min > max`, or outside sane bounds (e.g. min&lt;18 or max&gt;80 per setup UI) |
| `partial_preference` | Only one side has a valid range (reciprocal signal cannot run) |

**Do not** substitute model defaults (`[18,80]`) or setup defaults (`[25,35]`) when the stored preference is missing.

`available=false` is **`unknown`**. It is **not** `known_mismatch`. Do not collapse a computed miss into unknown.

### 2.5 Edge cases

| Case | Behavior |
| --- | --- |
| `min == max` | Valid; only that exact age fits that direction |
| Age exactly on boundary | Inclusive — fits |
| One side missing range | Entire age signal **unavailable** (reciprocity requires both prefs) |
| Ages present, ranges present, mutual false | `available=true`, `mutual_fit=false`, `diagnostic_class=known_mismatch` — **still Discover-eligible**; **does not reorder** |
| Preferential one-way only | Same `known_mismatch` class; report `a_accepts_b` / `b_accepts_a`; do not coerce to mutual; **not** a rank tier |

---

## 3. Distance soft signal — `l3_distance_preference_soft_v1`

### 3.1 Exact inputs (existing shapes)

| Role | Firestore / model | Shape |
| --- | --- | --- |
| Viewer preference | `users/{A}.distance_preference` | `int` km (setup slider **5–100**) |
| Candidate preference | `users/{B}.distance_preference` | same |
| Viewer geo | `users/{A}.location` | `GeoPoint` (lat/lng) |
| Candidate geo | `users/{B}.location` | `GeoPoint` |

**Not inputs:** `location_text` (display only; not a distance engine).

**Production promotion:** `production_promoted=false` until a location-privacy RFC (precise `GeoPoint` on peer-readable `users/{uid}`). The evaluator may still run as a **non-ranking diagnostic**. Do not sort by `distance_km`.

### 3.2 Directionality / reciprocity

1. Compute great-circle distance \(d\) (km) between `location_A` and `location_B` (implementation may use Geolocator / haversine; formula choice is engineering, not a product weight).  
2. **Mutual / stricter-of-two** when both prefs + both geos valid:

\[
d_{\max}=\min(A.\mathrm{distance\_preference},\, B.\mathrm{distance\_preference})
\]

\[
\mathrm{within}=\bigl(d \le d_{\max}\bigr)
\]

One-way diagnostics (optional wire fields) may also expose:

- \(A\to B\): \(d \le A.\mathrm{distance\_preference}\)  
- \(B\to A\): \(d \le B.\mathrm{distance\_preference}\)  

Primary reciprocal soft field is **`within_mutual_cap`** using \(d_{\max}\).

### 3.3 Output fields

| Field | Type | Meaning |
| --- | --- | --- |
| `available` | bool | Both geos + both valid prefs |
| `distance_km` | double? | Computed \(d\) |
| `cap_a_km` / `cap_b_km` | int? | Raw prefs |
| `mutual_cap_km` | int? | \(\min\) of prefs |
| `within_a_cap` | bool? | \(d \le\) A’s pref |
| `within_b_cap` | bool? | \(d \le\) B’s pref |
| `within_mutual_cap` | bool? | \(d \le d_{\max}\) |
| `production_promoted` | bool | `false` in v1 (location privacy) |
| `unavailable_reason` | string? | See §3.4 |

**No** continuous “distance score” / linear decay weight in v1.

### 3.4 Unavailable conditions

| Reason code | Condition |
| --- | --- |
| `missing_location_a` / `missing_location_b` | `GeoPoint` absent |
| `invalid_location_a` / `invalid_location_b` | Non-finite lat/lng or out of world bounds |
| `missing_distance_preference_a` / `_b` | Pref absent |
| `invalid_distance_preference_a` / `_b` | Non-int, ≤0, or outside setup band 5–100 (reject rather than clamp-impute) |
| `partial_geo_or_preference` | Any required input missing on one side |

### 3.5 Edge cases

| Case | Behavior |
| --- | --- |
| \(d = 0\) (same point) | `within_*=true` when prefs valid |
| \(d\) exactly equal to \(d_{\max}\) | Inclusive — within |
| One user has geo but no pref | Signal **unavailable** |
| Pref present, geo missing | **unavailable** — do not use city text |
| Very large \(d\) | `available=true`, `within_mutual_cap=false` — soft miss only |

---

## 4. Interests soft signal — `l3_interests_overlap_soft_v1`

### 4.1 Exact inputs

| Role | Firestore / model | Shape |
| --- | --- | --- |
| Viewer tags | `users/{A}.interests` | `List<String>` |
| Candidate tags | `users/{B}.interests` | `List<String>` |

Normalize for comparison: trim; recommend casefold for equality (document as engineering normalization, not imputation of tags). Empty strings dropped.

### 4.2 Directionality / reciprocity

**Symmetric** — Jaccard-style overlap (aligned with existing `CompatibilityScoring.tagOverlapScore` spirit):

\[
J=\frac{|A\cap B|}{|A\cup B|}
\quad\text{if }|A\cup B|>0
\]

No viewer/candidate direction.

### 4.3 Output fields

| Field | Type | Meaning |
| --- | --- | --- |
| `available` | bool | Both lists present as lists (may be empty — see below) |
| `overlap_count` | int? | \(|A\cap B|\) |
| `union_count` | int? | \(|A\cup B|\) |
| `jaccard` | double? | \(J\in[0,1]\) when union &gt; 0 |
| `production_promoted` | bool | `true` for interests in v1 |
| `unavailable_reason` | string? | See §4.4 |

**Note:** Live Discover ranking is trusted structural L2 (`structural_l2_v1`) and does **not** use this Jaccard as a rank key. Interests Jaccard inside `CompatibilityScoring` is **rollback only** (`legacy_v1`). Interests is an **active L3 v1 diagnostic** (`production_promoted=true`) and still **non-ranking**. Empty-vs-nonempty `jaccard=0` is known zero overlap, **not** unknown. This contract does **not** invent a combined score or percentage.

### 4.4 Unavailable conditions

| Reason code | Condition |
| --- | --- |
| `missing_interests_a` / `missing_interests_b` | Field absent (null / not a list) |
| `empty_union` | Both lists empty after normalize → `available=false` or `available=true` with `jaccard=null` — **choose:** v1 = `available=false`, reason `empty_union` (no evidence of overlap geometry) |

Empty-vs-nonempty: union &gt; 0 ⇒ `available=true`, `jaccard=0` (soft zero overlap, **not** L1 fail).

### 4.5 Edge cases

| Case | Behavior |
| --- | --- |
| Duplicate tags in one list | Treat as set |
| Only whitespace tags | Dropped; may yield empty_union |
| Disjoint nonempty sets | `jaccard=0`, available |
| Identical sets | `jaccard=1` |

---

## 5. Missing-data behavior (global)

| Situation | L3 behavior | L1 / Discover eligibility / ranking |
| --- | --- | --- |
| Missing age range / age / geo / distance pref / interests list | Signal `available=false` + reason = **unknown** | **Unchanged** — not a fail; not a mismatch |
| Soft mutual miss (age/distance) | `available=true`, fit flags false = **known mismatch** (age `diagnostic_class`) | **Unchanged** — not a fail; **does not reorder** |
| Empty interest overlap | Soft zero / empty_union per §4 | **Unchanged** |
| Defaults in profile model constructors | **Must not** be used as Matching fill when Firestore omitted the field | — |

**Never impute:** mid age bands, 50 km, empty→neutral 0.42, city-from-text geo, or gender/intent substitutes.

---

## 6. Explicitly inactive / forbidden under this contract

| Topic | Rule |
| --- | --- |
| `looking_for` | **Inactive** — no intent soft-match matrix |
| `gender` / `interested_in` | **Forbidden** inference or filter |
| Lifestyle self-attributes | **Not Matching inputs** (`religion`, `children`, drinking, smoking, pets, …) |
| CM relationship values / directional preference fit | **Not Discover L3 v1** — future L3 extension |
| Combined L3 score | **Forbidden** |
| Cross-signal weights | **Forbidden** |
| L3 as Discover rank key (lexicographic / rerank / buckets) | **Forbidden in v1** — requires a later ranking RFC |
| Promoting age/distance to L1 | Requires constraints-contract amendment RFC |
| Production-promoting distance | Requires location-privacy RFC |

---

## 7. Wire sketch (non-normative for UI)

```text
l3_soft_preferences_v1: {
  age:    { scoring_version, production_promoted=true, available, diagnostic_class, a_accepts_b, b_accepts_a, mutual_fit, unavailable_reason? }
  distance: { scoring_version, production_promoted=false, available, distance_km, mutual_cap_km, within_mutual_cap, ... }
  interests: { scoring_version, production_promoted=true, available, jaccard, overlap_count, union_count, ... }
}
```

Each block independent. Consumers must not average them.

---

## 8. Implementation status

Evaluators: `L3SoftPreferenceSignalMatcher` under `lib/features/matching/domain/l3_soft_preference_signal*.dart`.  
Discover attach: **after** `DiscoverStructuralL2Ranking.rankL1Batch`; list order unchanged.

Live Discover order remains trusted structural L2 (`structural_l2_v1`). L4/L5 are not live.

Future work (not this freeze): location-privacy RFC before promoting distance; intent RFC before `looking_for`; persistence + content review before CM values as an L3 extension; a separate RFC before any L3 ranking operator.

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-12 | Separate L3 soft signals for age_range, distance_preference, interests; soft-only; no combined score |
| v1 impl | 2026-08-12 | Shadow evaluators: `L3SoftPreferenceSignalMatcher`; status → `shadow_only_not_live` |
| v1 production freeze | 2026-08-16 | Status → `production_diagnostics_non_ranking_v1`; Discover L3 = profile signals; age/interests active diagnostics; distance not production-promoted; known age mismatch ≠ unknown; CM values = future extension; ranking unchanged |
