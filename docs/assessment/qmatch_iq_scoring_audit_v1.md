# QMatch IQ Scoring Audit v1

**Phase:** P2C-2A-4
**Constraint:** Live IQ scoring/behavior was **not** modified.

---

## Current live scoring formula

| Step | Behavior |
|------|----------|
| Selection | `QuestionService.loadIQAssessment` → fixed assigned 10-item set |
| Correctness | `_selectedAnswer == question.correctAnswer` where both are **list indices** |
| Aggregation | Running integer `_correctAnswers` (correct-count) |
| Output | Integer `0..questionCount` (typically 0..10) |

No per-dimension scoring. No option-ID identity.

## Current output scale

- Raw correct count integer.
- Field names include `iq_score` / `raw_score` / `correct_count`.
- **Not** a standardized IQ, percentile, or norm-referenced metric — but the field name `iq_score` implies "IQ" colloquially.

## Current persistence fields

Via `CanonicalAssessmentPersistence.buildLegacyIqEqPayload` + `AssessmentProgressService.markIqCompleted`:

- `raw_score`, `performance_summary.correct_count`
- `users/{uid}.iq_score` mirror
- empty `dimension_scores`
- `trait_scoring_version` = `trait_unscored_legacy_total`
- `canonical_profile_ready: false`

## Current runtime consumers

| Consumer | Use of IQ value |
|----------|-----------------|
| `IQTestScreen` → `EQTestIntroScreen(iqScore:)` | Passes correct-count forward |
| `AssessmentProgressService` | Completion gate + optional raw mirror |
| `CanonicalAssessmentPersistence.recoverIqResult` | Recovery of raw count |
| Discover / compatibility | **No direct IQ score dependency found** in discover package |
| `TraitScoringService` | Offline only; **not** called by IQTestScreen |
| Core Method v2 | Offline only; not wired |

## Legacy assumptions

- 10 MCQ items with index-based correctness.
- Single scalar total.
- Dimension list present only as `missing_dimensions` (IQ dimensions listed as missing).

## Does live code call the score "IQ"?

Yes, in naming: `iq_score`, `iqScore` parameters, screen names. Scientifically it is a **raw correct count**, not a calibrated IQ.

## Is any current result norm-referenced?

**No.** No population norms, percentiles, or IRT parameters in the live path.

## Risks when later replacing with canonical 4D scoring

1. Field `iq_score` may be misread as standardized IQ.
2. Index-based correctness is incompatible with shuffled option-ID sessions.
3. Downstream EQ intro expects an `int iqScore` — needs explicit migration.
4. Empty `dimension_scores` must not be filled with fabricated calibrated values.
5. Discover must not treat provisional [0,1] accuracies as IQ percentiles.

---

## Offline canonical scorer (this phase)

`IqCanonicalScorer` / `iq_4d_uncalibrated_accuracy_v1` produces four uncalibrated
dimension accuracies. **Not** wired to live UI or Firestore.
