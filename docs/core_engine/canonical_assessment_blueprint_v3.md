# Canonical Assessment Blueprint v3

**Status:** measurement architecture freeze (P2A-1) — provisional targets, not psychometric norms  
**Consumes:** `canonical_dimension_registry_v1`  
**Produces input for:** pure `PersonaScoringService` (not production-wired in this phase)  
**Session targets (provisional):** IQ 25 · EQ 30 · Frequency 50 · Adaptive separators 0–8  

---

## 1. Purpose of IQ, EQ, and Frequency

| Module | Purpose |
|---|---|
| **IQ** | Estimate four cognitive-style domain signals with keyed correctness for reliability and optional hard eligibility later |
| **EQ** | Estimate ten interpersonal/emotional-process dimensions from behavioral trade-off evidence |
| **Frequency** | Estimate six observable connection-rhythm preferences that dominate persona/matching weight |

Together they form a **versioned 20D profile** (`dimension_scores` + evidence + reliability + RVI), not a persona label and not a compatibility score.

## 2. What each module measures

- **IQ:** logical_reasoning, pattern_reasoning, verbal_reasoning, spatial_reasoning  
- **EQ:** empathy, perspective_taking, self_awareness, emotion_regulation, emotional_openness, boundary_setting, assertiveness, conflict_approach, repair_orientation, social_awareness  
- **Frequency:** depth_preference, social_energy, spontaneity, stability, disclosure_pace, communication_pace  

## 3. What each module must not claim

| Module | Must not claim |
|---|---|
| IQ | Wisdom, morality, leadership quality, creativity-as-personality, “smarter person” ranking for dating value |
| EQ | Mentally healthy/unhealthy, morally good/bad partner, clinical diagnosis, single “correct” relationship ethic |
| Frequency | Aura, physical vibration, spiritual superiority, destiny, romantic fate, intelligence |

## 4. Canonical question count (session)

| Phase | Count | Notes |
|---|---|---|
| IQ core | **25** | Fixed session size |
| EQ core | **30** | Fixed session size |
| Frequency core | **50** | Fixed session size |
| Adaptive separators | **0–8** | Only when top personas are near-tied; may remain unused |

## 5. Expected completion time (provisional)

| Module | Est. minutes | Notes |
|---|---|---|
| IQ | 12–18 | Depends on difficulty mix |
| EQ | 10–15 | Scenario reading time dominates |
| Frequency | 12–18 | Shorter stems, higher count |
| Separators | 0–6 | Only if triggered |
| **Total** | **~35–55** | Modules may be completed separately |

## 6. Core-item structure

Every session item has: stable `question_id`, module, schema/content versions, locale texts, `primary_dimension`, optional controlled `secondary_dimensions`, options or Likert contract, exposure class, review status.

## 7. Anchor-item structure

Anchors are **stable, reviewed items** shared across comparable forms for equating and drift checks.

- IQ: ≥4 anchors / form (one per domain preferred)  
- EQ: ≥6 anchors / form across families  
- Frequency: ≥6 anchors / form (one per dimension preferred)  

Anchors are never the sole determinant of a dimension score.

## 8. Semantic-pair structure

Paired items with near-equivalent meaning used for RVI semantic consistency. Pairs share `semantic_pair_id`. Scoring uses both for traits; RVI compares response agreement after reverse/keying rules.

## 9. Reverse-item structure

Items or options that load a dimension in the opposite direction (`reverse_pair_id` / reverse deltas). Required for EQ/Frequency to reduce acquiescence. IQ does not use Likert reverse; distractors are not “reverse traits.”

## 10. Behavioral-isomorph structure

Different surface stories measuring the same construct (`behavioral_isomorph_group`). Used for construct coverage and RVI repeated-context stability without near-duplicate wording.

## 11. Response-validity structure

RVI uses designated roles (semantic, reverse, timing, person-fit, variation, impression risk, stability). RVI affects **confidence / publishability / retest / matching eligibility**, never trait direction as punishment. See `response_validity_item_blueprint_v1.md`.

## 12. Adaptive-separator structure

After core modules, if persona top-2 margin is low, select up to 8 information-value items targeting separator dimensions between competing personas. Never ask persona-label identity questions. User may remain ambiguous. See `adaptive_separator_blueprint_v1.md`.

## 13. Dimension-coverage requirements

| Module | Rule |
|---|---|
| IQ | All 4 domains present in every 25-item form |
| EQ | All 10 dimensions have ≥1 primary item in session; secondary evidence distributed |
| Frequency | All 6 dimensions have ≥6 primary measurements in the 50-item session plan |

## 14. Minimum evidence per dimension (provisional)

Aligned with dimension registry intent; session plan must meet or exceed:

| Group | Min independent evidence before dimension may be “present” |
|---|---|
| IQ domains | ≥3 keyed items (research); ≥4 before individual domain feedback |
| EQ dims | ≥3 primary-equivalent evidence units |
| Frequency dims | ≥3 primary-equivalent evidence units |

Missing evidence stays missing (never 0 / 0.5 / 0.42).

## 15. Reliability requirements (provisional)

- Per-dimension reliability estimate in `[0,1]` when computable; omit if unknown  
- Form-level reporting may use internal consistency proxies in pilot; no percentile claims without norms  
- Low reliability lowers confidence / may mark dimension missing for persona input

## 16. Missing-data behavior

- Unanswered / void items → no score contribution  
- Dimension absent from `dimension_scores` + listed in `missing_dimensions`  
- Module incomplete → assessment `status: incomplete` / not persona-eligible  
- Never invent neutral trait values

## 17. Localization requirements

- Every active item has reviewed `tr` and `en` prompts/options  
- Locale-equivalent meaning, not literal-only translation  
- IQ answers must remain uniquely keyed across locales  
- No culture-specific untranslatable traps without review flag

## 18. Item-exposure policy

Classes: `core_pool`, `anchor`, `separator`, `pilot`, `secure_iq`.  
Limits on reuse per user/window; IQ secure items have stricter exposure and logging controls.

## 19. Versioning policy

Every administered session stores:

- `question_schema_version`  
- `content_version`  
- `scoring_version`  
- `normalization_version`  
- `assessment_version`  
- `set_id` / `question_order`

Same inputs + versions ⇒ same outputs.

## 20. Retake policy (provisional)

- Module-level retake allowed after cooldown  
- Prior completed docs become `superseded`, not silently overwritten  
- High RVI risk may require guided retest without trait punishment  
- Persona recompute only when all required modules meet evidence rules

## 21. Scoring-input contract (to trait engine)

For each module completion, emit fields compatible with `assessment_result_contract_v1` and `PersonaScoringInput`:

- `dimension_scores` (present only)  
- `dimension_evidence_counts`  
- `dimension_reliability`  
- `missing_dimensions`  
- `response_validity` / `responseValidityStatus`  
- version fields  

## 22. PersonaScoringService handoff contract

1. Build merged 20D profile from IQ+EQ+Frequency docs (no persona from IQ total alone).  
2. Call pure `PersonaScoringService` offline/shadow only until product gates pass.  
3. Preserve ambiguity / insufficientEvidence; never force persona.  
4. Similarity ≠ probability; confidence separate.  
5. Adaptive separators may add evidence then re-score; still may remain ambiguous.

---

## Non-negotiable design rules

1. IQ may have objectively correct answers.  
2. EQ and Frequency have **no morally correct answers**.  
3. No EQ/Frequency option may transparently be the socially desirable “good person” choice.  
4. No single item may determine a persona.  
5. Persona names must not appear in items.  
6. Dimension scores are continuous and non-moral.  
7. Missing evidence is not a neutral score.  
8. Response validity affects publishability/confidence, not trait direction.

## IQ blueprint summary (25)

| Domain | Core items |
|---|---|
| logical_reasoning | 7 |
| pattern_reasoning | 6 |
| verbal_reasoning | 6 |
| spatial_reasoning | 6 |
| **Total** | **25** |

Also emit legacy-compatible `performance_summary.correct_count` without using it as persona identity.

## EQ blueprint summary (30)

Mixed-loading: each item one primary dimension; controlled secondary deltas; 10 scenario families; every dimension gets primary + secondary coverage in bank/session plan (see detailed EQ section in companion docs / bank plan).

## Frequency blueprint summary (50)

≥6 strong primary items per dimension in session allocation, plus cross-trade-off and reverse/isomorph evidence. Observable rhythms only.

## Machine-readable companion

`assets/schemas/canonical_assessment_blueprint_v3.json` encodes session counts and domain allocations for contract tests.

---

## Appendix A — IQ measurement blueprint (25 core)

### Domain allocation

| Domain | Items | Anchor target / form | Difficulty bands (provisional mix) |
|---|---:|---:|---|
| logical_reasoning | 7 | ≥1 | 2 easy · 3 mid · 2 hard |
| pattern_reasoning | 6 | ≥1 | 2 easy · 2 mid · 2 hard |
| verbal_reasoning | 6 | ≥1 | 2 easy · 2 mid · 2 hard |
| spatial_reasoning | 6 | ≥1 | 2 easy · 2 mid · 2 hard |

### Distractor-design requirements

- Exactly one keyed correct option.
- Distractors must follow documented `distractor_logic` (common error class).
- No “joke” options; no culturally gated knowledge unless flagged.
- Option count: 4 for MCQ forms.

### Correct-answer & solution-method contract

- `correct_option_id` required (stable id, not presentation index alone).
- `solution_method` required for review (rule chain / pattern / verbal inference / spatial transform).
- Locale parity: same keyed option meaning in TR/EN.

### Item-security & exposure

- Classes: `secure_iq` for high-stakes keyed items; rotate sets; limit per-user reuse.
- Comparable forms: shared anchors; controlled overlap ≤20% non-anchor between adjacent forms.
- Timing metadata: `estimated_completion_seconds` per item; form-level soft timer optional later.
- Provisional discrimination metadata: `estimated_discrimination` hypothesis only until calibration.

### Minimum items per domain

- Session: as allocated above.
- Present-for-persona: ≥3 evidence units; individual feedback: ≥4.

### IQ outputs

- `performance_summary.correct_count` / attempted (legacy/reporting only)
- four domain scores in `[0,1]` when present
- evidence counts + reliability per domain
- versions: question/set/content/scoring/normalization

**IQ total must not determine persona identity.**

---

## Appendix B — EQ measurement blueprint (30 core)

### Design principles

- Mixed loading: one `primary_dimension`; optional controlled secondaries.
- Every option emits signed `dimension_deltas` in `[-1,1]`.
- No globally best option; realistic trade-offs with costs.
- No `correctAnswer` / persona points / grid IDs.

### Required item families (cover across bank; session samples ≥6 families)

1. Interpersonal scenarios  
2. Internal emotional scenarios  
3. Boundary and assertiveness conflicts  
4. Repair-after-conflict scenarios  
5. Perspective-taking scenarios  
6. Emotional-disclosure scenarios  
7. Social-awareness scenarios  
8. Stress-regulation scenarios  
9. Competing-value scenarios  
10. Behavioral-frequency scenarios  

### Social-desirability reduction

Balanced plausible options · real trade-offs · context variation · cost-bearing choices · indirect wording · semantic pairs · behavioral isomorphs · reverse-direction evidence · no obviously cruel or idealized option.

### Per-dimension plan (session + bank)

| Dimension | Primary in session (min) | Secondary evidence (session) | Families | Reverse | Contamination risks | Helps separate |
|---|---:|---:|---|---|---|---|
| empathy | 3 | ≥2 | 1,2,6 | yes | vs repair-only action | empat/sifaci, empat/sezgisel |
| perspective_taking | 3 | ≥2 | 5,7,9 | yes | vs verbal IQ fluency | bilge/analist, yargic/analist |
| self_awareness | 3 | ≥2 | 2,8,9 | yes | vs social performance | bilge/analist |
| emotion_regulation | 3 | ≥2 | 8,3,4 | yes | vs suppression-as-virtue | empat/sifaci, cesur/kararli |
| emotional_openness | 3 | ≥2 | 6,2,1 | yes | vs disclosure_pace (Frequency) | empat/iletisimci |
| boundary_setting | 3 | ≥2 | 3,9,4 | yes | vs coldness stereotype | koruyucu/muhafiz, bagimsiz/sezgisel |
| assertiveness | 3 | ≥2 | 3,9,1 | yes | vs aggression | lider/vizyoner, cesur/kararli |
| conflict_approach | 3 | ≥2 | 3,4,9 | yes | vs hostility | muhafiz/koruyucu, cesur/donusturucu |
| repair_orientation | 3 | ≥2 | 4,1,6 | yes | vs apology theater | empat/sifaci, koruyucu/sifaci |
| social_awareness | 3 | ≥2 | 7,5,1 | yes | vs people-pleasing | sezgisel/bagimsiz, lider/iletisimci |

Session total primaries ≈ 30 (about 3 primary slots × 10 dims). Secondaries are additional loadings on the same 30 items, not extra questions.

---

## Appendix C — Frequency measurement blueprint (50 core)

### What Frequency measures

Observable connection patterns: interaction depth preference, social stimulation, planning vs spontaneity, rhythm consistency, emotional disclosure speed, communication tempo.

### What Frequency must not measure

Aura · physical vibration · spiritual superiority · destiny · romantic fate · intelligence.

### Session allocation (provisional)

| Dimension | Strong primary items | Cross-trade-off share | Notes |
|---|---:|---:|---|
| depth_preference | 8 | shared | vs small-talk preference |
| social_energy | 8 | shared | selective ≠ defective |
| spontaneity | 8 | shared | low ≠ rigid-as-moral |
| stability | 9 | shared | high ≠ better partner |
| disclosure_pace | 8 | shared | ≠ EQ emotional_openness |
| communication_pace | 9 | shared | tempo ≠ empathy |
| **Total** | **50** | | |

### Per-dimension detail

| Dimension | Scenario families | Reverse | Biases | Separates | Matching / expectation |
|---|---|---|---|---|---|
| depth_preference | early-talk depth, topic steering | surface-chat comfort | depth-as-superiority | bilge/iletisimci | conversation expectation |
| social_energy | group vs dyad, recovery need | high-stimulation enjoy | introversion stigma | bagimsiz/lider | activity pace |
| spontaneity | plan-break, last-minute yes | schedule preference | spontaneity-as-fun-only | cesur/kararli, uygulayici | date planning |
| stability | routine keep, mood-rhythm | flexible reset | stability-as-boring | kararli/cesur | reliability expectation |
| disclosure_pace | share timing, vulnerability speed | slow reveal | overshare pressure | empat/sifaci | intimacy pacing |
| communication_pace | reply tempo, message length | slow deliberate | ghosting moralizing | iletisimci/bilge | texting expectation |

**disclosure_pace (Frequency) ≠ emotional_openness (EQ).** Do not mix constructs.
