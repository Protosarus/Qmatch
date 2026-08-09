# QMatch EQ Bank TR/EN Parity v1

**Phase:** P2C-2A-7R1

## Structural parity = validated

TR (`eq_bank_tr_v1`) and EN (`eq_bank_en_v1`) share identical:

* item IDs
* primary / secondary dimension IDs
* option IDs
* dimension delta maps
* scoring policy version (`eq_10d_uncalibrated_signed_evidence_v1`)
* response format
* semantic / reverse pair metadata
* schema version (`qmatch_eq_bank_v1`)

Only user-facing `prompt` / option `text` differ by locale.

Deltas were **not** adjusted for English wording.

## EN translation review status

| Check | Status |
|-------|--------|
| structural_parity | **validated** |
| translation_semantic_review | **candidate / review_required** |
| psychometric_cross_language_validation | **not_calibrated** |
| human expert psychological review | **pending** (no repo evidence of completed EN expert review) |

EN strings are **candidate localizations** authored for structural parity — not claimed as human-desk-reviewed psychometric translations.

No prior approved EN EQ runtime bank existed in the repository (pilot EN fields were explicit non-translations).
