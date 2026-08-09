# QMatch IQ → 20D Runtime Adapter v1

**Phase:** P2C-2A-6  
**Adapter version:** `iq_to_20d_runtime_adapter_v1`  
**Status:** IMPLEMENTED

---

## Flow

```
IqCanonicalScoringResult (4D uncalibrated)
        ↓
IqTo20dRuntimeAdapter.adapt(ownerUid:)
        ↓
QmatchCanonicalProfileFragment (partial)
        ↓
users/{uid}/profiles/canonical_v1
        ↓
onboarding continues → Reasoning Profile → EQ
```

## Input requirements

- Exactly four canonical IQ dimensions
- Scores in `[0,1]`
- Scoring policy ∈ `{iq_4d_uncalibrated_accuracy_v1}`
- Calibration = `uncalibrated`
- Non-empty owner UID, session id, bank version/locale

## Output

- Four measured IQ dimensions (`source=canonical_iq`)
- Sixteen IDs listed as missing (EQ + Frequency)
- `canonical_profile_ready=false`
- Locale-independent dimension IDs (TR/EN bank metadata only as source fields)

## Explicit non-goals

- EQ / Frequency migration
- Persona scoring
- Matching / QRCF / Discover
- Quantum-inspired state
- Group weights (0.15 / 0.30 / 0.55)
- Legacy `iq_score` / `correctCount/25` as profile coordinates
