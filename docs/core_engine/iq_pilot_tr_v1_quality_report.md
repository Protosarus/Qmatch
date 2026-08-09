# IQ Pilot TR v1 — Quality Report (P2A-2B-1)

**Form ID:** `iq_tr_pilot_v1`  
**Set ID:** `iq_tr_pilot_v1_set_001`  
**Content version:** `iq-tr-pilot-v1`  
**Locale:** `tr-TR`  
**Status:** pilot / uncalibrated  
**Runtime-loaded:** **No**  
**Production readiness:** **Not claimed**

---

## Summary counts

| Metric | Value |
|---|---|
| Item count | 25 |
| Domain allocation | logical 7 / pattern 6 / verbal 6 / spatial 6 |
| Difficulty (hypotheses) | easy 8 / medium 12 / hard 5 (encoded 2/3/4) |
| Correct-option positions | A7 / B6 / C6 / D6 |
| Max consecutive correct letter | 1 |
| Anchors | 4 (one per domain, medium) |
| Provenance | newly_authored 25 / adapted 0 / retained 0 |

## Item-type distribution

All 25 items: `mcq_keyed`.

## Anchor items

| Domain | Question ID | Anchor group |
|---|---|---|
| logical_reasoning | `iq_tr_v1_logical_003` | `iq_tr_v1_anchor_logical` |
| pattern_reasoning | `iq_tr_v1_pattern_003` | `iq_tr_v1_anchor_pattern` |
| verbal_reasoning | `iq_tr_v1_verbal_003` | `iq_tr_v1_anchor_verbal` |
| spatial_reasoning | `iq_tr_v1_spatial_003` | `iq_tr_v1_anchor_spatial` |

## Duplicate / near-duplicate

- Exact duplicate prompts: **none**
- High-risk near-duplicates (exact / Jaccard≥0.95 on contentful tokens): **none**
- Automated near-duplicate scan: deterministic via `tool/validate_iq_pilot_v1.dart`

## Language and cultural review

| Area | Status |
|---|---|
| Turkish clarity | **PENDING** expert language review |
| Verbal locale equivalents | Documented as required (no literal EN translation authored) |
| EN `prompt`/`option` fields | Schema stubs only |
| Cultural-bias risks | Low–moderate on verbal/spatial wording; expert review pending |
| Political/religious/medical judgment stems | Avoided by design |

## Security / exposure

- `exposure_class`: `pilot` or `anchor`
- `security_level`: `standard`
- Not listed in `pubspec.yaml`
- Not imported by live IQ screens/services

## TraitScoringService fixture results (offline)

| Fixture | Result |
|---|---|
| All correct | 1.0 × 4 domains; legacyRawScore=25 |
| All incorrect | 0.0 × 4 domains; legacyRawScore=0 |
| One correct per domain | Domain scores independent, in (0,1) |
| One domain unanswered | Domain unpublished / missing; not 0/0.5/0.42 |
| Alternating / seeded random / always-A | Finite scores in [0,1] |
| Duplicate / unknown response | Explicit validation failure |
| Incomplete status | `ModuleTraitStatus.incomplete` |
| Persona auto-calc | **Not invoked** |

## Quality gates

| # | Gate | Result |
|---|---|---|
| 1 | Exactly 25 valid items | **PASS** |
| 2 | Exact 7/6/6/6 domain balance | **PASS** |
| 3 | Exact 8/12/5 difficulty balance | **PASS** |
| 4 | Every item has one defensible answer | **CONDITIONAL** (manual semantic review pending) |
| 5 | Every item has a complete solution | **PASS** (documented; expert verify pending) |
| 6 | Every distractor has documented logic | **PASS** |
| 7 | No duplicate prompts | **PASS** |
| 8 | No unresolved high-risk near-duplicate | **PASS** |
| 9 | Correct-answer positions balanced | **PASS** |
| 10 | No retired aliases | **PASS** |
| 11 | Four anchors exist | **PASS** |
| 12 | All four domains become scoreable | **PASS** |
| 13 | Missing domains remain missing | **PASS** |
| 14 | TraitScoringService accepts the form | **PASS** |
| 15 | No persona automatically produced | **PASS** |
| 16 | No production integration | **PASS** |
| 17 | Language review completed | **CONDITIONAL** (explicitly pending) |
| 18 | Manual semantic review completed | **CONDITIONAL** (explicitly pending) |

## Readiness conclusion

**CONDITIONAL for expert revision / review only.**  
Automated structural and offline scoring gates pass.  
**Not** production-ready. Manual semantic + language review required before any runtime wiring.

## Unresolved manual-review items

- All 25 items: `pending_manual_semantic_and_language_review`
- Pattern factorial item (`iq_tr_v1_pattern_006`): confirm accessibility without heavy factorial memorization
- Cube rotation (`iq_tr_v1_spatial_003`): verify imagery-free comprehension with pilot respondents
- Verbal connective / quantifier items: dialect neutrality check
