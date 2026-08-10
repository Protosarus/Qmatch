# QMatch IQ Runtime Gap v1

**Phase:** P2C-2A-5 (updated)

---

## Current runtime path

```
iq_test_intro_screen
  → IQTestScreen (canonical runtime)
    → IqCanonicalRuntimeService + SharedPreferences session
    → 25 questions / option-ID answers
    → IqCanonicalScorer (uncalibrated 4D)
    → users/{uid}/assessments/iq (qmatch_iq_live_result_v1)
    → EQTestIntroScreen → EQ → Frequency → AssessmentFlowCompleteScreen
```

Orphan UI removed from onboarding: `IqReasoningProfileScreen`,
`IqToEqTransitionScreen` (no longer in tree).

| Fact | Value |
|------|-------|
| Questions shown | **25** |
| Answer identity | **selectedOptionId** |
| Scoring | **4D uncalibrated provisionalScore** |
| Standardized IQ | **none** |

---

## Status after P2C-2A-5

| Capability | Status |
|------------|--------|
| Canonical 340-item bank | **IMPLEMENTED** |
| 25-question session composer | **IMPLEMENTED** |
| Session persistence/resume | **IMPLEMENTED** |
| Canonical 4D IQ scorer | **IMPLEMENTED** |
| Live canonical IQ runtime | **IMPLEMENTED** |
| Legacy 10-item new-session path | **RETIRED_FROM_ACTIVE_NEW_SESSION_PATH** |
| Psychometric calibration | **NOT_STARTED** |
| 20D runtime adapter | **NOT_STARTED** |
| Cloud session sync | **NOT_STARTED / DEFERRED** |

---

## Remaining gaps

- Empirical calibration
- 20D adapter wiring
- Optional EN bank content: **IMPLEMENTED** (`iq_bank_en_v1.json` / `en_v2_340`)
- Legacy asset cleanup debt
