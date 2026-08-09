# QMatch EQ Legacy Runtime Retirement v1

**Phase:** P2C-2A-7R2

```text
legacy keyed EQ path = RETIRED_FROM_ACTIVE_NEW_SESSION_PATH
```

## Still present (historical / offline)

* `QuestionService.loadEQAssessment`
* `AssessmentSetService` EQ sets / `eq_sets.json` / `eq_questions.json`
* `buildLegacyIqEqPayload(..., legacyScoringMode: correct_answer_total)`
* Offline pilot banks under `assessment_v3/eq/eq_pilot_*`

## Active new-session path

`EQTestScreen` → `EqCanonicalRuntimeService` + canonical TR/EN banks only.

No `correctAnswer` / `_correctAnswers` in the live screen.
