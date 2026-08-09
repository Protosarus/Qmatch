# QMatch IQ Session Composer Audit v1

**Phase:** P2C-2A-2
**Constraint:** Live IQ selection/scoring was **not** modified.

---

## Current legacy selection behavior

```
IQTestIntroScreen
  → IQTestScreen._loadQuestions
    → QuestionService.loadIQAssessment
      → AssessmentSetService.getOrAssignSet(type: 'iq')
         • debug pilot override OR
         • existing assignment (persisted question_order / option_orders) OR
         • new: Random() active set + unseeded shuffle of IDs + unseeded option perms
    → QuestionModel MCQ (typically 10 items; correctAnswer = list index)
```

| Fact | Value |
|------|-------|
| Live item count | **10** (fixed set) |
| Seeded selection | **none** |
| Family uniqueness | **none** at runtime |
| Answer identity | **list index** (`correctAnswer`) |
| Canonical bank | offline only (`iq_bank_tr_v1.json`) |

---

## Reusable deterministic utilities (pre-existing)

| Utility | Role for P2C-2A-2 |
|---------|-------------------|
| `RobustnessRng` (CM v2 tools) | Pattern reference only — not imported |
| Pilot test `Random(seed)` fixtures | Answer fixtures only — not selection |
| New `IqDeterministicRng` | **Adopted** — FNV-1a + xorshift32 |

---

## Unsafe random / index identity (must stay untouched until migration)

- `AssessmentSetService._pickRandomActiveSet` — unseeded `Random()`
- `_buildShuffledQuestionIds` / `_buildOptionPermutationsForMcq` — unseeded
- `QuestionModel.correctAnswer` index remapping after option shuffle
- `IQTestScreen` index equality scoring

---

## Duplicate / family protections today

| Layer | Protection |
|-------|------------|
| Live sets | None for `template_family_id` |
| Offline recovered bank validator | 170 families × 2 variants |
| **New composer (this phase)** | ≤1 family per session + final invariant |

---

## Code that must remain untouched until runtime migration

1. `lib/features/assessment/services/assessment_set_service.dart`
2. `lib/features/assessment/services/question_service.dart`
3. `lib/features/assessment/screens/iq_test_screen.dart`
4. Bundled `assets/data/assessment_sets/iq_sets.json` / `iq_questions.json`
5. Assignment / progress / canonical persistence write paths
6. Trait scoring / IQ result screens

Safe parallel work: `lib/features/assessment/domain/iq_session/**`, tools, tests, docs.
