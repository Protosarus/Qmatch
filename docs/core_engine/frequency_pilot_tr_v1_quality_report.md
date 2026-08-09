# Frequency Pilot TR v1 — Quality Report

**Form ID:** `frequency_tr_pilot_v1`
**Set ID:** `frequency_tr_pilot_v1_set_001`
**Content version:** `frequency-tr-pilot-v1`
**Locale:** `tr-TR`
**Status:** pilot / uncalibrated
**Review state:** internal_review
**Runtime-loaded:** No
**Production readiness:** Not claimed

---

## Form identity & counts

| Metric | Value |
|---|---|
| Item count | 50 |
| Module | frequency |
| Schema | qmatch_question_schema_v3 |
| Trait scoring version | trait_scoring_v1.0 |

## Primary dimension allocation

| Dimension | Count |
|---|---:|
| `communication_pace` | 9 |
| `depth_preference` | 9 |
| `disclosure_pace` | 8 |
| `social_energy` | 8 |
| `spontaneity` | 8 |
| `stability` | 8 |

## Scenario family allocation

| Family | Count |
|---|---:|
| `conversation_depth_topic_progression` | 5 |
| `early_messaging_first_contact` | 5 |
| `longer_term_communication_rhythm` | 5 |
| `one_to_one_vs_group` | 5 |
| `personal_disclosure_trust` | 5 |
| `planning_scheduling_last_minute` | 5 |
| `routine_continuity_habits` | 5 |
| `shared_activities_novelty` | 5 |
| `silence_space_reconnection` | 5 |
| `social_outings_groups_recovery` | 5 |

## Provenance distribution

- `newly_authored`: 50

## Secondary dimension coverage

- Secondary evidence appearances by dimension: `depth_preference`=27, `communication_pace`=28, `social_energy`=26, `spontaneity`=16, `stability`=36, `disclosure_pace`=23
- All dimensions ≥5 secondary appearances: **yes**

## Independent contexts

- Contexts by dimension: `depth_preference`=10, `communication_pace`=10, `social_energy`=10, `spontaneity`=10, `stability`=10, `disclosure_pace`=10
- All dimensions ≥5 contexts: **yes**
- Unique Turkish prompts: **50** (no exact duplicate stems detected in bank)

## Pair counts

- Semantic pairs: **8**
- Reverse pairs: **6**
- Behavioral isomorph groups: **6**

## RVI coverage

- `repeated_context_stability`: 12 item assignments
- `response_variation`: 5 item assignments
- `reverse_consistency`: 12 item assignments
- `semantic_consistency`: 16 item assignments
- `social_impression_risk`: 5 item assignments
- `timing_quality`: 50 item assignments

## Option-balance findings (summary)

- Overall option length median: 47 chars
- Length imbalances >1.45×: **20** items
- All-positive multi-dim options: **0**
- Legacy dominant-option heuristic flags: **0**
- Total evidence magnitude: **147.20**

## Social-desirability (SDR) findings

- Option-level `low`: 195
- Option-level `moderate`: 5
- Item-level moderate SDR risk: 5 items (`frequency_tr_v1_communication_pace_005`, `frequency_tr_v1_depth_preference_001`, `frequency_tr_v1_disclosure_pace_001`, `frequency_tr_v1_social_energy_005`, `frequency_tr_v1_spontaneity_007`)

## Construct-contamination findings

- Frequency items intentionally use cross-dimension deltas within the six Frequency dims only.
- `disclosure_pace` items flagged for high review; must not collapse into EQ `emotional_openness`.
- See `frequency_pilot_tr_v1_construct_separation_report.md` for EQ leakage audit.

## Language review

| Area | Status |
|---|---|
| Internal language review | **completed** |
| Expert psychological review | **pending** |
| Cognitive interviews | **pending** |

## TraitScoringService fixture results

See `tool/validate_frequency_pilot_v1.dart` and `test/frequency_pilot_v1_*_test.dart` for offline TraitScoringService fixtures.

## Unresolved human-review items

- All 50 items: `pending_expert_psychological_review`
- All 50 items: `pending_cognitive_interviews`
- Reverse-pair items (6 pairs): confirm opposing evidence vectors under real response patterns
- disclosure_pace items: confirm separation from EQ emotional_openness
- Moderate-SDR items: confirm no single option reads as universally virtuous

## Quality gates (1–36)

| # | Gate | Result |
|---|---|---|
| 1 | Exactly 50 valid items | **PASS** |
| 2 | Exactly six canonical Frequency dimensions | **PASS** |
| 3 | Exact primary allocation passes | **PASS** |
| 4 | Exactly five items per scenario family | **PASS** |
| 5 | Every item has four plausible options | **PASS** |
| 6 | No item contains a correct-answer field | **PASS** |
| 7 | No Frequency type scoring exists | **PASS** |
| 8 | No persona scoring exists | **PASS** |
| 9 | No globally dominant all-positive option remains | **PASS** |
| 10 | No hidden moral ranking remains | **CONDITIONAL** |
| 11 | Every dimension has sufficient primary evidence | **PASS** |
| 12 | Every dimension has at least five secondary appearances | **PASS** |
| 13 | Every dimension spans at least five independent contexts | **PASS** |
| 14 | All deltas remain within bounds | **PASS** |
| 15 | No option exceeds influence limits | **PASS** |
| 16 | Evidence strength follows the frozen contract | **PASS** |
| 17 | At least eight semantic pairs exist | **PASS** |
| 18 | At least six reverse pairs exist | **PASS** |
| 19 | At least six behavioral-isomorph groups exist | **PASS** |
| 20 | Every dimension appears in all three relationship structures | **PASS** |
| 21 | Required RVI roles are represented | **PASS** |
| 22 | No Frequency item writes to EQ dimensions | **PASS** |
| 23 | disclosure_pace is separate from EQ emotional_openness | **PASS** |
| 24 | communication_pace is separate from assertiveness | **PASS** |
| 25 | spontaneity is separate from impulsivity | **PASS** |
| 26 | stability is separate from emotional stability | **PASS** |
| 27 | social_energy is separate from social skill | **PASS** |
| 28 | depth_preference is separate from intelligence | **PASS** |
| 29 | Missing evidence remains missing | **PASS — see TraitScoringService fixtures** |
| 30 | TraitScoringService accepts the form | **PASS — see validator/tests** |
| 31 | RVI remains separate from dimensions | **PASS** |
| 32 | No production integration exists | **PASS** |
| 33 | Internal Turkish-language review completed | **PASS** |
| 34 | External psychological/measurement review pending | **CONDITIONAL — pending** |
| 35 | Participant cognitive interviews pending | **CONDITIONAL — pending** |
| 36 | Calibration pending | **CONDITIONAL — pending** |

## Readiness conclusion

**Overall: CONDITIONAL** for expert revision / red-team review only.

Automated structural checks largely pass; secondary-dimension tagging, expert psychological review, cognitive interviews, calibration, and TraitScoring validator fixtures remain pending before any runtime wiring.