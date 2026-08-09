# EQ Pilot TR v1 — Quality Report

**Form ID:** `eq_tr_pilot_v1`
**Set ID:** `eq_tr_pilot_v1_set_001`
**Content version:** `eq-tr-pilot-v1`
**Locale:** `tr-TR`
**Status:** pilot / uncalibrated
**Review state:** internal_review
**Runtime-loaded:** No
**Production readiness:** Not claimed

---

## Form identity & counts

| Metric | Value |
|---|---|
| Item count | 30 |
| Module | eq |
| Schema | qmatch_question_schema_v3 |
| Trait scoring version | trait_scoring_v1.0 |

## Primary dimension allocation

| Dimension | Count |
|---|---:|
| `assertiveness` | 3 |
| `boundary_setting` | 3 |
| `conflict_approach` | 3 |
| `emotion_regulation` | 3 |
| `emotional_openness` | 3 |
| `empathy` | 3 |
| `perspective_taking` | 3 |
| `repair_orientation` | 3 |
| `self_awareness` | 3 |
| `social_awareness` | 3 |

## Scenario family allocation

| Family | Count |
|---|---:|
| `boundary_and_request_conflicts` | 3 |
| `competing_values_and_tradeoffs` | 3 |
| `emotional_disclosure` | 3 |
| `internal_emotional_awareness` | 3 |
| `interpersonal_support` | 3 |
| `perspective_taking_family` | 3 |
| `repair_after_disagreement` | 3 |
| `repeated_behavioral_patterns` | 3 |
| `social_context_awareness` | 3 |
| `stress_and_regulation` | 3 |

## Provenance distribution

- `adapted_from_legacy_scenario`: 3
- `newly_authored`: 26
- `substantially_rewritten_legacy_concept`: 1

## Secondary dimension coverage

- Secondary evidence appearances by dimension: `empathy`=8, `perspective_taking`=6, `self_awareness`=4, `emotion_regulation`=8, `emotional_openness`=4, `boundary_setting`=13, `assertiveness`=9, `conflict_approach`=12, `repair_orientation`=7, `social_awareness`=7
- All dimensions ≥2 secondary appearances: **yes**

## Independent contexts

- Contexts by dimension: `empathy`=4, `perspective_taking`=6, `self_awareness`=3, `emotion_regulation`=7, `emotional_openness`=4, `boundary_setting`=8, `assertiveness`=6, `conflict_approach`=10, `repair_orientation`=6, `social_awareness`=6
- All dimensions ≥3 contexts: **yes**
- Unique Turkish prompts: **30** (no exact duplicate stems detected in bank)

## Pair counts

- Semantic pairs: **6**
- Reverse pairs: **5**
- Behavioral isomorph groups: **5**

## RVI coverage

- `repeated_context_stability`: 10 item assignments
- `response_variation`: 5 item assignments
- `reverse_consistency`: 10 item assignments
- `semantic_consistency`: 12 item assignments
- `social_impression_risk`: 5 item assignments
- `timing_quality`: 30 item assignments

## Option-balance findings (summary)

- Overall option length median: 68 chars
- Length imbalances >1.45×: **3** items
- All-positive multi-dim options: **0**
- Legacy dominant-option heuristic flags: **24**
- Total evidence magnitude: **73.14**

## Social-desirability (SDR) findings

- Option-level `low`: 114
- Option-level `moderate`: 6
- Item-level moderate SDR risk: 5 items (`eq_tr_v1_assertiveness_002`, `eq_tr_v1_emotional_openness_001`, `eq_tr_v1_empathy_001`, `eq_tr_v1_repair_orientation_001`, `eq_tr_v1_social_awareness_001`)

## Construct-contamination findings

- EQ items intentionally use cross-dimension deltas; expert review must confirm primary construct purity.
- Items with openness/boundary/assertiveness overlap flagged for high human review in evidence mapping.

## Language review

| Area | Status |
|---|---|
| Internal language review | **completed** |
| Expert psychological review | **pending** |
| Cognitive interviews | **pending** |

## TraitScoringService fixture results

See `tool/validate_eq_pilot_v1.dart` and `test/eq_pilot_v1_*_test.dart` for offline TraitScoringService fixtures.

## Unresolved human-review items

- All 30 items: `pending_expert_psychological_review`
- All 30 items: `pending_cognitive_interviews`
- Reverse-pair items (5 pairs): confirm opposing evidence vectors under real response patterns
- Moderate-SDR items: confirm no single option reads as universally virtuous

## Quality gates (1–24)

| # | Gate | Result |
|---|---|---|
| 1 | Exactly 30 valid items | **PASS** |
| 2 | 3 primary items per EQ dimension (10 dims) | **PASS** |
| 3 | 3 items per scenario family (10 families) | **PASS** |
| 4 | Four options per item | **PASS** |
| 5 | No correct / keyed answer fields | **PASS** |
| 6 | No globally dominant all-positive option remains | **PASS** |
| 7 | Sufficient planned primary evidence (3/dim) | **PASS** |
| 8 | Every dimension has ≥2 secondary evidence appearances | **PASS** |
| 9 | Every dimension spans ≥3 independent contexts | **PASS** |
| 10 | Deltas within expected bounds | **PASS** |
| 11 | No option exceeds influence limits (≤3 dims, L1≤1.40) | **PASS** |
| 12 | ≥6 semantic pairs | **PASS** |
| 13 | ≥5 reverse pairs | **PASS** |
| 14 | ≥5 behavioral isomorph groups | **PASS** |
| 15 | Required RVI roles represented | **PASS** |
| 16 | No persona or legacy grid scoring | **PASS** |
| 17 | Missing evidence remains missing | **PASS** |
| 18 | TraitScoringService accepts the form | **PASS — see validator/tests** |
| 19 | RVI remains separate from traits | **PASS** |
| 20 | No production integration exists | **PASS** |
| 21 | Internal language review completed | **PASS** |
| 22 | External psychological/measurement review explicitly pending | **CONDITIONAL — pending** |
| 23 | Participant cognitive interviews explicitly pending | **CONDITIONAL — pending** |
| 24 | Calibration explicitly pending | **CONDITIONAL — pending** |

## Readiness conclusion

**Overall: CONDITIONAL** for expert revision / red-team review only.

Automated structural checks largely pass; secondary-dimension tagging, expert psychological review, cognitive interviews, calibration, and TraitScoring validator fixtures remain pending before any runtime wiring.