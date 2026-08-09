# QMatch EQ Canonical Migration Audit v1

**Phase:** P2C-2A-7 (read-only audit + blocker decision)
**Date:** 2026-08-09
**Tip at audit:** `35b81c05fca108b12f95266b99b0da541694f969`

**Decision (updated after P2C-2A-7R2):**

```text
P2C-2A-7 = COMPLETE
P2C-2A-7R1 = COMPLETE
P2C-2A-7R2 = COMPLETE
```

Live path now uses `EqCanonicalRuntimeService` + TR/EN banks + `CanonicalEqScorer`
+ `EqTo20dRuntimeAdapter`. Legacy keyed path is retired from active new sessions.

Historical blocker codes below document the pre-R2 state.


---

## 1. Live EQ path (post R2)

```
AuthWrapper / IQ handoff → EQTestIntroScreen → EQTestScreen
  → EqCanonicalRuntimeService (TR/EN bank, 30-item session)
  → selectedOptionId answers (no correctAnswer)
  → CanonicalEqScorer
  → assessments/eq (qmatch_eq_10d_live_result_v1)
  → EqTo20dRuntimeAdapter → profiles/canonical_v1 (14/20)
  → FrequencyIntroScreen
```

### Pre-R2 legacy path (retired from new sessions)

```
EQTestScreen
  → QuestionService.loadEQAssessment
  → keyed MCQ (selected index == correctAnswer)
  → buildLegacyIqEqPayload
  → FrequencyIntroScreen
```

Files:

- `lib/features/assessment/screens/eq_test_intro_screen.dart`
- `lib/features/assessment/screens/eq_test_screen.dart`
- `lib/features/assessment/services/question_service.dart`
- `lib/features/assessment/services/assessment_set_service.dart`
- `lib/features/assessment/services/canonical_assessment_persistence.dart`
- `lib/features/assessment/services/assessment_progress_service.dart`

Persona is **not** revealed after EQ (explicit in `EQTestScreen._showResults`).

---

## 2. Question source

Live priority (`AssessmentSetService`):

1. Firestore active EQ set
2. Bundled `assets/data/assessment_sets/eq_sets.json` (50 × 10 = **500** items)
3. Legacy Firestore questions
4. Emergency flat `assets/data/eq_questions.json` (**12** EN-only items)

Offline (not pubspec / not live):

- `assets/data/assessment_v3/eq/eq_pilot_tr_v1.json` — 30 items, `tr-TR`
- `assets/data/assessment_v3/eq/eq_pilot_tr_v1_review_candidate_1.json` — 30 items

Quality report (`docs/core_engine/eq_pilot_tr_v1_quality_report.md`):

- **Runtime-loaded: No**
- **Production readiness: Not claimed**
- Expert psychological review: **pending**
- Cognitive interviews: **pending**
- Calibration: **uncalibrated**

---

## 3. Number of items

| Path | Count |
|------|------:|
| Live set session | **10** |
| Live bank (sets) | **500** |
| Offline canonical pilot | **30** |

---

## 4. Response scale

Live: 4-option MCQ with a single keyed `correctAnswer` (list **index** into displayed options).

Offline pilot: 4 options with stable `option_id` (`A`–`D`) and signed `dimension_deltas` + `evidence_strength` (behavioral trade-off, not correctness).

---

## 5. Existing dimensions (live vs canonical)

Live EQ produces **no** per-dimension scores (`dimension_scores: {}` in persistence builder; all 10 EQ IDs listed in `missing_dimensions`).

Canonical registry EQ IDs (exactly 10 — present and frozen):

```text
empathy
perspective_taking
self_awareness
emotion_regulation
emotional_openness
boundary_setting
assertiveness
conflict_approach
repair_orientation
social_awareness
```

Sources: `docs/core_engine/canonical_dimension_registry_v1.md`,
`CanonicalDimensions.eq`, `PersonaDimensionIds.eq`.

---

## 6. Scoring logic (live)

```dart
if (_selectedAnswer == question.correctAnswer) _correctAnswers++;
// persist raw_score / eq_score = correctCount
// eq_normalized = ArchetypeCalculator.normalizeScore(correctCount, n)
```

Mode label: `legacy_scoring_mode: "correct_answer_total"`.

This is **IQ-style accuracy**, contrary to the canonical EQ construct (behavioral tendency / trade-off; no socially obvious correct answer — registry).

---

## 7. Reverse-scoring behavior

Live: **none**.

Offline pilot: 5 reverse pairs (`behavioral_correspondence`) for RVI only; must not invert trait direction
(`docs/core_engine/reverse_pair_consistency_contract_v1.md`).

---

## 8. Current persistence

| Path | Content |
|------|---------|
| `users/{uid}/assessment_assignments/eq` | assignment + scalar score |
| `users/{uid}/assessments/eq` | legacy total + empty dimension maps; `canonical_profile_ready: false` |
| `users/{uid}` | `eq_completed`, `eq_score`, `eq_normalized` |
| `users/{uid}/profiles/canonical_v1` | IQ-only (4 dims) after P2C-2A-6; EQ not merged |

No answer-level capture of option IDs on the live path.

---

## 9. Locale coverage

| Asset | Locale |
|-------|--------|
| Live `eq_sets.json` | bilingual `label.en` / `label.tr` |
| Flat fallback | EN only |
| v3 pilot | `tr-TR` only; `en` fields = **"EN equivalent pending (tr-TR pilot reference; not a translation)."** (~150 stubs) |

Canonical TR/EN parity for EQ (as required for live IQ) is **not** available.

---

## 10. Onboarding dependency

EQ completion → `FrequencyIntroScreen` → Frequency. Sequence IQ → EQ → Frequency → Persona remains.

---

## 11. Canonical migration gaps (why BLOCKED)

### Gap A — Legacy cannot map

`docs/core_engine/current_assessment_bank_audit_v1.md`:

> EQ items use `correctAnswer` and lack canonical EQ dimensions → treat as **REWRITE** before persona handoff.

Live items have no `primary_dimension`, option IDs, signed deltas, evidence strengths, or reverse metadata. Mapping `eq_score` / correctCount into the 10 canonical dimensions would be **scientifically unsupported invention**.

Phase rule: *If they cannot validly populate the canonical ten dimensions: do not force the mapping.*

### Gap B — Offline scoring contract exists but is not a live migration path

Authoritative offline contracts:

- `TraitScoringService.scoreModule` (EQ formula: signed deltas → `[0,1]`)
- `docs/core_engine/eq_evidence_strength_contract_v1.md`
- `docs/core_engine/trait_scoring_engine_report_v1.md`
- Pilot bank + tests (`test/eq_pilot_v1_*`)

These convert **schema-v3 pilot responses**, not live keyed sets. Engine is offline/provisional/uncalibrated.

### Gap C — EN canonical bank absent

Pilot EN strings are explicit non-translations. Phase requires:

```text
EN EQ session → English canonical EQ content
```

Without inventing EN content or silently serving TR, live EN locale integrity cannot be satisfied for a pilot-based runtime.

### Gap D — Pilot not runtime-approved

Quality report: Runtime-loaded **No**; expert review **pending**; cognitive interviews **pending**; production readiness **not claimed**.

Promoting the pilot to live EQ in this phase would exceed P2C-2A-7’s “use existing authoritative contracts” boundary and contradict repository readiness labels.

### Gap E — No EqTo20d adapter / session architecture yet

No `EqTo20dRuntimeAdapter`, no EQ session composer/persistence analogous to IQ, no approved rollout policy to replace live keyed EQ.

---

## What would unblock a future P2C-2A-7 (or successor)

1. Canonical EQ bank approved for runtime (expert review + explicit promotion), **or** a documented rewrite of live items with full schema-v3 evidence maps.
2. Canonical **EN** EQ bank with structural parity to TR (real translations/localizations, not “pending” stubs).
3. Live runtime: stable `option_id` responses, TraitScoring (or successor) for 10 dims, session resume.
4. `EqTo20dRuntimeAdapter` merging into `users/{uid}/profiles/canonical_v1` while preserving IQ’s 4 dimensions; Frequency remains missing; `canonical_profile_ready=false`.
5. Explicit retirement of live `correct_answer_total` path for **new** sessions.

---

## Explicit non-actions taken in this phase

- Did **not** map `eq_score` → 10D
- Did **not** invent weights / reverse rules / normalization
- Did **not** fabricate EN translations as production content
- Did **not** wire persona / matching / quantum
- Did **not** mark EQ group complete
