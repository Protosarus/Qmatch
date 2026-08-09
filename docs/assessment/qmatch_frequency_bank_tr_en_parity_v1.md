# QMatch Frequency Bank TR/EN Parity v1

**Phase:** P2C-2A-8R1A
**Date:** 2026-08-09

## Status

```text
TR runtime candidate = CREATED_AND_VALIDATED
EN runtime candidate = CREATED_AND_STRUCTURALLY_VALIDATED

structural_parity = validated
internal_translation_status = authored_candidate
translation_semantic_review = candidate/review_required
psychometric_cross_language_validation = not_calibrated
```

## Enforced identical fields

`FrequencyCanonicalBankParity` requires TR/EN identity for:

* item IDs / roles
* primary / secondary dimensions
* option IDs
* dimension-delta maps
* relationship / isomorph / reverse metadata
* separator_type / separator_dimensions / separator_persona_targets
* trait_scoring / quality_type / expected_protocol_option_id
* scoring policy / schema versions

Only user-visible language differs.

## EN content provenance

| Segment | EN source |
|---------|-----------|
| 30 core + 12 isomorph | Pilot EN stubs (pending full semantic review) |
| 6 separators + 2 quality | QMatch-authored EN supplied in P2C-2A-8R1A |

Do not claim psychometric cross-language equivalence.
