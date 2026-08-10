# DS-3A — Assessment UI Audit (IQ / EQ / Frequency)

**Date:** 2026-07-19 (historical audit)

**Current live flow note (2026-08):**
`IQ Intro → IQ → EQ Intro → EQ → Frequency Intro → Frequency → AssessmentFlowCompleteScreen`

Deleted orphans: Reasoning Profile, IQ→EQ transition, Frequency result, `eq_test_screen_temp`.

**Original scope:** Inspection only — no code, assets, scoring, Firestore, or navigation changes.

**App root:** Qmatch Flutter (`lib/features/assessment/`)

---

## 1. File map

### Screens

| Role | Path | Class | Production wiring |
|------|------|-------|-------------------|
| IQ intro | `lib/features/assessment/screens/iq_test_intro_screen.dart` | `IQTestIntroScreen` | Yes — `AuthWrapper` |
| IQ questions | `lib/features/assessment/screens/iq_test_screen.dart` | `IQTestScreen` | Yes — from IQ intro |
| EQ intro | `lib/features/assessment/screens/eq_test_intro_screen.dart` | `EQTestIntroScreen` | Yes — after IQ complete / AuthWrapper |
| EQ questions | `lib/features/assessment/screens/eq_test_screen.dart` | `EQTestScreen` | Yes — from EQ intro |
| Frequency intro | `lib/features/assessment/screens/frequency_intro_screen.dart` | `FrequencyIntroScreen` | Yes — after EQ / AuthWrapper |
| Frequency questions | `lib/features/assessment/screens/frequency_test_screen.dart` | `FrequencyTestScreen` | Yes — from Frequency intro |
| Flow complete | `lib/features/assessment/screens/assessment_flow_complete_screen.dart` | `AssessmentFlowCompleteScreen` | Yes — after Frequency finish |

Removed: `FrequencyResultScreen`, `IqReasoningProfileScreen`, `IqToEqTransitionScreen`, `eq_test_screen_temp.dart`.

### Services / models / utils

| Path | Role |
|------|------|
| `services/question_service.dart` | IQ/EQ question load |
| `services/frequency_service.dart` | Frequency load, score, save |
| `services/assessment_set_service.dart` | Set assign, order, option permutation (IQ), complete |
| `models/question_model.dart` | IQ/EQ MCQ model |
| `models/frequency_model.dart` | Frequency question / answer / result |
| `models/assessment_set_model.dart` | Set + assignment models |
| `models/archetype_model.dart` | Archetype from IQ+EQ scores |
| `utils/localized_text_resolver.dart` | `en`/`tr` content maps |
| `utils/assessment_result_display_resolver.dart` | Result display localization |
| `utils/assessment_language.dart` | Assessment language helper |
| `utils/assessment_debug_config.dart` | Pilot set override (`*_set_001`) |
| `lib/core/navigation/auth_wrapper.dart` | Gate: IQ → (EQ) → Frequency → Profile → Main |
| `lib/core/widgets/elegant_warning.dart` | Select-required warning (IQ/EQ) |

### Question data assets

| Path | Role |
|------|------|
| `assets/data/assessment_sets/iq_sets.json` | Primary IQ — 50 sets × 10 Q |
| `assets/data/assessment_sets/eq_sets.json` | Primary EQ — 50 sets × 10 Q |
| `assets/data/assessment_sets/frequency_sets.json` | Primary Frequency — 50 sets × 12 Q |
| `assets/data/iq_questions.json` | Legacy IQ emergency fallback |
| `assets/data/eq_questions.json` | Legacy EQ emergency fallback |

---

## 2. Runtime flow (current)

```
AuthWrapper
  └─ assessment progress → IQTestIntroScreen → IQTestScreen
       └─ complete → EQTestIntroScreen → EQTestScreen
            └─ complete → FrequencyIntroScreen → FrequencyTestScreen
                 └─ complete → AssessmentFlowCompleteScreen → AuthWrapper
```

| Concern | IQ | EQ | Frequency |
|---------|----|----|-----------|
| Result nav | → `EQTestIntroScreen` | → `FrequencyIntroScreen` | → `AssessmentFlowCompleteScreen` |

---

## 3. Shared vs separate architecture

### Shared (logic / data — not UI)

- `AssessmentSetService.getOrAssignSet` / `markAssignmentCompleted`
- Assignment docs: `users/{uid}/assessment_assignments/{iq|eq|frequency}`
- Content load priority: Firestore → bundled `assessment_sets` → legacy
- `LocalizedTextResolver` for question content maps

### Separate UI (duplicated)

- **IQ and EQ question screens** are near line-for-line copies (progress, A/B/C/D rows, Next/Finish).
- **Frequency** is a different layout (AppBar, 5 Likert labels from l10n, Back + Next).

### Question “type” determination

Not a polymorphic type field. Determined by **which screen/service** loads:

- IQ → `QuestionService.getRandomIQQuestions` / `type: 'iq'`
- EQ → `getRandomEQQuestions` / `type: 'eq'`
- Frequency → `FrequencyService.loadAssignedFrequencyQuestions` / `type: 'frequency'`

### Answer rendering

- **IQ/EQ:** `ListView` over `options`; letter badges A–D; selected = primary fill.
- **Frequency:** Hardcoded `List.generate(5)`; labels from l10n (`stronglyDisagree`…); **UI ignores** model `options` if present.

### Answer storage

| | Storage |
|--|---------|
| IQ/EQ | In-memory: current `_selectedAnswer`; `_correctAnswers` accumulator. Prior selections discarded on advance. |
| Frequency | `Map<String, int> _answers` by question id (1–5); survives Back. |

### Index / completion

- Advance only if answered (IQ/EQ warn; Frequency disables Next).
- Back: Frequency only.
- Completion: score → persist assignment/user fields → navigate.

---

## 4. Question-type matrix

### IQ (`iq_sets.json`)

| Attribute | Value |
|-----------|--------|
| Typical choices | **4** MCQ |
| Images / diagrams | **None** in data or assets |
| Formulas / symbols | Text-only (sequences, analogies, syllogisms; “shapes” described in words) |
| Likert | No |
| Key fields | `id`, `question` `{en,tr}`, `options[].label`, `correctAnswer`, `difficulty` |
| Special layouts needed | None beyond 4-option MCQ; occasional multiline stems |

### EQ (`eq_sets.json`)

| Attribute | Value |
|-----------|--------|
| Typical choices | **4** scenario MCQ with correct index |
| Images | None |
| Likert | **No** — same A/B/C/D chrome as IQ |
| Copy length | Longer stems/options than IQ (wrap-heavy TR) |
| Key fields | Same shape as IQ sets |
| Special layouts | Same MCQ family; need more vertical room for long options |

### Frequency (`frequency_sets.json`)

| Attribute | Value |
|-----------|--------|
| Typical choices | **5** Likert (UI chrome); JSON has **no** `options` |
| Images | None |
| Likert | **Yes** (1–5); `reverseScored` on subset |
| Dimensions | `depth`, `socialEnergy`, `spontaneity`, `stability`, `emotionalOpenness`, `conversationPace` (2 Q each per set) |
| Key fields | `id`, `question` `{en,tr}`, `dimension`, `reverseScored` |
| Special layouts | Distinct Likert + Back/Next; scroll risk on short phones |

### Summary: two UI families today

1. **4-option MCQ** — IQ + EQ (identical widget tree pattern)  
2. **5-option Likert** — Frequency only  

No image, matrix, formula, or multi-select renderers exist.

---

## 5. Protected behavior (must remain untouched in redesign)

### Scoring

- **IQ:** index vs remapped `correctAnswer`; `_correctAnswers`
- **EQ:** same + `ArchetypeCalculator.calculateArchetype(iq, eq, total)` → category
- **Frequency:** `FrequencyService.calculateResult` — normalize, reverse-score, 6D vector, type/tags — **do not change**

### Timers

None on any assessment screen.

### Persistence / Firestore

| What | Where |
|------|--------|
| Assignments | `users/{uid}/assessment_assignments/{iq\|eq\|frequency}` (`set_id`, `question_order`, IQ `option_orders`, `completed`, `score`, language) |
| IQ/EQ user results | `users/{uid}`: `test_completed`, `archetype`, `category`, `iq_score`, `eq_score`, normals via `AuthService.updateTestCompletion` |
| Frequency | `users/{uid}/assessments/frequency` + mirrors `frequency_completed`, `frequency_type`, `frequency_score`, `frequency_tags`, `frequency_vector` |

### Set selection (high risk)

- Shuffle `question_order` once per assignment
- **IQ-only** option permutations + `correctAnswer` remapping
- EQ/Frequency options stay canonical order
- Load: Firestore → assets → legacy
- Debug override: `QMATCH_DEBUG_FORCE_PILOT_ASSESSMENT_SETS`

### Localization

- Chrome: `app_en.arb` / `app_tr.arb`
- Content: JSON `en`/`tr` via `LocalizedTextResolver`
- Results: `AssessmentResultDisplayResolver`

### Resume

- **Assignment resumes** (same set + order)
- **In-progress answers do not resume** — restarting a screen resets to Q1

### Completion / gating

- `test_completed` only after EQ finishes
- Frequency gated via `frequency_completed`
- IQ: `FLAG_SECURE` (screenshot block); Frequency does not use it

### Do not touch in a UI pilot

Scoring formulas, set assignment, `option_orders`, Discover `frequency_vector` mirrors, `test_completed` gating logic.

---

## 6. Current UI weaknesses

| Area | Observation |
|------|-------------|
| Header | IQ/EQ question screens have **no AppBar/title** — progress only |
| Progress | IQ/EQ custom bar vs Frequency `LinearProgressIndicator` — inconsistent |
| Question / answers | No glass/card chrome; plain text + bordered rows |
| EQ copy | Long TR options cramped with 32px letter circle + tight padding |
| Nav | IQ/EQ: no in-app Back; system back can abandon mid-test |
| Frequency | 5 Likert + dual buttons without scroll → overflow risk on short devices |
| Loading / error | Spinner OK; empty set = text only, no retry; IQ/EQ completion errors mostly `debugPrint` |
| Intro | IQ intro large typography may overflow small phones; EQ intro unused |
| Cosmic DS | Assessment family still pre–Premium Cosmic Minimal |

---

## 7. Recommended pilot and reason

### Pilot: `EQTestIntroScreen` (presentation-only)

**Why:**

1. Pure chrome — **zero** scoring, assignment, or Firestore writes  
2. Currently **orphaned** — redesign/wire without touching live IQ→EQ jump risk  
3. Validates cosmic typography, bullets, CTA, small-screen spacing for the assessment family  

**Runner-up (live, still low risk):** `FrequencyIntroScreen` — already on `AuthWrapper` path, still no scoring.

**Avoid first:**

- `IQTestScreen` — option remapping + FLAG_SECURE + score path  
- `FrequencyTestScreen` finish — Discover-critical writes  
- Any change to `AssessmentSetService`

**Why not Frequency question UI as pilot:** cleaner UI, but finish/save touches Discover vectors. EQ MCQ chrome shares ~90% of IQ’s UI debt with less backend risk — better structural pilot after intro.

---

## 8. Proposed redesign phases

| Phase | Scope | Risk |
|-------|--------|------|
| **DS-3B** | Cosmic redesign of `EQTestIntroScreen` (and optionally wire between IQ dialog and EQ test) | Lowest |
| **DS-3C** | Extract shared MCQ shell (progress + option row + Next/Finish); apply to **EQ only** | Low–medium |
| **DS-3D** | Apply same shell to **IQ**; leave scoring / `option_orders` / FLAG_SECURE untouched | Medium |
| **DS-3E** | Frequency question chrome only (Likert + Back/Next + scroll); keep `_finish` / `calculateResult` | Medium |
| **DS-3F** | Result/completion dialogs (IQ→EQ, EQ archetype, Frequency result) — display only | Low |
| **Out of scope for UI** | Scoring, set assignment, Discover mirrors, gating flags | — |

---

## 9. Evidence anchors

- IQ advance / EQ handoff: `iq_test_screen.dart` → `EQTestIntroScreen`
- Set / option rules: `assessment_set_service.dart` header comments (`question_order`, IQ `option_orders`)
- Frequency Likert chrome: `frequency_test_screen.dart` → `_likertLabels(l10n)`
- Auth gating: `lib/core/navigation/auth_wrapper.dart`

---

## 10. Audit conclusion

Assessment UX is **two parallel UI families** (MCQ clone pair + Likert) with **shared data services** and **no shared widgets**. Safest redesign path: intro chrome → EQ MCQ shell → IQ MCQ → Frequency chrome → results — without touching scoring or set assignment.
