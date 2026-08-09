# EQ Pilot TR v1 Review Candidate 1 — Quality Report

**Form ID:** `eq_tr_pilot_v1_review_candidate_1`
**Content version:** `eq-tr-pilot-v1-review-candidate-1`
**Parent:** `eq-tr-pilot-v1`
**Runtime-loaded:** No
**Production readiness:** Not claimed

## Readiness layers

| Layer | Result |
|---|---|
| Structural validation | **PASS** (see candidate validator) |
| Internal red-team | **CONDITIONAL PASS** (no UNRESOLVED; reverse RVI service gap documented) |
| Expert psychological / measurement review | **pending** |
| Expert Turkish-language review | **pending** |
| Participant cognitive interviews | **pending** |
| Psychometric calibration | **pending** |

## Primary allocation after review

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

## Secondary-dimension appearances (item-level tags)

- `assertiveness`: 9
- `boundary_setting`: 9
- `conflict_approach`: 4
- `emotion_regulation`: 5
- `emotional_openness`: 3
- `empathy`: 7
- `perspective_taking`: 5
- `repair_orientation`: 6
- `self_awareness`: 3
- `social_awareness`: 8

## Verdict distribution

- PASS: 0
- PASS_WITH_MINOR_EDIT: 0
- EVIDENCE_REMAP: 30
- REWRITE: 0
- REPLACE: 0
- UNRESOLVED: 0

## Quality gates

| # | Gate | Result |
|---|---|---|
| 1 | Exactly 30 items | PASS |
| 2 | Four options each | PASS |
| 3 | No correct-answer fields | PASS |
| 4 | Canonical EQ dims only | PASS |
| 5 | No UNRESOLVED red-team items | PASS |
| 6 | No dominant/implausible options | PASS |
| 7 | Evidence strength contract applied | PASS |
| 8 | Flat 0.72 removed | PASS |
| 9 | Reverse polarity behaviorally keyed | PASS |
| 10 | empathy_003 SDR consistency | PASS |
| 11 | TraitScoringService accepts bank | PASS — validator/tests |
| 12 | Parent v1 unchanged | PASS |
| 13 | Not in pubspec / not runtime-loaded | PASS |
| 14 | Expert review | CONDITIONAL — pending |
| 15 | Participant testing | CONDITIONAL — pending |
| 16 | Calibration | CONDITIONAL — pending |
| 17 | Reverse RVI interpretability | CONDITIONAL — service gap |

## Overall

**CONDITIONAL** for continued internal iteration / expert review only. Not production-ready.

