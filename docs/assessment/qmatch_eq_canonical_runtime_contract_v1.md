# QMatch EQ Canonical Runtime Contract v1

**Phase:** P2C-2A-7R2

## Runtime path

```text
EQ entry → EqCanonicalRuntimeService
  → locale-sticky bank (eq_bank_tr_v1 / eq_bank_en_v1)
  → 30-item session (eq_30_full_bank_deterministic_v1)
  → selectedOptionId answers
  → CanonicalEqScorer (eq_10d_uncalibrated_signed_evidence_v1)
  → qmatch_eq_10d_live_result_v1
  → EqTo20dRuntimeAdapter
  → users/{uid}/profiles/canonical_v1
  → FrequencyIntroScreen
```

## Session schema

`qmatch_eq_persisted_session_v1` (SharedPreferences, UID-namespaced)

Preserves: owner, session id, bank version/locale, policies, item order,
displayed option IDs, selected option IDs, current index, status.

## Locale

New session follows app language. Active session bank_locale is frozen.

## Scoring

R1 math unchanged. No overall EQ. RVI gate inactive. Reliability not calibrated.
