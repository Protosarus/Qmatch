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
      → EQTestIntroScreen
      → EQTestScreen
      → FrequencyIntroScreen → FrequencyTestScreen
      → AssessmentFlowCompleteScreen
```

Removed from live onboarding (deleted): `IqReasoningProfileScreen`,
`IqToEqTransitionScreen`, `FrequencyResultScreen`.

## Invariants

- Exact resume for valid in-progress sessions
- Answer identity = `selectedOptionId` only
- UI does not score
- No standardized IQ / percentile
- Bank locale for new sessions: `tr-TR` or `en-US` from app language
- Active session bank locale is sticky (no mid-session regen/translation)
- No previous-question navigation (product UX unchanged)

## Legacy

`QuestionService.loadIQAssessment` remains in codebase for EQ tooling / rollback
but is **not** called by `IQTestScreen` for new sessions.
