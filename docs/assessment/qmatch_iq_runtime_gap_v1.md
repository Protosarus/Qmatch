# QMatch IQ Runtime Gap v1

**Phase:** P2C-2A-0  
**Constraint:** Current production IQ selection/scoring was **not** modified.

---

## Current runtime path

```
iq_test_intro_screen
  → IQTestScreen._loadQuestions
    → QuestionService.loadIQAssessment
      → AssessmentSetService.getOrAssignSet(type: 'iq')
         1) Firestore assessment_sets
         2) assets/data/assessment_sets/iq_sets.json
         3) legacy Firestore questions
         4) assets/data/iq_questions.json
    → QuestionModel MCQ UI (10 items)
    → correct-count score
    → CanonicalAssessmentPersistence (legacy total; empty dimension_scores)
    → IqToEqTransitionScreen
```

| Fact | Value |
|------|-------|
| Questions shown | **10** |
| Dimension IDs on items | **none** |
| Canonical four dims written | as **missing_dimensions** |
| TraitScoringService | **not** called from IQ screens |
| v3 pilot reachable | **no** |
| Fallback | bundled sets → flat 10 |

---

## Gaps for later phases

| Gap | Needed change (later) |
|-----|------------------------|
| Bank | Create `iq_bank_tr_v1.json` (340) |
| Pubspec | Register assessment_v3 IQ bank intentionally |
| Session composer | Build 25-item 7/6/6/6 from bank |
| Scoring | Wire TraitScoringService dimension scores |
| Progress | Persist per-dimension evidence |
| Migration | Move users off 10-item legacy sets |
| Exposure control | Avoid overplay of leaked items |
| Android verification | Device QA after wiring |

---

## Explicit non-goals of this phase

- No change to `QuestionService` / `AssessmentSetService` load order
- No change to `IQTestScreen` item count
- No Firestore schema changes
- No quantum-inspired selection
