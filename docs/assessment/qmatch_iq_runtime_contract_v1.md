# QMatch IQ Runtime Contract v1

**Phase:** P2C-2A-5
**Status:** IMPLEMENTED (live path)

---

## Live path

```
IQTestIntroScreen
  → IQTestScreen (IqCanonicalRuntimeService)
      → getOrCreateActiveSession (UID-scoped SharedPreferences)
      → render plan.displayedOptionIds
      → persist selectedOptionId + index (write-through)
      → complete (25 answers)
      → IqCanonicalScorer
      → users/{uid}/assessments/iq (qmatch_iq_live_result_v1)
      → markIqCompleted(rawScore: null)
      → IqReasoningProfileScreen
      → IqToEqTransitionScreen
      → EQTestIntroScreen(iqScore: 0)
```

## Invariants

- Exact resume for valid in-progress sessions
- Answer identity = `selectedOptionId` only
- UI does not score
- No standardized IQ / percentile
- Bank locale for this phase: `tr-TR` (question content); UI chrome follows app l10n
- Mid-session UI locale change does not mutate/regenerate the session
- No previous-question navigation (product UX unchanged)

## Legacy

`QuestionService.loadIQAssessment` remains in codebase for EQ tooling / rollback
but is **not** called by `IQTestScreen` for new sessions.
