# QMatch IQ Runtime Gap v1

**Phase:** P2C-2A-4 (updated)
**Constraint:** Current production IQ selection/scoring was **not** modified.

---

## Current runtime path (unchanged)

```
iq_test_intro_screen
  → IQTestScreen._loadQuestions
    → QuestionService.loadIQAssessment
      → AssessmentSetService.getOrAssignSet(type: 'iq')
    → QuestionModel MCQ UI (10 items)
    → correct-count score (list index)
    → CanonicalAssessmentPersistence (legacy total; empty dimension_scores)
```

| Fact | Value |
|------|-------|
| Questions shown | **10** |
| Dimension IDs on live items | **none** |
| v3 bank reachable at runtime | **no** |
| Session composer wired | **no** |
| Session persistence wired to UI | **no** |
| Canonical 4D scorer wired | **no** |

---

## Offline status after P2C-2A-4

| Capability | Status |
|------------|--------|
| Canonical 340-item bank | **IMPLEMENTED_OFFLINE** |
| 25-question session composer | **IMPLEMENTED_OFFLINE** |
| Session persistence/resume | **IMPLEMENTED_OFFLINE** |
| Answer-state persistence | **IMPLEMENTED_OFFLINE** |
| Canonical 4D IQ scorer | **IMPLEMENTED_OFFLINE** |
| Psychometric calibration | **NOT_STARTED** |
| 20D runtime adapter | **NOT_STARTED** |
| Runtime IQ screen integration | **NOT_STARTED** |
| Cloud session sync | **NOT_STARTED / DEFERRED** |

---

## Gaps for later phases

| Gap | Needed change (later) |
|-----|------------------------|
| Runtime wire | IQTestScreen → session manager → option-ID UI → 4D scorer |
| Persistence of results | Explicit schema for 4D provisional scores (not fake IQ) |
| Calibration | Pilot evidence per calibration plan |
| 20D adapter | Map four dimensions only; versioned |
| Migration | Move users off 10-item legacy sets / index scoring |

---

## Explicit non-goals of this phase

- No change to live IQ flow
- No overall IQ / percentile fabrication
- No TraitScoring / Core Method / EQ / Frequency changes
- No Firestore schema for canonical 4D results
- IQ assessment is **not** release-ready
