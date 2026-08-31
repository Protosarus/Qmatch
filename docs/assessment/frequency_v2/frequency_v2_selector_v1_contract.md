# Frequency V2 selector v1 (dormant 50-question session)

**Status:** dormant — not live-selectable  
**selector_version:** `frequency_behavior_v2_selector_v1`  
**manifest schema:** `qmatch_frequency_behavior_v2_session_manifest_v1`  
**bank_version:** `frequency_behavior_pool_tr_v2_draft1`  
**RNG:** `xorshift32_fnv1a32_v1`

This selector composes a 50-question Frequency **V2** session from the 405 dormant selectable questions. It is **not** wired to live Frequency routing, V1 banks, Discover, Persona, matching, C2, or Firebase.

`runtime_selectable` remains `false`. There is no 12D→6D adapter.

Live routing remains:

```
FrequencyCanonicalRuntimeService.assetPathForLocale
  tr-TR → frequency_bank_tr_v1.json
  en-US → frequency_bank_en_v1.json
```

---

## 1. Inputs

Selection is a pure function of:

| Input | Role |
|---|---|
| `selector_version` | Mixer part; changing it changes sessions |
| `bank_version` | Mixer part (`pool_version`) |
| `session_seed` | Per-session entropy |

Same three inputs ⇒ same 50 `question_id`s, same presentation order, same per-question option order, same derived `session_id`.

`created_at` is **manifest metadata only**. It is never mixed into the RNG. Wall-clock time is not used inside selection.

Not used (Phase 3A):

- age, profession, location, gender
- previous answers
- personality estimate / behavioral vector
- response speed

---

## 2. Eligibility

Only `selector_eligible=true` items with exactly one canonical primary are selectable.

Excluded:

- archived DROP (`drop_from_selectable`)
- `rewrite_pending`
- dual / empty / non-canonical primary
- `processing_style_present`
- unresolved leftover dimension labels

Archive size stays 426 / 1704. DROP items remain in the archive and must never appear in a session.

Canonical 12D:

`contact_need`, `closeness_pace`, `initiative`, `autonomy`, `reassurance_need`, `uncertainty_tolerance`, `disclosure_pace`, `boundary_firmness`, `repair_style`, `social_energy`, `structure_preference`, `adaptability`

---

## 3. Coverage (50 questions)

Base: **4 questions × 12 dimensions = 48**.

The remaining **2** questions:

- go to **two distinct** dimensions
- those two dimensions are chosen by shuffling the 12 IDs with stream `extra_slots` and taking the first two
- they are **not** fixed across sessions

Per session:

- 10 dimensions receive 4 questions
- 2 dimensions receive 5 questions

Across many seeds each dimension receives an extra slot with probability 2/12.

---

## 4. Question pick (per dimension)

Phase 3C: seed rank is **primary**. Semantic diversity is a **soft**
preference, not a hard per-cluster quota.

1. Rank every candidate in the dimension with a deterministic jitter:

   `FNV-1a32(selector_version, bank_version, session_seed, primary_dimension, question_id)`

   Do **not** traverse bank / question-ID order. This ranking happens
   **before** any diversity decision.

2. Walk that seeded order and take items until the quota (4 or 5) is filled.

3. Near-duplicate groups identified in review metadata still cannot co-occur
   in the same session.

4. When the next ranked candidate **repeats** a `semantic_cluster` already
   taken in this dimension, look at most
   `softClusterLookahead` (2) further unused eligible candidates for a
   **different** cluster. If none is that close in rank, keep the original
   candidate. A large cluster may therefore contribute 3 or 4 questions.

Do **not** scan the rest of the dimension bank just to obtain a unique
cluster. Rare / singleton clusters appear when they rank near the top,
not because a hard cap exhausted the majority cluster.

Not used as ranking or pick keys:

- evidence scores (`ambiguity`, `diagnostic_value`, …)
- `social_desirability` / `self_presentation_risk`
- weight sign or |weight|
- age, profession, location, previous answers, personality estimates

Evidence priors remain **uncalibrated**. High social desirability ≠ false. This is not a personality score.

---

## 5. Presentation order

Questions are **not** grouped by dimension.

1. Shuffle each dimension’s picked items (`queue|{dimension}`).
2. Shuffle the 12 dimension IDs (`interleave_order`).
3. Emit 4 round-robin rounds (48 questions). Adjacent items in this prefix have different primaries.
4. Insert the two extra items at the first position that:
   - keeps **≤ 2 consecutive** questions with the same primary
   - prefers different primary / context / cluster from both neighbors
5. One greedy adjacent pass swaps when two neighbors share a semantic cluster or the same family/payment/conflict tag, if the swap still satisfies the consecutive-primary cap.

Hard constraint: **no more than 2 consecutive questions with the same primary dimension**.

---

## 6. Option order

Authored A/B/C/D order is not the presentation order.

Each question shuffles its four `option_id`s with stream:

```
options|{question_id}
```

mixer parts: `selector_version`, `bank_version`, `session_seed`, stream, RNG algorithm.

Stable `option_id`s are preserved. Scoring and stored answers **must** use `option_id`, never display index.

---

## 7. Session manifest

```json
{
  "schema_version": "qmatch_frequency_behavior_v2_session_manifest_v1",
  "selector_version": "frequency_behavior_v2_selector_v1",
  "bank_version": "frequency_behavior_pool_tr_v2_draft1",
  "session_id": "frequency_v2_{fnv1a32_hex}",
  "session_seed": "...",
  "locale": "tr-TR",
  "created_at": "optional ISO-8601; not used in selection",
  "question_ids": ["... 50 ids ..."],
  "questions": [
    {
      "question_id": "frequency_v2_q0001",
      "primary_dimension": "initiative",
      "presentation_index": 0,
      "presented_option_order": ["frequency_v2_q0001_c", "..."]
    }
  ]
}
```

Do **not** copy `behavioral_weights` or `evidence_meta` into the manifest.

Derived `session_id` uses FNV-1a 32 of `selector_version|bank_version|session_seed` when the caller does not supply one.

---

## 8. RNG

Copied locally (not imported from IQ):

- FNV-1a 32-bit over UTF-16 code units, NUL separators between mixer parts
- xorshift32 stream
- Fisher–Yates on a copy
- rejection sampling for `nextInt`

Streams: candidate rank uses mixer parts `selector_version`, `bank_version`, `session_seed`, `primary_dimension`, `question_id` (no bank-order traversal). Presentation streams: `extra_slots`, `queue|{dim}`, `interleave_order`, `options|{question_id}`.

---

## 9. What this phase does not do

- Activate V2 or set `runtime_selectable=true`
- Modify V1 banks, locale routing, evidence values, question text, or weights
- Touch Firebase, C2, Discover, Persona, matching
- Build a 12D→6D map
- Adaptive item selection from user attributes or prior answers

Offline simulation:

```text
dart run tool/frequency_behavior_v2/simulate_phase3a_selector.dart
dart run tool/frequency_behavior_v2/simulate_phase3b_selector.dart
dart run tool/frequency_behavior_v2/simulate_phase3c_selector.dart
```

Phase 3A and 3B reports are historical. Phase 3C is the soft-diversity audit.
