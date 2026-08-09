# Assessment Result Contract v1

**Status:** Contract freeze (P1A)  
**Paths:**  
- `users/{uid}/assessments/iq`  
- `users/{uid}/assessments/eq`  
- `users/{uid}/assessments/frequency`  
- `users/{uid}/assessments/persona`  

Canonical detailed results live **only** in these documents.  
`users/{uid}` may hold **lightweight mirrors** only (see §5).

## Global rules

1. Field names below are **snake_case** in Firestore.  
2. Optional / null fields must be **omitted**, never written as JSON `null` in merges that can clobber.  
3. Missing dimensions appear in `missing_dimensions` (and absent from `dimension_scores`), never filled with `0.5` / `0.42`.  
4. Assessment result ≠ persona result ≠ compatibility score ≠ confidence.  
5. Same inputs + same version fields ⇒ same outputs (deterministic pure functions).  
6. Historical docs are immutable except explicit `status`/supersession metadata.

---

## 1. Shared assessment document fields (IQ / EQ / Frequency)

| Field | Type | Required | Meaning |
|---|---|---|---|
| `assessment_type` | string | yes | `iq` \| `eq` \| `frequency` |
| `assessment_version` | string | yes | Schema of this document shape |
| `content_version` | string | yes | Question bank / set content generation |
| `scoring_version` | string | yes | Trait scoring algorithm ID |
| `normalization_version` | string | yes | Mapping to 0–1 / missing policy |
| `question_schema_version` | string | yes | Item metadata schema |
| `locale` | string | yes | BCP47-ish locale used (e.g. `tr`, `en`) |
| `language_used` | string | yes | `tr` \| `en` (resolved assessment language) |
| `set_id` | string | yes | Assigned set id |
| `assignment_ref` | string | recommended | Path/id of assignment doc |
| `question_order` | string[] | yes | Stable ordered question ids as administered |
| `option_orders` | map | IQ required | Permutations per question id |
| `question_count` | number | yes | Assigned count |
| `answered_count` | number | yes | Non-null answers |
| `started_at` | timestamp | recommended | First answer / start |
| `completed_at` | timestamp | when complete | Server timestamp preferred |
| `status` | string | yes | `in_progress` \| `completed` \| `void` \| `superseded` |
| `raw_answers` | map | yes when completed | `question_id → answer payload` |
| `dimension_scores` | map\<string, number\> | yes when completed | Only **present** dims in `[0,1]` |
| `dimension_evidence_counts` | map\<string, number\> | yes when completed | Evidence units per dim |
| `dimension_reliability` | map\<string, number\> | optional early | `[0,1]` or omit if unknown |
| `missing_dimensions` | string[] | yes when completed | Canonical IDs lacking min evidence |
| `response_validity` | map | yes when completed | RVI components (see below) |
| `source` | string | yes | `client_v1` \| `server_v1` \| `imported_legacy` |
| `created_at` | timestamp | yes | |
| `updated_at` | timestamp | yes | |

### `raw_answers` payloads

- **IQ/EQ MCQ:** `{ "selected_value": string?, "selected_index": number, "presented_option_order": number[] }`  
- **Frequency Likert:** `{ "value": number }` with `1..5`  

Store identity by **value id** when available; index alone is legacy.

### `response_validity` (minimum)

```json
{
  "rvi_version": "rvi_v0",
  "completion_ratio": 1.0,
  "straightlining_flag": false,
  "too_fast_flag": false,
  "inconsistency_flag": false,
  "quality_band": "unknown"
}
```

### Module-specific notes

**IQ**

- May include `performance_summary`: `{ "correct_count": n, "attempted_count": n }` for internal analytics.  
- Must **not** expose percentiles without `normalization_version` that defines norms.  
- `dimension_scores` keys: only `logical_reasoning`, `pattern_reasoning`, `verbal_reasoning`, `spatial_reasoning`.

**EQ**

- No `correct_count` as character score.  
- Option contributions are signed evidence, not right/wrong.  
- `dimension_scores` keys: the 10 canonical EQ IDs.

**Frequency**

- Keep `vector`-compatible read adapters during migration, but canonical write key is `dimension_scores`.  
- Do **not** use `score_total` as persona input. If retained temporarily: `legacy_score_total` only.  
- `dimension_scores` keys: 6 canonical Frequency IDs (`disclosure_pace`, not `emotionalOpenness`).

---

## 2. Persona document — `users/{uid}/assessments/persona`

| Field | Type | Required | Meaning |
|---|---|---|---|
| `assessment_type` | string | yes | always `persona` |
| `persona_version` | string | yes | Document schema |
| `persona_profile_version` | string | yes | Prototype pack id |
| `scoring_version` | string | yes | Persona scoring algorithm |
| `normalization_version` | string | yes | Input vector normalization |
| `source_assessment_refs` | map | yes | `{ "iq": {...}, "eq": {...}, "frequency": {...} }` with set_id, content_version, scoring_version, completed_at |
| `primary_persona_id` | string | yes if status=completed | One of 18 canonical IDs |
| `secondary_persona_id` | string | recommended | |
| `primary_similarity` | number | yes if completed | Comparable similarity score |
| `secondary_similarity` | number | recommended | |
| `top2_margin` | number | yes if completed | |
| `confidence` | number | internal | Do not show as clinical % |
| `confidence_level` | string | yes if completed | `low` \| `medium` \| `high` |
| `evidence_dimensions` | string[] | yes | Canonical dim IDs |
| `counter_evidence` | string[] | recommended | |
| `reason_codes` | string[] | recommended | Stable explanation tokens |
| `adaptive_questions_used` | string[] | yes | Empty array if none |
| `personality_vector_ref` | map | recommended | Snapshot of 20D present dims + missing list (or hash/ref) |
| `status` | string | yes | `completed` \| `insufficient_evidence` \| `superseded` |
| `derived_at` | timestamp | yes | |
| `source` | string | yes | Prefer `server_v1` eventually |
| `created_at` / `updated_at` | timestamp | yes | |

**Forbidden:** deriving persona when any of IQ/EQ/Frequency canonical docs are missing or `status != completed` with required evidence.

---

## 3. History

Optional: `users/{uid}/assessments/persona/history/{resultId}` (or top-level `persona_history`) for immutability.  
Never overwrite prior `scoring_version` outputs in place.

---

## 4. Assignment docs (supporting, not results)

`users/{uid}/assessment_assignments/{iq|eq|frequency}` remain operational for set assignment.  
They are **not** the canonical scored profile. Scores on assignments are progress metadata only.

---

## 5. Allowed `users/{uid}` mirrors

### Allowed (lightweight)

| Field | Meaning |
|---|---|
| `test_completed` | Legacy IQ+EQ gate (freeze meaning; see mapping doc) |
| `frequency_completed` | Frequency gate |
| `iq_assessment_completed` | New explicit flag (add when implementing) |
| `eq_assessment_completed` | New explicit flag |
| `persona_ready` | True only when persona doc completed |
| `primary_persona_id` | Mirror of persona doc |
| `secondary_persona_id` | Mirror |
| `persona_confidence_level` | Mirror |
| `persona_result_ref` | Doc path / id |
| `persona_scoring_version` | Mirror |
| `profile_completed` | Profile setup |
| `discover_eligible` | Derived eligibility |
| `active` | Account flag |
| `looking_for`, demographics, photos | Profile / hard filters |

### Forbidden on user doc (canonical detail)

- Full `raw_answers`  
- Full `dimension_scores` maps (except temporary Frequency `frequency_vector` during migration — mark legacy)  
- Evidence counts, RVI detail  
- Prototype similarities matrix  
- Correct answer keys  

### Legacy mirrors to retain frozen then deprecate

`archetype`, `category`, `iq_score`, `eq_score`, `iq_normalized`, `eq_normalized`, `frequency_type`, `frequency_tags`, `frequency_score`, `frequency_vector` — see mapping doc.

---

## 6. Null and missing-data rules

| Situation | Required behavior |
|---|---|
| Optional field unknown | Omit key |
| Dimension below min evidence | List in `missing_dimensions`; omit from `dimension_scores` |
| Profile save with null persona | **Must not write** null over existing persona mirrors |
| Compatibility input missing | Signal absent → reduce confidence / exclude from soft score; **no** silent 0.5 fill |
| Partial Frequency answers | Score only answered dims; others missing |

---

## 7. Write ownership

| Data | Temporary (MVP) | Target |
|---|---|---|
| Raw answers | Client may write to own assessment doc | Client write answers only; server derives scores |
| Dimension scores / RVI / persona | Client-derived today (legacy) | **Server-authoritative** Cloud Function / trusted backend |
| User mirrors | Client merge | Server transaction after scoring |
| Spoof prevention | Weak today (owner update) | Rules field allowlists + server validation of versions + answer signatures |

**Client-submitted answers ≠ derived scores.**  
UI must never treat a client-written `primary_persona_id` as trusted without matching server persona doc + versions.

---

## 8. Compatibility / matching outputs (separate contract pointer)

Matching scores are **not** stored inside assessment docs as source of truth.  
If cached: `users/{uid}/matching_snapshots/{id}` or pair docs with `matching_scoring_version` + `matching_confidence` separate from persona confidence.

---

## Validation

- [x] Four assessment paths defined  
- [x] Persona separated from IQ/EQ/Frequency  
- [x] User mirrors limited  
- [x] Null-omit + missing explicit  
- [x] Ownership path to server authority stated  
