# QMatch Frequency Bank TR/EN Parity v1

**Phase:** P2C-2A-8R1  
**Date:** 2026-08-09

## Status

```text
TR runtime candidate = NOT_CREATED
EN runtime candidate = NOT_CREATED
structural_parity = N/A (no candidate pair)
translation_semantic_review = candidate/review_required (blocked upstream)
psychometric_cross_language_validation = not_calibrated
```

## Evidence from repository

Pilot TR (`frequency_pilot_tr_v1.json`) embeds EN prompt/option stubs:

```text
EN equivalent pending (tr-TR pilot reference; not a translation).
```

Notes in the pilot form mark EN fields as schema-required stubs only — **not** authored translations and **not** human semantic review.

There is **no** approved EN Frequency runtime-candidate bank to claim structural parity against.

## Parity contract (ready for future banks)

When TR/EN candidates exist, `FrequencyCanonicalBankParity` must enforce identical:

* item IDs / roles
* primary / secondary dimensions
* option IDs
* dimension-delta maps
* relationship / isomorph / reverse metadata
* scoring policy / schema versions

Only user-visible language may differ. Deltas must not change because English “sounds” stronger/weaker.

## Non-claim

Do not claim psychometric cross-language equivalence or completed EN semantic review without repository proof.
