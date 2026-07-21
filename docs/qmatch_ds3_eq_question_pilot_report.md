# DS-3B — EQ Question Pilot (Shared Cosmic MCQ Shell)

**Date:** 2026-07-19  
**Pilot screen:** `lib/features/assessment/screens/eq_test_screen.dart`  
**Scope:** Presentation only — EQ active question UI. No scoring, Firestore, set assignment, IQ, or Frequency changes.

---

## 1. Shared widgets created

| Widget | Path | Role |
|--------|------|------|
| `QAssessmentScaffold` | `lib/features/assessment/widgets/q_assessment_scaffold.dart` | Midnight cosmic backdrop, SafeArea, max content width, light status bar |
| `QAssessmentHeader` | `.../q_assessment_header.dart` | Qmatch eyebrow + assessment title + `n / N` chip |
| `QAssessmentProgress` | `.../q_assessment_progress.dart` | Violet→pink→gold progress bar (host supplies fraction) |
| `QQuestionCard` | `.../q_question_card.dart` | Glass question surface for long stems |
| `QAnswerOptionCard` | `.../q_answer_option_card.dart` | A–D glass option; selected glow + check |
| `QAssessmentNavigation` | `.../q_assessment_navigation.dart` | Next / Finish CTA (`eqGradient`) |
| Barrel | `.../assessment_widgets.dart` | Exports |

Suitable for later **IQ** reuse (same 4-option MCQ). Not generalized for Frequency Likert yet.

---

## 2. EQ screen visual changes

- Cosmic midnight scaffold (restrained nebula wash — no Welcome couple/hero)
- Header: `eqTestTitle` + question counter
- Progress: existing `(index+1)/total` → `QAssessmentProgress`
- Question: glass card, wrapping long TR/EN copy
- Answers: four stacked glass cards; selection = violet/pink glow + gold check
- Nav: same Next/Finish labels; calls existing `_nextQuestion`
- Scroll: `CustomScrollView` for long EQ scenarios/options
- Loading / empty: same messages, cosmic shell

**Not added:** new back/exit confirmation (none existed before).

---

## 3. Background strategy

Code-based only:

- `AppGradients.cosmicBackgroundGradient`
- Soft blurred violet / magenta orbs (low opacity)
- Dark vignette for readability

No Welcome assets, no per-question images.

---

## 4. Protected runtime functions (unchanged)

| Function | Role |
|----------|------|
| `_loadQuestions` | `QuestionService.getRandomEQQuestions` |
| `_nextQuestion` | Select guard → score if correct → advance or `_showResults` |
| `_showResults` | `ArchetypeCalculator` → `AuthService.updateTestCompletion` → `AssessmentSetService.markAssignmentCompleted` → dialog → `FrequencyIntroScreen` |
| Selection `setState` | `_selectedAnswer = index` |
| `_disableScreenshots` / `_enableScreenshots` | `FLAG_SECURE` |

Progress formula unchanged: `(_currentQuestionIndex + 1) / _questions.length`.

---

## 5. Responsive strategy

- `SafeArea` + horizontal padding from width
- `ConstrainedBox(maxWidth: 480)`
- `CustomScrollView` for question + answers (header/progress/nav pinned)
- Answer `minHeight: 56`, natural text growth
- No nested scroll conflict (single scroll region)

Representative targets: 320×568, 375×812, 390×844, 430×932 (layout constraints designed for these; manual device pass recommended).

---

## 6. Current limitations

- Completion dialog styling still legacy gold theme (out of scope)
- No in-app Back (parity with pre-pilot EQ)
- IQ / Frequency screens not migrated yet
- BackdropFilter on each answer may have modest cost on low-end devices

---

## 7. Reuse for IQ (next)

1. Swap `EQTestScreen` shell into `IQTestScreen` with same widgets.
2. Keep IQ `_nextQuestion` scoring + `option_orders` remapping + FLAG_SECURE untouched.
3. Pass IQ title via `QAssessmentHeader` (`iqTestTitle` or equivalent).
4. Do not port Frequency until Likert-specific option widgets exist.

---

## 8. Scoring / Firestore

**No changes.**
