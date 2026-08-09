# QMatch IQ Item Quality Standard v1

**Phase:** P2C-2A-0  
**Applies to:** future canonical items under `iq_item_schema_v1`.

---

## Difficulty policy

Bands: `easy` | `medium` | `hard`

| Rule | Statement |
|------|-----------|
| Assignment | Editorial estimate by author + reviewer using construct load, steps, and language demand |
| Not scientific yet | Bands are **not** psychometric measurements |
| Future calibration | Replace with empirical difficulty from pilot exposure + response data |
| Overexposure | Track item exposure counts; rotate families; suspend leaked items |
| Family calibration | Sequence vs verbal vs spatial may need separate empirical tracks |

`IqBankContract.treatsDifficultyAsCalibrated == false`.

Estimated time bounds: **20–180** seconds.

---

## Hard reject rules

Reject items with any of:

1. Zero or multiple correct answers / correct representations
2. Ambiguous correct answer (material alternative not controlled)
3. Repeated options / equal text after normalization
4. Duplicate prompt after normalization
5. Answer revealed in prompt wording
6. Grammar disagreement that uniquely reveals the answer
7. “All of the above” / “None of the above” (and TR equivalents)
8. Trick wording unrelated to reasoning
9. Unnecessary historical/general-knowledge dependence
10. Region-specific cultural assumptions as gates
11. Private/sensitive personal content
12. Unsupported image dependency
13. External-link dependency
14. Broken mathematical notation / inconsistent units
15. Control characters / raw HTML
16. Missing rationale
17. Unsupported dimension or subskill
18. Retired `numerical`
19. Estimated time outside bounds
20. Forbidden quantum / fake IRT / `correct_index` fields

Near-duplicates: **warnings** for review, not automatic schema failure unless exact normalized duplicate.

---

## Pilot findings snapshot (existing 25)

Source: `iq_pilot_tr_v1.json` + red-team docs (not silently edited this phase).

| Bucket | Guidance |
|--------|----------|
| Acceptable (keep seed) | Majority PASS items per red-team matrix |
| Needs revision | PASS_WITH_MINOR_EDIT items; language polish |
| Needs expert review | All 25 (`review_state` pending / internal only) |
| Reject / rewrite lineage | Items marked REWRITE/REPLACE in red-team (handled in review candidate, not auto-merged here) |

Pilot remains offline; promotion still required before runtime eligibility.
