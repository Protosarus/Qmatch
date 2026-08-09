# QMatch Frequency Runtime-Candidate Bank Audit v1

**Phase:** P2C-2A-8R1  
**Date:** 2026-08-09

## Verdict

```text
TR 50-item frequency_bank_tr_v1 = NOT_CREATED
EN 50-item frequency_bank_en_v1 = NOT_CREATED

Reason:
  BLOCKED_FREQUENCY_SEPARATOR_ITEM_COVERAGE
  BLOCKED_FREQUENCY_QUALITY_ITEM_COVERAGE
```

Existing offline pilot (`frequency_pilot_tr_v1.json`) is scientifically closer than legacy live sets, but it does **not** satisfy the frozen 30+12+6+2 role blueprint without inventing items.

## Blueprint checklist

| Check | Result |
|-------|--------|
| Exactly 50 runtime-candidate items | FAIL (asset absent) |
| Exactly six canonical Frequency IDs | PASS (registry + pilot taxonomy) |
| No historical alias as canonical ID | PASS on pilot / registry |
| 30 core / 5 per dim | SELECTABLE from pilot stock; not role-tagged |
| 12 behavioral-equivalence / 2 per dim | PASS in pilot isomorph registry |
| 6 separator items | **FAIL (0)** |
| 2 quality-only items | **FAIL (0)** |
| Explicit δ ∈ [-1,1] on trait options | PASS on pilot |
| No active correctness fields | PASS on pilot |
| Stable option IDs | PASS (`A`–`D`) |
| Registered in pubspec | Intentionally **false** until R2 |

## Validator readiness

`FrequencyCanonicalBankValidator` encodes the hard blueprint and will emit the blocker codes above until a complete candidate exists.

## Math fixture (not a runtime candidate)

`test/fixtures/frequency/frequency_math_fixture_v1.json` exists only to exercise `CanonicalFrequencyScorer`. Status = `math_fixture`.
