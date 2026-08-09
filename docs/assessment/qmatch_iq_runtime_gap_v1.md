# QMatch IQ Runtime Gap v1

**Phase:** P2C-2A-3 (updated)
**Constraint:** Current production IQ selection/scoring was **not** modified.

---

## Current runtime path (unchanged)

```
iq_test_intro_screen
  → IQTestScreen._loadQuestions
    → QuestionService.loadIQAssessment
      → AssessmentSetService.getOrAssignSet(type: 'iq')
    → QuestionModel MCQ UI (10 items)
    → correct-count score
    → CanonicalAssessmentPersistence (legacy total; empty dimension_scores)
```

| Fact | Value |
|------|-------|
| Questions shown | **10** |
| Dimension IDs on live items | **none** |
| v3 bank reachable at runtime | **no** |
| Session composer wired | **no** |
| Session persistence wired to UI | **no** |

---

## Offline status after P2C-2A-3

| Capability | Status |
|------------|--------|
| Canonical 340-item bank | **IMPLEMENTED_OFFLINE** |
| 25-question session composer | **IMPLEMENTED_OFFLINE** |
| Session persistence/resume | **IMPLEMENTED_OFFLINE** |
| Answer-state persistence | **IMPLEMENTED_OFFLINE** |
| Runtime IQ screen integration | **NOT_STARTED** |
| Canonical 4D IQ scoring | **NOT_STARTED** |
| Cloud session sync | **NOT_STARTED / DEFERRED** |
| Expert review/calibration | **open** |

---

## Gaps for later phases

| Gap | Needed change (later) |
|-----|------------------------|
| Pubspec assets | Register `assessment_v3/iq/iq_bank_tr_v1.json` intentionally when wiring |
| Runtime wire | IQTestScreen → `IqSessionManager` → option-ID UI |
| Scoring | P2C-2A-4 TraitScoring / 4D scores |
| Cloud sync | Explicit Firestore schema + rules + migration (not this phase) |
| Logout wipe | Optional `clearOwnerSessions` on sign-out if product requires |
| Migration | Move users off 10-item legacy sets |
| Review gates | Promote beyond `desk_reviewed_candidate` |

---

## Explicit non-goals of this phase

- No change to `QuestionService` / `AssessmentSetService` load order
- No change to `IQTestScreen` item count
- No Firestore schema changes for session drafts
- No scoring changes
- No EQ / Frequency / Core Method changes
