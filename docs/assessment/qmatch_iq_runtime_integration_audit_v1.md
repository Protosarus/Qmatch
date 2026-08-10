# QMatch IQ Runtime Integration Audit v1

**Phase:** P2C-2A-5 (pre-implementation audit)
**Date:** 2026-08-09
**Constraint:** Sections 1–10 describe the live path **before** canonical wiring.
**Current live onboarding (post orphan cleanup):**
`IQ → EQ Intro → EQ → Frequency → AssessmentFlowCompleteScreen`
(no Reasoning Profile / IQ→EQ transition / Frequency result screens).

---

## 1. Old live entry point

```
AuthWrapper (destination == iq)
  → IQTestIntroScreen
    → IQTestScreen
      → (complete) EQTestIntroScreen
          → EQTestScreen
```

Also: `verification_screen.dart` → `IQTestIntroScreen`.

Files:

- `lib/core/navigation/auth_wrapper.dart`
- `lib/features/assessment/screens/iq_test_intro_screen.dart`
- `lib/features/assessment/screens/iq_test_screen.dart`

---

## 2. Old question source

`IQTestScreen._loadQuestions` → `QuestionService.loadIQAssessment` →
`AssessmentSetService.getOrAssignSet(type: 'iq')`.

Primary bundled content: `assets/data/assessment_sets/iq_sets.json`
(50 sets × 10 questions). Fallback: `assets/data/iq_questions.json`.

Canonical `assets/data/assessment_v3/iq/iq_bank_tr_v1.json` was **not** in
pubspec and **not** loaded by the live path.

---

## 3. Old item count

**10** questions per live session.

---

## 4. Old answer identity

`int? _selectedAnswer` = **list index** into remapped options.
Bundled options lack stable option IDs. Identity = post-shuffle index.

---

## 5. Old correctness logic

```dart
if (_selectedAnswer == _questions[_currentQuestionIndex].correctAnswer) {
  _correctAnswers++;
}
```

Running correct-count; no per-item answer log; no 4D scoring.

---

## 6. Old score / result contract

| Field | Meaning |
|-------|---------|
| `_correctAnswers` | 0…10 correct count |
| assignment `score` | same |
| `raw_score` / `performance_summary.correct_count` | same |
| `users/{uid}.iq_score` | same (colloquial “IQ”, not calibrated) |
| `dimension_scores` | `{}` empty |
| `canonical_profile_ready` | `false` |

---

## 7. Firestore writes

| Path | Writer |
|------|--------|
| `users/{uid}/assessment_assignments/iq` | assign + `markAssignmentCompleted` |
| `users/{uid}/assessments/iq` | `CanonicalAssessmentPersistence.upsertCompletedAssessment` + legacy payload |
| `users/{uid}` | `markIqCompleted` → `iq_completed`, optional `iq_score` |

---

## 8. Onboarding completion dependency

`AssessmentProgressService` v2: IQ completed + EQ not → destination `eq`.
In-session: immediate `pushReplacement` to `EQTestIntroScreen`.
Persona is **not** revealed after IQ.

---

## 9. Result screen dependency

No dedicated IQ results UI. Onboarding goes IQ → EQ Intro directly.
EQ intro no longer takes an `iqScore` constructor argument.

---

## 10. Exact migration points

| Hook | Location |
|------|----------|
| Load | `iq_test_screen.dart` `_loadQuestions` |
| Answer select | option tap → index |
| Advance / score | `_nextQuestion` |
| Complete persist | assignment + legacy payload + `markIqCompleted` |
| EQ handoff | `_showTransitionDialog` |
| Intro entry | `iq_test_intro_screen.dart` Start CTA |
| Auth resume | `auth_wrapper.dart` destination routing |

---

## UX notes (preserve unless conflicting)

- **Within question:** user may change selection before Continue.
- **Previous questions:** no back-to-prior-item UI (do not introduce in P2C-2A-5).
- **Top bar back:** `maybePop` to intro (session must remain durable for reopen).
- **Locale:** UI chrome via l10n; bank is `tr-TR` only for this phase.
- **State management:** StatefulWidget + services (no Riverpod IQ controller).
- **Analytics:** none on IQ path.

---

## Post-integration target (this phase)

Replace active NEW session path with:

canonical session manager → 25 items → selectedOptionId answers →
4D uncalibrated scorer → versioned result persistence → EQ Intro → EQ.
