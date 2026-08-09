# QMatch IQ Legacy Compatibility v1

**Phase:** P2C-2A-0  
**Rule:** Do not silently import legacy items into the canonical bank in this phase.

---

## Legacy dimension inventory

| Legacy signal | Present in runtime IQ JSON? | Notes |
|---------------|----------------------------|-------|
| `logical_reasoning` | no field | Canonical target exists offline in pilot only |
| `pattern_reasoning` | no field | same |
| `verbal_reasoning` | no field | same |
| `spatial_reasoning` | no field | same |
| `numerical` | **not present as item dimension** | Retired / forbidden alias in persona registry |
| No dimension field | **yes** (`iq_sets.json`, `iq_questions.json`) | Items are untyped MCQs |

Live persistence still declares four canonical IQ dimensions and writes them as **missing** after legacy completion (`CanonicalDimensions.iq`), with empty `dimension_scores`.

---

## Mapping assessment

| Legacy source attribute | Canonical mapping | Confidence |
|-------------------------|-------------------|------------|
| Untyped MCQ in `iq_sets.json` | **Uncertain** — cannot map to one of four dims without expert reclassification | low |
| Flat `iq_questions.json` | Same — uncertain | low |
| `difficulty` int 1/2/3 | Rough editorial band only; not interchangeable with easy/medium/hard without policy | medium |
| `correctAnswer` string matching option label text | Incompatible with `correct_option_id` (A–D) | high (structural) |
| Option as `{label:{en,tr}}` | Incompatible with `{id,text}` canonical options | high |
| No rationale / solution | Missing required rationale | high |
| No subskill | Missing required subskill | high |
| Bilingual stubs | Locale policy for v1 bank is `tr-TR` primary | medium |

### Clean mappings

None of the legacy runtime items have an explicit dimension ID that cleanly equals a canonical dimension. Therefore **no automatic clean map** exists.

### Uncertain mappings

Any attempt to infer dimension from item wording (e.g. number sequences → pattern) is editorial guesswork and **out of scope** for silent import.

### Incompatible fields

- `correctAnswer` as free text / label match
- option objects without stable `A|B|C|D` ids
- missing `rationale`, `subskill`, `schema_version`, `review_state`
- set-oriented packaging (50×10) vs bank-oriented packaging (340 unique)

### Retired `numerical`

- Must **not** be remapped into logical/pattern/verbal/spatial.
- Must be rejected if encountered as a dimension ID.
- Numeric sequences may later be authored under `pattern_reasoning` / `numeric_sequence` **as new items**, not as renamed `numerical` imports.

---

## ID collision risk

| Source | ID style | Collision risk with pilot |
|--------|----------|---------------------------|
| `iq_sets.json` | short legacy ids | low vs `iq_tr_v1_*` |
| Flat bank | short ids | low |
| Pilot | `iq_tr_v1_{domain}_{nnn}` | n/a |
| Future bank | `iq_*` snake ids | must validate uniqueness globally |

---

## Safe-import verdict

| Source | Safe to import now? | Reason |
|--------|---------------------|--------|
| `iq_sets.json` | **No** | No dims, no rationales, wrong option contract, unreviewed |
| `iq_questions.json` | **No** | Emergency fallback only |
| Pilot / review candidate | **Not as runtime bank** | Offline seed only; promotion flow required |

**This phase does not import any legacy questions.**
